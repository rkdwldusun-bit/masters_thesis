# =====================================================================
# 12_treatment_timing_rule.R -- reproduce Table 3 from announcement dates
# Input : input/treatment_timing_sources.csv (hand-coded from Yearbook 2025,
#         2026 guideline sales windows, KREI R615 (2010) and KREI 2023-57;
#         one row per treated annual crop)
# Rule  : an announcement in month m of year y first applies to the sales
#         window of year y if that window ends in or after m, otherwise to
#         the window of year y + 1. Crop (harvest) year = window year +
#         harvest_offset (1 for autumn-planted onion and garlic).
#         The same rule converts pilot and expansion announcements.
# Assumption: historical sales windows equal the 2026 ones. pilot_sale_status /
#         expansion_sale_status record how far the KREI reports confirm the
#         first sales season (confirmed / partial / not verified / contradicted).
# Output: audit/output/12_treatment_timing_rule.csv; stops if the rule does
#         not reproduce verified_results/verified_treatment_coding.csv.
# =====================================================================

library(data.table)

S <- fread("input/treatment_timing_sources.csv", encoding = "UTF-8")
V <- fread("verified_results/verified_treatment_coding.csv", encoding = "UTF-8")

crop_year <- function(announce, end_month, offset) {
  y <- as.integer(substr(announce, 1, 4)); m <- as.integer(substr(announce, 6, 7))
  ifelse(end_month >= m, y, y + 1L) + offset
}

S[, `:=`(pilot_year     = crop_year(pilot_announce, window_end_month, harvest_offset),
         expansion_year = crop_year(expansion_announce, window_end_month, harvest_offset))]
# months between the announcement and the end of that year's sales window; 0-1 means the
# coded year flips if the historical window ended a month earlier than in 2026
S[, `:=`(pilot_margin_months     = window_end_month - as.integer(substr(pilot_announce, 6, 7)),
         expansion_margin_months = window_end_month - as.integer(substr(expansion_announce, 6, 7)))]
S[, `:=`(reference_year   = pilot_year - 1L,
         transition_years = expansion_year - pilot_year,
         product_table_minus_expansion = product_table_year - expansion_year)]

chk <- merge(S, V[, .(crop_id, v_pilot = pilot_year, v_nat = national_year)], by = "crop_id")
chk[, match := pilot_year == v_pilot & expansion_year == v_nat]
print(chk[, .(crop, pilot_announce, expansion_announce, window = paste0(window_start_month, "-", window_end_month),
              harvest_offset, pilot_year, pilot_margin_months, expansion_year, expansion_margin_months,
              product_table_year, reference_year, transition_years, match)])
print(S[, .(crop, pilot_sale_status, expansion_sale_status)])
stopifnot(nrow(chk) == 7, all(chk$match))

dir.create("audit/output", showWarnings = FALSE)
fwrite(S[, .(crop, pilot_announce, pilot_source, expansion_announce, expansion_source,
             window_start_month, window_end_month, harvest_offset, window_source,
             pilot_year, pilot_margin_months, expansion_year, expansion_margin_months, product_table_year, product_table_source,
             product_table_minus_expansion, reference_year, transition_years,
             pilot_sale_status, pilot_sale_evidence, expansion_sale_status, expansion_sale_evidence,
             sales_regions_pilot, sales_regions_expansion, note)],
       "audit/output/12_treatment_timing_rule.csv")
