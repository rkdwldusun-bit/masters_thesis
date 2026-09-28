# Reproduce the audit, the frozen verified results and all figures.
# Run from the repository root:  Rscript run_all.R
# Requires R >= 4.3 with data.table, readxl, ggplot2, MASS; python3 for the memo step.
Sys.setlocale("LC_ALL", "C.UTF-8")

steps <- c(
  "audit/00_extract_bundles.R",          # bundle sheets -> audit/extracted/*.csv
  "audit/01_panel_treatment_audit.R",    # panel, treatment identities, production identity
  "audit/02_replicate_main.R",           # independent R replication: headline + event study
  "audit/03_replicate_all_specs.R",      # all 102 specifications + rice (about 3 minutes)
  "audit/04_pretrend_fruit_redpepper.R", # pre-trend, Red pepper, fruit control composition
  "audit/05_tables_and_doc_numbers.R",   # presentation tables and DOCUMENTATION numbers
  "audit/06_price_apfs_audit.R",         # price construction and APFS descriptives
  "audit/06b_corrected_benchmarks.R",    # approved corrections: horizon-matched / same-pool TWFE, support tables
  "audit/07_freeze_verified.R",          # verified_results/*
  "audit/08_claim_audit.R",              # verified_results/claim_audit.csv
  "audit/09_corrected_memo.py",          # docs/METHODOLOGICAL_MEMO_v3.md (approved wording corrections)
  sprintf("R/%02d_figure%s.R", 1:11, c(1:10, "A1")),
  "R/12_figure_qc.R")

for (s in steps) {
  message("== ", s)
  status <- system2(if (grepl("\\.py$", s)) "python3" else "Rscript", s)
  if (status != 0) stop("failed: ", s)
}
file.copy("figures/figure_qc.csv", "verified_results/figure_qc.csv", overwrite = TRUE)
