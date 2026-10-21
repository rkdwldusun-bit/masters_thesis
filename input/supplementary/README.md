# Supplementary inputs (typed from published sources)

`mafra_2026-02-02_crop_insurance_2024_2025.csv` transcribes the attachment table
"2025년 농작물보험 주요 운영실적 / □ 농작물재해보험" of the MAFRA press release of
2 February 2026 ("2026년 농작물보험, 이렇게 바뀝니다!"). Only the crop disaster insurance
rows are used; the agricultural revenue insurance rows and the combined 57.7 percent
quoted in the release text (crop disaster + revenue insurance) are not.

Amounts are in KRW 100 million (억원). The loss ratio is the release's own figure.

The 2024 row is a bridge to the APFS public series in `verified_results/verified_apfs_national.csv`:
enrolled farms (589,676), insured area (676,226 ha) and the enrollment rate (54.2) are identical,
and the release's 2024 loss ratio (97.9) equals indemnities (10,208) divided by the APFS 2024
risk premium (1,042,753 million KRW), i.e. the same definition as the APFS series.
`R/09_figure9.R` checks the bridge before using the release values.

Used for Figure 9 (thesis Figure 2): 2025 enrollment rate; 2024 and 2025 loss ratios
(the APFS payment file ends in 2023).
