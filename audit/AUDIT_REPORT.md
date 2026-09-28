# Chapter 5 — Statistical audit report

Audit date: 2026-09-28. Scope: the five uploaded files (`input/`). The preferred estimator and the
headline estimates are unchanged. The corrections in §6 were **approved on 2026-09-28 and applied**;
see §8 for exactly what changed.

Verification labels: **A** = verified from embedded data · **B** = internally consistent, raw source
not embedded · **C** = external source verification required.

---

## 1. Inventory

**Data available (DATA_BUNDLE.xlsx, 22 sheets).**
- Analysis-ready master panel: 43 crops × 1980–2024 = 1,935 rows.
- Treatment-coding input, production crosswalk, nomenclature.
- Annual price panel: 31 units × 3 link windows.
- Price-item crosswalk, linking diagnostics, deflator link parameters.
- APFS tables:
  - three original public CSVs (national enrollment, national payments, 2023 crop-level);
  - derived national series, 2023 crop table, 2023/2024 province table;
  - 2024 fruit contract-detail crop summary and audit summary.
- Support sheets, dropped-observation log, KOSIS metadata, file manifest.

**Original data missing (FILE_MANIFEST = FALSE or not listed).**
- All 11 KOSIS production spreadsheets.
- DT_1J49 quarterly crop-price file and the DT_1J60 file.
- `price_quarterly_raw_all_tables.csv`, `price_linked_quarterly.csv`, `price_deflator_quarterly.csv`.
- The 336,232-row APFS 2024 fruit contract-detail CSV.
- All 7 PDFs (Yearbook 2025, guideline 2026, evaluations, JEP article).
- The DT_1J50 (2005=100) all-farm-output file `12_farm_output_price_index_2005.xlsx`, which `02_build_prices.py` reads, is **in neither manifest**.

**Scripts (CODE_BUNDLE.md).**

| Script | Inputs → outputs |
|---|---|
| `01_build_panel.py` | 11 KOSIS files + `treatment_coding_input.csv` (read from the *output* folder) → production panel, crosswalk, dropped log |
| `02_build_prices.py` | DT_1J49, DT_1J60, DT_1J50 → crosswalk, linking diagnostics, linked quarterly/annual panels, deflator |
| `est_engine.py` | Estimators and inference (see §3) |
| `03_estimate.py` | Panel + price panel → `results_summary_all_specs`, `results_dynamic_all_specs`, `results_rice_case`, old-series feasibility |
| `04_figures.py` | Results → Figures 1–6 |
| `05_apfs_descriptives.py` | Raw APFS CSVs → Figures 7–10, A1, fruit summaries |
| `06_final_tables.py` | Everything → master panel v2, nomenclature, `ch5_results_tables.xlsx` |
| `run_all.sh` | Runs 01–06 |

**Final results (RESULTS_BUNDLE.xlsx).**
- T1–T19 presentation tables.
- `RAW_SUMMARY`: 102 specifications.
- `RAW_DYNAMIC`: 1,671 event-time rows.
- `RAW_RICE`: 135 rows.
- Old-series feasibility, support sheets, figure manifest (hashes only).

**Tables and the analyses they report.**

| Table | Analysis |
|---|---|
| T1 | Headline |
| T2 | Figure 1 |
| T3 | Figure 2 |
| T4 | Figure 3 |
| T5 | Leave-one-crop-out |
| T6 | Cohort-only |
| T7, T8 | Fruit / Figure 4 |
| T9, T10 | Price / Figure 5 |
| T11 | Rice / Figure 6 |
| T12–T14 | Support and pre-trend slopes |
| T15, T17 | Price linking |
| T18 | Treatment coding |

**Claim hierarchy (memo §11).**
- **Main (suggestive):** annual-crop area, yield, production.
- **Secondary (suggestive):** estimator sensitivity; perennial fruit (leaning descriptive); relative price (weakly suggestive).
- **Descriptive:** rice, cohort-only estimates, pre-trend slopes, APFS national / crop / province series, 2024 fruit records.

---

## 2. Estimator identity (brief §3, most important)

`est_engine.cs_weights` implements exactly:

> ATT_i(e) = [Y_i,g_i+e − Y_i,b_i] − mean_j [Y_j,g_i+e − Y_j,b_i], where b_i is crop i's last clean pre-pilot year and j ranges over every other crop in the sample that is clean (never piloted, or before its own pilot) in **both** years; ATT(e) is the equal-weighted mean over treated crops; the headline is the mean over e = 0…9.

- There is no outcome regression, no propensity score, no cohort-size weighting, and no covariates.
- The description **"a custom group-time difference-in-differences estimator using clean not-yet-treated and never-treated controls"** is accurate.
- It is **not** the Callaway–Sant'Anna estimator.
- Internal identifiers still read `CS-A`, `CS-B`, `run_cs`, `cs_weights`. These must never appear in thesis text.

The independent R implementation (`R/lib/did_engine.R`) was written from this definition, not translated from the Python. It computes point estimates directly from the formula, with a separate linear-weight form used only for inference.

---

## 3. R replication result

Tolerances:
- **Point estimates:** 1e-6. The largest observed difference over all 102 specifications is 4.4e-13, and 7.1e-13 over all 1,671 event-time rows.
- **Clustered SEs:** 1e-6. The largest observed difference is 5.6e-15.
- **Bootstrap CIs:** within 0.08 × SE, about 3 Monte Carlo standard deviations. R used its own RNG with 99,999 draws; Python used 9,999.
- **Bootstrap p-values:** within 0.03.

| Outcome | Python | R | CI (Python, 9,999 draws) | CI (R, 99,999 draws) |
|---|---|---|---|---|
| Area | 0.048419 | 0.048419 | [−0.213, 0.310] | [−0.217, 0.314] |
| Yield | −0.028405 | −0.028405 | [−0.132, 0.075] | [−0.133, 0.076] |
| Production | 0.019883 | 0.019883 | [−0.287, 0.327] | [−0.282, 0.322] |

**Result:** all 102 specifications are REPLICATED. This covers:
- the estimator comparison, including imputation, TWFE clean and TWFE naive;
- dates, control pools, and leave-one-out (LOO) specifications;
- cohort-only estimates;
- fruit;
- price.

All 135 rice values also match exactly. There is no material discrepancy, so the stop rule was not triggered.

---

## 4. Event study (Figure 1), annual crops, preferred specification

CI = reported 95% wild-bootstrap interval (Python). R reproduces every point estimate to about 2e-15 and every interval within Monte Carlo error. Every row is **A / VERIFIED**. e = −4 … −1 are never estimated (transition).

| e | treated | controls (min–max) | G | area | area 95% CI | yield | yield 95% CI | production | production 95% CI | p (prod.) |
|---|---|---|---|---|---|---|---|---|---|---|
| -12 | 7 | 22–28 | 29 | -0.234 | [-0.461, -0.007] | -0.066 | [-0.181, 0.048] | -0.299 | [-0.543, -0.055] | 0.013 |
| -11 | 7 | 22–28 | 29 | -0.147 | [-0.297, 0.004] | -0.004 | [-0.095, 0.087] | -0.150 | [-0.282, -0.017] | 0.023 |
| -10 | 7 | 22–28 | 29 | -0.155 | [-0.298, -0.013] | -0.006 | [-0.078, 0.066] | -0.161 | [-0.289, -0.033] | 0.011 |
| -9 | 7 | 22–28 | 29 | -0.130 | [-0.252, -0.008] | -0.048 | [-0.151, 0.055] | -0.178 | [-0.328, -0.027] | 0.017 |
| -8 | 6 | 22–28 | 29 | -0.001 | [-0.160, 0.159] | -0.014 | [-0.073, 0.046] | -0.014 | [-0.182, 0.154] | 0.881 |
| -7 | 6 | 22–28 | 29 | -0.008 | [-0.155, 0.140] | 0.009 | [-0.060, 0.077] | 0.001 | [-0.181, 0.182] | 0.994 |
| -6 | 5 | 22–28 | 29 | 0.033 | [-0.052, 0.117] | 0.005 | [-0.068, 0.078] | 0.038 | [-0.103, 0.179] | 0.695 |
| -5 | 2 | 22–25 | 26 | 0.116 | [-0.015, 0.248] | -0.008 | [-0.064, 0.049] | 0.108 | [-0.042, 0.259] | 0.306 |
| 0 | 7 | 22–22 | 29 | 0.122 | [-0.159, 0.403] | 0.019 | [-0.047, 0.085] | 0.140 | [-0.142, 0.423] | 0.351 |
| 1 | 7 | 22–22 | 29 | 0.027 | [-0.228, 0.282] | 0.031 | [-0.063, 0.126] | 0.058 | [-0.226, 0.342] | 0.705 |
| 2 | 7 | 20–22 | 29 | -0.009 | [-0.298, 0.280] | -0.040 | [-0.169, 0.089] | -0.050 | [-0.416, 0.316] | 0.805 |
| 3 | 7 | 20–22 | 29 | -0.053 | [-0.340, 0.233] | -0.001 | [-0.100, 0.098] | -0.054 | [-0.370, 0.261] | 0.737 |
| 4 | 7 | 15–22 | 29 | 0.004 | [-0.251, 0.258] | -0.089 | [-0.187, 0.009] | -0.085 | [-0.372, 0.202] | 0.571 |
| 5 | 7 | 14–20 | 27 | 0.039 | [-0.208, 0.285] | -0.092 | [-0.230, 0.046] | -0.054 | [-0.339, 0.231] | 0.733 |
| 6 | 7 | 11–20 | 27 | 0.164 | [-0.144, 0.471] | -0.025 | [-0.127, 0.076] | 0.139 | [-0.168, 0.445] | 0.388 |
| 7 | 7 | 10–15 | 22 | 0.166 | [-0.139, 0.471] | -0.009 | [-0.172, 0.154] | 0.158 | [-0.223, 0.538] | 0.453 |
| 8 | 7 | 10–14 | 21 | 0.036 | [-0.273, 0.345] | -0.034 | [-0.195, 0.127] | 0.002 | [-0.385, 0.390] | 0.990 |
| 9 | 7 | 8–11 | 18 | -0.012 | [-0.354, 0.331] | -0.044 | [-0.241, 0.154] | -0.055 | [-0.491, 0.382] | 0.806 |

**Pre-trend: statistical test result.** The joint bootstrap Wald test does not reject: p = 0.346 (area), 0.670 (yield), 0.405 (production). With 7 treated crops this test has low power, and **non-rejection is not evidence that parallel trends hold.**

**Pre-trend: visual / substantive pattern.**
- Area and production leads at e = −12…−9 are clearly negative, about −0.13 to −0.30. All four production leads and three of four area leads are individually significant at 5% (area e = −11: p = 0.058).
- The leads then jump to about 0 at e = −8…−6 and are positive at e = −5, which rests on 2 crops.
- The claim that treated crops were growing relative to controls before the pilot is **supported** for area and production, and not for yield.
- The OLS slope of +0.047 (area) / +0.053 (production) per year is a summary only. The pattern is closer to a shift between e = −9 and −8, and the composition changes there: Red pepper leaves the pre sample after e = −9.

**Control support shrinks.** The post-period control set falls from 22 (e = 0) to 8–11 (e = 9), and G falls from 29 to 18.

---

## 5. Inference audit

- **Scores.** Each estimator is linear, θ = Σ a_ct·Y_ct, and each crop's score is ψ_c = Σ_t a_ct·ê_ct.
- **Residuals.** ê comes from a two-way FE model (crop + year) fitted on clean cells only. For treated post cells, ê = Y − fit − ATT(e). This demeans by the event-time average, so heterogeneity across treated crops enters the variance.
- **Contributing clusters.** Only crops with a non-zero score contribute: G = 29, meaning 7 treated plus 22 controls. The 24 listed controls include Winter napa cabbage and Winter radish, which never meet a 2007–2009 reference year.
- **Standard error.** SE = √(G/(G−1)·Σψ²), which is CR1-type. The normal p-value uses this SE.
- **Bootstrap.** One Webb 6-point multiplier per crop is drawn per replication, shared across event times. The replicated statistic is θ* = Σ v_c ψ_c.
  - CI = θ ± 95th percentile of |θ*|. This is a symmetric, non-studentised interval.
  - p = (#{|θ*| ≥ |θ|} + 1)/(B + 1).
- **Joint pre-trend Wald.** W = θ′ Σ⁺ θ, where Σ is the covariance of the pre-period θ* draws, compared against W* for each draw.
- **Status.** This is a **custom** inference procedure and must be called custom. It is related to the multiplier-bootstrap and wild-cluster literatures but is not a documented textbook procedure.
- **TWFE.** Inference is a standard restricted wild cluster bootstrap-t (WCR, Webb, 1,999 draws, CR1 with small-sample factor). With 7 treated clusters out of 31, WCR is known to be conservative.
- **Fragility.** With 7 / 6 / 4 treated clusters, inference **should be described as fragile**. Analytic and bootstrap p-values agree (0.901 vs 0.903) because both rest on the same 7 treated scores; that agreement is not independent confirmation.
- **Single-crop cases.** With one treated crop (Cohort 2015 only), p = 0.0001 = 1/(B+1). This is degenerate: descriptive only.
- **Reproducibility.** One RNG stream is shared by all specifications in run order, so bootstrap intervals are reproducible only for the exact script order.

---

## 6. Errors and inconsistencies found

All items were approved and resolved on 2026-09-28 (§8). The table records the original findings.

| # | WHAT | WHERE | WHY IT MATTERS | PROPOSED CORRECTION | Type |
|---|---|---|---|---|---|
| E1 | "The reference year lies 2–7 years before nationwide availability" | Memo §0 | The same paragraph lists e = −8 (Red pepper); the true range for annual crops is 4–8 years | "4–8 years before nationwide availability (e = −8 to −4)" | NUMERICAL_ERROR |
| E2 | Production pre-trend Wald p reported as 0.41 | Memo §2 | The results table says 0.4049, which rounds to 0.40; text and table must agree | 0.40 | NUMERICAL_ERROR (immaterial) |
| E3 | "DT_1J49 gives 8–12 years of pre-period placebo coefficients, vs 3–5 with DT_1J60 alone" | Memo §9 | Actual: 8 event-time coefficients (e = −12…−5), 4–8 per crop, vs 6 coefficients (e = −10…−5), 2–4 per crop | Use the actual counts | NUMERICAL_ERROR |
| E4 | "The divisor is common to all crops in a year, so it cancels; estimates identical to the undivided index" | README "Price variables"; memo §9 | The annual value is a mean of quarterly ratios, so the divisor is not common: its implied value differs 0.1–6.5% across crops within a year. The headline changes from −0.11806 to −0.11797 (undivided); event-time coefficients change by up to 0.006 | "approximately cancels; the main estimate changes by less than 0.001" | NUMERICAL_ERROR (claim), numerically negligible |
| E5 | "Fruit controls are annual crops only; no clean perennial comparison exists" | Memo §8, §12(6); Python Figure 4 note | Code also uses not-yet-treated Astringent persimmon (to 2005) and Plum (to 2007) as controls: 18 of 60 post comparisons, 55 of 104 overall. No never-treated perennial controls exist | (a) wording: "no never-treated perennial controls; comparison crops are annual crops plus two not-yet-treated fruit crops for early event times" — used in the new R Figure 4 note; or (b) drop fruit crops from the fruit control pool (**specification change — needs approval**) | CONFLICTING |
| E6 | Figure 2 x-axis "Average estimated change, e = 0 to 9" applies to TWFE rows | `04_figures.py` Fig 2 | TWFE coefficients average all post years (annual up to e = 12, fruit up to e = 21). The horizon difference is a second reason TWFE is larger (memo §6 gives only the pre-trend reason) | Label TWFE rows separately (done in the R Figure 2 note); add the horizon point to memo §6 | INTERPRETIVE_OVERREACH |
| E7 | Fruit TWFE benchmark uses the 24 annual controls (G = 30); the preferred fruit estimator uses 24 + 7 annual crops (G = 35) | `03_estimate.py` fruit block | Benchmark is not on the same control set as the estimate it is compared with | Re-run fruit TWFE with CTRL + ANN (**specification change — needs approval**) or state it | CODING inconsistency |
| E8 | EVENT_SUPPORT, COHORT_SUPPORT, CONTROL_COMP sheets | DATA_BUNDLE and RESULTS_BUNDLE `*_RAW` | Produced by an earlier pipeline: obsolete IDs (`maize`, `chili_dried`, `citrus`), 20-crop control pool, event times to −24. No script in the bundle produces them | Do not cite; use T12/T13 (consistent with the replication) | CONFLICTING |
| E9 | Korean provenance labels mis-encoded (UTF-8 read as Latin-1) | DATA_BUNDLE `MASTER_PANEL`, 5 text columns | Labels unreadable; numbers unaffected | Re-decoded in `verified_master_panel.csv`; all 43 match PROD_CROSSWALK; every other cell byte-identical | CODING_ERROR (bundle only) |
| E10 | File names read by code ≠ manifest; deflator source file absent from manifest; `treatment_coding_input.csv` read from the output folder; five bundle outputs produced by no bundled script | CODE_BUNDLE vs FILE_MANIFEST / DOCUMENTATION | Provenance chain incomplete; "run_all.sh rebuilds everything from raw" cannot be supported. The `08_…`/`10_…` vegetable file names are swapped between code and manifest | Add DT_1J50 file and hashes; align names; add the scripts that made the orphan tables | CONFLICTING / UNSUPPORTED (C) |
| E11 | "Loss ratio = indemnities / premium as defined by APFS" | Python Figure 9 note | Recomputed: loss ratio = indemnities / **risk premium** × 100 (exact to 0.1); it differs from indemnities / net premium from 2012 on | State "indemnities / risk premium" (done in the R Figure 9 note) | VERIFIED_WITH_CAVEAT |
| E12 | Audit row "rows with zero/invalid yield or price fields: 10,529" | APFS_FRUIT_AUD | Code counts rows with missing *normal yield* only | Relabel "rows with zero/invalid normal yield" | Label error |

**Caveats that must stay in the thesis text (not errors).**
- Area + yield = 0.020014 against production 0.019883: approximately equal, not "equals".
- The cell identity ln P = ln A + ln Y − ln 100 holds only up to KOSIS rounding: median gap 0.00014, maximum 0.074 (Spring radish 2001).
- Red pepper is influential (leaving it out gives production 0.132). Onion is nearly as influential in the opposite direction (−0.044), so the estimate is sensitive to single crops.
- The upper production bound corresponds to +38.7% (write +39%).
- Only 22 controls ever contribute, and 8–11 remain at e = 9.
- The e = −5 lead rests on 2 crops.
- Autumn potato is coded `robustness_treated` but is used nowhere.
- Several display names are not in your approved list: Other pulses, Malting barley, Ginger, seasonal Napa cabbage and Radish forms, Walnut. **Your decision.**
- Aside: your Stata Figure 2-2-1 lists 281,648 insured policies for 2017, but the APFS file has 284,648. Every other year matches.

---

## 7. Verification status by area

| Area | Level | Status |
|---|---|---|
| Panel structure, logs, treatment identities, clean-control rule, production identity | A | Verified (identity approximate) |
| Treatment dates themselves | C | Yearbook / press release / guideline not embedded |
| Main estimates, event study, all robustness, fruit, price, rice | A | Replicated independently |
| Custom inference | A | Replicated; custom; fragile |
| Price linking statistics | B | Flags recomputed exactly; statistics approximately re-derived from annual data; quarterly raw absent |
| Price item definitions, deflator source | C | |
| APFS national, 2023 crop table | A | Identical to embedded public CSVs; financing and loss ratio recomputed |
| APFS province table | B | Internally additive; raw not embedded |
| APFS 2024 fruit records (rows, duplicates, shares, quartiles) | B | Consistent with the supplied audit summary, **not recomputed from raw records** |
| 2010–2011 financing residual | A | Components 75.2% / 74.3%; provincial and municipal fields zero; residual unexplained. Nothing further is supported |
| Institutional history, budget, reinsurance, literature citations | C | Not audited from memory |

The full claim-by-claim audit is in `verified_results/claim_audit.csv` (139 claims):
- **Level A:** 95 claims (66 verified, 21 with caveat, 8 original errors or conflicts, all now resolved).
- **Level B:** 15 claims.
- **Level C:** 29 claims.

Original findings keep their status; resolutions are appended to `notes` ("RESOLVED 2026-09-28").

---

## 8. Approved corrections applied (2026-09-28)

**Scope.**
- The preferred estimator, all group-time estimates, the imputation estimator, all bootstrap intervals, the rice case and all APFS values are **unchanged**.
- Only the benchmark calculations were re-run (`audit/06b_corrected_benchmarks.R`).
- The frozen files, Figures 2, 4 and 7, and the figure QC were regenerated.
- Wording corrections are applied in `docs/METHODOLOGICAL_MEMO_v3.md`, generated by `audit/09_corrected_memo.py`. Every edit is asserted against the original text and listed in the memo's change log.
- Provenance is recorded in `docs/PROVENANCE.md`.
- No specification was chosen by statistical significance.

### 8.1 Numerical values that changed

| Quantity | Before | After | Why |
|---|---|---|---|
| Annual TWFE, clean cells (Figure 2 row) | 0.263 / −0.026 / 0.238 (all post years, e ≤ 12; n = 882) | **0.243 / −0.028 / 0.215** (e = 0…9; n = 868; WCR p 0.231 / 0.716 / 0.290) | Item 6: same post horizon as the estimators it is compared with. The old values are kept as the LEGACY benchmark. |
| Annual TWFE, Han-style naive coding (Figure 2 row) | 0.174 / −0.011 / 0.163 (e ≤ 12; n = 990) | **0.156 / −0.021 / 0.135** (e = 0…9; n = 976; WCR p 0.392 / 0.738 / 0.460) | Item 6. Old values kept as LEGACY. |
| Fruit TWFE benchmark (orchard area / production) | 0.432 / 0.411 (24 annual controls; G = 30; n = 850) | **0.414 / 0.399** (preferred fruit pool: 24 annual controls + 7 annual treated crops before their pilots; G = 37; n = 974; WCR p 0.053 / 0.047) | Item 7: same comparison pool as the preferred fruit estimator. Old values kept as SUPERSEDED in `verified_benchmark_record.csv`. A supplementary same-pool, e = 0…9 version (0.426 / 0.407) is recorded for information only. |
| Memo §8 range "B and TWFE give 0.38–0.43" | 0.38–0.43 | 0.38–0.41 | Follows from the fruit TWFE correction. |
| Production joint pre-trend p (text) | 0.41 | 0.40 (0.4049) | Item 2: rounding of the unchanged table value. |
| Reference gap (text) | 2–7 years | 4–8 years (e = −8 to −4) | Item 1. |
| Price placebo coefficients (text) | "8–12 vs 3–5 years" | 8 coefficients, 4–8 years per crop (linked) vs 6, 2–4 per crop (DT_1J60 only) | Item 3. |

Checks on the new benchmarks:
- The TWFE routine with the horizon restriction switched off reproduces the legacy Python TWFE exactly (|Δ| ≤ 2e-13).
- The WCR p-values of the new benchmarks use 9,999 draws in R, so their third decimal carries Monte Carlo error of about ±0.005.

### 8.2 Values verified but unchanged

| Item | Verified value |
|---|---|
| 15: control support | 24 listed; 22 contribute (Winter napa cabbage, Winter radish never do); controls per treated crop by event time: e = 0: 22–22, e = 4: 15–22, e = 5: 14–20, e = 6: 11–20, e = 7: 10–15, e = 8: 10–14, e = 9: 8–11 (11 distinct series) |
| 4: relative vs nominal price index | −0.118062 vs −0.117974; max event-time difference 0.0063 (0.0030 after availability) |
| 5: fruit not-yet-treated controls | Astringent persimmon (clean to 2005) and Plum (clean to 2007) in 18 of 60 post comparisons |
| 16: identity | Aggregated area + yield 0.020014 vs production 0.019883; crop-year gaps > 0.01: Spring radish 2001 (−0.0743), Sesame 2020 (−0.0123), recorded in `verified_identity_discrepancies.csv`, source values unchanged |
| 8: support tables | Rebuilt T12/T13 equivalents match RESULTS T12 (110 rows) and T13 (72 rows) exactly; stale sheets quarantined |
| 12: APFS audit | 10,529 = rows with missing or non-positive normal yield (label corrected; value unchanged) |
| 11: loss ratio | indemnities / risk premium × 100 (reported = recomputed to 0.1) |

### 8.3 Not changed (outside the approved list)

- The memo's "roughly −25% to +38%" (the upper bound is +38.7%).
- The memo's description "Cohort 2015 only (1 crop, p = 0.000)"; that p is the minimum attainable, 1/(B+1).
- These remain noted in `claim_audit.csv` (C030, C057).
