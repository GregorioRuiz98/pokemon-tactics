"""Build a private RC from source/EXE evidence. No publishing or network."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROJECT = (ROOT/'godot/project.godot').read_text(encoding='utf-8')
VERSION = re.search(r'config/version="([^"]+)"', PROJECT)[1]
STAGE = int(re.search(r'config/qa_stage=(\d+)', PROJECT)[1])
WORK = (ROOT/f'../../work/qa-sprint-{STAGE}').resolve()
RELEASE = (ROOT/f'../releases/pokemon-tactics-{VERSION}').resolve()
BUNDLE = RELEASE/'windows'
EXE = BUNDLE/'PokemonTactics.exe'
EVIDENCE = ROOT/f'docs/qa/sprint-{STAGE}'
BASELINE = 'c960674a10e22c15ab52dd98a94247a38e66ee9b'
PROTECTED = ['godot/core','godot/data','godot/tests','godot/assets','godot/art','src','public','tests','CREDITS.md']
SUITES = {
    'collection': ('collection-ui-result.json',34),
    'briefing': ('briefing-ui-result.json',1958),
    'review': ('review-ui-result.json',46),
    'closing-usability': ('closing-usability.json',25),
    'closing-performance': ('closing-performance.json',231),
    'closing-playthrough': ('closing-playthrough.json',15000),
}
PLAYER_DOCS = ['REGLAS_ACTUALES.md','PLAYTEST_WINDOWS.md','BETA_1_0.md','PLANTILLA_BETA.md','RELEASE_1_0_RC1.md']


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_pair(source, release, minimum):
    for report in [source, release]:
        assert not report['failures'] and report['assertions'] >= minimum
    for key in ['assertions','stateHash','nextStateHash','naturalStateHash','journalHash','campaignEdition','profileSchema','mapCatalogHash','gallery','visited','orders']:
        if key in source:
            assert source[key] == release[key], key
    if 'measurements' in source:
        assert source['measurements']['equivalence'] == release['measurements']['equivalence']


def archive():
    target = RELEASE/f'pokemon-tactics-{VERSION}-windows.zip'
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
        for path in sorted(BUNDLE.rglob('*')):
            if path.is_file():
                info = zipfile.ZipInfo((Path('windows')/path.relative_to(BUNDLE)).as_posix(),(2026,10,28,0,0,0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o100644 << 16
                package.writestr(info,path.read_bytes(),compresslevel=9)
    with zipfile.ZipFile(target) as package:
        assert package.testzip() is None
    return target


def main():
    assert VERSION == '1.0.0-rc.1' and STAGE == 38 and EXE.is_file()
    subprocess.run(['git','diff','--exit-code','--diff-filter=MDR',BASELINE,'--',*PROTECTED],cwd=ROOT,check=True,capture_output=True)
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    counts = {}
    for suite, (filename,minimum) in SUITES.items():
        pair = []
        for side in ['source','release']:
            path = WORK/f'{suite}-{side}'/filename
            if side == 'release': assert path.stat().st_mtime >= EXE.stat().st_mtime, f'Stale EXE evidence: {suite}'
            report = read(path)
            shutil.copy2(path,EVIDENCE/f'{suite}-{side}.json')
            pair.append(report)
        verify_pair(*pair,minimum)
        counts[suite] = pair[0]['assertions']
        if suite == 'closing-playthrough':
            assert pair[0]['orders'] == 7865 and len(pair[0]['visited']) == 58 and pair[0]['campaignEdition'] == 29
        for filename in pair[0].get('screenshots',[])[:3]:
            shutil.copy2(WORK/f'{suite}-source'/filename,EVIDENCE/f'{suite}-{filename}')
    validation, lint = read(WORK/'validation.json'), read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors']==0 and validation['counts']['warnings']==65 and lint['ok']
    core = read(ROOT/'docs/qa/sprint-36/rules.json')
    collection = read(ROOT/'docs/qa/sprint-36/collection-regression.json')
    campaign = read(ROOT/'docs/qa/sprint-36/campaign-29.json')
    assert not core['failures'] and core['checks']>=36 and not campaign['failures']
    assert not collection['failures'] and collection['checks']>=4196
    for name in ['validation','lint']:
        value = read(WORK/(name+'.json'))
        # Full SDK diagnostics include absolute local paths; keep compact public evidence.
        (EVIDENCE/(name+'.json')).write_text(json.dumps({'ok':value['ok'],'counts':value.get('counts',{})},indent=2)+'\n',encoding='utf-8')
    docs = BUNDLE/'Documentacion'; docs.mkdir(exist_ok=True)
    for filename in PLAYER_DOCS: shutil.copy2(ROOT/'docs'/filename,docs/filename)
    shutil.copy2(ROOT/'docs/PLAYTEST_WINDOWS.md',docs/'GUIA_DE_PRUEBA.md')
    shutil.copy2(ROOT/'docs/LEEME_WINDOWS.txt',BUNDLE/'LEEME.txt')
    shutil.copy2(ROOT/'tools/godot/check-pc.cmd',BUNDLE/'Comprobar-equipo.cmd')
    shutil.copytree(ROOT/'godot/licenses',BUNDLE/'licenses',dirs_exist_ok=True)
    shutil.copy2(ROOT/'godot/CREDITS.md',BUNDLE/'CREDITS.md')
    provenance = BUNDLE/'Procedencia'; provenance.mkdir(exist_ok=True)
    candidates = list((ROOT/'godot/data').glob('*provenance.json'))
    candidates += list((ROOT/'godot/assets').rglob('*credits*.txt'))
    candidates += list((ROOT/'godot/assets').rglob('CREDITS.md'))
    candidates += list((ROOT/'godot/assets').rglob('manifest.json'))
    candidates += [ROOT/'godot/art/manifest.json',ROOT/'godot/art/generated-provenance.json',ROOT/'godot/data/portraits.json']
    for path in candidates:
        if path.is_file():
            target = provenance/path.relative_to(ROOT/'godot'); target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(path,target)
    (provenance/'LEEME.txt').write_text('Manifiestos y créditos originales sin modificar. Las rutas res:// y de origen identifican archivos integrados en el EXE o fuentes de desarrollo; no requieren descargas. Los hashes prueban integridad, no autorización sobre la IP.\n',encoding='utf-8')
    check = subprocess.run(['node',str(ROOT/'tools/check-repository.mjs'),'--bundle',str(BUNDLE)],capture_output=True,text=True,encoding='utf-8')
    assert check.returncode==0,check.stdout+check.stderr
    verification = {'version':VERSION,'campaignEdition':29,'sourceAndExeStateMatch':True,'uiChecksPerBuild':counts,'coreChecks':core['checks'],'collectionRegressionChecks':collection['checks'],'campaignChecks':campaign['checks'],'campaignOrders':7865,'campaignLocations':58,'campaignBattles':57,'campaignMedals':8,'campaignMode':'Scripted legal orders through native UI and per-order persistence; no state injection','sourceCampaignOrigin':'Source run started during0.36 closure; same gameplay code, before RC metadata and EOF whitespace cleanup','loadTimingNote':'closing-playthrough coldLoadMs is the LAST reload timing, after next-starter creation; it is not the long cold-campaign replay duration. That replay is verified by state/assertions only.','errors':0,'warnings':65,'newWarnings':0,'publishedFilesUnchanged':PROTECTED,'humanPlaytest':False,'externalHardwareTest':False,'publicDeployment':False,'playerDocumentation':json.loads(check.stdout)}
    (docs/'VERIFICACION.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (EVIDENCE/'verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (BUNDLE/'SHA256SUMS.txt').write_text(digest(EXE)+'  PokemonTactics.exe\n',encoding='utf-8')
    target = archive()
    startup_path = WORK/'clean-startup.json'
    startup = read(startup_path) if startup_path.exists() else None
    if startup:
        assert startup['titleVisible'] and startup['archiveExtracted'] and startup['godotNotOnPath'] and not startup['externalHardwareTest']
        assert startup['exeSha256']==digest(EXE)
        assert startup['zipSha256']==digest(target), 'Clean startup must use this exact archive'
        shutil.copy2(startup_path,EVIDENCE/'clean-startup.json')
    fingerprint = hashlib.sha256()
    for path in sorted((ROOT/'godot').rglob('*')):
        if path.is_file() and '.godot' not in path.parts:
            fingerprint.update(path.relative_to(ROOT).as_posix().encode()); fingerprint.update(path.read_bytes())
    record = {**verification,'sourceFingerprint':fingerprint.hexdigest(),'cleanStartup':startup,'exe':{'bytes':EXE.stat().st_size,'sha256':digest(EXE)},'zip':{'bytes':target.stat().st_size,'sha256':digest(target)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(target)+'  '+target.name+'\n',encoding='utf-8')
    print(json.dumps(record,ensure_ascii=False))


if __name__ == '__main__': main()
