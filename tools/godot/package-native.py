"""Package the already tested native release; no editor, network or dependencies."""
import hashlib,json,os,pathlib,re,shutil,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
version=re.search(r'config/version="([^"]+)"',(ROOT/'godot/project.godot').read_text(encoding='utf-8'))[1]
chapter=int(version.split('.')[1]);qa_label={'0.22.1':'22-ui','0.22.2':'22-controls'}.get(version,str(chapter));work=ROOT/f'../../work/qa-sprint-{qa_label}'
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
if version in ['0.22.1','0.22.2']:
    interface=json.loads((work/'interface-source/interface-ui-result.json').read_text(encoding='utf-8'))
    interface_export=json.loads((work/'interface-release/interface-ui-result.json').read_text(encoding='utf-8'))
    assert interface==interface_export and not interface['failures']
controls=None
if version=='0.22.2':
    controls=json.loads((work/'input-source/input-ui-result.json').read_text(encoding='utf-8'))
    controls_export=json.loads((work/'input-release/input-ui-result.json').read_text(encoding='utf-8'))
    assert controls==controls_export and not controls['failures']
release=ROOT/f'../releases/pokemon-tactics-{version}';bundle=release/'windows'
if controls:
    shutil.copy2(ROOT/'docs/PLAYTEST_WINDOWS.md',bundle/'GUIA_DE_PRUEBA.md')
    shutil.copy2(ROOT/'docs/SPRINT_22_CONTROLS.md',bundle/'CONTROLES_Y_NAVEGACION.md')
exe=bundle/'PokemonTactics.exe';digest=hashlib.sha256(exe.read_bytes()).hexdigest()
assert digest in (bundle/'SHA256SUMS.txt').read_text()
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
record={'version':version,'campaignEdition':chapter-4,'combatEdition':state.get('battle',{}).get('combatEdition',0),'exe':{'path':os.path.abspath(exe),'bytes':exe.stat().st_size,'sha256':digest},'zip':{'path':os.path.abspath(archive),'bytes':archive.stat().st_size,'sha256':zip_digest},'uiSourceAndReleaseEqual':True,'releaseAssertions':source['assertions'],'publicDeployment':False}
if psychic:record.update(bothEndingsVerified=True,psychicAssertions=psychic['assertions'])
if interface:
    record.update(titleMenuVerified=True,interfaceAssertions=interface['assertions'])
    for kind in ['source','release']:shutil.copy2(work/f'interface-{kind}/interface-ui-result.json',evidence/f'interface-{kind}.json')
if controls:
    record.update(controlsVerified=True,controlsAssertions=controls['assertions'])
    for kind in ['source','release']:shutil.copy2(work/f'input-{kind}/input-ui-result.json',evidence/f'input-{kind}.json')
(evidence/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(release/'SHA256SUMS.txt').write_text(digest+'  windows/PokemonTactics.exe\n'+zip_digest+'  '+archive.name+'\n',encoding='utf-8')
print(json.dumps(record,ensure_ascii=False))
