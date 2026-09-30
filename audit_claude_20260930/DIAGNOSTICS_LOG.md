# 진단 실행 기록

| 일시 | 실행 내용 | 결과 확인 전/후 | 채택 여부 | 수치 |
|---|---|---|---|---|
| 2026-09-29 | 원 엔진(`reanalysis_20260929/original_engine.py`), 검증 패널, 선호 사양(A)에서 대조군 spring_napa·spring_radish 제외 | 후 (주 결과를 본 뒤) | 미채택 (진단용) | area −0.041 [−0.293, 0.210], yield −0.032, production −0.074 [−0.369, 0.221] |
| 2026-09-29 | 같음, 추가로 autumn_radish 제외 | 후 | 미채택 | area −0.062 [−0.316, 0.192], yield −0.026, production −0.088 [−0.392, 0.216] |
| 2026-09-30 | 원 KOSIS 파일 행·열 대조, 조화 계열 산출 (`scripts/01_reconcile_2014_series.py`) | — (추정 아님) | 기록용 | `outputs/panel_vs_kosis_2014.csv`, `outputs/harmonized_spring_winter_series.csv` |

두 진단 추정은 로컬에서만 실행했고, 스크립트는 이 저장소에 없다. 재현하려면 `run_cs(P, o, ANN, [c for c in CTRL if c not in DROP], norm='A')`에 `RNG = default_rng(20260927)`을 쓴다.
| 2026-09-30 (개정 1) | `scripts/01_reconcile_2014_series.py` 재실행: 조화 규칙을 연도별로 명시하고, 겨울 작형의 공란 / 보고된 0 / 양수를 구분 | — (추정 아님) | 기록용 | 무 겨울: 2005–2010 공란, 2011–2013 원자료 '0', 2014+ 양수 / 배추 겨울: 2005–2013 공란, 2014+ 양수 |
| 2026-09-30 (개정 1) | `scripts/02_full_panel_check.py`: 전체 패널 수치 대조 | — (추정 아님) | 기록용 | 5,805셀: 일치 4,854, 양쪽 결측 951, 불일치 0 (`outputs/full_panel_check_log.txt`) |
| 2026-09-30 (개정 1) | `scripts/03_contributing_cells.py`: 선호 사양에서 가중치가 0이 아닌 셀을 추출. 추정치·SE·p는 계산하지 않음 | — (표본 정의) | 기록용 | 처리 7품목 77셀(기준 7, 사후 70) / 대조 22품목 284셀(기준 66, 목표 218). 세 결과변수에서 동일 |
