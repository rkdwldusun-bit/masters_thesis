# Provenance and reproducibility record (final, 2026-09-28)

This record reconciles the physical source files, the names used by the analysis scripts
(`input/CODE_BUNDLE.md`) and the source manifests (`input/DOCUMENTATION.md`, DATA_BUNDLE
`FILE_MANIFEST`).

**No numerical data were changed.**

- **Machine-readable manifest:** `docs/SOURCE_MANIFEST_FINAL.csv`, built and validated by `audit/10_final_manifest.py`.
- **Tables below:** generated from that manifest; no hash is typed by hand.

## 1. Rule: identification by KOSIS table ID, not by physical file name

The panel script selects every series by **KOSIS table ID and item label**
(`01_build_panel.py`, `series(tid, label, ...)`), not by file name. The analytical identity of a
source is therefore its internal KOSIS table ID. Physical file names are provenance labels only.

### Resolved: two vegetable files were physically mis-named

The uploaded physical file names were swapped relative to their contents (author-supplied
confirmation, 2026-09-28):

| Physical file name (as uploaded) | Actual content | Semantically correct name (used by the code and the KOSIS metadata snapshot) |
|---|---|---|
| `08_vegetables_spices.xls` | **DT_1ET0029** 채소생산량(근채류), root vegetables | `08_vegetables_root.xls` |
| `10_vegetables_root.xls` | **DT_1ET0291** 채소생산량(조미채소), seasoning vegetables | `10_vegetables_spices.xls` |

This is a **provenance issue, not a numerical-data issue**:
- The code reads each table by its ID.
- The KOSIS metadata snapshot in DOCUMENTATION.md already records `08_…root → DT_1ET0029` and `10_…spices → DT_1ET0291`.
- Root-vegetable series (radish forms, carrot) come from DT_1ET0029, and seasoning-vegetable series (red pepper, onion, garlic, green onions, ginger) come from DT_1ET0291.

When original files are copied into the final reproducibility package, only the **copies** are renamed, to the semantically correct names in `SOURCE_MANIFEST_FINAL.csv`. `audit/stage_raw_copies.py` does this byte-for-byte and verifies the SHA-256 before and after copying. Raw source values are never altered.

## 2. Resolved: DT_1J50 (all-farm-output price index, 2005=100)

| Field | Value |
|---|---|
| Physical file | `농가판매가격지수_2005100__분기__20260927183931.xlsx` |
| KOSIS table | **DT_1J50** 농가판매가격지수(2005=100, 분기) |
| SHA-256 | `d0d3ceca9cb412a2442a1c77f057bb55b5306bcfe02e7668c89879efa037ca01` |
| Hash source | Author-supplied, 2026-09-28. The file is not in the uploaded bundles, so the hash cannot be recomputed here (verification level C until the file is staged with `audit/stage_raw_copies.py`) |
| Name used by `02_build_prices.py` | `12_farm_output_price_index_2005.xlsx` (variable `F50`) |
| Semantic copy name | `price_total_index_2005100_DT_1J50.xlsx` |
| Item used | 총지수 (all-farm-output total index), quarterly |
| Role | Older segment of the divisor of the **relative farm-gate price index** (crop index ÷ linked all-farm-output price index) |
| Linking | Linked to the DT_1J60 (2020=100) 총지수 over 2005Q1–2012Q4. k = mean(DT_1J60 / DT_1J50) = 0.7079 over 32 overlapping quarters; ratio CV 1.36%; correlation of quarterly log changes 0.912; maximum discrepancy 4.9% (`PRICE_DEFL_LINK`) |
| Linked divisor | The DT_1J60 value from 2005Q1 onward; DT_1J50 × 0.7079 before 2005 |

The quarterly linked divisor itself (`price_deflator_quarterly.csv`) is not embedded (FILE_MANIFEST).

Relative-price and nominal-index estimates are numerically almost identical: −0.1181 vs −0.1180 for the main price estimate. The small difference arises because annual relative prices are constructed from quarterly relative indices before annual aggregation.

## 3. All KOSIS source tables

<!-- KOSIS_TABLE_START -->
| KOSIS table | Table name | Physical file (as uploaded) | Name read by the Python code | Semantic copy name | Size (bytes) | SHA-256 | Hash source |
|---|---|---|---|---|---:|---|---|
| DT_1ET0024 | 잡곡생산량 | `05_coarse_grains.xlsx` | `05_coarse_grains.xlsx` | `05_coarse_grains.xlsx` | 42,884 | `4ea31c77065cbba1db24d6a0c99ec08030fbbdb23cde2a8857b4a432dd2bdd19` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0025 | 두류생산량 | `04_beans.xlsx` | `04_beans.xlsx` | `04_beans.xlsx` | 6,402 | `b529456153b285614b90bbd1c692a9868938477af99f2f4f5a081a9a513791eb` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0026 | 서류생산량(생서) | `06_potatoes.xlsx` | `06_potatoes.xlsx` | `06_potatoes.xlsx` | 68,351 | `4b8bdce346243349fbf093c46ada167a04ca59f137b118c7c6acba65e8c8e9f0` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0028 | 채소생산량(엽채류) | `09_vegetables_leafy.xls` | `09_vegetables_leafy.xls` | `09_vegetables_leafy.xls` | 2,680,150 | `89c30b64b35c2b94d26ba39c14a1dff47367dfa2511eed7d4c77136de85d228f` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0029 | 채소생산량(근채류) | `08_vegetables_spices.xls` | `08_vegetables_root.xls` | `08_vegetables_root.xls` | 2,068,118 | `fb300963a1538b36500dab6ecc44cf00d3b232a46b3ae893dbb8508e0e6167b5` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0222 | 미곡생산량(조곡) | `03_rice.xlsx` | `03_rice.xlsx` | `03_rice.xlsx` | 65,671 | `dd6ace60ab37f300c149fceaaa7996311acbe561285c960ff694b1895c0f8c02` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0231 | 맥류생산량(정곡) | `07_barley.xlsx` | `07_barely.xlsx` | `07_barley.xlsx` | 27,448 | `6f09b9daca14821c6832594391b45f570eeef1114124ed1c154ff2ae2560f83d` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0291 | 채소생산량(조미채소) | `10_vegetables_root.xls` | `10_vegetables_spices.xls` | `10_vegetables_spices.xls` | 2,940,629 | `a869a6078826688217c651d52a1d6eb0e7a6afa4865eeaeaccd3a1478f898013` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0292 | 과실생산량(성과수+미과수) | `01_fruit_total.xls` | `01_fruit_total.xls` | `01_fruit_total.xls` | 1,937,040 | `99be575280a5b1a55a2bfe48e7ea6861d1ddd381424c9531c54671ba6f4ab38a` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0293 | 특용작물생산량 | `특용작물생산량_20260927184000.xlsx` | `13_특용작물생산량__땅콩_.xlsx` | `13_special_crops_DT_1ET0293.xlsx` | 53,107 | `85f2263b31bb659f18d1fc6689534871ac42164e61d1d454e3d0b855decc3b09` | DATA_BUNDLE FILE_MANIFEST |
| DT_1ET0296 | 과실생산량(성과수) | `02_fruit_bearing.xlsx` | `02_fruit_bearing.xlsx` | `02_fruit_bearing.xlsx` | 57,199 | `52b152deefc54629a85dd6b00f9be8bedf63e35391a92e570d4eb9b4a46ceb24` | DATA_BUNDLE FILE_MANIFEST |
| DT_1J49 | 농가판매가격지수(2005=100, 분기, 품목별) | `농가판매가격지수_2005100__분기__품목별__20260927193919(2).xlsx` | `농가판매가격지수_2005100__분기__품목별__20260927193919.xlsx` | `price_crop_items_2005100_DT_1J49.xlsx` | 63,904 | `a84c053262776405a4f9dab096e52598242bcb00fb32cf6f30af7df6fd54e9e3` | DATA_BUNDLE FILE_MANIFEST |
| DT_1J50 | 농가판매가격지수(2005=100, 분기) | `농가판매가격지수_2005100__분기__20260927183931.xlsx` | `12_farm_output_price_index_2005.xlsx` | `price_total_index_2005100_DT_1J50.xlsx` | not supplied | `d0d3ceca9cb412a2442a1c77f057bb55b5306bcfe02e7668c89879efa037ca01` | AUTHOR-SUPPLIED 2026-09-28 (file not uploaded; hash not recomputable here) |
| DT_1J60 | 농가판매가격지수(2020=100, 분기): crop items and 총지수 | `11_farm_output_price_index.xlsx` | `11_farm_output_price_index_2026.xlsx` | `price_items_and_total_2020100_DT_1J60.xlsx` | 45,874 | `3b4b6d2a4bc083465b80bc05e63399a49a175ad21cdb8ddefc8b253cb1a4aa25` | DATA_BUNDLE FILE_MANIFEST |
<!-- KOSIS_TABLE_END -->

## 4. APFS sources

| File | Embedded? | Used for |
|---|---|---|
| `농업정책보험금융원_농작물재해보험 연도별 가입 현황_20241231.csv` | yes (APFS_ENROLL_RAW) | national enrollment, financing (Figures 9, 10) |
| `농업정책보험금융원_농작물재해보험 연도별 지급현황_20231231.csv` | yes (APFS_PAY_RAW) | indemnities; loss ratio = indemnities / risk premium × 100 (Figure 9) |
| `농업정책보험금융원_농작물재해보험 품목별 가입 및 지급현황_20231231.csv` | yes (APFS_CROPJOIN23) | 2023 crop cross-section |
| `농업정책보험금융원_농작물재해보험 계약된 과수작물 세부현황_20241231.csv` | **no** | 2024 fruit summaries (Figures 7, 8, A1): consistent with the supplied summary, not recomputed from raw records |
| province 2023/2024 source file | not listed | `apfs_province_2023_2024.csv` (derived table only) |

## 5. Intermediate files not produced by any bundled script

| File | Status |
|---|---|
| `treatment_coding_input.csv` | Hand-coded input (dates from Yearbook 2025, guideline 2026, press release 2025.6.15). `01_build_panel.py` reads it from the **output** folder. Treat it as a primary input and keep it with the raw files. |
| `apfs_crop_level_2023.csv`, `apfs_province_2023_2024.csv` | Produced outside the bundled scripts. The crop file is identical to the embedded public CSV; the province file adds up to its national totals. |
| `event_time_support.csv`, `cohort_year_support.csv`, `control_composition.csv` | **Stale** (earlier pipeline). Quarantined in `audit/extracted/*/stale_do_not_use/`; not used in any thesis-facing material. Replaced by `verified_results/verified_event_time_support.csv` and `verified_control_composition.csv`, which are identical to RESULTS T12 and T13. |

## 6. Reproducibility statement

- The **frozen verified results** are reproducible from the uploaded bundles with `Rscript run_all.R`.
- The **Python pipeline** (`run_all.sh`) cannot be re-run from the bundles, because the raw KOSIS, price and APFS contract files are not embedded. Its outputs were verified by independent R re-estimation from the embedded analysis-ready data.
- For a raw-source package, stage the originals with `python3 audit/stage_raw_copies.py <originals> <package>/raw`. This verifies every SHA-256 in `SOURCE_MANIFEST_FINAL.csv` and writes semantically named, byte-identical copies.
