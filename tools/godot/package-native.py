"""Package the already tested native release; no editor, network or dependencies."""
import hashlib,json,os,pathlib,re,shutil,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
version=re.search(r'config/version="([^"]+)"',(ROOT/'godot/project.godot').read_text(encoding='utf-8'))[1]
chapter=int(version.split('.')[1]);patch=int(version.split('.')[2]);modern=chapter==22 and patch>=4;qa_label={'0.22.1':'22-ui','0.22.2':'22-controls','0.22.3':'22-context'}.get(version,'22-updates-'+str(patch) if modern else str(chapter));work=ROOT/f'../../work/qa-sprint-{qa_label}'
source=json.loads((work/'journey-source/journey-ui-result.json').read_text(encoding='utf-8'))
exported=json.loads((work/'journey-release/journey-ui-result.json').read_text(encoding='utf-8'))
assert source==exported and not source['failures'] and source['phase'] in ['complete','ending']
psychic=None
if chapter>=21:
    psychic=json.loads((work/'journey-psychic-source/journey-ui-result.json').read_text(encoding='utf-8'))
    psychic_export=json.loads((work/'journey-psychic-release/journey-ui-result.json').read_text(encoding='utf-8'))
    assert psychic==psychic_export and not psychic['failures'] and psychic['phase']=='ending'
    assert source['finalPath']=='birds' and psychic['finalPath']=='psychic'
interface=None
if chapter==22 and patch>=1:
    interface=json.loads((work/'interface-source/interface-ui-result.json').read_text(encoding='utf-8'))
    interface_export=json.loads((work/'interface-release/interface-ui-result.json').read_text(encoding='utf-8'))
    assert interface==interface_export and not interface['failures']
controls=None
if chapter==22 and patch>=2:
    controls=json.loads((work/'input-source/input-ui-result.json').read_text(encoding='utf-8'))
    controls_export=json.loads((work/'input-release/input-ui-result.json').read_text(encoding='utf-8'))
    assert controls==controls_export and not controls['failures']
context=None
if chapter==22 and patch>=3:
    context=json.loads((work/'context-source/context-ui-result.json').read_text(encoding='utf-8'))
    context_export=json.loads((work/'context-release/context-ui-result.json').read_text(encoding='utf-8'))
    assert context==context_export and not context['failures'] and context['naturalReplay']
release=ROOT/f'../releases/pokemon-tactics-{version}';bundle=release/'windows'
if controls:
    shutil.copy2(ROOT/'docs/PLAYTEST_WINDOWS.md',bundle/'GUIA_DE_PRUEBA.md')
    shutil.copy2(ROOT/('docs/SPRINT_22_ACCESSIBILITY_COMPLETE.md' if modern else ('docs/SPRINT_22_CONTEXT.md' if context else 'docs/SPRINT_22_CONTROLS.md')),bundle/'CONTROLES_Y_NAVEGACION.md')
exe=bundle/'PokemonTactics.exe';digest=hashlib.sha256(exe.read_bytes()).hexdigest()
assert digest in (bundle/'SHA256SUMS.txt').read_text()
laboratory=None
if context:
    laboratory=json.loads((work/'source/ui-result.json').read_text(encoding='utf-8'))
    assert laboratory==json.loads((work/'release/ui-result.json').read_text(encoding='utf-8')) and not laboratory['failures']
    for folder,name,save in [('context','context-ui-result.json',None),('input','input-ui-result.json',None),('interface','interface-ui-result.json',None),('journey','journey-ui-result.json','campaign-save.json'),('journey-psychic','journey-ui-result.json','campaign-save.json'),('', 'ui-result.json','ui-save.json')]:
        left=work/(folder+'-source' if folder else 'source');right=work/(folder+'-release' if folder else 'release')
        assert (right/name).stat().st_mtime>=exe.stat().st_mtime, 'Stale executable QA: '+str(right/name)
        if save:
            a=json.loads(json.loads((left/save).read_text(encoding='utf-8'))['payload'])
            b=json.loads(json.loads((right/save).read_text(encoding='utf-8'))['payload'])
            assert a['state']==b['state'] and a['commands']==b['commands'], 'Source/executable full state mismatch: '+folder
updates=None
semantic=None
roster=None
baseline=None
if modern:
    updates=json.loads((work/'updates-source/updates-ui-result.json').read_text(encoding='utf-8'))
    assert updates==json.loads((work/'updates-release/updates-ui-result.json').read_text(encoding='utf-8')) and not updates['failures']
    assert (work/'updates-release/updates-ui-result.json').stat().st_mtime>=exe.stat().st_mtime
    shutil.copytree(ROOT/'docs/reports/aceptacion-0.22.10',bundle/'PRUEBAS_HUMANAS',dirs_exist_ok=True)
    shutil.copytree(ROOT/'docs/reports/aceptacion-0.22.10',bundle/'reports/aceptacion-0.22.10',dirs_exist_ok=True)
    for document in (ROOT/'docs').glob('SPRINT_22*.md'): shutil.copy2(document,bundle/document.name)
    semantic=json.loads((work/'semantic-source/updates-ui-result.json').read_text(encoding='utf-8'))
    assert semantic==json.loads((work/'semantic-release/updates-ui-result.json').read_text(encoding='utf-8')) and not semantic['failures']
    assert (work/'semantic-release/updates-ui-result.json').stat().st_mtime>=exe.stat().st_mtime
    shutil.copy2(ROOT/'docs/SPRINT_22_SCREEN_READER.md',bundle/'LECTOR_DE_PANTALLA.md')
    roster=json.loads((work/'roster-source/roster-ui-result.json').read_text(encoding='utf-8'))
    assert roster==json.loads((work/'roster-release/roster-ui-result.json').read_text(encoding='utf-8')) and not roster['failures']
    assert (work/'roster-release/roster-ui-result.json').stat().st_mtime>=exe.stat().st_mtime
    for side in ['source','release']:
        saved=json.loads(json.loads((work/f'roster-{side}/campaign-save.json').read_text(encoding='utf-8'))['payload'])
        if side=='source': roster_saved=saved
        else: assert saved['state']==roster_saved['state'] and saved['commands']==roster_saved['commands']
    baseline=json.loads((work/'baseline-parity.json').read_text(encoding='utf-8'))
    assert all(item['fullStateEqualTo0223'] and item['commandsEqualTo0223'] for item in baseline.values())
archive=release/f'pokemon-tactics-{version}-windows.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
    for file in sorted(bundle.rglob('*')):
        if file.is_file():package.write(file,pathlib.Path('windows')/file.relative_to(bundle))
with zipfile.ZipFile(archive) as package:assert package.testzip() is None
zip_digest=hashlib.sha256(archive.read_bytes()).hexdigest()
evidence=ROOT/f'docs/qa/sprint-{qa_label}';evidence.mkdir(parents=True,exist_ok=True)
for kind in ['source','release']:shutil.copy2(work/f'journey-{kind}/journey-ui-result.json',evidence/f'ui-{kind}.json')
if psychic:
    for kind in ['source','release']:shutil.copy2(work/f'journey-psychic-{kind}/journey-ui-result.json',evidence/f'ui-psychic-{kind}.json')
state=json.loads(json.loads((work/'journey-source/campaign-save.json').read_text(encoding='utf-8'))['payload'])['state']
fingerprint=hashlib.sha256()
for path in sorted((ROOT/'godot').rglob('*')):
    if path.is_file() and '.godot' not in path.parts and (path.suffix in ['.gd','.tscn'] or path.name in ['project.godot','export_presets.cfg']):
        fingerprint.update(path.relative_to(ROOT).as_posix().encode());fingerprint.update(path.read_bytes())
record={'sourceFingerprint':fingerprint.hexdigest(),'version':version,'campaignEdition':chapter-4,'combatEdition':state.get('battle',{}).get('combatEdition',0),'exe':{'path':os.path.abspath(exe),'bytes':exe.stat().st_size,'sha256':digest},'zip':{'path':os.path.abspath(archive),'bytes':archive.stat().st_size,'sha256':zip_digest},'uiSourceAndReleaseEqual':True,'releaseAssertions':source['assertions'],'publicDeployment':False}
if psychic:record.update(bothEndingsVerified=True,psychicAssertions=psychic['assertions'])
if interface:
    record.update(titleMenuVerified=True,interfaceAssertions=interface['assertions'])
    for kind in ['source','release']:shutil.copy2(work/f'interface-{kind}/interface-ui-result.json',evidence/f'interface-{kind}.json')
if controls:
    record.update(controlsVerified=True,controlsAssertions=controls['assertions'])
    for kind in ['source','release']:shutil.copy2(work/f'input-{kind}/input-ui-result.json',evidence/f'input-{kind}.json')
if context:
    record.update(contextVerified=True,contextAssertions=context['assertions'])
    for kind in ['source','release']:shutil.copy2(work/f'context-{kind}/context-ui-result.json',evidence/f'context-{kind}.json')
if laboratory:
    record.update(laboratoryAssertions=laboratory['assertions'],fullSavedStatesEqual=True)
    for kind in ['source','release']:shutil.copy2(work/kind/'ui-result.json',evidence/f'laboratory-{kind}.json')
if roster:
    record.update(rosterAssertions=roster['assertions'])
    for kind in ['source','release']: shutil.copy2(work/f'roster-{kind}/roster-ui-result.json',evidence/f'roster-{kind}.json')
if baseline:
    record.update(baseline0223StatesAndJournalsEqual=True)
    shutil.copy2(work/'baseline-parity.json',evidence/'baseline-parity.json')
if semantic:
    record.update(semanticAssertions=semantic['assertions'])
    for kind in ['source','release']:
        shutil.copy2(work/f'semantic-{kind}/updates-ui-result.json',evidence/f'semantic-{kind}.json')
        shutil.copy2(work/f'semantic-{kind}/accessibility-probe.json',evidence/f'semantic-probe-{kind}.json')
if updates:
    record.update(updatesAssertions=updates['assertions'],screenReaderHumanValidation='pending',humanBeta='prepared-pending')
    for kind in ['source','release']:
        shutil.copy2(work/f'updates-{kind}/updates-ui-result.json',evidence/f'updates-{kind}.json')
        shutil.copy2(work/f'updates-{kind}/accessibility-probe.json',evidence/f'accessibility-{kind}.json')
(evidence/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(release/'SHA256SUMS.txt').write_text(digest+'  windows/PokemonTactics.exe\n'+zip_digest+'  '+archive.name+'\n',encoding='utf-8')
print(json.dumps(record,ensure_ascii=False))
