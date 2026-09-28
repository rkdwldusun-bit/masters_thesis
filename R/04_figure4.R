# [Figure 4] Perennial fruit: orchard area and production (suggestive)
# Reads verified_results/verified_results_dynamic.csv; no estimation here.

source("R/00_theme_thesis.R")
source("R/lib/plot_event_study.R")

D <- fread(file.path(VERIFIED, "verified_results_dynamic.csv"))
d <- D[sample == "fruit" & spec == "CS-A (preferred)"]
d[, panel := factor(outcome, levels = c("ln_area_harmonized", "ln_production"),
                    labels = c("A. Orchard area (log; controls: log cultivated area)", "B. Production (log)"))]

# dates and ranges quoted in the note are read from the verified treatment table
TR <- fread(file.path(VERIFIED, "verified_treatment_coding.csv"))
fr <- TR[crop_id %in% unique(unlist(strsplit(d$treated_crops, ";")))][order(national_year, crop)]
treated_txt <- paste(fr[, .(t = paste0(paste(crop, collapse = ", "), " (", national_year[1], ")")), by = national_year]$t, collapse = "; ")
nyt <- fr[crop_id %in% c("astringent_persimmon", "plum")]
nyt_txt <- paste0(nyt$crop, " (to ", nyt$pilot_year - 1, ")", collapse = " and ")
ref_txt <- sprintf("e = \u2212%d to \u2212%d", -min(fr$reference_event_time), -max(fr$reference_event_time))

p <- plot_event_study(d, facet = "panel", ncol = 1) +
  labs(title = fig_title("fig4", "Perennial Fruit: Estimated Changes Associated with Insurance Expansion, 1991–2024 (Suggestive Only)"),
       caption = wrap(paste(
         paste0("Note: Treated (nationwide year): ", treated_txt, "."),
         "The comparison group consists primarily of annual crops, while later-treated fruit crops may also serve as not-yet-treated",
         paste0("controls during their clean pre-pilot periods: ", nyt_txt, " contribute in some comparisons at early event times."),
         "No never-treated perennial series exists; annual crops are not comparable perennial controls, and orchard area (a stock of",
         "trees) is compared with annual cultivated area. Pre-pilot estimates rise",
         "steadily and the post-period path continues that slope, so the estimates are suggestive at most. Sweet and Astringent",
         "persimmon series begin in 1998. Custom group-time difference-in-differences; reference year = final clean pre-pilot year",
         paste0("(", ref_txt, "); crop-specific transition years omitted. 95% crop-level wild bootstrap intervals (custom procedure)."),
         "Source: KOSIS Crop Production Survey (national series); author's calculations."), 108))

save_thesis_fig(p, "fig4", "fig4_fruit_event_study", height = 8.6,
                data = d[, .(outcome, event_time, period, est, ci_lo_wild, ci_hi_wild, n_treated)])
