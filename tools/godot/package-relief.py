"""Package RC3 only after terrain, natural campaign and source/EXE checks."""
from pathlib import Path
import json
import runpy
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
helpers = runpy.run_path(str(ROOT/'tools/godot/package-candidate.py'))
WORK, BUNDLE, RELEASE, EXE = [helpers[key] for key in ['WORK','BUNDLE','RELEASE','EXE']]
EVIDENCE = ROOT/'docs/qa/sprint-40'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    assert helpers['VERSION']=='1.0.0-rc.3' and EXE.is_file()
    subprocess.run(['git','diff','--exit-code','--diff-filter=MDR','0c29df9c98782d250b14728bcaa8bb852b483adf','--',*helpers['PROTECTED']],cwd=ROOT,check=True,capture_output=True)
    source = read(WORK/'relief-source/relief-ui.json')
    exported_path = WORK/'relief-release/relief-ui.json'
    assert exported_path.stat().st_mtime>=EXE.stat().st_mtime, 'Stale EXE evidence'
    exported = read(exported_path)
    helpers['verify_pair'](source,exported,1800)
    assert len(source['gallery'])==116 and source['campaignEdition']==30
    rules = read(WORK/'relief-rules/relief-rules.json')
    compatibility = read(WORK/'relief-compat/compatibility.json')
    assert not compatibility['failures'] and compatibility['checks']>=15
    campaign = read(WORK/'natural-relief-final/campaign-review.json')
    replay = read(WORK/'natural-relief-final/full-cold-replay.json')
    assert not replay['failures'] and not replay['cached'] and replay['phase']=='ending' and replay['orders']==campaign['orders']
    authored = read(WORK/'authored-geometry.json')
    assert not rules['failures'] and rules['checks']>=5600 and len(rules['gallery'])==116
    assert not campaign['failures'] and campaign['phase']=='ending' and len(campaign['cleared'])==58 and len(campaign['medals'])==8
    assert authored['ok'] and len(authored['layouts'])==58
    for result in [source,exported,rules,campaign]: assert result['mapCatalogHash']==authored['sha256']
    validation, lint = read(WORK/'validation.json'), read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors']==0 and validation['counts']['warnings']==65 and lint['ok']
    EVIDENCE.mkdir(exist_ok=True,parents=True)
    for name,value in [('full-cold-replay',replay),('compatibility',compatibility),('rules',rules),('authored-geometry',authored),('campaign',campaign),('source',source),('exported',exported)]:
        (EVIDENCE/(name+'.json')).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for name,value in [('validation',validation),('lint',lint)]:
        (EVIDENCE/(name+'.json')).write_text(json.dumps({'ok':value['ok'],'counts':value.get('counts',{})},indent=2)+'\n',encoding='utf-8')
    for name in ['forest','brock','route-24','legendary-birds','legendary-origin']:
        shutil.copy2(WORK/f'relief-source/{name}.png',EVIDENCE/(name+'.png'))
    docs = BUNDLE/'Documentacion'; docs.mkdir(exist_ok=True)
    for name in ['REGLAS_ACTUALES.md','PLAYTEST_WINDOWS.md','BETA_1_0.md','PLANTILLA_BETA.md','RELEASE_1_0_RC3.md','MAPAS_RELIEVE.md']:
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
    verification = {'version':'1.0.0-rc.3','campaignEdition':30,'combatEdition':25,'uiChecksPerBuild':source['assertions'],'coreChecks':rules['checks'],'compatibilityChecks':compatibility['checks'],'layouts':116,'campaignLocations':len(campaign['cleared']),'campaignMedals':len(campaign['medals']),'campaignOrders':campaign['orders'],'sourceAndExeUIStateMatch':True,'fullCampaignInExe':False,'campaignBattles':57,'fullCampaignColdReplay':{'cached':replay['cached'],'orders':replay['orders'],'stateHash':replay['stateHash']},'mapCatalogHash':authored['sha256'],'errors':0,'warnings':65,'newWarnings':0,'scope':'Natural legal-command headless campaign, per-order native opening and116 source/EXE rendering fixtures. No injected campaign victories.','humanPlaytest':False,'externalHardwareTest':False,'publicDeployment':False}
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
