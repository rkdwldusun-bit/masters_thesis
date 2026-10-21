# =====================================================================
# 01_national_confirmed_dates.R
# National crop analysis with the confirmed insurance dates.
#
# Design (unchanged from the thesis): reference = last pre-pilot year;
# contrasts against eligible comparison crops; equal-weight mean over the
# treated crops and ten target years from the expansion year (eq. 4-5);
# score SEs and Webb multiplier intervals, 9,999 draws (Appendix A).
#
# Main analysis: six treated crops; expansion year = harvest year of the
#   first nationwide sales season documented in MAFRA releases
#   (input/treatment_timing_sources.csv): soybean 2011, onion 2012,
#   sweet potato 2012, corn 2012, garlic 2013, red pepper 2014.
#   Spring potato is excluded because the 2008 potato pilot did not cover
#   lowland spring potato and its own first sales year is undocumented.
# Supplementary: (S1) seven crops, spring potato with its previous coding
#   (pilot 2008, expansion 2013); (S2) the previous thesis coding
#   (seven crops, Yearbook expansion years).
#
# Outputs: analysis/output/*.csv (one file per thesis table / figure).
# Every number comes from this script; nothing is typed by hand.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/did_engine.R")
source("R/lib/pilot_pretest.R")
source("R/lib/national_tables.R")

B    <- 9999
SEED <- 20261021
OUT  <- "analysis/output"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

P    <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
TS   <- fread("input/treatment_timing_sources.csv", encoding = "UTF-8")
ANN7 <- c("soybean", "onion", "sweet_potato", "corn", "garlic", "spring_potato", "red_pepper")
ANN6 <- setdiff(ANN7, "spring_potato")
CTRL <- sort(unique(P[role == "control_pool", crop_id]))
SPRING2 <- c("spring_napa", "spring_radish")
FIELD <- intersect(CTRL, c("red_bean", "mung_bean", "barley", "malting_barley", "wheat", "sesame", "perilla", "peanut"))
SEAS  <- c(grep("_napa$|_radish$", CTRL, value = TRUE), "carrot", "large_green_onion", "small_green_onion")
NAME  <- setNames(P$crop_en_display, P$crop_id)
OUTC  <- c(ln_area = "Area", ln_yield = "Yield", ln_production = "Production")

# ---- dates -------------------------------------------------------------
conf <- TS[crop_id %in% ANN6, setNames(expansion_sale_year_documented, crop_id)]
stopifnot(length(conf) == 6, !anyNA(conf),
          all(conf == c(soybean = 2011, onion = 2012, sweet_potato = 2012, corn = 2012,
                        garlic = 2013, red_pepper = 2014)[names(conf)]))
P_prev <- P                                                   # previous thesis coding
P_conf <- copy(P)[crop_id %in% names(conf), national_year := conf[crop_id]]
designs <- list(
  main = list(panel = P_conf, treated = ANN6, label = "Main: six crops, confirmed dates"),
  S1   = list(panel = P_conf, treated = ANN7, label = "S1: seven crops, spring potato with previous coding"),
  S2   = list(panel = P_prev, treated = ANN7, label = "S2: previous thesis coding"))

run_rows <- function(dz, controls, tag, ...) {
  rbindlist(lapply(names(OUTC), function(o) {
    x <- spec_row(dz$panel, o, dz$treated, controls, B, SEED, ...)
    x$row[, spec := tag]
  }))
}

# ---- Table 3: timing ---------------------------------------------------
T3 <- merge(TS[crop_id %in% ANN7, .(crop_id, crop, expansion_sale_year_documented, expansion_sale_status,
                                     pilot_sale_status, product_table_year)],
            unique(P[crop_id %in% ANN7, .(crop_id, pilot_year, previous_expansion_year = national_year)]),
            by = "crop_id")
T3[, `:=`(reference_year = pilot_year - 1L,
          expansion_year_main = fifelse(crop_id %in% ANN6, expansion_sale_year_documented, NA_integer_))]
T3[, transition_years_main := expansion_year_main - pilot_year]
T3[, in_main := crop_id %in% ANN6]
fwrite(T3[match(ANN7, crop_id)], file.path(OUT, "table3_timing.csv"))

# ---- Table 4: main contrasts, two comparison pools --------------------
T4 <- rbindlist(lapply(names(designs), function(k) rbind(
  run_rows(designs[[k]], CTRL, "A. Full comparison pool")[, design := k],
  run_rows(designs[[k]], setdiff(CTRL, SPRING2), "B. Excluding two spring series")[, design := k])))
fwrite(T4, file.path(OUT, "table4_main.csv"))

# ---- Table 5: sensitivity (main design) --------------------------------
dm <- designs$main
P_tab <- copy(P_conf)[crop_id %in% ANN6, national_year := national_year_alt_table]
P_ybk <- copy(P_prev)
T5 <- rbind(
  run_rows(dm, CTRL, "A. Reference period: mean of last five pre-pilot years", norm = "B", b5 = TRUE),
  run_rows(dm, CTRL, "B. Reference period: mean of all pre-pilot years", norm = "B"),
  run_rows(dm, FIELD, "C. Comparison crops: field crops only"),
  run_rows(dm, setdiff(CTRL, SEAS), "D. Comparison crops: excluding uncertain seasonal forms"),
  run_rows(list(panel = P_tab, treated = ANN6), CTRL, "E. Timing: product-table years"),
  run_rows(dm, CTRL, "F. Timing: target years begin with pilot", pilot_clock = TRUE),
  run_rows(list(panel = P_ybk, treated = ANN6), CTRL, "G. Timing: Yearbook main-program years (previous coding)"))
fwrite(T5, file.path(OUT, "table5_sensitivity.csv"))

# ---- Table 6: pre-pilot area weights -----------------------------------
w6 <- area_weights(P, ANN6)
T6 <- rbindlist(lapply(names(OUTC), function(o) rbind(
  area_weighted_row(P_conf, o, ANN6, CTRL, w6, B, SEED)[, spec := "A. Full comparison pool"],
  area_weighted_row(P_conf, o, ANN6, setdiff(CTRL, SPRING2), w6, B, SEED)[, spec := "B. Excluding two spring series"])))
fwrite(T6, file.path(OUT, "table6_area_weights.csv"))
fwrite(data.table(crop_id = names(w6), weight = unname(w6))[order(-weight)], file.path(OUT, "table6_weights.csv"))

# ---- Table A1: leave one crop out (main design) ------------------------
TA1 <- rbindlist(lapply(ANN6, function(c) run_rows(list(panel = P_conf, treated = setdiff(ANN6, c)), CTRL,
                                                   paste("Omit", NAME[[c]]))[, omitted := c]))
fwrite(TA1, file.path(OUT, "tableA1_leave_one_out.csv"))

# ---- Figure 7: crop-specific means -------------------------------------
crop_means <- function(dz, controls, pool) rbindlist(lapply(names(OUTC), function(o) {
  d  <- prep_cells(dz$panel, o, dz$treated, controls)
  cr <- att_direct(d, dz$treated, "A", FALSE, 0:9)[event_time %in% 0:9]
  cr[, .(est = mean(att_i), n_events = .N), by = .(crop_id = crop)][, `:=`(outcome = o, pool = pool)]
}))
F7 <- rbind(crop_means(dm, CTRL, "Full comparison pool"),
            crop_means(dm, setdiff(CTRL, SPRING2), "Excluding two spring series"),
            crop_means(designs$S1, CTRL, "Full comparison pool")[crop_id == "spring_potato"][, pool := "Supplementary (S1)"])
fwrite(F7, file.path(OUT, "fig7_crop_means.csv"))

# ---- Figure 6: pilot-aligned event time and joint pre-pilot test -------
# Treated crops are compared with comparison-pool crops only (other treated crops
# are not comparisons in their own pre-pilot years); joint test over e = -10..-2.
F6 <- list(); J6 <- list()
for (k in c("main", "S2")) for (o in names(OUTC)) {
  r <- pilot_event_study(designs[[k]]$panel, o, designs[[k]]$treated, CTRL, B = B, seed = SEED, donors = CTRL)
  F6[[length(F6) + 1]] <- r$dynamic[, `:=`(design = k, outcome = o)]
  J6[[length(J6) + 1]] <- r$joint[, `:=`(design = k, outcome = o)]
}
fwrite(rbindlist(F6), file.path(OUT, "fig6_event_time.csv"))
fwrite(rbindlist(J6), file.path(OUT, "fig6_joint_pretest.csv"))

# Monte Carlo spread of the joint p-value (independent draw sets, same statistic)
MC <- rbindlist(lapply(c("main", "S2"), function(k) rbindlist(lapply(names(OUTC), function(o)
  data.table(design = k, outcome = o, seed = SEED + 1:20, p = vapply(SEED + 1:20, function(s)
    pilot_event_study(designs[[k]]$panel, o, designs[[k]]$treated, CTRL, B = B, seed = s, donors = CTRL)$joint$p, 0))))))
MCs <- MC[, .(p_min = min(p), p_median = median(p), p_max = max(p), n_seeds = .N), by = .(design, outcome)]
fwrite(MCs, file.path(OUT, "fig6_joint_pretest_mc.csv"))

# ---- Table 2: summary statistics (main design) -------------------------
fit_main <- spec_row(P_conf, "ln_area", ANN6, CTRL, B, SEED)$fit
cells <- comparison_cells(fit_main, ANN6)
fwrite(summary_stats(P, cells), file.path(OUT, "table2_summary.csv"))
fwrite(cells, file.path(OUT, "table2_cells.csv"))

# ---- Table 9: pre-pilot growth, 1998-2007 ------------------------------
contrib <- setdiff(names(fit_main$overall$psi)[abs(fit_main$overall$psi) > 0], ANN6)
fwrite(slope_table(P, ANN6, contrib), file.path(OUT, "table9_prepilot_growth.csv"))

# ---- console summary ---------------------------------------------------
f3 <- function(x) sprintf("%.3f", x)
cat("\nTable 4 (main contrasts)\n")
print(T4[, .(design, spec = substr(spec, 1, 2), outcome = OUTC[outcome], est = f3(est), se = f3(se),
             ci = sprintf("[%s, %s]", f3(ci_lo), f3(ci_hi)), p = f3(p), n_comparison)])
cat("\nFigure 6 joint pre-pilot test (e = -10..-2)\n")
print(merge(rbindlist(J6), MCs, by = c("design", "outcome"))[
  , .(design, outcome = OUTC[outcome], stat = round(stat, 2), p = f3(p), p_range_20_seeds = sprintf("%s-%s", f3(p_min), f3(p_max)))])
