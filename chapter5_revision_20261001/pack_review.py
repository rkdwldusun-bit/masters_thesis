"""Create a self-contained review ZIP with repository-relative paths.
Official source PDFs and private uploaded manuscripts are intentionally not included.
"""
from pathlib import Path
import zipfile,json,hashlib
H=Path(__file__).resolve().parent;R=H.parent
files=[p for p in H.rglob('*') if p.is_file() and p.suffix!='.zip' and '__pycache__' not in p.parts and 'stata_exports' not in p.parts]
inputs=['verified_results/verified_master_panel.csv','verified_results/verified_treatment_coding.csv','verified_results/verified_results_summary.csv','verified_results/verified_price_results.csv','verified_results/verified_rice_case.csv','reanalysis_20260929/original_engine.py','reanalysis_20260930/PLAN.md','reanalysis_20260930/core.py','reanalysis_20260930/run_analysis.py','reanalysis_20260930/run_simulation.py']
inputs += ['reanalysis_20260930/outputs/'+n for n in ['manifest.json','main_inference.csv','crop_event_contrasts.csv','balanced_pretrends.csv','date_sensitivity.csv','simulation_calibration.csv','simulation_manifest.json','simulation_parameters.csv']]
files.extend(R/p for p in inputs)
archive=H/'Chapter5_Review_Package.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(files):z.write(p,p.relative_to(R))
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print(json.dumps({'zip':str(archive),'files':len(files),'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}))
