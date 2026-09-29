# Exploratory reanalysis — 2026-09-29

The source package is preserved. This folder is a separate, user-requested reanalysis, not a replacement of the preferred specification.

**Results:** 54 annual-crop effect tests, zero raw p-values below .05 (minimum .2306). All Holm-adjusted p-values are 1. Existing estimates and SEs reproduced to <1e-9. No new external observations or treatment-date verification.

**Important inference diagnostic:** under three stylized no-effect AR(1) designs (rho 0, .7, .95), the original custom multiplier test rejected at .05 in 11.8%, 9.55%, and 9.15% of 2,000 simulations. This does not give a real-data corrected p-value or validate a replacement method. Linear score calculations were checked against direct original-engine runs; benchmark bootstrap calculations were checked against literal OLS refits.

**Pretrends:** with all seven treated crops retained and donor composition fixed within each crop's pilot-preperiod window, area and production still show relative movements. Plots are descriptive, not tests of proven violations.

## Read and reproduce

- `reanalysis_report.html`: self-contained Korean report, all effect tests and embedded plots.
- `ANALYSIS_PLAN.md`: scope fixed before this run, but after earlier results had been inspected; not preregistration.
- `outputs/all_54_effect_tests.csv`: complete comparison; custom and benchmark inference clearly separated by method.
- `outputs/descriptive_stats.csv`, `descriptive_by_crop.csv`: N, means, SDs; not causal-effect SEs.
- `outputs/numerical_checks.csv`, `replication.csv`: verification evidence.
- `outputs/null_calibration.csv`: conditional Monte Carlo intervals for limited simulation designs.
- `outputs/run_manifest.json`: versions, seed, and source data hash.

Requires Python with numpy, pandas, scipy, matplotlib. From repository root:

```bash
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 python reanalysis_20260929/run_reanalysis.py
python reanalysis_20260929/build_report.py
```

`original_engine.py` is extracted unchanged from the bundled `est_engine(1).py`, source commit `00b60931ef577aca690d0d3aa2fc4a4c3bed5e64`. Running it again is a reproduction, not an independent validation of its statistical theory. Standard Callaway–Sant'Anna package estimation was not performed. TWFE/trend regressions remain sensitivity benchmarks because heterogeneous effects and trend restrictions can invalidate causal interpretation.
