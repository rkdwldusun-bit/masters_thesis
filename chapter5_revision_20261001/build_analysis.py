"""Reproduce Chapter 5 additions from the frozen panel. No new inference or simulations.
Run from any directory: python chapter5_revision_20261001/build_analysis.py
"""
from pathlib import Path
import sys, json, hashlib, shutil
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
HERE=Path(__file__).resolve().parent; ROOT=HERE.parent
sys.path.insert(0,str(ROOT/'reanalysis_20260929'))
import original_engine as E
OUT=HERE/'outputs'; FIG=HERE/'figures'; OUT.mkdir(exist_ok=True); FIG.mkdir(exist_ok=True)
ANN=['soybean','onion','sweet_potato','corn','garlic','spring_potato','red_pepper']
YS=['ln_area','ln_yield','ln_production']; LABEL=dict(zip(YS,['Area','Yield','Production']))
P=pd.read_csv(ROOT/'verified_results/verified_master_panel.csv')
PI=P.set_index(['crop_id','year']); META=P.drop_duplicates('crop_id').set_index('crop_id')
NAME=META.crop_en_display.to_dict()
CTRL=sorted(P.loc[P.role.eq('control_pool'),'crop_id'].unique())
VARIANTS={'original':CTRL,'exclude_spring':[c for c in CTRL if c not in ['spring_napa','spring_radish']]}
FIELD=['red_bean','mung_bean','barley','malting_barley','wheat','sesame','perilla','peanut']
SEASONAL=['spring_napa','highland_napa','autumn_napa','winter_napa','spring_radish','highland_radish','autumn_radish','winter_radish','carrot','large_green_onion','small_green_onion']
checks=[]
def check(name,error,tol=1e-10):
    error=float(error); checks.append({'check':name,'max_abs_error':error,'tolerance':tol,'passed':bool(error<=tol)})
    assert error<=tol,(name,error)
def save(df,name): df.to_csv(OUT/(name+'.csv'),index=False)
def point(y,controls=CTRL,tr=ANN,df=P,**kwargs):
    D,Y,M=E.prepare(df,y,tr,controls,**{k:v for k,v in kwargs.items() if k in ['pilot_clock']})
    A=E.cs_weights(D,Y,M,tr,**{k:v for k,v in kwargs.items() if k in ['norm','B5']})
    assert all(e in A and A[e]['n_tr']==len(tr) for e in range(10))
    return np.mean([sum(v*Y[k] for k,v in A[e]['w'].items()) for e in range(10)])
# Direct individual contrasts and explicit donor/reference support, separately from engine aggregation.
rows=[]; cells=[]; pre=[]
for variant,controls in VARIANTS.items():
  for y in YS:
    D,Y,M=E.prepare(P,y,ANN,controls); clean=set(zip(D.loc[D.clean,'crop_id'],D.loc[D.clean,'year']))
    for i in ANN:
      p=int(M.loc[i,'p']); b=p-1; g=int(M.loc[i,'g'])
      cells.append(dict(variant=variant,outcome=y,group='Treated reference',crop_id=i,year=b))
      for e in range(10):
        t=g+e; J=sorted(j for j in M.index if j!=i and (j,b) in clean and (j,t) in clean)
        assert J and (i,t) in Y
        delta=(Y[i,t]-Y[i,b])-np.mean([Y[j,t]-Y[j,b] for j in J])
        rows.append(dict(variant=variant,outcome=y,crop=i,crop_name=NAME[i],event_time=e,baseline=b,target=t,n_controls=len(J),contrast=delta,weight=1/70,donors=';'.join(J)))
        cells.append(dict(variant=variant,outcome=y,group='Treated target',crop_id=i,year=t))
        for j in J:
          cells.extend([dict(variant=variant,outcome=y,group='Donor reference',crop_id=j,year=b),dict(variant=variant,outcome=y,group='Donor target',crop_id=j,year=t)])
      ts=list(range(p-10,p)); J=sorted(j for j in M.index if j!=i and all((j,t) in clean for t in ts))
      assert J and all((i,t) in Y for t in ts)
      for t in ts:
        treated=Y[i,t]-Y[i,b]; donor=np.mean([Y[j,t]-Y[j,b] for j in J])
        pre.append(dict(variant=variant,outcome=y,crop=i,pilot_event=t-p,treated=treated,donor=donor,gap=treated-donor,n_donors=len(J),donors=';'.join(J)))
C=pd.DataFrame(rows); MEMBERS=pd.DataFrame(cells).drop_duplicates(); PRE=pd.DataFrame(pre)
save(C,'crop_event_contrasts'); save(MEMBERS,'contributing_cells');save(PRE,'pretrend_crop_paths')
old=pd.read_csv(ROOT/'reanalysis_20260930/outputs/crop_event_contrasts.csv')
m=C.merge(old,on=['variant','outcome','crop','event_time'],suffixes=('','_old'),validate='one_to_one')
check('all 420 direct contrasts vs frozen September 30',np.max(abs(m.contrast-m.contrast_old)))
oldpre=pd.read_csv(ROOT/'reanalysis_20260930/outputs/balanced_pretrends.csv')
m=PRE.merge(oldpre,on=['variant','outcome','crop','pilot_event'],validate='one_to_one')
check('fixed preperiod donor gaps vs frozen September 30',np.max(abs(m.gap-m.relative_log)))
MEANS=C.groupby(['variant','outcome','crop','crop_name'],sort=False).agg(contrast=('contrast','mean'),events=('event_time','nunique')).reset_index()
MEANS['equal_contribution']=MEANS.contrast/7
MEANS['crop_order']=MEANS.crop.map({c:i+1 for i,c in enumerate(ANN)})
save(MEANS,'crop_mean_contrasts')
PM=PRE.groupby(['variant','outcome','pilot_event'],sort=False)[['treated','donor','gap']].mean().reset_index();save(PM,'pretrend_mean_paths')
# Unique-cell descriptive statistics, not pseudo-independent observations or sampling SEs.
desc=[]
for (variant,y,group),z in MEMBERS.groupby(['variant','outcome','group'],sort=False):
  keys=list(zip(z.crop_id,z.year)); raw=PI.loc[keys]
  for variable,unit in [('area_ha','ha'),('yield_kg10a','kg/10a'),('production_t','tonnes')]:
    v=raw[variable].dropna()
    desc.append(dict(variant=variant,design_outcome=y,group=group,variable=variable,unit=unit,N=len(v),crops=v.index.get_level_values(0).nunique(),mean=v.mean(),sd=v.std(ddof=1),min=v.min(),max=v.max()))
DESC=pd.DataFrame(desc);save(DESC,'descriptive_statistics')
for variant in VARIANTS:
  masks=[]
  for y in YS:
    z=MEMBERS[(MEMBERS.variant==variant)&(MEMBERS.outcome==y)]
    masks.append(set(zip(z.group,z.crop_id,z.year)))
  check(f'{variant}: identical support across outcomes',len(masks[0]^masks[1])+len(masks[0]^masks[2]),0)
# Sensitivity points. These are alternate comparisons, not equally valid causal estimators.
P_ALT=P.copy();sel=P_ALT.crop_id.isin(ANN);P_ALT.loc[sel,'national_year']=P_ALT.loc[sel,'national_year_alt_table']
specs=[
 ('Reference: last clean year','CS-A (preferred)',{},CTRL,P,'Reference comparison'),
 ('Last five clean years','CS-B5 (mean of last 5 clean-pre years)',{'norm':'B','B5':True},CTRL,P,'Changes reference contrast'),
 ('All clean years','CS-B (mean of all clean-pre years)',{'norm':'B'},CTRL,P,'Changes reference contrast'),
 ('Exclude two spring series',None,{},VARIANTS['exclude_spring'],P,'Changes donor comparison'),
 ('Field-crop donors only','Controls: field crops only',{},[c for c in CTRL if c in FIELD],P,'Changes donor comparison'),
 ('Exclude uncertain seasonal forms','Controls: excl. uncertain seasonal forms',{},[c for c in CTRL if c not in SEASONAL],P,'Changes donor comparison'),
 ('Product-table dates','Dates: product-table nationwide year',{},CTRL,P_ALT,'Changes target dates'),
 ('Pilot-year clock','Dates: pilot-year clock (no transition exclusion)',{'pilot_clock':True},CTRL,P,'Changes policy exposure target')]
ARCH=pd.read_csv(ROOT/'verified_results/verified_results_summary.csv'); FROZEN=pd.read_csv(ROOT/'reanalysis_20260930/outputs/main_inference.csv')
sens=[]
for order,(label,archive,kwargs,controls,df,meaning) in enumerate(specs,1):
  for y in YS:
    v=point(y,controls=controls,df=df,**kwargs)
    if archive:
      a=ARCH[(ARCH['sample']=='annual')&(ARCH.spec_internal==archive)&(ARCH.outcome_internal==y)]
    else:
      a=FROZEN[(FROZEN.variant=='exclude_spring')&(FROZEN.outcome==y)&(FROZEN.method=='original_multiplier')]
    assert len(a)==1
    check(f'specification {order} {y} point vs archive',abs(v-a.est.iloc[0]))
    sens.append(dict(order=order,specification=label,outcome=y,est=v,comparison_change=meaning,treated_crops=7,events=10))
SENS=pd.DataFrame(sens);save(SENS,'key_sensitivity')
# Leave-one-out changes the target population and donor eligibility too; reproduce actual engine.
loo=[]
for omitted in ANN:
  for y in YS:
    v=point(y,tr=[i for i in ANN if i!=omitted]);a=ARCH[(ARCH['sample']=='annual')&(ARCH.spec_internal=='Leave out '+NAME[omitted])&(ARCH.outcome_internal==y)]
    assert len(a)==1;check('leave-one-out '+omitted+' '+y,abs(v-a.est.iloc[0]))
    loo.append(dict(omitted_crop=omitted,crop_name=NAME[omitted],outcome=y,est=v))
save(pd.DataFrame(loo),'leave_one_out')
# Fixed crop-area weights measured before ANY of the seven coded pilots.
W=P[P.crop_id.isin(ANN)&P.year.between(2003,2007)].groupby('crop_id').agg(mean_area_ha=('area_ha','mean'),years=('area_ha','count')).reindex(ANN).reset_index()
assert (W.years==5).all() and META.loc[ANN,'pilot_year'].min()>2007
W['crop_name']=W.crop_id.map(NAME);W['equal_weight']=1/7;W['area_weight']=W.mean_area_ha/W.mean_area_ha.sum();check('area weights sum',abs(W.area_weight.sum()-1))
save(W,'crop_weights');weighted=[]
for variant in VARIANTS:
  for y in YS:
    q=MEANS[(MEANS.variant==variant)&(MEANS.outcome==y)].merge(W,left_on='crop',right_on='crop_id',validate='one_to_one')
    for scheme,col in [('Equal crop','equal_weight'),('Pre-pilot area','area_weight')]:
      v=float((q.contrast*q[col]).sum())
      weighted.append(dict(variant=variant,outcome=y,weighting=scheme,est=v,concentration_index=float(1/np.sum(q[col]**2)),treated_crops=7,inference='not_computed'))
WEIGHTED=pd.DataFrame(weighted);save(WEIGHTED,'weight_comparison')
CONTR=MEANS.merge(W[['crop_id','area_weight']],left_on='crop',right_on='crop_id');CONTR['area_contribution']=CONTR.contrast*CONTR.area_weight;save(CONTR,'weighted_crop_contributions')
MAIN=FROZEN[FROZEN.method=='original_multiplier'].copy();save(MAIN,'main_diagnostics_frozen')
for variant in VARIANTS:
  for y in YS:
    v=MEANS[(MEANS.variant==variant)&(MEANS.outcome==y)].contrast.mean()
    ref=MAIN[(MAIN.variant==variant)&(MAIN.outcome==y)].est.iloc[0]
    check(f'crop mean aggregation {variant} {y}',abs(v-ref))
# Accounting check: published yield can be rounded separately; quantify, do not impose equality.
z=P[P.crop_id.isin(ANN)&P.year.between(1991,2024)].dropna(subset=YS)
identity=z.ln_production-z.ln_area-z.ln_yield+np.log(100)
ID=WEIGHTED.pivot(index=['variant','weighting'],columns='outcome',values='est').reset_index()
ID['production_minus_area_minus_yield']=ID.ln_production-ID.ln_area-ID.ln_yield;save(ID,'accounting_residuals')
# Frozen supplementary outputs: no inference rerun.
for source,target in [('reanalysis_20260930/outputs/date_sensitivity.csv','date_sensitivity_frozen.csv'),('reanalysis_20260930/outputs/simulation_calibration.csv','simulation_calibration_frozen.csv'),('verified_results/verified_price_results.csv','secondary_price_frozen.csv'),('verified_results/verified_rice_case.csv','secondary_rice_frozen.csv')]:shutil.copyfile(ROOT/source,OUT/target)
save(ARCH[ARCH['sample'].eq('fruit')],'secondary_fruit_frozen')
# Figures are descriptive points; no invented confidence bands.
plt.rcParams.update({'font.family':'DejaVu Serif','font.size':10,'axes.spines.top':False,'axes.spines.right':False,'axes.grid':False,'savefig.dpi':180})
blue='#235b83';orange='#ba5e2b';gray='#727272'
def finish(fig,name):
  fig.savefig(FIG/(name+'.png'),bbox_inches='tight',facecolor='white');fig.savefig(FIG/(name+'.pdf'),bbox_inches='tight');plt.close(fig)
fig,axs=plt.subplots(3,1,figsize=(6.2,6.5),sharex=True)
for ax,y in zip(axs,YS):
  a=PM[(PM.variant=='original')&(PM.outcome==y)].sort_values('pilot_event');b=PM[(PM.variant=='exclude_spring')&(PM.outcome==y)].sort_values('pilot_event')
  ax.plot(a.pilot_event,a.treated,'o-',color=blue,label='Treated crops',markersize=3)
  ax.plot(a.pilot_event,a.donor,'s-',color=gray,label='Original donors',markersize=3)
  ax.plot(b.pilot_event,b.donor,'^--',color=orange,label='Donors excluding two spring series',markersize=3)
  ax.axhline(0,color='#cccccc',lw=.7);ax.set_title(LABEL[y],loc='left',fontsize=11);ax.set_ylabel('Log change');ax.set_xticks(range(-10,0));ax.grid(axis='y',alpha=.15)
axs[-1].set_xlabel('Years relative to coded pilot (reference = −1)')
axs[0].legend(fontsize=8,frameon=False,loc='best');fig.tight_layout(h_pad=1.0);finish(fig,'fig5_1_pretrends')
fig,axs=plt.subplots(1,3,figsize=(7.0,4.2),sharey=True)
for ax,y in zip(axs,YS):
  for variant,col,marker,offset,lab in [('original',blue,'o',-.09,'Original donors'),('exclude_spring',orange,'D',.09,'Exclude spring series')]:
    a=MEANS[(MEANS.variant==variant)&(MEANS.outcome==y)].set_index('crop').loc[ANN]
    ax.scatter(a.contrast,np.arange(7)+offset,color=col,marker=marker,s=25,label=lab)
  ax.axvline(0,color=gray,lw=.8);ax.set_title(LABEL[y],fontsize=11);ax.set_xlabel('Mean log contrast');ax.grid(axis='x',alpha=.15)
axs[0].set_yticks(range(7),[NAME[i] for i in ANN]);axs[0].invert_yaxis()
fig.legend(*axs[0].get_legend_handles_labels(),loc='lower center',ncol=2,frameon=False,fontsize=9)
fig.tight_layout(rect=[0,.09,1,1]);finish(fig,'fig5_2_crop_contrasts')
EV=C.groupby(['variant','outcome','event_time'],sort=False).agg(est=('contrast','mean'),min_donors=('n_controls','min'),max_donors=('n_controls','max')).reset_index();save(EV,'post_event_points')
fig,axs=plt.subplots(3,1,figsize=(6.2,6.2),sharex=True)
for ax,y in zip(axs,YS):
  for variant,col,marker,lab in [('original',blue,'o','Original donors'),('exclude_spring',orange,'D','Exclude two spring series')]:
    a=EV[(EV.variant==variant)&(EV.outcome==y)].sort_values('event_time');ax.plot(a.event_time,a.est,marker=marker,color=col,label=lab,markersize=3)
  ax.axhline(0,color=gray,lw=.7);ax.set_title(LABEL[y],loc='left',fontsize=11);ax.set_ylabel('Log contrast');ax.grid(axis='y',alpha=.15)
axs[0].legend(frameon=False,fontsize=8);axs[-1].set_xticks(range(10));axs[-1].set_xlabel('Years relative to coded nationwide crop year')
fig.tight_layout(h_pad=1);finish(fig,'fig5_3_post_contrasts')
# Figure appendix: heterogeneity in fixed-donor preperiod gaps.
fig,axs=plt.subplots(3,1,figsize=(6.2,6.8),sharex=True)
for ax,y in zip(axs,YS):
  for i in ANN:
    a=PRE[(PRE.variant=='original')&(PRE.outcome==y)&(PRE.crop==i)].sort_values('pilot_event');ax.plot(a.pilot_event,a.gap,label=NAME[i],lw=1.1)
  ax.axhline(0,color=gray,lw=.7);ax.set_title(LABEL[y],loc='left',fontsize=11);ax.set_ylabel('Relative log gap')
axs[-1].set_xlabel('Years relative to coded pilot');axs[-1].set_xticks(range(-10,0))
fig.legend(*axs[0].get_legend_handles_labels(),loc='lower center',ncol=4,frameon=False,fontsize=8)
fig.tight_layout(rect=[0,.09,1,1]);finish(fig,'figA5_1_crop_pretrends')
sources=['verified_results/verified_master_panel.csv','verified_results/verified_treatment_coding.csv','verified_results/verified_results_summary.csv','reanalysis_20260929/original_engine.py','reanalysis_20260930/outputs/main_inference.csv','reanalysis_20260930/outputs/balanced_pretrends.csv','reanalysis_20260930/outputs/simulation_calibration.csv','chapter5_revision_20261001/REVISION_PLAN.md']
report={'checks':checks,'all_passed':all(c['passed'] for c in checks),'direct_contrasts':len(C),'raw_treated_identity_max_abs':float(abs(identity).max()),'raw_treated_identity_median_abs':float(abs(identity).median()),'source_sha256':{s:hashlib.sha256((ROOT/s).read_bytes()).hexdigest() for s in sources},'stata_executed':False,'new_bootstrap_or_simulation':False,'independent_raw_source_validation':False,'python':sys.version,'pandas':pd.__version__,'numpy':np.__version__}
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'checks':len(checks),'all_passed':report['all_passed'],'identity_max':report['raw_treated_identity_max_abs'],'weighted_points':WEIGHTED.to_dict('records'),'support':DESC[(DESC.variant=='original')&(DESC.design_outcome=='ln_area')&(DESC.variable=='area_ha')][['group','N','crops']].to_dict('records')},indent=2))
