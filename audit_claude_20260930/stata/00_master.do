* 00_master.do  -- NOT EXECUTED (written without Stata access, 2026-09-30)
version 17
clear all
set more off
global ROOT "."                                   // repository root
global RES  "$ROOT/verified_results"
global OUT  "$ROOT/audit_claude_20260930/stata/out"
capture mkdir "$OUT"
log using "$OUT/master.log", replace text
display "Stata " c(stata_version) "  " c(current_date)
do "$ROOT/audit_claude_20260930/stata/10_table_descriptives.do"
do "$ROOT/audit_claude_20260930/stata/20_table_main.do"
do "$ROOT/audit_claude_20260930/stata/30_fig_event_study.do"
log close
