# =====================================================================
# 03_replicate_all_specs.R
# Independent R re-estimation of every specification in RAW_SUMMARY
# (annual robustness, estimator comparison, fruit, price) and the rice
# case; comparison with the Python results.
# Spec definitions are re-derived from DOCUMENTATION.md / TREATMENT and
# checked against the Python spec list, not copied from it.
# Run from the repository root.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/did_engine.R")
source("R/lib/did_extras.R")

B_R  <- 99999           # R bootstrap draws (Python used 9,999; TWFE WCR 1,999)
SEED <- 20260927
TOL_POINT <- 1e-6
TOL_CI_REL <- 0.08       # |dCI endpoint| <= 0.08 * clustered SE  (~3 MC s.d. of the Python 9,999-draw quantile)
TOL_P <- 0.03            # |dp| for bootstrap p-values

P    <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
TRT  <- fread("audit/extracted/data/TREATMENT.csv", encoding = "UTF-8")
PS   <- fread("audit/extracted/results/RAW_SUMMARY.csv")
PDYN <- fread("audit/extracted/results/RAW_DYNAMIC.csv")
PR   <- fread("audit/extracted/data/PRICE_ANNUAL.csv")
RR   <- fread("audit/extracted/results/RAW_RICE.csv")

ANN   <- c("soybean", "onion", "sweet_potato", "corn", "garlic", "spring_potato", "red_pepper")
FRUIT <- c("apple", "pear", "tangerine", "sweet_persimmon", "astringent_persimmon", "plum")
CTRL  <- sort(unique(P[role == "control_pool", crop_id]))
# control-pool subsets as described in DOCUMENTATION.md section 4 / Figure 3 labels
FIELD <- c("red_bean", "mung_bean", "barley", "malting_barley", "wheat", "sesame", "perilla", "peanut")
SEAS  <- c(grep("_napa$|_radish$", CTRL, value = TRUE), "carrot", "large_green_onion", "small_green_onion")
SPILL <- c("leaf_lettuce", "spinach", "malting_barley")
NAME  <- setNames(P$crop_en_display, P$crop_id)
cohort_of <- setNames(TRT$national_year, TRT$crop_id)

specs <- list()
add <- function(sample, spec, outcome, treated, controls, panel = "P", norm = "A", b5 = FALSE,
                years = c(1991, 2024), pilot_clock = FALSE, type = "gt")
  specs[[length(specs) + 1]] <<- list(sample = sample, spec = spec, outcome = outcome, treated = treated,
                                      controls = controls, panel = panel, norm = norm, b5 = b5, years = years,
                                      pilot_clock = pilot_clock, type = type)

# ---- panels with alternative dates
panels <- list(P = P)
panels$P_alt <- copy(P)[crop_id %in% ANN, national_year := national_year_alt_table]
panels$P_ap2001 <- copy(P)[crop_id %in% c("apple", "pear"), national_year := 2001]
panels$P_pg2004 <- copy(P)[crop_id %in% c("peach", "grape"), national_year := 2004]
panels$P_pg2010 <- copy(P)[crop_id %in% c("peach", "grape"), national_year := 2010]

# ---- annual crops
for (o in c("ln_area", "ln_yield", "ln_production")) {
  add("annual", "CS-A (preferred)", o, ANN, CTRL)
  add("annual", "CS-B (mean of all clean-pre years)", o, ANN, CTRL, norm = "B")
  add("annual", "CS-B5 (mean of last 5 clean-pre years)", o, ANN, CTRL, norm = "B", b5 = TRUE)
  add("annual", "Imputation (FE on clean cells)", o, ANN, CTRL, type = "imp")
  add("annual", "TWFE static, clean cells (benchmark)", o, ANN, CTRL, type = "twfe_clean")
  add("annual", "TWFE static, Han-style naive coding (benchmark)", o, ANN, CTRL, type = "twfe_naive")
  add("annual", "Dates: product-table nationwide year", o, ANN, CTRL, panel = "P_alt")
  add("annual", "Dates: pilot-year clock (no transition exclusion)", o, ANN, CTRL, pilot_clock = TRUE)
  add("annual", "Controls: excl. other pulses", o, ANN, setdiff(CTRL, "other_pulses"))
  add("annual", "Controls: excl. likely spillover (leaf lettuce, spinach, malting barley)", o, ANN, setdiff(CTRL, SPILL))
  add("annual", "Controls: field crops only", o, ANN, intersect(CTRL, FIELD))
  add("annual", "Controls: excl. uncertain seasonal forms", o, ANN, setdiff(CTRL, SEAS))
  for (g in c(2012, 2013, 2015)) add("annual", paste("Leave out cohort", g), o, ANN[cohort_of[ANN] != g], CTRL)
  for (c in ANN) add("annual", paste("Leave out", NAME[c]), o, setdiff(ANN, c), CTRL)
  for (g in c(2012, 2013, 2015)) add("annual", paste0("Cohort ", g, " only"), o, ANN[cohort_of[ANN] == g], CTRL)
}
# ---- perennial fruit (controls = annual controls + annual treated crops before their pilots)
FCTRL <- c(CTRL, ANN)
for (o in c("ln_area_harmonized", "ln_production")) {
  add("fruit", "CS-A (preferred)", o, FRUIT, FCTRL)
  add("fruit", "CS-B (mean of all clean-pre years)", o, FRUIT, FCTRL, norm = "B")
  add("fruit", "Apple and Pear dated 2001", o, FRUIT, FCTRL, panel = "P_ap2001")
  add("fruit", "Adding Peach and Grape (nationwide 2004)", o, c(FRUIT, "peach", "grape"), FCTRL, panel = "P_pg2004")
  add("fruit", "Adding Peach and Grape (nationwide 2010)", o, c(FRUIT, "peach", "grape"), FCTRL, panel = "P_pg2010")
  add("fruit", "Controls: field crops only", o, FRUIT, intersect(FCTRL, c(FIELD, ANN)))
  # as coded in 03_estimate.py the fruit TWFE uses CTRL only (not CTRL + ANN): replicated as coded
  add("fruit", "TWFE static, clean cells (benchmark)", o, FRUIT, CTRL, type = "twfe_clean")
}

# ---- price panel: timing per price unit
# treated/production-linked units take dates from TREATMENT; pooled price units carry
# the hard-coded dates of 03_estimate.py (greenhouse products etc.; not in TREATMENT)
price_dates <- rbind(
  TRT[crop_id %in% c(ANN, "red_bean", "cabbage", "carrot", "ginger", "sesame", "perilla", "peanut", "mung_bean"),
      .(price_unit = crop_id, pilot_year, national_year)][price_unit != "spring_potato"],
  data.table(price_unit = c("potato", "napa_cabbage", "radish", "green_onion", "spinach", "leaf_lettuce"),
             pilot_year = c(2008, 2014, 2015, 2014, 2013, 2013), national_year = c(2013, NA, NA, NA, NA, NA)))
mk_price <- function(w) {
  x <- PR[link_window == w][, crop_id := price_unit]
  merge(x, price_dates, by = "price_unit", all.x = TRUE)
}
panels$PX <- mk_price("full_2005_2012"); panels$PX_early <- mk_price("early_2005_2006"); panels$PX_late <- mk_price("late_2010_2012")
panels$PX[, ln_nominal_linked := log(linked)]
T_MAIN <- c("onion", "sweet_potato", "garlic", "red_pepper")
C_MAIN <- c("red_bean", "cabbage", "carrot", "ginger", "sesame", "perilla", "peanut")
T_STR  <- c("sweet_potato", "garlic"); C_STR <- c("red_bean", "cabbage", "sesame", "perilla", "peanut")
C_APX  <- c(C_MAIN, "napa_cabbage", "radish", "green_onion", "spinach", "leaf_lettuce")
Y80 <- c(1980, 2024)
add("price", "CS-A main (exact match, annual linking rule)", "ln_real_linked", T_MAIN, C_MAIN, "PX", years = Y80)
add("price", "CS-B main", "ln_real_linked", T_MAIN, C_MAIN, "PX", norm = "B", years = Y80)
add("price", "Strict sample (both linking rules)", "ln_real_linked", T_STR, C_STR, "PX", years = Y80)
add("price", "Approximate matches included (+ all-potato, pooled vegetable items)", "ln_real_linked", c(T_MAIN, "potato"), C_APX, "PX", years = Y80)
add("price", "New series only 2005-2024 (6 exact crops)", "ln_real_new", c("soybean", "onion", "sweet_potato", "corn", "garlic", "red_pepper"), C_MAIN, "PX", years = c(2005, 2024))
add("price", "New series only 2005-2024 (main 4 crops)", "ln_real_new", T_MAIN, C_MAIN, "PX", years = c(2005, 2024))
add("price", "Link window 2005-2006", "ln_real_linked", T_MAIN, C_MAIN, "PX_early", years = Y80)
add("price", "Link window 2010-2012", "ln_real_linked", T_MAIN, C_MAIN, "PX_late", years = Y80)
for (c in T_MAIN) add("price", paste("Leave out", NAME[c]), "ln_real_linked", setdiff(T_MAIN, c), C_MAIN, "PX", years = Y80)
add("price", "TWFE static, clean cells (benchmark)", "ln_real_linked", T_MAIN, C_MAIN, "PX", years = Y80, type = "twfe_clean")
# audit-only: nominal (undivided) crop index -- tests the "denominator cancels" claim
add("price_audit", "AUDIT: CS-A main on nominal linked crop index (no divisor)", "ln_nominal_linked", T_MAIN, C_MAIN, "PX", years = Y80)

cat("specifications:", length(specs), "\n")

# ---- run
rows <- list(); dyn <- list()
for (k in seq_along(specs)) {
  s <- specs[[k]]; pn <- panels[[s$panel]]
  if (s$type == "gt") {
    r <- run_gt(pn, s$outcome, s$treated, s$controls, norm = s$norm, b5 = s$b5, years = s$years,
                pilot_clock = s$pilot_clock, B = B_R, seed = SEED + k)
    o <- r$overall
    rows[[k]] <- data.table(sample = s$sample, spec = s$spec, outcome = s$outcome, type = s$type,
      R_est = o$est, R_se = o$se_cluster, R_lo = o$ci_lo, R_hi = o$ci_hi, R_p = o$p_wild, R_p_norm = o$p_normal,
      R_G = o$G, R_n_tr = o$n_treated, R_n_ctrl = o$n_controls_listed,
      R_pre_k = if (is.null(o$pre_k)) NA_integer_ else o$pre_k,
      R_pre_p = if (is.null(o$pre_p_boot)) NA_real_ else o$pre_p_boot,
      R_pre_mean = if (is.null(o$pre_mean)) NA_real_ else o$pre_mean, R_n_obs = NA_integer_,
      R_ctrl_used = length(unique(unlist(strsplit(r$crop_att[event_time >= 0, ctrl], ";")))))
    dd <- copy(r$dynamic)[, `:=`(sample = s$sample, spec = s$spec, outcome = s$outcome)]
    dyn[[k]] <- dd
  } else if (s$type == "imp") {
    r <- run_imputation_inf(pn, s$outcome, s$treated, s$controls, years = s$years, B = B_R, seed = SEED + k)
    rows[[k]] <- data.table(sample = s$sample, spec = s$spec, outcome = s$outcome, type = s$type,
      R_est = r$est, R_se = r$se_cluster, R_lo = r$ci_lo, R_hi = r$ci_hi, R_p = r$p_wild, R_G = r$G, R_n_tr = r$n_treated)
    dyn[[k]] <- copy(r$dynamic)[, `:=`(sample = s$sample, spec = s$spec, outcome = s$outcome)]
  } else {
    r <- run_twfe_wcr(pn, s$outcome, s$treated, s$controls, variant = sub("twfe_", "", s$type), years = s$years,
                      B = 9999, seed = SEED + k)
    rows[[k]] <- data.table(sample = s$sample, spec = s$spec, outcome = s$outcome, type = s$type,
      R_est = r$est, R_se = r$se_cluster, R_p = r$p_wcr, R_G = r$G, R_n_tr = r$n_treated, R_n_obs = r$n_obs,
      R_post_e_max = r$post_e_max)
  }
}
R <- rbindlist(rows, fill = TRUE)
Py <- PS[, .(sample, spec, outcome, Py_est = est, Py_se = se_cluster, Py_lo = ci_lo_wild, Py_hi = ci_hi_wild,
             Py_p = p_wild, Py_p_norm = p_normal_cluster, Py_G = G, Py_n_tr = n_treated, Py_n_ctrl = n_controls,
             Py_pre_k = pre_k, Py_pre_p = pre_p_boot, Py_pre_mean = pre_mean, Py_n_obs = n_obs)]
X <- merge(R, Py, by = c("sample", "spec", "outcome"), all = TRUE)
X[, d_est := R_est - Py_est][, d_se := R_se - Py_se]
X[, point_ok := abs(d_est) < TOL_POINT & abs(d_se) < TOL_POINT]
X[, count_ok := (R_G == Py_G) & (R_n_tr == Py_n_tr) & (is.na(Py_n_obs) | R_n_obs == Py_n_obs)]
X[, boot_ok := is.na(Py_lo) | (abs(R_lo - Py_lo) <= TOL_CI_REL * Py_se & abs(R_hi - Py_hi) <= TOL_CI_REL * Py_se)]
X[, p_ok := is.na(Py_p) | abs(R_p - Py_p) <= TOL_P]
X[, status := fifelse(is.na(Py_est), "R-only (audit)",
               fifelse(point_ok & count_ok & boot_ok & p_ok, "REPLICATED",
               fifelse(point_ok & count_ok, "POINT+SE REPLICATED; bootstrap outside MC tolerance", "MISMATCH")))]
fwrite(X, "audit/output/03_all_specs_R_vs_Py.csv")

Dn <- rbindlist(dyn, fill = TRUE)
Dn[, event_time := as.integer(if ("e" %in% names(Dn)) fifelse(is.na(event_time), e, event_time) else event_time)]
PD2 <- PDYN[, .(sample, spec, outcome, event_time = suppressWarnings(as.integer(event_time)), Py_est = est, Py_se = se_cluster,
                Py_n_tr = n_treated, Py_cmin = n_ctrl_min, Py_cmax = n_ctrl_max)][!is.na(event_time)]
DX <- merge(Dn, PD2, by = c("sample", "spec", "outcome", "event_time"), all = TRUE)
DX[, d_est := est - Py_est]
fwrite(DX, "audit/output/03_all_dynamic_R_vs_Py.csv")

# ---- rice (single treated unit; point estimates only)
rice <- list()
for (o in c("ln_area", "ln_yield", "ln_production")) for (dt in list(c("nationwide 2014 (baseline)", 2014),
                                                                     c("product table 2012", 2012), c("full-scale 2017", 2017))) {
  pn <- copy(P)[crop_id == "rice", national_year := as.numeric(dt[2])]
  d  <- prep_cells(pn, o, "rice", CTRL)
  cr <- att_direct(d, "rice")
  rice[[length(rice) + 1]] <- cr[, .(outcome = o, dating = dt[1], event_time, R_est = att_i, R_n_ctrl = n_ctrl)]
}
RI <- merge(rbindlist(rice), RR[, .(outcome, dating, event_time = as.integer(event_time), Py_est = est, Py_n_ctrl = n_controls)],
            by = c("outcome", "dating", "event_time"), all = TRUE)
fwrite(RI, "audit/output/03_rice_R_vs_Py.csv")

sink("audit/output/03_all_specs_summary.txt", split = TRUE)
cat("Specs compared:", nrow(X), "\n"); print(X[, .N, by = status])
cat("\nmax |d_est| over all Python specs:", max(abs(X$d_est), na.rm = TRUE),
    "\nmax |d_se| (analytic/CR1):", max(abs(X$d_se), na.rm = TRUE), "\n")
print(X[, .(sample, spec = substr(spec, 1, 48), outcome, R_est = round(R_est, 4), Py_est = round(Py_est, 4),
            R_se = round(R_se, 4), R_lo = round(R_lo, 3), Py_lo = round(Py_lo, 3), R_hi = round(R_hi, 3), Py_hi = round(Py_hi, 3),
            R_p = round(R_p, 3), Py_p = round(Py_p, 3), R_G, Py_G, status)], nrows = 500)
cat("\nDynamic coefficients: rows", nrow(DX), " unmatched R:", DX[is.na(Py_est), .N], " unmatched Py:", DX[is.na(est), .N],
    "\n max |d_est|:", max(abs(DX$d_est), na.rm = TRUE), "\n")
cat("\nRice rows:", nrow(RI), " max |d|:", max(abs(RI$R_est - RI$Py_est), na.rm = TRUE),
    " n_ctrl mismatches:", RI[R_n_ctrl != Py_n_ctrl, .N], " unmatched:", RI[is.na(R_est) | is.na(Py_est), .N], "\n")
sink()
