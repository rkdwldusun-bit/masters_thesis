# =====================================================================
# 04_pretrend_fruit_redpepper.R
# Brief sections 7, 9 (Red pepper), 11 (fruit): diagnostics computed from
# the independently replicated R estimates.
# Run from the repository root.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/did_engine.R")

P  <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
X  <- fread("audit/output/03_all_specs_R_vs_Py.csv")
DX <- fread("audit/output/03_all_dynamic_R_vs_Py.csv")
T14 <- fread("audit/extracted/results/T14_pretrend_slopes.csv")
ANN   <- c("soybean", "onion", "sweet_potato", "corn", "garlic", "spring_potato", "red_pepper")
FRUIT <- c("apple", "pear", "tangerine", "sweet_persimmon", "astringent_persimmon", "plum")
CTRL  <- sort(unique(P[role == "control_pool", crop_id]))

sink("audit/output/04_pretrend_fruit_redpepper.txt", split = TRUE)

# ---------------- pre-trend: statistical test vs visual pattern
cat("==== PRE-TREND (preferred spec) ====\n")
pre <- DX[spec %in% c("CS-A (preferred)", "CS-A main (exact match, annual linking rule)") & event_time < 0]
print(pre[, .(sample, outcome, e = event_time, est = round(est, 3), lo = round(ci_lo, 3), hi = round(ci_hi, 3),
              p = round(p_wild, 3), n_tr = n_treated, sig5 = p_wild < 0.05)])
sl <- pre[, .(slope = coef(lm(est ~ event_time))[2], k = .N, mean_pre = mean(est)), by = .(sample, outcome)]
sl <- merge(sl, T14[, .(sample, outcome_label = outcome, py_slope = pre_slope_per_year)], by = "sample", allow.cartesian = TRUE)
cat("\nUnweighted OLS slope of pre coefficients on e (as in T14), R vs Python T14:\n")
print(unique(pre[, .(slope = round(coef(lm(est ~ event_time))[2], 4), mean_pre = round(mean(est), 3), k = .N), by = .(sample, outcome)]))
print(T14)
cat("\nJoint Wald p (Python / R):\n")
print(X[spec %in% c("CS-A (preferred)", "CS-A main (exact match, annual linking rule)"),
        .(sample, outcome, Py_pre_p = round(Py_pre_p, 4), R_pre_p = round(R_pre_p, 4), pre_k = R_pre_k)])

# ---------------- composition behind each pre coefficient
cat("\nTreated crops contributing to each annual pre coefficient:\n")
print(unique(DX[sample == "annual" & spec == "CS-A (preferred)" & outcome == "ln_production" & event_time < 0,
                .(event_time, n_treated, treated_crops)]))

# ---------------- Red pepper
cat("\n==== RED PEPPER ====\n")
C <- fread("audit/output/02_crop_level_att.csv")
rp <- C[crop == "red_pepper" & event_time >= 0, .(outcome, event_time, att_i = round(att_i, 3))]
print(dcast(rp, event_time ~ outcome, value.var = "att_i"))
cat("\nRed pepper series 2005-2016 (levels relative to 2007 reference):\n")
print(P[crop_id == "red_pepper" & year %between% c(2005, 2016),
        .(year, area_ha, production_t, d_ln_area_vs2007 = round(ln_area - P[crop_id == "red_pepper" & year == 2007, ln_area], 3),
          d_ln_prod_vs2007 = round(ln_production - P[crop_id == "red_pepper" & year == 2007, ln_production], 3),
          transition)])
loo <- X[sample == "annual" & grepl("^Leave out [A-Z]", spec) & !grepl("cohort", spec),
         .(spec, outcome, est = round(R_est, 4))]
base <- X[sample == "annual" & spec == "CS-A (preferred)", .(outcome, base = R_est)]
loo <- merge(loo, base, by = "outcome")[, shift := round(est - base, 4)]
cat("\nLeave-one-treated-crop-out shifts vs preferred:\n"); print(dcast(loo, spec ~ outcome, value.var = "shift"))
cat("range of LOO estimates:\n"); print(loo[, .(min = min(est), max = max(est)), by = outcome])

# ---------------- fruit: who are the controls?
cat("\n==== FRUIT CONTROLS ====\n")
FC <- c(CTRL, ANN)
for (o in c("ln_area_harmonized", "ln_production")) {
  d  <- prep_cells(P, o, FRUIT, FC)
  cr <- att_direct(d, FRUIT)
  cr[, n_fruit_ctrl := vapply(strsplit(ctrl, ";"), function(z) sum(z %in% FRUIT), 0L)]
  cr[, fruit_ctrls := vapply(strsplit(ctrl, ";"), function(z) paste(intersect(z, FRUIT), collapse = ","), "")]
  cat("\n", o, ": treated-crop x event-time comparisons that include a not-yet-treated FRUIT control:",
      cr[n_fruit_ctrl > 0, .N], "of", nrow(cr), "(post e>=0:", cr[n_fruit_ctrl > 0 & event_time >= 0, .N], "of",
      cr[event_time >= 0, .N], ")\n")
  print(cr[n_fruit_ctrl > 0 & event_time >= 0, .(crop, event_time, year, n_ctrl, n_fruit_ctrl, fruit_ctrls)])
  cat("pre coefficients:\n")
  print(DX[sample == "fruit" & spec == "CS-A (preferred)" & outcome == o & event_time < 0,
           .(event_time, est = round(est, 3), n_treated)])
  cat("post coefficients:\n")
  print(DX[sample == "fruit" & spec == "CS-A (preferred)" & outcome == o & event_time >= 0,
           .(event_time, est = round(est, 3), lo = round(ci_lo, 3), hi = round(ci_hi, 3), n_treated, n_ctrl_min, n_ctrl_max)])
}
cat("\nFirst year with production data, fruit:\n")
print(P[crop_id %in% c(FRUIT, "peach", "grape") & !is.na(production_t), .(first = min(year)), by = crop_id])
sink()
