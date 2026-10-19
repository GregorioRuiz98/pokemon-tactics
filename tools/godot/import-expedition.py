"""Explicit Kanto expansion import. Original editions and source images stay frozen.

Reuses the project's cached SpriteCollab importer and reviewed LGPE move adapter.
Run with the already installed Pillow runtime via PYTHONPATH=../../work/balance-python.
"""
import concurrent.futures, copy, csv, hashlib, io, json, pathlib, sys
ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from import_resources import fetch
from vendor.pokesurvivor_sprites import parse_animdata, resolve, ground_anchor
from PIL import Image
DEST=ROOT/'godot'; LOCK=json.loads((ROOT/'tools/sources.lock.json').read_text())
files=[]; sources=[]
def raw(url):
    data=fetch(url); sources.append({'url':url,'sha256':hashlib.sha256(data).hexdigest()}); return data
def put(path,data,source,modification='None'):
    target=DEST/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    files.append({'target':path,'source':source,'sha256':hashlib.sha256(data).hexdigest(),'modification':modification})
def dump(path,data):put(path,(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode(), 'Pinned public data and project tactical adaptations')
def rows(name):return list(csv.DictReader(io.StringIO(raw(LOCK['pokeapi']['raw']+'/data/v2/csv/'+name+'.csv').decode('utf-8-sig'))))
def parallel(fn,values):
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:return list(pool.map(fn,values))
base=json.loads((DEST/'data/letsgo.json').read_text(encoding='utf-8'))
old_ids={p['id'] for p in base['species']}
pokemon=dict(zip(range(1,152),parallel(lambda i:json.loads(raw(f'https://pokeapi.co/api/v2/pokemon/{i}')),range(1,152))))
details=dict(zip(range(1,152),parallel(lambda i:json.loads(raw(f'https://pokeapi.co/api/v2/pokemon-species/{i}')),range(1,152))))
def import_sprite(dex):
    folder=f'assets/expedition/{dex}';upstream=f"{LOCK['sprites']['raw']}/sprite/{dex:04d}"
    xml=raw(upstream+'/AnimData.xml');anims,_=parse_animdata(xml.decode('utf-8-sig'))
    put(folder+'/AnimData.xml',xml,upstream+'/AnimData.xml')
    put(folder+'/credits.txt',raw(upstream+'/credits.txt'),upstream+'/credits.txt')
    animations={}
    for name in ['Idle','Walk']:
        original,geometry=resolve(anims,name);url=upstream+'/'+original+'-Anim.png';png=raw(url)
        anchor=ground_anchor(raw(upstream+'/'+original+'-Shadow.png'),geometry['w'],geometry['h'])
        image=Image.open(io.BytesIO(png));assert image.height//geometry['h']==8 and anchor is not None
        target=folder+'/'+name+'.png';put(target,png,url)
        animations[name]=dict(width=geometry['w'],height=geometry['h'],columns=image.width//geometry['w'],rows=8,frames=geometry['n'],durations=geometry['d'],anchorX=anchor[0],anchorY=anchor[1],path=target)
    for name in ['Normal.png','credits.txt']:
        url=f"{LOCK['sprites']['raw']}/portrait/{dex:04d}/{name}"
        put(folder+'/'+('portrait-credits.txt' if name=='credits.txt' else name),raw(url),url)
    p=pokemon[dex];d=details[dex]
    print('Imported',dex,flush=True)
    return dict(id=dex,name=next(n['name'] for n in d['names'] if n['language']['name']=='es'),types=[t['type']['name'] for t in p['types']],baseStats={s['stat']['name']:s['base_stat'] for s in p['stats']},legendary=d['is_legendary'],mythical=d['is_mythical'],animations=animations,face=folder+'/Normal.png',movement=4,role='Especialista de Kanto',actions={'current':[],'classic':[]})
extra_species=parallel(import_sprite,sorted(set(range(1,152))-old_ids))
DENY=base['excludedPartnerMoves'];learnsets={};machines={}
for dex,p in pokemon.items():
    learned={};compatible=set()
    for entry in p['moves']:
        move=entry['move']['name']
        if move in DENY:continue
        for detail in entry['version_group_details']:
            if detail['version_group']['name']!='lets-go-pikachu-lets-go-eevee':continue
            if detail['move_learn_method']['name']=='level-up':learned[move]=min(learned.get(move,999),detail['level_learned_at'])
            if detail['move_learn_method']['name']=='machine':compatible.add(move)
    learnsets[dex]=learned;machines[dex]=compatible
    assert learned,dex
machine_rows=rows('machines');tm_names={int(r['move_id']):int(r['machine_number']) for r in machine_rows if r['version_group_id']=='19'}
move_ids=sorted(set().union(*(set(s) for s in learnsets.values()),*(s for s in machines.values())))
metadata=dict(zip(move_ids,parallel(lambda name:json.loads(raw('https://pokeapi.co/api/v2/move/'+name)),move_ids)))
stats={'attack':'attack','defense':'defense','special-attack':'specialAttack','special-defense':'specialDefense','speed':'speed','accuracy':'accuracy','evasion':'evasion'}
ailments={'poison':'poison','burn':'burn','paralysis':'paralysis','sleep':'sleep','freeze':'freeze','confusion':'confusion'}
# Reuse the already reviewed translation code; only a copy runs, never its legacy writes.
legacy=(ROOT/'tools/godot/import-letsgo.py').read_text(encoding='utf-8')
adapter=legacy[legacy.index('moves = {}'):legacy.index("for family in base['families']:")]
adapter=adapter.replace("    assert category!='status' or kind in ['guard','heal','status','push'] or changes, identity", "    if category=='status' and kind=='stages' and not changes:\n        definition.update(kind='guard',target='self',range=0,cost=2)\n        definition['description'] += ' Adaptación de apoyo: protección durante esta activación; no replica su efecto complejo original.'")
exec(compile(adapter,'reviewed-lgpe-adapter','exec'))
extra_moves={k:v for k,v in moves.items() if k not in base['moves']}
families={}
for dex in range(1,152):
    root=dex
    while details[root]['evolves_from_species'] and int(details[root]['evolves_from_species']['url'].rstrip('/').split('/')[-1])<=151:
        root=int(details[root]['evolves_from_species']['url'].rstrip('/').split('/')[-1])
    families.setdefault(root,[]).append(dex)
extra_families=[]
for root,ids in families.items():
    if root in old_ids:continue
    entries=[]
    for dex in ids:
        for move,level in sorted(learnsets[dex].items(),key=lambda e:(e[1],e[0])):
            definition=moves[move];entries.append(dict(id=move,level=level,role=1 if definition['category']=='status' or definition.get('secondary') else 0,forms=[dex]))
    extra_families.append(dict(id=pokemon[root]['name'],members=ids,roles=['Ofensivo','Apoyo y control'],learnset=entries))
items={r['id']:r['identifier'] for r in rows('items')};evolutions={};stones={}
for row in rows('pokemon_evolution'):
    if row.get('is_default')!='1' or row.get('region_id') or row.get('evolved_pokemon_form_id'):continue
    dex=int(row['evolved_species_id'])
    if dex>151:continue
    previous=details[dex]['evolves_from_species']
    if not previous:continue
    previous=int(previous['url'].rstrip('/').split('/')[-1])
    if row.get('required_pokemon_form_id') and int(row['required_pokemon_form_id'])!=previous:continue
    if previous>151 or previous in old_ids:continue
    if row.get('minimum_level',row.get('min_level')):evolutions[str(previous)]=[dex,int(row.get('minimum_level',row.get('min_level')))]
    elif row['evolution_trigger_id']=='2':stones.setdefault(str(previous),[]).append([dex,'link-cable'])
    elif row['trigger_item_id']:stones.setdefault(str(previous),[]).append([dex,items[row['trigger_item_id']]])
shop=copy.deepcopy(json.loads((DEST/'data/letsgo-shop.json').read_text(encoding='utf-8')))
for name,p in metadata.items():
    if p['id'] not in tm_names:continue
    shop['items']['tm-'+name]=dict(name=f"MT{tm_names[p['id']]:02d} · {moves[name]['name']}",kind='tm',move=name,price=80,species=[dex for dex in range(1,152) if name in machines[dex]],description='MT de Let’s Go, un uso. Cuatro movimientos preparados más básico. Alcance y PT tácticos.')
loc={r['id']:r['identifier'] for r in rows('locations')};areas={r['id']:loc[r['location_id']] for r in rows('location_areas')}
slots={r['id']:r['encounter_method_id'] for r in rows('encounter_slots')};methods={r['id']:r['identifier'] for r in rows('encounter_methods')}
encounters={}
for row in rows('encounters'):
    dex=int(row['pokemon_id'])
    if row['version_id'] not in ['31','32'] or dex>151 or details[dex]['is_legendary'] or details[dex]['is_mythical']:continue
    method=methods[slots[row['encounter_slot_id']]]
    if 'sky' in method or 'flying' in method or method in ['gift','gift-egg','only-one','pokeflute']:continue
    area=areas[row['location_area_id']];key=(dex,method)
    entry=encounters.setdefault(area,{}).setdefault(key,dict(speciesId=dex,minLevel=int(row['min_level']),maxLevel=int(row['max_level']),method=method,special='special' in method))
    entry['minLevel']=min(entry['minLevel'],int(row['min_level']));entry['maxLevel']=max(entry['maxLevel'],int(row['max_level']))
encounters={k:sorted(v.values(),key=lambda e:(e['speciesId'],e['method'])) for k,v in encounters.items()}
old_traits=json.loads((DEST/'data/traits.json').read_text(encoding='utf-8'));ability_ids={r['id']:r['identifier'] for r in rows('abilities')};ability_names={r['ability_id']:r['name'] for r in rows('ability_names') if r['local_language_id']=='7'}
abilities={};trait_species={str(i):[] for i in range(1,152)}
for row in rows('pokemon_abilities'):
    dex=int(row['pokemon_id'])
    if dex>151 or row['is_hidden']!='0':continue
    key=ability_ids[row['ability_id']];trait_species[str(dex)].append(dict(slot=int(row['slot']),id=key))
    if key not in old_traits['abilities']:abilities[key]=dict(name=ability_names[row['ability_id']],description='Habilidad normal. Consulta su adaptación táctica en la ficha.',implemented=False)
for entries in trait_species.values():entries.sort(key=lambda e:e['slot'])
names={}
for line in raw(LOCK['sprites']['raw']+'/credit_names.txt').decode('utf-8-sig').splitlines()[1:]:
    parts=line.split('\t')
    if len(parts)>=2:names[parts[1].strip()]=parts[0].strip() or parts[1].strip()
authors={}
for dex in sorted(set(range(1,152))-old_ids):
    credit='\n'.join((DEST/f'assets/expedition/{dex}/{file}').read_text(encoding='utf-8-sig') for file in ['credits.txt','portrait-credits.txt'])
    authors[str(dex)]=sorted({names.get(line.split('\t')[1],line.split('\t')[1]) for line in credit.splitlines() if '\t' in line})
dump('data/expedition.json',dict(species=extra_species,families=extra_families,moves=extra_moves,evolutions=evolutions,stoneEvolutions=stones,encounters=encounters,excludedPartnerMoves=DENY,encounterNote='LGPE Pikachu/Eevee union; ground/surf/special only, no sky or legendary captures. Normal species equal weights; special1%.'))
dump('data/expedition-shop.json',shop)
dump('data/expedition-traits.json',dict(species=trait_species,abilities=abilities,contact=[name for name,p in metadata.items() if any(f['name']=='contact' for f in p.get('flags',[]))]))
(DEST/'data/expedition-provenance.json').write_text(json.dumps(dict(spriteCommit=LOCK['sprites']['commit'],pokeapiCommit=LOCK['pokeapi']['commit'],authors=authors,files=sorted(files,key=lambda f:f['target']),sources=sorted({s['url']:s for s in sources}.values(),key=lambda s:s['url'])),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Imported',len(extra_species),'species,',len(extra_moves),'additional moves,',len(encounters),'encounter areas',flush=True)
