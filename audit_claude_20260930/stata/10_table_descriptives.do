* 10_table_descriptives.do -- NOT EXECUTED (written without Stata access; revised 2026-09-30)
* Descriptive statistics (Mean, SD, Min, Max, N crop-years, number of crops) for the preferred annual-crop design.
* Groups are defined by the cells that ACTUALLY carry weight in the headline estimate
* (audit_claude_20260930/outputs/contributing_cells.csv, from scripts/03_contributing_cells.py),
* not by a generic "post" label. A control crop's own post-pilot years are never used and are not shown.
* Raw units (ha, kg/10a, t) are reported alongside logs.
* In the current sample the contributing cells are identical across the three outcomes
* (see scripts/03_contributing_cells.py output); the ln_production flags are used for all variables.

import delimited "$ROOT/audit_claude_20260930/outputs/contributing_cells.csv", clear varnames(1) encoding(utf8)
keep if outcome=="ln_production"
keep crop_id year in_theta theta_role
tempfile flags
save `flags'

import delimited "$RES/verified_master_panel.csv", clear varnames(1) encoding(utf8)
keep if inrange(year,1991,2024)
gen byte treated = inlist(crop_id,"soybean","onion","sweet_potato","corn","garlic","spring_potato","red_pepper")
keep if treated==1 | role=="control_pool"
merge 1:1 crop_id year using `flags', keep(master match) nogenerate
replace in_theta = 0 if missing(in_theta)
replace theta_role = "" if missing(theta_role)

* group indicators (built separately; a crop-year may belong to more than one)
gen byte g_tr_cleanpre = treated==1 & year < pilot_year
gen byte g_tr_base     = treated==1 & strpos(theta_role,"treated_base")>0
gen byte g_tr_post     = treated==1 & strpos(theta_role,"treated_post")>0
gen byte g_ct_used     = treated==0 & in_theta==1
gen byte g_ct_clean    = treated==0 & (missing(pilot_year) | year < pilot_year)
* g_tr_cleanpre : treated, all clean pre-pilot years
* g_tr_base     : treated, reference year (final clean pre-pilot year)
* g_tr_post     : treated, post-national years used (e = 0..9)
* g_ct_used     : controls, cells used in the headline estimate (base and target years)
* g_ct_clean    : controls, all clean (pre-own-pilot) cells -- context only

tempname H
postfile `H' str20 grp str20 variable double(N ncrops mean sd min max) using "$OUT/t_desc.dta", replace
foreach g in g_tr_cleanpre g_tr_base g_tr_post g_ct_used g_ct_clean {
  foreach v in area_ha yield_kg10a production_t ln_area ln_yield ln_production {
    quietly summarize `v' if `g'==1
    * store returned results BEFORE running any other r-class command
    local n  = r(N)
    local mu = r(mean)
    local s  = r(sd)
    local lo = r(min)
    local hi = r(max)
    if `n' > 0 {
      quietly levelsof crop_id if `g'==1 & !missing(`v'), clean
      local nc : word count `r(levels)'
      post `H' ("`g'") ("`v'") (`n') (`nc') (`mu') (`s') (`lo') (`hi')
    }
  }
}
postclose `H'
use "$OUT/t_desc.dta", clear
export delimited using "$OUT/t_desc.csv", replace
* Table notes: SD is dispersion across crop-years, not the standard error of an effect.
* Similar means or non-significant differences do not establish parallel trends.
