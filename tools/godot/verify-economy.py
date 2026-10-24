"""Verify the locally cached, pinned PokéAPI inputs and imported EXP tables."""
from pathlib import Path
import csv,hashlib,json,urllib.request,sys
ROOT=Path(__file__).resolve().parents[2]
CACHE=ROOT/'tools/godot/reference/economy'
config=json.loads((ROOT/'godot/data/economy.json').read_text(encoding='utf-8'))
CACHE.mkdir(parents=True,exist_ok=True)
for name,expected in config['sources']['files'].items():
    file=CACHE/name
    if not file.exists() and '--fetch' in sys.argv:
        url=f"https://raw.githubusercontent.com/PokeAPI/pokeapi/{config['sources']['pokeapiCommit']}/data/v2/csv/{name}"
        file.write_bytes(urllib.request.urlopen(url,timeout=30).read())
    if not file.exists(): raise SystemExit(f'Missing cached reference {file}; use --fetch explicitly.')
    assert hashlib.sha256(file.read_bytes()).hexdigest()==expected,name
species={row['id']:int(row['growth_rate_id']) for row in csv.DictReader((CACHE/'pokemon_species.csv').open(encoding='utf-8')) if int(row['id'])<=151}
curves={str(i):[0]*101 for i in range(1,7)}
for row in csv.DictReader((CACHE/'experience.csv').open(encoding='utf-8')):curves[row['growth_rate_id']][int(row['level'])]=int(row['experience'])
assert species==config['growthGroups'] and curves==config['curves']
print(json.dumps({'species':len(species),'curves':len(curves),'sourceHashesVerified':True,'runtimeNetwork':False}))
