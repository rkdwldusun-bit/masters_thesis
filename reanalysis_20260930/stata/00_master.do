* Run from repository root. Stata 17+. NOT EXECUTED in the authoring environment.
version 17
clear all
set more off
set varabbrev off
global ROOT "."
global SRC "$ROOT/reanalysis_20260930/outputs"
global OUT "$ROOT/reanalysis_20260930/stata/out"
global FIG "$OUT/figures"
capture mkdir "$OUT"
capture mkdir "$FIG"
capture log close
log using "$OUT/master.log", text replace
display "Stata " c(stata_version) " " c(current_date)
do "$ROOT/reanalysis_20260930/stata/10_descriptives.do"
do "$ROOT/reanalysis_20260930/stata/20_figures.do"
log close
