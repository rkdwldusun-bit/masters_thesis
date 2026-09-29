"""Run from repository root: OPENBLAS_NUM_THREADS=1 python reanalysis_20260929/run_reanalysis.py.
Exploratory scope and limitations are in ANALYSIS_PLAN.md. Only numpy/pandas/scipy/matplotlib.
"""
from pathlib import Path
import json, hashlib, sys
import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import original_engine as E

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reanalysis_20260929'/'outputs'; OUT.mkdir(exist_ok=True)
P=pd.read_csv(ROOT/'verified_results/verified_master_panel.csv')
OLD=pd.read_csv(ROOT/'verified_results/verified_results_summary.csv')
ANN=['soybean','onion','sweet_potato','corn','garlic','spring_potato','red_pepper']
CTRL=sorted(P.loc[P.role=='control_pool','crop_id'].unique())
OUTCOMES=['ln_area','ln_yield','ln_production']
HORIZONS={'0_9':range(10),'0_2':range(3),'3_5':range(3,6),'6_9':range(6,10)}
SEED=20260929

def holm(p):
    p=np.asarray(p,float); order=np.argsort(p); out=np.empty(len(p))
    out[order]=np.minimum(1,np.maximum.accumulate(p[order]*(len(p)-np.arange(len(p)))))
    return out

rows=[]; dynamics=[]; replication=[]; numerical_checks=[]
for o in OUTCOMES:
    for clock in ['national','pilot']:
        for base in ['last','last5']:
            for h,events in HORIZONS.items():
                E.RNG=np.random.default_rng(SEED)
                R,O,D=E.run_cs(P,o,ANN,CTRL,norm='A' if base=='last' else 'B',B5=base=='last5',
                               pilot_clock=clock=='pilot',e_post=events)
                rows.append(dict(method='original_custom',outcome=o,clock=clock,base=base,horizon=h,
                                 n_obs=len(D),**O))
                R=R.assign(outcome=o,clock=clock,base=base,horizon=h); dynamics.append(R)
                if clock=='national' and base=='last' and h=='0_9':
                    target=OLD[(OLD['sample']=='annual')&(OLD.spec_internal=='CS-A (preferred)')&(OLD.outcome_internal==o)].iloc[0]
                    de=O['est']-target.est; ds=O['se_cluster']-target.se_cluster
                    assert abs(de)<1e-9 and abs(ds)<1e-9,(o,de,ds)
                    replication.append(dict(outcome=o,est=O['est'],se=O['se_cluster'],est_difference=de,
                        se_difference=ds,p_new=O['p_wild'],p_old=target.p_wild_py))
    print('Custom grid completed:',o,flush=True)

def twfe(o,trend=False):
    D,Y,meta=E.prepare(P,o,ANN,CTRL)
    D=D[(~D.post)|((D.year-D.g)<=9)].copy()
    c=pd.get_dummies(D.crop_id,dtype=float).to_numpy()
    yr=pd.get_dummies(D.year,dtype=float).to_numpy()[:,1:]
    X=np.column_stack([D.post.astype(float),c,yr]+([c*(D.year.to_numpy()[:,None]-2000)] if trend else []))
    y=D[o].to_numpy(); pinv=np.linalg.pinv(X); b=pinv@y; u=y-X@b
    h=pinv[0]; groups=sorted(D.crop_id.unique()); G=len(groups)
    ix=[np.flatnonzero(D.crop_id.to_numpy()==g) for g in groups]
    rank=np.linalg.matrix_rank(X); n=len(y); correction=G/(G-1)*(n-1)/(n-rank)
    score=np.array([h[z]@u[z] for z in ix]); se=np.sqrt(correction*(score@score))
    # Restricted wild cluster bootstrap-t, null beta_post=0. All OLS matrices fixed.
    Xr=X[:,1:]; ur=y-Xr@np.linalg.lstsq(Xr,y,rcond=None)[0]
    Z=np.zeros((n,G))
    for g,z in enumerate(ix): Z[z,g]=ur[z]
    delta=pinv@Z; U=Z-X@delta
    score_map=np.vstack([h[z]@U[z,:] for z in ix])
    V=np.random.default_rng(SEED).choice(E.WEBB,size=(G,9999))
    bst=delta[0]@V; sest=np.sqrt(correction*np.sum((score_map@V)**2,axis=0))
    # Check vectorized bootstrap against literal refit/cluster-sandwich calculations.
    max_t_error=0.
    for draw in range(20):
        ys=(y-ur)+Z@V[:,draw]
        bs=np.linalg.lstsq(X,ys,rcond=None)[0]; us=ys-X@bs
        ses=np.sqrt(correction*sum((h[z]@us[z])**2 for z in ix))
        max_t_error=max(max_t_error,abs(bs[0]/ses-bst[draw]/sest[draw]))
    assert max_t_error<1e-7,(o,trend,max_t_error)
    numerical_checks.append(dict(check='WCR vectorized vs literal refit',outcome=o,variant=str(trend),max_error=max_t_error))
    pb=(1+np.sum(np.abs(bst/sest)>=abs(b[0]/se)))/(V.shape[1]+1)
    # These CIs are cluster-t, not inverted WCR intervals; explicitly separate names.
    q=stats.t.ppf(.975,G-1)
    return dict(method='TWFE_trends' if trend else 'TWFE_clean',outcome=o,clock='national',base='FE',horizon='0_9',
                est=b[0],se_cluster=se,p_wild=pb,p_cluster_t=2*stats.t.sf(abs(b[0]/se),G-1),
                ci_lo_cluster_t=b[0]-q*se,ci_hi_cluster_t=b[0]+q*se,G=G,n_treated=7,n_obs=n,design_rank=rank)

for o in OUTCOMES:
    for tr in [False,True]: rows.append(twfe(o,tr))
S=pd.DataFrame(rows); S['p_holm_all54']=holm(S.p_wild)
S.to_csv(OUT/'all_54_effect_tests.csv',index=False)
pd.concat(dynamics).to_csv(OUT/'all_custom_dynamic.csv',index=False)
pd.DataFrame(replication).to_csv(OUT/'replication.csv',index=False)
print('Effect results:',S[['method','outcome','clock','base','horizon','est','se_cluster','p_wild','p_holm_all54']].to_string(index=False),flush=True)

# Descriptive statistics. SD describes dispersion across crop-years, not SE of a causal effect.
Q=P[P.crop_id.isin(ANN+CTRL)&P.year.between(1991,2024)].copy()
Q['group']=np.where(Q.crop_id.isin(ANN),'treated_7','control_pool_24')
Q['phase']=np.select([Q.pilot_year.isna()|(Q.year<Q.pilot_year),Q.year>=Q.national_year],['clean','national_post'],'pilot_or_other_exposed')
desc=Q.groupby(['group','phase'])[OUTCOMES+['area_ha','production_t','yield_kg10a']].agg(['count','mean','std','min','max'])
desc.to_csv(OUT/'descriptive_stats.csv')
Q.groupby(['crop_id','phase'])[OUTCOMES].agg(['count','mean','std']).to_csv(OUT/'descriptive_by_crop.csv')

# Crop-specific contrasts are diagnostic, not seven separate significance searches.
cr=[]; pre=[]; pslopes=[]
for o in OUTCOMES:
    D,Y,meta=E.prepare(P,o,ANN,CTRL); clean=set(zip(D.loc[D.clean,'crop_id'],D.loc[D.clean,'year']))
    for i in ANN:
        g=int(meta.loc[i,'g']); p=int(meta.loc[i,'p']); b=max(t for c,t in clean if c==i)
        for e in range(10):
            t=g+e; J=[j for j in meta.index if j!=i and (j,t) in clean and (j,b) in clean]
            di=Y[i,t]-Y[i,b]; dc=np.mean([Y[j,t]-Y[j,b] for j in J])
            cr.append(dict(outcome=o,crop=i,event_time=e,baseline=b,target=t,treated_change=di,control_change=dc,contrast=di-dc,n_controls=len(J)))
        # Freeze donors throughout pilot-relative prewindow -10..-1. Same 7 treated crops at every point.
        ts=list(range(p-10,p)); J=[j for j in meta.index if j!=i and all((j,t) in clean for t in ts)]
        assert all((i,t) in clean for t in ts) and J
        rel=np.array([Y[i,t]-np.mean([Y[j,t] for j in J]) for t in ts])
        slope=np.polyfit(np.arange(-10,0),rel,1)[0]
        pslopes.append(dict(outcome=o,crop=i,pre_slope=slope,n_controls=len(J),donors=';'.join(J)))
        for k,t in enumerate(ts):
            pre.append(dict(outcome=o,crop=i,pilot_relative_year=t-p,contrast=rel[k]-rel[-1],n_controls=len(J)))
C=pd.DataFrame(cr); C.to_csv(OUT/'crop_contrasts.csv',index=False)
C.groupby(['outcome','crop'])[['treated_change','control_change','contrast']].mean().to_csv(OUT/'crop_mean_contrasts.csv')
PRE=pd.DataFrame(pre); PRE.to_csv(OUT/'balanced_pilot_pretrends.csv',index=False)
pd.DataFrame(pslopes).to_csv(OUT/'crop_pretrend_slopes.csv',index=False)

# Reconstruct the original score map and audit its calibration under known no-effect DGPs.
# Linear algebra reproduces original scores exactly; simulated errors are stationary AR(1), independent across crops.
cal=[]; covariance=[]
for o in OUTCOMES:
    D,Y,meta=E.prepare(P,o,ANN,CTRL); cells=list(Y); ix={k:j for j,k in enumerate(cells)}; n=len(cells)
    ag=E.cs_weights(D,Y,meta,ANN); crops=sorted(D.crop_id.unique()); G=len(crops)
    bycrop={c:np.array([ix[k] for k in cells if k[0]==c]) for c in crops}
    U=list(zip(D.loc[D.clean,'crop_id'],D.loc[D.clean,'year']))
    _,_,XU,cs,ts,ci,ti=E.fe_fit(D,Y,U)
    XA=np.zeros((n,XU.shape[1]))
    for j,(c,t) in enumerate(cells):
        XA[j,ci[c]]=1
        if ti[t]>0: XA[j,len(cs)+ti[t]-1]=1
    M=np.eye(n); M[:,[ix[k] for k in U]]-=XA@np.linalg.pinv(XU)
    weights={}
    for e,a in ag.items():
        w=np.zeros(n)
        for k,v in a['w'].items(): w[ix[k]]=v
        weights[e]=w
    for r in D[D.post].itertuples():
        e=int(r.year-r.g)
        if e in weights: M[ix[r.crop_id,r.year]]-=weights[e]
    w=np.mean([weights[e] for e in range(10)],axis=0)
    A=np.zeros((G,n))
    for j,c in enumerate(crops): A[j,bycrop[c]]=w[bycrop[c]]
    L=A@M; y=np.array([Y[k] for k in cells]); psi=L@y
    active=np.sum(np.abs(psi)>1e-12)
    target=S[(S.method=='original_custom')&(S.outcome==o)&(S.clock=='national')&(S.base=='last')&(S.horizon=='0_9')].iloc[0]
    se=np.sqrt(active/(active-1)*np.sum(psi**2))
    assert abs(se-target.se_cluster)<1e-9,(o,se,target.se_cluster)
    # Pretest covariance diagnostics: do not assume a full-rank pseudoinverse Wald is reliable.
    pre_es=sorted(e for e in weights if e<0); scores=[]
    for e in pre_es:
        scores.append(np.array([np.sum(weights[e][bycrop[c]]*(M@y)[bycrop[c]]) for c in crops]))
    sc=np.array(scores); cov=sc@sc.T; ev=np.linalg.eigvalsh(cov)
    covariance.append(dict(outcome=o,k=len(pre_es),rank=np.linalg.matrix_rank(cov),eigen_min=ev[0],eigen_max=ev[-1],condition_number=np.linalg.cond(cov)))
    if o!='ln_production': continue
    # Verify synthetic-data score map and p-values against the original full estimator.
    for trial in range(3):
        syn=np.random.default_rng(SEED+trial).standard_normal(n)
        PS=P.copy(); vals={(c,t):syn[j] for j,(c,t) in enumerate(cells)}
        PS[o]=[vals.get((r.crop_id,r.year),getattr(r,o)) for r in P.itertuples()]
        E.B_DRAWS=1999; E.RNG=np.random.default_rng(SEED)
        _,oo,_=E.run_cs(PS,o,ANN,CTRL)
        vv=np.random.default_rng(SEED).choice(E.WEBB,size=(1999,G))
        ss=L@syn; tt=w@syn
        pp=(1+np.sum(np.abs(vv@ss)>=abs(tt)))/2000
        err=max(abs(oo['est']-tt),abs(oo['se_cluster']-np.sqrt(active/(active-1)*np.sum(ss**2))),abs(oo['p_wild']-pp))
        assert err<1e-9,(trial,err)
        numerical_checks.append(dict(check='Null score map vs original estimator',outcome=o,variant=str(trial),max_error=err))
    E.B_DRAWS=9999
    rng=np.random.default_rng(SEED); reps=2000; B=1999
    V=rng.choice(E.WEBB,size=(B,G))
    for rho in [0.,.7,.95]:
        yy=np.zeros((n,reps))
        for c in crops:
            years=sorted(t for cc,t in cells if cc==c)
            z=rng.standard_normal(reps)
            for t in range(min(years),max(years)+1):
                if t>min(years): z=rho*z+np.sqrt(1-rho*rho)*rng.standard_normal(reps)
                if (c,t) in ix: yy[ix[c,t]]=z
        theta=w@yy; ps=L@yy
        p=(1+np.sum(np.abs(V@ps)>=np.abs(theta)[None,:],axis=0))/(B+1)
        rate=np.mean(p<.05); mc=np.sqrt(rate*(1-rate)/reps)
        cal.append(dict(rho=rho,repetitions=reps,bootstrap_draws=B,rejection_rate=rate,mc_se=mc,
                        mc_95_lo=max(0,rate-1.96*mc),mc_95_hi=min(1,rate+1.96*mc)))
pd.DataFrame(cal).to_csv(OUT/'null_calibration.csv',index=False)
pd.DataFrame(covariance).to_csv(OUT/'pretest_covariance_diagnostics.csv',index=False)
pd.DataFrame(numerical_checks).to_csv(OUT/'numerical_checks.csv',index=False)
print('Null calibration:',cal,flush=True)

# Export scientific figures, with no cherry-picked horizons or crops.
fig,axes=plt.subplots(1,3,figsize=(13,4))
for ax,o in zip(axes,OUTCOMES):
    z=PRE[PRE.outcome==o]
    for c in ANN:
        t=z[z.crop==c]; ax.plot(t.pilot_relative_year,t.contrast,color='gray',alpha=.35,lw=.8)
    m=z.groupby('pilot_relative_year').contrast.mean(); ax.plot(m.index,m.values,color='#165a91',lw=2.5,label='Mean: same 7 crops')
    ax.axhline(0,color='black',lw=.7); ax.set(title=o,xlabel='Years before pilot',ylabel='Log difference vs pilot -1')
    ax.legend(fontsize=8)
fig.suptitle('Balanced preperiod diagnostics; fixed clean donors per crop; descriptive, no confidence band')
fig.tight_layout();fig.savefig(OUT/'balanced_pretrends.png',dpi=180);plt.close(fig)

fig,axes=plt.subplots(1,3,figsize=(13,4))
for ax,o in zip(axes,OUTCOMES):
    z=S[(S.method=='original_custom')&(S.outcome==o)&(S.clock=='national')&(S.base=='last')]
    x=np.arange(len(z)); ax.errorbar(x,z.est,yerr=[z.est-z.ci_lo_wild,z.ci_hi_wild-z.est],fmt='o',capsize=4,color='#165a91')
    ax.set_xticks(x,z.horizon); ax.axhline(0,color='black',lw=.7); ax.set(title=o,xlabel='Post-national event window',ylabel='Log-point estimate')
fig.suptitle('All fixed post windows; original custom 95% pointwise intervals (exploratory)')
fig.tight_layout();fig.savefig(OUT/'horizon_sensitivity.png',dpi=180);plt.close(fig)

fig,axes=plt.subplots(4,2,figsize=(12,13)); axes=axes.ravel()
for ax,c in zip(axes,ANN):
    z=P[(P.crop_id==c)&P.year.between(1991,2024)].copy(); p=int(z.pilot_year.iloc[0]); g=int(z.national_year.iloc[0])
    for o in OUTCOMES:
        b=z.loc[z.year==p-1,o].iloc[0]; ax.plot(z.year,z[o]-b,label=o)
    ax.axvline(p,color='gray',ls='--',label='Pilot');ax.axvline(g,color='black',ls=':',label='National')
    ax.axhline(0,color='gray',lw=.5); ax.set_title(c);ax.legend(fontsize=7)
axes[-1].axis('off');fig.suptitle('Raw treated-crop log outcomes; pilot -1 normalized to zero')
fig.tight_layout();fig.savefig(OUT/'raw_crop_trajectories.png',dpi=150);plt.close(fig)

manifest={'source_commit':'00b60931ef577aca690d0d3aa2fc4a4c3bed5e64','seed':SEED,'bootstrap_draws':9999,
    'numpy':np.__version__,'pandas':pd.__version__,'python':sys.version,
    'input_sha256':hashlib.sha256((ROOT/'verified_results/verified_master_panel.csv').read_bytes()).hexdigest(),
    'effect_tests':len(S),'raw_p_below_05':int((S.p_wild<.05).sum()),'holm_p_below_05':int((S.p_holm_all54<.05).sum()),
    'limitations':['Exploratory after prior results inspected','Original custom score inference not established by replication',
    'TWFE and linear-trend models are benchmarks, not automatically valid causal estimates','No new data or external date validation']}
(OUT/'run_manifest.json').write_text(json.dumps(manifest,indent=2))
print('COMPLETE',json.dumps(manifest),flush=True)
