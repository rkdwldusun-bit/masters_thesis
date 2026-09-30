import re
from lxml import etree
NS={'ss':'urn:schemas-microsoft-com:office:spreadsheet'}
def read(path):
    raw=open(path,'rb').read()
    raw=re.sub(rb'^\s+',b'',raw)
    raw=raw.replace(b'encoding="EUC-KR"',b'encoding="CP949"')
    parser=etree.XMLParser(recover=True,huge_tree=True)
    root=etree.fromstring(raw,parser)
    out={}
    for ws in root.findall('.//ss:Worksheet',NS):
        name=ws.get('{urn:schemas-microsoft-com:office:spreadsheet}Name')
        rows=[]
        for r in ws.findall('.//ss:Row',NS):
            row={};ci=0
            for c in r.findall('ss:Cell',NS):
                idx=c.get('{urn:schemas-microsoft-com:office:spreadsheet}Index')
                if idx: ci=int(idx)-1
                d=c.find('ss:Data',NS)
                v=d.text if d is not None else None
                ma=int(c.get('{urn:schemas-microsoft-com:office:spreadsheet}MergeAcross') or 0)
                for k in range(ma+1): row[ci+k]=v
                ci+=ma+1
            rows.append(row)
        n=max((max(r) for r in rows if r),default=-1)+1
        out[name]=[[r.get(i) for i in range(n)] for r in rows]
    return out
