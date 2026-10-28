"""Run existing offline QA in separate folders, retaining failures and provenance."""
from pathlib import Path
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
WORK = (ROOT/'../../work/beta-rc2-2026-10-28').resolve()
LANES = {
    'ui-followup': ['edge-portrait','edge-cycles','edge-seeds','edge-shop'],
    'legacy-controls': ['legacy-release','legacy-expedition','legacy-journey'],
    'ui-edges': ['edge-profile','edge-corrupt-load'],
    'campaign': ['qa-closing-playthrough-export','qa-closing-playthrough'],
    'core': ['test-closing','test-collection','test-quality','test-review','test-climate',
             'test-power','test-sleep','test-kanto','test-variety','test-trainer','test-controls',
             'test-spatial','test-economy','test-adventure','test-shop-batch','test-revive',
             'test-gym-caps','test-level-hp','test-growth','test-letsgo','test-tactics',
             'test-traits','test-expedition-abilities','test-progression','test-shop',
             'test-roster','test-scale','test-campaign-edges','test-release','test-finale',
             'test-expedition','test-campaign','test-letsgo-journey','test-tactics-journey',
             'test-traits-journey','test-journey','test'],
    'interface': ['qa-briefing-export','qa-briefing','qa-quality-export','qa-quality',
                  'qa-profile-export','qa-profile','qa-collection-export','qa-collection',
                  'qa-closing-usability-export','qa-closing-usability','qa-review-export','qa-review',
                  'qa-seeds-export','qa-seeds','qa-attack-effects-export','qa-attack-effects',
                  'qa-semantic-export','qa-semantic','qa-input-export','qa-input',
                  'qa-trainer-export','qa-trainer','qa-shop-export','qa-shop',
                  'qa-closing-performance-export','qa-closing-performance'],
}


def stamp():
    return datetime.now(timezone.utc).isoformat()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('lane', choices=LANES)
    parser.add_argument('--only', nargs='+')
    parser.add_argument('--label', default='')
    args = parser.parse_args()
    operations = args.only or LANES[args.lane]
    if any(op not in LANES[args.lane] for op in operations): parser.error('Unknown operation for lane')
    directory = WORK/(args.lane+('-'+args.label if args.label else ''))
    directory.mkdir(parents=True,exist_ok=True)
    exe = ROOT/'../releases/pokemon-tactics-1.0.0-rc.2/windows/PokemonTactics.exe'
    record = {'lane':args.lane,'started':stamp(),'sourceCommit':subprocess.check_output(
        ['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'exeSha256':hashlib.sha256(exe.read_bytes()).hexdigest(),
        'scope':'Offline automatic QA. Legacy suites retain published editions. No human or external-PC claim.',
        'operations':[]}
    env = {**os.environ,'GODOT_QA_DIR':str(directory)}
    for operation in operations:
        print('BETA_START '+operation,flush=True)
        started = time.monotonic()
        entry = {'operation':operation,'started':stamp()}
        log = directory/(operation+'.runner.log')
        command = ['node',str(ROOT/'tools/godot/run.mjs'),operation]
        external_report = None
        command_env = env
        if operation.startswith(('legacy-','edge-')):
            target = directory/operation; target.mkdir(exist_ok=True)
            command_env = {**env,'APPDATA':str(target/'profile'),'LOCALAPPDATA':str(target/'local-profile')}
            binary = env.get('GODOT_BIN',str(ROOT/'../../work/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'))
            legacy = operation.startswith('legacy-')
            script = 'beta-'+operation+'.gd' if legacy else 'beta-ui.gd'
            command = [binary,*(['--headless'] if legacy else ['--position','50,50','--audio-driver','Dummy','--max-fps','120','--quit-after','12000']),
                '--path',str(ROOT/'godot'),'--log-file',str(target/'engine-live.log'),
                '--script',str(ROOT/'tools/godot'/script),'--',
                '--save-dir='+str(target),'--chapter=21','--beta-dir='+str(target)]
            if not legacy: command.append('--beta-mode='+operation.removeprefix('edge-'))
            external_report = target/({'legacy-release':'release-core-result.json','legacy-expedition':'expedition-core-result.json',
                'legacy-journey':'journey-core-result.json','edge-profile':'beta-ui.json','edge-corrupt-load':'beta-corrupt-ui.json',
                'edge-portrait':'beta-portrait-ui.json','edge-cycles':'beta-cycles-ui.json',
                'edge-seeds':'beta-seeds-ui.json','edge-shop':'beta-shop-ui.json'}[operation])
            entry['scope'] = 'Historical metadata control in a separate process' if legacy else 'Additional source UI probe; shipped EXE cannot execute external scripts'
            if operation in ['legacy-release','legacy-journey']:
                stage = 21 if operation=='legacy-release' else 20
                source = ROOT/f'../../work/qa-sprint-{stage}/journey-full.json'
                if source.exists():
                    fixture = directory/f'qa-sprint-{stage}/journey-full.json'
                    fixture.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(source,fixture)
                    entry['historicalFixtureSha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
        try:
            with log.open('w',encoding='utf-8') as stream:
                result = subprocess.run(command,cwd=ROOT,
                    env=command_env,stdout=stream,stderr=subprocess.STDOUT,timeout=3700 if 'playthrough' in operation else 180 if operation.startswith('edge-') else 1000,
                    creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
            entry['exitCode'] = result.returncode
            entry['ok'] = result.returncode==0
        except subprocess.TimeoutExpired:
            entry.update(ok=False,error='Harness timeout')
        entry['seconds'] = round(time.monotonic()-started,3)
        entry['log'] = log.name
        text = log.read_text(encoding='utf-8',errors='replace')
        if external_report is not None:
            entry['report'] = str(external_report.relative_to(directory))
            entry['ok'] = entry['ok'] and external_report.exists() and not re.search(r'SCRIPT ERROR:|^ERROR:',text,re.M)
        entry['summary'] = [line for line in text.splitlines() if re.search(
            r'^(QA |INPUT_CHECK_FAILED|.*_FAILED:|Error:|SCRIPT ERROR:|ERROR:|\{)',line)][-10:]
        record['operations'].append(entry)
        record['finished'] = stamp()
        (directory/'suite.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print('BETA_DONE '+json.dumps(entry,ensure_ascii=False),flush=True)
    raise SystemExit(0 if all(item['ok'] for item in record['operations']) else 1)


if __name__=='__main__': main()
