"""Package RC4: modal regression and complete source/EXE campaign proof."""
from pathlib import Path
import json
import runpy
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
helpers = runpy.run_path(str(ROOT/'tools/godot/package-candidate.py'))
WORK, BUNDLE, RELEASE, EXE = [helpers[key] for key in ['WORK','BUNDLE','RELEASE','EXE']]
EVIDENCE = ROOT/'docs/qa/sprint-41'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    assert helpers['VERSION']=='1.0.0-rc.4' and EXE.is_file()
    subprocess.run(['git','diff','--exit-code','--diff-filter=MDR','760dc3f3c9f7681b8d111e7e9f6113d82432913b','--',*helpers['PROTECTED']],cwd=ROOT,check=True,capture_output=True)
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    results = {}
    for suite, filename, minimum in [('dex','dex-dialog.json',72),('journey','candidate-journey.json',20000)]:
        pair = []
        for side in ['source','release']:
            path = WORK/f'{suite}-{side}'/filename
            if side=='release': assert path.stat().st_mtime>=EXE.stat().st_mtime, 'Stale EXE evidence'
            value = read(path); pair.append(value)
            (EVIDENCE/f'{suite}-{side}.json').write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        helpers['verify_pair'](*pair,minimum)
        results[suite] = pair[0]
    campaign = results['journey']
    assert campaign['campaignEdition']==30 and campaign['orders']==10277 and len(campaign['visited'])==58
    assert campaign['mapCatalogHash']==read(ROOT/'docs/qa/sprint-40/release.json')['mapCatalogHash']
    validation, lint = read(WORK/'validation.json'), read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors']==0 and validation['counts']['warnings']==65 and lint['ok']
    for name,value in [('validation',validation),('lint',lint)]:
        (EVIDENCE/(name+'.json')).write_text(json.dumps({'ok':value['ok'],'counts':value.get('counts',{})},indent=2)+'\n',encoding='utf-8')
    for name in results['dex']['screenshots']: shutil.copy2(WORK/'dex-source'/name,EVIDENCE/name)
    shutil.copy2(WORK/'journey-release/complete-current-kanto.png',EVIDENCE/'complete-current-kanto.png')
    docs = BUNDLE/'Documentacion'; docs.mkdir(exist_ok=True)
    for name in ['REGLAS_ACTUALES.md','PLAYTEST_WINDOWS.md','BETA_1_0.md','PLANTILLA_BETA.md','RELEASE_1_0_RC4.md','MAPAS_RELIEVE.md']:
        shutil.copy2(ROOT/'docs'/name,docs/name)
    shutil.copy2(ROOT/'docs/PLAYTEST_WINDOWS.md',docs/'GUIA_DE_PRUEBA.md')
    shutil.copy2(ROOT/'docs/LEEME_WINDOWS.txt',BUNDLE/'LEEME.txt')
    shutil.copy2(ROOT/'tools/godot/check-pc.cmd',BUNDLE/'Comprobar-equipo.cmd')
    shutil.copytree(ROOT/'godot/licenses',BUNDLE/'licenses',dirs_exist_ok=True)
    shutil.copy2(ROOT/'godot/CREDITS.md',BUNDLE/'CREDITS.md')
    provenance = BUNDLE/'Procedencia'
    candidates = list((ROOT/'godot/data').glob('*provenance.json')) + list((ROOT/'godot/assets').rglob('*credits*.txt')) + list((ROOT/'godot/assets').rglob('CREDITS.md')) + list((ROOT/'godot/assets').rglob('manifest.json'))
    candidates += [ROOT/'godot/art/manifest.json',ROOT/'godot/art/generated-provenance.json',ROOT/'godot/data/portraits.json']
    for path in candidates:
        if path.is_file():
            destination = provenance/path.relative_to(ROOT/'godot'); destination.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(path,destination)
    verification = {'version':'1.0.0-rc.4','campaignEdition':30,'combatEdition':25,'uiChecksPerBuild':{key:value['assertions'] for key,value in results.items()},'campaignLocations':58,'campaignBattles':57,'campaignMedals':8,'campaignOrders':10277,'fullCampaignInExe':True,'sourceAndExeStateMatch':True,'stateHash':campaign['stateHash'],'nextStateHash':campaign['nextStateHash'],'mapCatalogHash':campaign['mapCatalogHash'],'errors':0,'warnings':65,'newWarnings':0,'humanPlaytest':False,'externalHardwareTest':False,'publicDeployment':False,'scope':'UI correction only; full edition30 legal journal executed through source and final EXE with per-order saves, full cold replay, profile and next-run starter. Prior RC3 map/core fixtures are historical, not repeated.'}
    (docs/'VERIFICACION.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (BUNDLE/'SHA256SUMS.txt').write_text(helpers['digest'](EXE)+'  PokemonTactics.exe\n',encoding='utf-8')
    subprocess.run(['node','tools/check-repository.mjs','--bundle',str(BUNDLE)],cwd=ROOT,check=True)
    archive = helpers['archive']()
    record = {**verification,'exe':{'bytes':EXE.stat().st_size,'sha256':helpers['digest'](EXE)},'zip':{'bytes':archive.stat().st_size,'sha256':helpers['digest'](archive)}}
    startup = WORK/'clean-startup.json'
    if startup.exists():
        value = read(startup)
        assert value['exeSha256']==record['exe']['sha256'] and value['zipSha256']==record['zip']['sha256']
        record['cleanStartup'] = value
    (EVIDENCE/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(record['exe']['sha256']+'  windows/PokemonTactics.exe\n'+record['zip']['sha256']+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps(record,ensure_ascii=False))


if __name__=='__main__': main()
