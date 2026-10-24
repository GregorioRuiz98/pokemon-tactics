"""Release20: current UI parity, honest simulation results and legacy preservation."""
from pathlib import Path
import hashlib,json,shutil,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2]
WORK=(ROOT/'../../work/qa-sprint-24').resolve()
RELEASE=ROOT/'../releases/pokemon-tactics-0.24.0'
BUNDLE=RELEASE/'windows'
EXE=BUNDLE/'PokemonTactics.exe'
EVIDENCE=ROOT/'docs/qa/sprint-24'
BASELINE='4e7b9d7fd6395f31bc37dc80edac1e7925fb9fce'
def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    assert EXE.is_file()
    protected=['godot/core','godot/data','godot/tests','src','public','tests','CREDITS.md']
    changed=subprocess.check_output(['git','diff','--name-only','--diff-filter=MDR',BASELINE,'--',*protected],cwd=ROOT,text=True).strip()
    assert not changed,'Published files changed: '+changed
    assert subprocess.run(['python','-X','utf8',str(ROOT/'tools/godot/verify-economy.py')],cwd=ROOT,capture_output=True).returncode==0
    validation=read(WORK/'validation.json');lint=read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors']==0 and validation['counts']['warnings']==65 and lint['counts']['errors']==0
    core=read(WORK/'economy-result.json');legacy=read(WORK/'spatial-result.json')
    assert not core['failures'] and core['checks']>=964 and not legacy['failures'] and legacy['checks']>=557
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    suites={}
    for suite,name,minimum in [('economy','economy-ui-result.json',57),('spatial','spatial-ui-result.json',55),('moves','moves-ui-result.json',304)]:
        source=WORK/f'{suite}-source'/name; tested=WORK/f'{suite}-release'/name
        assert tested.stat().st_mtime>=EXE.stat().st_mtime,'QA predates executable'
        report=read(source)
        assert report==read(tested) and not report['failures'] and report['assertions']>=minimum,suite
        suites[suite]=report['assertions']
        if suite=='spatial':assert report['naturalCampaignReplay'] and report['originalSounds']==40
        for side in ['source','release']:shutil.copy2(WORK/f'{suite}-{side}'/name,EVIDENCE/f'{suite}-{side}.json')
    assert read(WORK/'economy-source/economy-ui-result.json')['journeyHash']==digest(ROOT/'godot/data/journey-24.json')
    assert read(WORK/'economy-source/economy-ui-result.json')['curveHash']==digest(ROOT/'godot/data/economy.json')
    for suite in ['economy','spatial']:
        states=[read(WORK/f'{suite}-{side}'/'natural-campaign.json') for side in ['source','release']]
        assert states[0]['payload']==states[1]['payload'] and states[0]['checksum']==states[1]['checksum'],suite+' complete natural journal parity'
    opening=read(WORK/'balance-economy.json');long=read(WORK/'balance-economy-full.json');gyms=read(WORK/'gym-probes.json')
    assert len(opening['results'])==6 and len(long['results'])==3 and len(gyms['results'])==8
    assert not opening['failures'] and not long['failures'] and not gyms['failures']
    assert all(row['replay'] for row in opening['results']+long['results'])
    for filename in ['economy-result.json','spatial-result.json','balance-economy.json','balance-economy-full.json','gym-probes.json']:
        shutil.copy2(WORK/filename,EVIDENCE/filename)
    for shot in ['training-shop.png','local-reroll.png']:shutil.copy2(WORK/'economy-source'/shot,EVIDENCE/shot)
    shutil.copy2(ROOT/'docs/SPRINT_24_ECONOMY.md',BUNDLE/'CAMBIOS_0.24.md')
    shutil.copy2(ROOT/'docs/SPRINT_23_SPATIAL.md',BUNDLE/'MOVIMIENTOS_0.23.md')
    shutil.copy2(ROOT/'docs/reports/moves-2026-10-24/aplicacion-0.23.csv',BUNDLE/'MOVIMIENTOS.csv')
    shutil.copy2(ROOT/'docs/SPRINT_22_GENERATED_ART.md',BUNDLE/'ARTE_INTEGRADO.md')
    for source,name in [('balance-economy.json','SIMULACIONES_INICIO.json'),('balance-economy-full.json','SIMULACIONES_CAMPAÑA.json'),('gym-probes.json','GIMNASIOS_SINTETICOS.json')]:shutil.copy2(WORK/source,BUNDLE/name)
    verification={'version':'0.24.0','campaignEdition':20,'combatEdition':18,'baseline':BASELINE,'publishedFilesUnchanged':True,'validatorErrors':0,'existingWarnings':65,'newWarnings':0,'coreChecks':core['checks'],'legacySpatialChecks':legacy['checks'],'uiChecksPerBuild':suites,'sourceExecutableDataAndNaturalJournalsEqual':True,'openingSamples':6,'openingBrockWins':sum('brock' in r.get('cleared',[]) or r['medals']>0 for r in opening['results']),'longSamples':3,'longWins':sum(r['phase']=='ending' for r in long['results']),'bestNaturalMedals':max(r['medals'] for r in long['results']),'syntheticGymProbes':8,'syntheticGymWins':sum(r['outcome']=='victory' for r in gyms['results']),'balanceClosed':False,'publicDeployment':False}
    (EVIDENCE/'verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (BUNDLE/'QA_0.24.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    archive=RELEASE/'pokemon-tactics-0.24.0-windows.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
        for file in sorted(BUNDLE.rglob('*')):
            if file.is_file():package.write(file,Path('windows')/file.relative_to(BUNDLE))
    with zipfile.ZipFile(archive) as package: assert package.testzip() is None
    fingerprint=hashlib.sha256()
    for file in sorted((ROOT/'godot').rglob('*')):
        if file.is_file() and '.godot' not in file.parts:
            fingerprint.update(file.relative_to(ROOT).as_posix().encode());fingerprint.update(file.read_bytes())
    record={**verification,'sourceFingerprint':fingerprint.hexdigest(),'exe':{'bytes':EXE.stat().st_size,'sha256':digest(EXE)},'zip':{'bytes':archive.stat().st_size,'sha256':digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps(record,ensure_ascii=False))
if __name__=='__main__':main()
