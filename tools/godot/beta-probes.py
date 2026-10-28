"""Run each robustness probe in its own process so one crash cannot hide the others."""
from pathlib import Path
import argparse
import json
import os
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
WORK = (ROOT/'../../work/beta-rc2-2026-10-28/probes').resolve()
CASES = ['matrix','profiles','migrations','legacy-load','legacy-forecast','openings','save-truncated','save-checksum',
         'save-array','save-future','save-seed-long','save-state-array',
         'save-command-null','save-command-array','save-kind-array','save-order-null',
         'save-money-edit','save-size']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only', nargs='+', choices=CASES)
    parser.add_argument('--label', default='fresh')
    args = parser.parse_args()
    WORK.mkdir(parents=True,exist_ok=True)
    run = WORK/(args.label+'-'+str(time.time_ns())); run.mkdir()
    binary = os.environ.get('GODOT_BIN',str(ROOT/'../../work/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'))
    env = {**os.environ,'APPDATA':str(WORK/'profile'),'LOCALAPPDATA':str(WORK/'local-profile')}
    result = {'edition':29,'scope':'New current-edition synthetic robustness probes; no production changes.','cases':[]}
    for case in args.only or CASES:
        target = run/case; target.mkdir(exist_ok=True)
        entry = {'case':case}; started = time.monotonic()
        try:
            executed = subprocess.run([binary,'--headless','--max-fps','120','--quit-after','2000','--path',str(ROOT/'godot'),
                '--log-file',str(target/'engine-live.log'),'--script',str(ROOT/'tools/godot/beta-probes.gd'),'--','--beta-dir='+str(target),
                '--beta-case='+case],cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf-8',
                errors='replace',timeout=3600 if case=='migrations' else 900 if case=='openings' else 300,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
            log = executed.stdout+executed.stderr
            (target/'engine.log').write_text(log,encoding='utf-8')
            report = target/(case+'.json')
            entry.update(exitCode=executed.returncode,report=json.loads(report.read_text(encoding='utf-8')) if report.exists() else None,
                runtimeErrors=[line for line in log.splitlines() if 'SCRIPT ERROR:' in line or line.startswith('ERROR:')])
            entry['ok'] = executed.returncode==0 and entry['report'] is not None and not entry['report']['failures'] and not entry['runtimeErrors']
        except subprocess.TimeoutExpired:
            entry.update(ok=False,error='Probe timeout')
        entry['seconds'] = round(time.monotonic()-started,3)
        entry['directory'] = str(target.relative_to(WORK))
        result['cases'].append(entry)
        (run/'summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print('BETA_PROBE '+json.dumps({key:entry.get(key) for key in ['case','ok','seconds','runtimeErrors']},ensure_ascii=False),flush=True)
    raise SystemExit(0 if all(item['ok'] for item in result['cases']) else 1)


if __name__=='__main__': main()
