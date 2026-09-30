* 20_table_main.do -- NOT EXECUTED
* Reads stored results; does not re-estimate. Column names follow verified_results_summary.csv.
import delimited "$RES/verified_results_summary.csv", clear varnames(1) encoding(utf8)
keep if sample=="annual" & spec_internal=="CS-A (preferred)"
keep outcome_thesis est se_cluster ci_lo_wild_py ci_hi_wild_py p_wild_py pre_p_boot_py n_treated g
gen contributing_controls = g - n_treated
export delimited using "$OUT/t_main.csv", replace
