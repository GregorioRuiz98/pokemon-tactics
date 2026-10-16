"""Explicit edition-5 import. Existing native/web editions are never rewritten.

PokéAPI provides species/levels but no per-species LGPE encounter probabilities.
The combined table therefore uses equal normal-species weights, and 1% for the
forest special spawn. These are disclosed tactical weights, not cartridge rates.
"""
import concurrent.futures, copy, csv, hashlib, io, json, pathlib, sys
ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from import_resources import fetch
from vendor.pokesurvivor_sprites import parse_animdata, resolve, ground_anchor
from PIL import Image
DEST = ROOT / 'godot'
LOCK = json.loads((ROOT / 'tools/sources.lock.json').read_text(encoding='utf-8'))
files, sources = [], []
GROUP = 'lets-go-pikachu-lets-go-eevee'
DENY = ['pika-papow','veevee-volley','zippy-zap','splishy-splash','floaty-fall',
        'bouncy-bubble','buzzy-buzz','sizzly-slide','glitzy-glow','baddy-bad',
        'sappy-seed','freezy-frost','sparkly-swirl']

def raw(url):
    value = fetch(url)
    sources.append(dict(url=url, sha256=hashlib.sha256(value).hexdigest()))
    return value

def put(path, value, source, modification='None'):
    target = DEST / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(value)
    files.append(dict(target=path, source=source, sha256=hashlib.sha256(value).hexdigest(), modification=modification))

def dump(path, value):
    put(path, (json.dumps(value, ensure_ascii=False, indent=2)+'\n').encode(), 'LGPE data and explicit tactical adaptations; see letsgo-provenance.json')

base = json.loads((DEST / 'data/progression.json').read_text(encoding='utf-8'))
ids = sorted([p['id'] for p in base['species']] + [43,44,45,69,70,71])
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    payloads = list(pool.map(lambda dex: raw(f'https://pokeapi.co/api/v2/pokemon/{dex}'), ids))
pokemon = {dex: json.loads(value) for dex, value in zip(ids, payloads)}
for dex in [43,44,45,69,70,71]:
    p = pokemon[dex]
    d = json.loads(raw(f'https://pokeapi.co/api/v2/pokemon-species/{dex}'))
    folder = f'assets/letsgo/{dex}'
    upstream = f"{LOCK['sprites']['raw']}/sprite/{dex:04d}"
    xml = raw(upstream+'/AnimData.xml')
    anims, _ = parse_animdata(xml.decode('utf-8-sig'))
    put(folder+'/AnimData.xml', xml, upstream+'/AnimData.xml')
    put(folder+'/credits.txt', raw(upstream+'/credits.txt'), upstream+'/credits.txt')
    animations = {}
    for name in ['Idle','Walk']:
        original, geometry = resolve(anims,name)
        url = f'{upstream}/{original}-Anim.png'
        png = raw(url)
        shadow = raw(f'{upstream}/{original}-Shadow.png')
        anchor = ground_anchor(shadow,geometry['w'],geometry['h'])
        image = Image.open(io.BytesIO(png))
        assert image.height//geometry['h'] == 8 and anchor is not None
        target = folder+'/'+name+'.png'
        put(target,png,url)
        if name=='Idle':
            thumbnail=io.BytesIO()
            image.crop((0,0,geometry['w'],geometry['h'])).save(thumbnail,format='PNG')
            put(folder+'/thumbnail.png',thumbnail.getvalue(),url,'First down-facing frame cropped; no recoloring')
        animations[name] = dict(width=geometry['w'],height=geometry['h'],columns=image.width//geometry['w'],rows=8,frames=geometry['n'],durations=geometry['d'],anchorX=anchor[0],anchorY=anchor[1],path=target)
    for name in ['Normal.png','credits.txt']:
        url = f"{LOCK['sprites']['raw']}/portrait/{dex:04d}/{name}"
        put(folder+'/'+('portrait-credits.txt' if name=='credits.txt' else name),raw(url),url)
    base['species'].append(dict(id=dex,name=next(n['name'] for n in d['names'] if n['language']['name']=='es'),types=[t['type']['name'] for t in p['types']],baseStats={s['stat']['name']:s['base_stat'] for s in p['stats']},legendary=d['is_legendary'],mythical=d['is_mythical'],animations=animations,face=folder+'/Normal.png',movement=4,role='Control y drenaje',actions={'current':[],'classic':[]}))
    print('Imported sprites/portrait:',dex,flush=True)
base['families'] += [dict(id='oddish',members=[43,44,45],roles=['Drenador','Controlador'],learnset=[]),dict(id='bellsprout',members=[69,70,71],roles=['Hostigador','Controlador'],learnset=[])]
learnsets, machines = {}, {}
for dex,p in pokemon.items():
    learned, compatible = {}, set()
    for entry in p['moves']:
        move = entry['move']['name']
        if move in DENY: continue
        for detail in entry['version_group_details']:
            if detail['version_group']['name'] != GROUP: continue
            method = detail['move_learn_method']['name']
            if method == 'level-up': learned[move] = min(learned.get(move,999),detail['level_learned_at'])
            if method == 'machine': compatible.add(move)
    learnsets[dex], machines[dex] = learned, compatible
    assert learned, f'Missing LGPE learnset: {dex}'

tms = ['brick-break','scald','mega-drain','protect','thunderbolt','rock-slide','iron-tail']
identities = sorted(set(tms).union(*(set(m) for m in learnsets.values())))
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    payloads = list(pool.map(lambda name: raw('https://pokeapi.co/api/v2/move/'+name),identities))
metadata = {name:json.loads(value) for name,value in zip(identities,payloads)}
stats = {'attack':'attack','defense':'defense','special-attack':'specialAttack','special-defense':'specialDefense','speed':'speed','accuracy':'accuracy','evasion':'evasion'}
ailments = {'poison':'poison','burn':'burn','paralysis':'paralysis','sleep':'sleep','freeze':'freeze','confusion':'confusion'}
moves = {}
for identity,p in metadata.items():
    category = p['damage_class']['name']
    meta = p.get('meta') or {}
    self_target = p['target']['name'] in ['user','users-field','user-and-allies','user-or-ally','all-allies']
    changes = [dict(stat=stats[e['stat']['name']],stages=e['change']) for e in p['stat_changes'] if e['stat']['name'] in stats]
    kind, target = ('damage','enemy') if category!='status' else ('stages','self' if self_target else 'enemy')
    power = p['power'] or 0
    # Explicit tactical costs/geometry; these are not PP or cartridge targeting.
    cost = 1 if power<=50 else 2 if power<=85 else 3 if power<=110 else 4
    distance = 1 if category=='physical' else 3
    if category=='status': cost,distance = 1,0 if self_target else 2
    ailment = ailments.get((meta.get('ailment') or {}).get('name'))
    if category=='status' and ailment: kind='status';cost=2
    if meta.get('drain',0)>0: kind='drain'
    if identity=='protect': kind,target,distance='guard','self',0
    if identity=='roost': kind,target,distance,cost='heal','self',0,2
    if identity in ['earthquake','heat-wave','petal-dance']: kind='area-damage';distance=2;cost=max(3,cost)
    if meta.get('min_hits') and meta['min_hits']>1: power*=2
    extra = []
    if identity in ['double-kick','twineedle','fury-swipes','fury-attack','pin-missile']: extra.append('Dos impactos agregados en una tirada.')
    if identity in ['solar-beam','razor-wind','sky-attack','skull-bash']: cost=4;extra.append('La carga se adapta a 4 PT; no requiere un turno de espera.')
    if identity in ['quick-attack','aqua-jet','fake-out','sucker-punch']: extra.append('No altera la cola fija ni hace retroceder; golpe inmediato.')
    if identity in ['focus-energy','mirror-move','rage','bide','encore','stealth-rock','light-screen']:
        # These translations are intentional, visible in the ability description.
        adaptations = {
          'focus-energy':('self',[('accuracy',1)],'Concentración: +1 Precisión; no hay críticos.'),
          'mirror-move':('self',[('evasion',1)],'Imitación táctica: +1 Evasión; no copia movimientos.'),
          'rage':('self',[('attack',1)],'Furia táctica: +1 Ataque; consume la acción.'),
          'bide':('self',[('defense',1)],'Aguante táctico: +1 Defensa; no almacena daño.'),
          'encore':('enemy',[('specialAttack',-1)],'Presión táctica: -1 Ataque especial; no obliga a repetir.'),
          'stealth-rock':('enemy',[('speed',-1)],'Obstáculo táctico: -1 Velocidad; no coloca trampas de entrada.'),
          'light-screen':('self',[('specialDefense',2)],'Pantalla táctica: +2 Defensa especial individual.')}
        target, adapted, explanation = adaptations[identity]
        changes=[dict(stat=s,stages=n) for s,n in adapted]
        kind,category,power,cost,distance='stages','status',0,2,0 if target=='self' else 2
        extra.append(explanation)
    if identity=='leech-seed': kind='status';ailment='seed';extra.append('Drenadoras: pierde 1/8 de PS durante tres activaciones; el usuario recupera ese daño si sigue vivo. Inmune Planta.')
    if identity=='whirlwind': kind='push';extra.append('Empuja una casilla sin causar daño; no expulsa de la batalla.')
    if identity=='counter': extra.append('Devuelve el doble del último daño recibido desde su anterior acción; sin daño previo no puede usarse.')
    if identity in ['dragon-rage','super-fang']: extra.append('Daño fijo: 40 PS.' if identity=='dragon-rage' else 'Resta la mitad de los PS actuales del objetivo.')
    if identity in ['self-destruct','explosion']: extra.append('El usuario cae tras resolver el ataque, incluso si falla.')
    if meta.get('flinch_chance',0)>0: extra.append('El retroceso de turno no se aplica en esta cola fija.')
    if meta.get('crit_rate',0)>0: extra.append('Sin bonificación de crítico en esta muestra.')
    if identity in ['wrap','bind','fire-spin']: extra.append('Golpe único; sin inmovilización ni daño de atrapamiento.')
    if identity in ['outrage','petal-dance']:
        ailment=None
        extra.append('Ataque de una acción; sin repetición forzosa ni confusión posterior.')
    if identity=='toxic': extra.append('Veneno táctico fijo: 1/8 de PS máximos por activación; no escala.')
    if identity=='clear-smog': extra.append('Si acierta, elimina todas las etapas de atributos del objetivo.')
    secondary = None
    if ailment and category!='status': secondary=dict(kind=ailment,chance=meta.get('ailment_chance') or 100,duration=3)
    definition = dict(id=identity,name=next(n['name'] for n in p['names'] if n['language']['name']=='es'),type=p['type']['name'],power=power,category=category,accuracy=p['accuracy'] or 100,cost=cost,range=distance,kind=kind,target=target,secondary=secondary,embers=False,changes=changes,changesSelf=self_target or identity in ['rage'],changeChance=meta.get('stat_chance') or 100,recoil=max(0,-meta.get('drain',0)),selfKO=identity in ['self-destruct','explosion'],clearStages=identity=='clear-smog',fixedMode=identity if identity in ['dragon-rage','super-fang','counter'] else '',description='')
    if kind=='status': definition.update(effect=dict(kind=ailment,chance=100,duration=3),powder=identity.endswith('powder') or identity=='stun-spore')
    if changes: extra.append('Etapas: '+', '.join(f"{c['stat']} {c['stages']:+d}" for c in changes)+'. Límite táctico -2/+2; dura el combate.')
    if ailment=='sleep': extra.append('Dormido: puede desplazarse, pero no atacar durante tres activaciones.')
    if ailment=='confusion': extra.append('Confuso: -25 puntos de precisión durante tres activaciones; sin autolesión.')
    definition['description']=definition['name']+' · PT y alcance tácticos. '+' '.join(extra)
    assert category!='status' or kind in ['guard','heal','status','push'] or changes, identity
    moves[identity]=definition
for family in base['families']:
    family['learnset']=[]
    for dex in family['members']:
        for move,level in sorted(learnsets[dex].items(),key=lambda e:(e[1],e[0])):
            d=moves[move]
            role=1 if d['category']=='status' or d.get('secondary') else 0
            family['learnset'].append(dict(id=move,level=level,role=role,forms=[dex]))
base.update(version=5,moves=moves,excludedPartnerMoves=DENY)
base['evolutions'].update({'43':[44,21],'69':[70,21]})
base['stoneEvolutions']={'44':[45,'leaf-stone'],'70':[71,'leaf-stone']}
base['species'].sort(key=lambda p:p['id'])
for record in base['species']: record['actions']={'current':[],'classic':[]}
# Encounter facts from pinned CSV; ground encounters only, no postgame flying slots.
def table(name):
    url=f"{LOCK['pokeapi']['raw']}/data/v2/csv/{name}.csv"
    return list(csv.DictReader(io.StringIO(raw(url).decode())))
encounters=table('encounters')
base['encounters']={}
for name,area in [('Route1',295),('Route2',296),('ViridianForest',321)]:
    union={}
    for row in encounters:
        if int(row['version_id']) not in [31,32] or int(row['location_area_id'])!=area or int(row['encounter_slot_id']) not in [1173,1176]:continue
        dex=int(row['pokemon_id'])
        entry=union.setdefault(dex,dict(speciesId=dex,minLevel=int(row['min_level']),maxLevel=int(row['max_level']),versions=[],special=int(row['encounter_slot_id'])==1176))
        entry['versions'].append(int(row['version_id']))
        assert dex in ids
    base['encounters'][name]=sorted(union.values(),key=lambda e:e['speciesId'])
base['encounterNote']='Unión de ambas ediciones. Especies y niveles LGPE terrestres; probabilidades tácticas: normales equiprobables, Bulbasaur especial 1%. Sin combos, señuelos ni apariciones aéreas posjuego.'
machine_rows=table('machines')
numbers={int(r['move_id']):int(r['machine_number']) for r in machine_rows if int(r['version_group_id'])==19}
shop=copy.deepcopy(json.loads((DEST/'data/shop.json').read_text(encoding='utf-8')))
shop['items']={k:v for k,v in shop['items'].items() if v['kind']=='held'}
for move in tms:
    p=metadata[move]
    shop['items']['tm-'+move]=dict(name=f"MT{numbers[p['id']]:02d} · {moves[move]['name']}",kind='tm',move=move,price=80,species=[dex for dex in ids if move in machines[dex]],description='MT de Let’s Go, un uso. Compatibilidad exclusiva de esas ediciones; cuatro movimientos preparados como máximo.')
shop['moves']={}
shop['sourceNote']='Numeración, aprendizaje y compatibilidad de MT del grupo LGPE. Uso consumible, alcance/PT y equipables son adaptaciones tácticas.'
font_base=f"{LOCK['fonts']['raw']}/ofl/atkinsonhyperlegible"
put('assets/fonts/AtkinsonHyperlegible-Regular.ttf',raw(font_base+'/AtkinsonHyperlegible-Regular.ttf'),font_base+'/AtkinsonHyperlegible-Regular.ttf')
put('licenses/Atkinson-Hyperlegible-OFL.txt',raw(font_base+'/OFL.txt'),font_base+'/OFL.txt')
dump('data/letsgo.json',base)
dump('data/letsgo-shop.json',shop)
names = {}
for line in raw(f"{LOCK['sprites']['raw']}/credit_names.txt").decode('utf-8-sig').splitlines()[1:]:
    parts=line.split('\t')
    if len(parts)>=2: names[parts[1].strip()]=parts[0].strip() or parts[1].strip()
authors = {}
for dex in [43,44,45,69,70,71]:
    credits = '\n'.join((DEST/f'assets/letsgo/{dex}/{name}').read_text(encoding='utf-8-sig') for name in ['credits.txt','portrait-credits.txt'])
    authors[str(dex)] = sorted({names.get(line.split('\t')[1],line.split('\t')[1]) for line in credits.splitlines() if '\t' in line})
(DEST/'data/letsgo-provenance.json').write_text(json.dumps(dict(spriteCommit=LOCK['sprites']['commit'],pokeapiCommit=LOCK['pokeapi']['commit'],fontsCommit=LOCK['fonts']['commit'],authors=authors,files=files,sources=sorted(sources,key=lambda s:s['url'])),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Imported {len(ids)} species, {len(moves)} moves, 12 families, seven LGPE TMs, three combined encounter tables.',flush=True)
