# Stata 구성안

**상태: 코드 작성만 했고 실행 검증은 하지 않았다.** 이 환경에는 Stata가 없다. (개정 1: 10_table_descriptives.do 수정, 역시 미실행)

실행 순서: `00_master.do` → `10_table_descriptives.do` → `20_table_main.do` → `30_fig_event_study.do`

원칙
- 입력은 `verified_results/*.csv`와, 향후 `audit_claude_20260930/outputs/`에 생길 결과 CSV뿐이다. Stata 안에서는 효과를 다시 추정하지 않는다.
- CI는 저장된 하한·상한을 그대로 그린다(`rcap lo hi event_time`). SE로 정규근사 CI를 만들지 않는다.
- x축은 실제 `event_time` 변수다. 전환기간은 채우지 않고, 사전·사후를 선으로 잇지 않는다.
- `.log`, `.gph`, `.pdf`, `.png`와 그래프 입력 CSV를 함께 저장한다. Stata 버전과 추가 패키지를 로그에 기록한다.
