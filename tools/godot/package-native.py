"""Package the already tested native release; no editor, network or dependencies."""
import hashlib,json,os,pathlib,re,shutil,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
version=re.search(r'config/version="([^"]+)"',(ROOT/'godot/project.godot').read_text(encoding='utf-8'))[1]
chapter=int(version.split('.')[1]);work=ROOT/f'../../work/qa-sprint-{chapter}'
source=json.loads((work/'journey-source/journey-ui-result.json').read_text(encoding='utf-8'))
exported=json.loads((work/'journey-release/journey-ui-result.json').read_text(encoding='utf-8'))
assert source==exported and not source['failures'] and source['phase'] in ['complete','ending']
psychic=None
if chapter>=21:
    psychic=json.loads((work/'journey-psychic-source/journey-ui-result.json').read_text(encoding='utf-8'))
    psychic_export=json.loads((work/'journey-psychic-release/journey-ui-result.json').read_text(encoding='utf-8'))
    assert psychic==psychic_export and not psychic['failures'] and psychic['phase']=='ending'
    assert source['finalPath']=='birds' and psychic['finalPath']=='psychic'
release=ROOT/f'../releases/pokemon-tactics-{version}';bundle=release/'windows'
exe=bundle/'PokemonTactics.exe';digest=hashlib.sha256(exe.read_bytes()).hexdigest()
assert digest in (bundle/'SHA256SUMS.txt').read_text()
archive=release/f'pokemon-tactics-{version}-windows.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as package:
    for file in sorted(bundle.rglob('*')):
        if file.is_file():package.write(file,pathlib.Path('windows')/file.relative_to(bundle))
with zipfile.ZipFile(archive) as package:assert package.testzip() is None
zip_digest=hashlib.sha256(archive.read_bytes()).hexdigest()
evidence=ROOT/f'docs/qa/sprint-{chapter}';evidence.mkdir(parents=True,exist_ok=True)
for kind in ['source','release']:shutil.copy2(work/f'journey-{kind}/journey-ui-result.json',evidence/f'ui-{kind}.json')
if psychic:
    for kind in ['source','release']:shutil.copy2(work/f'journey-psychic-{kind}/journey-ui-result.json',evidence/f'ui-psychic-{kind}.json')
state=json.loads(json.loads((work/'journey-source/campaign-save.json').read_text(encoding='utf-8'))['payload'])['state']
record={'version':version,'campaignEdition':chapter-4,'combatEdition':state.get('battle',{}).get('combatEdition',0),'exe':{'path':os.path.abspath(exe),'bytes':exe.stat().st_size,'sha256':digest},'zip':{'path':os.path.abspath(archive),'bytes':archive.stat().st_size,'sha256':zip_digest},'uiSourceAndReleaseEqual':True,'releaseAssertions':source['assertions'],'publicDeployment':False}
if psychic:record.update(bothEndingsVerified=True,psychicAssertions=psychic['assertions'])
(evidence/'release.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(release/'SHA256SUMS.txt').write_text(digest+'  windows/PokemonTactics.exe\n'+zip_digest+'  '+archive.name+'\n',encoding='utf-8')
print(json.dumps(record,ensure_ascii=False))
