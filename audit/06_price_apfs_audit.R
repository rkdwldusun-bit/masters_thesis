# =====================================================================
# 06_price_apfs_audit.R
# Brief sections 10 (price construction) and 12 (APFS descriptives):
# everything that can be recomputed from embedded tables.
# Run from the repository root.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
PR <- fread("audit/extracted/data/PRICE_ANNUAL.csv")
LD <- fread("audit/extracted/data/PRICE_LINK_DIAG.csv", encoding = "UTF-8")
PX <- fread("audit/extracted/data/PRICE_ITEMS.csv", encoding = "UTF-8")
P  <- fread("audit/extracted/data/MASTER_PANEL.csv", encoding = "UTF-8")
sink("audit/output/06_price_apfs_audit.txt", split = TRUE)

cat("==== PRICE: annual panel construction ====\n")
cat("rows:", nrow(PR), " units:", uniqueN(PR$price_unit), " windows:", unique(PR$link_window), "\n")
cat("duplicate unit x window x year:", sum(duplicated(PR[, .(price_unit, link_window, year)])), "\n")
for (v in c("real_linked", "real_old", "real_new"))
  cat(sprintf("max |log(%s) - ln_%s| = %.2e\n", v, v, max(abs(log(PR[[v]]) - PR[[paste0("ln_", v)]]), na.rm = TRUE)))
cat("annual value present with <4 quarters (linked/old/new):",
    PR[nq_link < 4 & !is.na(real_linked), .N], PR[nq_old < 4 & !is.na(real_old), .N], PR[nq_new < 4 & !is.na(real_new), .N], "\n")
# link identity: for year >= 2005 linked series == new series; before 2005 == old * k
w <- merge(PR, LD[, .(price_unit, k_full = link_factor_full_2005_2012, k_early = link_factor_early_2005_2006,
                      k_late = link_factor_late_2010_2012)], by = "price_unit")
w[, k := fifelse(link_window == "full_2005_2012", k_full, fifelse(link_window == "early_2005_2006", k_early, k_late))]
a <- w[year >= 2005 & !is.na(real_linked)]
cat("year>=2005: max |real_linked - real_new| =", max(abs(a$real_linked - a$real_new), na.rm = TRUE), "\n")
b <- w[year < 2005 & !is.na(real_linked) & !is.na(real_old)]
b[, implied_k := real_linked / real_old]
cat("year<2005: max |real_linked/real_old - link_factor(rounded 4dp in diag)| =", max(abs(b$implied_k - b$k)), "\n")
cat("  within-unit sd of implied k (should be ~0):", max(b[, sd(implied_k), by = .(price_unit, link_window)]$V1, na.rm = TRUE), "\n")
cat("units with linked values before 2005 but no link factor:", b[is.na(k), uniqueN(price_unit)], "\n")

cat("\n==== PRICE: linking rule application (given the reported statistics) ====\n")
LD[, q_rule := corr_qoq_dlog_full_2005_2012 >= 0.90 & ratio_cv_pct_full_2005_2012 <= 5 & max_abs_disc_pct_full_2005_2012 <= 10 &
     match_class %in% c("exact", "approximate")]
LD[, a_rule := annual_corr_dlog >= 0.95 & annual_ratio_cv_pct <= 5 & annual_max_disc_pct <= 10 & match_class %in% c("exact", "approximate")]
LD[is.na(q_rule), q_rule := FALSE]; LD[is.na(a_rule), a_rule := FALSE]
LD[, main := a_rule & match_class == "exact"]; LD[, strict := q_rule & a_rule & match_class == "exact"]
cat("recomputed quarterly/annual/main/strict flags == reported:",
    all(LD$q_rule == LD$linkable_quarterly_rule), all(LD$a_rule == LD$linkable_annual_rule),
    all(LD$main == LD$price_sample_main), all(LD$strict == LD$price_sample_strict), "\n")
print(LD[, .(price_unit, match_class, quarterly = q_rule, annual = a_rule, main, strict,
             ann_corr = annual_corr_dlog, ann_cv = annual_ratio_cv_pct, ann_maxdisc = annual_max_disc_pct)])
# approximate annual-rule check from embedded annual relative series (divisor ~cancels in the ratio)
ap <- PR[link_window == "full_2005_2012" & year %between% c(2005, 2012) & nq_old == 4 & nq_new == 4]
ap <- ap[, .(n = .N, corr = cor(diff(log(real_old)), diff(log(real_new))),
             cv = sd(real_new / real_old) / mean(real_new / real_old) * 100,
             maxdisc = max(abs(real_old * mean(real_new / real_old) / real_new - 1)) * 100), by = price_unit]
ap <- merge(ap, LD[, .(price_unit, annual_corr_dlog, annual_ratio_cv_pct, annual_max_disc_pct)], by = "price_unit")
cat("\nApproximate re-computation of annual-rule statistics from embedded annual RELATIVE series\n",
    "(exact inputs = nominal quarterly series, not embedded):\n")
print(ap[, .(price_unit, n, corr = round(corr, 4), rep_corr = annual_corr_dlog, cv = round(cv, 3), rep_cv = annual_ratio_cv_pct,
             maxdisc = round(maxdisc, 3), rep_maxdisc = annual_max_disc_pct)])

cat("\n==== PRICE: implied annual divisor dispersion (tests 'common divisor') ====\n")
dv <- PR[link_window == "full_2005_2012" & !is.na(linked) & !is.na(real_linked)]
dv[, implied_divisor := linked / real_linked * 100]
dd <- dv[, .(n_units = .N, min = min(implied_divisor), max = max(implied_divisor),
             range_pct = (max(implied_divisor) / min(implied_divisor) - 1) * 100), by = year]
cat("If the divisor were common within a year, range_pct would be 0. Summary of range_pct across years:\n")
print(summary(dd$range_pct)); print(dd[order(-range_pct)][1:5])

cat("\n==== PRICE: master panel columns vs PRICE_ANNUAL ====\n")
m <- merge(P[!is.na(price_unit) & price_unit != "", .(crop_id, price_unit, year, relative_price_index, ln_rel_price_linked, ln_rel_price_new)],
           PR[link_window == "full_2005_2012", .(price_unit, year, real_linked, ln_real_linked, ln_real_new)], by = c("price_unit", "year"))
cat("rows:", nrow(m), " max |relative_price_index - real_linked|:", max(abs(m$relative_price_index - m$real_linked), na.rm = TRUE),
    " max |ln_rel_price_linked - ln_real_linked|:", max(abs(m$ln_rel_price_linked - m$ln_real_linked), na.rm = TRUE), "\n")
cat("crosswalk classes:\n"); print(PX[, .(price_unit, display, match_class, production_crop_ids)])

# ============================== APFS
cat("\n\n==== APFS national series ====\n")
N  <- fread("audit/extracted/data/APFS_NATIONAL.csv", encoding = "UTF-8")
E  <- fread("audit/extracted/data/APFS_ENROLL_RAW.csv", encoding = "UTF-8")
PM <- fread("audit/extracted/data/APFS_PAY_RAW.csv", encoding = "UTF-8")
setnames(N, c("year", "farms", "contracts", "insured_amt", "insured_area", "area_rate", "net_prem", "central", "province",
              "municipal", "farmer", "risk_prem", "claims", "indemnity", "loss_ratio"))
setnames(E, c("year", "farms", "contracts", "insured_amt", "insured_area", "area_rate", "net_prem", "central", "province",
              "municipal", "farmer", "risk_prem"))
setnames(PM, c("year", "claims", "indemnity", "loss_ratio"))
PM[, year := as.integer(sub("년", "", year))]
chk <- merge(E, PM, by = "year", all.x = TRUE)
cols <- setdiff(names(N), "year")
cat("APFS_NATIONAL == merge(ENROLL_RAW, PAY_RAW):",
    all(vapply(cols, function(v) isTRUE(all.equal(as.numeric(N[[v]]), as.numeric(chk[[v]]))), TRUE)), "\n")
N[, comp_sum := central + province + municipal + farmer]
N[, comp_share := comp_sum / net_prem]
N[, lr_recalc := indemnity / net_prem * 100]
print(N[, .(year, net_prem, central, province, municipal, farmer, comp_share = round(comp_share, 4),
            loss_ratio, lr_recalc = round(lr_recalc, 1), area_rate)])
cat("max |reported loss ratio - indemnity/net premium*100| (2001-2023):", max(abs(N$loss_ratio - N$lr_recalc), na.rm = TRUE), "\n")
cat("2010-2011 component share of net premium:", round(N[year %in% 2010:2011, comp_share], 4),
    "; provincial+municipal:", N[year %in% 2010:2011, province + municipal], "\n")

cat("\n==== APFS 2023 crop-level ====\n")
C23 <- fread("audit/extracted/data/APFS_CROP_2023.csv", encoding = "UTF-8")
C23r <- fread("audit/extracted/data/APFS_CROPJOIN23.csv", encoding = "UTF-8")
cat("derived == raw (values):", isTRUE(all.equal(unname(as.list(C23)), unname(as.list(C23r)))), " rows:", nrow(C23), "\n")
setnames(C23r, 1, "crop")
tot <- C23r[, .(net_prem = sum(`순보험료`), prem_after = sum(`환급금 차감 후 순보험료`), indemnity = sum(`보험금`))]
cat("sum over crops: net premium", tot$net_prem, " after refunds", tot$prem_after, " indemnity", tot$indemnity,
    " -> loss ratio", round(tot$indemnity / tot$prem_after * 100, 2), "\n")
cat("  national 2023: net premium (after refunds)", N[year == 2023, net_prem], " indemnity", N[year == 2023, indemnity],
    " loss ratio", N[year == 2023, loss_ratio], "\n")
C23r[, lr := `보험금` / `환급금 차감 후 순보험료` * 100]
cat("max |loss ratio - indemnity/premium after refunds|:", max(abs(C23r$lr - C23r$`손해율`), na.rm = TRUE), "\n")

cat("\n==== APFS province 2023/2024 ====\n")
PV <- fread("audit/extracted/data/APFS_PROV_23_24.csv", encoding = "UTF-8")
setnames(PV, 1, "region")
for (yy in c("2023", "2024")) {
  nat <- PV[region == "전국"]; reg <- PV[region != "전국"]
  for (v in c("가입농가수", "가입건수", "환급금차감후순보험료", "보험금")) {
    col <- paste0(v, "_", yy)
    cat(yy, v, ": national", nat[[col]], " sum of regions", round(sum(reg[[col]]), 3), "\n")
  }
  cat(yy, "loss ratio national:", round(nat[[paste0("손해율_", yy)]], 3), " recomputed:",
      round(nat[[paste0("보험금_", yy)]] / nat[[paste0("환급금차감후순보험료_", yy)]] * 100, 3), "\n")
}
cat("regions:", paste(PV$region, collapse = ","), "\n")

cat("\n==== APFS 2024 fruit contract-detail summaries ====\n")
FA <- fread("audit/extracted/data/APFS_FRUIT_AUD.csv", encoding = "UTF-8")
FC <- fread("audit/extracted/data/APFS_FRUIT_CROP.csv", encoding = "UTF-8")
print(FA)
n_all <- as.numeric(FA[item == "rows in file", value]); n_rev <- as.numeric(FA[grepl("revenue", item), value])
cat("sum of crop-level records:", sum(FC$records), " = rows - revenue grape rows:", n_all - n_rev,
    " -> ", sum(FC$records) == n_all - n_rev, "\n")
cat("sum of records_zero_or_invalid_yield:", sum(FC$records_zero_or_invalid_yield), " vs audit (incl. revenue grape):",
    FA[grepl("zero/invalid", item), value], "\n")
FC[, share_sum := share_ratio_below_1 + share_ratio_equal_1 + share_ratio_above_1]
cat("share triplets sum to 1 (max |sum-1|):", max(abs(FC$share_sum - 1)), "\n")
print(FC[order(-records), .(crop, records, below = round(share_ratio_below_1, 4), equal = round(share_ratio_equal_1, 4),
                            above = round(share_ratio_above_1, 4), ins_price_p25 = insured_price_p25,
                            ins_price_med = insured_price_median, ins_price_p75 = insured_price_p75)])
cat("crops in file:", nrow(FC), "\n")
sink()
