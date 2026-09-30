* 30_fig_event_study.do -- NOT EXECUTED
* Plots stored bootstrap CIs at actual event_time; transition years are absent (not filled, not connected).
import delimited "$RES/verified_results_dynamic.csv", clear varnames(1) encoding(utf8)
keep if sample=="annual" & spec=="CS-A (preferred)"
foreach v in ln_area ln_yield ln_production {
  preserve
  keep if outcome=="`v'"
  export delimited using "$OUT/plotdata_`v'.csv", replace
  twoway (rcap ci_hi_wild ci_lo_wild event_time if event_time<0, lcolor(gs10)) ///
         (scatter est event_time if event_time<0, msymbol(square) mcolor(gs8)) ///
         (rcap ci_hi_wild ci_lo_wild event_time if event_time>=0, lcolor(navy)) ///
         (scatter est event_time if event_time>=0, msymbol(square) mcolor(cranberry)), ///
         yline(0, lpattern(dash) lcolor(gs8)) xline(-0.5, lpattern(dot) lcolor(gs10)) ///
         xtitle("Years relative to nationwide availability (e)") ytitle("Log points") ///
         legend(order(2 "Clean pre-pilot years" 4 "After nationwide availability") rows(1)) ///
         note("Reference: each crop's final clean pre-pilot year (e = -8 to -4). Crop-specific transition years omitted." ///
              "95% pointwise intervals from stored crop-level multiplier bootstrap.") ///
         graphregion(color(white)) plotregion(color(white))
  graph save "$OUT/fig_es_`v'.gph", replace
  graph export "$OUT/fig_es_`v'.pdf", replace
  graph export "$OUT/fig_es_`v'.png", replace width(2400)
  restore
}
