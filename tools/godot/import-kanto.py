"""Explicit sprint-14 native import; preserves web/laboratory files and golden fixtures."""
import sys, pathlib, json, hashlib, io, subprocess, re
ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from import_resources import fetch
from vendor.pokesurvivor_sprites import parse_animdata, resolve, ground_anchor
from PIL import Image
DEST=ROOT/'godot'
LOCK=json.loads((ROOT/'tools/sources.lock.json').read_text(encoding='utf-8'))
files=[]
def put(target, data, source, modification='None'):
    p=DEST/target; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(data)
    files.append(dict(target=target,source=source,sha256=hashlib.sha256(data).hexdigest(),modification=modification))
def dump(path,value):
    (DEST/path).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def move(id,name,type='normal',power=40,cost=0,range=1,kind='damage',target='enemy',accuracy=100,category='physical',secondary=None):
    d=dict(id=id,name=name,type=type,power=power,cost=cost,range=range,kind=kind,target=target,accuracy=accuracy,category=category,secondary=secondary,embers=False,description=name+' · adaptación táctica para Kanto.')
    return d
guard=move('protect','Protección',cost=1,range=0,kind='guard',target='self')
hard=move('harden','Fortaleza',cost=1,range=0,kind='guard',target='self')
kits=json.loads(subprocess.check_output(['node','--experimental-strip-types',str(ROOT/'tools/godot/kanto-kits.ts')],cwd=ROOT))
local={p['id']:p for p in json.loads((ROOT/'public/data/pokemon.json').read_text(encoding='utf-8'))}
lab={p['id']:p for p in json.loads((DEST/'data/laboratory.json').read_text(encoding='utf-8'))['species']}
records=[]
for dex in list(range(1,21))+[25,26,74,95]:
    if dex in lab:
        record=json.loads(json.dumps(lab[dex])); record['face']=f'assets/portraits/{dex}/Normal.png'
    else:
        base=f"{LOCK['sprites']['raw']}/sprite/{dex:04d}"
        if dex in local:
            record=json.loads(json.dumps(local[dex]))
            for name in ['Idle.png','Walk.png','thumbnail.png','AnimData.xml','credits.txt']:
                source=ROOT/f'public/assets/pokemon/{dex}/{name}'
                put(f'assets/kanto/{dex}/{name}',source.read_bytes(),str(source.relative_to(ROOT)).replace('\\','/'))
            for name in record['animations']: record['animations'][name]['path']=f'assets/kanto/{dex}/{name}.png'
        else:
            raw=fetch(f'https://pokeapi.co/api/v2/pokemon/{dex}')
            details=fetch(f'https://pokeapi.co/api/v2/pokemon-species/{dex}')
            p=json.loads(raw); d=json.loads(details)
            put(f'data/kanto-sources/{dex}.json',raw,f'https://pokeapi.co/api/v2/pokemon/{dex}')
            put(f'data/kanto-sources/{dex}-species.json',details,f'https://pokeapi.co/api/v2/pokemon-species/{dex}')
            xml=fetch(base+'/AnimData.xml'); anims,_=parse_animdata(xml.decode('utf-8-sig'))
            put(f'assets/kanto/{dex}/AnimData.xml',xml,base+'/AnimData.xml')
            credits=fetch(base+'/credits.txt');put(f'assets/kanto/{dex}/credits.txt',credits,base+'/credits.txt')
            animations={}
            for name in ['Idle','Walk']:
                source,geometry=resolve(anims,name); png=fetch(f'{base}/{source}-Anim.png'); shadow=fetch(f'{base}/{source}-Shadow.png')
                anchor=ground_anchor(shadow,geometry['w'],geometry['h']); image=Image.open(io.BytesIO(png))
                assert image.height//geometry['h']==8 and anchor is not None
                target=f'assets/kanto/{dex}/{name}.png';put(target,png,f'{base}/{source}-Anim.png')
                animations[name]=dict(width=geometry['w'],height=geometry['h'],columns=image.width//geometry['w'],rows=8,frames=geometry['n'],durations=geometry['d'],anchorX=anchor[0],anchorY=anchor[1],path=target)
                if name=='Idle':
                    output=io.BytesIO();image.crop((0,0,geometry['w'],geometry['h'])).save(output,format='PNG')
                    put(f'assets/kanto/{dex}/thumbnail.png',output.getvalue(),f'{base}/{source}-Anim.png','First down-facing frame cropped; no recoloring')
            record=dict(id=dex,name=next((n['name'] for n in d['names'] if n['language']['name']=='es'),p['name'].title()),types=[t['type']['name'] for t in p['types']],baseStats={s['stat']['name']:s['base_stat'] for s in p['stats']},legendary=d['is_legendary'],mythical=d['is_mythical'],animations=animations)
        face=f'assets/kanto/{dex}/Normal.png'
        for name in ['Normal.png','credits.txt']:put(f'assets/kanto/{dex}/'+('portrait-credits.txt' if name=='credits.txt' else name),fetch(f"{LOCK['sprites']['raw']}/portrait/{dex:04d}/{name}"),f"{LOCK['sprites']['raw']}/portrait/{dex:04d}/{name}")
        record['face']=face
    if str(dex) in kits:
        kit=kits[str(dex)]; record['movement']=kit['movement']; record['role']=kit['role']; actions=kit['actions']
    else:
        record['movement']=4 if dex not in [11,14,95] else 3
        record['role']='Perfil de ruta de Kanto'
        if dex in [10,11]:actions=[move('basic','Placaje'),hard if dex==11 else move('bug-bite','Picadura','bug',60,2),guard] if dex==10 else [move('basic','Placaje'),hard]
        elif dex in [13,14,15]:
            actions=[move('basic','Picotazo Veneno','poison',40,secondary=dict(kind='poison',chance=10,duration=3)),hard if dex==14 else move('bug-bite','Picadura','bug',60,2)]
            if dex==15:actions.append(move('rock-smash','Golpe Roca','fighting',40,2))
        elif dex in [16,17,18]:actions=[move('basic','Tornado','flying',40,range=2,category='special'),move('wing-attack','Ataque Ala','flying',60,1),move('whirlwind','Remolino','flying',40,2,2,'push',category='special')]
        elif dex in [19,20]:actions=[move('basic','Placaje'),move('bite','Mordisco','dark',60,1),move('hyper-fang','Hipercolmillo',power=80,cost=2,accuracy=90)]
        else:actions=[move('basic','Atadura'),move('rock-throw','Lanzarrocas','rock',50,1,2,'push',accuracy=90),hard]
    record['actions']={'classic':actions,'current':actions}
    assert not record['legendary'] and not record['mythical']
    records.append(record);print(f"{record['name']}: native profile, sprites and portrait",flush=True)
# Preserve exact Red slots and their 256-based probabilities as factual source data.
commit='af519899719f0754965776faac0e836a3b906e6d'
sources=[]
for name in ['Route1','Route2','ViridianForest']:
    url=f'https://raw.githubusercontent.com/pret/pokered/{commit}/data/wild/maps/{name}.asm';raw=fetch(url);text=raw.decode()
    text=re.sub(r'IF DEF\(_BLUE\).*?ENDC','',text,flags=re.S)
    slots=re.findall(r'db\s+(\d+),\s+([A-Z_]+)',text)
    names={'PIDGEY':16,'RATTATA':19,'WEEDLE':13,'KAKUNA':14,'METAPOD':11,'CATERPIE':10,'PIKACHU':25}
    sources.append(dict(id=name,url=url,sha256=hashlib.sha256(raw).hexdigest(),slots=[dict(level=int(level),speciesId=names[species]) for level,species in slots]))
dump('data/kanto-catalog.json',dict(version=1,species=records,slots=sources,slotWeights=[51,51,39,25,25,25,13,13,11,3],pokeredCommit=commit))
dump('data/kanto-provenance.json',dict(spriteCommit=LOCK['sprites']['commit'],files=files,sources=sources,authors='Individual sprite and portrait credits beside each imported asset; existing licenses retained.'))
