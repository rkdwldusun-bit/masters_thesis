# Chapter 5 Documentation Bundle

Prepared for transfer to Claude Code under a five-file upload limit. This file contains the latest methodological documentation plus source/provenance notes.

## IMPORTANT SCOPE LIMITATION

The original binary KOSIS spreadsheets, official PDFs, and the full 336,232-row APFS fruit contract-detail CSV are **not embedded** in this Markdown file. `DATA_BUNDLE.xlsx` contains the current analysis-ready data, price raw/linked tables, APFS summaries, support diagnostics, and provenance metadata. Therefore Claude Code can independently audit calculations from the bundled tabular data, but claims that require inspection of an omitted original PDF/binary source should be marked `EXTERNAL SOURCE VERIFICATION REQUIRED`, not silently inferred.

The 2024 APFS fruit descriptive section is bundled through the audit and crop-level summary tables rather than the full 27 MB raw administrative file. Exact raw-row duplication and raw-field extraction should therefore be treated as source-derived claims unless the original APFS file is separately provided.

## Source manifest (not embedded)

| File | Size (bytes) | SHA-256 |
|---|---:|---|
| `농업재해보험연감 2025.pdf` | 79759262 | `1749be2931c06ad44f1239a5ac0b9146cb53dd5d8f47bbd6ca049af13c6c62d4` |
| `jep-36-4-135.pdf` | 865105 | `37ce79281a2941c8661c8c479303f9ddb206724ab15c67e76b7e9f986b23ff48` |
| `농어업재해보험 적절성 평가(2).pdf` | 3416173 | `a0dda6b7956620bdabbbe8ec567f523ecc118d0b2cb2313236607f62555f3b46` |
| `비공개 심층평가 최종보고서(2).pdf` | 17500693 | `e7b3950c647f9b5d57fd07ccfc8dfe0bdfc62c09d27d954c6668409930fc169d` |
| `Guidelines for the Use of AI Tools for Research Projects.pdf` | 214243 | `11374e3bcd8e65fef6f4c2f7a98904edef8cb02bf156b401b2586ec33fbbfc2b` |
| `A Guideline for Research Projects_2025 (1).pdf` | 1618755 | `943b2740db5c2dcdb07b99c12067b7af1324155c353906c7bb675d62caed0353` |
| `Introduction Outline and Methodology Gap Review — South Korea's Crop Disaster Insurance Thesis_apa.pdf` | 455854 | `06924788a39157889b0d2028dcec249e193cdfb166027e16d11880fec7c42634` |
| `01_fruit_total.xls` | 1937040 | `99be575280a5b1a55a2bfe48e7ea6861d1ddd381424c9531c54671ba6f4ab38a` |
| `02_fruit_bearing.xlsx` | 57199 | `52b152deefc54629a85dd6b00f9be8bedf63e35391a92e570d4eb9b4a46ceb24` |
| `03_rice.xlsx` | 65671 | `dd6ace60ab37f300c149fceaaa7996311acbe561285c960ff694b1895c0f8c02` |
| `04_beans.xlsx` | 6402 | `b529456153b285614b90bbd1c692a9868938477af99f2f4f5a081a9a513791eb` |
| `05_coarse_grains.xlsx` | 42884 | `4ea31c77065cbba1db24d6a0c99ec08030fbbdb23cde2a8857b4a432dd2bdd19` |
| `06_potatoes.xlsx` | 68351 | `4b8bdce346243349fbf093c46ada167a04ca59f137b118c7c6acba65e8c8e9f0` |
| `07_barley.xlsx` | 27448 | `6f09b9daca14821c6832594391b45f570eeef1114124ed1c154ff2ae2560f83d` |
| `08_vegetables_spices.xls` | 2068118 | `fb300963a1538b36500dab6ecc44cf00d3b232a46b3ae893dbb8508e0e6167b5` |
| `09_vegetables_leafy.xls` | 2680150 | `89c30b64b35c2b94d26ba39c14a1dff47367dfa2511eed7d4c77136de85d228f` |
| `10_vegetables_root.xls` | 2940629 | `a869a6078826688217c651d52a1d6eb0e7a6afa4865eeaeaccd3a1478f898013` |
| `특용작물생산량_20260927184000.xlsx` | 53107 | `85f2263b31bb659f18d1fc6689534871ac42164e61d1d454e3d0b855decc3b09` |
| `농가판매가격지수_2005100__분기__품목별__20260927193919(2).xlsx` | 63904 | `a84c053262776405a4f9dab096e52598242bcb00fb32cf6f30af7df6fd54e9e3` |
| `11_farm_output_price_index.xlsx` | 45874 | `3b4b6d2a4bc083465b80bc05e63399a49a175ad21cdb8ddefc8b253cb1a4aa25` |

## KOSIS metadata snapshot

```json
{
  "01_fruit_total.xls": {
    "통계표 메타자료 >": "None",
    "○통계표ID": "DT_1ET0292",
    "○통계표명": "과실생산량(성과수+미과수)",
    "○수록기간": "null",
    "○출처": "KOSIS(「농작물생산조사」, 국가데이터처), 2026.09.27 17:54 ",
    "○문의처": "042-481-2545/042-481-3732 ",
    "○통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101=DT_1ET0292=I3",
    "○주석": "None"
  },
  "02_fruit_bearing.xlsx": {
    "○ 통계표ID": "DT_1ET0296",
    "○ 통계표명": "과실생산량(성과수)",
    "○ 조회기간": "[년] 2009~2025  ",
    "○ 출처": "「농작물생산조사」, 국가데이터처",
    "○ 자료다운일자": "2026.09.27 17:56",
    "○ 통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1ET0296&conn_path=I3"
  },
  "03_rice.xlsx": {
    "○ 통계표ID": "DT_1ET0222",
    "○ 통계표명": "미곡생산량(조곡)",
    "○ 조회기간": "[년] 1980~2025  ",
    "○ 출처": "「농작물생산조사」, 국가데이터처",
    "○ 자료다운일자": "2026.09.27 17:57",
    "○ 통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1ET0222&conn_path=I3"
  },
  "04_beans.xlsx": {
    "○ 통계표ID": "DT_1ET0025",
    "○ 통계표명": "두류생산량",
    "○ 조회기간": "[년] 1980~2025  ",
    "○ 출처": "「농작물생산조사」, 국가데이터처",
    "○ 자료다운일자": "2026.09.27 17:58",
    "○ 통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1ET0025&conn_path=I3"
  },
  "05_coarse_grains.xlsx": {
    "○ 통계표ID": "DT_1ET0024",
    "○ 통계표명": "잡곡생산량",
    "○ 조회기간": "[년] 1980~2024  ",
    "○ 출처": "「농작물생산조사」, 국가데이터처",
    "○ 자료다운일자": "2026.09.27 18:00",
    "○ 통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1ET0024&conn_path=I3",
    "○ 주석": "nan",
    "통계표": "2010년부터 조, 수수 생산량 통계작성 중지됨"
  },
  "06_potatoes.xlsx": {
    "○ 통계표ID": "DT_1ET0026",
    "○ 통계표명": "서류생산량(생서)",
    "○ 조회기간": "[년] 1991~2026  ",
    "○ 출처": "「농작물생산조사」, 국가데이터처",
    "○ 자료다운일자": "2026.09.27 18:01",
    "○ 통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1ET0026&conn_path=I3",
    "○ 주석": "nan",
    "통계표": "*서류의 재배면적은 시설면적이 포함된 수치임"
  },
  "07_barely.xlsx": {
    "○ 통계표ID": "DT_1ET0231",
    "○ 통계표명": "맥류생산량(정곡)",
    "○ 조회기간": "[년] 1980~2026  ",
    "○ 출처": "「농작물생산조사」, 국가데이터처",
    "○ 자료다운일자": "2026.09.27 18:16",
    "○ 통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1ET0231&conn_path=I3",
    "○ 주석": "nan",
    "통계표": "2004년부터 호밀 생산량 통계작성 중지됨"
  },
  "08_vegetables_root.xls": {
    "통계표 메타자료 >": "None",
    "○통계표ID": "DT_1ET0029",
    "○통계표명": "채소생산량(근채류)",
    "○수록기간": "null",
    "○출처": "KOSIS(「농작물생산조사」, 국가데이터처), 2026.09.27 18:03 ",
    "○문의처": "042-481-2545/042-481-3732 ",
    "○통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101=DT_1ET0029=I3",
    "○주석": "None"
  },
  "09_vegetables_leafy.xls": {
    "통계표 메타자료 >": "None",
    "○통계표ID": "DT_1ET0028",
    "○통계표명": "채소생산량(엽채류)",
    "○수록기간": "null",
    "○출처": "KOSIS(「농작물생산조사」, 국가데이터처), 2026.09.27 18:03 ",
    "○문의처": "042-481-2545/042-481-3732 ",
    "○통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101=DT_1ET0028=I3",
    "○주석": "None"
  },
  "10_vegetables_spices.xls": {
    "통계표 메타자료 >": "None",
    "○통계표ID": "DT_1ET0291",
    "○통계표명": "채소생산량(조미채소)",
    "○수록기간": "null",
    "○출처": "KOSIS(「농작물생산조사」, 국가데이터처), 2026.09.27 18:02 ",
    "○문의처": "042-481-2545/042-481-3732 ",
    "○통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101=DT_1ET0291=I3"
  },
  "13_특용작물생산량__땅콩_.xlsx": {
    "○ 통계표ID": "DT_1ET0293",
    "○ 통계표명": "특용작물생산량",
    "○ 조회기간": "[년] 1980~2025  ",
    "○ 출처": "「농작물생산조사」, 국가데이터처",
    "○ 자료다운일자": "2026.09.27 18:40",
    "○ 통계표URL": "https://kosis.kr/statHtml/statHtml.do?orgId=101&tblId=DT_1ET0293&conn_path=I3",
    "○ 주석": "nan",
    "통계표": "- 땅콩은 껍질을 제거한 알땅콩을 기준함"
  }
}
```

---

# LATEST README

# Chapter 5 estimation package (v2)

Run `bash run_all.sh` to rebuild everything from the raw uploads, which are read-only. The random seed is fixed (20260927).
**Start with `METHODOLOGICAL_MEMO.md`.**

## Pipeline

| Script | What it does |
|---|---|
| `01_build_panel.py` | Production panel (1980–2024, 43 crop series) with thesis display names, provenance labels, treatment flags and the dropped-observation log |
| `02_build_prices.py` | Price-item crosswalk; DT_1J49 (2005=100) × DT_1J60 (2020=100) linking diagnostics with three link windows; linked quarterly and annual panels; deflator; overlap figure |
| `est_engine.py` | Estimators: custom group-time DiD with clean not-yet-treated and never-treated controls (normalizations A / B / B5), imputation estimator, TWFE with WCR; crop-level wild bootstrap. Not the Callaway–Sant'Anna estimator itself. |
| `03_estimate.py` | All specifications → `results_summary_all_specs.csv`, `results_dynamic_all_specs.csv`, `results_rice_case.csv` |
| `04_figures.py` | Figures 1–6 |
| `05_apfs_descriptives.py` | Figures 7–10 and Appendix Figure A1; 2024 records audit and tables |
| `06_final_tables.py` | `ch5_master_panel_national_v2.csv`, `appendix_crop_nomenclature.csv`, `ch5_results_tables.xlsx` (sheets T1–T18) |

## Key outputs

| Output | Contents |
|---|---|
| `ch5_master_panel_national_v2.csv` | Final panel |
| `ch5_results_tables.xlsx` | Regression and diagnostic tables |
| `price_linking_diagnostics.csv` | Price-link log |
| `price_quarterly_raw_all_tables.csv` | Raw quarterly prices, unmodified |
| `price_linked_quarterly.csv` | Preserves `old_price_index`, `new_price_index`, `link_factor`, `link_period`, `linked_price_index` |
| `fig*.png` | Figures |

**Provenance variables:** `crop_ko_official`, `crop_en_display`, `kosis_production_label_original`, `kosis_price_label_original`, `apfs_label_original`, `insurance_product_variant`.

**Naming.** Thesis-facing outputs use only the mandatory English display names (e.g., Pear, Tangerine, Green plum, Yuja, Napa cabbage, Radish; 두릅 = Dureup). Korean and raw labels appear only in the provenance columns and the appendix crosswalk.

**Price variables.** The price outcome is a *relative* farm-gate price index (crop index ÷ linked all-farm-output price index). Thesis-facing names in `ch5_master_panel_national_v2.csv`: `relative_price_index`, `ln_rel_price_linked`, `ln_rel_price_new`, `ln_rel_price_old`. Intermediate files (`price_annual_panel.csv`, `results_*.csv`) keep the internal names `real_*` / `ln_real_*`; the mapping is in results-workbook sheet T19. Because the divisor is common to all crops in a year, it cancels in the DiD and the estimates are unchanged.

**Language.** Estimates are described as *estimated changes associated with insurance expansion*, not causal effects (see memo §0 and §11).


---

# LATEST METHODOLOGICAL MEMO

# Chapter 5 — Methodological interpretation memo (estimation stage)

**Status.** Estimation complete; terminology revision applied (numbers unchanged). No chapter prose. No policy recommendations. Awaiting approval.

**Units.** All estimates are in log points. An estimate of 0.10 ≈ 10.5%.

**Intervals.** Unless stated otherwise, "CI" means the 95% crop-level wild-bootstrap interval (Webb weights, 9,999 draws). Exact figures are in `ch5_results_tables.xlsx`.

---

## 0. Specification fixed before estimation

**Terminology used throughout.** None of the estimates meets the standard for causal interpretation (§11). Estimates are therefore described as *estimated changes associated with insurance expansion*, not as effects of insurance.

**Target parameter.** For a treated crop *i*, the target parameter, written ATT_i(e), is the change in the outcome from the crop's **last clean pre-pilot year** to year g_i + e, where g_i is the year of nationwide availability. From this we subtract the same change for crops that are still cleanly untreated in both years.

- ATT(e) is the equal-weighted average over the treated crops observed at event time *e*.
- The headline number is the equal-weighted average of ATT(e) over e = 0 … 9.

**Why the gap matters.** The transition years (from pilot_year to national_year − 1) are excluded, so e = −1, −2 and often −3 to −7 are never observed.

The reference year therefore lies **2–7 years before nationwide availability**:
- Soybean, Sweet potato and Corn: e = −5
- Onion and Garlic: e = −4
- Spring potato: e = −6
- Red pepper: e = −8

As a result, each ATT(e) measures the **cumulative change associated with pilot-period partial exposure plus e years of nationwide availability**, relative to having no insurance at all. Only if the identifying assumptions hold would it be a causal effect, and even then it would not be the effect of the nationwide switch alone. Any change in the treated crops that is unrelated to insurance but happens during the transition years also loads into ATT(e).

**How to read the pre-period coefficients.** The clean pre-period coefficients are placebo differences relative to the same reference year. They test parallel trends *before the pilot*. They say nothing about the transition years.

**Normalizations compared.**
- A: last clean pre-year. This is the preferred choice.
- B: mean of all clean pre-years since 1991.
- B5: mean of the last five clean pre-years.

A was chosen **before** looking at results. It requires parallel trends only from the last untreated year onward, which is the shortest extrapolation. Its known cost is dependence on a single, weather-exposed reference year. B and B5 are reported for this reason.

**Estimators.**
- Preferred: a **custom group-time difference-in-differences estimator** using clean not-yet-treated and never-treated controls. Each control is used only before its own first pilot, and the reference period is the treated crop's final clean pre-pilot year. This estimator is not the Callaway–Sant'Anna estimator itself. Callaway and Sant'Anna (2021) may be cited as methodological background once the original reference has been verified.
- Comparison: an imputation estimator (two-way fixed effects fitted on clean cells only).
- Benchmark only: static TWFE on clean cells, and TWFE with Han (2014)-style naive coding.

**Inference.**
- Crop-clustered analytic standard errors.
- A crop-level wild (multiplier) bootstrap with Webb weights on score contributions, with residuals from a two-way fixed-effects model fitted on clean cells.
- For TWFE: a restricted wild cluster bootstrap (WCR, Webb weights, 1,999 draws).
- Pre-trend joint Wald test using the bootstrap covariance.

Citations for these methods must be verified in LINER before they are used in the thesis.

---

## 1. Is the annual-crop production change credibly identified?

**Only partly. The design is informative, but it is not strong enough for a causal claim about the size of any change.**

**Preferred estimates** (7 treated crops, 24 control series, 29 contributing clusters):

| Outcome | Estimate | 95% CI |
|---|---|---|
| Area | 0.048 | [−0.213, 0.310] |
| Yield | −0.028 | [−0.132, 0.075] |
| Production | 0.020 | [−0.287, 0.327] |

These intervals are wide. Using the minimum-detectable-effect rule (a standard power concept) of about 2.8 × SE:
- about ±0.45 for production;
- about ±0.39 for area;
- about ±0.15 for yield.

The data therefore **cannot rule out** production changes of roughly −25% to +38%. A statement such as "no effect" is not supported. The correct statement is "no statistically detectable change, with low power".

The estimates are also sensitive to Red pepper (see §3–4). This, too, argues against treating them as a precise causal estimate.

**Classification: B (suggestive).**

## 2. Are the pre-treatment diagnostics consistent with the identifying assumptions?

**The results are mixed.**

- **Joint test does not reject.** The joint Wald tests on the clean pre-period coefficients give p = 0.35 (area), 0.67 (yield) and 0.41 (production).
- **Individual long leads do reject.** For area and production, the leads at e = −12 to −9 are individually negative and significant (production: −0.30 to −0.15, wild p = 0.01–0.03).
- **The pattern is systematic.** The treated crops **were growing relative to the controls in the years before the pilot**. The fitted pre-period slope is about +0.05 log points per year for area and production, and close to zero for yield.
- **The pattern flattens near the reference year.** Coefficients at e = −8 to −6 are close to zero.
- **Cohort-level diagnostics are uninformative.** They rest on 1–4 treated crops, and the bootstrap-based Wald tests are degenerate with so few treated clusters (p ≈ 0.7–1.0). A p-value near 1 here should not be read as evidence of parallel trends.

**Interpretation.** The pre-pilot relative growth is evidence of **non-random treatment timing** and a **threat to the parallel-trends assumption**. It does not establish *why* these crops were chosen for insurance; the data cannot distinguish selection on growth from other time-varying crop-specific factors. It is the main threat to identification, and it is also why normalizations that use distant pre-periods give larger positive estimates (see §6).

## 3. Are the findings robust to the treatment-date definition?

**Yes, in the sense that no date choice produces a statistically detectable change.**

| Dating | Area | Production |
|---|---|---|
| Baseline | 0.048 | 0.020 |
| Product-table nationwide year | 0.062 | 0.036 |
| First-pilot clock (no transition exclusion) | 0.034 | 0.017 |

For fruit, dating Apple and Pear to 2001 instead of 2003 barely changes anything:
- area: 0.130 (vs 0.136);
- production: 0.117 (vs 0.115).

The Apple and Pear date conflict is therefore **not consequential** for the results.

## 4. Are the findings robust to alternative control pools?

**The signs are not stable, although every interval includes zero.**

- **Production across four control-pool variants:** estimates range from −0.105 (excluding uncertain seasonal forms) to 0.051 (excluding other pulses). The field-crops-only variant (15 clusters) gives −0.091 with a CI of [−0.53, 0.35].
- **Leaving out cohorts:** all estimates stay inside the confidence bands.
- **Leaving out Red pepper** raises production to 0.132 [−0.10, 0.37] and area to 0.129.

**Red pepper is influential.** Its dried-pepper area and production fell sharply during its long 2008–2014 transition. That decline is already −0.40 at e = 0 relative to its 2007 reference year, and it loads into its post-period estimates. This is exactly the gap problem described in §0; the decline cannot be attributed to insurance.

## 5. Are the area, yield and production estimates internally coherent?

**Yes, arithmetically.**
- Area 0.048 + yield −0.028 = 0.020, which equals production. The log identity holds on the common sample.
- Dynamically, area and production move together, and yield stays flat within ±0.10.

**Substantive reading.** The yield estimate is small and imprecise, providing no statistically detectable evidence of an intensive-margin response. The area estimate is also imprecise.

## 6. How different are the TWFE and preferred estimates?

**Materially different for area and production. Nearly identical for yield.**

| Estimator | Area | Yield | Production |
|---|---|---|---|
| Preferred (A) | 0.048 | −0.028 | 0.020 |
| B (mean of all clean pre-years) | 0.264 | −0.036 | 0.228 |
| B5 (last five clean pre-years) | 0.075 | −0.008 | 0.067 |
| Imputation | 0.244 | −0.028 | 0.216 |
| TWFE, clean cells | 0.263 | −0.026 | 0.238 |
| TWFE, Han (2014)-style naive coding | 0.174 | −0.011 | 0.163 |

**Why they differ.** B, imputation and TWFE all use the full pre-period as their baseline. Because of the pre-existing relative growth documented in §2, their post-period estimates absorb part of that growth. B5, which uses only the most recent pre-years, is close to A.

**Why TWFE is not the headline.** The TWFE estimates are larger because they absorb the pre-trend, not because they identify a better quantity. None of the estimators, including TWFE, is statistically significant.

## 7. Does the small number of crop clusters materially affect inference?

**Yes. This is a first-order limitation.**

- There are only **7 treated clusters** in the annual sample, 6 in fruit, and 4 in the main price sample.
- Analytic clustered p-values and wild-bootstrap p-values happen to be similar here: 0.901 vs 0.903 for production.
- No available procedure is reliable with 1–2 treated clusters. Cohort-specific estimates such as "Cohort 2015 only" (1 crop, p = 0.000) and all rice estimates must be treated as **descriptive**.
- Joint pre-trend tests have low power.

## 8. Are the perennial-fruit estimates credible enough for causal interpretation?

**No. They are suggestive at best.**

**Preferred estimates:**

| Outcome | Estimate | 95% CI |
|---|---|---|
| Orchard area | 0.136 | [−0.13, 0.40] |
| Production | 0.115 | [−0.09, 0.32] |

**Why the evidence is weak.**
- **Steady pre-trend.** The pre-period coefficients rise steadily, for example orchard area from −0.33 to −0.04, and the post-period path continues the same slope. This is consistent with the continuation of an existing trend rather than a break at treatment.
- **Controls are annual crops only.** No clean perennial comparison exists, so the area comparison is orchard area versus annual cultivated area.
- **Other specifications diverge.** Normalization B and TWFE give 0.38–0.43.
- **Adding Peach and Grape** (either 2004 or 2010 dating) changes little.
- **Bearing-area yield** is not estimable before 2009 and is not used.

**Classification: B (suggestive), leaning toward descriptive.**

## 9. Does DT_1J49 make the price analysis substantially more credible?

**Moderately. It helps the diagnostics, not the point estimate.**

**What it adds:** DT_1J49 supplies 1980–2004 crop-level history. This gives 8–12 years of clean pre-period placebo coefficients, compared with 3–5 years using DT_1J60 alone. It also makes normalization B possible.

**What it does not change:** Under the preferred normalization, the reference year and all post years fall inside DT_1J60 (2005 onward). The link factor therefore cancels. The point estimate is identical whether the linked series or the new series alone is used: −0.118 in both cases, and −0.118 for every link window.

**Main estimate (4 crops, log relative farm-gate price):** −0.118 [−0.289, 0.052]. The pre-period coefficients are noisy and mostly negative (about −0.15 to −0.19 at e ≤ −10), so a relatively high reference year cannot be ruled out.

**Variants:**

| Sample | Estimate |
|---|---|
| Strict sample (2 crops) | −0.051 |
| Approximate matches included | −0.145 |
| New series only, 6 exact crops | −0.166 |
| Normalization B | −0.019 |

**Old series only:** not feasible. For the 2012 cohort, at most e = 0 is observed. For the 2013 and 2015 cohorts, no post period is observed.

**Interpretation.** The price outcome is a **relative** farm-gate price index: each crop's index divided by the all-farm-output price index, not by a general-price deflator. Because the divisor is common to all crops in a year, it cancels in the difference-in-differences, so the estimates are identical to those on the undivided crop index; only the label changes. Price estimates are reduced-form associations. They cannot be attributed to insurance-induced output growth, especially since no production change is detected. **Classification: B (weakly suggestive).**

## 10. Which crops have genuinely comparable long-run linked indices?

Rules were set in advance, on the 2005Q1–2012Q4 overlap.
- **Quarterly rule:** correlation of quarterly log changes ≥ 0.90, ratio CV ≤ 5%, maximum discrepancy ≤ 10%.
- **Annual rule:** correlation ≥ 0.95, CV ≤ 5%, maximum discrepancy ≤ 10%, computed on annual means.

The main price sample requires an **exact item match and the annual rule**. The annual rule matches the annual outcome.

| Group | Crops |
|---|---|
| Exact match, both rules (strict) | Sweet potato, Garlic (treated); Red bean, Cabbage, Sesame, Perilla, Peanut (controls) |
| Exact match, annual rule only | Onion, Red pepper (treated); Carrot, Ginger (controls); Pear, Peach |
| Linkable but approximate definition | Potato (all potatoes vs Spring potato), Rice (일반미 → 멥쌀), Napa cabbage, Radish, Green onion, Spinach and Leaf lettuce (pooled seasonal/greenhouse items) |
| Not linkable | Soybean (annual maximum discrepancy 11.9%); Corn (annual log-change correlation −0.18; the series is incompatible); Barley and Malting barley (low correlation) |
| Incompatible definitions | Apple (Fuji only → all apples), Sweet persimmon (all persimmons → sweet persimmon) |
| No overlap | Tangerine, Grape, Plum, Green plum |

Soybean and Corn therefore appear only in the new-series (2005–2024) variant.

## 11. Evidence classification

| Class | Findings |
|---|---|
| **A. Causal** | None at this stage. No estimate satisfies the identifying assumptions well enough to support a causal claim about magnitude. |
| **B. Suggestive** | Annual-crop area, yield and production estimates (no statistically detectable change; wide CIs; yield estimate small and imprecise). Perennial-fruit estimates. Reduced-form relative-price estimates. The estimator-sensitivity finding: distant-baseline estimators give larger estimates because treated crops were already growing relative to controls before the pilot. |
| **C. Descriptive** | Rice case (single treated unit; timing overlaps rice-specific policies). Cohort-specific estimates with 1–2 crops. Pre-trend slopes. APFS national series 2001–2024 (enrollment, financing shares, loss ratios; in 2010–11 the reported components sum to about 75% of net premium, local-government fields are zero, and the dataset does not explain the residual). APFS 2023 crop and 2023/2024 province cross-sections. 2024 fruit contract-detail records (336,232 rows, 12,099 exact duplicates, no contract identifier). |

## 12. Limitations that must appear in the thesis

1. **Few treated clusters** (7 / 6 / 4). Inference is fragile, and cohort-level results are descriptive.
2. **Transition gap.** ATT includes pilot-period exposure and any change during 2–7 transition years. The Red pepper decline shows how this can dominate.
3. **Non-random treatment timing.** Treated crops were growing relative to controls before the pilot, which threatens parallel trends. Estimates that rely on distant baselines absorb this growth. The preferred normalization mitigates but does not eliminate the problem. The data do not reveal why these crops were chosen.
4. **Low power.** Changes of ±25–40% in area or production cannot be excluded.
5. **National aggregates only.** No crop-level enrollment intensity, so the estimates concern availability of insurance (intention-to-treat), not coverage. Heterogeneous products (e.g., 적과전종합Ⅱ vs 종합) sit behind a single binary treatment.
6. **Control comparability.** Controls are mostly vegetables; field-crop-only controls change the signs. For fruit, no perennial controls exist.
7. **Crop-year conversion** assumes that historical sales windows equal those in the 2026 guideline.
8. **Price data.** Only 4 treated crops are linkable (2 under the strict rule). Prices are reduced-form and jointly determined with production. The outcome is a relative price (crop index ÷ linked all-farm-output price index), not a deflated real price.
9. **Definitions.** Spring potato and Rice prices are approximate matches. Leaf lettuce (상추) is not Lettuce (양상추). Corn may include forage corn. Winter forms are observed only from 2014.
10. **Insured-price unit.** The unit of 가입가격 is not defined in the available official sources, so it appears only in the appendix figure.
11. **Scientific names and method citations** must be verified before submission.


---

# WORKING INTERVIEW / RESEARCH SUMMARY (NOT PRIMARY EVIDENCE)

The following is a working research summary. It contains hypotheses and interpretations as well as source notes. It must not override original official sources or verified empirical results.

# 농작물재해보험 정책분석 논문 — 면담용 요약

**총괄 논지:** 농작물재해보험은 시장실패 교정 수단으로 도입되었으나 확대 과정에서 소득지원 수단으로 변질되었고, 수단·목표·대상·운영 설계가 이 변질을 은폐한다. 미시적 인수통제는 정교해지는 반면(차등보조·할인할증), 거시적 설계(보조금 귀착, 독점, 성과체계, 수입안정보험과의 관계)는 방치되어 있다.

*출처 표기: [연감 p.○] = 농업재해보험연감 2025(2024년 실적), [지침 p.○] = 2026년 농작물재해보험 사업시행지침(3차)*

---

**1. 정부개입 — 개입은 정당하나, 개입 형태가 실패 원인과 불일치**
- 시장실패의 역사적 실증: 2002~03 태풍 루사·매미 → 삼성·현대 등 민영사 재보험 철수, 농협중앙회 사업 기피 → 2005 국가재보험 도입 후 복귀 [연감 p.266]
- 위험의 크기: 국가재보험 누적손해율 227.3%(재보험료 5,013억 vs 재보험금 1조 1,396억) [연감 p.269]
- 단, 미시 통제는 진화 중: 경작불능보험금 2회 수령 농지 국비 배제, 누적손해율 500% 가입자 보장 80% 이상 제한('26.7~), 개인별 사고실적 할인·할증('26.11~) [지침 p.3~5]

**2. 정책수단 — 쟁점은 지급 경로가 아니라 보조금의 최종 귀착**
- NH의 법적 지위 = "간접보조사업자(사업시행기관)" [지침 p.1] / 2026년 국고 예산 5,566억 [지침 p.1]
- 순보험료(위험보험료+손해조사비) 50% 내외 + 부가보험료("위탁판매비용 등") 100% 국고 [지침 p.2~3]; 운영비 100% 보조 [연감 p.38]; 예정사업비율은 예산 함수로 사전 결정 [연감 p.41]
- 손익분담방식 100%('19~)·국가분담 50%('20~) [연감 p.267~268] → NH의 순보유위험 얇음 → 사업자 경유 보조금은 위험인수가 아닌 행정서비스 구매 → 보험료 보조는 차감형 유지, 운영비는 경쟁·성과연동으로
- 보조율 차등화 확대(3개 품목군 33~65%, 전 품목 연차 확대 예정) — 정부가 이미 가는 방향, 논문의 차별점은 그 너머 [지침 p.2]

**3. 정책목표 — 가입률은 목표가 아니라 목표전치의 증상**
- 2024 가입률 54.2%는 벼 가입 증가 주도 [연감 p.157]; 품목 확대기 가입률 하락(2007 22.7% → 2012 13.6%, 분모효과) [연감 p.266]
- 공식 평가체계의 지표 전부가 투입·산출(가입실적·보조금 집행·홍보실적·민원), 결과(outcome) 지표 부재 [지침 p.20]; "가입률 제고" 목적 명문 반복 [지침 p.11, 13]
- 대안 지표: 재해연도 소득 하방변동성 감소, 사후 무상 재난지원 대체율, 위험노출액 대비 보장액

**4. 정책대상 — 품목 확대의 효율 논리와 형평 논리를 분리 평가**
- 2024년 73개 품목 [연감 p.38] → 2026년 78개(94개 상품) [지침 p.3]
- 품목군별 이질성: 과수4종 손해율 57.2%·가입률 71.1% vs 식량작물 165.5%, 노지 121.9%, 시설작물 120.9% [연감 p.178] — 전체 97.9%는 내부 교차보조의 평균
- 제도 스스로 한계품목 명단 제공: 본사업 1형/2형/시범사업 구분 [지침 p.27]; 시범품목(두릅·블루베리 등)은 수 개 시군 한정 → 위험분산 구조적 불능 [지침 p.25~26]

**5. 제도운영 — 재원별로 다른 현금흐름의 시간 구조**
- 농가분: 청약 시 수납 [지침 p.5] / 국고분: 연중 교부·배정, 익년 2.28 정산 [지침 p.9, 14; 연감 p.41~42]
- 지방비분: 농가는 예상 지원분 제외 납부, NH가 지자체에 후행 청구·분기 정산, 부족 시 차년도 미수금 정산, 선납 이자 미반영 — NH가 지자체에 신용 제공 [지침 p.36(별표 9)]
- 보험금: 확정 후 청구 시 7일 내 지급, 확정 전 50% 가지급 가능 [지침 p.5]
- 위탁판매비용 성과연동은 기본 대비 ±10%에 불과 → 실질화 제안 [지침 p.18]
- 재보험 정산의 비대칭 검증: 2022 국가 +1,047억, 2023 +1,694억 수령 / 2024 수입 0·지급 1,582억 [연감 p.269~270]

**6. 중복성 — 두 보험은 규정상 이미 대체재, 통합 로드맵 부재가 문제**
- "동일 목적물에 대해 수입안정보험과 재해보험 중 하나만 가입" [지침 p.3]
- 수입안정보험 2024: 9품목, 가입률 3.9%, 보험료 90억(재해보험의 0.8%), 손해율 변동 7.7~765.1%(2018) [연감 p.53]; "품목별 배정 예산 범위 내 판매" = 사실상 배급 [연감 p.57]
- 통합의 기술 비용 낮음: 재해보험 내 기준가격 산출 체계 상세 운영, '27년까지 가격산출 품목 확대 예정 [지침 p.29~34, 12]

---

**예상 질문과 답변 방향** ① 5장 데이터 확보 가능? → 농금원 실적집계·자금배정 내역, NH 경영공시, 국회 예산정책처 보고서로 접근. ② 6장 결론이 과한가? → '폐지'가 아닌 '기능 재배치'(핵심 품목은 수입보험으로 단계 이관, 잔여 품목은 재해보험 존치)로 톤 설정.
**보완 필요 자료:** 품목별(품목군 아님) 손해율 원자료, NH 사업비·수수료 내역, 지자체별 지원율 분포(조례).
