# =====================================================================
# 07_freeze_verified.R
# Write the frozen verified result files (brief section 20).
# Values are not edited: point estimates and clustered SEs are the
# Python values, confirmed by the independent R replication to <1e-12;
# bootstrap CIs / p-values are the Python-reported values, confirmed by
# R (99,999 draws) within Monte Carlo tolerance. R bootstrap values are
# stored alongside for transparency.
# Run from the repository root after audit/01-06.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
dir.create("verified_results", showWarnings = FALSE)
RS <- fread("audit/extracted/results/RAW_SUMMARY.csv")
RD <- fread("audit/extracted/results/RAW_DYNAMIC.csv")
X  <- fread("audit/output/03_all_specs_R_vs_Py.csv")
DX <- fread("audit/output/03_all_dynamic_R_vs_Py.csv")
RI <- fread("audit/output/03_rice_R_vs_Py.csv")

thesis_spec <- c(
  "CS-A (preferred)" = "Custom group-time DiD, final clean pre-pilot year (preferred)",
  "CS-B (mean of all clean-pre years)" = "Custom group-time DiD, mean of all clean pre-pilot years",
  "CS-B5 (mean of last 5 clean-pre years)" = "Custom group-time DiD, mean of last five clean pre-pilot years",
  "Imputation (FE on clean cells)" = "Imputation estimator (two-way FE fitted on clean cells)",
  "TWFE static, clean cells (benchmark)" = "Static TWFE, clean cells (benchmark only)",
  "TWFE static, Han-style naive coding (benchmark)" = "Static TWFE, naive coding as in Han (2014) (benchmark only)",
  "CS-A main (exact match, annual linking rule)" = "Custom group-time DiD, final clean pre-pilot year: main price sample",
  "CS-B main" = "Custom group-time DiD, mean of all clean pre-pilot years: main price sample")
thesis_outcome <- c(ln_area = "Log cultivated area", ln_yield = "Log yield per 10a", ln_production = "Log production",
                    ln_area_harmonized = "Log orchard area (fruit) / cultivated area (controls)",
                    ln_real_linked = "Log relative farm-gate price index (linked)",
                    ln_real_new = "Log relative farm-gate price index (2005-2024 series)")
lab_spec <- function(s) ifelse(s %in% names(thesis_spec), thesis_spec[s], s)

evidence <- function(sample, spec) fifelse(
  grepl("TWFE", spec), "Benchmark only",
  fifelse(grepl("Cohort 20.. only", spec), "Descriptive (1-4 treated crops; inference degenerate)",
  fifelse(sample == "annual", "Suggestive (B)",
  fifelse(sample == "fruit", "Suggestive, leaning descriptive (B/C)",
  "Weakly suggestive reduced form (B)"))))

# ---------------- summary
S <- merge(RS, X[, .(sample, spec, outcome, R_est, R_se, R_ci_lo = R_lo, R_ci_hi = R_hi, R_p_wild = R_p, R_G,
                     R_pre_p, replication_status = status, abs_diff_est = abs(d_est), abs_diff_se = abs(d_se))],
           by = c("sample", "spec", "outcome"))
S <- S[, .(sample, spec_internal = spec, spec_thesis = lab_spec(spec), outcome_internal = outcome,
           outcome_thesis = thesis_outcome[outcome], evidence_class = evidence(sample, spec),
           est, se_cluster, ci_lo_wild_py = ci_lo_wild, ci_hi_wild_py = ci_hi_wild, p_wild_py = p_wild,
           p_normal_cluster, G, n_treated, n_controls_listed = n_controls, e_range, pre_k, pre_p_boot_py = pre_p_boot,
           pre_mean, n_obs, R_est, R_se, R_ci_lo, R_ci_hi, R_p_wild, R_pre_p, abs_diff_est, abs_diff_se, replication_status,
           bootstrap_draws_py = fifelse(grepl("TWFE", spec), 1999L, 9999L),
           inference_note = fifelse(grepl("TWFE", spec),
             "CR1 crop-clustered SE; p from restricted wild cluster bootstrap-t (Webb, 1,999 draws). No CI reported. Static coefficient over ALL post years (annual up to e=12; fruit up to e=21), not e=0..9.",
             "Custom inference: score-based CR1-type SE; symmetric CI est +/- 95% quantile of |Webb multiplier draws of the crop score sum| (9,999 draws)."))]
S <- S[sample != "price_audit"]
setorder(S, sample, spec_internal, outcome_internal)
fwrite(S, "verified_results/verified_results_summary.csv")

# ---------------- dynamic
Dn <- RD[, .(sample, spec, outcome, event_time = suppressWarnings(as.integer(event_time)), est, se_cluster,
             ci_lo_wild, ci_hi_wild, p_wild, n_treated, n_ctrl_min, n_ctrl_max, G_contrib, treated_crops)]
Dn <- Dn[!is.na(event_time)]
Dn <- merge(Dn, DX[, .(sample, spec, outcome, event_time, R_est = est, R_ci_lo = ci_lo, R_ci_hi = ci_hi, R_p = p_wild)],
            by = c("sample", "spec", "outcome", "event_time"), all.x = TRUE)
Dn[, abs_diff_est := abs(R_est - est)]
Dn[, spec_thesis := lab_spec(spec)][, outcome_thesis := thesis_outcome[outcome]]
Dn[, period := fifelse(event_time < 0, "clean pre-pilot (placebo)", "after nationwide availability")]
setcolorder(Dn, c("sample", "spec", "spec_thesis", "outcome", "outcome_thesis", "event_time", "period"))
setorder(Dn, sample, spec, outcome, event_time)
fwrite(Dn, "verified_results/verified_results_dynamic.csv")
cat("dynamic rows:", nrow(Dn), " max |R - Py|:", max(Dn$abs_diff_est, na.rm = TRUE), " missing R:", Dn[is.na(R_est), .N], "\n")

# ---------------- rice (descriptive)
fwrite(RI[, .(outcome, outcome_thesis = thesis_outcome[outcome], dating, event_time, est = Py_est, R_est,
              abs_diff = abs(R_est - Py_est), n_controls = Py_n_ctrl,
              note = "Single treated crop: descriptive difference only; no inference.")],
       "verified_results/verified_rice_case.csv")

# ---------------- price results (summary rows + main dynamic + linking classification)
LD <- fread("audit/extracted/data/PRICE_LINK_DIAG.csv", encoding = "UTF-8")
PRs <- S[sample == "price"]
PRd <- Dn[sample == "price" & spec == "CS-A main (exact match, annual linking rule)"]
nominal <- X[sample == "price_audit"]
fwrite(rbindlist(list(
  PRs[, .(table = "summary", spec_thesis, outcome_thesis, event_time = NA_integer_, est, se_cluster, ci_lo = ci_lo_wild_py,
          ci_hi = ci_hi_wild_py, p_wild = p_wild_py, G, n_treated, replication_status)],
  PRd[, .(table = "dynamic (main sample)", spec_thesis, outcome_thesis, event_time, est, se_cluster, ci_lo = ci_lo_wild,
          ci_hi = ci_hi_wild, p_wild, G = G_contrib, n_treated, replication_status = "REPLICATED")],
  nominal[, .(table = "audit: undivided crop index (tests divisor cancellation)",
              spec_thesis = "Main price sample on nominal linked crop index (not a thesis estimate)",
              outcome_thesis = "Log nominal farm-gate price index (linked)", event_time = NA_integer_, est = R_est,
              se_cluster = R_se, ci_lo = R_lo, ci_hi = R_hi, p_wild = R_p, G = R_G, n_treated = R_n_tr,
              replication_status = "R-only audit check")]), fill = TRUE),
  "verified_results/verified_price_results.csv")
fwrite(LD[, .(price_unit, display, item_1J49, item_1J60, match_class, linkable_quarterly_rule, linkable_annual_rule,
              price_sample_main, price_sample_strict, annual_corr_dlog, annual_ratio_cv_pct, annual_max_disc_pct,
              corr_qoq_dlog_full_2005_2012, ratio_cv_pct_full_2005_2012, max_abs_disc_pct_full_2005_2012, link_decision)],
       "verified_results/verified_price_linking.csv")

# ---------------- master panel: unchanged values; Korean provenance labels re-decoded (bundle encoding defect)
P <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8", colClasses = "character")   # values passed through as text
redecode <- function(x) { y <- iconv(iconv(x, "UTF-8", "latin1"), "UTF-8", "UTF-8"); ifelse(is.na(y), x, y) }
kcols <- c("crop_ko_official", "kosis_production_label_original", "kosis_price_label_original", "apfs_label_original",
           "insurance_product_variant")
for (v in kcols) P[, (v) := redecode(get(v))]
XW <- fread("audit/extracted/data/PROD_CROSSWALK.csv", encoding = "UTF-8")
stopifnot(all(merge(unique(P[, .(crop_id, crop_ko_official)]), XW[, .(crop_id, k2 = crop_ko_official)])[, crop_ko_official == k2]))
fwrite(P, "verified_results/verified_master_panel.csv", bom = TRUE)

# ---------------- treatment coding (audit table)
fwrite(fread("audit/output/01_treatment_audit_table.csv"), "verified_results/verified_treatment_coding.csv")

# ---------------- APFS (descriptive; embedded public tables)
N <- fread("audit/extracted/data/APFS_NATIONAL.csv", encoding = "UTF-8")
setnames(N, c("year", "farms_enrolled", "contracts", "insured_amount_mkrw", "insured_area_ha", "area_enrollment_rate_pct",
              "net_premium_mkrw", "central_gov_mkrw", "provincial_mkrw", "municipal_mkrw", "farmer_mkrw", "risk_premium_mkrw",
              "claims_paid", "indemnity_mkrw", "loss_ratio_pct"))
N[, components_share_of_net_premium := (central_gov_mkrw + provincial_mkrw + municipal_mkrw + farmer_mkrw) / net_premium_mkrw]
N[, loss_ratio_recomputed := round(indemnity_mkrw / risk_premium_mkrw * 100, 1)]
fwrite(N, "verified_results/verified_apfs_national.csv")
fwrite(fread("audit/extracted/data/APFS_FRUIT_CROP.csv", encoding = "UTF-8"), "verified_results/verified_apfs_fruit_2024_by_crop.csv")
fwrite(fread("audit/extracted/data/APFS_FRUIT_AUD.csv", encoding = "UTF-8"), "verified_results/verified_apfs_fruit_2024_audit.csv")
cat("frozen files:\n"); print(list.files("verified_results"))
