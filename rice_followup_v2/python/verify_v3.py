"""Data verification and design-stage comparability for the 2009-vs-2011 pilot design.
Uses only pre-2009 outcomes for the comparability table (no treatment contrast is estimated).
Run from rice_followup_v2/:  python python/verify_v3.py   -> results/v3_design/"""
import numpy as np
import pandas as pd
from build_panel import read_rows, RICE, LAND, YEARS
from samples import ROOT, load

OUT = ROOT / 'results' / 'v3_design'
OUT.mkdir(parents=True, exist_ok=True)

# 1. Raw rows behind the Yeosu 2000 value (1998 merger of 여수시, 여천시, 여천군) and Ganghwa.
raw = []
for path, item in [(RICE, '재배면적'), (LAND, '논'), (LAND, '경지면적: 계')]:
    rows = read_rows(path)
    yc = {int(h[:4]): i for i, h in enumerate(rows[1]) if h[:4].isdigit()}
    for k, r in enumerate(rows):
        if len(r) > 1 and r[1] == item and any(s in r[0] for s in ('여수', '여천', '강화')):
            raw.append(dict(file=path.name, item=item, source_row=k + 1, label=r[0],
                            **{str(y): (r[yc[y]] if yc[y] < len(r) else '') for y in range(1996, 2012)}))
pd.DataFrame(raw).to_csv(OUT / 'raw_rows_yeosu_ganghwa.csv', index=False)

# 2. Rice changes not mirrored in paddy area, every complete unit (|dlog rice| > 0.2 and
#    |dlog rice - dlog paddy| > 0.15). Small urban units dominate; listed, not corrected.
d = load()
c = d[d.complete].sort_values(['id', 'year']).copy()
c['dlog_rice'] = c.groupby('id').y_rice.diff()
c['dlog_paddy'] = np.log(c.paddy).groupby(c.id).diff()
flag = c[(c.dlog_rice.abs() > .2) & ((c.dlog_rice - c.dlog_paddy).abs() > .15)]
flag[['id', 'cohort', 'year', 'rice', 'paddy', 'dlog_rice', 'dlog_paddy']].to_csv(OUT / 'rice_paddy_divergent_changes.csv', index=False)

# 3. SDID noise level with and without the Yeosu 2000 value (v2 primary input).
Yd = pd.read_csv(ROOT / 'results' / 'sdid_primary_Y.csv')
info = pd.read_csv(ROOT / 'results' / 'sdid_primary_info.csv').set_index('key').value
N0, T0 = int(info['N0']), int(info['T0'])
Y = Yd.drop(columns='id').to_numpy(float)
keep = [i for i in range(N0) if Yd.id[i] != 'JN_여수시']
sig = lambda M: np.diff(M[:, :T0], axis=1).std(ddof=1)
noise = pd.DataFrame([dict(controls='all 121', sigma=sig(Y[:N0])), dict(controls='without Yeosu', sigma=sig(Y[keep]))])
noise['zeta_omega'] = (18 * 3) ** .25 * noise.sigma
noise.to_csv(OUT / 'sdid_noise_yeosu.csv', index=False)

# 4. Design-stage comparability, 2009 cohort (original 17) vs 2011 cohort (9), 2000-2008 only.
q = d[d.cohort.isin([2009, 2011]) & d.complete & ~d.merged & (d.year <= 2008)]
g = q.groupby('id').agg(cohort=('cohort', 'first'), pre_mean_rice=('rice', 'mean'),
                        mean_log_share=('y_share', 'mean'), mean_log_paddyuse=('y_paddyuse', 'mean'))
g['pre_slope_log_rice'] = q.groupby('id').apply(lambda x: np.polyfit(x.year, x.y_rice, 1)[0])
g['pre_slope_log_share'] = q.groupby('id').apply(lambda x: np.polyfit(x.year, x.y_share, 1)[0])
g.sort_values(['cohort', 'pre_mean_rice']).to_csv(OUT / 'pre_comparability_units.csv')
summ = g.groupby('cohort').agg(['mean', 'median', 'min', 'max']).T
summ.to_csv(OUT / 'pre_comparability_summary.csv')
lo, hi = g[g.cohort == 2011].pre_mean_rice.agg(['min', 'max'])
overlap = g[(g.cohort == 2009) & g.pre_mean_rice.between(lo, hi)]
pd.Series(dict(late_min=lo, late_max=hi, early_in_late_range=len(overlap),
               early_ids=';'.join(overlap.index))).to_csv(OUT / 'size_overlap.csv')
pd.set_option('display.width', 200)
print(noise.round(4).to_string(index=False)); print(summ.round(4).to_string()); print(len(overlap), list(overlap.index))
