# -*- coding: utf-8 -*-
"""09_corrected_memo.py -- build docs/METHODOLOGICAL_MEMO_v3.md

Takes the README and METHODOLOGICAL MEMO sections of input/DOCUMENTATION.md
verbatim and applies ONLY the corrections approved on 2026-09-28. Every
replacement asserts that the original passage exists exactly once, so no
text is changed silently. Numbers inserted here were read from
verified_results/ (see audit/output/06b_*.txt and 03_*.csv).
Run from the repository root:  python3 audit/09_corrected_memo.py
"""
import re

doc = open("input/DOCUMENTATION.md", encoding="utf-8").read()
start = doc.index("# LATEST README")
end = doc.index("# WORKING INTERVIEW / RESEARCH SUMMARY")
text = doc[start:end].rstrip().rstrip("-").rstrip()

EDITS = [
 # ---- item 4 (README price variables)
 ("4", "Because the divisor is common to all crops in a year, it cancels in the DiD and the estimates are unchanged.",
  "The relative-price and nominal-index estimates are numerically almost identical (main estimate −0.1181 relative vs −0.1180 nominal; event-time coefficients differ by at most 0.006). The small difference arises because annual relative prices are constructed from quarterly relative indices (crop index ÷ all-farm-output index in each quarter) before annual aggregation, so the divisor is not an exactly common annual factor."),
 # ---- README pipeline: R figures supersede Python figures
 ("fig", "| `04_figures.py` | Figures 1–6 |",
  "| `04_figures.py` | Figures 1–6 (superseded for the thesis by the R figures in `R/01_figure1.R`–`R/06_figure6.R`) |"),
 ("fig", "| `05_apfs_descriptives.py` | Figures 7–10 and Appendix Figure A1; 2024 records audit and tables |",
  "| `05_apfs_descriptives.py` | Figures 7–10 and Appendix Figure A1 (superseded by `R/07_figure7.R`–`R/11_figureA1.R`); 2024 records audit and tables |"),
 # ---- status line
 ("status", "**Status.** Estimation complete; terminology revision applied (numbers unchanged). No chapter prose. No policy recommendations. Awaiting approval.",
  "**Status.** Estimation complete; independent R audit complete; approved corrections of 2026-09-28 applied (v3). Preferred estimator and headline estimates unchanged. No chapter prose. No policy recommendations."),
 # ---- item 1
 ("1", "The reference year therefore lies **2–7 years before nationwide availability**:",
  "The reference year therefore lies **4–8 years before nationwide availability (e = −8 to −4)**:"),
 # ---- items 6/7: estimator list and TWFE inference
 ("6", "- Benchmark only: static TWFE on clean cells, and TWFE with Han (2014)-style naive coding.",
  "- Benchmark only: static TWFE on clean cells, and TWFE with Han (2014)-style naive coding. For the annual estimator comparison both are estimated over the same post-treatment horizon as the other estimators, e = 0…9 (treated observations with e > 9 excluded); the earlier all-post-year versions are kept as legacy benchmarks. The fruit TWFE benchmark uses the same comparison pool as the preferred fruit estimator."),
 ("6", "- For TWFE: a restricted wild cluster bootstrap (WCR, Webb weights, 1,999 draws).",
  "- For TWFE: a restricted wild cluster bootstrap (WCR, Webb weights; 1,999 draws for the legacy benchmarks, 9,999 draws for the corrected benchmarks)."),
 # ---- item 15 (+ support) in section 1
 ("15", "**Preferred estimates** (7 treated crops, 24 control series, 29 contributing clusters):",
  "**Preferred estimates** (7 treated crops; 24 control-pool series listed, of which 22 contribute — Winter Napa cabbage and Winter Radish have no data in any treated crop's reference year; 29 contributing clusters):"),
 # ---- item 14 in section 1
 ("14", "The estimates are also sensitive to Red pepper (see §3–4). This, too, argues against treating them as a precise causal estimate.",
  "The aggregate estimate is also sensitive to individual treated crops (see §4): Red pepper exerts a sizable negative influence and Onion a sizable influence in the opposite direction. This, too, argues against treating the estimates as a precise causal estimate."),
 # ---- item 2
 ("2", "- **Joint test does not reject.** The joint Wald tests on the clean pre-period coefficients give p = 0.35 (area), 0.67 (yield) and 0.41 (production).",
  "- **Joint test does not reject.** The joint Wald tests on the clean pre-period coefficients give p = 0.35 (area), 0.67 (yield) and 0.40 (production; 0.4049 unrounded). With seven treated crops these tests have low power; failure to reject is not evidence that parallel trends hold."),
 # ---- item 13
 ("13", "- **Individual long leads do reject.** For area and production, the leads at e = −12 to −9 are individually negative and significant (production: −0.30 to −0.15, wild p = 0.01–0.03).",
  "- **Individual long leads.** For production, all four leads at e = −12 to −9 are individually negative and significant (−0.30 to −0.15; wild p = 0.011–0.023). For area, the leads over the same range are negative (−0.23 to −0.13); e = −12, −10 and −9 are individually significant at 5%, while e = −11 is marginal (p ≈ 0.058). Yield leads are not significant."),
 ("13", "- **The pattern flattens near the reference year.** Coefficients at e = −8 to −6 are close to zero.",
  "- **The pattern flattens near the reference year.** Coefficients at e = −8 to −6 are close to zero. The change between e = −9 and e = −8 coincides with a change in composition (Red pepper contributes only up to e = −9), and e = −5 rests on two crops (Onion, Garlic), so the linear slope is a summary only."),
 # ---- item 14 in section 4
 ("14", "- **Leaving out Red pepper** raises production to 0.132 [−0.10, 0.37] and area to 0.129.",
  "- **Leaving out single treated crops.** Leaving out Red pepper raises production to 0.132 [−0.10, 0.37] and area to 0.129; leaving out Onion lowers production to −0.044 [−0.34, 0.25] and area to −0.007. Across the seven leave-one-crop-out estimates, production ranges from −0.044 to 0.132."),
 ("14", "**Red pepper is influential.** Its dried-pepper area and production fell sharply during its long 2008–2014 transition.",
  "**The aggregate estimate is sensitive to individual crops.** Red pepper exerts a sizable negative influence and Onion a sizable influence in the opposite direction. Red pepper's dried-pepper area and production fell sharply during its long 2008–2014 transition."),
 # ---- item 16 (section 5)
 ("16", "**Yes, arithmetically.**\n- Area 0.048 + yield −0.028 = 0.020, which equals production. The log identity holds on the common sample.",
  "**Approximately.**\n- Area 0.048 + yield −0.028 = 0.020 (0.020014 unrounded) against production 0.020 (0.019883): the aggregated estimates are approximately consistent with the log production identity, not exactly equal.\n- At the crop-year level the identity ln P = ln A + ln Y − ln 100 (t = ha × kg/10a / 100) also holds only approximately: on the 990 estimation-sample cells the median |gap| is 0.00014 (KOSIS reports yield in whole kg/10a). Two crop-years exceed 0.01: Spring Radish 2001 (−0.074; reported yield 3,415 vs implied 3,171 kg/10a) and Sesame 2020 (−0.012). Source values are left unchanged and documented in `verified_results/verified_identity_discrepancies.csv`."),
 # ---- item 6 (section 6 table)
 ("6", "| TWFE, clean cells | 0.263 | −0.026 | 0.238 |\n| TWFE, Han (2014)-style naive coding | 0.174 | −0.011 | 0.163 |",
  "| TWFE, clean cells, e = 0…9 | 0.243 | −0.028 | 0.215 |\n| TWFE, Han (2014)-style naive coding, e = 0…9 | 0.156 | −0.021 | 0.135 |\n| *Legacy:* TWFE, clean cells, all post years (e ≤ 12) | 0.263 | −0.026 | 0.238 |\n| *Legacy:* TWFE, Han-style naive coding, all post years (e ≤ 12) | 0.174 | −0.011 | 0.163 |"),
 ("6", "**Why they differ.** B, imputation and TWFE all use the full pre-period as their baseline.",
  "**Why they differ.** All rows above except the legacy rows cover the same post horizon, e = 0…9. B, imputation and TWFE all use the full pre-period as their baseline."),
 # ---- item 15 in section 7 / limitations
 ("15", "- There are only **7 treated clusters** in the annual sample, 6 in fruit, and 4 in the main price sample.",
  "- There are only **7 treated clusters** in the annual sample, 6 in fruit, and 4 in the main price sample.\n- Control support also shrinks with the event horizon: 22 control series contribute at e = 0, but only 8–11 eligible controls per treated crop (11 distinct control series) remain at e = 9, as controls reach their own pilot years."),
 # ---- item 5 (section 8)
 ("5", "- **Controls are annual crops only.** No clean perennial comparison exists, so the area comparison is orchard area versus annual cultivated area.",
  "- **Comparison group.** The comparison group consists primarily of annual crops, while later-treated fruit crops may also serve as not-yet-treated controls during their clean pre-pilot periods. Astringent persimmon (clean to 2005) and Plum (clean to 2007) contribute as clean not-yet-treated controls in some comparisons (for Apple, Pear, Tangerine and Sweet persimmon at e = 0 to 4: 18 of 60 post-period crop × event-time comparisons). No never-treated perennial comparison exists, and the area comparison is orchard area versus annual cultivated area."),
 # ---- item 7 (section 8)
 ("7", "- **Other specifications diverge.** Normalization B and TWFE give 0.38–0.43.",
  "- **Other specifications diverge.** Normalization B (0.380 area, 0.386 production) and TWFE on the same comparison pool as the preferred fruit estimator (0.414 area, 0.399 production) give 0.38–0.41. An earlier TWFE benchmark (0.432 / 0.411) used only the 24 annual control series and is superseded because its control pool was not comparable."),
 # ---- item 3
 ("3", "**What it adds:** DT_1J49 supplies 1980–2004 crop-level history. This gives 8–12 years of clean pre-period placebo coefficients, compared with 3–5 years using DT_1J60 alone. It also makes normalization B possible.",
  "**What it adds:** DT_1J49 supplies 1980–2004 crop-level history. With the linked series the price event study has eight clean pre-period placebo coefficients (e = −12 to −5), resting on 4–8 placebo years per treated crop (the event window is truncated at e = −12); with DT_1J60 alone it has six (e = −10 to −5), resting on 2–4 placebo years per crop. It also gives normalization B a long baseline."),
 # ---- item 4 (section 9)
 ("4", "Because the divisor is common to all crops in a year, it cancels in the difference-in-differences, so the estimates are identical to those on the undivided crop index; only the label changes.",
  "The relative-price and nominal-index estimates are numerically almost identical (−0.1181 vs −0.1180; event-time coefficients differ by at most 0.006). The small difference arises because annual relative prices are constructed from quarterly relative indices before annual aggregation, so the divisor is not an exactly common annual factor."),
 # ---- item 11 (section 11)
 ("11", "APFS national series 2001–2024 (enrollment, financing shares, loss ratios;",
  "APFS national series 2001–2024 (enrollment, financing shares, loss ratios defined as indemnities / risk premium × 100;"),
 # ---- items 5 and 15 (section 12)
 ("5", "6. **Control comparability.** Controls are mostly vegetables; field-crop-only controls change the signs. For fruit, no perennial controls exist.",
  "6. **Control comparability and support.** Controls are mostly vegetables; field-crop-only controls change the signs. Although 24 control-pool series are listed, only 22 contribute to the preferred estimation, and eligible control support shrinks substantially at later event times (8–11 controls per treated crop by e = 9). For fruit, no never-treated perennial controls exist: the comparison group consists primarily of annual crops, with Astringent persimmon and Plum contributing as clean not-yet-treated controls in some comparisons."),
 ("14", "2. **Transition gap.** ATT includes pilot-period exposure and any change during 2–7 transition years. The Red pepper decline shows how this can dominate.",
  "2. **Transition gap.** ATT includes pilot-period exposure and any change during 2–7 transition years (3–7 for the annual crops). The Red pepper decline shows how this can dominate; more generally the aggregate estimate is sensitive to individual crops (Red pepper negative, Onion positive)."),
 # ---- final presentation corrections (approved 2026-09-28, second round)
 ("F1", "The data therefore **cannot rule out** production changes of roughly −25% to +38%.",
  "The data therefore **cannot rule out** production changes of roughly −25% to +39% (the 95% interval [−0.287, 0.327] in log points)."),
 ("F2", "Cohort-specific estimates such as \"Cohort 2015 only\" (1 crop, p = 0.000)",
  "Cohort-specific estimates such as \"Cohort 2015 only\" (1 crop, bootstrap p < 0.001, the smallest value the bootstrap can produce)"),
]

log = []
for item, old, new in EDITS:
    n = text.count(old)
    assert n == 1, f"item {item}: passage found {n} times: {old[:70]}"
    text = text.replace(old, new)
    log.append((item, old, new))

# guard: no 'cancels' statement about the all-farm-output divisor may remain
for m in re.finditer(r"[^.\n]*cancel[^.\n]*[.\n]", text):
    s = m.group(0)
    assert "divisor" not in s and "denominator" not in s, s
assert "2–7 years before" not in text and "0.41 (production)" not in text and "8–12 years" not in text
assert "+38%" not in text and "p = 0.000" not in text

header = """# Chapter 5 — Methodological memo and package README, v3 (corrected)

This file reproduces the README and METHODOLOGICAL MEMO sections of `input/DOCUMENTATION.md`
with **only** the corrections approved on 2026-09-28 applied (generated by
`audit/09_corrected_memo.py`; each edit is listed in the change log at the end).
The original upload is unchanged. Provenance corrections are in `docs/PROVENANCE.md`.
All numbers refer to `verified_results/`.

---

"""
changelog = "\n\n---\n\n## Change log (v2 → v3, approved 2026-09-28; items F1–F2 from the final presentation round)\n\n| Item | Original | Corrected |\n|---|---|---|\n"
for item, old, new in log:
    changelog += "| {} | {} | {} |\n".format(item, old.replace("\n", " ").replace("|", "\\|"), new.replace("\n", " ").replace("|", "\\|"))
open("docs/METHODOLOGICAL_MEMO_v3.md", "w", encoding="utf-8").write(header + text + changelog)
print(len(log), "edits applied")
