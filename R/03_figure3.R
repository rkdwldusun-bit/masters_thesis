# [Figure 3] Robustness comparison, annual crops
# Reads verified_results/verified_results_summary.csv; no estimation here.

source("R/00_theme_thesis.R")
source("R/lib/plot_forest.R")

S <- fread(file.path(VERIFIED, "verified_results_summary.csv"))
rows <- c("CS-A (preferred)"                                         = "Preferred specification",
          "Dates: product-table nationwide year"                     = "Treatment date: product-table nationwide year",
          "Dates: pilot-year clock (no transition exclusion)"        = "Treatment date: first pilot year",
          "Controls: excl. other pulses"                             = "Controls: excluding other pulses",
          "Controls: excl. likely spillover (leaf lettuce, spinach, malting barley)" = "Controls: excluding likely spillover crops",
          "Controls: field crops only"                               = "Controls: field crops only",
          "Controls: excl. uncertain seasonal forms"                 = "Controls: excluding uncertain seasonal forms",
          "Leave out cohort 2012"                                    = "Leave out 2012 cohort (Soybean, Onion)",
          "Leave out cohort 2013"                                    = "Leave out 2013 cohort",
          "Leave out cohort 2015"                                    = "Leave out 2015 cohort (Red pepper)")
lv <- vapply(rows, function(z) paste(strwrap(z, 32), collapse = "\n"), "")
d <- S[sample == "annual" & spec_internal %in% names(rows)]
d[, row := lv[spec_internal]]
d[, `:=`(lo = ci_lo_wild_py, hi = ci_hi_wild_py)]
d[, panel := factor(outcome_internal, levels = c("ln_area", "ln_yield", "ln_production"), labels = c("A. Area", "B. Yield", "C. Production"))]
d[, preferred := spec_internal == "CS-A (preferred)"]
# numbers quoted in the note are read from the verified files, not typed
loo <- S[sample == "annual" & outcome_internal == "ln_production" & grepl("^Leave out [A-Z]", spec_internal) & !grepl("cohort", spec_internal)]
lo_row <- loo[which.min(est)]; hi_row <- loo[which.max(est)]
fld <- S[sample == "annual" & spec_internal == "Controls: field crops only" & outcome_internal == "ln_production"]
sea <- S[sample == "annual" & spec_internal == "Controls: excl. uncertain seasonal forms" & outcome_internal == "ln_production"]
num <- function(x) sub("^-", "\u2212", sprintf("%.3f", x))

p <- plot_forest(d, lv) +
  labs(x = "Average estimated change, e = 0 to 9 (log points)",
       title = fig_title("fig3", "Annual Crops: Robustness of the Average Estimated Change after Nationwide Availability"),
       caption = wrap(paste(
         "Note: Custom group-time difference-in-differences with clean not-yet-treated and never-treated controls; reference year =",
         sprintf("final clean pre-pilot year. Field crops only: %d control series (%d clusters); excluding uncertain seasonal forms: %d control series.",
                 fld$n_controls_listed, fld$G, sea$n_controls_listed),
         sprintf("Leaving out single treated crops moves production from %s (%s) to %s (%s); see the results table.",
                 num(lo_row$est), sub("Leave out ", "", lo_row$spec_internal), num(hi_row$est), sub("Leave out ", "", hi_row$spec_internal)),
         "95% crop-level wild bootstrap intervals (Webb weights, 9,999 draws; custom procedure).",
         "Estimates are associations, not established causal effects.",
         "Source: KOSIS Crop Production Survey (national series); author's calculations."), NOTE_WIDTH))

save_thesis_fig(p, "fig3", "fig3_annual_robustness", height = 9,
                data = d[, .(spec_internal, outcome_internal, est, lo, hi)])
