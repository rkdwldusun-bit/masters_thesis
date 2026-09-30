"""Parametric calibration diagnostics, not proof that actual-data inference is valid."""
from pathlib import Path
import json,time
import numpy as np
import pandas as pd
from scipy import stats
from core import ROOT,E,ANN,OUTCOMES,SEED,Design,wilson

OUT=ROOT/'reanalysis_20260930/outputs'
P=pd.read_csv(ROOT/'verified_results/verified_master_panel.csv')
CTRL=sorted(P.loc[P.role=='control_pool','crop_id'].unique())
variants={'original':CTRL,'exclude_spring':[c for c in CTRL if c not in ['spring_napa','spring_radish']]}
REPS=4000; B=999
results=[]; params=[]; validation=[]
group_lookup=P.drop_duplicates('crop_id').set_index('crop_id').crop_group.to_dict()
start=time.time()
for vi,(variant,controls) in enumerate(variants.items()):
 for oi,o in enumerate(OUTCOMES):
    d=Design(P,o,controls); groups=d.crops; G=len(groups)
    clean=set(zip(d.D.loc[d.D.clean,'crop_id'],d.D.loc[d.D.clean,'year']))
    residual=d.Mclean@d.y; phi=[]; sig=[]
    for c in groups:
        years=sorted(t for cc,t in clean if cc==c)
        rr=np.array([residual[d.ix[c,t]] for t in years]); centered=rr-rr.mean()
        pairs=[(j,j+1) for j in range(len(years)-1) if years[j+1]==years[j]+1]
        xx=np.array([centered[a] for a,b in pairs]); zz=np.array([centered[b] for a,b in pairs])
        raw=float(xx@zz/(xx@xx)) if xx@xx>1e-15 else 0.
        ph=float(np.clip(raw,-.95,.95)); sd=float(rr.std(ddof=1))
        assert sd>0
        phi.append(ph);sig.append(sd)
        params.append(dict(variant=variant,outcome=o,crop=c,crop_group=group_lookup[c],clean_years=len(years),
          consecutive_pairs=len(pairs),residual_sd=sd,ar1_raw=raw,ar1_used=ph,ar1_clipped=raw!=ph))
    phi=np.array(phi); sig=np.array(sig); innovation_sd=sig*np.sqrt(1-phi**2)
    mapping=np.array([groups.index(c) for c,t in d.cells]); years=np.array([t for c,t in d.cells])
    cm=d.cropmap
    for ri,rho in enumerate([0.,.3,.6]):
        rng=np.random.default_rng(np.random.SeedSequence([SEED,vi,oi,ri,100]))
        bootrng=np.random.default_rng(np.random.SeedSequence([SEED,vi,oi,ri,200]))
        Corr=np.eye(G)
        for i,c in enumerate(groups):
            for j,cc in enumerate(groups):
                if i!=j and group_lookup[c]==group_lookup[cc]: Corr[i,j]=rho
        Cinnov=Corr*innovation_sd[:,None]*innovation_sd[None,:]
        Cstat=Cinnov/(1-phi[:,None]*phi[None,:])
        assert np.max(abs(np.diag(Cstat)-sig**2))<1e-12
        LI=np.linalg.cholesky(Cinnov); LS=np.linalg.cholesky(Cstat)
        z=LS@rng.standard_normal((G,REPS)); yy=np.zeros((len(d.cells),REPS))
        for t in range(int(years.min()),int(years.max())+1):
            if t>years.min(): z=phi[:,None]*z+LI@rng.standard_normal((G,REPS))
            ids=np.flatnonzero(years==t); yy[ids]=z[mapping[ids]]
        theta=d.w@yy; psi=d.L@yy; sb=d.LB@yy; sc=d.LC@yy
        obs_scores=d.LS@yy; se_stack=np.sqrt(d.cr1*np.sum(obs_scores**2,axis=0))
        cv=cm@yy; se7=cv.std(axis=0,ddof=1)/np.sqrt(7)
        p7=2*stats.t.sf(abs(theta/se7),6)
        orig_rej=np.zeros(REPS,bool); wcr_rej=np.zeros(REPS,bool); orig_cov=np.zeros(REPS,bool)
        widths=[]; qstack=stats.t.ppf(.975,d.G-1)
        for m in range(REPS):
            V=bootrng.choice(E.WEBB,(B,G))
            st=V@psi[:,m]; pb=(1+np.sum(abs(st)>=abs(theta[m])))/(B+1)
            quant=np.quantile(abs(st),.95)
            orig_rej[m]=pb<.05; orig_cov[m]=abs(theta[m])<=quant; widths.append(2*quant)
            bs=V@sb[:,m]; ses=np.sqrt(d.cr1*np.sum((V@sc[:,:,m].T)**2,axis=1))
            pw=(1+np.sum(abs(bs/ses)>=abs(theta[m]/se_stack[m])))/(B+1)
            wcr_rej[m]=pw<.05
            if m==0:
                er=max(abs(d.original(yy[:,m],V)['p']-pb),abs(d.stacked(yy[:,m],V)['p']-pw))
                assert er<1e-12
                validation.append(dict(variant=variant,outcome=o,rho=rho,check='simulation vs scalar inference',max_error=er))
            if (m+1)%1000==0: print('SIM',variant,o,rho,m+1,'elapsed',round(time.time()-start,1),flush=True)
        for method,reject,cover in [('original_multiplier',orig_rej,orig_cov),
            ('stacked_WCR',wcr_rej,~wcr_rej),('seven_means_t6',p7<.05,p7>=.05)]:
            k=int(reject.sum()); lo,hi=wilson(k,REPS); rate=k/REPS
            ck=int(cover.sum()); cl,ch=wilson(ck,REPS)
            results.append(dict(variant=variant,outcome=o,innovation_rho=rho,method=method,repetitions=REPS,
              bootstrap_draws=B if method!='seven_means_t6' else 0,rejections=k,rejection_rate=rate,
              mc_se=np.sqrt(rate*(1-rate)/REPS),mc95_lo=lo,mc95_hi=hi,null_inclusion=ck/REPS,
              inclusion_mc95_lo=cl,inclusion_mc95_hi=ch,
              inclusion_definition='membership_in_test_inversion_at_zero_only' if method=='stacked_WCR' else 'reported_interval_contains_zero',
              cluster_t_interval_coverage=float(np.mean(abs(theta)<=qstack*se_stack)) if method=='stacked_WCR' else np.nan,
              mean_original_interval_width=float(np.mean(widths)) if method=='original_multiplier' else np.nan))
        pd.DataFrame(results).to_csv(OUT/'simulation_calibration.csv',index=False)
        pd.DataFrame(params).to_csv(OUT/'simulation_parameters.csv',index=False)
        pd.DataFrame(validation).to_csv(OUT/'simulation_checks.csv',index=False)
(OUT/'simulation_manifest.json').write_text(json.dumps(dict(seed=SEED,repetitions=REPS,bootstrap_draws=B,
 scenarios=18,methods=3,bootstrap_weights='fresh per replicate',rho_definition='within-group standardized innovation correlation',
 calibration='clean TWFE residual SD and consecutive-year AR1 clipped to [-.95,.95]',
 elapsed_seconds=time.time()-start,limitations=['Parametric zero-effect DGP only','Calibration uncertainty not propagated',
 'No outcome/parameter reselection','No certification of causal identification or actual p-values']),indent=2))
print('SIMULATION COMPLETE',round(time.time()-start,1),flush=True)
