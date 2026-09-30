# -*- coding: utf-8 -*-
"""Reconcile spring/winter napa cabbage and radish series around 2014 (NO estimation).

Reads the ORIGINAL KOSIS exports (SpreadsheetML 2003 XML, EUC-KR, despite the .xls extension)
and the verified panel, and writes:
  outputs/kosis_2014_rows_long.csv          every national value with file, SHA-256, sheet, XML row/column
  outputs/panel_vs_kosis_2014.csv           panel value vs. the exact KOSIS cell it comes from
  outputs/harmonized_spring_winter_series.csv  'general spring + winter' series (definition equivalence UNVERIFIED)
Set RAW_DIR to the folder holding 08_vegetables_root.xls and 09_vegetables_leafy.xls.
"""
import hashlib
import os
import sys

import pandas as pd

sys.path.insert(0, os.path.dirname(__file__))
from xml2003 import read  # noqa: E402

RAW_DIR = os.environ.get('RAW_DIR', '/mnt/user-data/uploads/')
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, 'audit_claude_20260930', 'outputs')
FILES = {'08_vegetables_root.xls': ('DT_1ET0029', '채소생산량(근채류)'),
         '09_vegetables_leafy.xls': ('DT_1ET0028', '채소생산량(엽채류)')}
ITEMS = ['노지봄무', '일반봄무', '고랭지무', '노지가을무', '노지겨울무', '노지무',
         '노지봄배추', '일반봄배추', '고랭지배추', '노지가을배추', '노지겨울배추', '노지배추']

recs = []
for f, (tid, tname) in FILES.items():
    path = os.path.join(RAW_DIR, f)
    sha = hashlib.sha256(open(path, 'rb').read()).hexdigest()
    d = read(path)
    rows = d['데이터']
    hdr = rows[1]
    yc = {int(str(h)[:4]): i for i, h in enumerate(hdr) if h and str(h)[:4].isdigit()}
    reg = None
    for ri, r in enumerate(rows[2:], start=2):
        if r[0]:
            reg = r[0].strip()
        if reg != '계':
            continue
        lab = str(r[1] or '')
        crop, _, var = lab.partition(':')
        if crop in ITEMS:
            for y in range(2005, 2025):
                recs.append(dict(file=f, sha256=sha, table_id=tid, table_name=tname, sheet='데이터',
                                 xml_row=ri + 1, xml_col=yc[y] + 1, region='계(전국)', item_label=lab,
                                 crop=crop, variable=var, unit=r[2], year=y, raw=r[yc[y]]))
R = pd.DataFrame(recs)
R['value'] = pd.to_numeric(R.raw, errors='coerce')
R.to_csv(os.path.join(OUT, 'kosis_2014_rows_long.csv'), index=False, encoding='utf-8-sig')

V = pd.read_csv(os.path.join(ROOT, 'verified_results', 'verified_master_panel.csv'))
comp = []
for pid, lab in [('spring_radish', '일반봄무'), ('spring_napa', '일반봄배추'), ('winter_radish', '노지겨울무'),
                 ('winter_napa', '노지겨울배추'), ('autumn_radish', '노지가을무'), ('autumn_napa', '노지가을배추')]:
    for y in (2012, 2013, 2014, 2015):
        a = R[(R.crop == lab) & (R.variable.str.startswith('면적')) & (R.year == y)]
        v = V[(V.crop_id == pid) & (V.year == y)].area_ha
        comp.append(dict(panel_crop_id=pid, kosis_item=lab, year=y,
                         kosis_area_raw=a.raw.iloc[0] if len(a) else None,
                         xml_row=int(a.xml_row.iloc[0]) if len(a) else None,
                         xml_col=int(a.xml_col.iloc[0]) if len(a) else None,
                         panel_area=float(v.iloc[0]) if len(v) and pd.notna(v.iloc[0]) else None))
pd.DataFrame(comp).to_csv(os.path.join(OUT, 'panel_vs_kosis_2014.csv'), index=False, encoding='utf-8-sig')

# ---- harmonized 'general spring + winter' series (definition equivalence UNVERIFIED) ----------------------
# Year rules (explicit):
#   year <  2014 : winter form is NOT published as a separate KOSIS series (radish: raw '0' in 2011-2013,
#                  blank before; napa: blank). A raw '0' or blank is treated as 'not separately published',
#                  NOT as 'no winter crop'. Harmonized value = general spring as published; flag records that
#                  it is unknown whether winter crops were included in general spring.
#   year >= 2014 : harmonized = general spring + winter, only if BOTH components are positive numbers;
#                  otherwise the harmonized value is left missing (never filled with 0).
#   Yield is recomputed as production / area * 100 (kg/10a); it is never averaged.
def raw_type(v):
    if v is None or (isinstance(v, float) and v != v) or str(v).strip() == '':
        return 'blank'
    t = str(v).strip()
    if t == '-':
        return 'dash'
    try:
        x = float(t.replace(',', ''))
    except ValueError:
        return 'text'
    return 'reported_zero' if x == 0 else ('positive' if x > 0 else 'negative')

def cell(crop, var_prefix, y):
    z = R[(R.crop == crop) & (R.variable.str.startswith(var_prefix)) & (R.year == y)]
    return (z.raw.iloc[0] if len(z) else None)

out = []
for base, wint, name in [('일반봄무', '노지겨울무', 'radish_general_spring_plus_winter'),
                         ('일반봄배추', '노지겨울배추', 'napa_general_spring_plus_winter')]:
    for y in range(2005, 2025):
        sa, sp = cell(base, '면적', y), cell(base, '생산량', y)
        wa, wp = cell(wint, '면적', y), cell(wint, '생산량', y)
        ta, tp = raw_type(wa), raw_type(wp)
        sa_n, sp_n = float(str(sa).replace(',', '')), float(str(sp).replace(',', ''))
        if y < 2014:
            area, prod = sa_n, sp_n
            rule = 'pre-2014: general spring as published; winter not published separately (raw type: ' + ta + ')'
            flag = 'UNKNOWN whether winter crops are included in general spring'
        elif ta == 'positive' and tp == 'positive':
            area = sa_n + float(str(wa).replace(',', ''))
            prod = sp_n + float(str(wp).replace(',', ''))
            rule = '2014+: general spring + winter (both components positive)'
            flag = 'sum; equivalence with pre-2014 definition UNVERIFIED'
        else:
            area = prod = float('nan')
            rule = '2014+: winter component not a positive number (' + ta + '/' + tp + '); left missing'
            flag = 'missing by rule'
        out.append(dict(series=name, year=y, spring_area_raw=sa, spring_prod_raw=sp, winter_area_raw=wa,
                        winter_prod_raw=wp, winter_area_raw_type=ta, winter_prod_raw_type=tp,
                        area_ha=area, production_t=prod,
                        yield_kg10a=(prod / area * 100) if area and area == area else float('nan'),
                        rule=rule, status=flag))
pd.DataFrame(out).to_csv(os.path.join(OUT, 'harmonized_spring_winter_series.csv'), index=False, encoding='utf-8-sig')
print('rows', len(R))
