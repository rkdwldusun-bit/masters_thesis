# =====================================================================
# 13_expansion_date_sensitivity.R -- sensitivity of the annual-crop
# estimates to the expansion (first nationwide sales) year.
# Baseline: Table 3 expansion years (Yearbook 2025 본사업 month converted
# to a harvest year). Alternative: harvest year of the first nationwide
# sales season documented in MAFRA press releases
# (input/treatment_timing_sources.csv, expansion_sale_evidence):
#   soybean 2011, sweet potato 2012, corn 2012, red pepper 2014;
#   onion 2012 and garlic 2013 unchanged; spring potato unchanged (undocumented).
# Pilot years, reference years and controls are unchanged.
# Output: audit/output/13_expansion_date_sensitivity.csv
# =====================================================================

suppressPackageStartupMessages(library(data.table))
source("R/lib/did_engine.R")
`%||%` <- function(a, b) if (is.null(a)) b else a

P   <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
ANN <- c("soybean", "onion", "sweet_potato", "corn", "garlic", "spring_potato", "red_pepper")
CTRL <- sort(unique(P[role == "control_pool", crop_id]))

S <- fread("input/treatment_timing_sources.csv", encoding = "UTF-8")
stopifnot(!anyNA(S$expansion_sale_year_documented[S$crop_id != "spring_potato"]))
alt <- S[!is.na(expansion_sale_year_documented), setNames(expansion_sale_year_documented, crop_id)]

P_alt <- copy(P)[crop_id %in% names(alt), national_year := alt[crop_id]]
panels <- list(baseline = P, first_nationwide_sale = P_alt)
sets   <- list(all7 = ANN, excl_spring_potato = setdiff(ANN, "spring_potato"))

rows <- list(); k <- 0
for (pn in names(panels)) for (st in names(sets)) for (o in c("ln_area", "ln_yield", "ln_production")) {
  k <- k + 1
  r <- run_gt(panels[[pn]], o, sets[[st]], CTRL, B = 9999, seed = 20260927 + k)
  rows[[k]] <- data.table(dates = pn, treated = st, outcome = o, est = r$overall$est,
                          ci_lo = r$overall$ci_lo, ci_hi = r$overall$ci_hi, p_wild = r$overall$p_wild,
                          pre_p_boot = r$overall$pre_p_boot %||% NA_real_, n_treated = r$overall$n_treated)
}
X <- rbindlist(rows)
print(X[, .(dates, treated, outcome, est = round(est, 3), ci = sprintf("[%.3f, %.3f]", ci_lo, ci_hi),
            p_wild = round(p_wild, 3), pre_p = round(pre_p_boot, 3))])
dir.create("audit/output", showWarnings = FALSE)
fwrite(X, "audit/output/13_expansion_date_sensitivity.csv")
