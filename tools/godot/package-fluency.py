"""Package the measured presentation-only 0.24.1 optimization."""
from pathlib import Path
import hashlib, json, shutil, subprocess, zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = '0.24.1'
BASELINE = 'fd1607e814abc1aab96682e6075789ea23711537'
WORK = (ROOT / '../../work/qa-sprint-24-ui-1').resolve()
RELEASE = ROOT / f'../releases/pokemon-tactics-{VERSION}'
BUNDLE = RELEASE / 'windows'
EXE = BUNDLE / 'PokemonTactics.exe'
EVIDENCE = ROOT / 'docs/qa/performance-0.24.1'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    assert EXE.is_file() and f'config/version="{VERSION}"' in (ROOT/'godot/project.godot').read_text(encoding='utf-8')
    protected = ['godot/core', 'godot/data', 'godot/tests', 'src', 'public', 'tests', 'CREDITS.md']
    subprocess.run(['git','diff','--exit-code',BASELINE,'--',*protected],cwd=ROOT,check=True,capture_output=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    counts = {}
    for suite, filename, minimum in [('economy','economy-ui-result.json',57),('spatial','spatial-ui-result.json',55),('moves','moves-ui-result.json',304),('performance','performance-result.json',18),('fluency','performance-result.json',220)]:
        pair = []
        for side in ['source','release']:
            path = WORK/f'{suite}-{side}'/filename
            if side=='release': assert path.stat().st_mtime >= EXE.stat().st_mtime, 'QA predates executable'
            report = read(path)
            assert not report['failures'] and report['assertions']>=minimum, suite
            shutil.copy2(path,EVIDENCE/f'{suite}-{side}.json')
            pair.append(report)
        if suite in ['economy','spatial','moves']: assert pair[0]==pair[1], suite
        if suite=='fluency':
            assert pair[0]['measurements']['equivalence']==pair[1]['measurements']['equivalence']
            assert pair[0]['measurements']['planner']['cases']==93
        counts[suite] = pair[0]['assertions']
    validation = read(WORK/'validation.json')
    assert validation['ok'] and validation['counts']['errors']==0 and validation['counts']['warnings']==65
    core = {}
    for suite, minimum in [('economy',964),('spatial',557)]:
        report = read(WORK/f'{suite}-result.json')
        assert not report['failures'] and report['checks']>=minimum
        core[suite] = report['checks']
        shutil.copy2(WORK/f'{suite}-result.json',EVIDENCE/f'core-{suite}.json')
    shutil.copy2(ROOT/'../../work/fluency-before/performance-result.json',EVIDENCE/'before.json')
    shutil.copy2(ROOT/'../../work/fluency-full/performance-result.json',EVIDENCE/'initial-after.json')
    shutil.copy2(WORK/'fluency-source/current-12-units.png',EVIDENCE/'current-12-units.png')
    for source,target in [('docs/PERFORMANCE_0.24.1.md','FLUIDEZ_0.24.1.md'),('docs/SPRINT_24_ECONOMY.md','CAMBIOS_0.24.md'),('docs/SPRINT_23_SPATIAL.md','MOVIMIENTOS_0.23.md'),('docs/reports/moves-2026-10-24/aplicacion-0.23.csv','MOVIMIENTOS.csv'),('godot/assets/original-moves/manifest.json','PROCEDENCIA_SONIDOS.json')]:
        shutil.copy2(ROOT/source,BUNDLE/target)
    verification = {'version':VERSION,'baseline':BASELINE,'protectedPathsUnchanged':protected,'validatorOk':True,'errors':0,'warnings':65,'newWarnings':0,'coreChecks':core,'uiChecksPerBuild':counts,'identicalAiCases':93,'sourceAndExeDecisionsAndReplayMatch':True,'fullCampaignRerun':False,'previousCampaignEvidence':'docs/qa/sprint-24','publicDeployment':False}
    (EVIDENCE/'verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (BUNDLE/'QA_0.24.1.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    # Keep documentation links usable inside the portable folder.
    doc = BUNDLE/'FLUIDEZ_0.24.1.md'
    doc.write_text(doc.read_text(encoding='utf-8').replace('(SPRINT_24_ECONOMY.md)','(CAMBIOS_0.24.md)').replace('(qa/performance-0.24.1/verification.json)','(QA_0.24.1.json)').replace('(qa/performance-0.24.1/before.json)','(MEDICIONES_ANTES.json)').replace('(qa/performance-0.24.1/fluency-source.json)','(MEDICIONES_DESARROLLO.json)').replace('(qa/performance-0.24.1/fluency-release.json)','(MEDICIONES_EXE.json)'),encoding='utf-8')
    for source,target in [('before.json','MEDICIONES_ANTES.json'),('fluency-source.json','MEDICIONES_DESARROLLO.json'),('fluency-release.json','MEDICIONES_EXE.json')]: shutil.copy2(EVIDENCE/source,BUNDLE/target)
    archive = RELEASE/f'pokemon-tactics-{VERSION}-windows.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
        for file in sorted(BUNDLE.rglob('*')):
            if file.is_file(): package.write(file,Path('windows')/file.relative_to(BUNDLE))
    with zipfile.ZipFile(archive) as package: assert package.testzip() is None
    record = {**verification,'exe':{'bytes':EXE.stat().st_size,'sha256':digest(EXE)},'zip':{'bytes':archive.stat().st_size,'sha256':digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps(record,ensure_ascii=False))

if __name__=='__main__':
    main()
