"""Addendum 1 diagnostic D3(a)-(c): row coverage, municipal-sum/province-total ratios and large
treated-unit annual log changes, 2000-2011. Descriptive only.  python python/data_breaks.py"""
import numpy as np
import pandas as pd
from build_panel import read_rows, PROVS, RICE, LAND, YEARS
from samples import ROOT, load

OUT = ROOT / 'results' / 'placebo_trace'
OUT.mkdir(parents=True, exist_ok=True)


def province_and_municipal(path, item):
    rows = read_rows(path)
    yc = {int(h[:4]): i for i, h in enumerate(rows[1]) if h[:4].isdigit()}
    num = lambda r, y: pd.to_numeric(str(r[yc[y]]).replace(',', ''), errors='coerce') if yc[y] < len(r) else np.nan
    prov_tot, muni_sum, muni_rows, prov = {}, {}, {}, None
    for r in rows:
        if len(r) < 2 or r[1] != item:
            continue
        if r[0] in PROVS:
            prov = PROVS[r[0]]
            for y in YEARS:
                prov_tot[(prov, y)] = num(r, y)
            continue
        if r[0] == '전국' or '광역시' in r[0] or '특별' in r[0] or r[0] == '제주도':
            prov = None; continue
        if prov is None:
            continue
        for y in YEARS:
            v = num(r, y)
            if pd.notna(v):
                muni_sum[(prov, y)] = muni_sum.get((prov, y), 0) + v
                muni_rows[(prov, y)] = muni_rows.get((prov, y), 0) + 1
    out = pd.DataFrame([dict(item=item, province=p, year=y, province_total=prov_tot.get((p, y)),
                             municipal_sum=muni_sum.get((p, y)), municipal_rows=muni_rows.get((p, y)))
                        for p in sorted(set(PROVS.values())) for y in YEARS])
    out['ratio'] = out.municipal_sum / out.province_total
    return out


cov = pd.concat([province_and_municipal(RICE, '재배면적'), province_and_municipal(LAND, '경지면적: 계'),
                 province_and_municipal(LAND, '논')])
cov.to_csv(OUT / 'D3ab_rows_and_province_ratio.csv', index=False)

d = load()
q = d[(d.cohort != 2011) & d.complete].sort_values(['id', 'year']).copy()
for v in ('y_rice', 'y_share'):
    q['d_' + v] = q.groupby('id')[v].diff()
q['ln_farmland'] = np.log(q.farmland)
q['d_ln_farmland'] = q.groupby('id').ln_farmland.diff()
mean_change = q[q.year.between(2001, 2011)].groupby(['year', 'treated'])[['d_y_rice', 'd_ln_farmland', 'd_y_share']].mean().unstack()
mean_change.to_csv(OUT / 'D3c_mean_annual_log_change.csv')
big = q[(q.treated == 1) & q.year.between(2001, 2008) &
        ((q.d_y_rice.abs() > .10) | (q.d_ln_farmland.abs() > .10))]
big[['id', 'year', 'rice', 'farmland', 'paddy', 'd_y_rice', 'd_ln_farmland', 'd_y_share']].to_csv(
    OUT / 'D3c_treated_large_changes.csv', index=False)
# Share of units whose rice area rose 2005->2006, by group.
w = q[q.year.isin([2005, 2006])].pivot(index='id', columns='year', values='rice')
g = q.groupby('id').treated.first()
rose = ((w[2006] > w[2005]).groupby(g).mean()).rename('share_rice_rose_2005_06')
pd.DataFrame(rose).to_csv(OUT / 'D3c_rice_rose_2005_06.csv')

pd.set_option('display.width', 200)
piv = cov.pivot_table(index=['item', 'province'], columns='year', values='ratio').round(3)
print(piv.to_string())
print(cov.pivot_table(index='item', columns='year', values='municipal_rows', aggfunc='sum').to_string())
print(mean_change.round(4).to_string())
print(big.round(3).to_string()); print(rose)
