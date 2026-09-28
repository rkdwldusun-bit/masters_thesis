# [Figure 2] Estimator comparison, annual crops
# Reads verified_results/verified_results_summary.csv; no estimation here.

source("R/00_theme_thesis.R")
source("R/lib/plot_forest.R")

S <- fread(file.path(VERIFIED, "verified_results_summary.csv"))
rows <- c("CS-A (preferred)"                                  = "Group-time DiD, final clean pre-pilot year (preferred)",
          "CS-B (mean of all clean-pre years)"                = "Group-time DiD, mean of all clean pre-pilot years",
          "CS-B5 (mean of last 5 clean-pre years)"            = "Group-time DiD, mean of last five clean pre-pilot years",
          "Imputation (FE on clean cells)"                    = "Imputation estimator",
          "TWFE static, clean cells (benchmark)"              = "Static TWFE, clean cells (benchmark)",
          "TWFE static, Han-style naive coding (benchmark)"   = "Static TWFE, naive coding as in Han (2014) (benchmark)")
d <- S[sample == "annual" & spec_internal %in% names(rows)]
d[, row := vapply(rows[spec_internal], function(z) paste(strwrap(z, 30), collapse = "\n"), "")]
d[, is_twfe := grepl("TWFE", spec_internal)]
# group-time / imputation: reported wild-bootstrap interval; TWFE: est +/- 1.96 x crop-clustered SE (no bootstrap CI reported)
d[, lo := fifelse(is_twfe, est - qnorm(0.975) * se_cluster, ci_lo_wild_py)]
d[, hi := fifelse(is_twfe, est + qnorm(0.975) * se_cluster, ci_hi_wild_py)]
d[, panel := factor(outcome_internal, levels = c("ln_area", "ln_yield", "ln_production"), labels = c("A. Area", "B. Yield", "C. Production"))]
d[, preferred := spec_internal == "CS-A (preferred)"]
row_levels <- vapply(rows, function(z) paste(strwrap(z, 30), collapse = "\n"), "")

p <- plot_forest(d, row_levels) +
  labs(x = "Estimated change after nationwide availability (log points)",
       title = fig_title("fig2", "Annual Crops: Estimated Change after Nationwide Availability, by Estimator"),
       caption = wrap(paste(
         "Note: Same treated crops, controls and period as Figure 1. Group-time and imputation rows average e = 0 to 9;",
         "the two TWFE rows are single static coefficients over all post-availability years (up to e = 12) and are benchmarks only.",
         "Intervals: 95% crop-level wild bootstrap (group-time and imputation; custom procedure); TWFE: estimate ± 1.96",
         "crop-clustered standard errors (normal approximation; restricted wild cluster bootstrap p-values are in the results table).",
         "Estimates are associations, not established causal effects.",
         "Source: KOSIS Crop Production Survey (national series); author's calculations."), 108))

save_thesis_fig(p, "fig2", "fig2_estimator_comparison", height = 7.6,
                data = d[, .(spec_internal, outcome_internal, est, lo, hi, interval = fifelse(is_twfe, "est +/- 1.96 SE", "wild bootstrap"))])
