import re, html, sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
s = s.replace('<w:lastRenderedPageBreak/>', '')
s = re.sub(r'</w:t><w:t(?: xml:space="preserve")?>', '', s)
AUTH, DATE = 'Claude', '2026-10-22T09:00:00Z'
_id = [95000]
def at():
    _id[0] += 1; return f'w:id="{_id[0]}" w:author="{AUTH}" w:date="{DATE}"'
esc = lambda x: html.escape(x, quote=False)
RUN = re.compile(r'<w:r>((?:<w:rPr>(?:(?!</w:rPr>).)*</w:rPr>)?)<w:t(?: [^>]*)?>([^<]*)</w:t></w:r>', re.S)
def rep(old, new):
    global s
    hits = [m for m in RUN.finditer(s) if esc(old) in m.group(2)]
    assert len(hits) == 1, (len(hits), old[:60])
    m = hits[0]; rpr, txt = m.group(1), html.unescape(m.group(2)); i = txt.index(old)
    run = lambda x: f'<w:r>{rpr}<w:t xml:space="preserve">{esc(x)}</w:t></w:r>' if x else ''
    x = run(txt[:i]) + f'<w:del {at()}><w:r>{rpr}<w:delText xml:space="preserve">{esc(old)}</w:delText></w:r></w:del>' \
        + f'<w:ins {at()}><w:r>{rpr}<w:t xml:space="preserve">{esc(new)}</w:t></w:r></w:ins>' + run(txt[i + len(old):])
    s = s[:m.start()] + x + s[m.end():]
rep('Potato series are excluded where a consistent match between crop form and insurance timing has not been established. '
    'In particular, the early potato products covered highland summer and autumn potatoes, while ordinary spring potatoes were initially excluded (Gouk et al., 2024, pp. 17–18). '
    'I therefore do not assign the generic potato introduction date to the ordinary spring-potato series or use that series as a comparison crop.',
    'The three potato series do not meet these criteria. Potato insurance initially covered highland summer and autumn potatoes but not lowland spring potatoes (Gouk et al., 2024, pp. 17–18). '
    'Highland potato insurance has remained limited to Gangwon Province, and the first nationwide sales season of autumn potato is not reported separately from the general potato milestones (Gouk et al., 2024, p. 221). '
    'For lowland spring potato, the year in which coverage began is not documented, so I use this series neither as a treated crop nor as a comparison crop.')
rep(' begin with the coded expansion year, whereas Figure 6', ' begin with the expansion year, whereas Figure 6')
open(p, 'w', encoding='utf-8').write(s)
print('ok')
