# README — verified empirical outputs for Chapter 5

**Status: EMPIRICAL PACKAGE LOCKED (2026-09-28).** The audit was approved and the approved corrections were
applied (`audit/AUDIT_REPORT.md` §8). The preferred estimator and the headline annual estimates are unchanged.
No Chapter 5 prose has been drafted. Corrected package wording: `docs/METHODOLOGICAL_MEMO_v3.md`;
provenance: `docs/PROVENANCE.md`.

Reproduce everything with `Rscript run_all.R` from the repository root (R ≥ 4.3; data.table, readxl,
ggplot2, MASS; about 3.5 minutes). Inputs are the five uploaded files in `input/`.
The detailed findings are in `audit/AUDIT_REPORT.md`.

## Contents

| Path | What |
|---|---|
| `verified_results/verified_results_summary.csv` | All 102 Python specifications plus the 10 corrected benchmark rows. Point estimates and clustered SEs of the Python rows confirmed by independent R replication (max diff 4e-13); their bootstrap CIs/p are the Python-reported values, confirmed by R within Monte Carlo error (R values stored alongside). Column `benchmark_status` marks the LEGACY (all-post) and SUPERSEDED (non-comparable pool) TWFE rows; the corrected benchmarks are R-only, computed from embedded data |
| `verified_results/verified_benchmark_record.csv` | Record of every TWFE benchmark: CURRENT (e = 0…9 annual; same-pool fruit), SUPPLEMENTARY, LEGACY, SUPERSEDED |
| `verified_results/verified_event_time_support.csv`, `verified_control_composition.csv` | Code-consistent support tables (identical to RESULTS T12/T13); replace the stale EVENT_SUPPORT / COHORT_SUPPORT / CONTROL_COMP sheets |
| `verified_results/verified_identity_discrepancies.csv` | Crop-years whose log production identity gap exceeds 0.01 (source values unchanged) |
| `verified_results/verified_results_dynamic.csv` | All 1,671 event-time estimates, with R replication columns |
| `verified_results/verified_master_panel.csv` | Master panel; numeric values byte-identical to the bundle; the five Korean provenance columns carry the repaired UTF-8 labels (all 43 match the production crosswalk) |
| `verified_results/verified_treatment_coding.csv` | Crop-level treatment audit table (dates, last clean pre-pilot year, transition length, role, status) |
| `verified_results/verified_price_results.csv`, `verified_price_linking.csv` | Price estimates, main-sample event study, the nominal-index comparison (numerically almost identical), and linking classification |
| `verified_results/verified_rice_case.csv` | Rice descriptive differences (three datings) |
| `verified_results/verified_apfs_*.csv` | APFS national series (loss ratio = indemnities / risk premium × 100, recomputed; financing shares) and 2024 fruit summaries (audit label corrected: missing or non-positive normal yield) |
| `verified_results/claim_audit.csv` | 139 claims with verification level (A/B/C) and status; resolutions appended to `notes` |
| `verified_results/figure_qc.csv` | Figure QC table |
| `R/00_theme_thesis.R`, `R/style_reference.md` | Thesis theme and the evidence for each style choice |
| `R/01_figure1.R` … `R/11_figureA1.R`, `R/12_figure_qc.R` | Figure scripts (read only `verified_results/`), QC |
| `R/lib/` | Independent estimator (`did_engine.R`, `did_extras.R`) and plotting helpers |
| `figures/` | PNG (2400 px wide) and PDF for Figures 1–10 and A1; `plotdata/` holds exactly what is plotted |
| `audit/` | Audit scripts 00–09 and their outputs (stale bundle sheets quarantined in `audit/extracted/*/stale_do_not_use/`) |
| `docs/` | `METHODOLOGICAL_MEMO_v3.md` (approved corrections applied, with change log), `PROVENANCE.md` |

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
- **Corrected benchmarks** (computed in R from embedded data): annual TWFE over e = 0…9 (clean 0.243 / −0.028 / 0.215; naive 0.156 / −0.021 / 0.135); fruit TWFE on the preferred fruit pool (0.414 / 0.399). The legacy all-post and superseded annual-controls-only versions are retained and labelled.
- **Inference.** The custom score-based SE and Webb multiplier bootstrap, and the TWFE WCR, were replicated.
- **DOCUMENTATION numbers.** Nearly all were correct; the exceptions (E1–E12) are corrected in `docs/METHODOLOGICAL_MEMO_v3.md` and `docs/PROVENANCE.md`.
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
- Price-item definitions and the DT_1J50 all-farm-output source file (documented in `docs/PROVENANCE.md`; its hash must still be added by you), and which of the two vegetable files named `08_…` / `10_…` holds which KOSIS table.
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
3. Non-random timing. Treated crops were rising relative to controls before the pilot. All four production leads at e = −12 to −9 are individually significant; for area, e = −12, −10 and −9 are significant and e = −11 is marginal (p ≈ 0.058); yield shows no pre-trend. The joint tests do not reject (p = 0.35 area, 0.67 yield, 0.40 production), and failure to reject is not evidence of parallel trends.
4. Low power. Production changes of about −25% to +39% cannot be excluded.
5. The aggregate estimate is sensitive to individual crops: Red pepper exerts a sizable negative influence (leaving it out raises production from 0.020 to 0.132) and Onion a sizable influence in the opposite direction (leaving it out lowers production to −0.044). Control-pool choice changes signs.
6. Availability (intention-to-treat), not coverage. Heterogeneous products sit behind one binary treatment.
7. Control support. Although 24 control-pool series are listed, only 22 contribute to the preferred estimation, and eligible control support shrinks substantially at later event times (8–11 controls per treated crop by e = 9).
8. Fruit comparisons:
   - no never-treated perennial controls exist;
   - the comparison group consists primarily of annual crops, while later-treated fruit crops may also serve as not-yet-treated controls during their clean pre-pilot periods (Astringent persimmon and Plum contribute in some comparisons);
   - orchard area is compared with cultivated area;
   - the post-period continues the pre-trend.
9. Prices are relative farm-gate price indices (crop index ÷ linked all-farm-output price index), not CPI-deflated, and jointly determined with production. Relative-price and nominal-index estimates are numerically almost identical; the small difference arises because annual relative prices are built from quarterly relative indices.
10. The APFS 2010–2011 financing residual is unexplained by the public data. It must not be attributed to local government. Loss ratios are indemnities / risk premium.
11. Area, yield and production estimates are approximately consistent with the log production identity (0.048 − 0.028 = 0.020 vs 0.0199), not exactly; two crop-years (Spring radish 2001, Sesame 2020) show identity gaps above 0.01 in the source data, which are kept unchanged.

## Is Chapter 5 numerically safe to write?

**Yes. The empirical package is locked.** Every number Chapter 5 would report is in `verified_results/`,
reproduced by an independent R implementation (group-time, imputation, legacy TWFE) or computed in R from
embedded data (corrected benchmarks), and every approved wording correction is applied in
`docs/METHODOLOGICAL_MEMO_v3.md`. The preferred estimator and the headline estimates are unchanged.

Still open, none of them numerical:
- **(c)** the style choices in `R/style_reference.md` §2 (font, in-figure titles, numbering);
- **(d)** English names for series not on your list (Other pulses, Malting barley, Ginger, seasonal Napa cabbage / Radish forms, Walnut);
- the AUTHOR ACTION items in `docs/PROVENANCE.md` and all level-C source checks.
