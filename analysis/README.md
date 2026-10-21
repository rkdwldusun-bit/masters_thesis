# National crop analysis with confirmed insurance dates

Run from the repository root (R >= 4.3 with data.table, ggplot2, MASS):

```
Rscript analysis/01_national_confirmed_dates.R   # all estimates -> analysis/output/*.csv (~2 min)
Rscript analysis/02_figures_confirmed_dates.R    # Figures 6-7 -> figures/confirmed_dates/
Rscript analysis/03_results_memo.R               # analysis/RESULTS_CONFIRMED_DATES.md
```

The thesis design is unchanged: last pre-pilot reference year, eligible comparison crops,
equal-weight mean over treated crops and ten target years (equations 4-6), score SEs and
Webb multiplier intervals with 9,999 draws (Appendix A). What changes is the dating:

- Main analysis: six crops. Expansion year = harvest year of the first nationwide sales season
  documented in MAFRA releases (`input/treatment_timing_sources.csv`): soybean 2011, onion 2012,
  sweet potato 2012, corn 2012, garlic 2013, red pepper 2014. Pilot years are unchanged.
- Spring potato is excluded from the main analysis: the 2008 potato pilot covered highland and
  autumn potato, and the first sales year of lowland spring potato is undocumented. Design S1
  keeps it with its previous coding; design S2 is the previous thesis coding.
- Figure 6 aligns time on the pilot and compares treated crops with comparison-pool crops only.
  The joint pre-pilot test is the sum of squared standardized contrasts for e = -10..-2 against
  its distribution across the multiplier draws (Appendix A). Under S2 it gives p = 0.05 (area),
  0.88 (yield) and 0.03 (production); the thesis reports 0.06, 0.88 and 0.03. The area value is
  within or just above the range over 20 draw sets (0.046-0.055).

`R/lib/national_tables.R` and `R/lib/pilot_pretest.R` hold the table and event-time helpers.
They reproduce the thesis Tables 2, 4, 6 and 9 exactly under S2 (point estimates, SEs, weights).
The rice analysis (Tables 7-8, Figure 8; 17 early and 9 later municipalities, 2000-2010) is not
part of this folder and is not re-estimated.
