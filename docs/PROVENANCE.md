# Provenance and reproducibility record (approved correction 10, 2026-09-28)

This record reconciles the file names read by the analysis scripts (`input/CODE_BUNDLE.md`) with
the source manifests (`input/DOCUMENTATION.md` and DATA_BUNDLE `FILE_MANIFEST`). **No numerical
data were changed.** Items that cannot be resolved from the uploaded bundles are marked
**AUTHOR ACTION** and remain external-source items (verification level C).

## 1. Production sources (KOSIS Crop Production Survey)

The panel script selects series by **KOSIS table ID and item label** (`01_build_panel.py`,
`series(tid, label, ...)`), not by file name. Values are therefore unaffected by the naming
differences below, provided each file contains the table stated in its metadata.

| File name read by `01_build_panel.py` | File name in manifests | Size (bytes) | SHA-256 (manifest) | KOSIS table (metadata snapshot) | Status |
|---|---|---:|---|---|---|
| `01_fruit_total.xls` | same | 1,937,040 | `99be575280a5b1a55a2bfe48e7ea6861d1ddd381424c9531c54671ba6f4ab38a` | DT_1ET0292 과실생산량(성과수+미과수) | consistent |
| `02_fruit_bearing.xlsx` | same | 57,199 | `52b152deefc54629a85dd6b00f9be8bedf63e35391a92e570d4eb9b4a46ceb24` | DT_1ET0296 과실생산량(성과수) | consistent |
| `03_rice.xlsx` | same | 65,671 | `dd6ace60ab37f300c149fceaaa7996311acbe561285c960ff694b1895c0f8c02` | DT_1ET0222 미곡생산량(조곡) | consistent |
| `04_beans.xlsx` | same | 6,402 | `b529456153b285614b90bbd1c692a9868938477af99f2f4f5a081a9a513791eb` | DT_1ET0025 두류생산량 | consistent |
| `05_coarse_grains.xlsx` | same | 42,884 | `4ea31c77065cbba1db24d6a0c99ec08030fbbdb23cde2a8857b4a432dd2bdd19` | DT_1ET0024 잡곡생산량 | consistent |
| `06_potatoes.xlsx` | same | 68,351 | `4b8bdce346243349fbf093c46ada167a04ca59f137b118c7c6acba65e8c8e9f0` | DT_1ET0026 서류생산량(생서) | consistent |
| `07_barely.xlsx` (typo in code and metadata key) | `07_barley.xlsx` | 27,448 | `6f09b9daca14821c6832594391b45f570eeef1114124ed1c154ff2ae2560f83d` | DT_1ET0231 맥류생산량(정곡) | name differs by a typo only |
| `08_vegetables_root.xls` | `08_vegetables_spices.xls` | 2,068,118 | `fb300963a1538b36500dab6ecc44cf00d3b232a46b3ae893dbb8508e0e6167b5` | code/metadata: DT_1ET0029 채소생산량(근채류) | **names swapped** |
| `09_vegetables_leafy.xls` | same | 2,680,150 | `89c30b64b35c2b94d26ba39c14a1dff47367dfa2511eed7d4c77136de85d228f` | DT_1ET0028 채소생산량(엽채류) | consistent |
| `10_vegetables_spices.xls` | `10_vegetables_root.xls` | 2,940,629 | `a869a6078826688217c651d52a1d6eb0e7a6afa4865eeaeaccd3a1478f898013` | code/metadata: DT_1ET0291 채소생산량(조미채소) | **names swapped** |
| `13_특용작물생산량__땅콩_.xlsx` | `특용작물생산량_20260927184000.xlsx` | 53,107 | `85f2263b31bb659f18d1fc6689534871ac42164e61d1d454e3d0b855decc3b09` | DT_1ET0293 특용작물생산량 | renamed; download time in metadata (2026.09.27 18:40) matches the manifest time stamp |

Hashes copied programmatically from `audit/extracted/data/FILE_MANIFEST.csv` (identical to `input/DOCUMENTATION.md`).

**AUTHOR ACTION (08/10).** The code and the KOSIS metadata snapshot call the root-vegetable file
`08_…` and the seasoning-vegetable file `10_…`; the manifest reverses the two names. Because the
script selects by table ID, the panel is correct as long as each file holds the table its own
metadata sheet names. Open each original file, read `통계표ID` on its metadata sheet, and record the
file-name ↔ table-ID ↔ SHA-256 triple here.

## 2. Price sources

| Role | File name read by `02_build_prices.py` | File name in manifests | SHA-256 | Status |
|---|---|---|---|---|
| Crop farm-gate price index, 2005=100, quarterly (DT_1J49) | `농가판매가격지수_2005100__분기__품목별__20260927193919.xlsx` | `농가판매가격지수_2005100__분기__품목별__20260927193919(2).xlsx` | `a84c053262776405a4f9dab096e52598242bcb00fb32cf6f30af7df6fd54e9e3` | same download time stamp; "(2)" is a download-copy suffix |
| Crop items **and** all-farm-output total index (총지수), 2020=100, quarterly (DT_1J60) | `11_farm_output_price_index_2026.xlsx` | `11_farm_output_price_index.xlsx` | `3b4b6d2a4bc083465b80bc05e63399a49a175ad21cdb8ddefc8b253cb1a4aa25` | renamed; one file supplies both the crop items and the 2020=100 total index |
| **All-farm-output total index (총지수), 2005=100, quarterly (DT_1J50)** — older segment of the relative-price divisor | `12_farm_output_price_index_2005.xlsx` | **absent from both manifests** | **not recorded** | **AUTHOR ACTION** |

**The DT_1J50 / all-farm-output source (the divisor of the relative farm-gate price index).**
- `02_build_prices.py` reads the item `총지수` (all-farm-output total index) from DT_1J50 (2005=100) and from DT_1J60 (2020=100).
- It links the two over 2005Q1–2012Q4: k = mean(DT_1J60 / DT_1J50) = 0.7079 over 32 overlapping quarters. The ratio CV is 1.36%; the correlation of quarterly log changes is 0.912; the maximum discrepancy is 4.9% (`PRICE_DEFL_LINK`).
- Linked divisor: the DT_1J60 value from 2005Q1 onward; before that, DT_1J50 × 0.7079.
- The quarterly divisor file (`price_deflator_quarterly.csv`) is listed in FILE_MANIFEST as not embedded, and the DT_1J50 source file is listed nowhere.
- Every price estimate uses this divisor, but for the main estimate it is numerically immaterial: the relative-price and nominal-index estimates are almost identical (`verified_results/verified_price_results.csv`).
- **AUTHOR ACTION:** add `12_farm_output_price_index_2005.xlsx` with its KOSIS table ID, download date, size and SHA-256 to the source manifest.

## 3. APFS sources

| File | Embedded? | Used for |
|---|---|---|
| `농업정책보험금융원_농작물재해보험 연도별 가입 현황_20241231.csv` | yes (APFS_ENROLL_RAW) | national enrollment, financing (Figures 9, 10) |
| `농업정책보험금융원_농작물재해보험 연도별 지급현황_20231231.csv` | yes (APFS_PAY_RAW) | indemnities, loss ratio = indemnities / risk premium × 100 (Figure 9) |
| `농업정책보험금융원_농작물재해보험 품목별 가입 및 지급현황_20231231.csv` | yes (APFS_CROPJOIN23) | 2023 crop cross-section |
| `농업정책보험금융원_농작물재해보험 계약된 과수작물 세부현황_20241231.csv` (28,280,881 bytes) | **no** | 2024 fruit summaries (Figures 7, 8, A1): consistent with the supplied summary, not recomputed from raw records |
| province 2023/2024 source file | not listed | `apfs_province_2023_2024.csv` (derived table only) |

## 4. Intermediate files not produced by any bundled script

| File | Status |
|---|---|
| `treatment_coding_input.csv` | Hand-coded input (dates from Yearbook 2025, guideline 2026, press release 2025.6.15). `01_build_panel.py` reads it from the **output** folder. Treat it as a primary input and keep it with the raw files. |
| `apfs_crop_level_2023.csv`, `apfs_province_2023_2024.csv` | Produced outside the bundled scripts. The crop file is identical to the embedded public CSV; the province file adds up to its national totals. |
| `event_time_support.csv`, `cohort_year_support.csv`, `control_composition.csv` | **Stale** (earlier pipeline). Quarantined in `audit/extracted/*/stale_do_not_use/`; not used in any thesis-facing material. Replaced by `verified_results/verified_event_time_support.csv` and `verified_control_composition.csv`, rebuilt from the current design. These match RESULTS T12 (110 rows) and T13 (72 rows) exactly. |

## 5. Reproducibility statement

- The **frozen verified results** are reproducible from the uploaded bundles with `Rscript run_all.R`.
- The **Python pipeline** (`run_all.sh`) cannot be re-run from the bundles, because the raw KOSIS, price and APFS contract files are not embedded. Its outputs were verified by independent R re-estimation from the embedded analysis-ready data, not by re-running the Python code.
- Full reproducibility from raw sources also requires the AUTHOR ACTION items above.
