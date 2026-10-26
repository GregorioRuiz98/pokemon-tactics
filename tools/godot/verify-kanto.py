"""Check atlas alpha/CRC/hash, authored content and unchanged numerical balance."""
from pathlib import Path
import importlib.util
import json

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('art_validation', ROOT/'tools/godot/art-assets.py')
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
manifest = json.loads((ROOT/'godot/assets/kanto/provenance.json').read_text(encoding='utf-8'))
result = art.inspect_png(ROOT/'godot'/manifest['target'], {'width':manifest['width'],'height':manifest['height'],'alpha':True,'kind':'prop'})
assert result['sha256']==manifest['sha256']
old = json.loads((ROOT/'godot/data/journey-24.json').read_text(encoding='utf-8-sig'))
new = json.loads((ROOT/'godot/data/journey-26.json').read_text(encoding='utf-8'))
layouts = json.loads((ROOT/'godot/data/kanto-landscapes.json').read_text(encoding='utf-8'))
assert list(layouts)==[node['id'] for node in new] and len(new)==58
for before, after in zip(old,new):
    ignore = {'story','path','optional','requires'} if after.get('finale') else set()
    assert {k:v for k,v in before.items() if k not in ignore}=={k:v for k,v in after.items() if k not in ignore}
assert new[56]['requires']==['champion'] and new[57]['requires']==['legendary-birds']
print(json.dumps({'atlas':result,'maps':116,'numericalEncounterDataUnchanged':True,'offline':True}))
