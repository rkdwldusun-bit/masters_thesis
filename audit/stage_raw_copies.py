# -*- coding: utf-8 -*-
"""stage_raw_copies.py -- copy original source files into a reproducibility folder
under their semantically correct names, WITHOUT altering their contents.

Usage (from the repository root):
    python3 audit/stage_raw_copies.py <folder_with_original_files> <output_folder>

For every row of docs/SOURCE_MANIFEST_FINAL.csv whose physical file is present in
<folder_with_original_files>, the script
  1. computes the SHA-256 of the original and requires it to equal the manifest hash;
  2. copies the bytes unchanged to <output_folder>/<semantic_copy_name>;
  3. re-hashes the copy and requires it to be identical.
The originals are only read. Analytical identification follows the KOSIS table ID in
the manifest (e.g. the physical file '08_vegetables_spices.xls' holds DT_1ET0029, root
vegetables, and is copied as '08_vegetables_root.xls').
"""
import csv, hashlib, os, shutil, sys

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

src, dst = sys.argv[1], sys.argv[2]
os.makedirs(dst, exist_ok=True)
log = []
for r in csv.DictReader(open("docs/SOURCE_MANIFEST_FINAL.csv", encoding="utf-8-sig")):
    p = os.path.join(src, r["physical_filename"])
    if not os.path.exists(p):
        log.append((r["physical_filename"], "not present")); continue
    h = sha256(p)
    if h != r["sha256"]:
        log.append((r["physical_filename"], "HASH MISMATCH - not copied")); continue
    q = os.path.join(dst, r["semantic_copy_name"])
    shutil.copyfile(p, q)
    assert sha256(q) == h
    log.append((r["physical_filename"], "copied as " + r["semantic_copy_name"] + " (hash verified)"))
for f, s in log:
    print(f"{f}: {s}")
