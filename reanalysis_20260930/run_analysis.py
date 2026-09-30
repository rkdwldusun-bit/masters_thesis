from pathlib import Path
import json, hashlib, sys
import numpy as np
import pandas as pd
from scipy import stats
from core import ROOT, E, ANN, OUTCOMES, SEED, Design

OUT=ROOT/'reanalysis_20260930/outputs'; OUT.mkdir(parents=True,exist_ok=True)
P=pd.read_csv(ROOT/'verified_results/verified_master_panel.csv')
CTRL=sorted(P.loc[P.role=='control_pool','crop_id'].unique())
VARIANTS={'original':CTRL,'exclude_spring':[c for c in CTRL if c not in ['spring_napa','spring_radish']]}
checks=[]; main=[]; dynamic=[]; desc=[]; flags=[]; pre=[]; slopes=[]; scenario=[]; contrasts=[]; sensitivity=[]
for variant,controls in VARIANTS.items():
 for oi,o in enumerate(OUTCOMES):
    d=Design(P,o,controls); y=d.y
    error=d.check(); checks.append(dict(variant=variant,outcome=o,check='literal WLS/bootstrap and original score map',max_error=error,weight_error=d.weight_error))
    V=np.random.default_rng(SEED).choice(E.WEBB,(9999,len(d.crops)))
    for method,result in [('original_multiplier',d.original(y,V)),('stacked_WCR',d.stacked(y,V[:1999])),('seven_means_t6',d.t7(y))]:
        main.append(dict(variant=variant,outcome=o,method=method,**result,treated_crops=7,contributing_controls=d.G-7,
          ci_method='cluster_t_not_WCR_inversion' if method=='stacked_WCR' else method,
          inference_status='diagnostic_not_validated'))
    E.B_DRAWS=9999; E.RNG=np.random.default_rng(SEED)
    r,oo,_=E.run_cs(P,o,ANN,controls)
    a=main[-3]
    err=max(abs(oo['est']-a['est']),abs(oo['se_cluster']-a['se']),abs(oo['p_wild']-a['p']))
    assert err<1e-9,err
    checks.append(dict(variant=variant,outcome=o,check='full engine point SE p reproduction',max_error=err))
    dynamic.append(r.assign(variant=variant,outcome=o))
    # Explicit unique contributing-cell masks. Means are unweighted crop-year descriptives.
    clean=set(zip(d.D.loc[d.D.clean,'crop_id'],d.D.loc[d.D.clean,'year']))
    nz={k for k,w in zip(d.cells,d.w) if abs(w)>1e-14}
    trbase={(c,int(d.meta.loc[c,'p'])-1) for c in ANN}
    trpost={k for k in nz if k[0] in ANN and k not in trbase}
    masks={'treated_clean_pre':{k for k in clean if k[0] in ANN},'treated_base':trbase,
      'treated_post':trpost,'control_used':{k for k in nz if k[0] not in ANN},'control_clean_context':{k for k in clean if k[0] not in ANN}}
    for group,keys in masks.items():
        for c,t in sorted(keys): flags.append(dict(variant=variant,outcome=o,group=group,crop_id=c,year=t))
        z=P.set_index(['crop_id','year']).loc[list(keys)]
        for var in ['area_ha','yield_kg10a','production_t','ln_area','ln_yield','ln_production']:
            v=z[var].dropna(); desc.append(dict(variant=variant,design_outcome=o,group=group,variable=var,N=len(v),
              ncrops=v.index.get_level_values(0).nunique(),mean=v.mean(),sd=v.std(ddof=1),min=v.min(),max=v.max()))
    bias_terms=[]
    for i in ANN:
        p=int(d.meta.loc[i,'p']); b=p-1; g=int(d.meta.loc[i,'g'])
        for width in [10,5]:
            ts=list(range(p-width,p)); J=[j for j in d.meta.index if j!=i and all((j,t) in clean for t in ts)]
            assert J and all((i,t) in d.Y for t in ts)
            rel=np.array([d.Y[i,t]-np.mean([d.Y[j,t] for j in J]) for t in ts])
            if width==10:
                for t,v in zip(ts,rel-rel[-1]): pre.append(dict(variant=variant,outcome=o,crop=i,pilot_event=t-p,relative_log=v,n_donors=len(J),donors=';'.join(J)))
            else:
                lr=stats.linregress(np.arange(5),rel); s=lr.slope
                slopes.append(dict(variant=variant,outcome=o,crop=i,baseline=b,n_years=5,slope=s,se_iid=lr.stderr,
                   df_iid=3,n_donors=len(J),donors=';'.join(J),uncertainty='iid_OLS_only_no_serial_robustness'))
        for crop,e,bb,t,J,q in d.strata:
            if crop!=i: continue
            delta=d.Y[i,t]-d.Y[i,bb]-np.mean([d.Y[j,t]-d.Y[j,bb] for j in J])
            contrasts.append(dict(variant=variant,outcome=o,crop=i,event_time=e,baseline=bb,target=t,n_controls=len(J),weight=q,contrast=delta))
            bias_terms.append(q*s*(t-bb))
    bias=sum(bias_terms); theta=d.w@y
    for k in [0,.5,1]: scenario.append(dict(variant=variant,outcome=o,k=k,est=theta,assumed_bias=k*bias,adjusted_est=theta-k*bias,
       zero_crossing_k=theta/bias if abs(bias)>1e-12 else np.nan,interpretation='point_scenario_not_CI'))
    print('MAIN AND NUMERICAL CHECKS',variant,o,'est',theta,'error',error,flush=True)

# Four distinct common date shifts; no outcome-driven crop-specific selection.
shifts=[('original',0,0),('pilot_minus1',-1,0),('pilot_plus1',1,0),('national_minus1',0,-1),('national_plus1',0,1)]
for variant,controls in VARIANTS.items():
 for o in OUTCOMES:
  for name,dp,dg in shifts:
    Q=P.copy(); ix=Q.crop_id.isin(ANN)
    Q.loc[ix,'pilot_year']+=dp; Q.loc[ix,'national_year']+=dg
    assert (Q.loc[ix,'pilot_year']<=Q.loc[ix,'national_year']).all()
    for end in [9,8]:
        E.RNG=np.random.default_rng(SEED); E.B_DRAWS=9999
        r,a,D=E.run_cs(Q,o,ANN,controls,e_post=range(end+1))
        counts=r.loc[r.event_time.between(0,end),'n_treated']
        sensitivity.append(dict(variant=variant,outcome=o,date_scenario=name,window=f'0_{end}',
          pilot_shift=dp,national_shift=dg,min_treated_per_event=int(counts.min()),**a))
  print('DATE SENSITIVITY',variant,o,flush=True)

pd.DataFrame(main).to_csv(OUT/'main_inference.csv',index=False)
pd.concat(dynamic).to_csv(OUT/'event_study.csv',index=False)
pd.DataFrame(desc).to_csv(OUT/'descriptive_stats.csv',index=False)
pd.DataFrame(flags).to_csv(OUT/'descriptive_cell_membership.csv',index=False)
pd.DataFrame(pre).to_csv(OUT/'balanced_pretrends.csv',index=False)
pd.DataFrame(slopes).to_csv(OUT/'five_year_slopes.csv',index=False)
pd.DataFrame(scenario).to_csv(OUT/'trend_scenarios.csv',index=False)
pd.DataFrame(contrasts).to_csv(OUT/'crop_event_contrasts.csv',index=False)
pd.DataFrame(sensitivity).to_csv(OUT/'date_sensitivity.csv',index=False)
pd.DataFrame(checks).to_csv(OUT/'numerical_checks.csv',index=False)
(OUT/'manifest.json').write_text(json.dumps(dict(seed=SEED,python=sys.version,numpy=np.__version__,pandas=pd.__version__,
 input_sha256=hashlib.sha256((ROOT/'verified_results/verified_master_panel.csv').read_bytes()).hexdigest(),
 original_engine_sha256=hashlib.sha256((ROOT/'reanalysis_20260929/original_engine.py').read_bytes()).hexdigest(),
 plan_sha256=hashlib.sha256((ROOT/'reanalysis_20260930/PLAN.md').read_bytes()).hexdigest(),
 original_bootstrap_draws=9999,wcr_actual_draws=1999,stata_executed=False,raw_sources_rerun=False),indent=2))
print('ANALYSIS COMPLETE',flush=True)
