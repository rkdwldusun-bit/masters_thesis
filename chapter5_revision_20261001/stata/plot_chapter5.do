* Chapter 5 figures from verified CSV exports. No estimation or new inference.
* NOT EXECUTED: Stata was unavailable in the authoring environment.
* Run from the repository root:
* do chapter5_revision_20261001/stata/plot_chapter5.do
version 17
clear all
set more off
local root "chapter5_revision_20261001"
capture mkdir "`root'/stata_exports"
local out "`root'/stata_exports"
capture log close
log using "`out'/plot_chapter5.log", text replace
set scheme s2color
local ys "ln_area ln_yield ln_production"
local titles "Area Yield Production"
local k = 0
foreach y of local ys {
    local ++k
    local title : word `k' of `titles'
    import delimited "`root'/outputs/pretrend_mean_paths.csv", clear varnames(1)
    keep if outcome == "`y'"
    keep variant pilot_event treated donor gap
    reshape wide treated donor gap, i(pilot_event) j(variant) string
    assert abs(treatedoriginal-treatedexclude_spring)<1e-10
    twoway (connected treatedoriginal pilot_event, lcolor(navy) mcolor(navy) msymbol(O)) ///
        (connected donororiginal pilot_event, lcolor(gs8) mcolor(gs8) msymbol(S)) ///
        (connected donorexclude_spring pilot_event, lcolor(orange_red) mcolor(orange_red) lpattern(dash) msymbol(T)), ///
        title("`title'", size(medsmall) pos(11)) ytitle("Log change") ///
        xtitle("Years relative to coded pilot; reference = -1") xlabel(-10(1)-1) ///
        yline(0, lcolor(gs12)) graphregion(color(white)) ///
        legend(order(1 "Treated crops" 2 "Original donors" 3 "Exclude spring series") size(vsmall) rows(1)) name(pre`k', replace)
}
graph combine pre1 pre2 pre3, cols(1) xsize(6.2) ysize(8) graphregion(color(white))
graph export "`out'/fig5_1_pretrends.png", width(2000) replace
graph export "`out'/fig5_1_pretrends.pdf", replace
local k = 0
foreach y of local ys {
    local ++k
    local title : word `k' of `titles'
    import delimited "`root'/outputs/crop_mean_contrasts.csv", clear varnames(1)
    keep if outcome == "`y'"
    keep variant crop_order crop_name contrast
    reshape wide contrast, i(crop_order crop_name) j(variant) string
    gen pos_original = crop_order - .09
    gen pos_excluded = crop_order + .09
    local labs "ylabel(1(1)7, nolabels)"
    if `k'==1 local labs `"ylabel(1 "Soybean" 2 "Onion" 3 "Sweet potato" 4 "Corn" 5 "Garlic" 6 "Spring potato" 7 "Red pepper", angle(0) labsize(small))"'
    twoway (scatter pos_original contrastoriginal, mcolor(navy) msymbol(O)) ///
        (scatter pos_excluded contrastexclude_spring, mcolor(orange_red) msymbol(D)), ///
        title("`title'", size(medsmall)) xtitle("Mean log contrast", size(small)) ///
        ytitle("") `labs' yscale(reverse) xline(0, lcolor(gs10)) ///
        legend(order(1 "Original" 2 "Exclude spring") size(vsmall) rows(1)) ///
        graphregion(color(white)) name(crop`k', replace)
}
graph combine crop1 crop2 crop3, cols(3) ycommon xsize(9) ysize(5) graphregion(color(white))
graph export "`out'/fig5_2_crop_contrasts.png", width(2400) replace
graph export "`out'/fig5_2_crop_contrasts.pdf", replace
local k = 0
foreach y of local ys {
    local ++k
    local title : word `k' of `titles'
    import delimited "`root'/outputs/post_event_points.csv", clear varnames(1)
    keep if outcome == "`y'"
    twoway (connected est event_time if variant=="original", lcolor(navy) mcolor(navy) msymbol(O)) ///
        (connected est event_time if variant=="exclude_spring", lcolor(orange_red) mcolor(orange_red) msymbol(D)), ///
        title("`title'", size(medsmall) pos(11)) ytitle("Log contrast") ///
        xtitle("Years relative to coded national crop year") xlabel(0(1)9) yline(0, lcolor(gs12)) ///
        legend(order(1 "Original donors" 2 "Exclude spring series") size(vsmall) rows(1)) ///
        graphregion(color(white)) name(post`k', replace)
}
graph combine post1 post2 post3, cols(1) xsize(6.2) ysize(8) graphregion(color(white))
graph export "`out'/fig5_3_post_contrasts.png", width(2000) replace
graph export "`out'/fig5_3_post_contrasts.pdf", replace
local k = 0
foreach y of local ys {
    local ++k
    local title : word `k' of `titles'
    import delimited "`root'/outputs/pretrend_crop_paths.csv", clear varnames(1)
    keep if outcome=="`y'" & variant=="original"
    local plots ""
    foreach c in soybean onion sweet_potato corn garlic spring_potato red_pepper {
        local plots `"`plots' (line gap pilot_event if crop=="`c'", sort)"'
    }
    twoway `plots', title("`title'", size(medsmall) pos(11)) ///
        ytitle("Relative log gap") xtitle("Years relative to coded pilot") xlabel(-10(1)-1) yline(0, lcolor(gs12)) ///
        legend(order(1 "Soybean" 2 "Onion" 3 "Sweet potato" 4 "Corn" 5 "Garlic" 6 "Spring potato" 7 "Red pepper") rows(2) size(vsmall)) ///
        graphregion(color(white)) name(gap`k', replace)
}
graph combine gap1 gap2 gap3, cols(1) xsize(6.2) ysize(8) graphregion(color(white))
graph export "`out'/figA5_1_crop_pretrends.png", width(2000) replace
graph export "`out'/figA5_1_crop_pretrends.pdf", replace
log close
