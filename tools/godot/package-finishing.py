"""Package the finishing sprints from checked native source/executable evidence."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = re.search(r'config/version="([^"]+)"', (ROOT/'godot/project.godot').read_text(encoding='utf-8'))[1]
CHAPTER = int(VERSION.split('.')[1])
CONFIG = {
    28: {'baseline': '9d87cd1091815f72525ec66a4d4752065579c2f4', 'report': 'SPRINT_28_KECLEON.md', 'ui': {'shop': 70, 'trainer': 69, 'player': 719}, 'core': {'trainer': 120, 'adventure': 105}, 'edition': 21},
    27: {'baseline': 'be221c89082013c288adf3e28bb8acfb872e1474', 'report': 'SPRINT_27_TRAINER.md', 'ui': {'trainer': 69, 'player': 719}, 'core': {'trainer': 120, 'adventure': 105}, 'edition': 21},
}[CHAPTER]
WORK = (ROOT/f'../../work/qa-sprint-{CHAPTER}').resolve()
RELEASE = (ROOT/f'../releases/pokemon-tactics-{VERSION}').resolve()
BUNDLE = RELEASE/'windows'
EXE = BUNDLE/'PokemonTactics.exe'
EVIDENCE = ROOT/f'docs/qa/sprint-{CHAPTER}'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert EXE.is_file()
    protected = ['godot/core', 'godot/data', 'godot/tests', 'godot/assets', 'godot/art', 'src', 'public', 'tests', 'CREDITS.md']
    # New modules are allowed; published rules/assets/tests cannot be overwritten.
    subprocess.run(['git', 'diff', '--exit-code', '--diff-filter=MDR', CONFIG['baseline'], '--', *protected], cwd=ROOT, check=True, capture_output=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    counts = {}
    for suite, minimum in CONFIG['ui'].items():
        pair = []
        for side in ['source', 'release']:
            path = WORK/f'{suite}-{side}'/f'{suite}-ui-result.json'
            if side == 'release':
                assert path.stat().st_mtime >= EXE.stat().st_mtime, 'QA predates executable'
            report = read(path)
            assert not report['failures'] and report['assertions'] >= minimum, suite
            shutil.copy2(path, EVIDENCE/f'{suite}-{side}.json')
            pair.append(report)
        for key in ['assertions', 'stateHash', 'naturalStateHash', 'journalHash', 'campaignEdition', 'profileSchema']:
            if key in pair[0]:
                assert pair[0][key] == pair[1][key], (suite, key)
        counts[suite] = pair[0]['assertions']
        for name in pair[0].get('screenshots', [])[:8]:
            shutil.copy2(WORK/f'{suite}-source'/name, EVIDENCE/f'{suite}-{name}')
    core = {}
    for suite, minimum in CONFIG['core'].items():
        path = WORK/f'{suite}-result.json'
        result = read(path)
        assert not result['failures'] and result['checks'] >= minimum
        shutil.copy2(path, EVIDENCE/f'core-{suite}.json')
        core[suite] = result['checks']
    validation = read(WORK/'validation.json')
    lint = read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors'] == 0 and validation['counts']['warnings'] == 65 and lint['ok']
    docs = BUNDLE/'Documentacion'
    docs.mkdir(exist_ok=True)
    for name in ['GUIA_DE_PRUEBA.md', 'INFORME_BALANCE.md', 'BALANCE_RESULTADOS.json']:
        path = BUNDLE/name
        if path.is_file():
            path.replace(docs/name)
    shutil.copy2(ROOT/'docs'/CONFIG['report'], docs/f'CAMBIOS_0.{CHAPTER}.md')
    verification = {'version': VERSION, 'baseline': CONFIG['baseline'], 'publishedFilesUnchanged': protected, 'campaignEdition': CONFIG['edition'], 'errors': 0, 'warnings': 65, 'newWarnings': 0, 'coreChecks': core, 'uiChecksPerBuild': counts, 'sourceAndExeStateMatch': True, 'publicDeployment': False, 'fullCampaignPlayed': False}
    for path in [EVIDENCE/'verification.json', docs/f'QA_0.{CHAPTER}.json']:
        path.write_text(json.dumps(verification, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    readme = (ROOT/'../releases/pokemon-tactics-0.26.0/windows/LEEME.txt').read_text(encoding='utf-8')
    readme += '\nPerfil de entrenador: nombre, retrato, Pokédex, historial y logros se conservan entre aventuras. Los títulos y marcos son cosméticos.\n'
    (BUNDLE/'LEEME.txt').write_text(readme, encoding='utf-8')
    archive = RELEASE/f'pokemon-tactics-{VERSION}-windows.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for path in sorted(BUNDLE.rglob('*')):
            if path.is_file():
                package.write(path, Path('windows')/path.relative_to(BUNDLE))
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
    fingerprint = hashlib.sha256()
    for path in sorted((ROOT/'godot').rglob('*')):
        if path.is_file() and '.godot' not in path.parts:
            fingerprint.update(path.relative_to(ROOT).as_posix().encode()); fingerprint.update(path.read_bytes())
    record = {**verification, 'sourceFingerprint': fingerprint.hexdigest(), 'exe': {'bytes': EXE.stat().st_size, 'sha256': digest(EXE)}, 'zip': {'bytes': archive.stat().st_size, 'sha256': digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n', encoding='utf-8')
    print(json.dumps(record, ensure_ascii=False))


if __name__ == '__main__':
    main()
