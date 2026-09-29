# -*- coding: utf-8 -*-
"""est_engine.py — estimators and small-cluster inference used by 03_estimate.py.
All estimators are linear in the outcome: theta = sum_{c,t} a_ct * Y_ct. Inference uses crop-level
score contributions psi_c = sum_t a_ct * e_ct (e = residual from a two-way FE model fitted on clean untreated
cells; treated post cells are additionally demeaned by their event-time ATT) with (i) CR1-type analytic SE and
(ii) a wild (multiplier) bootstrap with Webb six-point weights at the crop level."""
import numpy as np, pandas as pd
RNG = np.random.default_rng(20260927)
WEBB = np.array([-np.sqrt(1.5), -1, -np.sqrt(.5), np.sqrt(.5), 1, np.sqrt(1.5)])
B_DRAWS = 9999

def prepare(P, outcome, treated, controls, gcol='national_year', pcol='pilot_year', years=(1991, 2024), pilot_clock=False):
    """Return dict of cells and metadata. treated/controls: lists of crop_ids.
    Clean (untreated) cell: year < pilot_year (or crop never piloted by 2024). Treated crops' own clean-pre cells
    are also valid not-yet-treated controls for other crops."""
    D = P[(P.year >= years[0]) & (P.year <= years[1]) & P.crop_id.isin(treated + controls)][['crop_id', 'year', outcome, gcol, pcol]].copy()
    D = D[D[outcome].notna()]
    D['g'] = D[pcol] if pilot_clock else D[gcol]
    D['p'] = D[pcol]
    D['clean'] = D.p.isna() | (D.year < D.p)
    D['is_tr'] = D.crop_id.isin(treated)
    D['post'] = D.is_tr & (D.year >= D.g)
    D['transition'] = D.is_tr & ~D.clean & ~D.post
    D = D[~D.transition]                      # transition (pilot-exposed, pre-national) cells excluded
    D = D[D.clean | D.post]                   # drops controls' post-pilot cells
    Y = {(c, t): v for c, t, v in zip(D.crop_id, D.year, D[outcome])}
    meta = D.drop_duplicates('crop_id').set_index('crop_id')[['g', 'p']]
    return D, Y, meta

def _add(a, key, w):
    a[key] = a.get(key, 0.0) + w

def cs_weights(D, Y, meta, treated, norm='A', e_post=range(0, 10), e_pre_min=-12, B5=False):
    """Group-time DiD with not-yet-treated/never-treated controls and a custom clean-pre base.
    norm A: base = last clean-pre year of the treated crop. norm B: base = average of clean-pre years (all in window, or last 5 if B5).
    Returns dict e -> (weights dict, n_treated, mean n controls) for post and pre (placebo) event times."""
    clean = set(zip(D.crop_id[D.clean], D.year[D.clean]))
    crops = D.crop_id.unique()
    out = {}
    for i in treated:
        if i not in meta.index: continue
        g, p = meta.loc[i, 'g'], meta.loc[i, 'p']
        pre = sorted(t for (c, t) in Y if c == i and (c, t) in clean)
        if not pre: continue
        base = [pre[-1]] if norm == 'A' else (pre[-5:] if B5 else pre)
        bmax = max(base)
        targets = [(g + e, e) for e in e_post if (i, g + e) in Y]
        targets += [(t, int(t - g)) for t in pre if (t - g) >= e_pre_min and (norm != 'A' or t != pre[-1])]
        for t, e in targets:
            ctrl = [j for j in crops if j != i and (j, t) in clean and all((j, b) in clean for b in base)]
            if not ctrl: continue
            w = {}
            _add(w, (i, t), 1.0)
            for b in base: _add(w, (i, b), -1.0 / len(base))
            for j in ctrl:
                _add(w, (j, t), -1.0 / len(ctrl))
                for b in base: _add(w, (j, b), 1.0 / (len(ctrl) * len(base)))
            out.setdefault(e, []).append((i, w, len(ctrl)))
    agg = {}
    for e, lst in out.items():
        n = len(lst); W = {}
        for (_, w, _) in lst:
            for k, v in w.items(): _add(W, k, v / n)
        agg[e] = dict(w=W, n_tr=n, n_ctrl_min=min(x[2] for x in lst), n_ctrl_max=max(x[2] for x in lst), crops=[x[0] for x in lst])
    return agg

def fe_fit(D, Y, cells):
    """Two-way FE OLS on given cells; returns alpha, lambda dicts."""
    cs = sorted({c for c, _ in cells}); ts = sorted({t for _, t in cells})
    ci = {c: k for k, c in enumerate(cs)}; ti = {t: k for k, t in enumerate(ts)}
    X = np.zeros((len(cells), len(cs) + len(ts) - 1)); y = np.zeros(len(cells))
    for r, (c, t) in enumerate(cells):
        X[r, ci[c]] = 1
        if ti[t] > 0: X[r, len(cs) + ti[t] - 1] = 1
        y[r] = Y[(c, t)]
    b = np.linalg.lstsq(X, y, rcond=None)[0]
    al = {c: b[ci[c]] for c in cs}; la = {t: (b[len(cs) + ti[t] - 1] if ti[t] > 0 else 0.0) for t in ts}
    return al, la, X, cs, ts, ci, ti

def residuals(D, Y, att_by_e):
    clean_cells = list(zip(D.crop_id[D.clean], D.year[D.clean]))
    al, la, *_ = fe_fit(D, Y, clean_cells)
    res = {}
    for r in D.itertuples():
        k = (r.crop_id, r.year)
        if r.crop_id not in al or r.year not in la: continue
        fit = al[r.crop_id] + la[r.year]
        if r.post:
            e = int(r.year - r.g); res[k] = Y[k] - fit - att_by_e.get(e, 0.0)
        else:
            res[k] = Y[k] - fit
    return res

def infer(w, res, draws=None):
    """theta, analytic CR1 SE, wild-bootstrap (Webb) SE/CI/p from crop-level scores."""
    theta = sum(v * YV for k, v in w.items() for YV in [res['_Y'][k]])
    psi = {}
    for k, v in w.items():
        if k in res: psi[k[0]] = psi.get(k[0], 0.0) + v * res[k]
    ps = np.array(list(psi.values())); G = len(ps)
    se = np.sqrt(G / (G - 1) * np.sum(ps ** 2)) if G > 1 else np.nan
    V = draws if draws is not None else RNG.choice(WEBB, size=(B_DRAWS, G))
    star = V[:, :G] @ ps
    q = np.quantile(np.abs(star), 0.95)
    p = (np.sum(np.abs(star) >= abs(theta)) + 1) / (len(star) + 1)
    return dict(est=theta, se_cl=se, se_boot=star.std(), ci_lo=theta - q, ci_hi=theta + q, p_boot=p, G=G, psi=psi, star=star)

def run_cs(P, outcome, treated, controls, norm='A', B5=False, e_post=range(0, 10), **kw):
    D, Y, meta = prepare(P, outcome, treated, controls, **kw)
    agg = cs_weights(D, Y, meta, treated, norm=norm, e_post=e_post, B5=B5)
    att = {e: sum(v * Y[k] for k, v in d['w'].items()) for e, d in agg.items()}
    res = residuals(D, Y, att); res['_Y'] = Y
    crops = sorted(D.crop_id.unique()); cix = {c: k for k, c in enumerate(crops)}
    V = RNG.choice(WEBB, size=(B_DRAWS, len(crops)))
    rows, stars = [], {}
    def inf_full(w):
        theta = sum(v * Y[k] for k, v in w.items())
        psi = np.zeros(len(crops))
        for k, v in w.items():
            if k in res: psi[cix[k[0]]] += v * res[k]
        G = int(np.sum(np.abs(psi) > 0)); se = np.sqrt(G / (G - 1) * np.sum(psi ** 2)) if G > 1 else np.nan
        star = V @ psi; q = np.quantile(np.abs(star), 0.95)
        p = (np.sum(np.abs(star) >= abs(theta)) + 1) / (len(star) + 1)
        return theta, se, star, q, p, G
    for e in sorted(agg):
        d = agg[e]; th, se, star, q, p, G = inf_full(d['w']); stars[e] = star
        rows.append(dict(event_time=e, est=th, se_cluster=se, ci_lo_wild=th - q, ci_hi_wild=th + q, p_wild=p, se_wild=star.std(),
                         p_normal_cluster=2 * (1 - _ncdf(abs(th / se))) if se and se > 0 else np.nan,
                         n_treated=d['n_tr'], n_ctrl_min=d['n_ctrl_min'], n_ctrl_max=d['n_ctrl_max'], G_contrib=G, treated_crops=';'.join(d['crops'])))
    R = pd.DataFrame(rows)
    # overall post average (equal weight over e in e_post that are observed)
    post_e = [e for e in e_post if e in agg]
    W = {}
    for e in post_e:
        for k, v in agg[e]['w'].items(): _add(W, k, v / len(post_e))
    th, se, star, q, p, G = inf_full(W)
    overall = dict(est=th, se_cluster=se, ci_lo_wild=th - q, ci_hi_wild=th + q, p_wild=p, se_wild=star.std(),
                   p_normal_cluster=2 * (1 - _ncdf(abs(th / se))) if se > 0 else np.nan, G=G,
                   n_treated=len(set(sum([agg[e]['crops'] for e in post_e], []))), n_controls=len(set(D.crop_id) - set(treated)),
                   e_range=f"{min(post_e)}..{max(post_e)}" if post_e else '')
    # joint pre-trend Wald test using bootstrap covariance
    pre_e = [e for e in sorted(agg) if e < 0]
    if len(pre_e) >= 2:
        th_pre = np.array([R.set_index('event_time').est[e] for e in pre_e]); S = np.column_stack([stars[e] for e in pre_e])
        Sig = np.cov(S, rowvar=False); Wd = float(th_pre @ np.linalg.pinv(Sig) @ th_pre)
        Wstar = np.einsum('ij,jk,ik->i', S, np.linalg.pinv(Sig), S)
        overall.update(pre_wald=Wd, pre_k=len(pre_e), pre_p_boot=(np.sum(Wstar >= Wd) + 1) / (len(Wstar) + 1),
                       pre_mean=float(th_pre.mean()))
    return R, overall, D

def run_bjs(P, outcome, treated, controls, e_post=range(0, 10), **kw):
    """Imputation estimator: FE model fitted on clean untreated cells; treated post cells imputed."""
    D, Y, meta = prepare(P, outcome, treated, controls, **kw)
    U = list(zip(D.crop_id[D.clean], D.year[D.clean])); T = [(r.crop_id, r.year, int(r.year - r.g)) for r in D[D.post].itertuples() if (r.year - r.g) in e_post]
    al, la, XU, cs, ts, ci, ti = fe_fit(D, Y, U)
    T = [x for x in T if x[0] in ci and x[1] in ti]
    XtX_inv = np.linalg.pinv(XU.T @ XU)
    def xrow(c, t):
        x = np.zeros(XU.shape[1]); x[ci[c]] = 1
        if ti[t] > 0: x[len(cs) + ti[t] - 1] = 1
        return x
    res_clean = {k: Y[k] - al[k[0]] - la[k[1]] for k in U}
    out = []; Wtot = {}
    es = sorted({e for _, _, e in T})
    for e in es + ['overall']:
        cells = [(c, t) for c, t, ee in T if (ee == e or e == 'overall')]
        if e == 'overall':
            # equal weight per event time
            wts = {}
            for ee in es:
                ce = [(c, t) for c, t, x in T if x == ee]
                for k in ce: wts[k] = wts.get(k, 0) + 1 / (len(ce) * len(es))
        else:
            wts = {k: 1 / len(cells) for k in cells}
        wT = np.array([wts[k] for k in wts]); XT = np.vstack([xrow(*k) for k in wts])
        aU = -(XU @ (XtX_inv @ (XT.T @ wT)))
        a = dict(zip(wts.keys(), wT)); [_add(a, k, v) for k, v in zip(U, aU)]
        theta = sum(v * Y[k] for k, v in a.items())
        tau = {k: Y[k] - al[k[0]] - la[k[1]] for k in wts}
        taubar = np.mean(list(tau.values()))
        psi = {}
        for k, v in a.items():
            r = res_clean[k] if k in res_clean else tau[k] - (np.average([tau[x] for x in wts if (x[1] - meta.loc[x[0], 'g']) == (k[1] - meta.loc[k[0], 'g'])]))
            psi[k[0]] = psi.get(k[0], 0) + v * r
        ps = np.array(list(psi.values())); G = int(np.sum(np.abs(ps) > 0))
        se = np.sqrt(G / (G - 1) * np.sum(ps ** 2)); star = RNG.choice(WEBB, size=(B_DRAWS, len(ps))) @ ps
        q = np.quantile(np.abs(star), 0.95)
        out.append(dict(event_time=e, est=theta, se_cluster=se, ci_lo_wild=theta - q, ci_hi_wild=theta + q,
                        p_wild=(np.sum(np.abs(star) >= abs(theta)) + 1) / (B_DRAWS + 1), n_treated=len({k[0] for k in wts}), G=G))
    return pd.DataFrame(out)

def run_twfe(P, outcome, treated, controls, variant='clean', years=(1991, 2024)):
    """Static TWFE benchmark. variant 'clean': same cells as the preferred estimator (transition excluded, controls clean only).
    variant 'naive': Han (2014)-style — all cells; post = year>=national_year for treated; transition coded untreated;
    control crops' post-pilot cells kept as untreated."""
    D = P[(P.year >= years[0]) & (P.year <= years[1]) & P.crop_id.isin(treated + controls) & P[outcome].notna()].copy()
    D['post'] = (D.crop_id.isin(treated) & (D.year >= D.national_year)).astype(float)
    if variant == 'clean':
        clean = D.pilot_year.isna() | (D.year < D.pilot_year)
        D = D[clean | (D.post == 1)]
    cs = sorted(D.crop_id.unique()); ts = sorted(D.year.unique())
    X = np.column_stack([D.post.values] + [(D.crop_id == c).values.astype(float) for c in cs] + [(D.year == t).values.astype(float) for t in ts[1:]])
    y = D[outcome].values; cl = D.crop_id.values
    beta, se, p_wcr, G = _wcr(X, y, cl)
    return dict(est=beta, se_cluster=se, p_wcr=p_wcr, G=G, n_obs=len(D), n_treated=len(set(treated) & set(cs)))

def _wcr(X, y, cl, B=1999):
    n, k = X.shape; XtX = np.linalg.pinv(X.T @ X); b = XtX @ X.T @ y; u = y - X @ b
    groups = np.unique(cl); G = len(groups)
    meat = np.zeros((k, k))
    for g in groups:
        s = X[cl == g].T @ u[cl == g]; meat += np.outer(s, s)
    V = XtX @ meat @ XtX * (G / (G - 1)) * ((n - 1) / (n - k)); se = np.sqrt(V[0, 0]); t0 = b[0] / se
    # restricted WCR (impose beta=0), Webb weights
    Xr = X[:, 1:]; br = np.linalg.pinv(Xr.T @ Xr) @ Xr.T @ y; ur = y - Xr @ br; fr = Xr @ br
    gi = {g: np.where(cl == g)[0] for g in groups}
    ts = []
    for _ in range(B):
        v = RNG.choice(WEBB, size=G); ys = fr.copy()
        for gg, vv in zip(groups, v): ys[gi[gg]] += vv * ur[gi[gg]]
        bs = XtX @ X.T @ ys; us = ys - X @ bs; mt = np.zeros((k, k))
        for gg in groups:
            s = X[gi[gg]].T @ us[gi[gg]]; mt += np.outer(s, s)
        Vs = XtX @ mt @ XtX * (G / (G - 1)) * ((n - 1) / (n - k)); ts.append(bs[0] / np.sqrt(Vs[0, 0]))
    p = (np.sum(np.abs(ts) >= abs(t0)) + 1) / (B + 1)
    return b[0], se, p, G

def _ncdf(x):
    from math import erf, sqrt
    return 0.5 * (1 + erf(x / sqrt(2)))

