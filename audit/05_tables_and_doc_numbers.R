# =====================================================================
# 05_tables_and_doc_numbers.R
# (a) RESULTS_BUNDLE presentation tables T1-T14 vs underlying RAW sheets
# (b) full-precision values behind every number quoted in DOCUMENTATION.md
# Run from the repository root.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
RS <- fread("audit/extracted/results/RAW_SUMMARY.csv")
RD <- fread("audit/extracted/results/RAW_DYNAMIC.csv")
X  <- fread("audit/output/03_all_specs_R_vs_Py.csv")
lab <- c("Custom group-time DiD, final clean pre-pilot year (preferred)" = "CS-A (preferred)",
         "Custom group-time DiD, mean of all clean pre-pilot years" = "CS-B (mean of all clean-pre years)",
         "Custom group-time DiD, mean of last 5 clean pre-pilot years" = "CS-B5 (mean of last 5 clean-pre years)",
         "Imputation estimator (two-way FE fitted on clean cells)" = "Imputation (FE on clean cells)",
         "Custom group-time DiD, final clean pre-pilot year: main price sample (exact match, annual linking rule)" = "CS-A main (exact match, annual linking rule)",
         "Custom group-time DiD, mean of all clean pre-pilot years: main price sample" = "CS-B main")
oc <- c(Area = "ln_area", Yield = "ln_yield", Production = "ln_production", "Orchard area" = "ln_area_harmonized",
        "Relative price" = "ln_real_linked", "Relative price (2005–2024 series)" = "ln_real_new")

sink("audit/output/05_tables_and_doc_numbers.txt", split = TRUE)
cat("==== (a) presentation tables vs RAW_SUMMARY ====\n")
bad <- 0; n <- 0
for (tb in c("T1_annual_main", "T3_estimator_comparison", "T4_annual_robustness", "T5_leave_one_crop_out",
             "T6_cohort_pretrends", "T7_fruit", "T9_price")) {
  T <- fread(file.path("audit/extracted/results", paste0(tb, ".csv")), encoding = "UTF-8")
  smp <- fifelse(tb == "T7_fruit", "fruit", fifelse(tb == "T9_price", "price", "annual"))
  for (i in seq_len(nrow(T))) {
    sp <- T$Specification[i]; sp <- if (sp %in% names(lab)) lab[[sp]] else sp
    r <- RS[sample == smp & spec == sp & outcome == oc[[T$Outcome[i]]]]
    n <- n + 1
    ci <- if (!is.na(r$ci_lo_wild)) sprintf("[%.3f, %.3f]", r$ci_lo_wild, r$ci_hi_wild) else "—"
    ok <- nrow(r) == 1 && abs(round(r$est, 3) - T$Estimated_change[i]) < 1e-9 &&
      abs(round(r$se_cluster, 3) - T$SE_crop_clustered[i]) < 1e-9 && ci == T$CI95_wild_bootstrap[i] &&
      (is.na(T$p_wild_bootstrap[i]) || abs(round(r$p_wild, 3) - T$p_wild_bootstrap[i]) < 1e-9) &&
      r$G == T$Clusters[i] && r$n_treated == T$Treated_crops[i]
    if (!isTRUE(ok)) { bad <- bad + 1; cat("MISMATCH", tb, i, sp, T$Outcome[i], "\n") }
  }
}
cat("rows checked:", n, " mismatches:", bad, "\n")
for (tb in c("T2_annual_dynamic", "T8_fruit_dynamic", "T10_price_dynamic")) {
  T <- fread(file.path("audit/extracted/results", paste0(tb, ".csv")))
  smp <- c(T2_annual_dynamic = "annual", T8_fruit_dynamic = "fruit", T10_price_dynamic = "price")[[tb]]
  sp  <- if (smp == "price") "CS-A main (exact match, annual linking rule)" else "CS-A (preferred)"
  R <- RD[sample == smp & spec == sp]
  if (!"Outcome" %in% names(T)) T[, Outcome := "Relative price"]
  T[, outcome := oc[Outcome]]
  M <- merge(T, R[, .(outcome, event_time = as.integer(event_time), est)], by = c("outcome", "event_time"))
  cat(tb, ": rows", nrow(T), " matched", nrow(M), " max |round4 diff|", max(abs(M$estimated_change - round(M$est, 4))), "\n")
}

cat("\n==== (b) full-precision values for DOCUMENTATION numbers ====\n")
g <- function(s, o, smp = "annual", v = "est") RS[sample == smp & spec == s & outcome == o][[v]]
show <- function(label, val, claim) cat(sprintf("%-62s %12.6f   doc: %s\n", label, val, claim))
show("A area", g("CS-A (preferred)", "ln_area"), "0.048")
show("A yield", g("CS-A (preferred)", "ln_yield"), "-0.028")
show("A production", g("CS-A (preferred)", "ln_production"), "0.020")
show("A area + A yield", g("CS-A (preferred)", "ln_area") + g("CS-A (preferred)", "ln_yield"), "= 0.020 = production")
show("A area CI lo/hi", g("CS-A (preferred)", "ln_area", v = "ci_lo_wild"), "-0.213")
show("", g("CS-A (preferred)", "ln_area", v = "ci_hi_wild"), "0.310")
show("A yield CI lo/hi", g("CS-A (preferred)", "ln_yield", v = "ci_lo_wild"), "-0.132")
show("", g("CS-A (preferred)", "ln_yield", v = "ci_hi_wild"), "0.075")
show("A prod CI lo/hi", g("CS-A (preferred)", "ln_production", v = "ci_lo_wild"), "-0.287")
show("", g("CS-A (preferred)", "ln_production", v = "ci_hi_wild"), "0.327")
for (o in c("ln_production", "ln_area", "ln_yield")) show(paste("MDE 2.8 x SE", o), 2.8 * g("CS-A (preferred)", o, v = "se_cluster"), "0.45 / 0.39 / 0.15")
show("exp(CI lo)-1 production", exp(g("CS-A (preferred)", "ln_production", v = "ci_lo_wild")) - 1, "-25%")
show("exp(CI hi)-1 production", exp(g("CS-A (preferred)", "ln_production", v = "ci_hi_wild")) - 1, "+38%")
for (o in c("ln_area", "ln_yield", "ln_production")) show(paste("pre Wald p", o), g("CS-A (preferred)", o, v = "pre_p_boot"), "0.35 / 0.67 / 0.41")
show("dates alt-table area", g("Dates: product-table nationwide year", "ln_area"), "0.062")
show("dates alt-table production", g("Dates: product-table nationwide year", "ln_production"), "0.036")
show("pilot clock area", g("Dates: pilot-year clock (no transition exclusion)", "ln_area"), "0.034")
show("pilot clock production", g("Dates: pilot-year clock (no transition exclusion)", "ln_production"), "0.017")
show("fruit AP2001 area", g("Apple and Pear dated 2001", "ln_area_harmonized", "fruit"), "0.130")
show("fruit AP2001 production", g("Apple and Pear dated 2001", "ln_production", "fruit"), "0.117")
show("fruit A area", g("CS-A (preferred)", "ln_area_harmonized", "fruit"), "0.136")
show("fruit A production", g("CS-A (preferred)", "ln_production", "fruit"), "0.115")
for (s in c("Controls: excl. other pulses", "Controls: excl. likely spillover (leaf lettuce, spinach, malting barley)",
            "Controls: field crops only", "Controls: excl. uncertain seasonal forms"))
  show(paste("prod", substr(s, 11, 50)), g(s, "ln_production"), "range -0.105 .. 0.051; field -0.091 [-0.53,0.35]")
show("field-only CI lo", g("Controls: field crops only", "ln_production", v = "ci_lo_wild"), "-0.53")
show("field-only CI hi", g("Controls: field crops only", "ln_production", v = "ci_hi_wild"), "0.35")
show("LOO red pepper production", g("Leave out Red pepper", "ln_production"), "0.132")
show("LOO red pepper prod CI lo", g("Leave out Red pepper", "ln_production", v = "ci_lo_wild"), "-0.10")
show("LOO red pepper prod CI hi", g("Leave out Red pepper", "ln_production", v = "ci_hi_wild"), "0.37")
show("LOO red pepper area", g("Leave out Red pepper", "ln_area"), "0.129")
tab6 <- c("CS-B (mean of all clean-pre years)", "CS-B5 (mean of last 5 clean-pre years)", "Imputation (FE on clean cells)",
          "TWFE static, clean cells (benchmark)", "TWFE static, Han-style naive coding (benchmark)")
for (s in tab6) for (o in c("ln_area", "ln_yield", "ln_production")) show(paste(substr(s, 1, 30), o), g(s, o), "memo s.6 table")
show("p_normal production", g("CS-A (preferred)", "ln_production", v = "p_normal_cluster"), "0.901")
show("p_wild production", g("CS-A (preferred)", "ln_production", v = "p_wild"), "0.903")
show("Cohort 2015 only p (prod)", g("Cohort 2015 only", "ln_production", v = "p_wild"), "0.000")
cat("cohort-only pre-trend Wald p range:", range(RS[grepl("Cohort 20", spec), pre_p_boot]), "  doc: 0.7-1.0\n")
fr <- RS[sample == "fruit" & spec %in% c("CS-B (mean of all clean-pre years)", "TWFE static, clean cells (benchmark)"), est]
cat("fruit B / TWFE range:", range(fr), "  doc: 0.38-0.43\n")
for (s in c("CS-A main (exact match, annual linking rule)", "Strict sample (both linking rules)",
            "Approximate matches included (+ all-potato, pooled vegetable items)", "CS-B main"))
  show(paste("price", substr(s, 1, 40)), g(s, "ln_real_linked", "price"), "-0.118/-0.051/-0.145/-0.019")
show("price new-only 6 crops", g("New series only 2005-2024 (6 exact crops)", "ln_real_new", "price"), "-0.166")
show("price new-only 4 crops", g("New series only 2005-2024 (main 4 crops)", "ln_real_new", "price"), "-0.118")
show("price CI lo", g("CS-A main (exact match, annual linking rule)", "ln_real_linked", "price", "ci_lo_wild"), "-0.289")
show("price CI hi", g("CS-A main (exact match, annual linking rule)", "ln_real_linked", "price", "ci_hi_wild"), "0.052")
for (w in c("Link window 2005-2006", "Link window 2010-2012")) show(w, g(w, "ln_real_linked", "price"), "-0.118")
cat("\nG / treated / controls for preferred annual:", unlist(RS[sample == "annual" & spec == "CS-A (preferred)" & outcome == "ln_production", .(G, n_treated, n_controls)]), "  doc: 29 / 7 / 24\n")
cat("field-only clusters:", RS[spec == "Controls: field crops only" & outcome == "ln_production", G], "  doc: 15\n")
sink()
