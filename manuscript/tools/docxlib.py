import re
CAPS = {
 'T1': 'Enrollment and Loss Ratios for Selected Crops, 2023',
 'T2': 'Summary Statistics',
 'T3': 'Insurance Timing for the Seven Annual Crops',
 'T4': 'Mean Post-Period Contrasts',
 'T5': 'Sensitivity to the Reference Period, Comparison Crops, and Timing',
 'T6': 'Contrasts under Pre-Pilot Area Weights',
 'T9': 'Pre-Pilot Growth of Treated and Comparison Crops, 1998-2007',
 'TA1': 'Leave-One-Crop-Out Contrasts',
}
def find_table(s, cap):
    best = None
    for m in re.finditer(re.escape(cap), s):
        t = s.find('<w:tbl>', m.end())
        if t < 0: continue
        if best is None or t - m.end() < best[1]: best = (t, t - m.end())
    t = best[0]
    # tables are not nested here
    e = s.find('</w:tbl>', t) + len('</w:tbl>')
    return t, e
def rows(tbl):
    return [m for m in re.finditer(r'<w:tr[ >].*?</w:tr>', tbl, re.S)]
def cells(tr):
    return [m for m in re.finditer(r'<w:tc>.*?</w:tc>', tr, re.S)]
def text(x):
    return ''.join(re.findall(r'<w:t(?: [^>]*)?>([^<]*)</w:t>', x))
