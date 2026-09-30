# -*- coding: utf-8 -*-
"""Identify the crop-year cells that carry non-zero weight in the preferred annual-crop estimator.

This is a SAMPLE-DEFINITION step, not an estimation: it calls the original engine's cell preparation and
weight construction (reanalysis_20260929/original_engine.py: prepare, cs_weights; normalization A,
e = 0..9 for the headline parameter, placebo e = -12..last clean pre-year excluding the base year).
Outcome values are used only to determine data availability; no estimate, SE or p-value is computed.

Output: outputs/contributing_cells.csv with one row per (outcome, crop_id, year) and flags
  role_group        treated / control
  in_theta          cell has non-zero weight in the headline average over e = 0..9
  theta_role        treated_base, treated_post, control_base, control_post (a control can be both)
  in_placebo        cell has non-zero weight in at least one pre-period (placebo) coefficient
"""
import os
import sys

import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, 'reanalysis_20260929'))
import original_engine as E  # noqa: E402

P = pd.read_csv(os.path.join(ROOT, 'verified_results', 'verified_master_panel.csv'))
ANN = ['soybean', 'onion', 'sweet_potato', 'corn', 'garlic', 'spring_potato', 'red_pepper']
CTRL = sorted(P.loc[P.role == 'control_pool', 'crop_id'].unique())
rows = []
for o in ['ln_area', 'ln_yield', 'ln_production']:
    D, Y, meta = E.prepare(P, o, ANN, CTRL)
    agg = E.cs_weights(D, Y, meta, ANN, norm='A')
    theta_cells, placebo_cells = {}, set()
    for e, d in agg.items():
        for (c, t), w in d['w'].items():
            if abs(w) < 1e-15:
                continue
            if 0 <= e <= 9:
                theta_cells.setdefault((c, t), set())
                if c in ANN and t >= meta.loc[c, 'g']:
                    theta_cells[(c, t)].add('treated_post')
                elif c in ANN and t == meta.loc[c, 'p'] - 1:
                    theta_cells[(c, t)].add('treated_base')
                elif c in ANN:
                    theta_cells[(c, t)].add('treated_crop_as_control')  # not expected for e >= 0; flagged if it occurs
                elif w < 0:
                    theta_cells[(c, t)].add('control_post')
                else:
                    theta_cells[(c, t)].add('control_base')
            elif e < 0:
                placebo_cells.add((c, t))
    for (c, t) in sorted(set(theta_cells) | placebo_cells):
        rows.append(dict(outcome=o, crop_id=c, year=t, role_group='treated' if c in ANN else 'control',
                         in_theta=int((c, t) in theta_cells), theta_role=';'.join(sorted(theta_cells.get((c, t), set()))),
                         in_placebo=int((c, t) in placebo_cells)))
out = pd.DataFrame(rows)
out.to_csv(os.path.join(ROOT, 'audit_claude_20260930', 'outputs', 'contributing_cells.csv'), index=False, encoding='utf-8-sig')
print(out.groupby(['outcome', 'role_group']).agg(cells=('year', 'size'), theta=('in_theta', 'sum'),
      crops_theta=('crop_id', lambda s: out.loc[s.index][out.loc[s.index, 'in_theta'] == 1].crop_id.nunique())).to_string())
print(out[out.in_theta == 1].groupby(['outcome', 'theta_role']).size().to_string())
