* Reproducible graphs from executed Python CSVs. NOT EXECUTED in authoring environment.
* No re-estimation, CI replacement, missing-event interpolation, or invented common reference year.
set scheme s2color
capture graph set window fontface "Times New Roman"
capture program drop savefig
program define savefig
 args filename
 graph save "$FIG/`filename'.gph", replace
 graph export "$FIG/`filename'.pdf", replace
 graph export "$FIG/`filename'.png", replace width(2400)
end

foreach v in original exclude_spring {
 foreach o in ln_area ln_yield ln_production {
  import delimited "$SRC/event_study.csv", clear varnames(1) encoding(utf8)
  keep if variant=="`v'" & outcome=="`o'"
  isid event_time
  export delimited using "$FIG/event_input_`v'_`o'.csv", replace
  twoway (rcap ci_lo_wild ci_hi_wild event_time, lcolor(navy)) ///
   (scatter est event_time, msymbol(square) mcolor(cranberry) msize(small)), ///
   yline(0, lpattern(dash) lcolor(gs6)) xline(0, lpattern(dot) lcolor(gs10)) ///
   graphregion(color(white)) plotregion(color(white)) legend(off) ///
   title("`o': `v'") xtitle("Years relative to nationwide availability") ytitle("Log points") ///
   note("Crop-specific final pre-pilot baselines. Varying pre-event crop composition." ///
        "Stored multiplier pointwise intervals; inference remains diagnostic.")
  savefig event_`v'_`o'

  import delimited "$SRC/balanced_pretrends.csv", clear varnames(1) encoding(utf8)
  keep if variant=="`v'" & outcome=="`o'"
  bysort pilot_event: egen mean_rel=mean(relative_log)
  local layers ""
  quietly levelsof crop, local(crops) clean
  foreach c of local crops {
   local layers `"`layers' (line relative_log pilot_event if crop=="`c'", sort lcolor(gs12) lwidth(thin))"'
  }
  bysort pilot_event: gen byte first=_n==1
  twoway `layers' (connected mean_rel pilot_event if first, sort lcolor(navy) mcolor(cranberry) msymbol(square)), ///
   yline(0, lpattern(dash) lcolor(gs6)) legend(off) graphregion(color(white)) plotregion(color(white)) ///
   title("`o': `v'") xtitle("Years relative to pilot") ytitle("Relative log change") ///
   note("Same seven crops; fixed donors within each crop. Descriptive, no confidence band.")
  savefig pre_`v'_`o'

  import delimited "$SRC/date_sensitivity.csv", clear varnames(1) encoding(utf8)
  keep if variant=="`v'" & outcome=="`o'" & window=="0_8"
  gen x=.
  replace x=1 if date_scenario=="original"
  replace x=2 if date_scenario=="pilot_minus1"
  replace x=3 if date_scenario=="pilot_plus1"
  replace x=4 if date_scenario=="national_minus1"
  replace x=5 if date_scenario=="national_plus1"
  assert !missing(x)
  twoway (rcap ci_lo_wild ci_hi_wild x, lcolor(navy)) (scatter est x, msymbol(square) mcolor(cranberry)), ///
   xlabel(1 "Base" 2 "Pilot -1" 3 "Pilot +1" 4 "National -1" 5 "National +1", angle(25)) ///
   yline(0, lpattern(dash) lcolor(gs6)) legend(off) graphregion(color(white)) plotregion(color(white)) ///
   title("`o': `v'") xtitle("") ytitle("Log points") ///
   note("Common event support 0-8. All seven treated dates shifted together. Diagnostic intervals.")
  savefig dates_`v'_`o'

  import delimited "$SRC/simulation_calibration.csv", clear varnames(1) encoding(utf8)
  keep if variant=="`v'" & outcome=="`o'"
  foreach x in rejection_rate mc95_lo mc95_hi {
   replace `x'=100*`x'
  }
  twoway (rcap mc95_lo mc95_hi innovation_rho if method=="original_multiplier", lcolor(cranberry)) ///
   (connected rejection_rate innovation_rho if method=="original_multiplier", sort mcolor(cranberry) lcolor(cranberry)) ///
   (rcap mc95_lo mc95_hi innovation_rho if method=="stacked_WCR", lcolor(navy)) ///
   (connected rejection_rate innovation_rho if method=="stacked_WCR", sort mcolor(navy) lcolor(navy)) ///
   (rcap mc95_lo mc95_hi innovation_rho if method=="seven_means_t6", lcolor(olive)) ///
   (connected rejection_rate innovation_rho if method=="seven_means_t6", sort mcolor(olive) lcolor(olive)), ///
   yline(5, lpattern(dash) lcolor(gs6)) xlabel(0 .3 .6) ///
   legend(order(2 "Original multiplier" 4 "Stacked WCR" 6 "Seven-means t(6)") rows(2)) ///
   graphregion(color(white)) plotregion(color(white)) title("`o': `v'") ///
   xtitle("Within-group innovation correlation") ytitle("Rejection rate (%)") ///
   note("4,000 null panels per condition. Wilson Monte Carlo intervals. Parametric diagnostics only.")
  savefig simulation_`v'_`o'
 }
}

foreach o in ln_area ln_yield ln_production {
 import delimited "$SRC/main_inference.csv", clear varnames(1) encoding(utf8)
 keep if outcome=="`o'" & method=="original_multiplier"
 gen x=cond(variant=="original",1,2)
 twoway (rcap ci_lo ci_hi x, lcolor(navy)) (scatter est x, msymbol(square) mcolor(cranberry)), ///
  yline(0, lpattern(dash) lcolor(gs6)) xlabel(1 "Original" 2 "Exclude two") xtitle("") ytitle("Log points") ///
  title("`o'") legend(off) graphregion(color(white)) plotregion(color(white)) ///
  note("Events 0-9. Stored original multiplier intervals; not validated causal inference.")
 savefig main_`o'
 import delimited "$SRC/trend_scenarios.csv", clear varnames(1) encoding(utf8)
 keep if outcome=="`o'"
 twoway (connected adjusted_est k if variant=="original", sort mcolor(cranberry) lcolor(cranberry)) ///
  (connected adjusted_est k if variant=="exclude_spring", sort mcolor(navy) lcolor(navy)), ///
  yline(0, lpattern(dash) lcolor(gs6)) xlabel(0 .5 1) xtitle("Assumed persistence fraction k") ytitle("Adjusted log contrast") ///
  legend(order(1 "Original" 2 "Exclude two")) graphregion(color(white)) plotregion(color(white)) ///
  title("`o'") note("Point scenarios only. Not bias estimates or confidence intervals.")
 savefig scenario_`o'
}

foreach c in spring_napa spring_radish {
 foreach x in area_ha production_t {
  import delimited "$ROOT/verified_results/verified_master_panel.csv", clear varnames(1) encoding(utf8)
  keep if crop_id=="`c'" & inrange(year,2005,2020)
  twoway connected `x' year, sort msymbol(square) mcolor(cranberry) lcolor(navy) ///
   xline(2014, lpattern(dash) lcolor(gs8)) legend(off) graphregion(color(white)) plotregion(color(white)) ///
   title("`c': `x'") xtitle("Year") note("Existing panel. Statistical definition around 2014 remains unresolved.")
  savefig raw_`c'_`x'
 }
}
