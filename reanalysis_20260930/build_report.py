from pathlib import Path
import base64,html,json
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from core import ROOT,OUTCOMES,ANN

HERE=ROOT/'reanalysis_20260930'; O=HERE/'outputs'; F=HERE/'figures'; F.mkdir(exist_ok=True)
main=pd.read_csv(O/'main_inference.csv'); pre=pd.read_csv(O/'balanced_pretrends.csv')
dates=pd.read_csv(O/'date_sensitivity.csv'); trend=pd.read_csv(O/'trend_scenarios.csv')
sim=pd.read_csv(O/'simulation_calibration.csv'); dynamic=pd.read_csv(O/'event_study.csv')
desc=pd.read_csv(O/'descriptive_stats.csv'); panel=pd.read_csv(ROOT/'verified_results/verified_master_panel.csv')
names={'ln_area':'Cultivated area','ln_yield':'Yield','ln_production':'Production'}
vn={'original':'Original donors','exclude_spring':'Exclude spring cabbage and radish'}
colors={'original':'#9e2636','exclude_spring':'#1d577b'}
plt.rcParams.update({'font.family':'serif','font.size':11,'axes.spines.top':False,'axes.spines.right':False,
 'axes.labelsize':11,'axes.titlesize':12,'figure.facecolor':'white','savefig.facecolor':'white'})
def save(fig,name,note):
    fig.text(.02,.01,note,fontsize=9,ha='left')
    fig.tight_layout(rect=[0,.07,1,.95])
    fig.savefig(F/(name+'.png'),dpi=170)
    fig.savefig(F/(name+'.pdf'))
    plt.close(fig)

fig,axs=plt.subplots(1,3,figsize=(12.5,4.4))
for ax,o in zip(axs,OUTCOMES):
 z=main[(main.outcome==o)&(main.method=='original_multiplier')]
 for j,v in enumerate(vn):
  r=z[z.variant==v].iloc[0]
  ax.errorbar(j,r.est,yerr=[[r.est-r.ci_lo],[r.ci_hi-r.est]],fmt='s',color=colors[v],ecolor='#315e85',capsize=4)
 ax.axhline(0,color='black',ls='--',lw=.8);ax.set(title=names[o],ylabel='Log points',xticks=[0,1],xticklabels=['Original','Exclude two'])
 ax.set_xlim(-.5,1.5)
fig.suptitle('Average baseline-relative contrast, events 0–9')
save(fig,'01_main_comparison','Stored original multiplier 95% pointwise intervals. Calibration concerns remain; no causal-effect certification.')

fig,axs=plt.subplots(2,3,figsize=(12.5,7.8),sharex=True)
for row,v in enumerate(vn):
 for ax,o in zip(axs[row],OUTCOMES):
  z=pre[(pre.variant==v)&(pre.outcome==o)]
  for crop in ANN:
   q=z[z.crop==crop];ax.plot(q.pilot_event,q.relative_log,color='.72',lw=.8)
  q=z.groupby('pilot_event').relative_log.mean();ax.plot(q.index,q.values,color=colors[v],marker='s',lw=1.7,ms=4)
  ax.axhline(0,color='black',ls='--',lw=.7);ax.set(title=names[o],xlabel='Years relative to pilot',ylabel='Relative log change')
 axs[row,0].text(0,1.15,vn[v],transform=axs[row,0].transAxes,fontsize=12)
fig.suptitle('Balanced pre-pilot trajectories: the same seven treated crops')
save(fig,'02_balanced_pretrends','Gray: individual crops. Color: equal crop mean. Fixed clean donors within each crop; normalized at pilot −1. No confidence bands.')

fig,axs=plt.subplots(2,3,figsize=(12.5,8),sharex=True)
order=['original','pilot_minus1','pilot_plus1','national_minus1','national_plus1']
for row,v in enumerate(vn):
 for ax,o in zip(axs[row],OUTCOMES):
  z=dates[(dates.variant==v)&(dates.outcome==o)&(dates.window=='0_8')].set_index('date_scenario').loc[order]
  ax.errorbar(range(5),z.est,yerr=[z.est-z.ci_lo_wild,z.ci_hi_wild-z.est],fmt='s',color=colors[v],ecolor='#315e85',capsize=3)
  ax.axhline(0,color='black',ls='--',lw=.7);ax.set(title=names[o],ylabel='Log points',xticks=range(5),xticklabels=['Base','Pilot −1','Pilot +1','Nat. −1','Nat. +1'])
  ax.tick_params(axis='x',labelrotation=35)
 axs[row,0].text(0,1.15,vn[v],transform=axs[row,0].transAxes,fontsize=12)
fig.suptitle('Date sensitivity on common event support, 0–8')
save(fig,'03_date_sensitivity','All seven treated crops shifted together; donor dates unchanged. Original multiplier intervals, diagnostic only.')

fig,axs=plt.subplots(1,3,figsize=(12.5,4.5))
for ax,o in zip(axs,OUTCOMES):
 for v in vn:
  z=trend[(trend.variant==v)&(trend.outcome==o)]
  ax.plot(z.k,z.adjusted_est,marker='s',color=colors[v],label='Original' if v=='original' else 'Exclude two')
 ax.axhline(0,color='black',ls='--',lw=.7);ax.set(title=names[o],xlabel='Assumed persistence fraction k',ylabel='Adjusted log-point contrast');ax.legend(fontsize=9)
fig.suptitle('Trend-persistence scenarios')
save(fig,'04_trend_scenarios','Point scenarios only, not causal corrections or confidence intervals. Bias = five-year relative slope × k × elapsed years.')

methodnames={'original_multiplier':'Original multiplier','stacked_WCR':'Stacked WCR','seven_means_t6':'Seven-means t(6)'}
methodcolors=['#9e2636','#1d577b','#66704b']
fig,axs=plt.subplots(2,3,figsize=(12.5,8),sharey=True)
for row,v in enumerate(vn):
 for ax,o in zip(axs[row],OUTCOMES):
  for j,(m,col) in enumerate(zip(methodnames,methodcolors)):
   z=sim[(sim.variant==v)&(sim.outcome==o)&(sim.method==m)].sort_values('innovation_rho')
   x=z.innovation_rho+(j-1)*.012
   ax.errorbar(x,100*z.rejection_rate,yerr=[100*(z.rejection_rate-z.mc95_lo),100*(z.mc95_hi-z.rejection_rate)],fmt='s-',color=col,ms=4,capsize=3,label=methodnames[m])
  ax.axhline(5,color='black',ls='--',lw=.8);ax.set(title=names[o],xlabel='Within-group innovation correlation',ylabel='Rejection rate (%)',xticks=[0,.3,.6],ylim=(0,23))
 axs[row,0].text(0,1.15,vn[v],transform=axs[row,0].transAxes,fontsize=12)
axs[0,0].legend(fontsize=8)
fig.suptitle('Zero-effect simulations: nominal 5% tests')
save(fig,'05_simulation_calibration','4,000 panels per condition, fresh Webb draws per panel. Bars: Wilson Monte Carlo 95% intervals. Parametric diagnostics only.')

fig,axs=plt.subplots(2,3,figsize=(12.5,8),sharex=True)
for row,v in enumerate(vn):
 for ax,o in zip(axs[row],OUTCOMES):
  z=dynamic[(dynamic.variant==v)&(dynamic.outcome==o)]
  ax.errorbar(z.event_time,z.est,yerr=[z.est-z.ci_lo_wild,z.ci_hi_wild-z.est],fmt='s',color='#9e2636',ecolor='#315e85',capsize=2,ms=3)
  ax.axhline(0,color='black',ls='--',lw=.7);ax.axvline(0,color='.6',ls=':',lw=.8)
  ax.set(title=names[o],xlabel='Years relative to nationwide availability',ylabel='Log points')
 axs[row,0].text(0,1.15,vn[v],transform=axs[row,0].transAxes,fontsize=12)
fig.suptitle('Event-time contrasts with crop-specific pre-pilot baselines')
save(fig,'06_event_study','Stored original multiplier pointwise intervals. Pre-event crop composition varies. Transition observations omitted, not interpolated.')

fig,axs=plt.subplots(2,2,figsize=(10,7))
for row,crop in enumerate(['spring_napa','spring_radish']):
 z=panel[(panel.crop_id==crop)&panel.year.between(2005,2020)]
 for col,(var,label) in enumerate([('area_ha','Area (ha)'),('production_t','Production (tonnes)')]):
  ax=axs[row,col];ax.plot(z.year,z[var],color='#9e2636',marker='s',ms=4)
  ax.axvline(2014,color='.5',ls='--');ax.set(title=crop.replace('_',' ').title(),ylabel=label,xlabel='Year')
fig.suptitle('Published general-spring series around 2014')
save(fig,'07_spring_series','Values from the existing panel. A visible break does not establish reclassification; no spring/winter combination is applied.')

def table(df):return df.to_html(index=False,border=0,float_format=lambda x:f'{x:,.4f}',classes='data')
def figblock(name,caption):
 b=base64.b64encode((F/(name+'.png')).read_bytes()).decode()
 return f'<figure><img src="data:image/png;base64,{b}"><figcaption>{caption}</figcaption></figure>'
baseline=main[main.method=='original_multiplier'][['variant','outcome','est','se','ci_lo','ci_hi','p','contributing_controls']]
ranges=dates.groupby(['variant','outcome','window']).agg(min_est=('est','min'),max_est=('est','max'),min_p=('p_wild','min')).reset_index()
simrange=sim.groupby(['variant','method']).rejection_rate.agg(['min','max']).reset_index()
original_prod=baseline[(baseline.variant=='original')&(baseline.outcome=='ln_production')].iloc[0]
excluded_prod=baseline[(baseline.variant=='exclude_spring')&(baseline.outcome=='ln_production')].iloc[0]
md=f'''# 재분석 결과 — 2026년 9월 30일

## 결과

- 기존 패널의 연간 처리품목 7개를 유지하고, 원 대조군과 일반봄배추·일반봄무 제외 대조군을 모두 계산했다.
- 생산량 점추정: {original_prod.est:.6f} → {excluded_prod.est:.6f} log points (지수 변환 약 {100*np.expm1(original_prod.est):.1f}% → {100*np.expm1(excluded_prod.est):.1f}%). 원래 추론의 p는 {original_prod.p:.4f} → {excluded_prod.p:.4f}. 유의성 확보가 아니라 비교집단 민감성이 확인됐다.
- 시점 민감도 60개 결과(두 대조군 × 세 결과변수 × 다섯 시점 규칙 × 두 관측창)에서 최소 원래 방식 p = {dates.p_wild.min():.4f}. 이는 이미 결과를 본 뒤 실시한 탐색·민감도 분석이며 독립적인 확증 검정이 아니다. 같은 기준 분석이 여러 표에서 반복되므로 60개의 독립 가설을 뜻하지 않는다.
- 원래 비교집단의 생산량 점추정은 마지막 5년 상대 추세가 약 {trend[(trend.variant=='original')&(trend.outcome=='ln_production')].zero_crossing_k.iloc[0]*100:.1f}% 지속된다는 시나리오에서 0을 지난다. 이는 확률·유의성 임계점이나 실제 편향 추정치가 아니다. 음의 zero_crossing_k는 k≥0 범위에서 부호가 바뀌지 않음을 뜻한다.
- 18개 자료생성과정 조건, 조건당 4,000회, 총 72,000개 영효과 패널을 모의실험했다. 세 절차 각각 같은 패널을 평가했다. 전체 기각률 범위: 원 multiplier {sim[sim.method=='original_multiplier'].rejection_rate.min():.1%}–{sim[sim.method=='original_multiplier'].rejection_rate.max():.1%}, WCR {sim[sim.method=='stacked_WCR'].rejection_rate.min():.1%}–{sim[sim.method=='stacked_WCR'].rejection_rate.max():.1%}, 일곱 품목 t(6) {sim[sim.method=='seven_means_t6'].rejection_rate.min():.1%}–{sim[sim.method=='seven_means_t6'].rejection_rate.max():.1%}. 명목 5%보다 높았다. 어느 방법도 이 점검으로 신뢰할 수 있는 주 추론이라고 선정하지 않는다.

## 논문에 사용할 수 있는 해석

현재 전국 품목 패널의 비교에서는 보험 공급 이후 생산량·재배면적·단수의 변화가 정밀하게 식별되지 않았다. 면적과 생산량 점추정의 부호는 특정 대조품목 포함 여부에 민감하며, 고정 구성 사전 궤적과 추세 시나리오는 평행추세 가정에 대한 우려를 보여준다. 적은 처리품목 수와 품목 간 의존성을 고려한 모의실험에서도 검토한 추론 절차의 과다기각이 관찰됐다. 이 결과는 보험의 효과가 없음을 입증하지 않으며, 농가 소득 안정이나 실제 가입의 인과효과를 측정하지 않는다.

## 실행·검증 구분

- Python 실행: 기술통계, 원단위/로그, 두 대조군, 정책연도 공통 ±1년, 공통 관측창 0–8년, 원 창 0–9년, 고정 사전 궤적, 기울기 시나리오, 정확히 같은 계수를 갖는 누적 차분 회귀와 세 추론 방법, 모의실험, 그림.
- Stata: do-file 작성, 미실행. 그림 PDF/PNG는 Python으로 생성했으며 Stata 산출물로 표시하지 않는다.
- 검증: 원 추정치·SE·p 재현; 선형 가중치 일치; 합성 결과변수와 literal WLS/부트스트랩 재적합 일치. 수치 오차는 numerical_checks.csv와 simulation_checks.csv에 기록.
- 원 KOSIS 원파일 재실행, 공식 통계 정의·과거 판매기간 확정은 수행하지 않았다. Claude 원자료 대조 로그는 저자의 실행 증거로 보존했다.
- R/Rambachan–Roth는 실행하지 않았다. staggered adoption 자체가 적용 불가 이유는 아니다. 이 설계의 기준시점·사전계수 구성·공백과 공분산에 맞는 제약의 정당화가 필요하다.

## 결과 파일 사용 시 주의

main_inference.csv에서 stacked_WCR의 p는 귀무가설 0에 대한 restricted bootstrap-t이다. 그 행의 CI는 별도 cluster-t 구간이며 WCR 역산 구간이 아니다. 시뮬레이션 WCR null_inclusion은 0이 검정 역산 집합에 속하는 비율만 계산한 것이다. 숫자가 넓거나 p가 크다는 이유로 더 타당한 추론이 되지는 않는다.

기술통계는 표본의 품목-연도별 무가중 요약이다. 추정량의 대비 가중치와 다르다. 집단은 중첩될 수 있으므로 N을 합산하지 않는다. control_clean_context는 맥락용이며 모든 셀이 효과 추정에 쓰이지 않는다.

모의실험은 clean TWFE 잔차에서 추정한 SD·AR(1)를 고정한다. 모수 추정 오차와 모든 가능한 오차과정을 포함하지 않는다. ρ는 작물군 내 혁신오차 상관이며 수준 상관과 다를 수 있다. 결론은 해당 자료생성과정 아래의 성능이다. 실제 p-value를 보정하는 계수로 사용하지 않는다.

## 남은 외부 확인

1. 일반봄 계열의 2014년 전후 정의와 2010년 겨울배추 제외 주석: 공식 답변 필요. 합산 계열 미채택.
2. 2008–2015년 품목별 판매기간·최초 보장 수확연도: 현재 연도 코딩의 불확실성 지속.
3. 소득 안정이 중심 질문이라면 소득·보험금·가입 또는 지역별 노출 자료와 식별 설계를 별도로 확보해야 한다. 현재 분석으로 소득 안정 결론을 대체하지 않는다.

## 재실행

저장소 루트에서 Python(numpy, pandas, scipy, matplotlib)으로 run_analysis.py → run_simulation.py → build_report.py 순서. 정확한 명령은 README.md. 기존 결과 및 감사 폴더를 덮어쓰지 않는다.
'''
(HERE/'RESULTS_KO.md').write_text(md)
body='<h1>농작물재해보험 재분석</h1><p class="sub">2026.09.30 · 결과 확인 후 민감도 분석 · 전국 품목 패널</p>'
body+='<div class="lead"><b>현재 자료로 효과의 방향과 크기를 정밀하게 확정하기 어렵다.</b><p>비교집단을 바꾸면 면적·생산량 점추정의 부호가 달라진다. 세 추론 절차 모두 설정한 영효과 모의실험에서 명목 5%보다 자주 기각했다.</p></div>'
body+='<h2>1. 원 대조군과 두 품목 제외 비교</h2>'+table(baseline)+figblock('01_main_comparison','그림 1. 원 multiplier 구간은 추론의 타당성이 확정된 구간이 아니다.')
body+='<h2>2. 사전 궤적과 사건연구</h2>'+figblock('02_balanced_pretrends','그림 2. 같은 일곱 처리품목과 품목별 고정 대조군. 인과 검정이 아닌 기술적 진단.')+figblock('06_event_study','그림 3. 전환기간을 보간하지 않았다. 사건연구의 사전계수별 처리품목 구성은 달라진다.')
body+='<h2>3. 처치 시점 민감도</h2><p>0–8년 창에서는 일곱 품목이 모두 관측된다. 0–9년 창의 national +1은 고추의 마지막 해를 관측하지 못한다. 두 창을 모두 제공한다.</p>'+table(ranges)+figblock('03_date_sensitivity','그림 4. 모든 처리품목의 시점을 함께 이동시킨 결과. 실제 연도 확인을 대체하지 않는다.')
body+='<h2>4. 추세 지속 시나리오</h2>'+table(trend[['variant','outcome','k','adjusted_est','zero_crossing_k']])+figblock('04_trend_scenarios','그림 5. k는 연간 상대 기울기가 유지된다고 가정한 비율. 확률이나 신뢰수준이 아니다.')
body+='<h2>5. 추론 모의실험</h2><p>18조건 × 4,000회. 각 영효과 패널을 세 절차로 평가했다. 아래 범위는 각 대조군/방법에서 세 결과변수와 세 상관 설정에 걸친 범위다.</p>'+table(simrange)+figblock('05_simulation_calibration','그림 6. 세 절차 모두 추론의 한계가 남는다. WCR의 보수성을 일반적으로 가정하지 않는다.')
body+='<details><summary>실제 자료의 세 추론 절차 결과 전체</summary>'+table(main)+'</details>'
body+='<h2>6. 기술통계</h2><p>N은 품목-연도 수, SD는 그 관측치들의 산포다. 각 집단은 중첩될 수 있다. 같은 관측셀인 세 설계 중 생산량 설계 기준을 표시했다.</p>'
for v in vn:
 z=desc[(desc.variant==v)&(desc.design_outcome=='ln_production')&(~desc.variable.str.startswith('ln_'))]
 body+=f'<h3>{vn[v]}</h3>'+table(z[['group','variable','N','ncrops','mean','sd','min','max']])
body+='<h2>7. 아직 확정하지 않은 원자료 정의</h2>'+figblock('07_spring_series','그림 7. 현재 패널 값. 2014년 전후의 변화가 정의 변경인지 실제 변화인지는 공식 확인이 필요하다.')
body+='<h2>8. 실행 상태와 해석 범위</h2><p>위 계산과 그림은 Python 실행 결과다. Stata 코드는 제공하지만 실행하지 않았다. 기존 감사의 원 KOSIS 파일 검증을 이번에 재실행한 것은 아니다. 공식 정책연도와 자료 정의 문제는 남아 있다.</p><p>계수의 수치 재현은 인과 식별 또는 표준오차의 유효성을 입증하지 않는다. 생산량·면적·단수 분석을 소득 안정 효과로 해석하지 않는다.</p><p>전체 방법·검증·한계는 RESULTS_KO.md, PLAN.md 및 CSV에 기록했다.</p>'
body+='<h2>방법 출처</h2><p><a href="https://doi.org/10.1111/ectj.12107">MacKinnon &amp; Webb (2018)</a>; <a href="https://www.econ.queensu.ca/research/working-papers/1404">Few treated clusters and bootstrap inference</a>; <a href="https://github.com/asheshrambachan/HonestDiD">HonestDiD 공식 저장소</a>.</p>'
css='body{font-family:"Malgun Gothic",Arial,sans-serif;max-width:1180px;margin:40px auto;padding:0 24px;color:#202b34;line-height:1.7}h1{font-size:32px}h2{margin-top:44px;border-bottom:1px solid #c8d0d6;padding-bottom:9px}h3{margin-top:24px}.sub{color:#657380}.lead{background:#eef3f6;padding:22px;border-left:4px solid #315e85}table{border-collapse:collapse;font-size:12px;width:100%;display:block;overflow-x:auto}th,td{padding:7px 9px;text-align:right;white-space:nowrap}thead{border-top:2px solid #333;border-bottom:1px solid #777}tbody tr:last-child{border-bottom:2px solid #333}td:first-child,th:first-child{text-align:left}figure{margin:26px 0}img{width:100%;height:auto}figcaption{font-size:13px;color:#56616c}summary{cursor:pointer;font-weight:bold}a{color:#1d577b}'
(HERE/'report.html').write_text('<!doctype html><html lang="ko"><meta charset="utf-8"><title>농작물재해보험 재분석</title><style>'+css+'</style><body>'+body+'</body></html>')
print('REPORT AND SEVEN FIGURES COMPLETE')
