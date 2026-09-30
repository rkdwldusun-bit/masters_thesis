# Post-result execution plan — 2026-09-30

Written after the original results, 54 exploratory specifications, and Claude audit revisions were inspected. This is not preregistration. Parent audit: 086aa262; remote baseline: d4a4630. Preserve both previous folders unchanged.

## Fixed scope before this run

- Same national crop panel, 1991–2024, seven annual treated crops and the original control pool.
- Two donor variants: original; exclude spring_napa and spring_radish. No unverified spring/winter harmonization.
- Three log outcomes: area, yield, production. Main window e=0..9, last clean pre-pilot baseline.
- Date sensitivities: original; shift pilot dates of all seven treated crops -1/+1; shift national dates -1/+1. These are four separate common shifts, not all joint combinations. Keep control dates unchanged. Also report a common-support e=0..8 window for every date variant because a +1 national shift loses e=9 for red pepper in 2024. All results retained. No significance-based selection.
- Actual-data inference: original crop-score Webb multiplier, 9,999 draws, plus two explicitly diagnostic alternatives at unshifted dates: seven crop means t(6); exact weighted stacked difference regression with original-crop clusters and restricted wild bootstrap-t (WCR), 1,999 draws. WCR p tests zero; cluster-t CIs are separately named and are NOT inverted WCR CIs.
- Stacked identity: each treated crop/event stratum contains its own baseline-to-target difference (weight q) and each clean donor difference (weight q/n_donor), q=1/(number events * treated crops in that event). Absorb stratum intercepts; regress on treated indicator. Exact cell-weight equality and synthetic-outcome equality required. Cluster all repeats of each original crop together. Equivalence of point estimates does not establish valid inference under heterogeneous effects or few treated clusters.
- Trends: fixed clean donors over pilot-relative -10..-1; additionally fit crop-specific relative slopes on final five clean years. Scenario bias k*s_i*(target-baseline), k=0,.5,1, with original event/crop weights. Report point scenarios and zero crossing. OLS slope SE is an iid-model descriptive quantity, not serial-correlation-robust uncertainty. No scenario confidence intervals.
- Descriptives: actual contributing cells, all clean pre-period context, raw units and logs, mean, SD, min, max, N and crop count. No claim that similar means establish parallel trends.

## Simulation design, fixed before execution

- Six designs = two donor variants * three outcomes, unshifted dates only. 4,000 zero-effect panels per design and correlation setting; rho in {0,.3,.6}.
- Calibrate residual SD and consecutive-year AR(1) on each crop's clean TWFE residuals. Bound AR estimates to [-.95,.95] and export raw and bounded parameters. Groups are the panel's vegetable, grain, pulse, tuber, special categories.
- Stationary multivariate AR(1) with diagonal crop persistence. Marginal SD calibrated above. Standardized innovation contemporaneous correlation rho within crop group, zero across groups. Different persistence implies level correlations need not equal rho. Initialize from the implied stationary covariance; retain calendar gaps before masking to actual cells. Export parameter table.
- Null outcome is the simulated error process, no treatment effects. Fixed FE may be omitted since all tested contrast weights annihilate additive crop and year FE. This is a parametric stress test, not a validation of parallel trends.
- Compare original multiplier and seven-means t(6); WCR evaluated on the same panels using crop-cluster restricted residuals. 999 bootstrap draws per simulated panel. Fresh Webb weights per panel; shared weights between multiplier and WCR for paired comparison. Actual-data bootstrap uses more draws. Seed 20260930 with distinct reproducible streams.
- Report rejection at .05, Wilson Monte Carlo 95% intervals, SE of rejection rate, null inclusion=1-rejection (for test-inverted WCR, only null membership is evaluated). No pass/fail tolerance and no automated preferred-method selection. WCR observed cluster-t interval coverage reported separately from its bootstrap rejection.
- Retain all simulation conditions and inference methods, whether favorable or unfavorable. No width-based claim of validity. Numerical equivalence checks before substantive simulation.

## Scope limits and execution

Raw KOSIS originals and historical policy sources are not newly validated. The inherited audit log is evidence of Claude's run, not our independent raw-file rerun. Nationwide crop effects concern availability and include pilot transition exposure relative to the pre-pilot baseline, not individual enrollment effects or income stability. Stata is unavailable: Python figures are executed previews; Stata do-files are supplied but unexecuted.

Methods references: MacKinnon & Webb, The wild bootstrap for few (treated) clusters, Econometrics Journal (2018), https://doi.org/10.1111/ectj.12107 ; https://www.econ.queensu.ca/research/working-papers/1404 . HonestDiD supports staggered adoption in appropriate designs (https://github.com/asheshrambachan/HonestDiD); common calendar adoption is not a universal requirement. Our varying pre-event composition, nonstandard baselines/gaps and uncertain covariance require a justified mapping before application. It is not run or presented as automatically inapplicable.
