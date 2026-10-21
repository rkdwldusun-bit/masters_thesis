import re, sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
# rows and paragraphs that are deleted as a whole
s = re.sub(r'<w:tr[ >](?:(?!</w:tr>).)*?<w:trPr>(?:(?!</w:trPr>).)*?<w:del [^>]*/>(?:(?!</w:tr>).)*</w:tr>', '', s, flags=re.S)
s = re.sub(r'<w:p[ >](?:(?!</w:p>).)*?<w:pPr>(?:(?!</w:pPr>).)*?<w:rPr><w:del [^>]*/></w:rPr></w:pPr>(?:(?!</w:p>).)*</w:p>', '', s, flags=re.S)
s = re.sub(r'<w:del [^>]*>.*?</w:del>', '', s, flags=re.S)          # deleted runs
s = re.sub(r'<w:ins [^>]*/>', '', s)                                 # insertion marks on rows/paragraphs
s = re.sub(r'<w:ins [^>]*>(.*?)</w:ins>', r'\1', s, flags=re.S)       # inserted runs
s = s.replace('<w:rPr></w:rPr>', '')
assert '<w:del ' not in s and '<w:ins ' not in s
open(p, 'w', encoding='utf-8').write(s)
