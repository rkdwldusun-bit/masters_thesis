import re, sys
p = sys.argv[1] + '/word/document.xml'; s = open(p, encoding='utf-8').read()
for rid, cx, ratio in [('rId16', 4933950, 1.0), ('rId17', 5669280, 1350 / 2400)]:
    i = s.find(f'r:embed="{rid}"'); a = s.rfind('<w:drawing>', 0, i); b = s.find('</w:drawing>', i)
    cy = round(cx * ratio); seg = s[a:b]
    seg = re.sub(r'(<wp:extent cx="%d" cy=")\d+(")' % cx, r'\g<1>%d\2' % cy, seg)
    seg = re.sub(r'(<a:ext cx="%d" cy=")\d+(")' % cx, r'\g<1>%d\2' % cy, seg)
    s = s[:a] + seg + s[b:]
def anchor(key, cid):
    global s
    i = [m.start() for m in re.finditer(re.escape(key), s)][-1]
    a = max(s.rfind('<w:p ', 0, i), s.rfind('<w:p>', 0, i)); b = s.find('</w:p>', i)
    pe = s.find('</w:pPr>', a, b); start = pe + 8 if pe > 0 else s.find('>', a) + 1
    s = s[:b] + f'<w:commentRangeEnd w:id="{cid}"/><w:r><w:rPr><w:rStyle w:val="CommentReference"/></w:rPr><w:commentReference w:id="{cid}"/></w:r>' + s[b:]
    s = s[:start] + f'<w:commentRangeStart w:id="{cid}"/>' + s[start:]
anchor('Event-Time Contrasts for Cultivated Area, Yield, and Production', 11)
anchor('Mean Contrasts by Treated Crop', 12)
anchor('Jeong, W. H., &amp; Choi, K. H. (2013).', 13)
anchor('Pilot and expansion years are the first harvest years covered', 14)

# Table 5 now spans two pages: repeat only the column-header row, not the Panel A heading
import sys as _s; _s.path.insert(0, __file__.rsplit('/', 1)[0])
from docxlib import find_table, rows
a, b = find_table(s, 'Sensitivity to the Reference Period, Comparison Crops, and Timing')
r1 = rows(s[a:b])[1]
x = r1.group(0).replace('<w:tblHeader/>', '', 1)
s = s[:a + r1.start()] + x + s[a + r1.end():]
open(p, 'w', encoding='utf-8').write(s)
