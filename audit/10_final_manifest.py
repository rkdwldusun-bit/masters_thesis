# -*- coding: utf-8 -*-
"""10_final_manifest.py -- build and validate docs/SOURCE_MANIFEST_FINAL.csv

Sources of each row:
  * DATA_BUNDLE FILE_MANIFEST (size + SHA-256 recorded at bundling time)
  * input/DOCUMENTATION.md source-manifest table (PDFs; hashes identical to FILE_MANIFEST
    for the 13 overlapping data files -- checked below)
  * AUTHOR-SUPPLIED (2026-09-28): the DT_1J50 source file and the true table IDs of the two
    physically mis-named vegetable files
Analytical identification follows the internal KOSIS table ID, never the physical file name.
No numerical data are read or changed here.
Run from the repository root:  python3 audit/10_final_manifest.py
"""
import csv, re

man = {r["file"]: r for r in csv.DictReader(open("audit/extracted/data/FILE_MANIFEST.csv", encoding="utf-8"))}
doc = open("input/DOCUMENTATION.md", encoding="utf-8").read()
docman = {m.group(1): (int(m.group(2)), m.group(3))
          for m in re.finditer(r"\| `([^`]+)` \| (\d+) \| `([0-9a-f]{64})` \|", doc)}
code = open("input/CODE_BUNDLE.md", encoding="utf-8").read()

# physical file -> (KOSIS table, table name, role, name used by the Python code, semantic copy name, id source)
KOSIS = {
 "01_fruit_total.xls": ("DT_1ET0292", "과실생산량(성과수+미과수)", "production: fruit", "01_fruit_total.xls", "01_fruit_total.xls", "metadata snapshot"),
 "02_fruit_bearing.xlsx": ("DT_1ET0296", "과실생산량(성과수)", "production: fruit bearing area", "02_fruit_bearing.xlsx", "02_fruit_bearing.xlsx", "metadata snapshot"),
 "03_rice.xlsx": ("DT_1ET0222", "미곡생산량(조곡)", "production: rice", "03_rice.xlsx", "03_rice.xlsx", "metadata snapshot"),
 "04_beans.xlsx": ("DT_1ET0025", "두류생산량", "production: pulses", "04_beans.xlsx", "04_beans.xlsx", "metadata snapshot"),
 "05_coarse_grains.xlsx": ("DT_1ET0024", "잡곡생산량", "production: coarse grains", "05_coarse_grains.xlsx", "05_coarse_grains.xlsx", "metadata snapshot"),
 "06_potatoes.xlsx": ("DT_1ET0026", "서류생산량(생서)", "production: potatoes", "06_potatoes.xlsx", "06_potatoes.xlsx", "metadata snapshot"),
 "07_barley.xlsx": ("DT_1ET0231", "맥류생산량(정곡)", "production: barley/wheat", "07_barely.xlsx", "07_barley.xlsx", "metadata snapshot"),
 "08_vegetables_spices.xls": ("DT_1ET0029", "채소생산량(근채류)", "production: root vegetables", "08_vegetables_root.xls", "08_vegetables_root.xls",
                              "AUTHOR-SUPPLIED 2026-09-28 (physical name swapped relative to contents)"),
 "09_vegetables_leafy.xls": ("DT_1ET0028", "채소생산량(엽채류)", "production: leafy vegetables", "09_vegetables_leafy.xls", "09_vegetables_leafy.xls", "metadata snapshot"),
 "10_vegetables_root.xls": ("DT_1ET0291", "채소생산량(조미채소)", "production: seasoning vegetables", "10_vegetables_spices.xls", "10_vegetables_spices.xls",
                            "AUTHOR-SUPPLIED 2026-09-28 (physical name swapped relative to contents)"),
 "특용작물생산량_20260927184000.xlsx": ("DT_1ET0293", "특용작물생산량", "production: special crops (peanut, sesame, perilla)",
                                    "13_특용작물생산량__땅콩_.xlsx", "13_special_crops_DT_1ET0293.xlsx", "metadata snapshot (download time 2026.09.27 18:40 matches file stamp)"),
 "농가판매가격지수_2005100__분기__품목별__20260927193919(2).xlsx": ("DT_1J49", "농가판매가격지수(2005=100, 분기, 품목별)", "price: crop items 2005=100",
                                    "농가판매가격지수_2005100__분기__품목별__20260927193919.xlsx", "price_crop_items_2005100_DT_1J49.xlsx", "02_build_prices.py (table label in code)"),
 "11_farm_output_price_index.xlsx": ("DT_1J60", "농가판매가격지수(2020=100, 분기): crop items and 총지수", "price: crop items and all-farm-output total index 2020=100",
                                    "11_farm_output_price_index_2026.xlsx", "price_items_and_total_2020100_DT_1J60.xlsx", "02_build_prices.py (table label in code)"),
}
DT_1J50 = dict(file="농가판매가격지수_2005100__분기__20260927183931.xlsx", size_bytes="",
               sha256="d0d3ceca9cb412a2442a1c77f057bb55b5306bcfe02e7668c89879efa037ca01", embedded_in_DATA_BUNDLE="False")

rows = []
for f, r in man.items():
    k = KOSIS.get(f)
    rows.append(dict(physical_filename=f, semantic_copy_name=k[4] if k else f, name_read_by_python_code=k[3] if k else "",
                     kosis_table_id=k[0] if k else "", table_name=k[1] if k else "", role=k[2] if k else "derived / APFS table",
                     size_bytes=r["size_bytes"], sha256=r["sha256"], hash_source="DATA_BUNDLE FILE_MANIFEST",
                     embedded_in_DATA_BUNDLE=r["embedded_in_DATA_BUNDLE"], table_id_source=k[5] if k else ""))
rows.append(dict(physical_filename=DT_1J50["file"], semantic_copy_name="price_total_index_2005100_DT_1J50.xlsx",
                 name_read_by_python_code="12_farm_output_price_index_2005.xlsx", kosis_table_id="DT_1J50",
                 table_name="농가판매가격지수(2005=100, 분기)", role="price: all-farm-output total index (총지수) 2005=100 -- older segment of the relative-price divisor",
                 size_bytes="not supplied", sha256=DT_1J50["sha256"], hash_source="AUTHOR-SUPPLIED 2026-09-28 (file not uploaded; hash not recomputable here)",
                 embedded_in_DATA_BUNDLE="False", table_id_source="AUTHOR-SUPPLIED 2026-09-28"))
for f, (size, h) in docman.items():
    if f not in man:
        rows.append(dict(physical_filename=f, semantic_copy_name=f, name_read_by_python_code="", kosis_table_id="", table_name="",
                         role="document (PDF)", size_bytes=str(size), sha256=h, hash_source="DOCUMENTATION.md source manifest",
                         embedded_in_DATA_BUNDLE="False", table_id_source=""))

# ---------------- validation
errs = []
for r in rows:
    if not re.fullmatch(r"[0-9a-f]{64}", r["sha256"]): errs.append(("bad hash", r["physical_filename"]))
hs = [r["sha256"] for r in rows]
if len(hs) != len(set(hs)): errs.append(("duplicate hash", ""))
for f, (size, h) in docman.items():               # DOCUMENTATION and FILE_MANIFEST agree
    if f in man and (man[f]["sha256"] != h or int(man[f]["size_bytes"]) != size): errs.append(("doc/manifest mismatch", f))
read = set(re.findall(r"'([^'\n]+\.(?:xlsx?|csv))'", code))   # every raw file named in the Python code
read = {x for x in read if not x.startswith(("price_", "results_", "panel_", "apfs_", "dropped_", "crop_", "ch5_", "appendix_",
                                              "treatment_", "fig", "kosis_"))}
read = {x.lstrip("; ").strip() for x in read}                 # drop label fragments such as '; 02_fruit_bearing.xlsx'
mapped = {r["name_read_by_python_code"] for r in rows} | {r["physical_filename"] for r in rows}
norm = lambda x: x.replace(" ", "_")
# 05_apfs_descriptives.py builds APFS names as prefix + suffix ('농업정책보험금융원_농작물재해보험_' + '연도별_...')
unmapped = sorted(x for x in read if norm(x) not in {norm(m) for m in mapped}
                  and not any(norm(m).endswith(norm(x)) for m in mapped))
ids = [r["kosis_table_id"] for r in rows if r["kosis_table_id"]]
if len(ids) != len(set(ids)): errs.append(("table id used twice", ""))

with open("docs/SOURCE_MANIFEST_FINAL.csv", "w", encoding="utf-8-sig", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print("rows:", len(rows), "| KOSIS tables:", len(ids), "| errors:", errs)
print("raw file names read by the Python code:", len(read), "| not mapped to a manifest row:", unmapped)
assert not errs and not unmapped

# ---------------- fill the KOSIS table in docs/PROVENANCE.md from the manifest and validate the document
prov = open("docs/PROVENANCE.md", encoding="utf-8").read()
t = ["| KOSIS table | Table name | Physical file (as uploaded) | Name read by the Python code | Semantic copy name | Size (bytes) | SHA-256 | Hash source |",
     "|---|---|---|---|---|---:|---|---|"]
for r in sorted((r for r in rows if r["kosis_table_id"]), key=lambda r: r["kosis_table_id"]):
    size = f'{int(r["size_bytes"]):,}' if r["size_bytes"].isdigit() else r["size_bytes"]
    t.append(f'| {r["kosis_table_id"]} | {r["table_name"]} | `{r["physical_filename"]}` | `{r["name_read_by_python_code"]}` | '
             f'`{r["semantic_copy_name"]}` | {size} | `{r["sha256"]}` | {r["hash_source"]} |')
start, end = "<!-- KOSIS_TABLE_START -->", "<!-- KOSIS_TABLE_END -->"
prov = prov[:prov.index(start) + len(start)] + "\n" + "\n".join(t) + "\n" + prov[prov.index(end):]
open("docs/PROVENANCE.md", "w", encoding="utf-8").write(prov)
allhash = {r["sha256"] for r in rows}
bad = [h for h in re.findall(r"`([0-9a-f]{64})`", prov) if h not in allhash]
assert not bad, bad
print("PROVENANCE.md: KOSIS table written;", len(re.findall(r"`([0-9a-f]{64})`", prov)), "hashes, all in the final manifest")
