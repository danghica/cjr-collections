from pathlib import Path
import os,sys
ROOT=Path(__file__).resolve().parents[1]
CORE=Path(os.environ.get('CJR_CORE_DIR',ROOT.parent/'cjr-core')).resolve()
sys.path.insert(0,str(CORE))
os.environ['CJR_PROJECT_ROOT']=str(ROOT)
