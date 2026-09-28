# README — verified empirical outputs for Chapter 5

**Status: audit complete, awaiting your approval. No Chapter 5 prose has been drafted.
No part of the empirical specification has been changed.**

Reproduce everything with `Rscript run_all.R` from the repository root (R ≥ 4.3; data.table, readxl,
ggplot2, MASS; about 3.5 minutes). Inputs are the five uploaded files in `input/`.
The detailed findings are in `audit/AUDIT_REPORT.md`.

## Contents

| Path | What |
|---|---|
| `verified_results/verified_results_summary.csv` | All 102 specifications. Point estimates and clustered SEs confirmed by independent R replication (max diff 4e-13); bootstrap CIs/p are the Python-reported values, confirmed by R within Monte Carlo error (R values stored alongside) |
| `verified_results/verified_results_dynamic.csv` | All 1,671 event-time estimates, with R replication columns |
| `verified_results/verified_master_panel.csv` | Master panel; values byte-identical to the bundle; Korean labels re-decoded (bundle encoding defect E9) |
| `verified_results/verified_treatment_coding.csv` | Crop-level treatment audit table (dates, last clean pre-pilot year, transition length, role, status) |
| `verified_results/verified_price_results.csv`, `verified_price_linking.csv` | Price estimates, main-sample event study, the undivided-index audit check, and linking classification |
| `verified_results/verified_rice_case.csv` | Rice descriptive differences (three datings) |
| `verified_results/verified_apfs_*.csv` | APFS national series (with recomputed loss ratio and financing shares) and 2024 fruit summaries |
| `verified_results/claim_audit.csv` | 129 claims with verification level (A/B/C) and status |
| `verified_results/figure_qc.csv` | Figure QC table |
| `R/00_theme_thesis.R`, `R/style_reference.md` | Thesis theme and the evidence for each style choice |
| `R/01_figure1.R` … `R/11_figureA1.R`, `R/12_figure_qc.R` | Figure scripts (read only `verified_results/`), QC |
| `R/lib/` | Independent estimator (`did_engine.R`, `did_extras.R`) and plotting helpers |
| `figures/` | PNG (2400 px wide) and PDF for Figures 1–10 and A1; `plotdata/` holds exactly what is plotted |
| `audit/` | Audit scripts 00–08 and their outputs |

## What was independently verified (A: from embedded data)

- **Panel.**
  - 43 crops × 45 years, no duplicate crop-years.
  - Logs exact.
  - The identities clean_pre, transition and national_treatment hold for every row.
  - No control is used at or after its own pilot.
- **Production identity.** Production (t) = area (ha) × yield (kg/10a) / 100. On the estimation sample, ln P − ln A − ln Y + ln 100 has median |gap| 0.00014, 95th percentile 0.0035, and maximum 0.074 (Spring radish 2001).
- **Estimator.**
  - It is a custom group-time DiD with clean not-yet-treated and never-treated controls, **not** Callaway–Sant'Anna.
  - Re-derived and re-implemented in R, it reproduces every Python specification: headline area 0.048, yield −0.028, production 0.020, plus all event-time, robustness, fruit, price, imputation, TWFE and rice numbers.
- **Inference.** The custom score-based SE and Webb multiplier bootstrap, and the TWFE WCR, were replicated.
- **DOCUMENTATION numbers.** Nearly all are correct; the exceptions are listed below.
- **Price construction.** Link identity exact; rule flags reproduced; the relative-price definition is as stated.
- **APFS.**
  - National series and 2023 crop table are identical to the embedded public CSVs.
  - Loss ratio = indemnities / risk premium.
  - 2010–2011 components are 75.2% / 74.3% of net premium, with provincial and municipal fields zero.

## What was only internally checked (B)

- Price linking statistics: the quarterly raw series are not embedded.
- APFS province table.
- 2024 fruit contract-detail summaries: 336,232 rows, 12,099 duplicates, shares and quartiles. These are **consistent with the supplied audit summary, not recomputed from raw records**.
- Manifest hashes: DOCUMENTATION and FILE_MANIFEST agree, but the files themselves are absent.

## What still requires original-source verification (C)

- Every treatment date and the crop-year conversion rule (Yearbook 2025, guideline 2026, press release).
- Price-item definitions and the DT_1J50 deflator source file. That file is missing from the manifest.
- The insured-price unit.
- Corn possibly including forage corn.
- Rice-specific policy overlap.
- All institutional, budget and reinsurance figures in the working summary.
- Scientific names.
- Literature and method citations (Callaway–Sant'Anna, Han 2014, imputation, WCR).

## Findings by evidence class

**Suggestive:**
- annual area, yield and production (no statistically detectable change; low power);
- estimator sensitivity (distant-baseline estimators are larger);
- perennial fruit (suggestive at most, leaning descriptive);
- relative farm-gate price (weakly suggestive reduced form; 4 treated crops).

**Descriptive:**
- rice;
- cohort-only estimates (1–4 crops);
- pre-trend slopes;
- all APFS series and cross-sections;
- 2024 fruit records.

## Identification limitations that must remain in the thesis

1. Only 7 (annual), 6 (fruit), and 4 (price) treated clusters. Inference is custom and fragile, and single-crop results are degenerate.
2. The transition gap. ATT(e) includes pilot-period exposure and all change over 3–7 transition years (annual crops); Red pepper shows how large this can be.
3. Non-random timing. Treated crops were rising relative to controls before the pilot (area, production). Failure to reject the joint test is not evidence of parallel trends.
4. Low power. Production changes of about −25% to +39% cannot be excluded.
5. Sensitivity to single crops: Red pepper (+0.11 when left out) and Onion (−0.06 when left out). Control-pool choice changes signs.
6. Availability (intention-to-treat), not coverage. Heterogeneous products sit behind one binary treatment.
7. The control set shrinks at long horizons (22 → 8–11 controls by e = 9).
8. Fruit comparisons:
   - no never-treated perennial controls exist;
   - annual crops (plus two not-yet-treated fruit crops early on) serve as controls;
   - orchard area is compared with cultivated area;
   - the post-period continues the pre-trend.
9. Prices are relative to the all-farm-output index, not CPI-deflated, and jointly determined with production.
10. The APFS 2010–2011 financing residual is unexplained by the public data. It must not be attributed to local government.

## Is Chapter 5 numerically safe to write?

**Yes, conditionally.** Every estimate that Chapter 5 would report has been reproduced by an independent R implementation, and the frozen files in `verified_results/` are safe to cite. Before drafting, you need to approve or reject:

- **(a)** the wording corrections E1–E4, E6, E11 and E12 in `audit/AUDIT_REPORT.md`;
- **(b)** two decisions that would change the specification if accepted:
  - E5: fruit control pool;
  - E7: fruit TWFE control set;
- **(c)** the style choices in `R/style_reference.md` §2: font, in-figure titles, numbering;
- **(d)** names for series not in your approved list.

None of these changes the headline numbers.
