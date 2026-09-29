from pathlib import Path
import base64, json, html
import pandas as pd
R=Path(__file__).resolve().parent; O=R/'outputs'
S=pd.read_csv(O/'all_54_effect_tests.csv'); rep=pd.read_csv(O/'replication.csv')
def table(d): return d.to_html(index=False,border=0,float_format=lambda x:f'{x:.4f}',escape=True)
def img(name): return '<img alt="'+name+'" src="data:image/png;base64,'+base64.b64encode((O/name).read_bytes()).decode()+'">'
sections=[]
def add(title,text): sections.append(f'<section><h2>{title}</h2>{text}</section>')
add('판단', '''<p><strong>연간 작물 7개를 대상으로 정해둔 54개 효과 검정을 실행했으며, 보정 전에도 p&lt;0.05인 결과는 없었다.</strong>
최소 p-value는 0.2306이다. 이번 분석은 기존 결과를 본 뒤 수행한 탐색적 재분석이며 사전등록 연구가 아니다.
과수·가격·소득 안정성의 재분석은 이번 실행 범위에 포함되지 않는다.</p>
<p>기존 계수와 표준오차는 재현되었다. 동시에 자체 점수 기반 p-value의 모의실험에서 과다 기각이 발견되었다.
이를 근거로 실제 p-value의 정확한 편향을 계산할 수는 없지만, 기존 추론을 검증 없이 확정값으로 사용하는 것은 권하지 않는다.</p>''')
add('1. 기존 결과 재현',table(rep)+'''<p>동일한 원본 Python 추정 엔진을 추출하여 실행한 재현이다. 새로운 독립 추정법의 검증과 구분해야 한다.
점추정·표준오차 오차는 10⁻⁹ 미만이다. 기존 부트스트랩 난수 스트림 전체를 재연하지 않았으므로 p-value는 소폭 달라졌다.
고정 시드 20260929, 각 효과 검정 9,999회 Webb 추출을 사용했다.</p>''')
z=S[(S.method=='original_custom')&(S.clock=='national')&(S.base=='last')]
add('2. 효과가 특정 기간에만 나타나는가?',table(z[['outcome','horizon','est','se_cluster','p_wild','ci_lo_wild','ci_hi_wild']])+img('horizon_sensitivity.png')+'''<p>전국 도입 이후 0–2년, 3–5년, 6–9년을 별도로 분석했다. 어느 기간에서도 유의한 효과가 발견되지 않았다.
단기·중기·후기 평균은 서로 다른 추정대상이며, 이를 전체 10년 효과의 대체 결과로 임의 선택해서는 안 된다.
ln_area=재배면적, ln_yield=단수, ln_production=생산량. 계수·구간 단위는 로그포인트다.</p>''')
add('3. 품목별 선형추세를 통제하면?',table(S[S.method.str.startswith('TWFE')][['method','outcome','est','se_cluster','p_wild','p_cluster_t','ci_lo_cluster_t','ci_hi_cluster_t']])+'''<p>비처치 관측치와 전국 도입 후 0–9년의 처리 관측치만 사용한 고정효과 회귀를 비교했다.
품목별 선형추세를 넣으면 면적 계수는 0.243에서 −0.086으로, 생산량 계수는 0.215에서 −0.066으로 바뀐다.
둘 다 유의하지 않다. 이는 추세 가정에 대한 민감성이지 음의 보험효과가 입증된 결과가 아니다.</p>
<p>TWFE는 처리효과 이질성에 따른 가중 문제를 해결하지 못하며, 선형추세 통제는 실제 효과를 흡수할 수 있다.
따라서 이 분석들은 보조 진단이다. p_wild는 귀무가설을 부과한 wild cluster bootstrap-t,
해당 표의 신뢰구간은 별도의 군집 t 근사 구간이므로 부트스트랩 p-value와 정확히 대응하는 구간이 아니다.</p>''')
cr=pd.read_csv(O/'crop_mean_contrasts.csv')
add('4. 품목별 차이가 평균에 가려지는가?',table(cr[cr.outcome=='ln_production'][['crop','treated_change','control_change','contrast']])+'''<p>생산량의 평균 대비 차이는 양파 약 +0.406, 고추 약 −0.651 로그포인트로 반대 방향이다.
이 차이는 실제 보험효과의 이질성뿐 아니라 서로 다른 산업 추세·충격도 반영할 수 있다.
고추를 제거하거나 양파만 선택하는 근거가 되지는 않는다. 각 품목의 대조 차이에 대한 개별 유의성 탐색은 수행하지 않았다.</p>'''+img('raw_crop_trajectories.png'))
sl=pd.read_csv(O/'crop_pretrend_slopes.csv').groupby('outcome').pre_slope.agg(['mean','min','max']).reset_index()
add('5. 동일한 7개 품목으로 사전 추세 재점검',img('balanced_pretrends.png')+table(sl)+'''<p>시범사업 시점을 기준으로 −10~−1년을 사용했다. 모든 시점에서 처리품목은 같은 7개이며,
각 처리품목의 비교품목 구성도 이 기간 내에서 고정했다. 단, 처리품목마다 비교품목 집합은 다를 수 있다.
−1년의 차이를 0으로 정규화했다. 면적과 생산량의 상대적 상승 움직임은 구성을 고정해도 관찰된다.</p>
<p>기울기는 해당 사전기간에 대한 기술적 요약이며 검정통계량이나 보험효과가 아니다. 도입 뒤에도 같은 기울기가 계속된다는 증거도 아니다.
기존 공동검정 공분산의 랭크는 세 결과 모두 8/8이었다. 높은 공동검정 p-value를 단순한 특이행렬 문제로 설명할 근거는 발견하지 못했다.</p>''')
add('6. 자체 추론의 모의실험: 중요한 한계',table(pd.read_csv(O/'null_calibration.csv'))+'''<p><strong>실제 효과가 0인 가상 패널에서 명목 5% 검정의 기각률은 9.15~11.80%였다.</strong>
실제 분석과 같은 관측 셀·시점·가중을 유지하고, 품목 간 독립인 정상 AR(1) 오차를 생성했다.
rho는 연도 간 자기상관 계수(0, 0.7, 0.95)다. 각 조건 2,000개 패널, 패널별 1,999회 Webb 추출을 사용했다.
mc_se와 mc_95 구간은 고정된 부트스트랩 가중 추출 아래 모의실험 반복에 따른 불확실성이다.</p>
<p>추정량과 잔차가 자료의 선형함수라는 점을 이용해 점수 행렬을 계산했으며,
세 개의 별도 가상 패널을 원본 추정 엔진에 직접 넣어 계수·표준오차·p-value 일치를 확인했다.
이는 단순한 가상 조건에서도 검정 크기가 명목 수준과 다를 수 있다는 증거다.
실제 자료에서 보험효과의 부호, 정확한 p-value 왜곡, 모든 상황의 성능을 결정하지는 않는다.
모의실험에 근거한 임의 p-value 보정은 하지 않았다.</p>''')
add('7. 전체 54개 결과 — 선택적 생략 없음',table(S[['method','outcome','clock','base','horizon','est','se_cluster','p_wild','p_holm_all54']])+'''<p>국가 도입/시범사업 시계 × 기준연도 1개/최근 5개년 × 4개 사후기간 × 3개 결과 = 48개,
추세 유무 TWFE × 3개 결과 = 6개로 구성된다. 원래 주 분석 재현도 포함된다.
Holm 보정은 이번 54개 효과 검정에 적용했으며, 과거 저장소의 모든 분석까지 포함한 전체 연구의 선택 문제를 해소하지 않는다.
모든 보정 p-value가 1인 것은 유의성이 보정 때문에 사라졌다는 뜻이 아니다. 보정 전부터 모두 0.05보다 크다.
다중검정 보정은 식별·추론 오류를 해결하지 않는다.</p>''')
add('8. 다음 수정의 우선순위', '''<ol>
<li>전국 확대의 추가 효과와 최초 시범 도입의 효과 중 연구대상을 확정한다. 현재 전국 도입 기준 분석은 시범사업 전 기준연도부터의 긴 변화까지 포함한다.</li>
<li>추론을 재검토한다. 표준 추정법의 문서화된 구현으로 바꾸려면 시범사업 노출·처치 시점·결측 구조를 먼저 맞춰야 한다. 이번 실행은 표준 Callaway–Sant’Anna 패키지로 전환한 분석이 아니다.</li>
<li>지역×품목의 시범사업 도입·적용 자료를 확보할 수 있는지 검토한다. 실제 지역별 노출 차이가 있어야 새 식별 정보가 생긴다. 전국 품목 처치를 지역별로 복제한다고 독립적인 처치가 늘지는 않는다.</li>
<li>소득 안정성이라는 질문을 유지한다면 소득·수입 및 위험 지표가 필요하다. 생산량·면적 평균만으로 이를 입증할 수 없다.</li>
<li>자료 확장이 불가능하면 현재 결과를 생산 반응에 대한 제한적인 증거로 보고하고, 유의성을 목적으로 표본을 계속 변경하지 않는다.</li>
</ol><p>추론 개선은 p-value를 낮춘다는 보장이 없으며 더 보수적인 결론으로 이어질 수도 있다.</p>''')
add('9. 재현 및 파일 안내', '''<p>기준 커밋: <code>00b60931ef577aca690d0d3aa2fc4a4c3bed5e64</code>.
원자료·기존 분석 파일은 변경하지 않았다. 신규 파일은 <code>reanalysis_20260929/</code>에 있다.</p>
<pre>OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 python reanalysis_20260929/run_reanalysis.py
python reanalysis_20260929/build_report.py</pre>
<p>outputs/descriptive_stats.csv와 descriptive_by_crop.csv에는 관측치 수·평균·표준편차가 있다.
표준편차는 관측값의 분산 정도이며 회귀계수의 표준오차와 다르다. 회귀계수 표준오차는 all_54_effect_tests.csv에 있다.
run_manifest.json에는 입력 해시·실행환경·난수 시드가 있다.</p>
<p>확인하지 않은 사항: 원출처의 도입연도, 원자료 재수집, 개별 농가 가입, 지역별 정책·기상 충격, 실제 소득 안정성.
공식 방법 참고: <a href="https://bcallaway11.github.io/did/articles/multi-period-did.html">Callaway–Sant’Anna 문서</a>,
<a href="https://www.jonathandroth.com/assets/files/roth_pretrends_testing.pdf">Roth, Pretest with Caution</a>.</p>''')
css='body{font-family:Arial,"Noto Sans KR",sans-serif;max-width:1120px;margin:40px auto;padding:0 24px;line-height:1.75;color:#18283a}h1{font-size:30px}h2{font-size:23px;margin-top:42px}table{width:100%;border-collapse:collapse;font-size:13px;display:block;overflow-x:auto}th,td{padding:8px;border-bottom:1px solid #dbe2ea;text-align:right}th{background:#eaf1f8}td:first-child,th:first-child{text-align:left}img{width:100%;margin:16px 0}pre{background:#f1f5f8;padding:16px;overflow:auto}section{margin-bottom:32px}strong{color:#174d77}'
doc='<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>석사논문 재분석 결과 — 2026-09-29</title><style>'+css+'</style><body><h1>석사논문 재분석 결과</h1><p>2026년 9월 29일 · 연간 작물 7개 · 원자료 유지 · 탐색적 분석</p>'+''.join(sections)+'</body></html>'
(R/'reanalysis_report.html').write_text(doc)
print('Created',R/'reanalysis_report.html')
