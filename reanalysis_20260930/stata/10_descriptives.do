* Recompute raw/log descriptives from the frozen panel and exported cell membership.
* NOT EXECUTED. Match t_desc_stata.csv against outputs/descriptive_stats.csv (design_outcome ln_production).
import delimited "$SRC/descriptive_cell_membership.csv", clear varnames(1) encoding(utf8)
keep if outcome=="ln_production"
isid variant group crop_id year
tempfile members
save `members'
import delimited "$ROOT/verified_results/verified_master_panel.csv", clear varnames(1) encoding(utf8)
isid crop_id year
merge 1:m crop_id year using `members', keep(match) assert(master match) nogenerate
tempname H
postfile `H' str20 variant str30 group str20 variable double(N ncrops mean sd min max) using "$OUT/t_desc_stata.dta", replace
foreach v in original exclude_spring {
 foreach g in treated_clean_pre treated_base treated_post control_used control_clean_context {
  foreach x in area_ha yield_kg10a production_t ln_area ln_yield ln_production {
   quietly summarize `x' if variant=="`v'" & group=="`g'"
   local n=r(N)
   local mu=r(mean)
   local sd=r(sd)
   local lo=r(min)
   local hi=r(max)
   quietly levelsof crop_id if variant=="`v'" & group=="`g'" & !missing(`x'), clean
   local nc : word count `r(levels)'
   post `H' ("`v'") ("`g'") ("`x'") (`n') (`nc') (`mu') (`sd') (`lo') (`hi')
  }
 }
}
postclose `H'
use "$OUT/t_desc_stata.dta", clear
export delimited using "$OUT/t_desc_stata.csv", replace
import delimited "$SRC/main_inference.csv", clear varnames(1) encoding(utf8)
export delimited using "$OUT/main_inference_stata.csv", replace
* p for stacked_WCR is WCR; its stored CI is cluster-t, NOT inverted WCR.
* These tables describe data and sensitivity. No significance stars are added.
