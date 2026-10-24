"""Package edition19 only after source/EXE parity and dedicated spatial checks."""
from pathlib import Path
import hashlib,json,shutil,zipfile,subprocess

ROOT=Path(__file__).resolve().parents[2]
WORK=(ROOT/'../../work/qa-sprint-23').resolve()
RELEASE=ROOT/'../releases/pokemon-tactics-0.23.0'
BUNDLE=RELEASE/'windows'
EXE=BUNDLE/'PokemonTactics.exe'
EVIDENCE=ROOT/'docs/qa/sprint-23'

def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    assert EXE.is_file()
    results={}
    for folder,name in [('spatial','spatial-ui-result.json'),('journey','journey-ui-result.json'),('journey-psychic','journey-ui-result.json')]:
        source=read(WORK/(folder+'-source')/name)
        tested=WORK/(folder+'-release')/name
        assert tested.stat().st_mtime>=EXE.stat().st_mtime,'Executable QA predates export'
        assert source==read(tested) and not source['failures'],folder
        results[folder]=source
        save='natural-campaign.json' if folder=='spatial' else 'campaign-save.json'
        states=[]
        for side in ['source','release']:
            envelope=read(WORK/(folder+'-'+side)/save)
            assert hashlib.sha256(envelope['payload'].encode()).hexdigest()==envelope['checksum']
            states.append(json.loads(envelope['payload']))
        assert states[0]['state']==states[1]['state'] and states[0]['commands']==states[1]['commands'],folder+' full state/journal'
        assert states[0]['version']==19 and states[0]['state']['battle']['combatEdition']==18
    assert results['journey']['phase']==results['journey-psychic']['phase']=='ending'
    assert results['journey']['finalPath']=='birds' and results['journey-psychic']['finalPath']=='psychic'
    core=read(WORK/'spatial-result.json');assert not core['failures'] and core['checks']>=553
    verification=read(WORK/'verification.json');assert verification['errors']==0 and verification['newWarnings']==0 and verification['publishedFilesUnchanged']
    assert subprocess.run(['python',str(ROOT/'tools/godot/verify-original-moves.py')],cwd=ROOT,capture_output=True).returncode==0
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    report=(ROOT/'docs/SPRINT_23_SPATIAL.md').read_text(encoding='utf-8').replace('(reports/moves-2026-10-24/aplicacion-0.23.csv)','(MOVIMIENTOS.csv)').replace('(../godot/assets/original-moves/manifest.json)','(PROCEDENCIA_SONIDOS.json)').replace('(../godot/CREDITS.md)','(CREDITS.md)').replace('(qa/sprint-23/release.json)','(QA_0.23.json)')
    (BUNDLE/'MOVIMIENTOS_0.23.md').write_text(report,encoding='utf-8')
    shutil.copy2(ROOT/'docs/reports/moves-2026-10-24/aplicacion-0.23.csv',BUNDLE/'MOVIMIENTOS.csv')
    shutil.copy2(ROOT/'godot/assets/original-moves/manifest.json',BUNDLE/'PROCEDENCIA_SONIDOS.json')
    shutil.copy2(ROOT/'godot/CREDITS.md',BUNDLE/'CREDITS.md')
    shutil.copytree(ROOT/'godot/licenses',BUNDLE/'licenses',dirs_exist_ok=True)
    shutil.copy2(ROOT/'docs/SPRINT_22_GENERATED_ART.md',BUNDLE/'ARTE_INTEGRADO.md')
    quick={'version':'0.23.0','campaignEdition':19,'combatEdition':18,'coreChecks':core['checks'],'uiChecks':results['spatial']['assertions'],'birdsChecks':results['journey']['assertions'],'psychicChecks':results['journey-psychic']['assertions'],'sourceAndExecutableStatesAndJournalsEqual':True,'verification':verification,'exeSha256':digest(EXE),'publicDeployment':False}
    (BUNDLE/'QA_0.23.json').write_text(json.dumps(quick,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    readme=BUNDLE/'LEEME.txt'
    addition='\n0.23.0: reglas espaciales de edición19. Consulta MOVIMIENTOS_0.23.md y MOVIMIENTOS.csv. Habilidades también sobre suelo vacío; Q/E gira pantallas y lanzamientos. Zonas, desplazamientos, fuego amigo y controles temporales; no rectificar efectos ni tiradas.40 muestras originales, incluida Hiperrayo. El informe de balance0.22 es histórico y no valida estas reglas.\n'
    text=readme.read_text(encoding='utf-8')
    if addition not in text:readme.write_text(text+addition,encoding='utf-8')
    for folder,name in [('spatial','spatial-ui-result.json'),('journey','journey-ui-result.json'),('journey-psychic','journey-ui-result.json')]:
        for side in ['source','release']:
            shutil.copy2(WORK/(folder+'-'+side)/name,EVIDENCE/(folder+'-'+side+'.json'))
    for shot in results['spatial']['screenshots']:shutil.copy2(WORK/'spatial-source'/shot,EVIDENCE/('source-'+shot))
    shutil.copy2(WORK/'spatial-result.json',EVIDENCE/'core.json')
    shutil.copy2(WORK/'verification.json',EVIDENCE/'verification.json')
    archive=RELEASE/'pokemon-tactics-0.23.0-windows.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
        for file in sorted(BUNDLE.rglob('*')):
            if file.is_file():package.write(file,Path('windows')/file.relative_to(BUNDLE))
    with zipfile.ZipFile(archive) as package:assert package.testzip() is None
    fingerprint=hashlib.sha256()
    for file in sorted((ROOT/'godot').rglob('*')):
        if file.is_file() and '.godot' not in file.parts and file.suffix in ['.gd','.tscn','.json','.png','.wav','.ttf','.otf','.cfg','.godot','.import','.uid']:
            fingerprint.update(file.relative_to(ROOT).as_posix().encode());fingerprint.update(file.read_bytes())
    record={'version':'0.23.0','campaignEdition':19,'combatEdition':18,'sourceFingerprint':fingerprint.hexdigest(),'coreChecks':core['checks'],'spatialUiChecks':results['spatial']['assertions'],'birdsChecks':results['journey']['assertions'],'psychicChecks':results['journey-psychic']['assertions'],'sourceAndExecutableStatesAndJournalsEqual':True,'finaleOrigin':'previously earned champion checkpoints, explicitly upgraded','originalSounds':40,'audioListening':'pending; PCM/hash validation and playback under Dummy','publicDeployment':False,'exe':{'path':str(EXE.resolve()),'bytes':EXE.stat().st_size,'sha256':digest(EXE)},'zip':{'path':str(archive.resolve()),'bytes':archive.stat().st_size,'sha256':digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps(record,ensure_ascii=False))

if __name__=='__main__':main()
