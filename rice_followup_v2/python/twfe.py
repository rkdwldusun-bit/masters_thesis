"""TWFE specifications S1, S2, S3, S6 (protocol_v2.md section 4).
Municipality CR1 clustered SE, t(G-1); same estimator as the original analyze.py."""
import numpy as np
import pandas as pd
from scipy import stats
from samples import ROOT, load, original_17_42, full_pool, full_screened

OUT = ROOT / 'results'
OUT.mkdir(exist_ok=True)


def within(a, q):
    z = np.asarray(a, float).copy()
    for g in (q.id, q.year):
        codes, lev = pd.factorize(g)
        s = np.zeros(len(lev)); np.add.at(s, codes, z)
        z -= s[codes] / np.bincount(codes)[codes]
    return z


def twfe(q, y, label):
    x = (q.treated * (q.year >= 2009)).to_numpy(float)
    xr, yr = within(x, q), within(q[y], q)
    b = xr @ yr / (xr @ xr); e = yr - b * xr
    codes, lev = pd.factorize(q.id); G, N = len(lev), len(q)
    K = G + q.year.nunique() - 1 + 1
    sc = np.zeros(G); np.add.at(sc, codes, xr * e)
    se = np.sqrt(G / (G - 1) * (N - 1) / (N - K) * (sc ** 2).sum() / (xr @ xr) ** 2)
    t = stats.t.ppf(.975, G - 1); t90 = stats.t.ppf(.95, G - 1)
    return dict(spec=label, outcome=y, estimator='TWFE', treated=q[q.treated == 1].id.nunique(),
                controls=q[q.treated == 0].id.nunique(), beta=b, se=se, se_method='CR1 municipality',
                p=2 * stats.t.sf(abs(b / se), G - 1), ci95_low=b - t * se, ci95_high=b + t * se,
                ci90_low=b - t90 * se, ci90_high=b + t90 * se, df=G - 1)


d = load()
s1 = original_17_42(d)
assert (s1.treated.groupby(s1.id).first().value_counts().to_dict() == {0: 42, 1: 17})
rows = [twfe(s1, 'y_rice', 'S1 original 17/42')]
assert abs(rows[0]['beta'] - 0.030596536322393914) < 1e-12 and abs(rows[0]['se'] - 0.020799768874834593) < 1e-12, \
    'S1 must reproduce the original main estimate'
rows.append(twfe(s1, 'y_share', 'S2 original 17/42'))
s3 = full_screened(d)
rows += [twfe(s3, y, 'S3 merged units, screened') for y in ('y_rice', 'y_share')]
fp = full_pool(d)
rows += [twfe(fp, 'y_share', 'S6 full pool, unweighted'),
         twfe(fp, 'y_rice', 'S6-ref full pool, unweighted (original all-controls design + merged units)')]
r = pd.DataFrame(rows)
r.to_csv(OUT / 'twfe.csv', index=False)
s3.groupby('id').first()[['treated']].to_csv(OUT / 'sample_S3_units.csv')
print(r[['spec', 'outcome', 'treated', 'controls', 'beta', 'se', 'p']].to_string(index=False))
