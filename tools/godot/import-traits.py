"""Explicit offline-game data import; pinned PokéAPI CSVs, no legacy edits."""
import csv, hashlib, io, json, pathlib, urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
LOCK = json.loads((ROOT/'tools/sources.lock.json').read_text())['pokeapi']
BASE = LOCK['raw']+'/data/v2/csv/'
sources = []

def rows(name):
    url = BASE+name+'.csv'
    cache = ROOT/'tools/cache'/hashlib.sha256(url.encode()).hexdigest()
    if not cache.exists():
        cache.parent.mkdir(parents=True,exist_ok=True)
        with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'pokemon-tactics-traits'}),timeout=40) as response:
            cache.write_bytes(response.read())
    payload = cache.read_bytes()
    sources.append({'url':url,'sha256':hashlib.sha256(payload).hexdigest()})
    return list(csv.DictReader(io.StringIO(payload.decode('utf-8-sig'))))

stats = {'2':'attack','3':'defense','4':'specialAttack','5':'specialDefense','6':'speed'}
names = {r['nature_id']:r['name'] for r in rows('nature_names') if r['local_language_id']=='7'}
natures = {}
for r in rows('natures'):
    up, down = stats[r['increased_stat_id']],stats[r['decreased_stat_id']]
    natures[r['identifier']] = {'name':names[r['id']],'up':up if up!=down else '', 'down':down if up!=down else ''}
catalog = json.loads((ROOT/'godot/data/letsgo.json').read_text(encoding='utf-8'))
ids = {p['id'] for p in catalog['species']}
ability_ids = {r['id']:r['identifier'] for r in rows('abilities')}
ability_names = {r['ability_id']:r['name'] for r in rows('ability_names') if r['local_language_id']=='7'}
species = {str(i):[] for i in sorted(ids)}
for r in rows('pokemon_abilities'):
    if int(r['pokemon_id']) in ids and r['is_hidden']=='0':
        species[r['pokemon_id']].append({'slot':int(r['slot']),'id':ability_ids[r['ability_id']]})
for entries in species.values(): entries.sort(key=lambda r:r['slot'])
descriptions = {
 'overgrow':'Espesura: potencia de movimientos Planta ×1,5 con un tercio de PS o menos.',
 'blaze':'Mar Llamas: potencia de movimientos Fuego ×1,5 con un tercio de PS o menos.',
 'torrent':'Torrente: potencia de movimientos Agua ×1,5 con un tercio de PS o menos.',
 'swarm':'Enjambre: potencia de movimientos Bicho ×1,5 con un tercio de PS o menos.',
 'shield-dust':'Polvo Escudo: bloquea efectos secundarios de movimientos dañinos enemigos; no movimientos de estado, empujes ni sus efectos propios.',
 'shed-skin':'Mudar: probabilidad de 1/3 de curar el estado principal al terminar su activación, antes del daño residual. No cura confusión ni Drenadoras.',
 'compound-eyes':'Ojo Compuesto: multiplica la precisión de sus movimientos por 1,3.',
 'keen-eye':'Vista Lince: evita bajadas de precisión e ignora etapas positivas de evasión del objetivo.',
 'tangled-feet':'Tumbos: duplica su evasión mientras está confuso.',
 'guts':'Agallas: Ataque ×1,5 al tener un estado principal; evita la reducción ofensiva de quemadura.',
 'static':'Elec. Estática: 30 % de paralizar a quien le acierte con contacto. El atacante debe seguir vivo, admitir parálisis y no tener otro estado principal.',
 'rock-head':'Cabeza Roca: evita el retroceso de movimientos. No evita Vidaesfera ni el coste de Autodestrucción.',
 'sturdy':'Robustez: con todos sus PS resiste un golpe que lo debilitaría, quedando en 1 PS. No evita daño residual o costes propios. Los multiimpactos actuales se resuelven como un golpe táctico agregado.',
 'chlorophyll':'Clorofila: duplica la Velocidad con sol. Pendiente del sistema de clima; no tiene efecto en los escenarios actuales.',
 'run-away':'Fuga: garantiza la huida ante Pokémon salvajes. Pendiente de la acción de huida; no tiene efecto en los encuentros actuales.'}
used = {e['id'] for entries in species.values() for e in entries}
assert used==set(descriptions),used-set(descriptions)
abilities = {name:{'name':ability_names[identity],'description':descriptions[name],'available':name not in ['chlorophyll','run-away']} for identity,name in ability_ids.items() if name in used}
move_ids = {r['identifier']:r['id'] for r in rows('moves')}
contact_ids = {r['move_id'] for r in rows('move_flag_map') if r['move_flag_id']=='1'}
contact = sorted(name for name in catalog['moves'] if move_ids[name] in contact_ids)
# The fixed typeless basic is a disclosed custom contact move.
contact.append('basic')
data = {'version':10,'reference':'Modern main-series normal ability slots; LGPE moves and tactical adaptations retained','natures':natures,'abilities':abilities,'species':species,'contact':contact,'mintPrice':100,'capsulePrice':150}
payload = (json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode()
(ROOT/'godot/data/traits.json').write_bytes(payload)
provenance = {'pokeapiCommit':LOCK['commit'],'sources':sources,'files':[{'target':'data/traits.json','sha256':hashlib.sha256(payload).hexdigest()}],'changes':'Selected 32 species, 25 natures and 15 normal abilities; Spanish descriptions and tactical timing supplied by project. 13 active abilities; climate/escape dependencies disclosed. No hidden abilities.'}
(ROOT/'godot/data/traits-provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'species':len(species),'natures':len(natures),'abilities':len(abilities),'contactMoves':len(contact),'sources':len(sources)}))
