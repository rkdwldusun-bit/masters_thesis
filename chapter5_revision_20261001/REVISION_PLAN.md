# Chapter 5 revision plan

Recorded before running the additional calculations on 2026-10-01 Korea time. Existing estimates and diagnostics have already been inspected; this is a post-result revision, not a preregistration.

## Scope

Preserve original files. Retain the seven annual crops as a reference specification, not as a newly validated optimal sample. Add descriptive statistics, fixed-composition pre-pilot paths, crop-specific contrasts, selected specification sensitivities, and a fixed pre-exposure area-weighted comparison. Keep existing fruit, price and rice analyses as explicitly secondary material. Do not claim to recreate the unseen outstanding-thesis template.

## Fixed choices

- Data: verified_results/verified_master_panel.csv and existing coding; years 1991–2024.
- Outcomes: ln_area, ln_yield, ln_production, with raw units in descriptive tables.
- Treated: soybean, onion, sweet_potato, corn, garlic, spring_potato, red_pepper.
- Reference: pilot year minus one; target: coded nationwide crop year plus e, e=0,...,9. All seven contribute at every target.
- Donors: existing control_pool plus clean observations of included treated crops where eligible; clean at both dates. Also show original donors excluding spring_napa and spring_radish, without claiming reclassification is confirmed.
- Descriptives: unique contributing crop-year cells, separately for treated reference, treated targets, donor reference and donor targets. Within each group deduplicate cells; groups may overlap. Mean/SD/min/max are unweighted summaries, not estimator weights.
- Pre-pilot figure: p-10,...,p-1; all seven crops throughout. Within each crop/outcome/variant, donors are clean and observed throughout this entire ten-year window. Normalize treated and donor series to zero at p-1. Same donor set throughout each crop path, but crop-specific sets differ. No CI bands; plots diagnose observed trajectories rather than prove counterfactual trends.
- Crop contrasts: average each crop's ten contrasts. Show both donor variants, without crop-level p-values. Contributions sum to the aggregate.
- Sensitivity table: original reference, last five clean years, all clean years; exclusion of two spring series; field-crop donors; uncertain-seasonal exclusions; product-table and pilot-clock dates. Recover point estimates from code and compare with stored outputs. Leave-one-out and common date shifts go in supplementary tables. Do not select by p-value.
- Area weights: each treated crop's mean area over common 2003–2007, normalized to sum to one. Entire weight window precedes earliest coded pilot (2008). Equal weights remain reference; weights change the target average and do not add independent clusters. Donor contrasts and event-time weights remain unchanged. Apply same weights to all three outcomes and both donor variants. Report concentration 1/sum(w²) as a descriptive index, not inferential degrees of freedom.
- Inference: use frozen September 30 main_inference.csv for original diagnostic SE/CI/p. Explicitly label nominal multiplier intervals and reported p-values as unvalidated diagnostics. Do not silently mix seeds or substitute WCR p-values with unrelated CIs. No new simulation, no new weighted inference. Weight comparison is point-estimate sensitivity only.

## Verification and delivery

Check direct contrasts against original engine and stored results; donor cleanliness; complete support; unique-cell counts; normalized weights; contributions; accounting residual; and main table numeric sources. Render Word and inspect all pages. Supply native editable equations, CSV data, Python builds, and Stata plotting scripts (unexecuted if Stata unavailable). Explain all unavailable validations. Publish only the new revision folder on a dedicated branch based on remote e1057dd7f11b385a582bff335452ccf9dbb7ab2c. No private source PDF or meeting transcript uploads.
