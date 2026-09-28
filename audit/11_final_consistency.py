# -*- coding: utf-8 -*-
"""11_final_consistency.py -- final consistency checks across thesis-facing files.

Thesis-facing = README_VERIFIED.md, docs/*, verified_results/* (claim_audit.csv and
verified_benchmark_record.csv are audit records that quote original wording and are
checked only for the items that must hold there), figure labels.
Change-log sections that quote superseded original wording are excluded from the
wording checks. No data are modified. Exit code 1 if any check fails.
Run from the repository root:  python3 audit/11_final_consistency.py
"""
import csv, glob, re, sys

fails, notes = [], []
def check(ok, msg):
    (notes if ok else fails).append(("PASS " if ok else "FAIL ") + msg)

def read(p): return open(p, encoding="utf-8-sig").read()
def strip_changelog(t):
    i = t.find("## Change log")
    return t if i < 0 else t[:i]

facing = {p: read(p) for p in ["README_VERIFIED.md", "docs/PROVENANCE.md", "docs/SOURCE_MANIFEST_FINAL.csv",
                               "R/style_reference.md"] + glob.glob("figures/plotdata/*_labels.txt")}
facing["docs/METHODOLOGICAL_MEMO_v3.md"] = strip_changelog(read("docs/METHODOLOGICAL_MEMO_v3.md"))
for p in glob.glob("verified_results/*.csv"):
    if not p.endswith(("claim_audit.csv", "verified_benchmark_record.csv")):
        facing[p] = read(p)

BANNED = ["Asian pear", "Japanese apricot", "Chinese cabbage", "Daikon", "Satsuma", "Yuzu", "Citron", "maize"]
for p, t in facing.items():
    hits = [b for b in BANNED if re.search(r"\b" + re.escape(b) + r"\b", t, re.I)]
    check(not hits, f"banned crop names absent: {p}" + (f" -> {hits}" if hits else ""))
    for pat, lab in [(r"p\s*=\s*0\.000\b", "no 'p = 0.000'"), (r"\+38\s*%", "no '+38%'"),
                     (r"cancels? exactly", "no 'cancels exactly'"), (r"\[(Appendix )?Figure [0-9A]+\]", "no bracketed figure number")]:
        if p.startswith("figures/") or p.endswith((".md",)):
            m = re.search(pat, t)
            check(m is None, f"{lab}: {p}" + (f" -> '{m.group(0)}'" if m else ""))
    if p.endswith(".csv"):
        check(not re.search(r"(^|,)\"?0\.000\"?(,|$)", t, re.M) or "p_display" not in t.split("\n")[0],
              f"no displayed p of 0.000: {p}")

# p display columns
S = list(csv.DictReader(open("verified_results/verified_results_summary.csv", encoding="utf-8")))
D = list(csv.DictReader(open("verified_results/verified_results_dynamic.csv", encoding="utf-8")))
check(all(r["p_display"] != "0.000" for r in S + D), "p_display never '0.000' (summary + dynamic)")
check(all((r["p_display"] == "p < 0.001") == (r["p_wild_py"] != "" and float(r["p_wild_py"]) < 0.001)
          for r in S if r["p_wild_py"] != ""), "p_display 'p < 0.001' exactly where p < 0.001 (numeric values unchanged)")

# DT_1J50 hash identical wherever stated
H = "d0d3ceca9cb412a2442a1c77f057bb55b5306bcfe02e7668c89879efa037ca01"
man = list(csv.DictReader(open("docs/SOURCE_MANIFEST_FINAL.csv", encoding="utf-8-sig")))
dt = [r for r in man if r["kosis_table_id"] == "DT_1J50"]
check(len(dt) == 1 and dt[0]["sha256"] == H and dt[0]["physical_filename"] == "농가판매가격지수_2005100__분기__20260927183931.xlsx",
      "DT_1J50 row in final manifest (file name + hash)")
check(H in read("docs/PROVENANCE.md"), "DT_1J50 hash in PROVENANCE.md")
veg = {r["physical_filename"]: r["kosis_table_id"] for r in man}
check(veg.get("08_vegetables_spices.xls") == "DT_1ET0029" and veg.get("10_vegetables_root.xls") == "DT_1ET0291",
      "vegetable files identified by table ID (08_vegetables_spices.xls = DT_1ET0029; 10_vegetables_root.xls = DT_1ET0291)")

# thesis-facing crop names in the frozen panel are all approved
APPROVED = set("""Apple;Pear;Sweet persimmon;Astringent persimmon;Tangerine;Peach;Grape;Plum;Green plum;Kiwifruit;Yuja;Apricot;
Blueberry;Fig;Jujube;Chestnut;Korean black raspberry;Omija;Mulberry;Rice;Soybean;Red bean;Mung bean;Corn;Sweet potato;
Spring potato;Highland potato;Autumn potato;Barley;Wheat;Buckwheat;Oats;Onion;Red pepper;Garlic;Cabbage;Broccoli;Napa cabbage;
Radish;Carrot;Large green onion;Small green onion;Spinach;Leaf lettuce;Sweet pumpkin;Watermelon;Sesame;Perilla;Peanut;Tea;
Ginseng;Dureup;Other pulses;Malting barley;Ginger;Walnut;Spring Napa cabbage;Highland Napa cabbage;Autumn Napa cabbage;
Winter Napa cabbage;Spring Radish;Highland Radish;Autumn Radish;Winter Radish;Lettuce""".replace("\n", "").split(";"))
P = list(csv.DictReader(open("verified_results/verified_master_panel.csv", encoding="utf-8-sig")))
names = {r["crop_en_display"] for r in P}
check(names <= APPROVED, f"master-panel crop names all approved ({len(names)} names)" + (f" -> unapproved {sorted(names - APPROVED)}" if names - APPROVED else ""))
lt = {r["crop_ko_official"] for r in P if r["crop_en_display"] == "Leaf lettuce"}
check(lt == {"상추"}, "Leaf lettuce = 상추")
for p, key in [("verified_results/verified_apfs_fruit_2024_by_crop.csv", "crop"), ("verified_results/verified_control_composition.csv", "control"),
               ("verified_results/verified_treatment_coding.csv", "crop"), ("verified_results/verified_identity_discrepancies.csv", "crop")]:
    nm = {r[key] for r in csv.DictReader(open(p, encoding="utf-8-sig"))}
    check(nm <= APPROVED, f"names approved in {p}" + (f" -> {sorted(nm - APPROVED)}" if nm - APPROVED else ""))

# master panel values unchanged: only display/label columns differ from the bundle extraction
A = list(csv.reader(open("audit/extracted/data/MASTER_PANEL.csv", encoding="utf-8")))
B = list(csv.reader(open("verified_results/verified_master_panel.csv", encoding="utf-8-sig")))
labels = {"crop_en_display", "crop_ko_official", "kosis_production_label_original", "kosis_price_label_original",
          "apfs_label_original", "insurance_product_variant"}
diff = [(A[0][j]) for i in range(1, len(A)) for j in range(len(A[0])) if A[i][j] != B[i][j] and A[0][j] not in labels]
check(len(A) == len(B) and not diff, f"master panel: all non-label cells byte-identical to the bundle ({len(A) - 1} rows)")

# QC and claim audit
Q = list(csv.DictReader(open("verified_results/figure_qc.csv", encoding="utf-8")))
check(len(Q) == 11 and all(r["status"].startswith("PASS") for r in Q), "figure QC: 11/11 PASS")
C = list(csv.DictReader(open("verified_results/claim_audit.csv", encoding="utf-8-sig")))
n = len(C)
check(f"{n} claims" in read("README_VERIFIED.md"), f"README states the claim count ({n})")
check(any(r["claim_id"] == "C140" and H[:8] in r["claim_text"] for r in C), "claim audit records the DT_1J50 source (C140)")

print("\n".join(notes + fails))
print(f"\n{len(notes)} passed, {len(fails)} failed")
sys.exit(1 if fails else 0)
