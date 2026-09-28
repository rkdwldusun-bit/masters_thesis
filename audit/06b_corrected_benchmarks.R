# =====================================================================
# 06b_corrected_benchmarks.R  (approved corrections, 2026-09-28)
#  Item 6 : annual TWFE benchmarks re-estimated on the same post horizon
#           (e = 0..9) as the group-time estimators; all-post versions kept
#           as legacy benchmarks.
#  Item 7 : fruit TWFE re-estimated on the preferred fruit comparison pool
#           (annual controls + annual treated crops before their pilots);
#           the old annual-controls-only result is kept as superseded.
#  Item 8 : code-consistent support tables (T12/T13 equivalents) rebuilt
#           from the current design and checked against RESULTS T12/T13.
#  Item 15: control-support numbers verified.
#  Item 16: crop-year identity discrepancies listed (raw values unchanged).
# The preferred estimator and all group-time estimates are NOT touched.
# Run from the repository root.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/did_engine.R")
source("R/lib/did_extras.R")

P    <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
PS   <- fread("audit/extracted/results/RAW_SUMMARY.csv")
T12  <- fread("audit/extracted/results/T12_event_time_support.csv")
T13  <- fread("audit/extracted/results/T13_control_composition.csv", encoding = "UTF-8")
ANN   <- c("soybean", "onion", "sweet_potato", "corn", "garlic", "spring_potato", "red_pepper")
FRUIT <- c("apple", "pear", "tangerine", "sweet_persimmon", "astringent_persimmon", "plum")
CTRL  <- sort(unique(P[role == "control_pool", crop_id]))
FCTRL <- c(CTRL, ANN)
SEED  <- 20260928
sink("audit/output/06b_corrected_benchmarks.txt", split = TRUE)

# ---------------- items 6 and 7: benchmarks
rows <- list(); k <- 0
bench <- function(sample, spec, outcome, treated, controls, variant, e_max, status, note) {
  k <<- k + 1
  r <- run_twfe_wcr(P, outcome, treated, controls, variant = variant, e_max = e_max, B = 9999, seed = SEED + k)
  rows[[k]] <<- data.table(sample = sample, spec = spec, outcome = outcome, est = r$est, se_cluster = r$se_cluster,
                           p_wcr = r$p_wcr, G = r$G, n_obs = r$n_obs, n_treated = r$n_treated,
                           post_e_max = r$post_e_max, status = status, note = note)
}
for (o in c("ln_area", "ln_yield", "ln_production")) {
  bench("annual", "TWFE static, clean cells, e = 0..9 (benchmark)", o, ANN, CTRL, "clean", 9, "CURRENT (approved item 6)",
        "Same post horizon as the group-time estimators; treated cells with e > 9 dropped.")
  bench("annual", "TWFE static, Han-style naive coding, e = 0..9 (benchmark)", o, ANN, CTRL, "naive", 9, "CURRENT (approved item 6)",
        "Same post horizon as the group-time estimators; treated cells with e > 9 dropped.")
  bench("annual", "CHECK: TWFE clean, all post years (R re-run)", o, ANN, CTRL, "clean", Inf, "CHECK", "Must equal legacy Python value.")
}
for (o in c("ln_area_harmonized", "ln_production")) {
  bench("fruit", "TWFE static, clean cells, preferred fruit pool (benchmark)", o, FRUIT, FCTRL, "clean", Inf, "CURRENT (approved item 7)",
        "Comparison pool = 24 annual controls + 7 annual treated crops before their pilots, as in the preferred fruit estimator; all post years.")
  bench("fruit", "TWFE static, clean cells, preferred fruit pool, e = 0..9 (supplementary)", o, FRUIT, FCTRL, "clean", 9, "SUPPLEMENTARY",
        "Same pool and same post horizon as the preferred fruit estimator. Reported for information; not requested.")
}
B <- rbindlist(rows)
# legacy / superseded rows (unchanged Python values)
leg <- PS[grepl("TWFE", spec), .(sample, spec, outcome, est, se_cluster, p_wcr = p_wild, G, n_obs, n_treated)]
leg[, post_e_max := fifelse(sample == "fruit", 21L, 12L)]
leg[, status := fifelse(sample == "fruit", "SUPERSEDED (non-comparable control pool: 24 annual controls only)",
                 fifelse(sample == "annual", "LEGACY benchmark (all post years; not horizon-matched)", "UNCHANGED (price benchmark; all post years)"))]
leg[, note := "Python value, independently replicated in R (audit/03). WCR p from 1,999 draws."]
chk <- merge(B[grepl("^CHECK", spec), .(outcome, r_est = est, r_se = se_cluster, r_n = n_obs)],
             leg[sample == "annual" & spec == "TWFE static, clean cells (benchmark)", .(outcome, est, se_cluster, n_obs)], by = "outcome")
cat("R all-post re-run vs legacy Python TWFE clean: max |d est| =", max(abs(chk$r_est - chk$est)),
    " max |d se| =", max(abs(chk$r_se - chk$se_cluster)), " n_obs equal:", all(chk$r_n == chk$n_obs), "\n\n")
OUT <- rbind(B[!grepl("^CHECK", spec)], leg, fill = TRUE)
fwrite(OUT, "audit/output/06b_benchmarks.csv")
print(OUT[, .(sample, spec = substr(spec, 1, 62), outcome, est = round(est, 4), se = round(se_cluster, 4),
              p_wcr = round(p_wcr, 3), G, n_obs, post_e_max, status = substr(status, 1, 26))])

# ---------------- item 15: control support, annual preferred (production)
d  <- prep_cells(P, "ln_production", ANN, CTRL)
cr <- att_direct(d, ANN)
sup <- cr[, .(n_treated = .N, controls_min = min(n_ctrl), controls_max = max(n_ctrl),
              distinct_controls = uniqueN(unlist(strsplit(ctrl, ";"))),
              distinct_pure_controls = uniqueN(setdiff(unlist(strsplit(ctrl, ";")), ANN)),
              treated_crops = paste(crop, collapse = ";")), by = event_time][order(event_time)]
contrib <- unique(unlist(strsplit(cr$ctrl, ";")))
cat("\nListed control-pool series:", length(CTRL), "\nControl-pool series that ever contribute:",
    length(intersect(contrib, CTRL)), "  never:", paste(setdiff(CTRL, contrib), collapse = ", "),
    "\nNot-yet-treated treated crops used as controls at some e:", paste(intersect(contrib, ANN), collapse = ", "), "\n")
print(sup[event_time >= 0, .(event_time, n_treated, controls_min, controls_max, distinct_controls)])

# support tables for all three preferred samples (T12 equivalent)
sup_tab <- function(sample, outcome, treated, controls, panel, years) {
  d  <- prep_cells(panel, outcome, treated, controls, years)
  cr <- att_direct(d, treated)
  cr[, .(sample = sample, outcome = outcome, n_treated = .N, controls_min = min(n_ctrl), controls_max = max(n_ctrl),
         distinct_controls = uniqueN(unlist(strsplit(ctrl, ";"))), treated_crops = paste(crop, collapse = ";")),
     by = event_time][order(event_time)]
}
PX <- fread("audit/extracted/data/PRICE_ANNUAL.csv")[link_window == "full_2005_2012"][, crop_id := price_unit]
TRT <- fread("audit/extracted/data/TREATMENT.csv")
PX <- merge(PX, TRT[, .(crop_id, pilot_year, national_year)], by = "crop_id", all.x = TRUE)
S12 <- rbind(
  rbindlist(lapply(c("ln_area", "ln_yield", "ln_production"), function(o) sup_tab("annual", o, ANN, CTRL, P, c(1991, 2024)))),
  rbindlist(lapply(c("ln_area_harmonized", "ln_production"), function(o) sup_tab("fruit", o, FRUIT, FCTRL, P, c(1991, 2024)))),
  sup_tab("price", "ln_real_linked", c("onion", "sweet_potato", "garlic", "red_pepper"),
          c("red_bean", "cabbage", "carrot", "ginger", "sesame", "perilla", "peanut"), PX, c(1980, 2024)))
oc <- c(Area = "ln_area", Yield = "ln_yield", Production = "ln_production", "Orchard area" = "ln_area_harmonized", "Relative price" = "ln_real_linked")
T12[, outcome_i := oc[outcome]]
m12 <- merge(S12, T12[, .(sample, outcome = outcome_i, event_time, t_n = treated_crops_n, t_min = controls_min, t_max = controls_max)],
             by = c("sample", "outcome", "event_time"), all = TRUE)
cat("\nT12 equivalent vs RESULTS T12: rows", nrow(m12), " mismatches:",
    m12[is.na(t_n) | is.na(n_treated) | t_n != n_treated | t_min != controls_min | t_max != controls_max, .N], "\n")
fwrite(S12, "audit/output/06b_event_time_support.csv")

# ---------------- item 8: T13 equivalent (control composition by annual cohort)
cc <- rbindlist(lapply(c(2012, 2013, 2015), function(g) rbindlist(lapply(CTRL, function(c) {
  x <- P[crop_id == c & year %between% c(1991, 2024) & !is.na(ln_production) & (is.na(pilot_year) | year < pilot_year)]
  if (!nrow(x)) return(NULL)
  data.table(cohort = g, crop_id = c, control = x$crop_en_display[1], group = x$crop_group[1],
             clean_years = paste0(min(x$year), "–", max(x$year)), clean_after_cohort_year = sum(x$year >= g))
}))))
m13 <- merge(cc, T13, by = c("cohort", "control"), all = TRUE, suffixes = c("", "_T13"))
cat("T13 equivalent vs RESULTS T13: rows", nrow(m13), " mismatches:",
    m13[is.na(group_T13) | is.na(group) | clean_years != clean_years_T13 | clean_after_cohort_year != clean_after_cohort_year_T13, .N], "\n")
fwrite(cc, "audit/output/06b_control_composition.csv")

# ---------------- item 16: crop-year identity discrepancies (source values unchanged)
E <- P[perennial == 0 & crop_id %in% c(ANN, CTRL) & year %between% c(1991, 2024) &
         !is.na(area_ha) & !is.na(yield_kg10a) & !is.na(production_t)]
E[, identity_gap := log(production_t) - (log(area_ha) + log(yield_kg10a) - log(100))]
E[, implied_yield_kg10a := production_t / area_ha * 100]
disc <- E[abs(identity_gap) > 0.01, .(crop_id, crop = crop_en_display, year, area_ha, yield_kg10a, production_t,
                                       implied_yield_kg10a = round(implied_yield_kg10a, 1), identity_gap = round(identity_gap, 5),
                                       in_estimation = crop_id %in% ANN | crop_id %in% CTRL)]
cat("\nCrop-years in the annual estimation sample with |ln P - ln A - ln Y + ln 100| > 0.01:\n"); print(disc)
cat("Summary over", nrow(E), "cells: median |gap|", signif(median(abs(E$identity_gap)), 3),
    "; 95th pct", signif(quantile(abs(E$identity_gap), .95), 3), "; max", signif(max(abs(E$identity_gap)), 3), "\n")
# aggregated level
agg <- PS[sample == "annual" & spec == "CS-A (preferred)", setNames(est, outcome)]
cat(sprintf("Aggregated: area + yield = %.6f ; production = %.6f ; difference = %.6f\n",
            agg[["ln_area"]] + agg[["ln_yield"]], agg[["ln_production"]], agg[["ln_area"]] + agg[["ln_yield"]] - agg[["ln_production"]]))
fwrite(disc, "audit/output/06b_identity_discrepancies.csv")
sink()
