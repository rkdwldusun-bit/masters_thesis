# Reanalysis, 30 September 2026

Read [RESULTS_KO.md](RESULTS_KO.md) for findings or download [report.html](report.html) for a standalone illustrated Korean report. This is post-result sensitivity work, not preregistered confirmatory evidence.

The supplied Claude audit (commits 5744490 and 086aa26) is preserved in `../audit_claude_20260930/`. Its raw-file claims were not independently rerun here. This folder contains newly executed calculations.

## Reproduce

From repository root, Python with numpy, pandas, scipy and matplotlib:

```bash
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 python reanalysis_20260930/run_analysis.py
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 python reanalysis_20260930/run_simulation.py
OPENBLAS_NUM_THREADS=1 python reanalysis_20260930/build_report.py
```

Execution plan: [PLAN.md](PLAN.md). No randomness in point estimates. Actual-data Webb seed 20260930; 9,999 original multiplier draws and 1,999 restricted wild cluster bootstrap-t draws. Simulations use 18 conditions, 4,000 panels each, 999 fresh Webb draws per panel and method-specific inference on shared panels. No simulation pass/fail selection.

The weighted stacked regression has exactly the original estimator's cell weights. Repeated baseline and donor observations are clustered by original crop, not by stack. This numerical identity is not a proof of valid inference: seven treated clusters, cross-crop dependence and heterogeneous effects remain relevant.

## Outputs

- `outputs/main_inference.csv`: three inference procedures for both donor variants and all outcomes. WCR p-values and cluster-t intervals are explicitly distinct.
- `outputs/date_sensitivity.csv`: 60 rows, five date definitions and two horizons. National +1 loses one treated crop at event 9; common support 0–8 also reported.
- `outputs/trend_scenarios.csv`: point scenarios only; no claimed robust confidence intervals.
- `outputs/descriptive_stats.csv`: raw/log mean, sample SD, range, N and crop count; full contributing-cell membership supplied.
- `outputs/balanced_pretrends.csv`, `five_year_slopes.csv`, `crop_event_contrasts.csv`: all crops, donors, dates and weights.
- `outputs/simulation_calibration.csv`: all calibration conditions, rejection rates, Monte Carlo intervals and null inclusion.
- `outputs/simulation_parameters.csv`: fitted residual SD, raw and clipped AR(1), group labels.
- `outputs/numerical_checks.csv` and `simulation_checks.csv`: executed numerical checks.
- `figures/`: seven publication-style PDF and PNG figures, generated with Python. They are not Stata output.

## Stata (not executed)

From repository root in Stata 17+:

```stata
do reanalysis_20260930/stata/00_master.do
```

This recomputes descriptive tables and redraws all figure families from stored CSVs, retaining stored intervals and actual event coordinates. It does not re-estimate the custom causal procedure. Outputs go to `stata/out/`. Compare descriptive tables with the Python outputs before publication. Stata is not installed in the execution environment; its scripts have been statically reviewed, not run.

## Open external questions

KOSIS general-spring/winter definitions and historical insurance selling/first-covered-harvest dates remain unresolved. No combined spring/winter series is adopted. No assertion about farmer income stability follows from these production/area/yield contrasts. Formal HonestDiD sensitivity is not executed; its general support for staggered adoption does not remove the need to justify the mapping of this custom design.
