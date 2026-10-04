"""Protocol v3 addendum 1 (protocol_v3_addendum1.md): drop the municipalities hosting a 4 Major
Rivers weir or its construction section (E1: Sangju, Gumi, Naju; Uiseong) and re-run estimator A
with CR1 and the null-imposed Webb WCR bootstrap-t (9,999 draws, seed 20261004, CI by inversion).
Run from rice_followup_v2/:  python python/v3_e1.py  -> results/v3/sensitivity_E1.json"""
import json
import numpy as np
import pandas as pd
from scipy import stats
from samples import ROOT, load

E1 = {'GB_상주시', 'GB_구미시', 'JN_나주시', 'GB_의성군'}
SEED, B = 20261004, 9999
WEBB = np.array([-np.sqrt(1.5), -1, -np.sqrt(.5), np.sqrt(.5), 1, np.sqrt(1.5)])

d = load()
q = d[d.cohort.isin([2009, 2011]) & d.complete & ~d.merged & (d.year <= 2010)]
assert E1 <= set(q.id), 'E1 ids must be in the v3 sample'
q = q[~q.id.isin(E1)].sort_values(['id', 'year']).reset_index(drop=True)
q['D'] = ((q.cohort == 2009) & (q.year >= 2009)).astype(float)
G, T = q.id.nunique(), q.year.nunique(); N = G * T
nt, nc = q[q.cohort == 2009].id.nunique(), q[q.cohort == 2011].id.nunique()
assert (nt, nc) == (14, 8) and len(q) == N


def within(a):
    z = np.asarray(a, float).reshape(G, T, -1)
    return (z - z.mean(0, keepdims=True) - z.mean(1, keepdims=True) + z.mean((0, 1), keepdims=True)).reshape(N, -1)


xr = within(q.D)[:, 0]; yr = within(q.y_rice)[:, 0]; xx = xr @ xr
beta = xr @ yr / xx
cadj = G / (G - 1) * (N - 1) / (N - (G + T - 1 + 1))


def se_from(e):
    s = (e * xr).reshape(*e.shape[:-1], G, T).sum(-1)
    return np.sqrt(cadj * (s ** 2).sum(-1) / xx ** 2)


se = se_from(yr - beta * xr)
Vobs = np.repeat(np.random.default_rng(SEED).choice(WEBB, size=(B, G)), T, axis=1)


def wcr_p(b0):
    z = (Vobs * (yr - b0 * xr)).reshape(B, G, T)
    z = (z - z.mean(1, keepdims=True) - z.mean(2, keepdims=True) + z.mean((1, 2), keepdims=True)).reshape(B, N)
    db = z @ xr / xx
    tstar = db / se_from(z - db[:, None] * xr[None, :])
    return float(np.mean(np.abs(tstar) >= abs((beta - b0) / se) - 1e-12))


grid = beta + se * np.arange(-8, 8.0001, 1 / 50)
inside = np.array([wcr_p(b) >= .05 for b in grid]); idx = np.flatnonzero(inside)
assert inside.any() and not inside[0] and not inside[-1]


def bisect(lo, hi, lo_in):
    for _ in range(60):
        mid = (lo + hi) / 2
        if (wcr_p(mid) >= .05) == lo_in: lo = mid
        else: hi = mid
        if hi - lo < 1e-7: break
    return (lo + hi) / 2


t975 = stats.t.ppf(.975, G - 1)
# Pre-period joint test, event study 2000-2010 with 2008 reference, CR1.
years = [y for y in range(2000, 2011) if y != 2008]
X = np.column_stack([((q.cohort == 2009) & (q.year == y)).astype(float) for y in years])
Xr = within(X); inv = np.linalg.inv(Xr.T @ Xr); be = inv @ Xr.T @ yr; e = yr - Xr @ be
sc = (Xr * e[:, None]).reshape(G, T, -1).sum(1)
Ve = G / (G - 1) * (N - 1) / (N - (G + T - 1 + len(years))) * inv @ sc.T @ sc @ inv
W = float(be[:8] @ np.linalg.solve(Ve[:8, :8], be[:8]))
out = dict(analysis='S-E1: v3 sample without weir-host municipalities (Sangju, Gumi, Naju; Uiseong)',
           treated=nt, controls=nc, n=N, beta=beta, se_cr1=se, p_cr1_t=2 * stats.t.sf(abs(beta / se), G - 1),
           ci95_cr1=[beta - t975 * se, beta + t975 * se], p_wcr_bootstrap=wcr_p(0.0),
           ci95_wcr=[bisect(grid[idx[0] - 1], grid[idx[0]], False), bisect(grid[idx[-1]], grid[idx[-1] + 1], True)],
           wcr_set_contiguous=bool(np.all(np.diff(idx) == 1)), wcr='null-imposed Webb bootstrap-t, B=9999, seed 20261004',
           pretrend_joint=dict(F=W / 8, df=[8, G - 1], p=float(stats.f.sf(W / 8, 8, G - 1))),
           event_2009=float(be[8]), event_2010=float(be[9]))
(ROOT / 'results' / 'v3' / 'sensitivity_E1.json').write_text(json.dumps(out, indent=2, ensure_ascii=False, default=float))
print(json.dumps(out, indent=1, ensure_ascii=False, default=float))
