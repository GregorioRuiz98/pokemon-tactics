"""Extract the RC in a new folder and launch its bundled engine offline."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
import zipfile

ROOT = Path(__file__).resolve().parents[2]
project = (ROOT/'godot/project.godot').read_text(encoding='utf-8')
version = re.search(r'config/version="([^"]+)"',project)[1]
stage = re.search(r'config/qa_stage=(\d+)',project)[1]
work = Path(os.environ.get('GODOT_QA_DIR',str(ROOT/f'../../work/qa-sprint-{stage}'))).resolve()
work.mkdir(parents=True,exist_ok=True)
slug = re.search(r'config/artifact_slug="([^"]+)"',project)
slug = slug[1] if slug else 'pokemon-tactics'
executable = re.search(r'config/executable_name="([^"]+)"',project)
executable = executable[1] if executable else 'PokemonTactics.exe'
archive = (ROOT/f'../releases/{slug}-{version}/{slug}-{version}-windows.zip').resolve()
target = work/f'clean-extract-{time.time_ns()}'
target.mkdir(parents=True)
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    for name in package.namelist():
        resolved = (target/name).resolve()
        assert resolved.is_relative_to(target), 'Archive escapes target'
    package.extractall(target)
env = {**os.environ,'APPDATA':str(target/'isolated-profile'),'LOCALAPPDATA':str(target/'isolated-local'),'PATH':os.path.join(os.environ['SystemRoot'],'System32')}
assert shutil.which('godot',path=env['PATH']) is None
report_path = target/'startup.json'
exe = target/'windows'/executable
result = subprocess.run([str(exe),'--audio-driver','Dummy','--','--smoke-report='+str(report_path)],cwd=exe.parent,env=env,capture_output=True,text=True,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
assert result.returncode==0 and report_path.is_file(), result.stderr
report = json.loads(report_path.read_text(encoding='utf-8'))
assert report['titleVisible'] and report['version']==version and not report['editorHint']
helper = subprocess.run([os.path.join(env['PATH'],'cmd.exe'),'/c',str(exe.parent/'Comprobar-equipo.cmd'),'--sin-pausa'],cwd=exe.parent,env=env,capture_output=True,text=True,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
assert helper.returncode==0,helper.stdout+helper.stderr
record = {**report,'executable':executable,'archiveExtracted':True,'isolatedProfile':True,'godotNotOnPath':True,'diagnosticHelperPassed':True,'externalHardwareTest':False,'humanPlaytest':False,'exeSha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'zipSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'scope':'Exact ZIP extracted to a fresh directory on the same physical PC. Engine embedded, no Godot on PATH. Audio uses Dummy for smoke; human audio and external hardware remain pending.'}
(work/'clean-startup.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(record,ensure_ascii=False))
