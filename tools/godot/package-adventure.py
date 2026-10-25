"""Package 0.25.0 after native UI, historical regression and replay checks."""
from pathlib import Path
import hashlib, json, shutil, subprocess, zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = '0.25.0'
BASELINE = 'a52d10a56b87037e5fff6e58d69fcab6e5ae4082'
WORK = (ROOT/'../../work/qa-sprint-25').resolve()
RELEASE = ROOT/f'../releases/pokemon-tactics-{VERSION}'
BUNDLE = RELEASE/'windows'
EXE = BUNDLE/'PokemonTactics.exe'
EVIDENCE = ROOT/'docs/qa/sprint-25'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    assert EXE.is_file() and f'config/version="{VERSION}"' in (ROOT/'godot/project.godot').read_text(encoding='utf-8')
    protected = ['godot/core','godot/data','godot/tests','src','public','tests','CREDITS.md']
    # New edition modules/tests are additive; published files remain unchanged.
    subprocess.run(['git','diff','--exit-code','--diff-filter=MDR',BASELINE,'--',*protected],cwd=ROOT,check=True,capture_output=True)
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    counts = {}
    for suite,filename,minimum in [('adventure','adventure-ui-result.json',100),('economy','economy-ui-result.json',57),('spatial','spatial-ui-result.json',55),('moves','moves-ui-result.json',304),('performance','performance-result.json',18),('fluency','performance-result.json',220)]:
        pair = []
        for side in ['source','release']:
            path = WORK/f'{suite}-{side}'/filename
            if side=='release': assert path.stat().st_mtime>=EXE.stat().st_mtime, 'QA predates executable'
            report = read(path)
            assert not report['failures'] and report['assertions']>=minimum, suite
            shutil.copy2(path,EVIDENCE/f'{suite}-{side}.json')
            pair.append(report)
        if suite=='adventure':
            for key in ['naturalStateHash','journalHash','gyms','edition','combatEdition','assertions']: assert pair[0][key]==pair[1][key], key
            assert pair[0]['gyms']==8 and pair[0]['edition']==21 and pair[0]['combatEdition']==19
        elif suite=='fluency': assert pair[0]['measurements']['equivalence']==pair[1]['measurements']['equivalence']
        elif suite in ['economy','spatial','moves']: assert pair[0]==pair[1],suite
        counts[suite] = pair[0]['assertions']
    core = {}
    for suite,minimum in [('adventure',101),('economy',964),('spatial',557)]:
        report = read(WORK/f'{suite}-result.json')
        assert not report['failures'] and report['checks']>=minimum
        core[suite] = report['checks']
        shutil.copy2(WORK/f'{suite}-result.json',EVIDENCE/f'core-{suite}.json')
    validation = read(WORK/'validation.json'); lint = read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors']==0 and validation['counts']['warnings']==65 and lint['ok']
    balance = read(WORK/'adventure-balance.json')
    assert not balance['failures'] and len(balance['results'])==6 and all(r['replay'] for r in balance['results'])
    shutil.copy2(WORK/'adventure-balance.json',EVIDENCE/'balance.json')
    for name in ['preparation-threats.png','abilities-1024-150.png','deployment-contrast.png','terrain-reaction.png','journey-card.png','brock.png','misty.png','koga.png','sabrina.png','all-threats.png']:
        shutil.copy2(WORK/'adventure-source'/name,EVIDENCE/name)
    for source,target in [('docs/SPRINT_25_TACTICAL.md','CAMBIOS_0.25.md'),('docs/SPRINT_24_ECONOMY.md','CAMBIOS_0.24.md'),('docs/SPRINT_23_SPATIAL.md','MOVIMIENTOS_0.23.md'),('docs/PERFORMANCE_0.24.1.md','FLUIDEZ_0.24.1.md'),('docs/reports/moves-2026-10-24/aplicacion-0.23.csv','MOVIMIENTOS.csv'),('godot/assets/original-moves/manifest.json','PROCEDENCIA_SONIDOS.json')]:
        shutil.copy2(ROOT/source,BUNDLE/target)
    verification = {'version':VERSION,'baseline':BASELINE,'publishedModulesUnchanged':protected,'campaignEdition':21,'combatEdition':19,'validatorOk':True,'errors':0,'warnings':65,'newWarnings':0,'coreChecks':core,'uiChecksPerBuild':counts,'historicalAiCases':93,'sourceAndExeNaturalReplayMatch':True,'openingSamples':6,'openingBrockWins':sum(r['medals']>0 for r in balance['results']),'balanceClosed':False,'fullCampaignRerun':False,'publicDeployment':False}
    for path in [EVIDENCE/'verification.json',BUNDLE/'QA_0.25.json']: path.write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    shutil.copy2(EVIDENCE/'balance.json',BUNDLE/'SIMULACIONES_0.25.json')
    doc = BUNDLE/'CAMBIOS_0.25.md'
    doc.write_text(doc.read_text(encoding='utf-8').replace('(qa/sprint-25/verification.json)','(QA_0.25.json)').replace('(qa/sprint-25/release.json)','(QA_0.25.json)').replace('(qa/sprint-25/balance.json)','(SIMULACIONES_0.25.json)'),encoding='utf-8')
    archive = RELEASE/f'pokemon-tactics-{VERSION}-windows.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
        for file in sorted(BUNDLE.rglob('*')):
            if file.is_file(): package.write(file,Path('windows')/file.relative_to(BUNDLE))
    with zipfile.ZipFile(archive) as package: assert package.testzip() is None
    fingerprint = hashlib.sha256()
    for file in sorted((ROOT/'godot').rglob('*')):
        if file.is_file() and '.godot' not in file.parts:
            fingerprint.update(file.relative_to(ROOT).as_posix().encode()); fingerprint.update(file.read_bytes())
    record = {**verification,'sourceFingerprint':fingerprint.hexdigest(),'exe':{'bytes':EXE.stat().st_size,'sha256':digest(EXE)},'zip':{'bytes':archive.stat().st_size,'sha256':digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps(record,ensure_ascii=False))

if __name__=='__main__': main()
