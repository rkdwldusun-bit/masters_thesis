# Manuscript update: six-crop national analysis

Base: `261021_KANG_Jiyeon_Fact_Checked.docx` (fact-checked version, 21 Oct 2026).
`261021_KANG_Jiyeon_six_crops_tracked.docx` carries every text and table edit as a tracked change
(author "Claude"); `..._clean.docx` is the same file with the changes accepted. All numbers come from
`analysis/output/` (`analysis/01_national_confirmed_dates.R`); `tools/edit.py` applies them.

| Item | Change |
|---|---|
| Abstract, 1, 7 | Seven -> six crops; production contrast 0.020 [-0.277, 0.317] -> -0.002 [-0.318, 0.315] |
| 2.2, Table 1 | "seven annual crops" -> six; Panel B retitled, spring potato row deleted |
| 4.1, Table 2 | Treated rows recomputed (6 crops, 6 reference and 60 target obs); comparison target years 218 -> 232 obs |
| 4.2 | Spring potato excluded, with sources; expansion = first documented nationwide sales season |
| Table 3 | Six crops; expansion soybean 2012->2011, sweet potato and corn 2013->2012, red pepper 2015->2014; transition years recomputed; notes give conversion rule and sources |
| 4.3, eq. (5)-(6) | 1/7 and sums to 7 -> 6; pre-pilot comparisons exclude other treated crops |
| Footnote 1 | MDE: SE 0.159 -> 0.168, MDE 0.45 -> 0.47 |
| 5.1, Figure 6 | Image replaced (six crops); joint pre-pilot p: area 0.06 -> 0.08, yield 0.88 -> 0.92, production 0.03 -> 0.05 (0.0535) |
| 5.2, Table 4 | Panel A 0.011 / -0.012 / -0.002; Panel B -0.069 / -0.014 / -0.084 |
| Figure 7 | Image replaced (six crops, spring potato removed) |
| 5.3, Table 5 | Panels A-F recomputed; Panel G (yearbook main-program years) and Panel H (previous seven-crop specification) added; table now spans two pages |
| Table 6 | Recomputed with six-crop area weights (soybean 39.0 ... onion 6.9; equal 16.7) |
| 5.5, Table 9 | Six treated crops; std. differences 0.83 / -0.37 / 0.64 |
| Table A1 | Spring potato row deleted; five-crop leave-one-out values |
| References | MIFAFF 2011 -> 2011a; added MIFAFF 2011b, 2012, MAFRA 2014, Jeong & Choi 2013, Kim et al. 2021, Kook et al. 2024; MAFRA 2024 deleted (no longer cited) |
| Comments | Image-replacement notes (Figures 6, 7); reply on Table 3 reproducibility; romanization check for new KREI references |

Not changed: rice analysis (Tables 7-8, Figure 8) and all other chapters. Images cannot be tracked in Word.
LibreOffice drops Word equations when accepting changes, so the clean copy is built by `tools/accept_xml.py`.
