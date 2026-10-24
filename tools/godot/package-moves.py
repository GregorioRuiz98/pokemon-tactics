"""Package the presentation-only 0.23.1 fix with its actual checks."""
from pathlib import Path
import hashlib, json, shutil, subprocess, zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = '0.23.1'
BASELINE = '6285412ace7d19fd6038011a2b693aa43cb42fc4'
WORK = (ROOT / '../../work/qa-sprint-23-ui-1').resolve()
RELEASE = ROOT / f'../releases/pokemon-tactics-{VERSION}'
BUNDLE = RELEASE / 'windows'
EXE = BUNDLE / 'PokemonTactics.exe'
EVIDENCE = ROOT / 'docs/qa/moves-0.23.1'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    assert EXE.is_file() and f'config/version="{VERSION}"' in (ROOT/'godot/project.godot').read_text(encoding='utf-8')
    protected = ['godot/core', 'godot/data', 'godot/tests', 'src', 'public', 'tests', 'CREDITS.md']
    subprocess.run(['git', 'diff', '--exit-code', BASELINE, '--', *protected], cwd=ROOT, check=True, capture_output=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    results = {}
    for suite, filename in [('moves', 'moves-ui-result.json'), ('spatial', 'spatial-ui-result.json')]:
        source = WORK/f'{suite}-source'/filename
        tested = WORK/f'{suite}-release'/filename
        assert tested.stat().st_mtime >= EXE.stat().st_mtime, 'QA predates executable'
        report = read(source)
        assert report == read(tested) and not report['failures'], suite
        results[suite] = report['assertions']
        for side in ['source', 'release']:
            shutil.copy2(WORK/f'{suite}-{side}'/filename, EVIDENCE/f'{suite}-{side}.json')
    assert results['moves'] >= 304 and results['spatial'] >= 63
    core = read(WORK/'spatial-result.json')
    validation = read(WORK/'validation.json')
    assert not core['failures'] and core['checks'] >= 557
    assert validation['ok'] and validation['counts']['errors'] == 0 and validation['counts']['warnings'] == 65
    shutil.copy2(WORK/'spatial-result.json', EVIDENCE/'core.json')
    shutil.copy2(ROOT/'docs/FIX_MOVES_0.23.1.md', BUNDLE/'CAMBIOS_0.23.1.md')
    for source, target in [('docs/SPRINT_23_SPATIAL.md','MOVIMIENTOS_0.23.md'), ('docs/reports/moves-2026-10-24/aplicacion-0.23.csv','MOVIMIENTOS.csv'), ('godot/assets/original-moves/manifest.json','PROCEDENCIA_SONIDOS.json'), ('docs/SPRINT_22_GENERATED_ART.md','ARTE_INTEGRADO.md')]:
        shutil.copy2(ROOT/source, BUNDLE/target)
    report = BUNDLE/'MOVIMIENTOS_0.23.md'
    report.write_text(report.read_text(encoding='utf-8').replace('(reports/moves-2026-10-24/aplicacion-0.23.csv)', '(MOVIMIENTOS.csv)').replace('(../godot/assets/original-moves/manifest.json)', '(PROCEDENCIA_SONIDOS.json)').replace('(../godot/CREDITS.md)', '(CREDITS.md)').replace('(qa/sprint-23/release.json)', '(QA_0.23.1.json)'),encoding='utf-8')
    for name in ['equipped-1280-100.png', 'equipped-1024-150.png']:
        shutil.copy2(WORK/'moves-source'/name, EVIDENCE/name)
    verification = {'baseline': BASELINE, 'protectedPathsUnchanged': protected, 'validatorOk': True, 'errors': 0, 'warnings': 65, 'newWarnings': 0, 'coreChecks': core['checks'], 'uiChecksPerBuild': results, 'fullCampaignRerun': False, 'previousFinaleEvidence': 'docs/qa/sprint-23', 'publicDeployment': False}
    (EVIDENCE/'verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (BUNDLE/'QA_0.23.1.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    archive = RELEASE/f'pokemon-tactics-{VERSION}-windows.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
        for file in sorted(BUNDLE.rglob('*')):
            if file.is_file(): package.write(file, Path('windows')/file.relative_to(BUNDLE))
    with zipfile.ZipFile(archive) as package: assert package.testzip() is None
    record = {'version': VERSION, **verification, 'exe': {'bytes': EXE.stat().st_size, 'sha256': digest(EXE)}, 'zip': {'bytes': archive.stat().st_size, 'sha256': digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps(record, ensure_ascii=False))

if __name__ == '__main__':
    main()
