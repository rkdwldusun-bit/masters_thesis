"""Independent re-implementation of synthdid_estimate (default options) and its fixed-weight
jackknife, checked against the official R output for the primary specification (protocol section 3)."""
import numpy as np
import pandas as pd
from samples import ROOT

RES = ROOT / 'results'


def fw_step(A, x, b, eta):
    Ax = A @ x
    half_grad = (Ax - b) @ A + eta * x
    i = int(np.argmin(half_grad))
    dx = -x.copy(); dx[i] = 1 - x[i]
    if np.all(dx == 0):
        return x
    derr = A[:, i] - Ax
    step = -(half_grad @ dx) / (derr @ derr + eta * dx @ dx)
    return x + min(1.0, max(0.0, step)) * dx


def sc_weight_fw(Y, zeta, lam=None, min_decrease=1e-3, max_iter=1000):
    N0, T0 = Y.shape[0], Y.shape[1] - 1
    lam = np.full(T0, 1 / T0) if lam is None else lam
    Y = Y - Y.mean(axis=0)  # intercept
    A, b, eta = Y[:, :T0], Y[:, T0], N0 * zeta ** 2
    vals = []
    while len(vals) < max_iter and (len(vals) < 2 or vals[-2] - vals[-1] > min_decrease ** 2):
        lam = fw_step(A, lam, b, eta)
        err = Y @ np.append(lam, -1)
        vals.append(zeta ** 2 * lam @ lam + err @ err / N0)
    return lam


def sparsify(v):
    v = np.where(v <= v.max() / 4, 0, v)
    return v / v.sum()


def weights(Y, N0, T0):
    N1, T1 = Y.shape[0] - N0, Y.shape[1] - T0
    noise = np.diff(Y[:N0, :T0], axis=1).std(ddof=1)
    zeta_o, zeta_l = (N1 * T1) ** 0.25 * noise, 1e-6 * noise
    md = 1e-5 * noise
    Yc = np.column_stack([np.vstack([Y[:N0, :T0], Y[N0:, :T0].mean(0)]),
                          np.append(Y[:N0, T0:].mean(1), Y[N0:, T0:].mean())])
    lam = sc_weight_fw(Yc[:N0, :], zeta_l, None, md, 100)
    lam = sc_weight_fw(Yc[:N0, :], zeta_l, sparsify(lam), md, 10000)
    om = sc_weight_fw(Yc[:, :T0].T, zeta_o, None, md, 100)
    om = sc_weight_fw(Yc[:, :T0].T, zeta_o, sparsify(om), md, 10000)
    return om, lam


def tau(Y, N0, T0, om, lam):
    N1, T1 = Y.shape[0] - N0, Y.shape[1] - T0
    return np.append(-om, np.full(N1, 1 / N1)) @ Y @ np.append(-lam, np.full(T1, 1 / T1))


Yd = pd.read_csv(RES / 'sdid_primary_Y.csv')
info = pd.read_csv(RES / 'sdid_primary_info.csv').set_index('key').value
Y = Yd.drop(columns='id').to_numpy(float)
N0, T0 = int(info['N0']), int(info['T0'])
om, lam = weights(Y, N0, T0)
b = tau(Y, N0, T0, om, lam)
n = Y.shape[0]
u = []
for i in range(n):
    keep = np.r_[0:i, i + 1:n]; n0 = int((keep < N0).sum())
    o = om[keep[keep < N0]]; u.append(tau(Y[keep], n0, T0, o / o.sum(), lam))
se = np.sqrt((n - 1) / n * (n - 1) * np.var(u, ddof=1))
r = pd.read_csv(RES / 'sdid.csv')
r_se = r[(r.spec == 'PRIMARY full pool') & (r.se_method == 'jackknife')].se.iloc[0]
out = pd.DataFrame([dict(quantity='beta', python=b, R=info['beta'], abs_diff=abs(b - info['beta'])),
                    dict(quantity='jackknife_se', python=se, R=r_se, abs_diff=abs(se - r_se))])
out.to_csv(RES / 'sdid_python_check.csv', index=False)
print(out.to_string(index=False))
assert out.abs_diff.max() < 1e-6, 'Python and R synthdid disagree'
