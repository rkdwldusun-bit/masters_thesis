"""Sample definitions shared by the TWFE and SDID scripts (protocol_v2.md sections 1 and 4)."""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
BOUND = {'창원시', '마산시', '진해시', '논산시', '계룡시', '괴산군', '증평군'}


def load():
    return pd.read_csv(ROOT / 'data' / 'panel_v2.csv')


def screen(q):
    """Original pre-area screen: controls whose 2000-2008 mean rice area lies in the treated range."""
    pre = q[q.year < 2009].groupby('id').rice.mean()
    tr = q[q.treated == 1].id.unique()
    lo, hi = pre.loc[tr].min(), pre.loc[tr].max()
    keep = set(tr) | set(pre[pre.between(lo, hi)].index)
    return q[q.id.isin(keep)]


def original_17_42(d):
    """The original main sample: boundary-affected units dropped, positive rice 2000-2011, screen."""
    q = d[(d.cohort != 2011) & ~d.merged & ~d.name.isin(BOUND)]
    n = q.groupby('id').y_rice.count()
    return screen(q[q.id.isin(n[n == 12].index)]).sort_values(['id', 'year']).reset_index(drop=True)


def full_pool(d):
    """v2 pool: 2009 cohort (18 incl. 논산+계룡) and every complete 2012-cohort unit."""
    return d[(d.cohort != 2011) & d.complete].sort_values(['id', 'year']).reset_index(drop=True)


def full_screened(d):
    return screen(full_pool(d)).sort_values(['id', 'year']).reset_index(drop=True)
