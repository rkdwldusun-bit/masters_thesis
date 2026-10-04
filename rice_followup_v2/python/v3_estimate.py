"""Protocol v3 (protocol_v3.md): 2009 cohort (17) vs 2011 cohort (9), 2000-2010, ln rice area.
Primary: TWFE (estimator A) with a null-imposed wild cluster bootstrap-t (Webb, 9,999, seed 20261004),
95% CI by inverting the same test. Supplementary analyses use CR1 SE and t(G-1).
Run from rice_followup_v2/:  python python/v3_estimate.py  -> results/v3/"""
import json
import numpy as np
import pandas as pd
from scipy import stats
from samples import ROOT, load

OUT = ROOT / 'results' / 'v3'
OUT.mkdir(parents=True, exist_ok=True)
SEED, B = 20261004, 9999
WEBB = np.array([-np.sqrt(1.5), -1, -np.sqrt(.5), np.sqrt(.5), 1, np.sqrt(1.5)])

d = load()
base = d[d.cohort.isin([2009, 2011]) & d.complete & (d.year <= 2010)].copy()
base['D'] = ((base.cohort == 2009) & (base.year >= 2009)).astype(float)


def sample(nonsan=False):
    q = base if nonsan else base[~base.merged]
    return q.sort_values(['id', 'year']).reset_index(drop=True)


def within(a, q):
    """Exact two-way demeaning for a balanced panel sorted by id then year (columns of a)."""
    a = np.asarray(a, float)
    G, T = q.id.nunique(), q.year.nunique()
    z = a.reshape(G, T, -1)
    z = z - z.mean(0, keepdims=True) - z.mean(1, keepdims=True) + z.mean((0, 1), keepdims=True)
    return z.reshape(G * T, -1)


def cr1(q, X, y):
    X = np.asarray(X, float).reshape(len(q), -1)
    xr, yr = within(X, q), within(y, q)[:, 0]
    inv = np.linalg.inv(xr.T @ xr); b = inv @ xr.T @ yr; e = yr - xr @ b
    codes, lev = pd.factorize(q.id); G, N = len(lev), len(q)
    K = G + q.year.nunique() - 1 + X.shape[1]
    sc = np.zeros((G, X.shape[1])); np.add.at(sc, codes, xr * e[:, None])
    V = G / (G - 1) * (N - 1) / (N - K) * inv @ sc.T @ sc @ inv
    return b, V, G, K


def row(label, q, y='y_rice', D='D', note=''):
    b, V, G, _ = cr1(q, q[D], q[y]); se = np.sqrt(V[0, 0]); t = stats.t.ppf(.975, G - 1)
    return dict(analysis=label, outcome=y, treated=q[q.cohort == 2009].id.nunique(), controls=q[q.cohort == 2011].id.nunique(),
                n=len(q), beta=b[0], se_cr1=se, p_cr1_t=2 * stats.t.sf(abs(b[0] / se), G - 1),
                ci95_cr1_low=b[0] - t * se, ci95_cr1_high=b[0] + t * se, df=G - 1, note=note)


# ---------------- primary: estimator A + null-imposed WCR bootstrap-t -------------------
q = sample()
assert q[q.cohort == 2009].id.nunique() == 17 and q[q.cohort == 2011].id.nunique() == 9 and len(q) == 286
G, T, N = 26, 11, 286
codes, levels = pd.factorize(q.id)
xr = within(q.D, q)[:, 0]; yr = within(q.y_rice, q)[:, 0]
xx = xr @ xr
beta = xr @ yr / xx
K = G + T - 1 + 1
cadj = G / (G - 1) * (N - 1) / (N - K)


def se_from(e):  # e: (..., N) residuals in within space
    s = (e * xr).reshape(*e.shape[:-1], G, T).sum(-1)
    return np.sqrt(cadj * (s ** 2).sum(-1) / xx ** 2)


se_hat = se_from(yr - beta * xr)
rng = np.random.default_rng(SEED)
Wg = rng.choice(WEBB, size=(B, G))          # one Webb draw per municipality and replication
Vobs = np.repeat(Wg, T, axis=1)              # sorted by id then year


def wcr_p(b0):
    u = yr - b0 * xr                         # restricted (beta = b0) residuals, FE absorbed
    vu = Vobs * u                            # (B, N)
    z = vu.reshape(B, G, T)
    z = (z - z.mean(1, keepdims=True) - z.mean(2, keepdims=True) + z.mean((1, 2), keepdims=True)).reshape(B, N)
    db = z @ xr / xx                         # beta* - b0
    e = z - db[:, None] * xr[None, :]
    tstar = db / se_from(e)
    tobs = (beta - b0) / se_hat
    return float(np.mean(np.abs(tstar) >= abs(tobs) - 1e-12))


p_wcr = wcr_p(0.0)
grid = beta + se_hat * np.arange(-8, 8.0001, 1 / 50)
pg = np.array([wcr_p(b) for b in grid])
inside = pg >= .05
assert inside.any() and not inside[0] and not inside[-1], 'grid does not bracket the WCR confidence set'
idx = np.flatnonzero(inside)
contiguous = bool(np.all(np.diff(idx) == 1))


def bisect(lo, hi, lo_in):
    for _ in range(60):
        mid = (lo + hi) / 2
        if (wcr_p(mid) >= .05) == lo_in: lo = mid
        else: hi = mid
        if hi - lo < 1e-7: break
    return (lo + hi) / 2


ci_low = bisect(grid[idx[0] - 1], grid[idx[0]], False)
ci_high = bisect(grid[idx[-1]], grid[idx[-1] + 1], True)
t975, t80 = stats.t.ppf(.975, G - 1), stats.t.ppf(.80, G - 1)
primary = dict(analysis='PRIMARY: estimator A (TWFE 2000-2010)', outcome='y_rice', treated=17, controls=9, n=N,
               beta=beta, se_cr1=se_hat, p_cr1_t=2 * stats.t.sf(abs(beta / se_hat), G - 1),
               ci95_cr1_low=beta - t975 * se_hat, ci95_cr1_high=beta + t975 * se_hat,
               p_wcr_bootstrap=p_wcr, ci95_wcr_low=ci_low, ci95_wcr_high=ci_high, wcr_set_contiguous=contiguous,
               wcr_B=B, wcr_weights='Webb 6-point', wcr_seed=SEED, wcr_null='imposed', wcr_stat='CR1-studentized t, symmetric two-sided',
               mde80_cr1=(t975 + t80) * se_hat, pct=100 * np.expm1(beta),
               pct_wcr_low=100 * np.expm1(ci_low), pct_wcr_high=100 * np.expm1(ci_high))
# Collapsed 2x2 check of the TWFE coefficient (balanced panel identity).
m = q.assign(post=q.year >= 2009).groupby(['id', 'cohort', 'post']).y_rice.mean().unstack()
dd = (m[True] - m[False]).groupby(level='cohort').mean()
assert abs(dd[2009] - dd[2011] - beta) < 1e-12
(OUT / 'primary.json').write_text(json.dumps(primary, indent=2, default=float))
pd.DataFrame({'beta0': grid, 'p_wcr': pg}).to_csv(OUT / 'wcr_pvalue_grid.csv', index=False)

# ---------------- supplementary (CR1, t(G-1)) -------------------------------------------
rows = [row('A (CR1 view of the primary)', q)]
q08 = q[q.year >= 2008].reset_index(drop=True)
rows.append(row('(a) B: 2008 baseline, mean of 2009-2010', q08))
rows.append(row('(e) A incl. Nonsan+Gyeryong (18 vs 9)', sample(nonsan=True)))
pre = q[q.year <= 2008].groupby('id').rice.mean(); coh = q.groupby('id').cohort.first()
lo, hi = pre[coh == 2011].min(), pre[coh == 2011].max()
ov = q[q.id.isin(pre[(coh == 2011) | pre.between(lo, hi)].index)].reset_index(drop=True)
rows.append(row('(f) A, size overlap 6 vs 9 (different target population)', ov))
for y in ('y_share', 'y_paddyuse'):
    rows.append(row(f'(g) A, outcome {y}', q, y=y))
rows.append(row('(h) A without Gumi (influence diagnostic)', q[q.id != 'GB_구미시'].reset_index(drop=True)))
supp = pd.DataFrame(rows)
supp.to_csv(OUT / 'supplementary.csv', index=False)

# (b) event study, 2008 reference, CR1; joint Wald F(8, 25) on 2000-2007.
years = [y for y in range(2000, 2011) if y != 2008]
Xe = np.column_stack([(q.cohort == 2009) & (q.year == y) for y in years]).astype(float)
be, Ve, Ge, _ = cr1(q, Xe, q.y_rice)
tcrit = stats.t.ppf(.975, Ge - 1)
ev = pd.DataFrame({'year': years, 'beta': be, 'se_cr1': np.sqrt(np.diag(Ve))})
ev['ci95_low'] = ev.beta - tcrit * ev.se_cr1; ev['ci95_high'] = ev.beta + tcrit * ev.se_cr1
ev['p_cr1_t'] = 2 * stats.t.sf(np.abs(ev.beta / ev.se_cr1), Ge - 1)
ev.to_csv(OUT / 'event_study.csv', index=False)
ip = np.arange(8)
W = float(be[ip] @ np.linalg.solve(Ve[np.ix_(ip, ip)], be[ip]))
joint = dict(F=W / 8, df1=8, df2=Ge - 1, p=float(stats.f.sf(W / 8, 8, Ge - 1)))
pd.DataFrame(Ve, index=years, columns=years).to_csv(OUT / 'event_study_vcov_cr1.csv')

# (c) yearly group means and gap; unit paths relative to 2008.
gm = q.groupby(['year', 'cohort']).y_rice.mean().unstack()
gm.columns = ['mean_ln_rice_2009_cohort', 'mean_ln_rice_2011_cohort']
gm['gap'] = gm.iloc[:, 0] - gm.iloc[:, 1]
gm['gap_minus_2008'] = gm.gap - gm.gap.loc[2008]
gm.to_csv(OUT / 'yearly_group_gap.csv')
paths = q.assign(rel_2008=q.y_rice - q.id.map(q[q.year == 2008].set_index('id').y_rice))
paths[['id', 'name', 'cohort', 'year', 'rice', 'y_rice', 'rel_2008']].to_csv(OUT / 'unit_paths.csv', index=False)

summary = dict(primary=primary, pretrend_joint=joint, overlap_sample=dict(late_range=[lo, hi], early_units=sorted(set(ov[ov.cohort == 2009].id))))
(OUT / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False, default=float))
pd.set_option('display.width', 220)
print(json.dumps(primary, indent=1, default=float))
print(supp[['analysis', 'outcome', 'treated', 'controls', 'beta', 'se_cr1', 'p_cr1_t', 'ci95_cr1_low', 'ci95_cr1_high']].round(4).to_string(index=False))
print(ev.round(4).to_string(index=False)); print(joint); print(gm.round(4).to_string())
