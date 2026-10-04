"""Build the v2 municipal panel (2000-2011) from the two KOSIS SpreadsheetML files.

Rules: protocol_v2.md section 1-2. Run from rice_followup_v2/:  python python/build_panel.py
Outputs go to data/: panel_v2.csv (all units, all cohorts), name_matching_audit.csv,
merge_audit.csv, rice_exceeds_paddy.csv, coverage_v2.csv.
"""
from pathlib import Path
import re, html, json, hashlib
import xml.etree.ElementTree as ET
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
INP, OUT = ROOT / 'input', ROOT / 'data'
OUT.mkdir(exist_ok=True)
RICE, LAND = INP / 'rice_area_DT_1ET0033.xls', INP / 'farmland_DT_1EB002.xls'
YEARS = range(2000, 2012)


def read_rows(path):
    s = re.sub(r'<\?xml[^>]+\?>', '', path.read_bytes().decode('euc-kr').lstrip())
    # Only mis-escaped XML text is repaired in memory; numbers and the file are untouched.
    s = re.sub(r'(<Data\b[^>]*>)(.*?)(</Data>)',
               lambda m: m[1] + html.escape(html.unescape(m[2]), quote=False) + m[3], s, flags=re.S)
    ns = {'s': 'urn:schemas-microsoft-com:office:spreadsheet'}
    rows = []
    for row in ET.fromstring(s).find('s:Worksheet', ns).find('s:Table', ns).findall('s:Row', ns):
        a = []
        for c in row.findall('s:Cell', ns):
            idx = c.get('{' + ns['s'] + '}Index')
            if idx:
                a += [''] * (int(idx) - 1 - len(a))
            v = c.find('s:Data', ns)
            a.append('' if v is None else ''.join(v.itertext()))
        rows.append(a)
    return rows


PROVS = {'경기도': 'GG', '강원도': 'GW', '강원특별자치도': 'GW', '충청북도': 'CB', '충청남도': 'CN',
         '전라북도': 'JB', '전북특별자치도': 'JB', '전라남도': 'JN', '경상북도': 'GB', '경상남도': 'GN'}


def parse(path, item):
    """Long table (province, name, source_row, year, value) for municipal rows of one item.
    Same province tracking as the original analyze.py: rows after a metropolitan city,
    a special city or Jeju are skipped until the next province header."""
    rows = read_rows(path)
    yc = {int(h[:4]): i for i, h in enumerate(rows[1]) if h[:4].isdigit()}
    recs, prov = [], None
    for k, r in enumerate(rows):
        if len(r) < 2 or r[1] != item:
            continue
        name = r[0]
        if name in PROVS:
            prov = PROVS[name]; continue
        if name == '전국' or '광역시' in name or '특별' in name or name == '제주도':
            prov = None; continue
        if prov is None:
            continue
        for y in YEARS:
            v = r[yc[y]] if yc[y] < len(r) else ''
            try:
                val = float(v.replace(',', ''))
            except ValueError:
                val = np.nan
            recs.append((prov, name, k + 1, y, val))
    d = pd.DataFrame(recs, columns=['province', 'name', 'source_row', 'year', 'value'])
    keep = d.groupby('source_row').value.count()
    d = d[d.source_row.isin(keep[keep > 0].index)]
    # Same label twice within a province (e.g. GN 창원시 in the farmland file): combine only
    # when the rows never both carry a value in the same year.
    clash = d.dropna(subset=['value']).groupby(['province', 'name', 'year']).size()
    assert (clash <= 1).all(), f'{path.name}: duplicate labels with overlapping years\n{clash[clash > 1]}'
    dup = d.groupby(['province', 'name']).source_row.nunique()
    combined = [f'{p}_{n}' for (p, n), c in dup.items() if c > 1]
    d = d.groupby(['province', 'name', 'year'], as_index=False).agg(
        value=('value', lambda s: s.dropna().iloc[0] if s.notna().any() else np.nan),
        source_rows=('source_row', lambda s: '+'.join(map(str, sorted(set(s))))))
    return d, combined


rice, rice_comb = parse(RICE, '재배면적')
tot, tot_comb = parse(LAND, '경지면적: 계')
pad, pad_comb = parse(LAND, '논')

early = {'GG': ['평택시', '이천시'], 'GW': ['철원군'], 'CB': ['청원군', '진천군'], 'CN': ['당진군', '서산시', '논산시'],
         'JB': ['김제시', '부안군', '익산시'], 'JN': ['나주시', '영암군', '해남군'], 'GB': ['구미시', '상주시'],
         'GN': ['김해시', '밀양시'], 'BS': ['기장군'], 'US': ['울주군']}
late = {'GG': ['화성시'], 'CN': ['예산군', '아산시'], 'JB': ['고창군', '정읍시'], 'JN': ['영광군', '고흥군'],
        'GB': ['경주시', '의성군'], 'IC': ['강화군']}
E = {(p, n) for p, v in early.items() for n in v}
L = {(p, n) for p, v in late.items() for n in v}

# Name matching between files: the farmland row with the same (province, name) and/or its
# 시<->군 counterpart (군 upgraded to 시, e.g. 양주군 -> 양주시). When both exist they are joined
# year by year, which is allowed only if they never both carry a value in the same year.
land_names = set(map(tuple, tot[['province', 'name']].drop_duplicates().values))
match_log, land_name = [], {}
for p, n in rice[['province', 'name']].drop_duplicates().itertuples(index=False):
    alt = n[:-1] + ('군' if n.endswith('시') else '시')
    found = [m for m in (n, alt) if (p, m) in land_names]
    land_name[(p, n)] = found
    if found != [n]:
        match_log.append((p, n, '+'.join(found), 'joined 시/군 rows' if len(found) == 2 else 'suffix swap' if found else 'no farmland row'))
pd.DataFrame(match_log, columns=['province', 'rice_name', 'farmland_name', 'rule']).to_csv(
    OUT / 'name_matching_audit.csv', index=False)


def wide(d, col):
    return d.pivot_table(index=['province', 'name'], columns='year', values='value', aggfunc='first').rename_axis(None, axis=1)


R, T, P = wide(rice, 'rice'), wide(tot, 'tot'), wide(pad, 'pad')
MERGES = [('CN', ['논산시', '계룡시']), ('CB', ['괴산군', '증평군']), ('GN', ['창원시', '마산시', '진해시'])]
SPLIT_OFF = {'계룡시', '증평군'}  # blank before their first appearance = included in the parent


EMPTY = pd.Series(np.nan, index=list(YEARS))


def land_series(tab, p, n):
    rows = [tab.loc[(p, m)] for m in land_name.get((p, n), []) if (p, m) in tab.index]
    if not rows:
        return EMPTY
    both = pd.concat(rows, axis=1)
    assert (both.notna().sum(axis=1) <= 1).all(), f'{p} {n}: 시/군 rows overlap'
    return both.sum(axis=1, min_count=1)


def series(tab, p, names, land=False):
    out = []
    for n in names:
        s = land_series(tab, p, n) if land else (tab.loc[(p, n)] if (p, n) in tab.index else EMPTY)
        if n in SPLIT_OFF:
            first = s.first_valid_index()
            s = s.where(s.index >= first, 0.0) if first is not None else s
        out.append(s)
    return out


units, merge_log = [], []
merged_names = {(p, n) for p, ns in MERGES for n in ns}
for p, n in R.index:
    if (p, n) in merged_names:
        continue
    units.append(dict(province=p, name=n, components=n, rice=R.loc[(p, n)],
                      tot=land_series(T, p, n), pad=land_series(P, p, n), key=(p, n)))
for p, ns in MERGES:
    parts = {}
    for lab, tab, land in [('rice', R, False), ('tot', T, True), ('pad', P, True)]:
        comps = series(tab, p, ns, land)
        # Merged label rows (창원 from the merger year) carry the total; components are blank then.
        parts[lab] = pd.concat(comps, axis=1).sum(axis=1, min_count=1)
        for n, s in zip(ns, comps):
            merge_log.append(dict(unit='+'.join(ns), component=n, item=lab, **{str(y): s[y] for y in YEARS}))
    units.append(dict(province=p, name='+'.join(ns), components='+'.join(ns), key=(p, ns[0]), **parts))
pd.DataFrame(merge_log).to_csv(OUT / 'merge_audit.csv', index=False)

recs = []
for u in units:
    p, n0 = u['key']
    cohort = 2009 if (p, n0) in E else 2011 if (p, n0) in L else 2012
    for y in YEARS:
        recs.append(dict(id=f"{u['province']}_{u['name']}", province=u['province'], name=u['name'],
                         components=u['components'], merged='+' in u['name'], year=y, cohort=cohort,
                         rice=u['rice'][y], farmland=u['tot'][y], paddy=u['pad'][y]))
d = pd.DataFrame(recs)
assert not d.duplicated(['id', 'year']).any()
d['treated'] = (d.cohort == 2009).astype(int)
pos = lambda s: np.log(s.where(s > 0))
d['y_rice'] = pos(d.rice)
d['y_share'] = pos(d.rice) - pos(d.farmland)
d['y_paddyuse'] = pos(d.rice) - pos(d.paddy)
ok = d.groupby('id')[['y_rice', 'y_share', 'y_paddyuse']].apply(lambda g: g.notna().all().all())
d['complete'] = d.id.map(ok)
d.to_csv(OUT / 'panel_v2.csv', index=False)

d[(d.rice > d.paddy) & d.complete].to_csv(OUT / 'rice_exceeds_paddy.csv', index=False)
cov = d.groupby(['id', 'province', 'name', 'cohort', 'merged']).agg(
    complete=('complete', 'first'), rice_years=('y_rice', 'count'), farmland_years=('farmland', 'count'),
    paddy_years=('paddy', 'count'), pre_mean_rice=('rice', lambda s: s.iloc[:9].mean())).reset_index()
cov.to_csv(OUT / 'coverage_v2.csv', index=False)
meta = dict(rice_sha256=hashlib.sha256(RICE.read_bytes()).hexdigest(),
            farmland_sha256=hashlib.sha256(LAND.read_bytes()).hexdigest(),
            duplicate_labels_combined=dict(rice=rice_comb, farmland_total=tot_comb, paddy=pad_comb),
            complete_units=cov[cov.complete].groupby('cohort').size().to_dict(),
            incomplete_units=cov[~cov.complete].groupby('cohort').size().to_dict(),
            rice_exceeds_paddy_rows=int(((d.rice > d.paddy) & d.complete).sum()))
(OUT / 'build_meta.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2, default=str))
print(json.dumps(meta, ensure_ascii=False, indent=2, default=str))
print(pd.DataFrame(match_log, columns=['province', 'rice_name', 'farmland_name', 'rule']).to_string())
