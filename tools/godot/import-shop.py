"""Import edition-3 move metadata/compatibility; never rewrite published editions."""
import hashlib, json, pathlib, sys
ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from import_resources import fetch
DEST = ROOT / 'godot'
sources = []
def source(url):
    raw = fetch(url)
    sources.append(dict(url=url, sha256=hashlib.sha256(raw).hexdigest()))
    return json.loads(raw)
base = json.loads((DEST / 'data/progression.json').read_text(encoding='utf-8'))
move = source('https://pokeapi.co/api/v2/move/brick-break')
brick = dict(id='brick-break', name='Demolición', type=move['type']['name'], power=move['power'], category=move['damage_class']['name'], accuracy=move['accuracy'], cost=2, range=1, kind='damage', target='enemy', secondary=None, embers=False, description='Demolición: cobertura física de Lucha, 2 PT y alcance 1. No hay pantallas en esta muestra.')
tms = [('tm-brick-break','MT31 · Demolición','brick-break'), ('tm-water-pulse','MT03 · Hidropulso','water-pulse'), ('tm-mega-drain','MT21 · Megaagotar','mega-drain'), ('tm-protect','MT17 · Protección','protect'), ('tm-thunderbolt','MT24 · Rayo','thunderbolt'), ('tm-rock-tomb','MT39 · Tumba Rocas','rock-tomb')]
compatibility = {identity: [] for identity, _, _ in tms}
for record in base['species']:
    pokemon = source(f"https://pokeapi.co/api/v2/pokemon/{record['id']}")
    # A selected move must have an actual machine entry, across supported games.
    machines = {entry['move']['name'] for entry in pokemon['moves'] if any(d['move_learn_method']['name'] == 'machine' for d in entry['version_group_details'])}
    for identity, _, name in tms:
        if name in machines: compatibility[identity].append(record['id'])
items = {}
for identity, name, move_id in tms:
    items[identity] = dict(name=name, kind='tm', move=move_id, price=80, species=compatibility[identity], description='Un uso: enseña el movimiento a un Pokémon compatible. Prepararlo después es gratis; máximo cuatro.')
for identity, name, price, description in [
    ('life-orb','Vidaesfera',100,'Daño ×1,3. Pierde el 10% de PS máximos una vez por acción que cause daño; puede caer por el retroceso.'),
    ('leftovers','Restos',100,'Recupera 1/16 de PS máximos al terminar su activación si sigue vivo.'),
    ('assault-vest','Chaleco Asalto',90,'Defensa especial ×1,5. Impide movimientos de estado y apoyo.'),
    ('heavy-duty-boots','Botas Gruesas',60,'Evita el daño de las casillas con ascuas. No evita los estados.')]:
    items[identity] = dict(name=name, kind='held', price=price, description=description)
source('https://pokeapi.co/api/v2/item/life-orb')
catalog = dict(items=items, moves={'brick-break':brick}, rerollBase=25, sourceNote='Compatibilidad por MT verificada en PokéAPI, unión de versiones. Numeración de MT de distintas generaciones; alcance/PT y economía son adaptaciones tácticas.')
raw = (json.dumps(catalog, ensure_ascii=False, indent=2)+'\n').encode('utf-8')
(DEST/'data/shop.json').write_bytes(raw)
(DEST/'data/shop-provenance.json').write_text(json.dumps(dict(sources=sources, files=[dict(target='data/shop.json', sha256=hashlib.sha256(raw).hexdigest())]), indent=2)+'\n', encoding='utf-8')
assert 4 in compatibility['tm-brick-break']
print('Imported 10 shop items, one new move, 26 machine compatibility tables.')
