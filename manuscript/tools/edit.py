"""Tracked-change update of the thesis to the six-crop national analysis.
All table numbers are read from analysis/output/ (no hand-typed values)."""
import csv, re, sys, html
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from docxlib import CAPS, find_table, rows, cells, text

DOC = sys.argv[1]
OUT = '/home/user/masters_thesis/analysis/output/'
AUTH, DATE = 'Claude', '2026-10-21T12:00:00Z'
s = open(DOC, encoding='utf-8').read()

# ---------------- normalise runs (content-preserving) ----------------
s = s.replace('<w:lastRenderedPageBreak/>', '')
s = re.sub(r'</w:t><w:t(?: xml:space="preserve")?>', '', s)
s = s.replace('<w:t>', '<w:t xml:space="preserve">')
def _split(m):
    rpr, body = m.group(1) or '', m.group(2)
    kids = [k.group(0) for k in re.finditer(r'<w:t(?: [^>]*)?>[^<]*</w:t>|<w:delText(?: [^>]*)?>[^<]*</w:delText>|<(?:w|m):[A-Za-z]+(?: [^>]*)?/>|<(w:[A-Za-z]+)(?: [^>]*)?>.*?</\1>', body, re.S)]
    if len(kids) <= 1 or ''.join(kids) != body: return m.group(0)
    return ''.join(f'<w:r>{rpr}{k}</w:r>' for k in kids)
s = re.sub(r'<w:r>(<w:rPr>(?:(?!</w:rPr>).)*</w:rPr>)?((?:(?!</w:r>).)*)</w:r>', _split, s, flags=re.S)
_id = [90000]
def nid():
    _id[0] += 1
    return _id[0]
esc = lambda x: html.escape(x, quote=False)
def attrs(): return f'w:id="{nid()}" w:author="{AUTH}" w:date="{DATE}"'
def t_el(x, tag='w:t'): return f'<{tag} xml:space="preserve">{esc(x)}</{tag}>'
def del_run(rpr, x): return f'<w:del {attrs()}><w:r>{rpr}{t_el(x, "w:delText")}</w:r></w:del>'
def ins_run(rpr, x): return f'<w:ins {attrs()}><w:r>{rpr}{t_el(x)}</w:r></w:ins>'
def plain_run(rpr, x): return f'<w:r>{rpr}{t_el(x)}</w:r>' if x else ''

RUN = re.compile(r'<w:r>((?:<w:rPr>(?:(?!</w:rPr>).)*</w:rPr>)?)<w:t(?: [^>]*)?>([^<]*)</w:t></w:r>', re.S)
LOG = []
NB = lambda x: re.sub(r'\b(pp?)\. (?=\d)', '\\1.\u00a0', x)

def rep(old, new, lo=0, hi=None, note=''):
    """Replace text `old` (inside one run, unique in s[lo:hi]) by `new` as a tracked change."""
    global s
    old, new = NB(old), NB(new)
    hi = len(s) if hi is None else hi
    eo = esc(old)
    hits = [m for m in RUN.finditer(s, lo, hi) if eo in m.group(2)]
    hits = [m for m in hits if m.group(2).count(eo) == 1] if len(hits) == 1 else hits
    if len(hits) != 1:
        raise SystemExit(f'{len(hits)} runs contain {old!r}')
    m = hits[0]; rpr, txt = m.group(1), html.unescape(m.group(2))
    i = txt.index(old)
    new_xml = plain_run(rpr, txt[:i]) + del_run(rpr, old) + (ins_run(rpr, new) if new else '') + plain_run(rpr, txt[i + len(old):])
    s = s[:m.start()] + new_xml + s[m.end():]
    LOG.append((old, new, note))

def insert_after(anchor, new, lo=0, hi=None):
    """Insert `new` right after text `anchor` (inside one run) as a tracked insertion."""
    global s
    anchor, new = NB(anchor), NB(new)
    hi = len(s) if hi is None else hi
    ea = esc(anchor)
    hits = [m for m in RUN.finditer(s, lo, hi) if ea in m.group(2)]
    if len(hits) != 1: raise SystemExit(f'{len(hits)} runs contain anchor {anchor!r}')
    m = hits[0]; rpr, txt = m.group(1), html.unescape(m.group(2))
    i = txt.index(anchor) + len(anchor)
    s = s[:m.start()] + plain_run(rpr, txt[:i]) + ins_run(rpr, new) + plain_run(rpr, txt[i:]) + s[m.end():]
    LOG.append(('', new, 'insert after ' + anchor[:40]))

# ---------------- table helpers ----------------
def tbl_span(key):
    return find_table(s, CAPS[key])

def set_cell(key, r, c, new):
    a, b = tbl_span(key)
    tr = rows(s[a:b])[r]
    tc = cells(tr.group(0))[c]
    lo = a + tr.start() + tc.start(); hi = a + tr.start() + tc.end()
    old = text(tc.group(0))
    old = html.unescape(old)
    if old == new: return
    rep(old, new, lo, hi, f'{key} r{r} c{c}')

def delete_row(key, r):
    global s
    a, b = tbl_span(key)
    tr = rows(s[a:b])[r]
    x = tr.group(0)
    mark = f'<w:del {attrs()}/>'
    if '<w:trPr>' in x: x = x.replace('</w:trPr>', mark + '</w:trPr>', 1)
    else: x = re.sub(r'^(<w:tr[^>]*>)', r'\1<w:trPr>' + mark + '</w:trPr>', x)
    x = RUN.sub(lambda m: del_run(m.group(1), html.unescape(m.group(2))), x)
    # paragraph marks inside the deleted row
    x = re.sub(r'<w:pPr>((?:(?!</w:pPr>).)*?)</w:pPr>', lambda m: '<w:pPr>' + m.group(1) + f'<w:rPr><w:del {attrs()}/></w:rPr></w:pPr>' if '<w:rPr>' not in m.group(1) else m.group(0), x, flags=re.S)
    s = s[:a + tr.start()] + x + s[a + tr.end():]
    LOG.append((f'{key} row {r}', '', 'row deleted'))

def insert_rows_after(key, r_after, templates, texts):
    """Clone rows `templates` (indices) with new cell texts; insert as tracked rows after r_after."""
    global s
    a, b = tbl_span(key)
    R = rows(s[a:b])
    new_xml = ''
    for ti, vals in zip(templates, texts):
        x = R[ti].group(0)
        cs = cells(x)
        out, last = '', 0
        for c, val in zip(cs, vals):
            cx = c.group(0)
            runs = list(RUN.finditer(cx))
            if runs:
                m = runs[0]
                cx = cx[:m.start()] + (ins_run(m.group(1), val) if val else '') + cx[m.end():]
                for m2 in runs[1:]: cx = cx.replace(m2.group(0), '')
            elif val:
                cx = cx.replace('</w:p>', ins_run('', val) + '</w:p>', 1)
            out += x[last:c.start()] + cx; last = c.end()
        out += x[last:]
        mark = f'<w:ins {attrs()}/>'
        out = out.replace('</w:trPr>', mark + '</w:trPr>', 1) if '<w:trPr>' in out else re.sub(r'^(<w:tr[^>]*>)', r'\1<w:trPr>' + mark + '</w:trPr>', out)
        out = re.sub(r'<w:pPr>((?:(?!</w:pPr>).)*?)</w:pPr>', lambda m: '<w:pPr>' + m.group(1) + f'<w:rPr><w:ins {attrs()}/></w:rPr></w:pPr>' if '<w:rPr>' not in m.group(1) else m.group(0), out, flags=re.S)
        new_xml += out
    pos = a + R[r_after].end()
    s = s[:pos] + new_xml + s[pos:]
    LOG.append((f'{key} rows after {r_after}', str(len(texts)), 'rows inserted'))

# ---------------- numbers ----------------
def rd(f): return list(csv.DictReader(open(OUT + f, encoding='utf-8')))
mn = lambda x: x.replace('-', '−')
f3 = lambda x: mn(f'{(0.0 if abs(float(x)) < 0.0005 else float(x)):.3f}')
def star(p): p = float(p); return '***' if p < .01 else '**' if p < .05 else '*' if p < .1 else ''
O3 = ['ln_area', 'ln_yield', 'ln_production']
def panel(rowsel):
    d = {r['outcome']: r for r in rowsel}
    return ([f3(d[o]['est']) + star(d[o]['p']) for o in O3], [f'({f3(d[o]["se"])})' for o in O3],
            [f'[{f3(d[o]["ci_lo"])}, {f3(d[o]["ci_hi"])}]' for o in O3], [d[o]['n_comparison'] for o in O3])
T4 = rd('table4_main.csv'); T5 = rd('table5_sensitivity.csv'); T6 = rd('table6_area_weights.csv')
A1 = rd('tableA1_leave_one_out.csv'); T2 = rd('table2_summary.csv'); T9 = rd('table9_prepilot_growth.csv')
W6 = rd('table6_weights.csv'); J6 = rd('fig6_joint_pretest.csv'); F7 = rd('fig7_crop_means.csv')
sel = lambda L, **k: [r for r in L if all(r[a] == v for a, v in k.items())]

# ---------------- tables ----------------
def fill_panel(key, r0, vals, with_n=True):
    est, se, ci, n = vals
    for c in range(3):
        set_cell(key, r0, c + 1, est[c]); set_cell(key, r0 + 1, c + 1, se[c]); set_cell(key, r0 + 2, c + 1, ci[c])
        if with_n: set_cell(key, r0 + 3, c + 1, n[c])

# Table 4
fill_panel('T4', 2, panel(sel(T4, design='main', spec='A. Full comparison pool')))
fill_panel('T4', 7, panel(sel(T4, design='main', spec='B. Excluding two spring series')))
# Table 5 panels A-F, then G-H inserted
specs5 = sorted({r['spec'] for r in T5})
G = panel(sel(T5, spec=[x for x in specs5 if x[0] == 'G'][0]))
H = panel(sel(T4, design='S2', spec='A. Full comparison pool'))
insert_rows_after('T5', 24, [21, 22, 23, 24, 21, 22, 23, 24], [
    ['Panel G. Timing: Yearbook main-program years', '', '', ''], ['Contrast'] + G[0], [''] + G[1], [''] + G[2],
    ['Panel H. Seven crops with previous timing', '', '', ''], ['Contrast'] + H[0], [''] + H[1], [''] + H[2]])
for k, sp in enumerate([x for x in specs5 if x[0] in 'ABCDEF']):
    fill_panel('T5', 2 + 4 * k, panel(sel(T5, spec=sp)), with_n=False)
# Table 6
fill_panel('T6', 2, panel(sel(T6, spec='A. Full comparison pool')), with_n=False)
fill_panel('T6', 6, panel(sel(T6, spec='B. Excluding two spring series')), with_n=False)
# Table A1 (rows: Soybean, Onion, Sweet potato, Corn, Garlic, [Spring potato], Red pepper)
order = ['soybean', 'onion', 'sweet_potato', 'corn', 'garlic', None, 'red_pepper']
for r, crop in enumerate(order, start=1):
    if crop is None: continue
    d = {x['outcome']: x for x in sel(A1, omitted=crop)}
    for c, o in enumerate(O3): set_cell('TA1', r, c + 1, f3(d[o]['est']) + star(d[o]['p']))
delete_row('TA1', 6)
# Table 2
grp = ['Treated, reference year', 'Treated, target years', 'Comparison, reference years', 'Comparison, target years']
for p0, var in [(2, 'area_ha'), (7, 'yield_kg10a'), (12, 'production_t')]:
    for k, g in enumerate(grp):
        d = sel(T2, variable=var, group=g)[0]
        vals = [f'{round(float(d[x])):,}' for x in ['mean', 'sd', 'min', 'max']] + [d['obs'], d['crops']]
        for c, v in enumerate(vals): set_cell('T2', p0 + k, c + 1, v)
# Table 9
for r0, var in [(1, 'ln_area'), (3, 'ln_yield'), (5, 'ln_production')]:
    d = sel(T9, variable=var)[0]
    set_cell('T9', r0, 1, f3(d['m_t'])); set_cell('T9', r0, 2, f3(d['m_c']))
    set_cell('T9', r0, 3, f3(d['diff'])); set_cell('T9', r0, 4, f3(d['std_diff']))
    set_cell('T9', r0 + 1, 1, f'({f3(d["sd_t"])})'); set_cell('T9', r0 + 1, 2, f'({f3(d["sd_c"])})')
set_cell('T9', 7, 1, sel(T9, variable='ln_area')[0]['n_t']); set_cell('T9', 7, 2, sel(T9, variable='ln_area')[0]['n_c'])
# Table 3 (timing): read from table3_timing.csv
T3 = {r['crop_id']: r for r in rd('table3_timing.csv')}
for r, crop in enumerate(['soybean', 'onion', 'sweet_potato', 'corn', 'garlic', None, 'red_pepper'], start=1):
    if crop is None: continue
    set_cell('T3', r, 2, T3[crop]['expansion_year_main']); set_cell('T3', r, 5, T3[crop]['transition_years_main'])
delete_row('T3', 6)
# Table 1: six crops in Panel B
set_cell('T1', 5, 0, 'Panel B. Six annual crops')
delete_row('T1', 10)

# ---------------- prose ----------------
m4 = {r['outcome']: r for r in sel(T4, design='main', spec='A. Full comparison pool')}
mB = {r['outcome']: r for r in sel(T4, design='main', spec='B. Excluding two spring series')}
pA, pY, pP = (f'{float(m4[o]["p"]):.2f}' for o in O3)
ciP = f'[{f3(m4["ln_production"]["ci_lo"])}, {f3(m4["ln_production"]["ci_hi"])}]'
eP = f3(m4['ln_production']['est'])
jm = {r['outcome']: r for r in J6 if r['design'] == 'main'}
wt = {r['crop_id']: 100 * float(r['weight']) for r in W6}

# Abstract and introduction
rep('I compare seven annual crops with crops for', 'I compare six annual crops with crops for')
rep('The mean production contrast across the seven crops is 0.020 log points, with an exploratory 95 percent interval of [−0.277, 0.317].',
    f'The mean production contrast across the six crops is {eP} log points, with an exploratory 95 percent interval of {ciP}.')
rep('I then compare seven annual crops with crops for', 'I then compare six annual crops with crops for')
rep('The national production contrast is 0.020 log points, but its sign changes', f'The national production contrast is {eP} log points, and its sign changes')
# Chapter 2
rep('among the seven annual crops examined in Chapter 5', 'among the six annual crops examined in Chapter 5')
# List of tables and Table 3 caption
for cap_lo in [m.start() for m in re.finditer(re.escape('Insurance Timing for the Seven Annual Crops'), s)][::-1]:
    rep('Insurance Timing for the Seven Annual Crops', 'Insurance Timing for the Six Annual Crops', max(0, cap_lo - 600), cap_lo + 200)
# 4.1
rep('Treated crops have roughly three times the cultivated area of comparison crops on average.',
    'Treated crops have more than three times the cultivated area of comparison crops on average.')
# 4.2 sample
rep('I select seven annual crops: soybean, onion, sweet potato, corn, garlic, spring potato, and red pepper. Each has a continuous series from 1991, an identified pilot year, and ten observed years following expansion.',
    'I select six annual crops: soybean, onion, sweet potato, corn, garlic, and red pepper. Each has a continuous series from 1991, a documented pilot year and first nationwide sales season, and ten observed years following expansion.')
insert_after('Autumn potato is excluded because its program milestones are not reported separately from those of other potato forms.',
    ' I also exclude spring potato. The product insured as spring potato from 2009 was a highland summer crop sold only in Pyeongchang through at least 2013 (Jeong & Choi, 2013, pp. 9-10), which corresponds to the separately reported highland potato series rather than to the lowland spring potato series used here. Lowland spring potato appears as a separately insured form only by 2020 and was sold in two provinces in 2023 (Kim et al., 2021, p. 33; Kook et al., 2024, p. 221), so its first year of coverage is undocumented and ten post-expansion years cannot be observed. For the same reason, I do not use it as a comparison crop.')
rep('The pilot marks the start of regional availability, while the coded expansion year marks the beginning of the ten target years.',
    'The pilot marks the start of regional availability, while the expansion year, the harvest year of the first documented nationwide sales season, marks the beginning of the ten target years.')
rep('I convert historical announcement dates to harvest years using recent sales calendars, which ', '')
rep('introduces uncertainty about timing. Spring potato was still restricted to selected regions in 2023-2024 (MAFRA, 2024, 2025). Its coded expansion year therefore does not indicate nationwide availability.',
    'Pilot seasons are confirmed by first-sale dates or first-year enrollment and indemnity records (Choi et al., 2010, p. 163; Kook et al., 2024, pp. 17-21). Nationwide sales began in 2011 for soybean and onion, in 2012 for sweet potato, corn, and garlic, and in 2014 for red pepper (Kook et al., 2024, p. 18; Ministry for Food, Agriculture, Forestry and Fisheries, 2011b, 2012; MAFRA, 2014). Onion and garlic are sold in autumn, so their nationwide sales in 2011 and 2012 cover the 2012 and 2013 harvests. For soybean, sweet potato, corn, and red pepper, the first nationwide season precedes the main-program date recorded in the yearbook by one harvest year.')
# Table 3 notes
rep('Pilot and expansion years follow the milestone sequence described in Section 2.2.',
    'Pilot and expansion years are the first harvest years covered by pilot and nationwide sales. An announcement applies to the same year’s crop if it precedes the end of that crop’s sales window and to the following year’s crop otherwise.')
rep('Data from MAFRA (2025, pp. 37, 44, 46).',
    'Data from MAFRA (2014, 2025, pp. 37, 44, 46), Choi et al. (2010, p. 163), Kook et al. (2024, pp. 17-21, 221), and Ministry for Food, Agriculture, Forestry and Fisheries (2011b, 2012).')
rep('All seven treated crops entered pilots by 2010, before the first target year in 2012.',
    'All six treated crops entered pilots by 2010, before the first target year in 2011.')
# 4.3
rep('average them across seven crops and ten target years', 'average them across six crops and ten target years')
rep('contrasts across seven crops and ten target years; multiplying', 'contrasts across six crops and ten target years; multiplying')
rep('I average the seven crop-specific contrasts equally.',
    'Comparison crops are drawn from the comparison pool; treated crops are not used as comparisons for one another before their pilots. I average the six crop-specific contrasts equally.')
# 4.4 citation year suffix
rep('Ministry for Food, Agriculture, Forestry and Fisheries, 2011)', 'Ministry for Food, Agriculture, Forestry and Fisheries, 2011a)')
# footnote (MDE)
se_p = float(m4['ln_production']['se'])
# 5.1
rep('Each point averages seven crop-specific contrasts', 'Each point averages six crop-specific contrasts')
pre = {o: [(int(r['event_time']), float(r['est'])) for r in rd('fig6_event_time.csv') if r['design'] == 'main' and r['outcome'] == o and -10 <= int(r['event_time']) <= -2] for o in O3}
ylo, yhi = min(v for _, v in pre['ln_yield']), max(v for _, v in pre['ln_yield'])
rep('Pre-pilot yield contrasts range from approximately −0.04 to 0.03 log points.',
    f'Pre-pilot yield contrasts range from approximately {mn(f"{ylo:.2f}")} to {yhi:.2f} log points.')
rep('(p = 0.88). With only seven treated crops', f'(p = {float(jm["ln_yield"]["p"]):.2f}). With only six treated crops')
rep('The exploratory joint p-values are 0.06 for area and 0.03 for production. Only production meets the stated 5 percent threshold, but both trajectories matter for comparability.',
    f'The exploratory joint p-values are {float(jm["ln_area"]["p"]):.2f} for area and {float(jm["ln_production"]["p"]):.2f} for production. The production value, {float(jm["ln_production"]["p"]):.4f} before rounding, lies at the stated 5 percent threshold and falls below it under some sets of multiplier draws; both trajectories matter for comparability.')
rep('averaged over the seven treated crops.', 'averaged over the six treated crops; comparison crops exclude the other treated crops.')
# 5.2
rep(': Log outcomes; seven treated crops; ten target years. Target years', ': Log outcomes; six treated crops; ten target years. Target years')
rep('Using the full pool, I obtain mean contrasts of 0.048 log points for area, −0.028 for yield, and 0.020 for production, with respective p-values of 0.73, 0.61, and 0.90.',
    f'Using the full pool, I obtain mean contrasts of {f3(m4["ln_area"]["est"])} log points for area, {f3(m4["ln_yield"]["est"])} for yield, and {eP} for production, with respective p-values of {pA}, {pY}, and {pP}.')
rep('Excluding the two spring series changes the contrasts to −0.041, −0.032, and −0.074. Area and production reverse sign, while yield changes little.',
    f'Excluding the two spring series changes the contrasts to {f3(mB["ln_area"]["est"])}, {f3(mB["ln_yield"]["est"])}, and {f3(mB["ln_production"]["est"])}. Area reverses sign and production moves further below zero, while yield changes little. With the seven crops and yearbook dates used before the timing was verified, the full-pool contrasts are 0.048, −0.028, and 0.020 (Table 5, Panel H).')
lo_, hi_ = float(m4['ln_production']['ci_lo']), float(m4['ln_production']['ci_hi'])
rep('approximately [−0.28, 0.32] log points', f'approximately [{mn(f"{lo_:.2f}")}, {hi_:.2f}] log points')
cm = {r['crop_id']: float(r['est']) for r in F7 if r['pool'] == 'Full comparison pool' and r['outcome'] == 'ln_production'}
rep('Production contrasts are 0.406 for onion, 0.193 for spring potato, and −0.651 for red pepper. Under equal weights, these crops contribute approximately 0.058, 0.028, and −0.093 log points, respectively.',
    f'Production contrasts are {cm["onion"]:.3f} for onion, {cm["sweet_potato"]:.3f} for sweet potato, and {f3(cm["red_pepper"])} for red pepper. Under equal weights, these crops contribute approximately {cm["onion"]/6:.3f}, {cm["sweet_potato"]/6:.3f}, and {f3(cm["red_pepper"]/6)} log points, respectively.')
la = [float(r['est']) for r in A1 if r['outcome'] == 'ln_production']
rep('moves the aggregate between −0.044 and 0.132', f'moves the aggregate between {f3(min(la))} and {max(la):.3f}')
# 5.3
rep(': Log outcomes; seven treated crops; ten target years; full comparison pool unless stated.',
    ': Log outcomes; six treated crops (seven in Panel H); ten target years; full comparison pool unless stated.')
rep('F starts the ten target years at the pilot year rather than the coded expansion year.',
    'F starts the ten target years at the pilot year rather than the expansion year. Panel G dates expansion by the main-program years recorded in the yearbook. Panel H reproduces the earlier specification with seven crops, yearbook dates, and spring potato dated 2008 (pilot) and 2013 (expansion).')
g5 = lambda sp, o: [r for r in T5 if r['spec'][0] == sp and r['outcome'] == o][0]
pmin = min(T5, key=lambda r: float(r['p']))
rep('The smallest p-value is 0.144, for area when all pre-pilot years form the reference.',
    f'The smallest p-value is {float(pmin["p"]):.3f}, for area when all pre-pilot years form the reference.')
rep('Earlier reference periods raise the production contrast to 0.067 and 0.228.',
    f'Earlier reference periods raise the production contrast to {f3(g5("A", "ln_production")["est"])} and {f3(g5("B", "ln_production")["est"])}.')
rep('Restricting the comparison pool lowers the production contrast to −0.091 or −0.105.',
    f'Restricting the comparison pool lowers the production contrast to {f3(g5("C", "ln_production")["est"])} or {f3(g5("D", "ln_production")["est"])}.')
tim = [float(g5(k, 'ln_production')['est']) for k in 'EFG']
rep('Alternative timing definitions produce smaller changes, to 0.036 and 0.017.',
    f'Alternative timing definitions change the production contrast little, to between {f3(min(tim))} and {f3(max(tim))}; the earlier seven-crop specification gives {f3(sel(T4, design="S2", spec="A. Full comparison pool")[2]["est"])} (Panel H).')
ses = [float(r['se']) for r in T5 if r['outcome'] != 'ln_yield']
rep('Standard errors for area and production range from 0.11 to 0.24', f'Standard errors for area and production range from {min(ses):.2f} to {max(ses):.2f}')
a6 = {r['outcome']: r for r in T6 if r['spec'][0] == 'A'}; b6 = {r['outcome']: r for r in T6 if r['spec'][0] == 'B'}
rep('The production contrast falls from 0.020 to −0.093 with the full comparison pool and from −0.074 to −0.185 after excluding the two spring series.',
    f'The production contrast falls from {eP} to {f3(a6["ln_production"]["est"])} with the full comparison pool and from {f3(mB["ln_production"]["est"])} to {f3(b6["ln_production"]["est"])} after excluding the two spring series.')
rep('Soybean and red pepper account for 61 percent of these weights. Onion and spring potato, which have positive contrasts, receive less weight.',
    f'Soybean and red pepper account for {round(wt["soybean"] + wt["red_pepper"])} percent of these weights. Onion and sweet potato, which have positive contrasts, receive less weight.')
names = {'soybean': 'soybean', 'red_pepper': 'red pepper', 'garlic': 'garlic', 'sweet_potato': 'sweet potato', 'corn': 'corn', 'onion': 'onion'}
ws = sorted(wt.items(), key=lambda kv: -kv[1])
wtxt = ', '.join(f'{names[k]} {v:.1f}' for k, v in ws[:-1]) + f', and {names[ws[-1][0]]} {ws[-1][1]:.1f} percent; equal weights are {100/6:.1f} percent.'
rep('Area weights are soybean 36.6, red pepper 24.1, garlic 12.6, sweet potato 7.2, corn 6.8, onion 6.5, and spring potato 6.3 percent; equal weights are 14.3 percent.',
    'Area weights are ' + wtxt)
# 5.5
d9 = {r['variable']: r for r in T9}
r2 = lambda x: mn(f'{float(x):.2f}')
rep('Across the seven treated and 22 contributing comparison crops, mean log-area slopes were −0.015 and −0.046 per year, respectively. Mean production slopes were −0.005 and −0.031. Yield slopes were closer, at 0.010 and 0.015. The standardized differences are 0.87 for area, 0.71 for production, and −0.31 for yield.',
    f'Across the six treated and {d9["ln_area"]["n_c"]} contributing comparison crops, mean log-area slopes were {f3(d9["ln_area"]["m_t"])} and {f3(d9["ln_area"]["m_c"])} per year, respectively. Mean production slopes were {f3(d9["ln_production"]["m_t"])} and {f3(d9["ln_production"]["m_c"])}. Yield slopes were closer, at {f3(d9["ln_yield"]["m_t"])} and {f3(d9["ln_yield"]["m_c"])}. The standardized differences are {r2(d9["ln_area"]["std_diff"])} for area, {r2(d9["ln_production"]["std_diff"])} for production, and {r2(d9["ln_yield"]["std_diff"])} for yield.')
# Chapter 7
rep('Across seven annual crops, the mean production contrast is 0.020 log points, with an exploratory 95 percent interval of [−0.277, 0.317].',
    f'Across six annual crops, the mean production contrast is {eP} log points, with an exploratory 95 percent interval of {ciP}.')
# Appendix A1 notes
rep('Log-point contrasts with six treated crops, the full comparison pool', 'Log-point contrasts with five treated crops, the full comparison pool')


# ---------------- references ----------------
I = '<w:rPr><w:i/><w:iCs/></w:rPr>'
def para_bounds(key):
    i = s.find(esc(key)); assert i > 0 and s.find(esc(key), i + 1) < 0, key
    return s.rfind('<w:p ', 0, i), s.find('</w:p>', i) + 6
def insert_ref_after(key, parts):
    global s
    a, b = para_bounds(key)
    ppr = re.search(r'<w:pPr>.*?</w:pPr>', s[a:b], re.S).group(0).replace('</w:pPr>', f'<w:rPr><w:ins {attrs()}/></w:rPr></w:pPr>')
    body = ''.join(ins_run(I if it else '', t) for t, it in parts)
    s = s[:b] + f'<w:p>{ppr}{body}</w:p>' + s[b:]
    LOG.append(('', ''.join(t for t, _ in parts)[:80], 'reference added'))
def delete_para(key):
    global s
    a, b = para_bounds(key)
    x = s[a:b]
    x = RUN.sub(lambda m: del_run(m.group(1), html.unescape(m.group(2))), x)
    x = x.replace('</w:pPr>', f'<w:rPr><w:del {attrs()}/></w:rPr></w:pPr>', 1)
    s = s[:a] + x + s[b:]
    LOG.append((key, '', 'reference deleted'))

rep('Ministry for Food, Agriculture, Forestry and Fisheries. (2011). Rice disaster', 'Ministry for Food, Agriculture, Forestry and Fisheries. (2011a). Rice disaster')
insert_ref_after('insurance goes on sale from', [
    ('Ministry for Food, Agriculture, Forestry and Fisheries. (2011b). Soybean disaster insurance enrollment period extended [Press release]. https://www.korea.kr/briefing/pressReleaseView.do?newsId=155771961', False)])
insert_ref_after('Soybean disaster insurance enrollment period extended', [
    ('Ministry for Food, Agriculture, Forestry and Fisheries. (2012). Rice insurance expanded nationwide; farmers pay 20-30 percent of premiums [Press release]. https://www.korea.kr/news/policyNewsView.do?newsId=148732398', False)])
insert_ref_after('Rice insurance expanded nationwide; farmers pay', [
    ('Ministry of Agriculture, Food and Rural Affairs. (2014). Make use of crop disaster insurance for worry-free farming [Press release]. https://www.korea.kr/briefing/pressReleaseView.do?newsId=155956185', False)])
delete_para('Ministry of Agriculture, Food and Rural Affairs. (2024). ')
insert_ref_after('Hazell, P., Sberro-Kessler, R., &amp; Varangis, P. (2017).'.replace('&amp;', '&'), [
    ('Jeong, W. H., & Choi, K. H. (2013). ', False),
    ('Expanding the agricultural and fishery disaster reinsurance fund and securing stable financing', True),
    (' (Research Report C2013-29). Korea Rural Economic Institute. https://www.krei.re.kr/attach/pdf/605ba745-af00-2a94-e054-b09928988b3c.pdf', False)])
insert_ref_after('Kang, S., & Chung, W. (2017).', [
    ('Kim, T. H., Kim, M. B., & Jeong, W. S. (2021). ', False),
    ('Improving the efficiency of crop disaster insurance', True),
    (' (Research Report C2021-19). Korea Rural Economic Institute. https://www.krei.re.kr/attach/pdf/4fa8a92b-4019-45e9-923f-4f4da057cef1.pdf', False)])
insert_ref_after('Improving the efficiency of crop disaster insurance', [
    ('Kook, S. Y., Kim, M. B., Kim, T. H., Joo, J. Y., Choi, H. D., Kim, D. Y., & Kim, S. H. (2024). ', False),
    ('Improving the operating system of crop disaster insurance', True),
    (' (Research Report C2023-57). Korea Rural Economic Institute. https://www.krei.re.kr/attach/pdf/e4c5e193-861e-411d-b126-f20caf797a9c.pdf', False)])

# ---------------- equations (5)-(6): 7 -> 6 ----------------
MR = re.compile(r'<m:r>((?:<w:rPr>(?:(?!</w:rPr>).)*</w:rPr>)?)<m:t>7</m:t></m:r>')
for anchor in ['θ', ]:
    pass
eqs = [m for m in re.finditer(r'<m:oMath>.*?</m:oMath>', s, re.S)
       if re.search(r'<m:t>[^<]*θ', m.group(0)) and len(MR.findall(m.group(0))) == 2]
assert len(eqs) == 2, len(eqs)
for m in reversed(eqs):
    x = MR.sub(lambda r: f'<w:del {attrs()}>{r.group(0)}</w:del><w:ins {attrs()}><m:r>{r.group(1)}<m:t>6</m:t></m:r></w:ins>', m.group(0))
    s = s[:m.start()] + x + s[m.end():]
LOG.append(('equations (5)-(6)', '7 -> 6', 'math'))

open(DOC, 'w', encoding='utf-8').write(s)
# footnotes.xml: minimum detectable effect footnote
FN = DOC.replace('document.xml', 'footnotes.xml')
s = open(FN, encoding='utf-8').read()
s = s.replace('<w:lastRenderedPageBreak/>', '')
s = re.sub(r'</w:t><w:t(?: xml:space="preserve")?>', '', s).replace('<w:t>', '<w:t xml:space="preserve">')
rep('(0.159 for the national production contrast and 0.022', f'({se_p:.3f} for the national production contrast and 0.022')
rep('approximately 0.45 and 0.06 log points', f'approximately {2.8016 * se_p:.2f} and 0.06 log points')
open(FN, 'w', encoding='utf-8').write(s)
print(len(LOG), 'edits')
for o, n, k in LOG: print('-', k, '|', o[:70], '=>', n[:90])
