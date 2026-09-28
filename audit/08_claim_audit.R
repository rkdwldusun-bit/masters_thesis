# =====================================================================
# 08_claim_audit.R  -- builds verified_results/claim_audit.csv
# One row per numerical / methodological claim in DOCUMENTATION.md
# (README, METHODOLOGICAL MEMO, source manifest, working summary) and
# in the figure notes of 04_figures.py / 05_apfs_descriptives.py.
# Evidence for each row: audit/output/01-06 (script noted in 'notes').
# verification_level: A = verified from embedded data; B = internally
# consistent (raw source not embedded); C = external source required.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
rows <- list()
cl <- function(id, text, cat, loc, reported, recalc, lvl, status, notes = "")
  rows[[length(rows) + 1]] <<- data.table(claim_id = id, claim_text = text, claim_category = cat, source_location = loc,
    reported_value_or_statement = reported, independently_recalculated_value = recalc,
    verification_level = lvl, status = status, notes = notes)

# ---------------- scope, provenance, pipeline
cl("C001", "Original KOSIS spreadsheets, official PDFs and the full APFS contract-detail CSV are not embedded", "provenance", "DOC: Scope limitation",
   "not embedded", "FILE_MANIFEST: 17 originals embedded_in_DATA_BUNDLE = FALSE; 7 PDFs listed only in DOCUMENTATION", "A", "VERIFIED")
cl("C002", "Source manifest sizes and SHA-256 hashes", "provenance", "DOC: Source manifest table",
   "13 data files with size/hash", "All 13 data-file hashes identical in DOCUMENTATION and FILE_MANIFEST; hashes of the originals themselves cannot be recomputed (files absent)", "B", "VERIFIED_WITH_CAVEAT",
   "Integrity of the originals: C.")
cl("C003", "Pipeline reads the manifest files", "provenance", "CODE 01_build_panel PROD_FILES; 02_build_prices F49/F60/F50",
   "08_vegetables_root.xls, 10_vegetables_spices.xls, 07_barely.xlsx, 13_특용작물생산량__땅콩_.xlsx, 11_farm_output_price_index_2026.xlsx, 12_farm_output_price_index_2005.xlsx",
   "Manifest names 08_vegetables_SPICES.xls and 10_vegetables_ROOT.xls (swapped), 07_barley.xlsx, 특용작물생산량_20260927184000.xlsx, 11_farm_output_price_index.xlsx; 12_farm_output_price_index_2005.xlsx (DT_1J50, deflator base) absent from both manifests",
   "C", "CONFLICTING", "Series are selected by KOSIS table ID, so values are unaffected if each file holds the table its metadata states; the deflator source file must be added to the manifest. audit/output/06; FILE_MANIFEST.")
cl("C004", "run_all.sh rebuilds everything from the raw uploads", "provenance", "DOC README",
   "bash run_all.sh rebuilds everything", "01_build_panel reads treatment_coding_input.csv from the OUTPUT folder (hand-made input); event_time_support, cohort_year_support, control_composition, apfs_crop_level_2023, apfs_province_2023_2024 are produced by no script in CODE_BUNDLE",
   "C", "UNSUPPORTED", "Rebuild from raw cannot be tested (raw files absent). audit/output/01, CODE_BUNDLE.")
cl("C005", "EVENT_SUPPORT / COHORT_SUPPORT / CONTROL_COMP diagnostics describe the current design", "provenance", "DATA_BUNDLE sheets; RESULTS_BUNDLE *_RAW",
   "support diagnostics", "Sheets use obsolete crop IDs (chili_dried, maize, potato_spring, adzuki_bean, citrus), a 20-crop control pool and event times to -24: they come from an earlier pipeline. Current support = RESULTS T12/T13 (consistent with replication).",
   "A", "CONFLICTING", "Do not cite these three sheets. They also contain the banned term 'maize' (as an internal ID).")
cl("C006", "Production panel 1980-2024, 43 crop series", "sample", "DOC README pipeline table", "1980-2024; 43 series",
   "1,935 rows = 43 crops x 45 years; no duplicate crop-year", "A", "VERIFIED", "audit/output/01")
cl("C007", "MASTER_PANEL provenance labels (crop_ko_official etc.)", "provenance", "DATA_BUNDLE MASTER_PANEL", "Korean labels",
   "Five Korean text columns are mis-encoded (UTF-8 read as Latin-1) in the transfer workbook; after re-decoding all 43 match PROD_CROSSWALK. Numeric columns unaffected.",
   "A", "CODING_ERROR", "Transfer-bundle defect only. verified_master_panel.csv carries re-decoded labels; every other cell byte-identical.")
cl("C008", "Random seed fixed (20260927)", "inference", "DOC README; est_engine RNG", "seed 20260927",
   "Seed set once; a single RNG stream is shared across all specifications in run order, so any added/removed spec changes every later bootstrap draw", "A", "VERIFIED_WITH_CAVEAT",
   "Bootstrap CIs are reproducible only for the exact script order.")
cl("C009", "Thesis-facing outputs use only mandatory English display names", "terminology", "DOC README Naming",
   "only mandatory names", "Display names include series not in the thesis name list: Other pulses, Malting barley, Ginger, seasonal Napa cabbage / Radish forms (Spring/Highland/Autumn/Winter), Walnut (APFS). No banned term in thesis-facing labels; 'maize' only in obsolete support sheets.",
   "A", "VERIFIED_WITH_CAVEAT", "Needs author decision on names for control series absent from the list.")
cl("C010", "Estimates described as associations, not causal effects", "interpretation", "DOC README Language; memo s.0, s.11", "associations", "Consistent across memo, figure titles and notes", "A", "VERIFIED")

# ---------------- estimator definition
cl("C011", "Preferred estimator = custom group-time DiD with clean not-yet-treated and never-treated controls; NOT the Callaway-Sant'Anna estimator", "method", "DOC README; memo s.0 Estimators; est_engine.cs_weights",
   "custom group-time DiD", "Code implements exactly this: per treated crop, change from last clean pre-pilot year to g+e minus mean change of all other crops clean in both years (never-treated + not-yet-treated, incl. other treated crops before their pilots); equal weights over crops then over e=0..9. Independent R implementation reproduces all 102 specifications to <1e-12.",
   "A", "VERIFIED", "Internal spec IDs still read 'CS-A', 'CS-B', function run_cs/cs_weights: must never appear in thesis text. No doubly-robust/outcome-regression step, no covariates, no cohort-size weighting -> not C&S. audit/02, 03.")
cl("C012", "Target parameter ATT_i(e): change from last clean pre-pilot year to g_i+e minus same change for crops cleanly untreated in both years; ATT(e) equal-weighted; headline = mean over e=0..9", "method", "memo s.0",
   "definition", "Matches code and R derivation exactly", "A", "VERIFIED", "audit/02")
cl("C013", "Transition years (pilot..national-1) excluded, so e=-1,-2 and often -3..-7 never observed", "treatment", "memo s.0",
   "e=-1,-2, often -3..-7 unobserved", "Unobserved e: Onion, Garlic -3..-1; Soybean, Sweet potato, Corn -4..-1; Spring potato -5..-1; Red pepper -7..-1", "A", "VERIFIED", "audit/01 treatment table")
cl("C014", "The reference year lies 2-7 years before nationwide availability", "treatment", "memo s.0 'Why the gap matters'",
   "2-7 years", "Annual crops: 4-8 years (e=-4 Onion/Garlic; -5 Soybean/Sweet potato/Corn; -6 Spring potato; -8 Red pepper). The memo's own list includes e=-8.",
   "A", "NUMERICAL_ERROR", "Correct: 'lies 4-8 years before nationwide availability (e = -8 to -4)'. Fruit: 3-5 years.")
cl("C015", "Reference years by crop: Soybean/Sweet potato/Corn e=-5; Onion/Garlic -4; Spring potato -6; Red pepper -8", "treatment", "memo s.0",
   "-5/-4/-6/-8", "Same", "A", "VERIFIED")
cl("C016", "Normalizations A (last clean pre-year), B (mean of all clean pre-years since 1991), B5 (mean of last five)", "method", "memo s.0",
   "A/B/B5", "Replicated (window starts 1991; B uses all clean years in window)", "A", "VERIFIED")
cl("C017", "Normalization A was chosen before looking at results; linking rules set in advance", "process", "memo s.0, s.10",
   "pre-specified", "Not verifiable from the bundles", "C", "UNSUPPORTED", "Process claim; keep only if documented elsewhere (e.g. dated pre-analysis note).")
cl("C018", "Each control is used only before its own first pilot", "treatment", "memo s.0",
   "clean controls", "No control cell at/after own pilot enters any comparison (checked in R); 78 control crop-years dropped in log", "A", "VERIFIED", "audit/01, 02")
cl("C019", "Comparison estimator: imputation (two-way FE fitted on clean cells only)", "method", "memo s.0", "imputation",
   "Replicated: 0.244 / -0.028 / 0.216 (exact)", "A", "VERIFIED", "Imputation-style estimator in the spirit of Borusyak-Jaravel-Spiess; citation to be verified (C).")
cl("C020", "Benchmarks: static TWFE on clean cells and Han (2014)-style naive coding", "method", "memo s.0",
   "benchmarks", "Replicated exactly (n=882 / 990). TWFE post dummy covers ALL post years (annual up to e=12; fruit up to e=21), not e=0..9",
   "A", "VERIFIED_WITH_CAVEAT", "Figure 2 axis label 'e = 0 to 9' is wrong for TWFE rows. Han (2014) coding description: C.")

# ---------------- inference
cl("C021", "Crop-clustered analytic standard errors", "inference", "memo s.0 Inference; est_engine inf_full",
   "crop-clustered SE", "SE = sqrt(G/(G-1) * sum_c psi_c^2), psi_c = sum_t a_ct * e_ct over the estimator's linear weights; G = crops with non-zero score. Replicated to 1e-14.",
   "A", "VERIFIED_WITH_CAVEAT", "Custom score-based CR1-type variance, not a regression sandwich. Treated post residuals are net of the event-time ATT, so treatment-effect heterogeneity across the 7 crops is part of the variance.")
cl("C022", "Crop-level wild (multiplier) bootstrap, Webb weights, residuals from a two-way FE model on clean cells, 9,999 draws", "inference", "memo s.0",
   "Webb, 9,999", "Confirmed: star = V psi (V Webb 6-point, one draw per crop, shared across e); CI = est +/- 95% quantile of |star|; p = (#|star|>=|est|+1)/(B+1). R with 99,999 draws reproduces CIs within Monte Carlo error.",
   "A", "VERIFIED_WITH_CAVEAT", "Custom procedure (non-studentised symmetric multiplier interval on score sums); should be called custom, not textbook WCB.")
cl("C023", "TWFE: restricted wild cluster bootstrap (WCR, Webb, 1,999 draws)", "inference", "memo s.0",
   "WCR, Webb, 1,999", "Code: bootstrap-t imposing beta=0, CR1 with (G/(G-1))((n-1)/(n-k)); replicated SE exactly, p within MC error", "A", "VERIFIED_WITH_CAVEAT",
   "Standard WCR-C design; with 7 treated of 31 clusters WCR is known to be conservative. Method citation: C.")
cl("C024", "Pre-trend joint Wald test using the bootstrap covariance", "inference", "memo s.0",
   "bootstrap Wald", "W = th' pinv(cov(star)) th, compared with W* of each draw; replicated within MC error", "A", "VERIFIED_WITH_CAVEAT", "Custom test.")

# ---------------- main estimates
cl("C025", "Preferred sample: 7 treated crops, 24 control series, 29 contributing clusters", "sample", "memo s.1",
   "7 / 24 / 29", "7 / 24 / 29. Winter napa cabbage and Winter radish (data from 2014) never meet a 2007-2009 base year, so only 22 controls ever contribute; post-period controls fall from 22 (e=0) to 8-11 (e=9)",
   "A", "VERIFIED_WITH_CAVEAT", "State 'up to 22 contributing controls' and the shrinking control set at long horizons.")
cl("C026", "Area 0.048 [-0.213, 0.310]", "main estimate", "memo s.1", "0.048 [-0.213, 0.310]", "0.048419; SE 0.13905; R CI [-0.217, 0.314] (99,999 draws)", "A", "VERIFIED", "audit/02")
cl("C027", "Yield -0.028 [-0.132, 0.075]", "main estimate", "memo s.1", "-0.028 [-0.132, 0.075]", "-0.028405; SE 0.05478; R CI [-0.133, 0.076]", "A", "VERIFIED", "audit/02")
cl("C028", "Production 0.020 [-0.287, 0.327]", "main estimate", "memo s.1", "0.020 [-0.287, 0.327]", "0.019883; SE 0.15913; R CI [-0.282, 0.322]", "A", "VERIFIED", "audit/02")
cl("C029", "MDE (2.8 x SE): about +/-0.45 production, +/-0.39 area, +/-0.15 yield", "power", "memo s.1", "0.45 / 0.39 / 0.15",
   "0.446 / 0.389 / 0.153 (analytic SE)", "A", "VERIFIED", "2.8 = 1.96 + 0.84 (5% two-sided, 80% power) under normal approximation.")
cl("C030", "Cannot rule out production changes of roughly -25% to +38%", "power", "memo s.1", "-25% to +38%",
   "exp(-0.287)-1 = -24.98%; exp(0.327)-1 = +38.70%", "A", "VERIFIED_WITH_CAVEAT", "Round the upper bound to +39%.")
cl("C031", "Estimates are sensitive to Red pepper", "robustness", "memo s.1, s.4", "sensitive",
   "Leaving out Red pepper: production 0.020 -> 0.132, area 0.048 -> 0.129. Leaving out Onion moves production to -0.044 (area -0.007). LOO range production -0.044..0.132",
   "A", "VERIFIED_WITH_CAVEAT", "Supported, but Onion is nearly as influential in the opposite direction; say the estimate is sensitive to individual crops, most of all Red pepper and Onion.")

# ---------------- pre-trends
cl("C032", "Joint pre-trend Wald p = 0.35 (area), 0.67 (yield), 0.41 (production)", "pre-trend", "memo s.2",
   "0.35 / 0.67 / 0.41", "Reported 0.3462 / 0.6702 / 0.4049 -> 0.35 / 0.67 / 0.40. R (independent draws): 0.353 / 0.664 / 0.410",
   "A", "NUMERICAL_ERROR", "Production p rounds to 0.40 from the reported table; difference is within Monte Carlo error but text must match the table. Non-rejection is NOT evidence of parallel trends (low power).")
cl("C033", "Leads e=-12..-9 individually negative and significant for area and production (production -0.30..-0.15, wild p 0.01-0.03)", "pre-trend", "memo s.2",
   "all four significant", "Production: -0.299, -0.150, -0.161, -0.178; p 0.013, 0.023, 0.011, 0.017 (all <0.05). Area: -0.234, -0.147, -0.155, -0.130; p 0.042, 0.058, 0.030, 0.034 -> e=-11 not significant at 5% (CI [-0.297, 0.004])",
   "A", "VERIFIED_WITH_CAVEAT", "Say: all four production leads and three of four area leads.")
cl("C034", "Treated crops were growing relative to controls before the pilot; fitted pre-slope ~ +0.05/yr for area and production, ~0 for yield", "pre-trend", "memo s.2",
   "+0.05 / +0.05 / ~0", "OLS slope of pre coefficients: 0.047 / 0.053 / 0.006 (matches T14)", "A", "VERIFIED_WITH_CAVEAT",
   "Visual pattern is a shift between e=-9 (about -0.13 to -0.18) and e=-8 (about 0), then flat, not a smooth trend; the e=-8 set excludes Red pepper and e=-5 rests on 2 crops (Onion, Garlic). Linear slope is a summary only.")
cl("C035", "Coefficients at e=-8..-6 close to zero", "pre-trend", "memo s.2", "near zero",
   "Area -0.001, -0.008, 0.033; production -0.014, 0.001, 0.038", "A", "VERIFIED", "e=-5 (2 crops) is +0.117 area / +0.108 production and is not mentioned.")
cl("C036", "Cohort-level diagnostics rest on 1-4 treated crops; bootstrap Wald degenerate (p ~0.7-1.0)", "pre-trend", "memo s.2",
   "p 0.7-1.0", "Cohort-only pre-trend p range 0.694-0.997", "A", "VERIFIED")
cl("C037", "Pre-pilot relative growth is evidence of non-random timing and the main threat to parallel trends; explains larger distant-baseline estimates", "interpretation", "memo s.2, s.6",
   "interpretation", "Consistent with estimates (B 0.264 vs A 0.048 area); causal reason for selection not identifiable from data (memo says so)", "A", "VERIFIED")

# ---------------- dating robustness
cl("C038", "Product-table nationwide year: area 0.062, production 0.036", "robustness", "memo s.3", "0.062 / 0.036", "0.061689 / 0.036398", "A", "VERIFIED")
cl("C039", "First-pilot clock: area 0.034, production 0.017", "robustness", "memo s.3", "0.034 / 0.017", "0.034486 / 0.016682", "A", "VERIFIED")
cl("C040", "Fruit: Apple and Pear dated 2001: area 0.130 (vs 0.136), production 0.117 (vs 0.115)", "robustness", "memo s.3",
   "0.130 vs 0.136; 0.117 vs 0.115", "0.129992 vs 0.135664; 0.117243 vs 0.114542", "A", "VERIFIED")
cl("C041", "No date choice produces a statistically detectable change", "robustness", "memo s.3", "none significant",
   "All dating variants p_wild >= 0.61", "A", "VERIFIED")
cl("C042", "Treatment dates (pilot, nationwide, alternative, full-scale) from Yearbook 2025 pp.37-38, 44-48, press release 2025.6.15, guideline 2026", "treatment", "TREATMENT sheet 'source'",
   "dates per crop", "Coding is internally consistent (panel = TREATMENT input; identities hold); dates themselves need the Yearbook", "C", "VERIFIED_WITH_CAVEAT",
   "EXTERNAL SOURCE VERIFICATION REQUIRED for every date; crop-year conversion rule (sales month) also external.")

# ---------------- control pools / LOO
cl("C043", "Production across control-pool variants ranges -0.105 (excl. uncertain seasonal) to 0.051 (excl. other pulses)", "robustness", "memo s.4",
   "-0.105 .. 0.051", "-0.104599 .. 0.050692 (spillover -0.054720, field -0.091290)", "A", "VERIFIED")
cl("C044", "Field-crops-only controls (15 clusters): -0.091 [-0.53, 0.35]", "robustness", "memo s.4", "-0.091 [-0.53, 0.35]; G=15",
   "-0.091290 [-0.529, 0.346]; G=15", "A", "VERIFIED")
cl("C045", "Signs not stable across control pools; every interval includes zero", "robustness", "memo s.4", "signs change",
   "Area: +0.066/-0.005/-0.054/-0.082; production +0.051/-0.055/-0.091/-0.105; all CIs contain 0", "A", "VERIFIED")
cl("C046", "Leaving out cohorts: all estimates stay inside the confidence bands", "robustness", "memo s.4", "inside bands",
   "LOO-cohort production -0.061 / -0.069 / 0.132, all inside preferred CI [-0.287, 0.327]", "A", "VERIFIED")
cl("C047", "Leaving out Red pepper: production 0.132 [-0.10, 0.37], area 0.129", "robustness", "memo s.4", "0.132 [-0.10, 0.37]; 0.129",
   "0.131755 [-0.103, 0.367]; 0.129428", "A", "VERIFIED")
cl("C048", "Red pepper area and production fell sharply during its 2008-2014 transition; ATT already -0.40 at e=0 vs 2007", "robustness", "memo s.4",
   "-0.40 at e=0", "ATT_RedPepper(0): production -0.402, area -0.408; raw ln area 2014 vs 2007 -0.418, production -0.634", "A", "VERIFIED")
cl("C049", "Red pepper decline cannot be attributed to insurance", "interpretation", "memo s.4", "not attributable",
   "Appropriate: decline occurs in excluded transition years and carries into post estimates", "A", "VERIFIED")

# ---------------- coherence, estimator comparison
cl("C050", "Area 0.048 + yield -0.028 = 0.020 = production; the log identity holds on the common sample", "coherence", "memo s.5",
   "exact identity", "0.048419 + (-0.028405) = 0.020014 vs production 0.019883 (gap 0.00013). Cell-level ln P - ln A - ln Y + ln 100: median |gap| 0.00014, 95th pct 0.0035, max 0.074 (Spring radish 2001) in estimation sample",
   "A", "VERIFIED_WITH_CAVEAT", "Identity holds approximately (KOSIS rounds yield to whole kg/10a; one outlier). Say 'approximately equals'. Unit relation verified: t = ha x kg/10a / 100.")
cl("C051", "Dynamically area and production move together; yield flat within +/-0.10", "coherence", "memo s.5", "within +/-0.10",
   "Yield event-time estimates -0.092..0.031 (post), -0.066..0.009 (pre)", "A", "VERIFIED")
cl("C052", "Estimator table: B 0.264/-0.036/0.228; B5 0.075/-0.008/0.067; Imputation 0.244/-0.028/0.216; TWFE clean 0.263/-0.026/0.238; Han-style 0.174/-0.011/0.163", "estimator comparison", "memo s.6",
   "as listed", "0.264361/-0.036218/0.227833; 0.075429/-0.008459/0.066856; 0.244486/-0.028009/0.216218; 0.263409/-0.025606/0.237516; 0.174417/-0.011445/0.162616", "A", "VERIFIED")
cl("C053", "None of the estimators, including TWFE, is statistically significant", "estimator comparison", "memo s.6", "none significant",
   "Annual: smallest p = 0.147 (B area)", "A", "VERIFIED")
cl("C054", "TWFE estimates larger because they absorb the pre-trend", "interpretation", "memo s.6", "interpretation",
   "Consistent with full-baseline estimators all ~0.22-0.26 vs A/B5 0.05-0.08; TWFE also averages over longer post horizon (to e=12)", "A", "VERIFIED_WITH_CAVEAT", "Add the horizon difference as a second reason.")

# ---------------- clusters
cl("C055", "7 treated clusters annual, 6 fruit, 4 main price", "inference", "memo s.7, s.12", "7 / 6 / 4", "7 / 6 / 4", "A", "VERIFIED")
cl("C056", "Analytic and wild p similar: 0.901 vs 0.903 (production)", "inference", "memo s.7", "0.901 / 0.903", "0.900561 / 0.9032", "A", "VERIFIED")
cl("C057", "Cohort 2015 only (1 crop, p = 0.000)", "inference", "memo s.7", "p = 0.000", "p_wild = 0.0001 = 1/(B+1), the minimum attainable; single treated crop -> degenerate", "A", "VERIFIED",
   "Report as descriptive; never as significant.")
cl("C058", "Inference with few treated clusters is fragile", "inference", "memo s.7, s.12", "fragile",
   "Supported: 7/6/4 treated clusters; custom multiplier bootstrap; analytic and bootstrap agree only because both rest on the same 7 treated scores", "A", "VERIFIED")

# ---------------- fruit
cl("C059", "Fruit preferred: orchard area 0.136 [-0.13, 0.40], production 0.115 [-0.09, 0.32]", "fruit", "memo s.8",
   "0.136 [-0.13,0.40]; 0.115 [-0.09,0.32]", "0.135664 [-0.129, 0.401]; 0.114542 [-0.089, 0.318]", "A", "VERIFIED")
cl("C060", "Fruit pre-period rises steadily (orchard area -0.33 to -0.04); post continues the same slope", "fruit", "memo s.8",
   "-0.33 .. -0.04", "Pre: -0.326 (e=-12) .. -0.036 (e=-4); post 0.056 (e=0) .. 0.174-0.181 (e=4..9)", "A", "VERIFIED")
cl("C061", "Fruit controls are annual crops only; no clean perennial comparison exists", "fruit", "memo s.8, s.12(6); Figure 4 note",
   "annual controls only", "Controls are 24 annual controls + 7 annual treated crops before their pilots, AND the not-yet-treated fruit crops Astringent persimmon (to 2005) and Plum (to 2007) enter as controls for Apple, Pear, Tangerine, Sweet persimmon in 18 of 60 post comparisons (e=0..4) and 55 of 104 comparisons overall",
   "A", "CONFLICTING", "No NEVER-treated perennial controls exist (true); but perennial not-yet-treated controls are used. Either correct the wording or exclude fruit crops as controls (specification change -> needs approval).")
cl("C062", "Normalization B and TWFE give 0.38-0.43 for fruit", "fruit", "memo s.8", "0.38-0.43", "0.3798 / 0.3864 (B); 0.4319 / 0.4114 (TWFE)", "A", "VERIFIED_WITH_CAVEAT",
   "Fruit TWFE uses CTRL only (24 annual controls, G=30) while CS uses CTRL+annual treated (G=35): benchmark not on the same control set.")
cl("C063", "Adding Peach and Grape (2004 or 2010 dating) changes little", "fruit", "memo s.8", "little change",
   "Area 0.115 / 0.150 vs 0.136; production 0.082 / 0.081 vs 0.115", "A", "VERIFIED_WITH_CAVEAT", "Production falls by about 0.033 (~30%); 'little' is a judgement.")
cl("C064", "Bearing-area yield not estimable before 2009", "fruit", "memo s.8", "bearing area from 2009", "bearing_area_ha first year 2009 (Green plum 2019)", "A", "VERIFIED")
cl("C065", "Sweet and astringent persimmon series begin in 1998", "fruit", "Figure 4 note", "1998", "first production year 1998 for both", "A", "VERIFIED")
cl("C066", "Fruit final clean pre-pilot year ranges from e=-5 to -3", "fruit", "Figure 4 note", "-5..-3", "Apple/Pear/Tangerine/Sweet/Astringent persimmon -3; Plum -5", "A", "VERIFIED")
cl("C067", "Orchard area (fruit) and cultivated area (controls) compared in one outcome", "fruit", "memo s.8; 01_build_panel ln_area_harmonized",
   "harmonized area", "ln_area_harmonized = ln total orchard area (fruit) / ln cultivated area (annual): conceptually different stocks", "A", "VERIFIED", "Keep as limitation.")

# ---------------- price
cl("C068", "DT_1J49 supplies 1980-2004 crop-level history", "price", "memo s.9", "1980-2004",
   "Old series from 1980Q1 for 26 units (Ginger 1995Q1; Plum, Green plum 2000Q1); annual old values present 1980-2012", "B", "VERIFIED_WITH_CAVEAT", "Quarterly raw not embedded.")
cl("C069", "Linked series gives 8-12 years of clean pre-period placebo coefficients vs 3-5 with DT_1J60 alone", "price", "memo s.9",
   "8-12 vs 3-5", "Linked: 8 event-time coefficients (e=-12..-5), 4-8 per crop (truncated at e=-12). DT_1J60 only: 6 coefficients (e=-10..-5), 2-4 per crop (3-5 clean pre years incl. the reference)",
   "A", "NUMERICAL_ERROR", "Correct: 'eight pre-period coefficients (4-8 years per crop) instead of six (2-4 per crop)'.")
cl("C070", "Under A, reference and post years lie in DT_1J60, so the link factor cancels; -0.118 linked, new-only and every link window", "price", "memo s.9",
   "-0.118 in all", "-0.118062 identical in all four (bases 2007-2009)", "A", "VERIFIED")
cl("C071", "Main price estimate (4 crops): -0.118 [-0.289, 0.052]", "price", "memo s.9", "-0.118 [-0.289, 0.052]", "-0.118062 [-0.2886, 0.0524]; R [-0.291, 0.055]", "A", "VERIFIED")
cl("C072", "Price pre-period coefficients noisy, mostly negative (~-0.15 to -0.19 at e<=-10)", "price", "memo s.9", "-0.15..-0.19",
   "e=-12..-10: -0.184, -0.189, -0.163", "A", "VERIFIED")
cl("C073", "Variants: strict -0.051; approximate -0.145; new-only 6 crops -0.166; normalization B -0.019", "price", "memo s.9",
   "as listed", "-0.051436 / -0.145121 / -0.165833 / -0.019063", "A", "VERIFIED")
cl("C074", "Old series only not feasible (2012 cohort at most e=0; 2013, 2015 none)", "price", "memo s.9", "infeasible", "RAW_PRICE_FEAS consistent; old series ends 2012Q4", "A", "VERIFIED")
cl("C075", "Price outcome = crop farm-gate price index divided by the linked all-farm-output price index (relative, not deflated real price)", "price", "memo s.9; README",
   "relative index", "Code divides each quarterly crop index by the linked total index (x100) and averages the ratios within the year; variable names real_* are internal only", "A", "VERIFIED",
   "Thesis label must be 'relative farm-gate price index'.")
cl("C076", "The common annual divisor cancels in the DiD; estimates identical to those on the undivided crop index", "price", "memo s.9; README Price variables",
   "identical", "Annual value = mean of QUARTERLY ratios, so the divisor is not common across crops (implied annual divisor varies 0.1-6.5% across crops within a year). Main estimate: relative -0.118062 vs undivided -0.117974 (diff 0.00009); event-time coefficients differ by up to 0.006",
   "A", "NUMERICAL_ERROR", "Algebraically exact only for a ratio of annual means. Correct: 'approximately cancels; the main estimate changes by less than 0.001'.")
cl("C077", "Deflator: DT_1J50 (2005=100) linked to DT_1J60 (2020=100), link factor 0.7079 over 2005Q1-2012Q4", "price", "PRICE_DEFL_LINK; 02_build_prices",
   "k = 0.7079", "Parameters embedded; quarterly deflator (price_deflator_quarterly.csv) and DT_1J50 source not embedded", "C", "VERIFIED_WITH_CAVEAT", "EXTERNAL SOURCE VERIFICATION REQUIRED.")
cl("C078", "Linking rules (quarterly corr>=0.90, CV<=5%, max disc<=10%; annual corr>=0.95, CV<=5%, disc<=10%); main = exact AND annual; strict = exact AND both", "price", "memo s.10",
   "rules", "Recomputing the flags from the reported statistics reproduces all quarterly/annual/main/strict flags", "A", "VERIFIED", "Statistics themselves: B (quarterly raw not embedded); approximate recomputation from embedded annual series agrees closely.")
cl("C079", "Strict: Sweet potato, Garlic (treated); Red bean, Cabbage, Sesame, Perilla, Peanut (controls)", "price", "memo s.10", "7 units", "Same 7 units", "B", "VERIFIED")
cl("C080", "Annual rule only: Onion, Red pepper; Carrot, Ginger; Pear, Peach", "price", "memo s.10", "6 units", "Same", "B", "VERIFIED")
cl("C081", "Approximate but linkable: Potato, Rice, Napa cabbage, Radish, Green onion, Spinach, Leaf lettuce", "price", "memo s.10", "7 units",
   "All 7 pass annual rule; Radish and Spinach fail the quarterly rule", "B", "VERIFIED")
cl("C082", "Not linkable: Soybean (annual max disc 11.9%), Corn (annual corr -0.18), Barley, Malting barley (low corr)", "price", "memo s.10",
   "11.9%; -0.18", "11.936%; -0.1793; 0.688 / 0.814", "B", "VERIFIED")
cl("C083", "Incompatible: Apple (Fuji -> all), Sweet persimmon (all persimmons -> sweet); no overlap: Tangerine, Grape, Plum, Green plum", "price", "memo s.10",
   "as listed", "Same; Mung bean (old series only, ends 2004) is not mentioned in the memo table", "B", "VERIFIED_WITH_CAVEAT")
cl("C084", "Soybean and Corn appear only in the new-series (2005-2024) variant", "price", "memo s.10", "new-series only", "Confirmed", "A", "VERIFIED")
cl("C085", "Price-item definitions (e.g. rice 일반미 -> 멥쌀; potato pools seasons; leaf lettuce vs lettuce)", "price", "memo s.10, s.12(9); PRICE_ITEMS",
   "item crosswalk", "Crosswalk internally consistent", "C", "VERIFIED_WITH_CAVEAT", "Item definitions require the KOSIS item metadata (not embedded).")
cl("C086", "Pooled price units carry hard-coded dates (napa cabbage 2014, radish 2015, green onion 2014, spinach 2013, leaf lettuce 2013; potato 2008/2013)", "price", "03_estimate.py PD dict",
   "hard-coded", "Not in TREATMENT input; used only in the approximate-match variant", "C", "VERIFIED_WITH_CAVEAT", "Greenhouse-product dates need the Yearbook.")

# ---------------- rice
cl("C087", "Rice is a descriptive single-crop case with dates 2012 / 2014 / 2017", "rice", "memo s.11; 03_estimate",
   "descriptive", "135 rice ATT(e) values replicated exactly for all three datings; no inference produced", "A", "VERIFIED", "Dates: C.")
cl("C088", "Rice timing overlaps rice-specific policies (direct payments, production adjustment, public stockholding)", "rice", "Figure 6 note",
   "overlap", "Not verifiable from bundles", "C", "UNSUPPORTED", "EXTERNAL SOURCE VERIFICATION REQUIRED.")

# ---------------- APFS
cl("C089", "APFS national series 2001-2024 (enrollment, financing, loss ratio)", "APFS", "memo s.11; APFS_NATIONAL",
   "national series", "APFS_NATIONAL = merge of embedded public CSVs (ENROLL_RAW, PAY_RAW), identical", "A", "VERIFIED", "Recomputed from the embedded public tables.")
cl("C090", "2010-2011: reported components sum to about 75% of net premium; provincial and municipal fields zero; dataset does not explain the residual", "APFS", "memo s.11; Figure 10 note",
   "~75%", "2010: 75.19%; 2011: 74.34%; provincial = municipal = 0; all other years 100%", "A", "VERIFIED", "Do NOT attribute the residual to any payer.")
cl("C091", "Loss ratio = indemnities / premium as defined by APFS", "APFS", "Figure 9 note",
   "indemnities / premium", "Reported loss ratio = indemnity / RISK premium (위험보험료) x 100 (max deviation 0.1, rounding); equals indemnity / net premium only up to 2011", "A", "VERIFIED_WITH_CAVEAT",
   "State the denominator explicitly: risk premium.")
cl("C092", "Enrollment-rate denominator expands as crops are added (e.g. rice from 2009)", "APFS", "Figure 9 note",
   "denominator expands", "Area rate falls 23.1% (2008) -> 12.5% (2009) while insured area rises 26,037 -> 48,331 ha: consistent", "B", "VERIFIED_WITH_CAVEAT", "Rice-2009 attribution: C.")
cl("C093", "APFS 2023 crop cross-section", "APFS", "APFS_CROP_2023", "82 items", "Identical to embedded public CSV (APFS_CROPJOIN23)", "A", "VERIFIED",
   "Crop-level loss ratio = indemnity / risk premium x 100 (max deviation 6e-8); using premium after refunds would deviate by up to 43 points.")
cl("C094", "APFS 2023/2024 province cross-section", "APFS", "APFS_PROV_23_24", "18 regions",
   "Regional sums equal national totals for farms, contracts, premium, indemnity (2023, 2024); national loss ratio 107.3 (2023) / 97.9 (2024) = indemnity / risk premium", "B", "VERIFIED",
   "Raw province file not embedded (derived table only).")
cl("C095", "2024 fruit contract-detail file: 336,232 rows, 12,099 exact duplicates, no contract identifier, 694 revenue-insurance grape rows", "APFS", "memo s.11; APFS_FRUIT_AUD",
   "336,232 / 12,099 / none / 694", "Crop-level records sum to 335,538 = 336,232 - 694 (consistent). Duplicates and identifier cannot be checked", "B", "VERIFIED_WITH_CAVEAT",
   "Consistent with the supplied audit summary; NOT recomputed from raw records.")
cl("C096", "Rows with zero/invalid yield or price fields: 10,529", "APFS", "APFS_FRUIT_AUD", "10,529",
   "Crop-level zero/invalid normal-yield counts sum to 10,518 (crop-disaster rows only); difference 11 = revenue-grape rows (plausible)", "B", "VERIFIED_WITH_CAVEAT",
   "Audit label says 'yield or price' but code counts only missing normal yield.")
cl("C097", "Insured-to-normal yield shares by crop (Figure 7)", "APFS", "APFS_FRUIT_CROP", "shares",
   "Below/equal/above shares sum to 1 for all 21 crops", "B", "VERIFIED_WITH_CAVEAT", "Consistent with supplied summary; raw not embedded.")
cl("C098", "Insured-price unit not defined in available official sources", "APFS", "memo s.12(10); Figure A1 note", "undefined unit", "Not verifiable", "C", "VERIFIED_WITH_CAVEAT",
   "Keep appendix-only.")
cl("C099", "Rows are administrative contract-detail records, not unique contracts", "APFS", "Figure 8 note", "records", "Consistent with audit summary (no identifier)", "B", "VERIFIED")

# ---------------- limitations
cl("C100", "ATT includes pilot-period exposure and changes during 2-7 transition years", "limitation", "memo s.12(2)", "2-7 years",
   "Transition lengths: annual 3-7, fruit 2-4", "A", "VERIFIED_WITH_CAVEAT", "Say 3-7 years for annual crops.")
cl("C101", "Changes of +/-25-40% in area or production cannot be excluded", "limitation", "memo s.12(4)", "+/-25-40%",
   "Production CI -25%..+39%; area CI -19%..+36%", "A", "VERIFIED")
cl("C102", "Controls mostly vegetables; field-crop-only controls change the signs", "limitation", "memo s.12(6)", "mostly vegetables",
   "15 of 24 control series are vegetables; field-only: area -0.054, production -0.091 (sign change)", "A", "VERIFIED")
cl("C103", "Winter forms observed only from 2014", "limitation", "memo s.12(9)", "2014", "Winter napa / winter radish first year 2014 (2011 zero recoded missing)", "A", "VERIFIED")
cl("C104", "Crop-year conversion assumes historical sales windows equal those in the 2026 guideline", "limitation", "memo s.12(7)", "assumption", "Not verifiable", "C", "UNSUPPORTED", "EXTERNAL SOURCE VERIFICATION REQUIRED.")
cl("C105", "Corn series may include forage corn; Spring potato and Rice prices approximate", "limitation", "memo s.12(9)", "definitions", "Not verifiable from bundles", "C", "VERIFIED_WITH_CAVEAT")
cl("C106", "Scientific names and method citations must be verified", "limitation", "memo s.12(11); NOMENCLATURE", "to verify", "Not verified", "C", "UNSUPPORTED")
cl("C107", "Autumn potato coded 'robustness_treated'", "treatment", "TREATMENT sheet", "robustness treated",
   "Autumn potato is not used in any specification", "A", "VERIFIED_WITH_CAVEAT", "Harmless; remove the role or add the robustness spec.")
cl("C108", "Figure 1/3 notes: 'Controls: 24 annual crop series'", "figure note", "04_figures NOTE_ANN", "24 controls",
   "24 listed; 22 ever contribute; 8-11 remain at e=9", "A", "VERIFIED_WITH_CAVEAT")
cl("C109", "Figure 2 x-axis: 'Average estimated change, e = 0 to 9' for all estimators", "figure note", "04_figures Fig 2", "e = 0..9",
   "TWFE rows are single static coefficients over all post years (e up to 12)", "A", "INTERPRETIVE_OVERREACH", "Label TWFE rows separately.")

# ---------------- working interview summary: institutional/history claims (not primary evidence)
wk <- list(
  c("2002-03 typhoons Rusa and Maemi; private reinsurers withdrew; national reinsurance introduced 2005", "연감 p.266"),
  c("National reinsurance cumulative loss ratio 227.3% (premium 501.3bn vs claims 1,139.6bn KRW)", "연감 p.269"),
  c("Micro-underwriting changes: exclusion after two non-cultivation payouts; 80% cap at 500% cumulative loss ratio (2026.7); individual experience rating (2026.11)", "지침 p.3-5"),
  c("NH legal status = indirect subsidy operator; 2026 national budget 556.6bn KRW", "지침 p.1"),
  c("Net premium ~50% subsidy + loading 100% national; operating cost 100% subsidised; expected expense ratio set by budget", "지침 p.2-3; 연감 p.38, 41"),
  c("Profit-loss sharing 100% (2019-), national share 50% (2020-)", "연감 p.267-268"),
  c("Differentiated subsidy rates 33-65% across three crop groups", "지침 p.2"),
  c("Evaluation indicators are all input/output measures; 'raise enrollment' objective repeated", "지침 p.11, 13, 20"),
  c("2024: 73 crops; 2026: 78 crops (94 products)", "연감 p.38; 지침 p.3"),
  c("Crop-group loss ratios 2024: four fruits 57.2% (enrollment 71.1%), food crops 165.5%, open-field 121.9%, greenhouse 120.9%", "연감 p.178"),
  c("Main program types 1/2 and pilot lists; pilots limited to a few counties", "지침 p.25-27"),
  c("Cash-flow timing of farmer, national, local shares; NH advances local-government share", "지침 p.5, 9, 14, 36; 연감 p.41-42"),
  c("Commission performance linkage only +/-10%", "지침 p.18"),
  c("Reinsurance settlements 2022 +104.7bn, 2023 +169.4bn received; 2024 0 received, 158.2bn paid", "연감 p.269-270"),
  c("Revenue insurance: one of the two per object; 2024 9 crops, 3.9% enrollment, 9bn premium (0.8%), loss ratio 7.7-765.1%; sold within crop budgets", "지침 p.3; 연감 p.53, 57"),
  c("Price-calculation crops to expand by 2027", "지침 p.12, 29-34"))
for (k in seq_along(wk)) cl(sprintf("C%03d", 109 + k), wk[[k]][1], "external (working summary)", paste("DOC working interview summary;", wk[[k]][2]),
                            wk[[k]][1], "Not checked (source PDF not embedded; not audited from memory)", "C", "UNSUPPORTED",
                            "EXTERNAL SOURCE VERIFICATION REQUIRED. Working summary is not primary evidence.")
cl("C126", "2024 enrollment rate 54.2%, driven by rice", "APFS", "DOC working summary; 연감 p.157", "54.2%",
   "Area enrollment rate 2024 = 54.2 (APFS_NATIONAL). 'Driven by rice': not verifiable", "A", "VERIFIED_WITH_CAVEAT", "Rice attribution: C.")
cl("C127", "Enrollment fell during crop expansion: 22.7% (2007) -> 13.6% (2012)", "APFS", "DOC working summary; 연감 p.266", "22.7 -> 13.6",
   "Area enrollment rate 2007 = 22.7, 2012 = 13.6", "A", "VERIFIED", "'Denominator effect' interpretation: consistent with rising eligible area but not proven.")
cl("C128", "Overall loss ratio 97.9% (2024)", "APFS", "DOC working summary; 연감 p.178", "97.9%", "APFS province table 2024 national: 97.89 (indemnity / risk premium)", "B", "VERIFIED")
cl("C129", "Callaway and Sant'Anna (2021), Han (2014), BJS, MacKinnon-Webb citations", "external (literature)", "memo s.0",
   "citations", "Not audited", "C", "UNSUPPORTED", "Verify originals before citing.")

# ---------------- new claims introduced by the approved corrections (2026-09-28)
cl("C130", "Annual static TWFE, clean cells, estimated over e = 0..9 (same horizon as the other estimators)", "estimator comparison",
   "docs/METHODOLOGICAL_MEMO_v3 s.6; Figure 2; audit/06b", "0.243 / -0.028 / 0.215",
   "0.242951 / -0.027927 / 0.214717; CR1 SE 0.1920 / 0.0695 / 0.1959; WCR p 0.231 / 0.716 / 0.290 (9,999 draws); n = 868, G = 31",
   "A", "VERIFIED", "Computed in R from embedded data (new benchmark; no Python counterpart). All-post legacy version retained: 0.263 / -0.026 / 0.238.")
cl("C131", "Annual static TWFE, Han-style naive coding, estimated over e = 0..9", "estimator comparison",
   "docs/METHODOLOGICAL_MEMO_v3 s.6; Figure 2; audit/06b", "0.156 / -0.021 / 0.135",
   "0.156347 / -0.021043 / 0.134919; CR1 SE 0.1770 / 0.0562 / 0.1767; WCR p 0.392 / 0.738 / 0.460; n = 976, G = 31",
   "A", "VERIFIED", "Legacy all-post version retained: 0.174 / -0.011 / 0.163.")
cl("C132", "Fruit static TWFE on the preferred fruit comparison pool (24 annual controls + 7 annual treated crops before their pilots)", "fruit",
   "docs/METHODOLOGICAL_MEMO_v3 s.8; audit/06b", "0.414 / 0.399",
   "Orchard area 0.413716 (SE 0.1854, WCR p 0.053); production 0.399009 (SE 0.1620, WCR p 0.047); G = 37, n = 974, all post years (e <= 21). Supplementary e = 0..9 version: 0.426 / 0.407",
   "A", "VERIFIED", "Supersedes the annual-controls-only benchmark (0.432 / 0.411, G = 30). Benchmark only; the p-values carry no interpretive weight (the benchmark absorbs the pre-trend).")
cl("C133", "24 control-pool series listed; 22 contribute; eligible control support shrinks to about 8-11 controls by e = 9", "sample",
   "docs/METHODOLOGICAL_MEMO_v3 s.1, s.7, s.12(6); Figure 1 note", "24 / 22 / 8-11",
   "24 listed; 22 contribute (Winter napa cabbage and Winter radish never do); per treated crop min-max controls: e=0 22-22, e=4 15-22, e=5 14-20, e=6 11-20, e=7 10-15, e=8 10-14, e=9 8-11 (11 distinct series at e=9)",
   "A", "VERIFIED", "verified_results/verified_event_time_support.csv")
cl("C134", "Current support tables (T12/T13 equivalents) replace the stale EVENT_SUPPORT / COHORT_SUPPORT / CONTROL_COMP sheets", "provenance",
   "verified_results/verified_event_time_support.csv, verified_control_composition.csv", "code-consistent support",
   "Rebuilt from the current design; identical to RESULTS T12 (110 rows) and T13 (72 rows)", "A", "VERIFIED", "Stale sheets quarantined in audit/extracted/*/stale_do_not_use/.")
cl("C135", "Relative-price and nominal-index estimates are numerically almost identical; the small difference arises from building annual relative prices from quarterly relative indices", "price",
   "docs/METHODOLOGICAL_MEMO_v3 README and s.9", "almost identical",
   "Main: -0.118062 (relative) vs -0.117974 (nominal); max event-time difference 0.0063 (0.0030 post); implied annual divisor varies 0.1-6.5% across crops within a year",
   "A", "VERIFIED", "Replaces C076 wording.")
cl("C136", "Price placebo coefficients: 8 (e = -12..-5; 4-8 years per crop) with the linked series vs 6 (e = -10..-5; 2-4 per crop) with DT_1J60 alone", "price",
   "docs/METHODOLOGICAL_MEMO_v3 s.9", "8 vs 6", "Per crop linked: Onion 8, Sweet potato 7, Garlic 8, Red pepper 4; DT_1J60 only: 3, 3, 4, 2", "A", "VERIFIED", "Replaces C069 wording.")
cl("C137", "Fruit comparison group consists primarily of annual crops; later-treated fruit crops may serve as not-yet-treated controls in clean pre-pilot periods (Astringent persimmon, Plum)", "fruit",
   "docs/METHODOLOGICAL_MEMO_v3 s.8, s.12(6); Figure 4 note", "wording", "Astringent persimmon (to 2005) and Plum (to 2007) in 18 of 60 post comparisons (e = 0..4 for Apple, Pear, Tangerine, Sweet persimmon)",
   "A", "VERIFIED", "Replaces C061 wording; specification unchanged.")
cl("C138", "Crop-year log production identity discrepancies > 0.01 in the estimation sample", "coherence",
   "verified_results/verified_identity_discrepancies.csv", "documented",
   "Spring radish 2001 (gap -0.0743; reported yield 3,415 vs implied 3,170.5 kg/10a); Sesame 2020 (-0.0123). Source values unchanged",
   "A", "VERIFIED", "Aggregated: area + yield 0.020014 vs production 0.019883 -> 'approximately consistent with the log production identity'.")
cl("C139", "Figure 7 excludes records with a missing or non-positive insured or normal yield", "APFS", "Figure 7 note; 05_apfs_descriptives.py",
   "exclusion rule", "Code: ratio = insured / normal yield after non-positive values set to missing; shares on non-missing ratios", "B", "VERIFIED", "Raw records not embedded.")

A <- rbindlist(rows)
stopifnot(!anyDuplicated(A$claim_id))

# ---------------- resolutions of the approved corrections (status of the original finding is kept)
res <- c(
  C014 = "Item 1: corrected to '4-8 years before nationwide availability (e = -8 to -4)'.",
  C032 = "Item 2: corrected to 0.40 (0.4049 unrounded); non-rejection explicitly not evidence of parallel trends.",
  C069 = "Item 3: replaced by the actual counts (see C136).",
  C076 = "Item 4: every 'cancels' statement about the divisor removed; replaced by 'numerically almost identical' (see C135).",
  C061 = "Item 5: specification unchanged; description replaced by the approved wording; Astringent persimmon and Plum documented (see C137).",
  C020 = "Item 6: Figure 2 now uses TWFE estimated over e = 0..9 (C130, C131); all-post TWFE retained as LEGACY benchmark.",
  C109 = "Item 6: Figure 2 axis and note corrected; all rows now cover e = 0..9.",
  C054 = "Item 6: horizon difference removed from the Figure 2 comparison by construction.",
  C062 = "Item 7: fruit TWFE re-estimated on the preferred fruit pool (C132); old result SUPERSEDED in verified_benchmark_record.csv. Range now 0.38-0.41.",
  C005 = "Item 8: stale sheets quarantined; replaced by code-consistent T12/T13 equivalents (C134).",
  C007 = "Item 9: verified_master_panel.csv carries the re-decoded UTF-8 labels.",
  C003 = "Item 10: reconciled in docs/PROVENANCE.md; DT_1J50 documented; AUTHOR ACTION remains for 08/10 file names and the DT_1J50 hash.",
  C004 = "Item 10: documented in docs/PROVENANCE.md (reproducibility statement).",
  C091 = "Item 11: loss ratio defined as indemnities / risk premium x 100 in Figure 9 and memo v3.",
  C096 = "Item 12: audit label corrected to 'rows with missing or non-positive normal yield'; value unchanged.",
  C033 = "Item 13: pre-trend prose corrected (production all four; area e = -11 marginal, p ~ 0.058).",
  C031 = "Item 14: influence discussion now names Red pepper (negative) and Onion (opposite direction).",
  C025 = "Item 15: support limitation added; numbers verified (C133).",
  C108 = "Item 15: Figure 1 note states 24 listed, 22 contribute, 8-11 at e = 9 (computed from data).",
  C050 = "Item 16: 'approximately consistent with the log production identity'; crop-year discrepancies documented (C138).",
  C100 = "Memo v3 s.12(2): '2-7 transition years (3-7 for the annual crops)'.")
A[claim_id %in% names(res), notes := paste0(notes, fifelse(notes == "", "", " | "), "RESOLVED 2026-09-28 -- ", res[claim_id])]
stopifnot(all(names(res) %in% A$claim_id))
fwrite(A, "verified_results/claim_audit.csv", bom = TRUE)
cat("claims:", nrow(A), "\n"); print(A[, .N, by = .(verification_level, status)][order(verification_level, status)])
