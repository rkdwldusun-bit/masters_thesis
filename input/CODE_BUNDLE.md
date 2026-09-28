# Chapter 5 Code Bundle

This file concatenates the **current/final Chapter 5 analysis scripts** for transfer to Claude Code under a five-file upload limit.\n
## Integrity and usage notes

- Source directory at bundling time: `/mnt/data`.
- The three presentation scripts (`04_figures`, `05_apfs_descriptives`, `06_final_tables`) are the post-terminology-revision versions.
- `01_build_panel`, `02_build_prices`, `03_estimate`, and `est_engine` were unchanged in the final terminology revision.
- Raw source files are **not embedded** in this Markdown file; see `DATA_BUNDLE.xlsx` and the source manifest in `DOCUMENTATION.md`.
- Do not assume the code is correct merely because it is reproducible; the intended next step is an independent forensic/R audit.

## Included files

- `01_build_panel(1).py` — SHA-256 `e45b5001dd4f0340d610828233a0fb2341a78d5ab06b1b9231f26a4bd681d0ee`
- `02_build_prices(1).py` — SHA-256 `097a74da90c1fa126fe44e529ba407af61cd38151294ba751546dc204774f7c5`
- `est_engine(1).py` — SHA-256 `87fb3c7782ae62e9e8551596e350480807f9f357f02159369054e8ed6cf2e064`
- `03_estimate(1).py` — SHA-256 `a3aff0c7ae2defc7ce9421b4ebb0ebcfb645928a049d8d41756c94127fd731f0`
- `04_figures(1).py` — SHA-256 `d85060928bf1f74a0c94196c4e6179ec0f6a712453a25c69648347b7c09c42db`
- `05_apfs_descriptives(1).py` — SHA-256 `f4e551058fe5645255b44accf8ddcf8958ad5a95cc6f8dcf6aecf4c1f56633bc`
- `06_final_tables(1).py` — SHA-256 `8a5e3fcd60d5f3a63422e30bd37a5a0dca2a8ca3fb0f275a2f95857659687a25`
- `run_all(4).sh` — SHA-256 `8a1f430b8e82b50ccc5d0498be1ad3b22c8639b8d36a163ee95185baef74372b`

---

# FILE: 01_build_panel(1).py

```python
# -*- coding: utf-8 -*-
"""
build_ch5_panel.py — reproducible construction of the Chapter 5 national crop x year panel.
Reads raw KOSIS files from RAW (unchanged) and writes analysis files to OUT.
No regression is estimated here.
"""
import re, os, json, warnings
import numpy as np, pandas as pd
from lxml import etree
warnings.filterwarnings("ignore")
RAW = "/mnt/user-data/uploads/"
OUT = "/mnt/user-data/outputs/ch5_v2/"
YEAR_MIN, YEAR_MAX = 1980, 2024          # panel range; estimation window chosen later
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- 1. raw readers
NS = {'ss': 'urn:schemas-microsoft-com:office:spreadsheet'}
def read_spreadsheetml(path):
    """KOSIS '.xls' exports that are SpreadsheetML-2003 XML (EUC-KR)."""
    raw = re.sub(rb'^\s+', b'', open(path, 'rb').read()).replace(b'encoding="EUC-KR"', b'encoding="CP949"')
    root = etree.fromstring(raw, etree.XMLParser(recover=True, huge_tree=True))
    out = {}
    for ws in root.findall('.//ss:Worksheet', NS):
        rows = []
        for r in ws.findall('.//ss:Row', NS):
            row, ci = {}, 0
            for c in r.findall('ss:Cell', NS):
                idx = c.get('{%s}Index' % NS['ss'])
                if idx: ci = int(idx) - 1
                d = c.find('ss:Data', NS)
                ma = int(c.get('{%s}MergeAcross' % NS['ss']) or 0)
                for k in range(ma + 1): row[ci + k] = d.text if d is not None else None
                ci += ma + 1
            rows.append(row)
        n = max((max(r) for r in rows if r), default=-1) + 1
        out[ws.get('{%s}Name' % NS['ss'])] = [[r.get(i) for i in range(n)] for r in rows]
    return out

def split_item(s):
    s = str(s).strip()
    m = re.match(r'(.*):(.*?)\s*[\(\[]([^\)\]]*)[\)\]]\s*$', s)
    return (m.group(1).strip(), m.group(2).strip(), m.group(3).strip()) if m else (s, '', '')

def num(v):
    if v is None: return np.nan
    s = str(v).strip().replace(',', '')
    try: return float(s)
    except ValueError: return np.nan

def read_kosis(fname):
    """Return long df: file, table_id, table_name, region1, region2, crop_label, variable, unit, year, raw, value."""
    recs, meta = [], {}
    if open(RAW + fname, 'rb').read(200).lstrip().startswith(b'<?xml'):
        d = read_spreadsheetml(RAW + fname)
        for r in d.get('메타정보', []):
            if r and r[0] and len(r) > 1: meta[str(r[0]).strip()] = r[1]
        rows = d['데이터']; hdr = rows[1]
        ycols = [(i, int(str(h)[:4])) for i, h in enumerate(hdr) if h and re.match(r'\d{4}', str(h))]
        reg = None
        for r in rows[2:]:
            if r[0]: reg = r[0].strip()
            if not r[1]: continue
            crop, var, unit = split_item(r[1])
            for i, y in ycols: recs.append((reg, '', crop, var, unit or (r[2] or ''), y, r[i]))
    else:
        x = pd.read_excel(RAW + fname, sheet_name=None, header=None)
        for _, r in x['메타정보'].iterrows():
            if isinstance(r[0], str): meta[r[0].strip()] = r[1]
        dat = x['데이터']
        two = str(dat.iloc[0, 1]).startswith('시도별')
        start = 2 if two else 1; reg1 = None
        for ri in range(2, len(dat)):
            if isinstance(dat.iloc[ri, 0], str): reg1 = dat.iloc[ri, 0].strip()
            r2 = str(dat.iloc[ri, 1]).strip() if two else ''
            for ci in range(start, dat.shape[1]):
                crop, var, unit = split_item(dat.iloc[1, ci])
                recs.append((reg1, r2, crop, var, unit, int(str(dat.iloc[0, ci])[:4]), dat.iloc[ri, ci]))
    df = pd.DataFrame(recs, columns=['region1', 'region2', 'crop_label', 'variable', 'unit', 'year', 'raw'])
    df['value'] = df['raw'].map(num)
    tid = next((str(v) for k, v in meta.items() if '통계표ID' in k), '')
    tname = next((str(v) for k, v in meta.items() if '통계표명' in k), '')
    df.insert(0, 'table_name', tname); df.insert(0, 'table_id', tid); df.insert(0, 'file', fname)
    return df, meta

PROD_FILES = ['01_fruit_total.xls', '02_fruit_bearing.xlsx', '03_rice.xlsx', '04_beans.xlsx',
              '05_coarse_grains.xlsx', '06_potatoes.xlsx', '07_barely.xlsx', '08_vegetables_root.xls',
              '09_vegetables_leafy.xls', '10_vegetables_spices.xls', '13_특용작물생산량__땅콩_.xlsx']
L, METAS = [], {}
for f in PROD_FILES:
    d, m = read_kosis(f); L.append(d); METAS[f] = m
L = pd.concat(L, ignore_index=True)
NAT = L[L.region1.isin(['계', '전국']) & L.region2.isin(['', '소계'])].copy()

# ---------------------------------------------------------------- 2. crop crosswalk (national series)
# crop_id, English name (thesis terminology), Korean, form, group, perennial, table_id, KOSIS crop label for area/yield, label for production
XW = [
 # crop_id, crop_en_display, crop_ko_official, crop_form, crop_group, perennial, table_id, kosis_production_label_original, kosis_prod_label
 ('apple','Apple','사과','total','fruit',1,'DT_1ET0292','사과','사과'),
 ('pear','Pear','배','total','fruit',1,'DT_1ET0292','배','배'),
 ('sweet_persimmon','Sweet persimmon','단감','total','fruit',1,'DT_1ET0292','단감','단감'),
 ('astringent_persimmon','Astringent persimmon','떫은감','total','fruit',1,'DT_1ET0292','떫은감','떫은감'),
 ('tangerine','Tangerine','감귤','total','fruit',1,'DT_1ET0292','감귤','감귤'),
 ('peach','Peach','복숭아','total','fruit',1,'DT_1ET0292','복숭아','복숭아'),
 ('grape','Grape','포도','total','fruit',1,'DT_1ET0292','포도','포도'),
 ('plum','Plum','자두','total','fruit',1,'DT_1ET0292','자두','자두'),
 ('green_plum','Green plum','매실','total','fruit',1,'DT_1ET0292','매실','매실'),
 ('rice','Rice','벼','paddy','grain',0,'DT_1ET0222','논벼','논벼:조곡'),
 ('soybean','Soybean','콩','all','pulse',0,'DT_1ET0025','콩','콩'),
 ('red_bean','Red bean','팥','all','pulse',0,'DT_1ET0025','팥','팥'),
 ('mung_bean','Mung bean','녹두','all','pulse',0,'DT_1ET0025','녹두','녹두'),
 ('other_pulses','Other pulses','기타두류','all','pulse',0,'DT_1ET0025','기타두류','기타두류'),
 ('corn','Corn','옥수수','all','grain',0,'DT_1ET0024','옥수수','옥수수'),
 ('sweet_potato','Sweet potato','고구마','all','tuber',0,'DT_1ET0026','고구마','고구마'),
 ('spring_potato','Spring potato','봄감자','spring','tuber',0,'DT_1ET0026','일반봄감자','일반봄감자'),
 ('highland_potato','Highland potato','고랭지감자','highland','tuber',0,'DT_1ET0026','고랭지감자','고랭지감자'),
 ('autumn_potato','Autumn potato','가을감자','autumn','tuber',0,'DT_1ET0026','가을감자','가을감자'),
 ('barley','Barley','보리','hulled+naked','grain',0,'DT_1ET0231','겉보리,쌀보리','겉보리,쌀보리'),
 ('malting_barley','Malting barley','맥주보리','malting','grain',0,'DT_1ET0231','맥주보리','맥주보리'),
 ('wheat','Wheat','밀','all','grain',0,'DT_1ET0231','밀','밀'),
 ('spring_radish','Spring radish','봄무','spring','vegetable',0,'DT_1ET0029','일반봄무','일반봄무'),
 ('highland_radish','Highland radish','고랭지무','highland','vegetable',0,'DT_1ET0029','고랭지무','고랭지무'),
 ('autumn_radish','Autumn radish','가을무','autumn','vegetable',0,'DT_1ET0029','노지가을무','노지가을무'),
 ('winter_radish','Winter radish','월동무','winter','vegetable',0,'DT_1ET0029','노지겨울무','노지겨울무'),
 ('carrot','Carrot','당근','all','vegetable',0,'DT_1ET0029','당근','당근'),
 ('spring_napa','Spring napa cabbage','봄배추','spring','vegetable',0,'DT_1ET0028','일반봄배추','일반봄배추'),
 ('highland_napa','Highland napa cabbage','고랭지배추','highland','vegetable',0,'DT_1ET0028','고랭지배추','고랭지배추'),
 ('autumn_napa','Autumn napa cabbage','가을배추','autumn','vegetable',0,'DT_1ET0028','노지가을배추','노지가을배추'),
 ('winter_napa','Winter napa cabbage','월동배추','winter','vegetable',0,'DT_1ET0028','노지겨울배추','노지겨울배추'),
 ('cabbage','Cabbage','양배추','all','vegetable',0,'DT_1ET0028','양배추','양배추'),
 ('spinach','Spinach','시금치','open-field','vegetable',0,'DT_1ET0028','노지시금치','노지시금치'),
 ('leaf_lettuce','Leaf lettuce','상추','open-field','vegetable',0,'DT_1ET0028','노지상추','노지상추'),
 ('red_pepper','Red pepper','고추','open-field (dried)','vegetable',0,'DT_1ET0291','건고추','건고추'),
 ('large_green_onion','Large green onion','대파','open-field','vegetable',0,'DT_1ET0291','노지대파','노지대파'),
 ('small_green_onion','Small green onion','쪽파','open-field','vegetable',0,'DT_1ET0291','노지쪽파','노지쪽파'),
 ('onion','Onion','양파','all','vegetable',0,'DT_1ET0291','양파','양파'),
 ('garlic','Garlic','마늘','all','vegetable',0,'DT_1ET0291','마늘','마늘'),
 ('ginger','Ginger','생강','all','vegetable',0,'DT_1ET0291','생강','생강'),
 ('sesame','Sesame','참깨','all','special',0,'DT_1ET0293','참깨','참깨'),
 ('perilla','Perilla','들깨','all','special',0,'DT_1ET0293','들깨','들깨'),
 ('peanut','Peanut','땅콩','all','special',0,'DT_1ET0293','땅콩','땅콩'),
]
XW = pd.DataFrame(XW, columns=['crop_id','crop_en_display','crop_ko_official','crop_form','crop_group','perennial','table_id','kosis_label','kosis_prod_label'])
XW['kosis_production_label_original'] = XW.kosis_label

def series(tid, label, var_prefix):
    s = NAT[(NAT.table_id == tid) & (NAT.crop_label == label) & (NAT.variable.str.startswith(var_prefix))]
    return s.set_index('year')[['value', 'raw', 'file']]

rows, droplog = [], []
for _, c in XW.iterrows():
    a = series(c.table_id, c.kosis_label, '면적'); y = series(c.table_id, c.kosis_label, '10a당')
    prod_var = '생산량' if c.crop_id != 'rice' else '생산량'
    p = series(c.table_id, c.kosis_prod_label, prod_var)
    b = series('DT_1ET0296', c.kosis_label, '면적') if c.perennial else None
    for yr in range(YEAR_MIN, YEAR_MAX + 1):
        r = dict(crop_id=c.crop_id, year=yr)
        r['area_raw'] = a.value.get(yr, np.nan); r['yield_raw'] = y.value.get(yr, np.nan); r['prod_raw'] = p.value.get(yr, np.nan)
        r['bearing_area_raw'] = b.value.get(yr, np.nan) if b is not None else np.nan
        r['source_file'] = (a.file.iloc[0] if len(a) else '') + ('; 02_fruit_bearing.xlsx' if c.perennial else '')
        rows.append(r)
P = pd.DataFrame(rows).merge(XW, on='crop_id')

# zero / missing rule: national totals of 0 or '-' are treated as 'not reported'
for col in ['area_raw', 'yield_raw', 'prod_raw', 'bearing_area_raw']:
    z = P[col] <= 0
    for _, r in P[z].iterrows(): droplog.append((r.crop_id, r.year, col, r[col], 'national value <= 0 recoded to missing (series not reported)'))
    P.loc[z, col] = np.nan

P['production_t'] = P.prod_raw
P['area_ha'] = np.where(P.perennial == 0, P.area_raw, np.nan)
P['total_orchard_area_ha'] = np.where(P.perennial == 1, P.area_raw, np.nan)
P['bearing_area_ha'] = P.bearing_area_raw
P['yield_kg10a'] = np.where(P.perennial == 0, P.yield_raw, np.nan)
# fruit: KOSIS yield in DT_1ET0292 = production / total orchard area -> NOT agronomic yield
P['prod_per_total_orchard_kg10a'] = np.where(P.perennial == 1, P.production_t / P.total_orchard_area_ha * 100, np.nan)
P['yield_per_bearing_area_kg10a'] = np.where(P.perennial == 1, P.production_t / P.bearing_area_ha * 100, np.nan)
for v, s in [('area_ha','ln_area'),('yield_kg10a','ln_yield'),('production_t','ln_production'),
             ('total_orchard_area_ha','ln_total_orchard_area'),('bearing_area_ha','ln_bearing_area'),
             ('yield_per_bearing_area_kg10a','ln_yield_per_bearing_area'),('prod_per_total_orchard_kg10a','ln_prod_per_total_orchard')]:
    P[s] = np.log(P[v].where(P[v] > 0))
# harmonized area: total orchard area for fruit, cultivated area for annual crops (used only when fruit is compared with annual controls)
P['ln_area_harmonized'] = np.where(P.perennial == 1, P.ln_total_orchard_area, P.ln_area)
# identity check for annual crops: prod = area*yield/100
P['identity_gap'] = np.where(P.perennial == 0, np.log(P.production_t) - np.log(P.area_ha * P.yield_kg10a / 100), np.nan)

# ---------------------------------------------------------------- 3. treatment coding (crop-year basis)
# pilot_year / national_year = first HARVEST (crop) year covered, converted from event month + sales window.
# Rule B (baseline): national_year = first crop-year of the earliest Yearbook-history (연혁, 2025 Yearbook pp.37-38)
#   event described as '전국적 본사업', '전국사업' or '본사업'. Alternatives preserved.
TR = pd.read_csv(OUT + 'treatment_coding_input.csv')
P = P.merge(TR, on='crop_id', how='left')
P['pilot_year'] = P.pilot_year.astype('float'); P['national_year'] = P.national_year.astype('float')
P['clean_pre'] = (P.pilot_year.isna() | (P.year < P.pilot_year)).astype(int)
P['transition'] = ((P.year >= P.pilot_year) & (P.national_year.isna() | (P.year < P.national_year))).astype(int)
P['national_treatment'] = (P.year >= P.national_year).fillna(False).astype(int)
P['event_time'] = P.year - P.national_year
P['event_time_pilot'] = P.year - P.pilot_year          # alternative clock (sensitivity)
P['last_clean_pre_year'] = P.pilot_year - 1
P['transition_length'] = P.national_year - P.pilot_year
P['treatment_cohort'] = P.national_year.where(P.national_year <= YEAR_MAX, 0).fillna(0).astype(int)
P['ever_treated_by_2024'] = (P.treatment_cohort > 0).astype(int)
# baseline estimation sample flags
P['bl_treated_row'] = ((P.role == 'baseline_treated') & (P.transition == 0)).astype(int)
P['bl_control_row'] = ((P.role == 'control_pool') & (P.clean_pre == 1)).astype(int)
P['in_baseline_sample'] = ((P.bl_treated_row == 1) | (P.bl_control_row == 1)).astype(int)
for _, r in P[(P.role == 'baseline_treated') & (P.transition == 1)].iterrows():
    droplog.append((r.crop_id, r.year, 'all', '', 'transition year (pilot<=year<national) excluded from baseline'))
for _, r in P[(P.role == 'control_pool') & (P.clean_pre == 0)].iterrows():
    droplog.append((r.crop_id, r.year, 'all', '', 'control crop exposed to pilot/insurance -> not a valid control from pilot year'))

# ---------------------------------------------------------------- 4. write (prices are built in 02_build_prices.py)
P = P.sort_values(['crop_id', 'year'])
P.to_csv(OUT + 'panel_production_stage1.csv', index=False, encoding='utf-8-sig')
pd.DataFrame(droplog, columns=['crop_id','year','variable','raw_value','reason']).to_csv(OUT + 'dropped_observation_log.csv', index=False, encoding='utf-8-sig')
XW.to_csv(OUT + 'crop_crosswalk_production.csv', index=False, encoding='utf-8-sig')
json.dump({k: {kk: str(vv) for kk, vv in v.items()} for k, v in METAS.items()}, open(OUT + 'kosis_metadata.json', 'w'), ensure_ascii=False, indent=1)
print('stage1 rows', len(P), 'crops', P.crop_id.nunique())

```

---

# FILE: 02_build_prices(1).py

```python
# -*- coding: utf-8 -*-
"""02_build_prices.py — crop-level price crosswalk, DT_1J49 (2005=100) x DT_1J60 (2020=100) linking,
linked quarterly and annual price panels. Raw files are read, never modified."""
import numpy as np, pandas as pd, warnings, matplotlib
warnings.filterwarnings('ignore'); matplotlib.use('Agg'); import matplotlib.pyplot as plt
RAW='/mnt/user-data/uploads/'; OUT='/mnt/user-data/outputs/ch5_v2/'
F49='농가판매가격지수_2005100__분기__품목별__20260927193919.xlsx'; F60='11_farm_output_price_index_2026.xlsx'; F50='12_farm_output_price_index_2005.xlsx'

def q2(y,q): return y*10+q
# ---- raw quarterly panels (tidy, unchanged values)
d=pd.read_excel(RAW+F49,sheet_name='데이터',header=None); qs=d.iloc[0,2:].astype(str).tolist(); g=None; r=[]
for i in range(1,len(d)):
    if isinstance(d.iloc[i,0],str): g=d.iloc[i,0].replace(' ','')
    it=str(d.iloc[i,1]).strip(); key=it.replace(' ','')
    for j,qq in enumerate(qs): r.append(('DT_1J49',g,it,key,int(qq[:4]),int(qq[5]),pd.to_numeric(d.iloc[i,j+2],errors='coerce')))
Q49=pd.DataFrame(r,columns=['table','group','item_raw','item','year','quarter','value'])
d=pd.read_excel(RAW+F60,sheet_name='데이터',header=None); qs=d.iloc[0,1:].astype(str).tolist(); r=[]
for i in range(2,len(d)):
    it=str(d.iloc[i,0]); key=it.replace('\u3000','').strip()
    for j,qq in enumerate(qs): r.append(('DT_1J60','',it,key,int(qq[:4]),int(qq[5]),pd.to_numeric(d.iloc[i,j+1],errors='coerce')))
Q60=pd.DataFrame(r,columns=['table','group','item_raw','item','year','quarter','value'])
d=pd.read_excel(RAW+F50,sheet_name='데이터',header=None); qs=d.iloc[0,1:].astype(str).tolist(); r=[]
for i in range(1,len(d)):
    it=str(d.iloc[i,0]).strip()
    for j,qq in enumerate(qs): r.append(('DT_1J50','',it,it,int(qq[:4]),int(qq[5]),pd.to_numeric(d.iloc[i,j+1],errors='coerce')))
Q50=pd.DataFrame(r,columns=['table','group','item_raw','item','year','quarter','value'])
pd.concat([Q49,Q60,Q50]).to_csv(OUT+'price_quarterly_raw_all_tables.csv',index=False,encoding='utf-8-sig')

# ---- price-unit crosswalk (price units are crop-level; seasonal production forms map to one pooled price item)
# price_unit, display, 1J49 item, 1J60 item, production crop_ids, match class, definition note, treatment dates for price unit
PX=[
('soybean','Soybean','콩','콩','soybean','exact','Same item name in both tables.'),
('onion','Onion','양파','양파','onion','exact',''),
('sweet_potato','Sweet potato','고구마','고구마','sweet_potato','exact',''),
('corn','Corn','옥수수','옥수수','corn','exact','Production series may include forage corn.'),
('garlic','Garlic','마늘','마늘','garlic','exact',''),
('red_pepper','Red pepper','건고추','건고추','red_pepper','exact','Dried red pepper in both tables.'),
('potato','Potato (all seasons)','감자','감자','spring_potato','approximate','Price pools spring, highland and autumn potatoes; treatment of spring potato only.'),
('rice','Rice','일반미','멥쌀','rice','approximate','Item renamed (일반미 -> 멥쌀); rice case only.'),
('red_bean','Red bean','팥','팥','red_bean','exact',''),
('mung_bean','Mung bean','녹두','','mung_bean','old-only','DT_1J49 ends 2004Q4; absent in DT_1J60.'),
('barley','Barley','쌀보리','쌀보리(조곡)','barley','approximate','Naked barley price only; production = hulled + naked; 조곡 qualifier added in DT_1J60.'),
('malting_barley','Malting barley','맥주맥','맥주보리','malting_barley','approximate','Item renamed (맥주맥 -> 맥주보리).'),
('cabbage','Cabbage','양배추','양배추','cabbage','exact',''),
('carrot','Carrot','당근','당근','carrot','exact','All forms in both production and price.'),
('ginger','Ginger','생강','생강','ginger','exact','DT_1J49 starts 1995Q1.'),
('sesame','Sesame','참깨','참깨','sesame','exact',''),
('perilla','Perilla','들깨','들깨','perilla','exact',''),
('peanut','Peanut','땅콩','땅콩','peanut','exact',''),
('napa_cabbage','Napa cabbage (all seasons)','배추','배추','spring_napa;highland_napa;autumn_napa;winter_napa','approximate','Pools seasonal forms and greenhouse napa cabbage (insured from 2014).'),
('radish','Radish (all seasons)','무','무','spring_radish;highland_radish;autumn_radish;winter_radish','approximate','Pools seasonal forms and greenhouse radish (insured from 2015).'),
('green_onion','Green onion (all types)','파','파','large_green_onion;small_green_onion','approximate','Pools large and small green onion and greenhouse green onion (insured from 2014).'),
('spinach','Spinach (all)','시금치','시금치','spinach','approximate','Pools open-field and greenhouse spinach (greenhouse insured from 2013).'),
('leaf_lettuce','Leaf lettuce (all)','상추','상추','leaf_lettuce','approximate','Pools open-field and greenhouse lettuce (greenhouse insured from 2013).'),
('apple','Apple','사과(후지)','사과','apple','incompatible','Old series = Fuji variety only; new = all apples.'),
('pear','Pear','배','배','pear','exact',''),
('peach','Peach','복숭아','복숭아','peach','exact',''),
('sweet_persimmon','Sweet persimmon','감','단감','sweet_persimmon','incompatible','Old series = all persimmons.'),
('tangerine','Tangerine','감귤','감귤','tangerine','approximate','Old 감귤 ends 2004; 2005-12 split into 온주밀감/한라봉 -> no overlap for 감귤.'),
('plum','Plum','자두','자두','plum','no-overlap','Old ends 2012Q4; new starts 2015Q1.'),
('grape','Grape','포도','포도','grape','approximate','Old 포도 ends 2004; varieties 2005-12 -> no overlap for 포도.'),
('green_plum','Green plum','매실','매실','green_plum','no-overlap','Old ends 2012Q4; new starts 2015Q1.'),
]
PX=pd.DataFrame(PX,columns=['price_unit','display','item_1J49','item_1J60','production_crop_ids','match_class','definition_note'])

def series(Q,item):
    s=Q[Q.item==item.replace(' ','')].set_index(['year','quarter']).value if item else pd.Series(dtype=float)
    return s.dropna()
def link_stats(old,new,window):
    idx=old.index.intersection(new.index); idx=[k for k in idx if window[0]<=k[0]<=window[1]]
    if len(idx)<4: return None
    o=old.loc[idx]; n=new.loc[idx]; ratio=n/o; k=ratio.mean()
    dlo=np.log(o).diff(); dln=np.log(n).diff()
    disc=(o*k/n-1).abs()
    return dict(n_overlap_q=len(idx),link_factor=k,ratio_cv_pct=ratio.std()/ratio.mean()*100,corr_qoq_dlog=dlo.corr(dln),
                mean_abs_disc_pct=disc.mean()*100,max_abs_disc_pct=disc.max()*100)
# pre-specified compatibility rule (set before estimation):
RULE='linkable if corr(q-o-q dlog) >= 0.90 AND ratio CV <= 5% AND max abs discrepancy <= 10% over 2005Q1-2012Q4, and item definitions identical (exact) or documented approximate'
rows=[]; LINKED=[]
WINDOWS={'full_2005_2012':(2005,2012),'early_2005_2006':(2005,2006),'late_2010_2012':(2010,2012)}
for _,x in PX.iterrows():
    o=series(Q49,x.item_1J49); n=series(Q60,x.item_1J60)
    rec=dict(price_unit=x.price_unit,display=x.display,item_1J49=x.item_1J49,item_1J60=x.item_1J60,match_class=x.match_class,
             old_first=f"{o.index[0][0]}Q{o.index[0][1]}" if len(o) else '',old_last=f"{o.index[-1][0]}Q{o.index[-1][1]}" if len(o) else '',
             new_first=f"{n.index[0][0]}Q{n.index[0][1]}" if len(n) else '',new_last=f"{n.index[-1][0]}Q{n.index[-1][1]}" if len(n) else '')
    st={w:link_stats(o,n,v) for w,v in WINDOWS.items()} if len(o) and len(n) else {}
    for w in WINDOWS:
        s=st.get(w)
        if s:
            for k,v in s.items(): rec[f'{k}_{w}']=round(v,4)
    f=st.get('full_2005_2012')
    ok = f is not None and f['corr_qoq_dlog']>=0.90 and f['ratio_cv_pct']<=5 and f['max_abs_disc_pct']<=10 and x.match_class in ('exact','approximate')
    rec['stat_test_pass']=bool(f is not None and f['corr_qoq_dlog']>=0.90 and f['ratio_cv_pct']<=5 and f['max_abs_disc_pct']<=10)
    rec['linkable']=bool(ok)
    rec['link_decision']=('linked' if ok else ('not linked: '+('no overlap / old-only' if f is None else 'fails statistical rule' if x.match_class in ('exact','approximate') else 'incompatible definition')))
    rows.append(rec)
    # build linked quarterly series (new series retained on its own range; old rescaled before 2005Q1)
    for w in WINDOWS:
        s=st.get(w)
        allq=sorted(set(o.index)|set(n.index))
        for k in allq:
            ov=o.get(k,np.nan); nv=n.get(k,np.nan)
            lk = nv if not np.isnan(nv) else (ov*s['link_factor'] if (s is not None and not np.isnan(ov) and k[0]<2005) else np.nan)
            LINKED.append((x.price_unit,w,k[0],k[1],ov,nv,s['link_factor'] if s else np.nan,f'{WINDOWS[w][0]}Q1-{WINDOWS[w][1]}Q4',lk,x.match_class))
LD=pd.DataFrame(rows)
# annual-level rule (outcome is annual): annual means over 2005-2012 with 4 quarters in both tables
ANN=[]
for u,z in pd.DataFrame(LINKED,columns=['u','w','y','q','o','n','k','p','l','m']).query("w=='full_2005_2012' and y>=2005 and y<=2012").groupby('u'):
    a=z.groupby('y').agg(o=('o','mean'),n=('n','mean'),no=('o','count'),nn=('n','count')); a=a[(a.no==4)&(a.nn==4)]
    if len(a)<4: continue
    rt=a.n/a.o; kk=rt.mean(); disc=(a.o*kk/a.n-1).abs()
    ANN.append(dict(price_unit=u,annual_n_years=len(a),annual_ratio_cv_pct=round(rt.std()/rt.mean()*100,3),annual_corr_dlog=round(np.log(a.o).diff().corr(np.log(a.n).diff()),4),annual_max_disc_pct=round(disc.max()*100,3)))
LD=LD.merge(pd.DataFrame(ANN),on='price_unit',how='left')
LD['linkable_quarterly_rule']=LD.linkable
LD['linkable_annual_rule']=(LD.annual_corr_dlog>=0.95)&(LD.annual_ratio_cv_pct<=5)&(LD.annual_max_disc_pct<=10)&LD.match_class.isin(['exact','approximate'])
LD['price_sample_strict']=LD.linkable_quarterly_rule&LD.linkable_annual_rule&(LD.match_class=='exact')
LD['price_sample_main']=LD.linkable_annual_rule&(LD.match_class=='exact')
LD['rules']='quarterly: corr>=0.90, CV<=5%, max disc<=10% (2005Q1-2012Q4); annual: corr>=0.95, CV<=5%, max disc<=10% (2005-2012 annual means). Main price sample = exact item match AND annual rule; strict = exact AND both rules.'
LD=LD.drop(columns=['linkable'])
LD.to_csv(OUT+'price_linking_diagnostics.csv',index=False,encoding='utf-8-sig')
LQ=pd.DataFrame(LINKED,columns=['price_unit','link_window','year','quarter','old_price_index','new_price_index','link_factor','link_period','linked_price_index','price_definition_match'])
LQ.to_csv(OUT+'price_linked_quarterly.csv',index=False,encoding='utf-8-sig')
PX.to_csv(OUT+'price_item_crosswalk.csv',index=False,encoding='utf-8-sig')

# ---- deflator: all-farm-output index, DT_1J50 (2005=100) linked to DT_1J60 (2020=100)
o=Q50[Q50.item=='총지수'].set_index(['year','quarter']).value.dropna(); n=Q60[Q60.item=='총지수'].set_index(['year','quarter']).value.dropna()
dst=link_stats(o,n,(2005,2012)); kdef=dst['link_factor']
defl=pd.Series({k:(n[k] if k in n.index else o[k]*kdef) for k in sorted(set(o.index)|set(n.index))})
DEF=defl.rename('total_index_linked').reset_index(); DEF.columns=['year','quarter','total_index_linked']
DEF['deflator_link_factor']=kdef
DEF.to_csv(OUT+'price_deflator_quarterly.csv',index=False,encoding='utf-8-sig')
pd.DataFrame([dict(series='총지수 DT_1J50 x DT_1J60',**{k:round(v,4) for k,v in dst.items()})]).to_csv(OUT+'price_deflator_link.csv',index=False,encoding='utf-8-sig')

# ---- annual panel (simple mean of 4 quarters; <4 quarters -> missing)
LQ2=LQ.merge(DEF[['year','quarter','total_index_linked']],on=['year','quarter'],how='left')
LQ2['real_linked']=LQ2.linked_price_index/LQ2.total_index_linked*100
LQ2['real_old']=LQ2.old_price_index/LQ2.total_index_linked*100
LQ2['real_new']=LQ2.new_price_index/LQ2.total_index_linked*100
A=LQ2.groupby(['price_unit','link_window','year']).agg(nq_link=('linked_price_index','count'),linked=('linked_price_index','mean'),real_linked=('real_linked','mean'),
    nq_old=('old_price_index','count'),real_old=('real_old','mean'),nq_new=('new_price_index','count'),real_new=('real_new','mean')).reset_index()
for v,nq in [('linked','nq_link'),('real_linked','nq_link'),('real_old','nq_old'),('real_new','nq_new')]: A.loc[A[nq]<4,v]=np.nan
for v in ['real_linked','real_old','real_new']: A['ln_'+v]=np.log(A[v])
A=A[(A.year>=1980)&(A.year<=2024)]
A.to_csv(OUT+'price_annual_panel.csv',index=False,encoding='utf-8-sig')

# ---- overlap figures (visual diagnostics) for linkable/approximate annual units
units=[u for u in LD.price_unit if u in ('soybean','onion','sweet_potato','corn','garlic','red_pepper','potato','red_bean','barley','malting_barley','cabbage','carrot','ginger','sesame','perilla','peanut','napa_cabbage','radish','green_onion','spinach','leaf_lettuce','rice','pear','peach')]
fig,axs=plt.subplots(6,4,figsize=(11,13)); axs=axs.ravel()
for ax,u in zip(axs,units):
    z=LQ[(LQ.price_unit==u)&(LQ.link_window=='full_2005_2012')&(LQ.year.between(2003,2014))]
    t=z.year+(z.quarter-1)/4; k=z.link_factor.iloc[0]
    ax.plot(t,z.new_price_index,lw=1.2,label='DT_1J60 (2020=100)')
    if not np.isnan(k): ax.plot(t,z.old_price_index*k,lw=1.0,ls='--',label='DT_1J49 rebased')
    rr=LD[LD.price_unit==u].iloc[0]
    tag='passes quarterly and annual rules' if (rr.linkable_quarterly_rule and rr.linkable_annual_rule) else ('passes annual rule only' if rr.linkable_annual_rule else 'fails linking rules')
    ax.set_title(f"{rr.display.split(' (')[0]}\n{tag}",fontsize=8); ax.tick_params(labelsize=7)
for ax in axs[len(units):]: ax.axis('off')
axs[0].legend(fontsize=6)
fig.suptitle('Price-index overlap diagnostics, 2005Q1–2012Q4 (old series rebased by mean ratio over overlap)',fontsize=10)
fig.tight_layout(rect=[0,0,1,0.97]); fig.savefig(OUT+'fig_price_link_overlap.png',dpi=160); plt.close()
print(LD[['price_unit','match_class','linkable_quarterly_rule','linkable_annual_rule','price_sample_main','price_sample_strict']].to_string())
print('deflator',dst)

```

---

# FILE: est_engine(1).py

```python
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

```

---

# FILE: 03_estimate(1).py

```python
# -*- coding: utf-8 -*-
"""03_estimate.py — all Chapter 5 estimations (production, fruit, rice case, prices) and robustness.
Specification choices were fixed in advance (see memo): preferred = group-time DiD, normalization A
(last clean-pre year), national_year treatment, transition excluded, e = 0..9, crop-level Webb wild bootstrap."""
import numpy as np, pandas as pd, warnings, est_engine as E
warnings.filterwarnings('ignore')
OUT='/mnt/user-data/outputs/ch5_v2/'
P=pd.read_csv(OUT+'panel_production_stage1.csv')
NAME=dict(zip(P.crop_id,P.crop_en_display))
ANN=['soybean','onion','sweet_potato','corn','garlic','spring_potato','red_pepper']
FRUIT=['apple','pear','tangerine','sweet_persimmon','astringent_persimmon','plum']
CTRL=sorted(P[P.role=='control_pool'].crop_id.unique())
FIELD=['red_bean','mung_bean','barley','malting_barley','wheat','sesame','perilla','peanut']
SEASONAL_UNCERTAIN=['spring_napa','highland_napa','autumn_napa','winter_napa','spring_radish','highland_radish','autumn_radish','winter_radish','carrot','large_green_onion','small_green_onion']
SPILL=['leaf_lettuce','spinach','malting_barley']
OUTC=['ln_area','ln_yield','ln_production']
dyn=[]; summ=[]; support=[]
def rec(sample,spec,outcome,R,O,family,evidence):
    for r in R.to_dict('records'): dyn.append(dict(sample=sample,spec=spec,outcome=outcome,**r))
    summ.append(dict(family=family,sample=sample,spec=spec,outcome=outcome,evidence_class=evidence,**{k:v for k,v in O.items()}))
def cs(sample,spec,outcome,treated,controls,family,evidence,P_=None,**kw):
    R,O,D=E.run_cs(P if P_ is None else P_,outcome,treated,controls,**kw); rec(sample,spec,outcome,R,O,family,evidence); return R,O

# ---------------- A. annual crops (headline)
for y in OUTC:
    cs('annual','CS-A (preferred)',y,ANN,CTRL,'main','see memo',norm='A')
    cs('annual','CS-B (mean of all clean-pre years)',y,ANN,CTRL,'estimator','see memo',norm='B')
    cs('annual','CS-B5 (mean of last 5 clean-pre years)',y,ANN,CTRL,'estimator','see memo',norm='B',B5=True)
    bj=E.run_bjs(P,y,ANN,CTRL)
    for r in bj.to_dict('records'):
        if r['event_time']=='overall': summ.append(dict(family='estimator',sample='annual',spec='Imputation (FE on clean cells)',outcome=y,evidence_class='see memo',est=r['est'],se_cluster=r['se_cluster'],ci_lo_wild=r['ci_lo_wild'],ci_hi_wild=r['ci_hi_wild'],p_wild=r['p_wild'],G=r['G'],n_treated=r['n_treated']))
        else: dyn.append(dict(sample='annual',spec='Imputation (FE on clean cells)',outcome=y,**r))
    for v,lab in [('clean','TWFE static, clean cells (benchmark)'),('naive','TWFE static, Han-style naive coding (benchmark)')]:
        t=E.run_twfe(P,y,ANN,CTRL,variant=v)
        summ.append(dict(family='estimator',sample='annual',spec=lab,outcome=y,evidence_class='benchmark only',est=t['est'],se_cluster=t['se_cluster'],p_wild=t['p_wcr'],G=t['G'],n_treated=t['n_treated'],n_obs=t['n_obs']))
    # treatment-date robustness
    P2=P.copy(); m=P2.crop_id.isin(ANN); P2.loc[m,'national_year']=P2.loc[m,'national_year_alt_table']
    cs('annual','Dates: product-table nationwide year',y,ANN,CTRL,'dates','see memo',P_=P2,norm='A')
    cs('annual','Dates: pilot-year clock (no transition exclusion)',y,ANN,CTRL,'dates','see memo',norm='A',pilot_clock=True)
    # control pools
    cs('annual','Controls: excl. other pulses',y,ANN,[c for c in CTRL if c!='other_pulses'],'controls','see memo',norm='A')
    cs('annual','Controls: excl. likely spillover (leaf lettuce, spinach, malting barley)',y,ANN,[c for c in CTRL if c not in SPILL],'controls','see memo',norm='A')
    cs('annual','Controls: field crops only',y,ANN,[c for c in CTRL if c in FIELD],'controls','see memo',norm='A')
    cs('annual','Controls: excl. uncertain seasonal forms',y,ANN,[c for c in CTRL if c not in SEASONAL_UNCERTAIN],'controls','see memo',norm='A')
    for g in [2012,2013,2015]:
        tr=[c for c in ANN if P[P.crop_id==c].national_year.iloc[0]!=g]
        cs('annual',f'Leave out cohort {g}',y,tr,CTRL,'loo','see memo',norm='A')
    for c in ANN:
        cs('annual',f'Leave out {NAME[c]}',y,[x for x in ANN if x!=c],CTRL,'loo','see memo',norm='A')
    # cohort-specific pre-trends
    for g in [2012,2013,2015]:
        tr=[c for c in ANN if P[P.crop_id==c].national_year.iloc[0]==g]
        cs('annual',f'Cohort {g} only',y,tr,CTRL,'cohort','see memo',norm='A')

# ---------------- B. perennial fruit (separate, suggestive)
FO=['ln_area_harmonized','ln_production']   # fruit area = total orchard area; controls' area = cultivated area
FCTRL=CTRL+ANN        # annual crops, incl. annual baseline crops before their pilots (not-yet-treated)
for y in FO:
    cs('fruit','CS-A (preferred)',y,FRUIT,FCTRL,'fruit','see memo',norm='A')
    cs('fruit','CS-B (mean of all clean-pre years)',y,FRUIT,FCTRL,'fruit','see memo',norm='B')
    P3=P.copy(); m=P3.crop_id.isin(['apple','pear']); P3.loc[m,'national_year']=2001
    cs('fruit','Apple and Pear dated 2001',y,FRUIT,FCTRL,'fruit','see memo',P_=P3,norm='A')
    for yr in [2004,2010]:
        P4=P.copy(); m=P4.crop_id.isin(['peach','grape']); P4.loc[m,'national_year']=yr
        cs('fruit',f'Adding Peach and Grape (nationwide {yr})',y,FRUIT+['peach','grape'],FCTRL,'fruit','see memo',P_=P4,norm='A')
    cs('fruit','Controls: field crops only',y,FRUIT,[c for c in FCTRL if c in FIELD+ANN],'fruit','see memo',norm='A')
    t=E.run_twfe(P,y,FRUIT,CTRL,variant='clean')
    summ.append(dict(family='fruit',sample='fruit',spec='TWFE static, clean cells (benchmark)',outcome=y,evidence_class='benchmark only',est=t['est'],se_cluster=t['se_cluster'],p_wild=t['p_wcr'],G=t['G'],n_treated=t['n_treated'],n_obs=t['n_obs']))

# ---------------- C. rice case (single treated unit; no cluster inference)
rice_rows=[]
for y in OUTC:
    for lab,yr in [('nationwide 2014 (baseline)',2014),('product table 2012',2012),('full-scale 2017',2017)]:
        P5=P.copy(); P5.loc[P5.crop_id=='rice','national_year']=yr
        D,Yd,meta=E.prepare(P5,y,['rice'],CTRL)
        agg=E.cs_weights(D,Yd,meta,['rice'],norm='A')
        for e,d in sorted(agg.items()):
            rice_rows.append(dict(outcome=y,dating=lab,event_time=e,est=sum(v*Yd[k] for k,v in d['w'].items()),n_controls=d['n_ctrl_min']))
pd.DataFrame(rice_rows).to_csv(OUT+'results_rice_case.csv',index=False,encoding='utf-8-sig')

# ---------------- D. prices (reduced form, secondary)
PR=pd.read_csv(OUT+'price_annual_panel.csv')
PD={'onion':(2009,2012),'sweet_potato':(2009,2013),'garlic':(2010,2013),'red_pepper':(2008,2015),'soybean':(2008,2012),'corn':(2009,2013),'potato':(2008,2013),
    'red_bean':(2020,2024),'cabbage':(2017,np.nan),'carrot':(2019,np.nan),'ginger':(2025,np.nan),'sesame':(2025,np.nan),'perilla':(2027,np.nan),'peanut':(np.nan,np.nan),
    'napa_cabbage':(2014,np.nan),'radish':(2015,np.nan),'green_onion':(2014,np.nan),'spinach':(2013,np.nan),'leaf_lettuce':(2013,np.nan),'mung_bean':(2025,np.nan)}
def price_panel(window='full_2005_2012'):
    X=PR[PR.link_window==window].rename(columns={'price_unit':'crop_id'}).copy()
    X['pilot_year']=X.crop_id.map(lambda c: PD.get(c,(np.nan,np.nan))[0]); X['national_year']=X.crop_id.map(lambda c: PD.get(c,(np.nan,np.nan))[1])
    return X
PX=price_panel()
T_MAIN=['onion','sweet_potato','garlic','red_pepper']; C_MAIN=['red_bean','cabbage','carrot','ginger','sesame','perilla','peanut']
T_STRICT=['sweet_potato','garlic']; C_STRICT=['red_bean','cabbage','sesame','perilla','peanut']
C_APPROX=C_MAIN+['napa_cabbage','radish','green_onion','spinach','leaf_lettuce']
yrs=(1980,2024)
cs('price','CS-A main (exact match, annual linking rule)','ln_real_linked',T_MAIN,C_MAIN,'price','see memo',P_=PX,norm='A',years=yrs)
cs('price','CS-B main','ln_real_linked',T_MAIN,C_MAIN,'price','see memo',P_=PX,norm='B',years=yrs)
cs('price','Strict sample (both linking rules)','ln_real_linked',T_STRICT,C_STRICT,'price','see memo',P_=PX,norm='A',years=yrs)
cs('price','Approximate matches included (+ all-potato, pooled vegetable items)','ln_real_linked',T_MAIN+['potato'],C_APPROX,'price','see memo',P_=PX,norm='A',years=yrs)
cs('price','New series only 2005-2024 (6 exact crops)','ln_real_new',['soybean','onion','sweet_potato','corn','garlic','red_pepper'],C_MAIN,'price','see memo',P_=PX,norm='A',years=(2005,2024))
cs('price','New series only 2005-2024 (main 4 crops)','ln_real_new',T_MAIN,C_MAIN,'price','see memo',P_=PX,norm='A',years=(2005,2024))
for w,lab in [('early_2005_2006','Link window 2005-2006'),('late_2010_2012','Link window 2010-2012')]:
    cs('price',lab,'ln_real_linked',T_MAIN,C_MAIN,'price','see memo',P_=price_panel(w),norm='A',years=yrs)
for c in T_MAIN:
    cs('price',f'Leave out {NAME.get(c,c)}','ln_real_linked',[x for x in T_MAIN if x!=c],C_MAIN,'price','see memo',P_=PX,norm='A',years=yrs)
t=E.run_twfe(PX.assign(pilot_year=PX.pilot_year),'ln_real_linked',T_MAIN,C_MAIN,variant='clean',years=yrs)
summ.append(dict(family='price',sample='price',spec='TWFE static, clean cells (benchmark)',outcome='ln_real_linked',evidence_class='benchmark only',est=t['est'],se_cluster=t['se_cluster'],p_wild=t['p_wcr'],G=t['G'],n_treated=t['n_treated'],n_obs=t['n_obs']))
# old-series-only feasibility
old=PX[PX.year<=2012]; feas=[]
for c in ['soybean','onion','sweet_potato','corn','garlic','red_pepper']:
    g=PD[c][1]; feas.append(dict(crop=NAME.get(c,c),national_year=g,post_years_in_old_series=max(0,2012-g+1)))
pd.DataFrame(feas).to_csv(OUT+'results_price_old_series_feasibility.csv',index=False,encoding='utf-8-sig')

S=pd.DataFrame(summ); Dy=pd.DataFrame(dyn)
S.to_csv(OUT+'results_summary_all_specs.csv',index=False,encoding='utf-8-sig'); Dy.to_csv(OUT+'results_dynamic_all_specs.csv',index=False,encoding='utf-8-sig')
print(S[['sample','spec','outcome','est','se_cluster','ci_lo_wild','ci_hi_wild','p_wild','G','n_treated','pre_p_boot']].round(3).to_string())

```

---

# FILE: 04_figures(1).py

```python
# -*- coding: utf-8 -*-
"""04_figures.py — thesis-facing figures (English display names only)."""
import numpy as np, pandas as pd, matplotlib
matplotlib.use('Agg'); import matplotlib.pyplot as plt
OUT='/mnt/user-data/outputs/ch5_v2/'
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':9,'axes.spines.top':False,'axes.spines.right':False})
D=pd.read_csv(OUT+'results_dynamic_all_specs.csv'); S=pd.read_csv(OUT+'results_summary_all_specs.csv')
LAB={'ln_area':'Log cultivated area','ln_yield':'Log yield per 10a','ln_production':'Log production',
     'ln_area_harmonized':'Log orchard area (fruit) / cultivated area (controls)','ln_real_linked':'Log relative farm-gate price index'}
def es_panel(ax,d,title,ylab):
    d=d.copy(); d['event_time']=d.event_time.astype(int); pre=d[d.event_time<0].sort_values('event_time'); post=d[d.event_time>=0].sort_values('event_time')
    ax.axhline(0,color='black',lw=0.6)
    if len(pre):
        ax.errorbar(pre.event_time,pre.est,yerr=[pre.est-pre.ci_lo_wild,pre.ci_hi_wild-pre.est],fmt='o',ms=3.5,color='#7F7F7F',ecolor='#BFBFBF',elinewidth=1,capsize=0,label='Clean pre-pilot years (placebo)')
        ax.plot(pre.event_time,pre.est,color='#7F7F7F',lw=0.8)
        ax.axvline(-0.5,color='#7F7F7F',ls=':',lw=0.8)
    ax.errorbar(post.event_time,post.est,yerr=[post.est-post.ci_lo_wild,post.ci_hi_wild-post.est],fmt='o',ms=3.5,color='#1F4E79',ecolor='#9DC3E6',elinewidth=1,capsize=0,label='Years after nationwide availability')
    ax.plot(post.event_time,post.est,color='#1F4E79',lw=0.8)
    ax.set_title(title,fontsize=9,loc='left'); ax.set_ylabel(ylab,fontsize=8); ax.set_xlabel('Years relative to nationwide availability (e)',fontsize=8)
    if len(pre):
        y0,y1=ax.get_ylim(); xm=(pre.event_time.max()-0.5)/2
        ax.text(xm,y1-(y1-y0)*0.04,'Crop-specific\ntransition years\nomitted',ha='center',va='top',fontsize=6.5,color='#595959',style='italic')
def sel(sample,spec,o): return D[(D['sample']==sample)&(D.spec==spec)&(D.outcome==o)]
NOTE_ANN=('Notes: Custom group-time difference-in-differences with clean not-yet-treated and never-treated controls; reference = each crop\'s final clean pre-pilot\n'
          'year. Treated: Soybean, Onion, Sweet potato, Corn, Garlic, Spring potato, Red pepper (nationwide availability 2012–2015). Controls: 24 annual crop series,\n'
          'each used only before its first pilot. National data, 1991–2024. Crop-specific pilot-to-national transition observations are omitted; the final clean\n'
          'pre-pilot year ranges from e = −8 to −4. Estimates are associations, not established causal effects. 95% crop-level wild bootstrap intervals (Webb, 9,999 draws).')
# Fig 1 annual
fig,axs=plt.subplots(1,3,figsize=(12,4.1),sharex=True)
for ax,o,t in zip(axs,['ln_area','ln_yield','ln_production'],['A. Area (extensive margin)','B. Yield (intensive margin)','C. Production']):
    es_panel(ax,sel('annual','CS-A (preferred)',o),t,LAB[o])
axs[0].legend(fontsize=7,loc='lower left',frameon=False)
fig.suptitle('Figure 1. Estimated changes in annual-crop area, yield and production associated with insurance expansion, 1991–2024',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.005,NOTE_ANN,fontsize=6.6,va='bottom'); fig.tight_layout(rect=[0,0.15,1,0.94]); fig.savefig(OUT+'fig1_annual_event_study.png',dpi=220); plt.close()
# Fig 2 estimator comparison
specs=['CS-A (preferred)','CS-B (mean of all clean-pre years)','CS-B5 (mean of last 5 clean-pre years)','Imputation (FE on clean cells)','TWFE static, clean cells (benchmark)','TWFE static, Han-style naive coding (benchmark)']
short=['Custom group-time DiD, final clean pre-pilot year (preferred)','Custom group-time DiD, mean of all clean pre-pilot years','Custom group-time DiD, mean of last 5 clean pre-pilot years','Imputation estimator','TWFE, clean cells (benchmark)','TWFE, naive coding as in Han (2014) (benchmark)']
fig,axs=plt.subplots(1,3,figsize=(12,3.6),sharey=True)
for ax,o,t in zip(axs,['ln_area','ln_yield','ln_production'],['A. Area','B. Yield','C. Production']):
    for k,(sp,lab) in enumerate(zip(specs,short)):
        r=S[(S['sample']=='annual')&(S.spec==sp)&(S.outcome==o)].iloc[0]
        lo,hi=(r.ci_lo_wild,r.ci_hi_wild) if not pd.isna(r.ci_lo_wild) else (r.est-1.96*r.se_cluster,r.est+1.96*r.se_cluster)
        col='#1F4E79' if k==0 else ('#A6A6A6' if 'TWFE' in sp else '#5B9BD5')
        ax.errorbar(r.est,k,xerr=[[r.est-lo],[hi-r.est]],fmt='o',color=col,ms=4,capsize=0)
    ax.axvline(0,color='black',lw=0.6); ax.set_title(t,fontsize=9,loc='left'); ax.set_xlabel('Average estimated change, e = 0 to 9 (log points)',fontsize=8)
axs[0].set_yticks(range(len(short))); axs[0].set_yticklabels(short,fontsize=7.5); axs[0].invert_yaxis()
fig.suptitle('Figure 2. Annual crops: average estimated change after nationwide availability, by estimator',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,'Notes: Same treated crops, controls and period as Figure 1. Intervals: crop-level wild bootstrap for group-time and imputation estimators; TWFE intervals use\ncrop-clustered standard errors (normal approximation; wild cluster bootstrap p-values in Table 3). TWFE is a benchmark only. Estimates are associations.',fontsize=6.8)
fig.tight_layout(rect=[0,0.1,1,0.93]); fig.savefig(OUT+'fig2_estimator_comparison.png',dpi=220); plt.close()
# Fig 3 robustness forest
rob=[('CS-A (preferred)','Preferred specification'),('Dates: product-table nationwide year','Treatment date: product-table nationwide year'),('Dates: pilot-year clock (no transition exclusion)','Treatment date: first pilot year'),
     ('Controls: excl. other pulses','Controls: excluding other pulses'),('Controls: excl. likely spillover (leaf lettuce, spinach, malting barley)','Controls: excluding likely spillover crops'),
     ('Controls: field crops only','Controls: field crops only'),('Controls: excl. uncertain seasonal forms','Controls: excluding uncertain seasonal forms'),
     ('Leave out cohort 2012','Leave out 2012 cohort'),('Leave out cohort 2013','Leave out 2013 cohort'),('Leave out cohort 2015','Leave out 2015 cohort (Red pepper)')]
fig,axs=plt.subplots(1,3,figsize=(12,4.2),sharey=True)
for ax,o,t in zip(axs,['ln_area','ln_yield','ln_production'],['A. Area','B. Yield','C. Production']):
    for k,(sp,lab) in enumerate(rob):
        r=S[(S['sample']=='annual')&(S.spec==sp)&(S.outcome==o)].iloc[0]
        ax.errorbar(r.est,k,xerr=[[r.est-r.ci_lo_wild],[r.ci_hi_wild-r.est]],fmt='o',color='#1F4E79' if k==0 else '#5B9BD5',ms=4,capsize=0)
    ax.axvline(0,color='black',lw=0.6); ax.set_title(t,fontsize=9,loc='left'); ax.set_xlabel('Average estimated change, e = 0 to 9 (log points)',fontsize=8)
axs[0].set_yticks(range(len(rob))); axs[0].set_yticklabels([x[1] for x in rob],fontsize=7.5); axs[0].invert_yaxis()
fig.suptitle('Figure 3. Annual crops: robustness of the average estimated change after nationwide availability',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,'Notes: Custom group-time DiD with clean not-yet-treated and never-treated controls; reference = final clean pre-pilot year; 95% crop-level wild bootstrap\nintervals. National data, 1991–2024. Estimates are associations, not established causal effects.',fontsize=6.8)
fig.tight_layout(rect=[0,0.08,1,0.93]); fig.savefig(OUT+'fig3_annual_robustness.png',dpi=220); plt.close()
# Fig 4 fruit
fig,axs=plt.subplots(1,2,figsize=(9.5,4.1),sharex=True)
for ax,o,t in zip(axs,['ln_area_harmonized','ln_production'],['A. Orchard area','B. Production']):
    es_panel(ax,sel('fruit','CS-A (preferred)',o),t,'Log orchard area' if 'area' in o else 'Log production')
axs[0].legend(fontsize=7,loc='lower right',frameon=False)
fig.suptitle('Figure 4. Perennial fruit: estimated changes associated with insurance expansion (suggestive), 1991–2024',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.005,('Notes: Treated: Apple, Pear (nationwide 2003), Tangerine, Sweet persimmon (2004), Astringent persimmon (2008), Plum (2012). No untreated perennial\n'
    'fruit series exist; controls are annual crops before their first pilot, so the area comparison is orchard area versus cultivated area. Sweet and astringent\n'
    'persimmon series begin in 1998. Custom group-time DiD; reference = final clean pre-pilot year. Crop-specific pilot-to-national transition observations are\n'
    'omitted; the final clean pre-pilot year ranges from e = −5 to −3. Estimates are associations. 95% crop-level wild bootstrap intervals.'),fontsize=6.8,va='bottom')
fig.tight_layout(rect=[0,0.16,1,0.93]); fig.savefig(OUT+'fig4_fruit_event_study.png',dpi=220); plt.close()
# Fig 5 price
fig,ax=plt.subplots(figsize=(6.8,4.2))
es_panel(ax,sel('price','CS-A main (exact match, annual linking rule)','ln_real_linked'),'Onion, Sweet potato, Garlic, Red pepper','Log relative farm-gate price index')
ax.legend(fontsize=7,loc='lower left',frameon=False)
fig.suptitle('Figure 5. Relative farm-gate prices: reduced-form estimated changes\nassociated with insurance expansion (secondary), 1980–2024',fontsize=9.5,x=0.01,ha='left')
fig.text(0.01,0.005,('Notes: Annual mean of quarterly farm-gate price indices (1980–2004 from the 2005=100 crop-level series, rebased to 2020=100 over 2005Q1–2012Q4;\n'
    '2005–2024 from the 2020=100 series), divided by the all-farm-output price index (relative price, not a general-price deflator). Controls: Red bean,\n'
    'Cabbage, Carrot, Ginger, Sesame, Perilla, Peanut, each before its first pilot. Custom group-time DiD; reference = final clean pre-pilot year. Crop-specific\n'
    'pilot-to-national transition observations are omitted; the final clean pre-pilot year ranges from e = −8 to −4. Prices and production are jointly\n'
    'determined; estimates are reduced-form associations. 95% crop-level wild bootstrap intervals.'),fontsize=6.3,va='bottom')
fig.tight_layout(rect=[0,0.2,1,0.9]); fig.savefig(OUT+'fig5_price_event_study.png',dpi=220); plt.close()
# Fig 6 rice (descriptive)
P=pd.read_csv(OUT+'panel_production_stage1.csv'); CTRL=P[P.role=='control_pool'].crop_id.unique()
fig,axs=plt.subplots(1,3,figsize=(12,3.8))
for ax,o,t in zip(axs,['ln_area','ln_yield','ln_production'],['A. Area','B. Yield','C. Production']):
    r=P[(P.crop_id=='rice')&P.year.between(1991,2024)].set_index('year')[o]
    ax.plot(r.index,r-r.loc[2008],color='#1F4E79',lw=1.4,label='Rice')
    for yv,ls,lab in [(2009,':','First pilot (2009)'),(2014,'-','Nationwide, baseline (2014)'),(2012,'--','Product-table date (2012)'),(2017,'-.','Full-scale (2017)')]:
        ax.axvline(yv,color='#7F7F7F',ls=ls,lw=0.9,label=lab)
    ax.axhline(0,color='black',lw=0.5); ax.set_title(t,fontsize=9,loc='left'); ax.set_ylabel(LAB[o]+', 2008 = 0',fontsize=8)
axs[0].legend(fontsize=6.5,frameon=False,loc='lower left')
fig.suptitle('Figure 6. Rice: production series and alternative insurance dates (descriptive case)',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,'Notes: Paddy rice, national data, 1991–2024. Rice is not pooled with other crops because its insurance timing overlaps with rice-specific policies\n(direct payments, production adjustment, public stockholding). Vertical lines mark alternative official treatment dates.',fontsize=6.8)
fig.tight_layout(rect=[0,0.08,1,0.93]); fig.savefig(OUT+'fig6_rice_descriptive.png',dpi=220); plt.close()
print('figures done')

```

---

# FILE: 05_apfs_descriptives(1).py

```python
# -*- coding: utf-8 -*-
"""05_apfs_descriptives.py — descriptive (non-causal) APFS outputs with thesis display names."""
import numpy as np, pandas as pd, re, matplotlib
matplotlib.use('Agg'); import matplotlib.pyplot as plt
RAW='/mnt/user-data/uploads/'; OUT='/mnt/user-data/outputs/ch5_v2/'
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':9,'axes.spines.top':False,'axes.spines.right':False})
d=pd.read_csv(RAW+'농업정책보험금융원_농작물재해보험_계약된_과수작물_세부현황_20241231.csv',encoding='utf-8-sig')
PROD={'(적과전종합Ⅱ)사과':('Apple','적과전종합Ⅱ'),'복숭아':('Peach',''),'(적과전종합Ⅱ)배':('Pear','적과전종합Ⅱ'),'(적과전종합Ⅱ)떫은감':('Astringent persimmon','적과전종합Ⅱ'),
'자두':('Plum',''),'(종합)감귤(온주밀감류)':('Tangerine','종합 (온주밀감류)'),'밤':('Chestnut',''),'대추':('Jujube',''),'(적과전종합Ⅱ)단감':('Sweet persimmon','적과전종합Ⅱ'),
'매실':('Green plum',''),'포도':('Grape',''),'유자':('Yuja',''),'(종합)감귤(만감류)':('Tangerine','종합 (만감류)'),'참다래':('Kiwifruit',''),
'(농업수입안정)포도':('Grape','농업수입안정 (revenue insurance)'),'복분자':('Korean black raspberry',''),'두릅':('Dureup',''),'블루베리':('Blueberry',''),
'살구':('Apricot',''),'호두':('Walnut',''),'무화과':('Fig',''),'오미자':('Omija',''),'오디':('Mulberry','')}
d['crop_en_display']=d['품목명'].map(lambda x: PROD[x][0]); d['insurance_product_variant']=d['품목명'].map(lambda x: PROD[x][1]); d['apfs_label_original']=d['품목명']
d['program']=np.where(d['품목명'].str.contains('농업수입안정'),'Revenue insurance','Crop disaster insurance')
n0=len(d); ndup=int(d.duplicated().sum())
for c in ['표준수확량','평년수확량','가입수확량','가입가격']: d.loc[d[c]<=0,c]=np.nan
d['ins_to_normal']=d['가입수확량']/d['평년수확량']
cd=d[d.program=='Crop disaster insurance']
# crop-level table
rows=[]
for c,h in cd.groupby('crop_en_display'):
    r=dict(crop=c,records=len(h),product_variants='; '.join(sorted(v for v in h.insurance_product_variant.unique() if v)) or '—',varieties=h['품종명'].nunique())
    for col,lab in [('수령','tree_age'),('주수','trees'),('표준수확량','standard_yield'),('평년수확량','normal_yield'),('가입수확량','insured_yield'),('가입가격','insured_price'),('ins_to_normal','insured_to_normal_ratio')]:
        s=h[col].dropna(); r[lab+'_median']=s.median() if len(s) else np.nan; r[lab+'_p25']=s.quantile(.25) if len(s) else np.nan; r[lab+'_p75']=s.quantile(.75) if len(s) else np.nan
    rr=h.ins_to_normal.dropna(); r['share_ratio_below_1']=(rr<0.9995).mean(); r['share_ratio_equal_1']=((rr>=0.9995)&(rr<=1.0005)).mean(); r['share_ratio_above_1']=(rr>1.0005).mean()
    r['records_zero_or_invalid_yield']=int(h['평년수확량'].isna().sum())
    rows.append(r)
T=pd.DataFrame(rows).sort_values('records',ascending=False); T.to_csv(OUT+'apfs_fruit_records_2024_by_crop.csv',index=False,encoding='utf-8-sig')
pd.DataFrame([dict(item='rows in file',value=n0),dict(item='exact duplicate rows',value=ndup),dict(item='unique contract identifier',value='none in file'),
    dict(item='rows from revenue-insurance grape (excluded from crop-disaster figures)',value=int((d.program!='Crop disaster insurance').sum())),
    dict(item='rows with zero/invalid yield or price fields (set to missing)',value=int(d['평년수확량'].isna().sum())),
    dict(item='observation unit',value='administrative contract-detail record (not necessarily a contract)')]).to_csv(OUT+'apfs_fruit_records_2024_audit.csv',index=False,encoding='utf-8-sig')
major=T.crop.head(8).tolist()
# Figure 7 (Figure B): insured/normal yield
fig,ax=plt.subplots(figsize=(7.4,4.0)); y=np.arange(len(major))
sh=np.array([[T.set_index('crop').loc[c,k] for k in ['share_ratio_below_1','share_ratio_equal_1','share_ratio_above_1']] for c in major])
ax.barh(y,sh[:,0],color='#C55A11',label='Below 1'); ax.barh(y,sh[:,1],left=sh[:,0],color='#A6A6A6',label='Equal to 1'); ax.barh(y,sh[:,2],left=sh[:,0]+sh[:,1],color='#1F4E79',label='Above 1')
ax.set_yticks(y); ax.set_yticklabels(major); ax.invert_yaxis(); ax.set_xlim(0,1); ax.set_xlabel('Share of administrative contract-detail records')
ax.legend(title='Insured yield / normal yield',fontsize=7,title_fontsize=7,frameon=False,loc='lower right')
fig.suptitle('Figure 7. Insured-to-normal yield ratio, eight largest fruit crops, 2024',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,f'Notes: APFS 2024 contract-detail file ({n0:,} rows; {ndup:,} exact duplicates; no contract identifier). Crop disaster insurance only; rows with\nzero or invalid yield fields excluded. Descriptive only.',fontsize=6.8)
fig.tight_layout(rect=[0,0.09,1,0.93]); fig.savefig(OUT+'fig7_insured_to_normal_yield.png',dpi=220); plt.close()
# Figure 8 (Figure C): composition
c=cd.crop_en_display.value_counts()
fig,ax=plt.subplots(figsize=(7.4,4.8)); ax.barh(c.index[::-1],c.values[::-1],color='#1F4E79')
ax.set_xlabel('Number of administrative contract-detail records')
fig.suptitle('Figure 8. Administrative contract-detail records by fruit crop, 2024',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,f'Notes: APFS 2024 contract-detail file, crop disaster insurance only ({len(cd):,} rows; revenue-insurance grape rows excluded). Rows are not\nunique contracts: the file has no contract identifier and contains {ndup:,} exact duplicate rows.',fontsize=6.8)
fig.tight_layout(rect=[0,0.08,1,0.94]); fig.savefig(OUT+'fig8_record_composition.png',dpi=220); plt.close()
# Appendix figure A1: insured price as recorded (unit not verifiable in official sources available)
fig,ax=plt.subplots(figsize=(7.4,4.0))
ax.boxplot([cd.loc[cd.crop_en_display==m,'가입가격'].dropna() for m in major],vert=False,showfliers=False,whis=(5,95),widths=0.6)
ax.set_yticks(range(1,len(major)+1)); ax.set_yticklabels(major); ax.invert_yaxis(); ax.set_xscale('log'); ax.set_xlabel('Insured price as recorded in the APFS file (log scale)')
fig.suptitle('Appendix Figure A1. Insured price field by fruit crop, 2024',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,'Notes: Box = interquartile range; whiskers = 5th–95th percentiles. The measurement unit of this field is not defined in the Yearbook or the 2026\nimplementation guideline; values are shown as recorded and should not be compared with market prices.',fontsize=6.8)
fig.tight_layout(rect=[0,0.09,1,0.93]); fig.savefig(OUT+'figA1_insured_price_appendix.png',dpi=220); plt.close()
# National series figures
def rd(f):
    for e in ['utf-8-sig','cp949']:
        try: return pd.read_csv(RAW+f,encoding=e)
        except Exception: pass
pre='농업정책보험금융원_농작물재해보험_'
E=rd(pre+'연도별_가입_현황_20241231.csv'); E.columns=[re.sub(r'\s+','',c) for c in E.columns]
for c in E.columns: E[c]=pd.to_numeric(E[c].astype(str).str.replace(',','').str.replace('년',''),errors='coerce')
Pm=rd(pre+'연도별_지급현황_20231231.csv'); Pm.columns=[re.sub(r'\s+','',c) for c in Pm.columns]
for c in Pm.columns: Pm[c]=pd.to_numeric(Pm[c].astype(str).str.replace(',','').str.replace('년',''),errors='coerce')
N=E.merge(Pm,on='연도',how='left')
fig,axs=plt.subplots(1,2,figsize=(11,3.8))
axs[0].plot(N['연도'],N['면적가입률(퍼센트)'],color='#1F4E79',marker='o',ms=3); axs[0].set_ylabel('Area enrollment rate (%)'); axs[0].set_title('A. Area enrollment rate, 2001–2024',fontsize=9,loc='left')
axs[1].bar(N['연도'],N['손해율'],color='#5B9BD5'); axs[1].axhline(100,color='black',lw=0.6,ls='--'); axs[1].set_ylabel('Loss ratio (%)'); axs[1].set_title('B. Loss ratio, 2001–2023',fontsize=9,loc='left')
fig.suptitle('Figure 9. Crop disaster insurance: national participation and loss experience',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,'Notes: APFS public national series. The enrollment-rate denominator (eligible area) expands as crops are added (e.g., rice from 2009), so the rate is not\ncomparable across years without adjustment. Loss ratio = indemnities / premium as defined by APFS. Descriptive only.',fontsize=6.8)
fig.tight_layout(rect=[0,0.1,1,0.92]); fig.savefig(OUT+'fig9_apfs_national_trends.png',dpi=220); plt.close()
sh=pd.DataFrame({'Central government':N['국가보조보험료(백만원)'],'Provinces':N['시도보조보험료(백만원)'],'Municipalities':N['시군구보조보험료(백만원)'],'Farmers':N['농가부담금(백만원)']}).div(N['순보험료(백만원)'],axis=0)
fig,ax=plt.subplots(figsize=(8,3.9)); bottom=np.zeros(len(N))
for col,cl in zip(sh.columns,['#1F4E79','#5B9BD5','#9DC3E6','#C55A11']):
    ax.bar(N['연도'],sh[col],bottom=bottom,color=cl,label=col); bottom+=sh[col].fillna(0).values
ax.axvspan(2009.5,2011.5,facecolor='none',hatch='///',edgecolor='#7F7F7F',lw=0)
ax.set_ylabel('Share of net premium'); ax.legend(fontsize=7,frameon=False,ncol=4,loc='upper center',bbox_to_anchor=(0.5,1.12))
fig.suptitle('Figure 10. Financing of net premiums by payer, 2001–2024',fontsize=10,x=0.01,ha='left')
fig.text(0.01,0.01,'Notes: APFS public national series. Hatched years (2010–2011): the reported components sum to approximately 75% of net premium, and the\nprovincial and municipal subsidy fields are recorded as zero. The public dataset does not explain the residual. Descriptive only.',fontsize=6.8)
fig.tight_layout(rect=[0,0.1,1,0.9]); fig.savefig(OUT+'fig10_apfs_financing_shares.png',dpi=220); plt.close()
N.to_csv(OUT+'apfs_national_series.csv',index=False,encoding='utf-8-sig')
print(T[['crop','records','product_variants','insured_price_median','insured_to_normal_ratio_median']].head(10).to_string())

```

---

# FILE: 06_final_tables(1).py

```python
# -*- coding: utf-8 -*-
"""06_final_tables.py — final master panel with provenance + price columns, nomenclature appendix, regression tables."""
import numpy as np, pandas as pd
from openpyxl import load_workbook
from openpyxl.styles import Font, PatternFill, Alignment
OUT='/mnt/user-data/outputs/ch5_v2/'
P=pd.read_csv(OUT+'panel_production_stage1.csv'); PR=pd.read_csv(OUT+'price_annual_panel.csv'); LD=pd.read_csv(OUT+'price_linking_diagnostics.csv')
PX=pd.read_csv(OUT+'price_item_crosswalk.csv'); S=pd.read_csv(OUT+'results_summary_all_specs.csv'); Dy=pd.read_csv(OUT+'results_dynamic_all_specs.csv')
TR=pd.read_csv(OUT+'treatment_coding_input.csv')
# ---- price unit mapping
PU={'spring_potato':'potato','highland_potato':'potato','autumn_potato':'potato','spring_napa':'napa_cabbage','highland_napa':'napa_cabbage','autumn_napa':'napa_cabbage',
    'winter_napa':'napa_cabbage','spring_radish':'radish','highland_radish':'radish','autumn_radish':'radish','winter_radish':'radish','large_green_onion':'green_onion','small_green_onion':'green_onion'}
P['price_unit']=P.crop_id.map(lambda c: PU.get(c,c if c in set(PX.price_unit) else np.nan))
m=PR[PR.link_window=='full_2005_2012'][['price_unit','year','real_old','real_new','linked','real_linked','ln_real_linked','ln_real_new','ln_real_old']]
m=m.rename(columns={'real_old':'relative_price_old','real_new':'relative_price_new','real_linked':'relative_price_index','ln_real_linked':'ln_rel_price_linked','ln_real_new':'ln_rel_price_new','ln_real_old':'ln_rel_price_old'})
LQ=pd.read_csv(OUT+'price_linked_quarterly.csv'); LQ=LQ[LQ.link_window=='full_2005_2012']
nom=LQ.groupby(['price_unit','year']).agg(old_price_index=('old_price_index','mean'),new_price_index=('new_price_index','mean'),link_factor=('link_factor','first'),link_period=('link_period','first')).reset_index()
P=P.merge(nom,on=['price_unit','year'],how='left').merge(m.rename(columns={'linked':'linked_price_index'}),on=['price_unit','year'],how='left')
P=P.merge(LD[['price_unit','match_class','linkable_quarterly_rule','linkable_annual_rule','price_sample_main','price_sample_strict']].rename(columns={'match_class':'price_definition_match'}),on='price_unit',how='left')
P=P.merge(PX[['price_unit','item_1J49','item_1J60']],on='price_unit',how='left')
P['kosis_price_label_original']=P.apply(lambda r: f"DT_1J49: {r.item_1J49} | DT_1J60: {r.item_1J60}" if isinstance(r.item_1J49,str) else '',axis=1)
APFS={'apple':'사과','pear':'배','sweet_persimmon':'단감','astringent_persimmon':'떫은감','tangerine':'감귤','peach':'복숭아','grape':'포도','plum':'자두','green_plum':'매실',
 'rice':'벼','soybean':'콩','red_bean':'팥','corn':'옥수수','sweet_potato':'고구마','spring_potato':'봄감자','highland_potato':'고랭지감자','autumn_potato':'가을감자',
 'barley':'보리','wheat':'밀','onion':'양파','red_pepper':'고추','garlic':'마늘','cabbage':'양배추','highland_radish':'고랭지무','winter_radish':'월동무','autumn_radish':'가을무',
 'highland_napa':'고랭지배추','winter_napa':'월동배추','autumn_napa':'가을배추','spring_napa':'봄배추','large_green_onion':'대파','small_green_onion':'쪽파(실파)','carrot':'당근','spinach':'시금치'}
VAR={'apple':'적과전종합 (2024 records: 적과전종합Ⅱ)','pear':'적과전종합 (2024 records: 적과전종합Ⅱ)','sweet_persimmon':'적과전종합 (2024 records: 적과전종합Ⅱ)',
 'astringent_persimmon':'적과전종합 (2024 records: 적과전종합Ⅱ)','tangerine':'종합 (온주밀감류, 만감류)','grape':'종합; separate 농업수입안정 product exists'}
P['apfs_label_original']=P.crop_id.map(APFS).fillna('')
P['insurance_product_variant']=P.crop_id.map(lambda c: VAR.get(c,'종합 (see Yearbook 2025 pp.44–51)' if c in APFS else ''))
P=P.rename(columns={'kosis_label':'kosis_production_label_original'}) if 'kosis_production_label_original' not in P.columns else P.drop(columns=['kosis_label'],errors='ignore')
keep=['crop_id','crop_en_display','crop_ko_official','crop_form','crop_group','perennial','role','year','source_file','table_id','kosis_production_label_original',
 'kosis_price_label_original','apfs_label_original','insurance_product_variant',
 'area_ha','yield_kg10a','production_t','total_orchard_area_ha','bearing_area_ha','yield_per_bearing_area_kg10a','prod_per_total_orchard_kg10a',
 'ln_area','ln_yield','ln_production','ln_total_orchard_area','ln_area_harmonized','ln_bearing_area','ln_yield_per_bearing_area','identity_gap',
 'pilot_year','national_year','national_year_alt_table','fullscale_year','timing_confidence','clean_pre','transition','national_treatment','event_time','event_time_pilot','treatment_cohort',
 'price_unit','old_price_index','new_price_index','link_factor','link_period','linked_price_index','relative_price_index','ln_rel_price_linked','ln_rel_price_new','ln_rel_price_old',
 'price_definition_match','linkable_quarterly_rule','linkable_annual_rule','price_sample_main','price_sample_strict']
P[keep].sort_values(['crop_id','year']).to_csv(OUT+'ch5_master_panel_national_v2.csv',index=False,encoding='utf-8-sig')
# ---- nomenclature appendix
SCI={'apple':'Malus domestica','pear':'Pyrus pyrifolia','sweet_persimmon':'Diospyros kaki (non-astringent cultivars)','astringent_persimmon':'Diospyros kaki (astringent cultivars)',
 'tangerine':'Citrus unshiu and other Citrus spp.','peach':'Prunus persica','grape':'Vitis spp.','plum':'Prunus salicina','green_plum':'Prunus mume','rice':'Oryza sativa',
 'soybean':'Glycine max','red_bean':'Vigna angularis','mung_bean':'Vigna radiata','other_pulses':'—','corn':'Zea mays','sweet_potato':'Ipomoea batatas',
 'spring_potato':'Solanum tuberosum','highland_potato':'Solanum tuberosum','autumn_potato':'Solanum tuberosum','barley':'Hordeum vulgare','malting_barley':'Hordeum vulgare',
 'wheat':'Triticum aestivum','spring_radish':'Raphanus sativus','highland_radish':'Raphanus sativus','autumn_radish':'Raphanus sativus','winter_radish':'Raphanus sativus',
 'carrot':'Daucus carota subsp. sativus','spring_napa':'Brassica rapa subsp. pekinensis','highland_napa':'Brassica rapa subsp. pekinensis','autumn_napa':'Brassica rapa subsp. pekinensis',
 'winter_napa':'Brassica rapa subsp. pekinensis','cabbage':'Brassica oleracea var. capitata','spinach':'Spinacia oleracea','leaf_lettuce':'Lactuca sativa',
 'red_pepper':'Capsicum annuum','large_green_onion':'Allium fistulosum','small_green_onion':'Allium × wakegi','onion':'Allium cepa','garlic':'Allium sativum',
 'ginger':'Zingiber officinale','sesame':'Sesamum indicum','perilla':'Perilla frutescens','peanut':'Arachis hypogaea'}
NOTES={'rice':'Paddy rice (논벼); production in rough-rice (조곡) tonnes.','barley':'KOSIS 겉보리+쌀보리; insurance coverage of barley types not verified.',
 'red_pepper':'KOSIS dried red pepper (건고추); insurance covers open-field red pepper.','leaf_lettuce':'KOSIS 노지상추 (leaf lettuce), distinct from 양상추 (Lettuce).',
 'spinach':'Open-field spinach; greenhouse spinach insured separately from 2013.','corn':'KOSIS series may include forage corn.','winter_radish':'Series from 2014 (form split).',
 'winter_napa':'Series from 2014 (form split).','sweet_persimmon':'Separate series from 1998.','astringent_persimmon':'Separate series from 1998.','green_plum':'KOSIS series from 2019 only.',
 'tangerine':'KOSIS 감귤 (all citrus).','spring_potato':'Price index covers all potatoes.','peanut':'Shelled peanut (알땅콩).'}
N=P.drop_duplicates('crop_id')[['crop_id','crop_en_display','crop_ko_official','kosis_production_label_original','kosis_price_label_original','apfs_label_original','insurance_product_variant']].copy()
N['scientific_name']=N.crop_id.map(SCI); N['notes_on_statistical_definition']=N.crop_id.map(NOTES).fillna('')
N=N.rename(columns={'crop_en_display':'Thesis English Name','crop_ko_official':'Official Korean Name','scientific_name':'Scientific Name','kosis_production_label_original':'KOSIS Production Label',
 'kosis_price_label_original':'KOSIS Price Label','apfs_label_original':'APFS / Yearbook Label','insurance_product_variant':'Insurance Product Variant','notes_on_statistical_definition':'Notes on Statistical Definition'})
N=N[['Thesis English Name','Official Korean Name','Scientific Name','KOSIS Production Label','KOSIS Price Label','APFS / Yearbook Label','Insurance Product Variant','Notes on Statistical Definition']]
N.to_csv(OUT+'appendix_crop_nomenclature.csv',index=False,encoding='utf-8-sig')
# ---- regression tables
SPEC={'CS-A (preferred)':'Custom group-time DiD, final clean pre-pilot year (preferred)',
 'CS-B (mean of all clean-pre years)':'Custom group-time DiD, mean of all clean pre-pilot years',
 'CS-B5 (mean of last 5 clean-pre years)':'Custom group-time DiD, mean of last 5 clean pre-pilot years',
 'Imputation (FE on clean cells)':'Imputation estimator (two-way FE fitted on clean cells)',
 'CS-A main (exact match, annual linking rule)':'Custom group-time DiD, final clean pre-pilot year: main price sample (exact match, annual linking rule)',
 'CS-B main':'Custom group-time DiD, mean of all clean pre-pilot years: main price sample'}
def lab(sp): return SPEC.get(sp,sp)
def fmt(r):
    lo,hi=r.get('ci_lo_wild',np.nan),r.get('ci_hi_wild',np.nan)
    return pd.Series(dict(Estimated_change=round(r.est,3),SE_crop_clustered=round(r.se_cluster,3),
        CI95_wild_bootstrap=(f"[{lo:.3f}, {hi:.3f}]" if pd.notna(lo) else '—'),p_wild_bootstrap=round(r.p_wild,3) if pd.notna(r.p_wild) else np.nan,
        p_cluster_normal=round(r.p_normal_cluster,3) if 'p_normal_cluster' in r and pd.notna(r.p_normal_cluster) else np.nan,
        Treated_crops=int(r.n_treated) if pd.notna(r.n_treated) else np.nan,Clusters=int(r.G) if pd.notna(r.G) else np.nan,
        Pretrend_Wald_p=round(r.pre_p_boot,3) if 'pre_p_boot' in r and pd.notna(r.pre_p_boot) else np.nan))
OL={'ln_area':'Area','ln_yield':'Yield','ln_production':'Production','ln_area_harmonized':'Orchard area','ln_real_linked':'Relative price','ln_real_new':'Relative price (2005–2024 series)'}
def tab(sample,specs,outcomes):
    rows=[]
    for sp in specs:
        for o in outcomes:
            x=S[(S['sample']==sample)&(S.spec==sp)&(S.outcome==o)]
            if len(x): rows.append(pd.concat([pd.Series(dict(Specification=lab(sp),Outcome=OL.get(o,o))),fmt(x.iloc[0])]))
    return pd.DataFrame(rows)
T={}
T['T1_annual_main']=tab('annual',['CS-A (preferred)'],['ln_area','ln_yield','ln_production'])
dd=Dy[(Dy['sample']=='annual')&(Dy.spec=='CS-A (preferred)')].copy(); dd['Outcome']=dd.outcome.map(OL)
T['T2_annual_dynamic']=dd[['Outcome','event_time','est','se_cluster','ci_lo_wild','ci_hi_wild','p_wild','n_treated','n_ctrl_min','n_ctrl_max','treated_crops']].round(4)
T['T3_estimator_comparison']=tab('annual',['CS-A (preferred)','CS-B (mean of all clean-pre years)','CS-B5 (mean of last 5 clean-pre years)','Imputation (FE on clean cells)','TWFE static, clean cells (benchmark)','TWFE static, Han-style naive coding (benchmark)'],['ln_area','ln_yield','ln_production'])
T['T4_annual_robustness']=tab('annual',['CS-A (preferred)','Dates: product-table nationwide year','Dates: pilot-year clock (no transition exclusion)','Controls: excl. other pulses',
  'Controls: excl. likely spillover (leaf lettuce, spinach, malting barley)','Controls: field crops only','Controls: excl. uncertain seasonal forms','Leave out cohort 2012','Leave out cohort 2013','Leave out cohort 2015'],['ln_area','ln_yield','ln_production'])
T['T5_leave_one_crop_out']=tab('annual',[s for s in S.spec.unique() if s.startswith('Leave out ') and 'cohort' not in s],['ln_area','ln_yield','ln_production'])
T['T6_cohort_pretrends']=tab('annual',['Cohort 2012 only','Cohort 2013 only','Cohort 2015 only'],['ln_area','ln_yield','ln_production'])
T['T7_fruit']=tab('fruit',S[S['sample']=='fruit'].spec.unique().tolist(),['ln_area_harmonized','ln_production'])
dd=Dy[(Dy['sample']=='fruit')&(Dy.spec=='CS-A (preferred)')].copy(); dd['Outcome']=dd.outcome.map(OL)
T['T8_fruit_dynamic']=dd[['Outcome','event_time','est','se_cluster','ci_lo_wild','ci_hi_wild','p_wild','n_treated','n_ctrl_min','treated_crops']].round(4)
T['T9_price']=tab('price',S[S['sample']=='price'].spec.unique().tolist(),['ln_real_linked','ln_real_new'])
dd=Dy[(Dy['sample']=='price')&(Dy.spec=='CS-A main (exact match, annual linking rule)')].copy()
T['T10_price_dynamic']=dd[['event_time','est','se_cluster','ci_lo_wild','ci_hi_wild','p_wild','n_treated','n_ctrl_min','treated_crops']].round(4)
R=pd.read_csv(OUT+'results_rice_case.csv'); R['Outcome']=R.outcome.map(OL)
T['T11_rice_case']=R.pivot_table(index=['Outcome','event_time'],columns='dating',values='est').round(3).reset_index()
# support tables
sup=[]
for (s,sp,o),g in Dy.groupby(['sample','spec','outcome']):
    if sp in ('CS-A (preferred)','CS-A main (exact match, annual linking rule)'):
        for r in g.itertuples(): sup.append(dict(sample=s,outcome=OL.get(o,o),event_time=r.event_time,treated_crops_n=r.n_treated,controls_min=r.n_ctrl_min,controls_max=r.n_ctrl_max,treated=r.treated_crops))
T['T12_event_time_support']=pd.DataFrame(sup)
# control composition by cohort (annual)
cc=[]
for g,tr in [(2012,['soybean','onion']),(2013,['sweet_potato','corn','garlic','spring_potato']),(2015,['red_pepper'])]:
    for c in sorted(P[(P.role=='control_pool')].crop_id.unique()):
        x=P[(P.crop_id==c)&(P.year.between(1991,2024))&P.ln_production.notna()&((P.pilot_year.isna())|(P.year<P.pilot_year))]
        if len(x): cc.append(dict(cohort=g,control=x.crop_en_display.iloc[0],group=x.crop_group.iloc[0],clean_years=f"{x.year.min()}–{x.year.max()}",clean_after_cohort_year=int((x.year>=g).sum())))
T['T13_control_composition']=pd.DataFrame(cc)
# pre-trend slope heuristic
sl=[]
for (s,sp,o),g in Dy[Dy.spec.isin(['CS-A (preferred)','CS-A main (exact match, annual linking rule)'])].groupby(['sample','spec','outcome']):
    pre=g[g.event_time<0]
    if len(pre)>=3:
        b=np.polyfit(pre.event_time.astype(float),pre.est,1)[0]; sl.append(dict(sample=s,outcome=OL.get(o,o),pre_slope_per_year=round(b,4),pre_coefs=len(pre),mean_pre=round(pre.est.mean(),3)))
T['T14_pretrend_slopes']=pd.DataFrame(sl)
T['T15_price_linking']=LD
T['T19_label_map']=pd.DataFrame([dict(internal_id=k,thesis_label=v) for k,v in {**SPEC,**{'ln_real_linked':'ln_rel_price_linked (Log relative farm-gate price index, linked)','ln_real_new':'ln_rel_price_new (Log relative farm-gate price index, 2005–2024 series)','real_linked':'relative_price_index'}}.items()])
for k in ['T2_annual_dynamic','T8_fruit_dynamic','T10_price_dynamic']: T[k]=T[k].rename(columns={'est':'estimated_change'})
T['T16_nomenclature_appendix']=N
T['T17_price_item_crosswalk']=PX
T['T18_treatment_coding']=TR
with pd.ExcelWriter(OUT+'ch5_results_tables.xlsx') as w:
    for k,v in T.items(): v.to_excel(w,sheet_name=k[:31],index=False)
wb=load_workbook(OUT+'ch5_results_tables.xlsx')
for ws in wb.worksheets:
    for c in ws[1]: c.font=Font(name='Arial',bold=True,color='FFFFFF'); c.fill=PatternFill('solid',fgColor='1F4E78'); c.alignment=Alignment(wrap_text=True)
    for row in ws.iter_rows(min_row=2):
        for c in row: c.font=Font(name='Arial',size=9)
    for col in ws.columns:
        L=max(len(str(c.value)) if c.value is not None else 0 for c in col[:100]); ws.column_dimensions[col[0].column_letter].width=min(max(9,L*0.95),55)
    ws.freeze_panes='B2'
wb.save(OUT+'ch5_results_tables.xlsx')
for k in ['T1_annual_main','T3_estimator_comparison','T6_cohort_pretrends','T14_pretrend_slopes','T9_price']: print(k); print(T[k].to_string())

```

---

# FILE: run_all(4).sh

```bash
#!/bin/bash
# Reproduce every Chapter 5 output from raw uploads (read-only). Fixed seed (20260927) in est_engine.py.
set -e; cd "$(dirname "$0")"
python3 01_build_panel.py          # production panel, names, treatment flags, dropped-obs log
python3 02_build_prices.py         # price crosswalk, DT_1J49 x DT_1J60 linking diagnostics, linked panels, overlap figure
python3 03_estimate.py > run03.log # all estimations and robustness
python3 04_figures.py              # event-study, estimator, robustness, fruit, price, rice figures
python3 05_apfs_descriptives.py    # descriptive APFS outputs
python3 06_final_tables.py         # final master panel v2, nomenclature appendix, results workbook

```

---
