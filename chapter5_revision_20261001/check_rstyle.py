"""Validate frozen values, complete figure files, and editable Word equations."""
from pathlib import Path
import hashlib,json,zipfile
import pandas as pd
import numpy as np
from PIL import Image
import fitz
from docx import Document
from lxml import etree
H=Path(__file__).resolve().parent;O=H/'outputs';F=H/'figures_r'
checks={}
def check(k,v):
 checks[k]=bool(v)
 if not v:raise AssertionError(k)
Y=['ln_area','ln_yield','ln_production'];labels=dict(zip(Y,['Area','Yield','Production']))
for name,src,cols in [('fig5_2_crop_contrasts','crop_mean_contrasts.csv',['contrast','events','equal_contribution','crop_order']),('fig5_3_post_contrasts','post_event_points.csv',['event_time','est','min_donors','max_donors'])]:
 a=pd.read_csv(O/src);b=pd.read_csv(F/(name+'_plotdata.csv'))
 check(name+'_values',np.allclose(a[cols],b[cols],atol=1e-14,rtol=0))
 check(name+'_outcomes',list(a.outcome.map(labels))==list(b.outcome))
a=pd.read_csv(O/'pretrend_mean_paths.csv');b=pd.read_csv(F/'fig5_1_pretrends_plotdata.csv')
for v,series,col in [('original','Treated crops','treated'),('original','Original donors','donor'),('exclude_spring','Exclude two spring series','donor')]:
 x=a[a.variant==v];z=b[b.series==series]
 check('pretrend_'+series,np.allclose(x[col],z.value,atol=1e-14,rtol=0) and list(x.pilot_event)==list(z.x) and list(x.outcome.map(labels))==list(z.outcome))
a=pd.read_csv(O/'pretrend_crop_paths.csv');a=a[a.variant=='original'];b=pd.read_csv(F/'figA5_1_crop_pretrends_plotdata.csv')
check('individual_paths',np.allclose(a[['gap','pilot_event','treated','donor','n_donors']],b[['gap','pilot_event','treated','donor','n_donors']],atol=1e-14,rtol=0) and list(a.crop)==list(b.crop))
a=pd.read_csv(O/'descriptive_statistics.csv');a=a[(a.variant=='original')&(a.design_outcome=='ln_area')];b=pd.read_csv(H/'tables_r/table5_2.csv',keep_default_na=False)
for j,var in enumerate(['area_ha','yield_kg10a','production_t']):
 for k,g in enumerate(['Treated reference','Treated target','Donor reference','Donor target']):
  r=a[(a.variable==var)&(a.group==g)].iloc[0];z=b.iloc[j*5+1+k]
  actual=[float(str(z[x]).replace(',','')) for x in ['Mean','S.D.','Min.','Max.','Obs.','Crops']]
  check('table5_2_'+var+'_'+g,actual==[round(r[x]) for x in ['mean','sd','min','max','N','crops']])
a=pd.read_csv(O/'main_diagnostics_frozen.csv');b=pd.read_csv(H/'tables_r/table5_3.csv',keep_default_na=False)
for j,v in enumerate(['original','exclude_spring']):
 for y,label in labels.items():
  r=a[(a.variant==v)&(a.outcome==y)].iloc[0]
  expected=[f'{r.est:.3f}',f'({r.se:.3f})',f'[{r.ci_lo:.3f}, {r.ci_hi:.3f}]',f'{r.p:.3f}',str(int(r.treated_crops)),str(int(r.contributing_controls))]
  check('table5_3_'+v+'_'+y,b.iloc[j*7+1:j*7+7][label].tolist()==expected)
for name in ['fig5_1_pretrends','fig5_2_crop_contrasts','fig5_3_post_contrasts','figA5_1_crop_pretrends']:
 with Image.open(F/(name+'.png')) as im:
  im.load();check(name+'_png_complete',im.width==2400)
 with fitz.open(F/(name+'.pdf')) as pdf:
  check(name+'_pdf_page',len(pdf)==1)
  pix=pdf[0].get_pixmap()
  check(name+'_pdf_nonblank',np.frombuffer(pix.samples,dtype=np.uint8).std()>2)
  check(name+'_pdf_text',len(pdf[0].get_text())>100)
old=Document(H/'Chapter5_Revised.docx');new=Document(H/'Chapter5_RStyle.docx')
def maths(d):return [etree.tostring(x,method='c14n') for x in d.element.xpath('.//m:oMath')]
check('editable_math_preserved',maths(old)==maths(new))
check('nine_editable_tables',len(new.tables)==9)
check('four_embedded_figures',len(new.inline_shapes)==4)
for i in [0,3,4,5,6,7,8]:
 old_rows=[[c.text for c in r.cells] for r in old.tables[i].rows]
 new_rows=[[c.text for c in r.cells] for r in new.tables[i].rows]
 for j,v in enumerate(new_rows[0]):
  if v.startswith('('):new_rows[0][j]=v.split('\n',1)[1]
 check('table_'+str(i)+'_unchanged',old_rows==new_rows)
qa=H/'qa_rstyle';qa.mkdir(exist_ok=True)
with fitz.open(qa/'Chapter5_RStyle.pdf') as pdf:
 check('word_pdf_has_content',len(pdf)>=20 and all(len(p.get_text().strip())>10 for p in pdf))
 for i,p in enumerate(pdf):p.get_pixmap(matrix=fitz.Matrix(1,1)).save(qa/f'page-{i+1}.png')
 pages=len(pdf)
report={'checks':checks,'passed':sum(checks.values()),'r_executed':True,'new_models':False,'pages':pages,'native_math':len(maths(new)),'visual_review':'Current CI rendering exported for review; automated checks do not replace visual review. Earlier local 23-page styling reviewed before environment loss.','docx_sha256':hashlib.sha256((H/'Chapter5_RStyle.docx').read_bytes()).hexdigest(),'source_csv_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob('*.csv')}}
(O/'rstyle_validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'passed':sum(checks.values()),'total':len(checks),'pages':pages}))
