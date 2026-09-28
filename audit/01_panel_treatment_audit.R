# =====================================================================
# 01_panel_treatment_audit.R
# Sections 4-5 of the audit brief: panel structure, treatment identities,
# crop-level treatment table, production identity.
# Run from the repository root.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
dir.create("audit/output", showWarnings = FALSE)

P  <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
TR <- fread("audit/extracted/data/TREATMENT.csv", encoding = "UTF-8")
XW <- fread("audit/extracted/data/PROD_CROSSWALK.csv", encoding = "UTF-8")
DL <- fread("audit/extracted/data/DROPPED_LOG.csv", encoding = "UTF-8")

sink("audit/output/01_panel_treatment_audit.txt", split = TRUE)
cat("==== PANEL STRUCTURE ====\n")
cat("rows:", nrow(P), " crops:", uniqueN(P$crop_id), " years:", min(P$year), "-", max(P$year), "\n")
cat("duplicate crop x year:", sum(duplicated(P[, .(crop_id, year)])), "\n")
cat("rows per crop (all should be 45):\n"); print(table(P[, .N, by = crop_id]$N))
cat("crop groups:\n"); print(P[, .(n = uniqueN(crop_id)), by = .(crop_group, perennial)])
cat("roles:\n"); print(P[, .(n = uniqueN(crop_id), crops = paste(unique(crop_id), collapse = ",")), by = role])

# ---- encoding defect in provenance labels (transfer bundle)
fix_mojibake <- function(x) {
  y <- iconv(x, from = "UTF-8", to = "latin1")
  z <- iconv(y, from = "UTF-8", to = "UTF-8")
  z <- ifelse(is.na(z), x, z)
  enc2utf8(z)
}
ko <- unique(P[, .(crop_id, crop_ko_official)])
ko[, repaired := fix_mojibake(crop_ko_official)]
ko <- merge(ko, XW[, .(crop_id, xw_ko = crop_ko_official)], by = "crop_id")
cat("\nKorean label encoding: MASTER_PANEL raw == crosswalk:", sum(ko$crop_ko_official == ko$xw_ko), "/", nrow(ko),
    "; after latin1->utf8 repair:", sum(ko$repaired == ko$xw_ko), "/", nrow(ko), "\n")

# ---- missingness by crop on estimation window 1991-2024
cat("\n==== MISSINGNESS (1991-2024) ====\n")
W <- P[year >= 1991 & year <= 2024]
miss <- W[, .(n = .N,
              area_obs = sum(!is.na(ln_area)), yield_obs = sum(!is.na(ln_yield)),
              prod_obs = sum(!is.na(ln_production)), orchard_obs = sum(!is.na(ln_total_orchard_area)),
              first_prod = suppressWarnings(min(year[!is.na(production_t)])),
              last_prod = suppressWarnings(max(year[!is.na(production_t)]))),
          by = .(crop_id, role, perennial)]
print(miss[order(perennial, role, crop_id)])
fwrite(miss, "audit/output/01_missingness.csv")

# ---- log transformations
cat("\n==== LOG TRANSFORMATIONS ====\n")
chk <- function(v, lv) { ok <- !is.na(P[[v]]) & P[[v]] > 0; max(abs(log(P[[v]][ok]) - P[[lv]][ok])) }
for (pr in list(c("area_ha", "ln_area"), c("yield_kg10a", "ln_yield"), c("production_t", "ln_production"),
                c("total_orchard_area_ha", "ln_total_orchard_area"), c("bearing_area_ha", "ln_bearing_area")))
  cat(sprintf("max |log(%s) - %s| = %.3e ; non-positive raw values: %d ; log present when raw missing: %d\n",
              pr[1], pr[2], chk(pr[1], pr[2]), sum(P[[pr[1]]] <= 0, na.rm = TRUE),
              sum(is.na(P[[pr[1]]]) & !is.na(P[[pr[2]]]))))
h <- P[, ln_area_harmonized - fifelse(perennial == 1, ln_total_orchard_area, ln_area)]
cat("ln_area_harmonized identity max gap:", max(abs(h), na.rm = TRUE), "\n")

# ---- treatment timing variables versus TREATMENT input
cat("\n==== TREATMENT CODING ====\n")
tp <- unique(P[, .(crop_id, pilot_year, national_year, national_year_alt_table, fullscale_year)])
cat("one timing row per crop:", nrow(tp) == uniqueN(P$crop_id), "\n")
m <- merge(tp, TR[, .(crop_id, role, tr_pilot = pilot_year, tr_nat = national_year, tr_alt = national_year_alt_table,
                      tr_full = fullscale_year)], by = "crop_id", all = TRUE)
eqna <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
cat("panel timing == TREATMENT input (pilot, national, alt, fullscale):",
    all(eqna(m$pilot_year, m$tr_pilot)), all(eqna(m$national_year, m$tr_nat)),
    all(eqna(m$national_year_alt_table, m$tr_alt)), all(eqna(m$fullscale_year, m$tr_full)), "\n")

# identities
P[, clean_chk := as.integer(is.na(pilot_year) | year < pilot_year)]
P[, trans_chk := as.integer(!is.na(pilot_year) & year >= pilot_year & (is.na(national_year) | year < national_year))]
P[, nat_chk   := as.integer(!is.na(national_year) & year >= national_year)]
cat("clean_pre identity mismatches:", sum(P$clean_chk != P$clean_pre), "\n")
cat("transition identity mismatches:", sum(P$trans_chk != P$transition), "\n")
cat("national_treatment identity mismatches:", sum(P$nat_chk != P$national_treatment), "\n")
cat("event_time == year - national_year mismatches:", sum(P$event_time != P$year - P$national_year, na.rm = TRUE), "\n")
cat("cells in >1 of {clean, transition, national}:", sum(P$clean_chk + P$trans_chk + P$nat_chk > 1), "\n")
cat("piloted crop-years in none of the three states:", sum(!is.na(P$pilot_year) & P$clean_chk + P$trans_chk + P$nat_chk == 0), "\n")
# which cells are neither (e.g. pilot but no national year and past pilot?) -> must be transition
cat("crops with pilot_year but no national_year (post-pilot years coded transition):\n")
print(unique(P[!is.na(pilot_year) & is.na(national_year), .(crop_id, role, pilot_year)]))

# ---- crop-level treatment audit table
cat("\n==== CROP-LEVEL TREATMENT TABLE ====\n")
last_clean <- function(cid, v) {
  x <- P[crop_id == cid & year >= 1991 & year <= 2024 & clean_chk == 1 & !is.na(get(v))]
  if (nrow(x)) max(x$year) else NA_integer_
}
T <- merge(TR, XW[, .(crop_id, crop_en_display, crop_group)], by = "crop_id")
T[, last_clean_pre_year_rule := pilot_year - 1]
T[, last_clean_pre_obs_production := vapply(crop_id, last_clean, 0L, v = "ln_production")]
T[, last_clean_pre_obs_area_harm := vapply(crop_id, last_clean, 0L, v = "ln_area_harmonized")]
T[, transition_length := national_year - pilot_year]
T[, reference_event_time := last_clean_pre_obs_production - national_year]
ANN   <- c("soybean", "onion", "sweet_potato", "corn", "garlic", "spring_potato", "red_pepper")
FRUIT <- c("apple", "pear", "tangerine", "sweet_persimmon", "astringent_persimmon", "plum")
T[, analysis_role := fcase(
  crop_id %in% ANN,                    "Annual: treated (headline sample)",
  crop_id %in% FRUIT,                  "Fruit: treated (suggestive)",
  crop_id %in% c("peach", "grape"),    "Fruit: added only in robustness (dates 2004 / 2010)",
  crop_id == "rice",                   "Rice: descriptive single-crop case",
  role == "control_pool",              "Control (annual and fruit samples; clean years only)",
  crop_id == "autumn_potato",          "Coded 'robustness_treated' but not used by any specification",
  role == "excluded",                  "Excluded",
  default = NA_character_)]
T[is.na(analysis_role), analysis_role := role]
T[, verification_status := fifelse(
  crop_id %in% c(ANN, FRUIT, "rice", "peach", "grape"),
  "Coding identities: A (verified from embedded panel). Dates themselves: C (Yearbook 2025 / press release not embedded)",
  "Coding identities: A. Pilot date: C (source not embedded)")]
T[, alternative_dates := paste0("alt table=", national_year_alt_table, "; full-scale=", fullscale_year)]
out <- T[, .(crop = crop_en_display, crop_id, group = crop_group, role_in_input = role, pilot_year, national_year,
             alternative_dates, timing_confidence, last_clean_pre_year_rule, last_clean_pre_obs_production,
             transition_length, reference_event_time, analysis_role, verification_status, conflict_note)]
setorder(out, analysis_role, national_year, crop)
print(out[, 1:13])
fwrite(out, "audit/output/01_treatment_audit_table.csv")

# ---- controls used after own pilot?  (should be impossible by construction)
cat("\n==== CONTROL CLEANLINESS ====\n")
cc <- P[role == "control_pool" & year >= 1991 & !is.na(pilot_year) & year >= pilot_year, .N, by = crop_id]
cat("control-pool crop-years at/after own pilot in panel (these must be excluded by the estimator):\n"); print(cc)
cat("dropped-observation log reasons:\n"); print(DL[, .N, by = reason])

# ---- production identity (section 5)
cat("\n==== PRODUCTION IDENTITY ====\n")
cat("Units: area ha; yield kg/10a; production t.  1 ha = 10 x 10a  =>  kg = area*yield*10 ; t = area*yield/100\n")
A <- P[perennial == 0 & !is.na(area_ha) & !is.na(yield_kg10a) & !is.na(production_t)]
A[, gap_own := log(production_t) - (log(area_ha) + log(yield_kg10a) - log(100))]
cat("stored identity_gap == recomputed gap, max diff:", max(abs(A$gap_own - A$identity_gap)), "\n")
summ_gap <- function(x) c(n = length(x), max_abs = max(abs(x)), p50_abs = median(abs(x)),
                          p95_abs = unname(quantile(abs(x), .95)), p99_abs = unname(quantile(abs(x), .99)),
                          share_gt_0.01 = mean(abs(x) > 0.01), share_gt_0.001 = mean(abs(x) > 0.001))
cat("All annual crops, all years:\n"); print(round(summ_gap(A$gap_own), 6))
E <- A[year >= 1991 & year <= 2024 & crop_id %in% c(ANN, TR[role == "control_pool", crop_id])]
cat("Estimation window 1991-2024, 7 treated + 24 controls:\n"); print(round(summ_gap(E$gap_own), 6))
top <- E[order(-abs(gap_own))][1:10, .(crop_id, year, area_ha, yield_kg10a, production_t, gap_own)]
cat("Largest discrepancies:\n"); print(top)
fwrite(E[, .(crop_id, year, area_ha, yield_kg10a, production_t, gap_own)], "audit/output/01_identity_gaps.csv")
# rows where one of the three is observed but others missing (identity sample != estimation sample)
cat("\nWindow cells with production but no area or yield (annual 31 crops):\n")
print(P[perennial == 0 & year >= 1991 & crop_id %in% c(ANN, TR[role == "control_pool", crop_id]) &
          (!is.na(ln_production) != !is.na(ln_area) | !is.na(ln_production) != !is.na(ln_yield)),
        .(crop_id, year, area_ha, yield_kg10a, production_t)])
sink()
