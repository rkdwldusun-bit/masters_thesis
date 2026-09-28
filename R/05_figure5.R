# [Figure 5] Relative farm-gate price index (reduced form, secondary)
# Reads verified_results/verified_results_dynamic.csv; no estimation here.

source("R/00_theme_thesis.R")
source("R/lib/plot_event_study.R")

D <- fread(file.path(VERIFIED, "verified_results_dynamic.csv"))
d <- D[sample == "price" & spec == "CS-A main (exact match, annual linking rule)"]

TR <- fread(file.path(VERIFIED, "verified_treatment_coding.csv"))
pr <- TR[crop_id %in% unique(unlist(strsplit(d$treated_crops, ";")))]
ref_txt <- sprintf("e = \u2212%d to \u2212%d", -min(pr$reference_event_time), -max(pr$reference_event_time))

p <- plot_event_study(d, ylab = "Log relative farm-gate price index") +
  labs(title = fig_title("fig5", "Relative Farm-Gate Prices: Reduced-Form Estimated Changes Associated with Insurance Expansion (Secondary)"),
       caption = wrap(paste(
         "Note: Treated: Onion, Sweet potato, Garlic, Red pepper (exact item match, annual linking rule). Controls: Red bean, Cabbage,",
         "Carrot, Ginger, Sesame, Perilla, Peanut, each before its first pilot. Outcome: annual mean of the quarterly ratio of the crop",
         "farm-gate price index to the linked all-farm-output price index (a relative price, not a CPI-deflated real price);",
         "1980–2004 from the 2005=100 crop series rebased to 2020=100 over 2005Q1–2012Q4, 2005–2024 from the 2020=100 series.",
         paste0("Custom group-time difference-in-differences; reference year = final clean pre-pilot year (", ref_txt, ");"),
         "crop-specific transition years omitted. Only four treated crops; prices and production are jointly determined, so",
         "estimates are reduced-form associations. 95% crop-level wild bootstrap intervals (custom procedure).",
         "Source: KOSIS farm-gate price index tables DT_1J49 and DT_1J60; author's calculations."), NOTE_WIDTH))

save_thesis_fig(p, "fig5", "fig5_price_event_study", height = 6.8,
                data = d[, .(outcome, event_time, period, est, ci_lo_wild, ci_hi_wild, n_treated)])
