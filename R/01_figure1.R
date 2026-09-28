# [Figure 1] Annual-crop event study: area, yield, production
# Reads verified_results/verified_results_dynamic.csv; no estimation here.

source("R/00_theme_thesis.R")
source("R/lib/plot_event_study.R")

D <- fread(file.path(VERIFIED, "verified_results_dynamic.csv"))
d <- D[sample == "annual" & spec == "CS-A (preferred)" & outcome %in% c("ln_area", "ln_yield", "ln_production")]
d[, panel := factor(outcome, levels = c("ln_area", "ln_yield", "ln_production"),
                    labels = c("A. Area (log cultivated area)", "B. Yield (log yield per 10a)", "C. Production (log production)"))]

# control counts quoted in the note are read from the verified files
S <- fread(file.path(VERIFIED, "verified_results_summary.csv"))
s0 <- S[sample == "annual" & spec_internal == "CS-A (preferred)" & outcome_internal == "ln_production"]
e9 <- d[outcome == "ln_production" & event_time == 9]
n_contrib <- s0$G - s0$n_treated

p <- plot_event_study(d, facet = "panel", ncol = 1) +
  labs(title = fig_title("fig1", "Estimated Changes in Annual-Crop Area, Yield and Production Associated with Insurance Expansion, 1991–2024"),
       caption = wrap(paste(
         "Note: Custom group-time difference-in-differences with clean not-yet-treated and never-treated controls;",
         "reference year = each treated crop's final clean pre-pilot year (e = \u22128 to \u22124). Treated: Soybean, Onion, Sweet potato,",
         sprintf("Corn, Garlic, Spring potato, Red pepper (nationwide availability 2012\u20132015). Controls: %d listed annual crop series,", s0$n_controls_listed),
         sprintf("each used only before its own first pilot; %d contribute, and %d\u2013%d remain at e = 9.", n_contrib, e9$n_ctrl_min, e9$n_ctrl_max),
         "Crop-specific pilot-to-national transition years are omitted (not estimated); the e = \u22125 estimate rests on two crops.",
         "Estimates are associations, not established causal effects. Vertical bars: 95% crop-level wild bootstrap intervals",
         "(Webb weights, 9,999 draws; custom procedure).",
         "Source: KOSIS Crop Production Survey (national series); author's calculations."), 108))

save_thesis_fig(p, "fig1", "fig1_annual_event_study", height = 10.5,
                data = d[, .(outcome, event_time, period, est, ci_lo_wild, ci_hi_wild, n_treated, n_ctrl_min, n_ctrl_max)])
