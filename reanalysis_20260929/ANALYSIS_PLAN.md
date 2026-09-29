# Exploratory reanalysis plan — 2026-09-29

Source commit: 00b60931ef577aca690d0d3aa2fc4a4c3bed5e64. Existing results were inspected before this plan; this is NOT preregistration. No external treatment-date verification or new observations are introduced.

Scope: national annual-crop production panel, seven original treated crops, original control pool, 1991–2024. Outcomes: log area, log yield, log production. Preserve original files.

1. Reproduce all three preferred coefficients and clustered SEs (tolerance 1e-9), using the original bundled Python estimator. Bootstrap seed fixed, 9,999 Webb draws; compare Monte Carlo differences, not exact p-values.
2. Fixed sensitivity grid: national vs pilot clock; final clean pre-pilot year vs last five clean years; post horizons 0–9, 0–2, 3–5, 6–9. Total 48 estimates, all reported. Shorter horizons describe different estimands, not increased evidence for the original ten-year effect. Pilot clock is national aggregate exposure to partial rollout, not universal enrollment.
3. Conventional clean-cell TWFE benchmarks over national event time 0–9, with and without crop-specific linear trends (6 estimates). Trends are a strong extrapolation/restriction and may absorb real effects; TWFE can suffer heterogeneous-effect weighting. Never promote the most significant benchmark as the preferred causal result.
4. Provide Holm correction across all 54 exploratory effect tests, while emphasizing that multiple-testing correction cannot repair invalid identification or inference.
5. Diagnostics: descriptive N/mean/SD; seven crop-specific contrasts; pilot-relative preperiod -10 to -2 against -1 using the same seven treated crops and fixed per-crop clean donors over the whole prewindow; raw trajectories; leave-one-out results already available.
6. Audit the original score procedure under stylized no-effect panel simulations with AR(1) rho=0,0.7,0.95; fixed observed sample/missingness; independent crop errors. This is a limited calibration check, not proof of validity, and cannot diagnose all real-data dependence. Report MC uncertainty. No calibration-based p-value correction.
7. No outcome-guided deletions, one-sided conversions, stopping when significant, or new treatments based on results. Do not claim regional clustering adds independent treatment assignments to nationwide crop-level rollout.

Decision: retain inconclusive findings where warranted; distinguish sensitivity of estimates from credible causal evidence. A low p-value in a trend model is an exploratory conditional association until its restrictions are supported.
