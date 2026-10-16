"""Explicit native progression import. Never rewrites laboratory/Kanto-v1 fixtures."""
import sys,pathlib,json,hashlib,copy,zipfile,io
ROOT=pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from import_resources import fetch
DEST=ROOT/'godot'
LOCK=json.loads((ROOT/'tools/sources.lock.json').read_text(encoding='utf-8'))
files=[];sources=[]
def put(path,data,source):
    target=DEST/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    files.append(dict(target=path,source=source,sha256=hashlib.sha256(data).hexdigest()))
def source(url):
    raw=fetch(url);sources.append(dict(url=url,sha256=hashlib.sha256(raw).hexdigest()));return json.loads(raw)
base=json.loads((DEST/'data/kanto-catalog.json').read_text(encoding='utf-8'))
local={p['id']:p for p in json.loads((ROOT/'public/data/pokemon.json').read_text(encoding='utf-8'))}
for dex in [75,76]:
    record=copy.deepcopy(local[dex]);folder=f'assets/progression/pokemon/{dex}'
    for name in ['Idle.png','Walk.png','thumbnail.png','AnimData.xml','credits.txt']:
        path=f'public/assets/pokemon/{dex}/{name}';put(folder+'/'+name,(ROOT/path).read_bytes(),path)
    for name in record['animations']:record['animations'][name]['path']=folder+'/'+name+'.png'
    for name in ['Normal.png','credits.txt']:
        url=f"{LOCK['sprites']['raw']}/portrait/{dex:04d}/{name}"
        put(folder+'/'+('portrait-credits.txt' if name=='credits.txt' else name),fetch(url),url)
    record['face']=folder+'/Normal.png';base['species'].append(record)
# Unlock levels are curated for this tactical campaign, not a claimed canonical learnset.
# Per-entry forms preserve stage identity; previously learned moves survive evolution.
families=[]
def family(identity,members,roles,learn):
    entries=[]
    for move,level,role,forms in learn:
        entries.append(dict(id=move,level=level,role=role,forms=forms or members))
    families.append(dict(id=identity,members=members,roles=roles,learnset=entries))
family('bulbasaur',[1,2,3],['Drenador','Controlador'],[
 ('vine-whip',1,0,None),('growl',3,1,None),('mega-drain',7,0,None),('poison-powder',9,1,None),('razor-leaf',12,0,None),('giga-drain',20,0,[2,3])])
family('charmander',[4,5,6],['Artillero','Escaramuzador'],[
 ('ember',1,0,None),('growl',3,1,None),('metal-claw',9,1,None),('flame-burst',15,0,None),('slash',20,1,[5,6]),('flamethrower',34,0,[5,6]),('wing-attack',36,1,[6])])
family('squirtle',[7,8,9],['Baluarte','Tirador'],[
 ('water-gun',1,1,None),('withdraw',3,0,None),('bite',8,0,None),('water-pulse',12,1,None),('protect',16,0,None),('surf',28,1,[8,9])])
family('caterpie',[10,11,12],['Controlador','Artillero'],[
 ('string-shot',1,0,[10]),('bug-bite',5,1,[10]),('harden',7,0,[11]),('confusion',10,1,[12]),('poison-powder',11,0,[12]),('stun-spore',12,0,[12]),('gust',13,1,[12]),('psybeam',18,1,[12])])
family('weedle',[13,14,15],['Asaltante','Hostigador'],[
 ('poison-sting',1,1,[13]),('string-shot',1,1,[13]),('harden',7,1,[14]),('twineedle',10,0,[15]),('pin-missile',12,1,[15]),('agility',16,0,[15]),('poison-jab',22,0,[15])])
family('pidgey',[16,17,18],['Escaramuzador','Apoyo'],[
 ('gust',1,0,None),('growl',3,1,None),('quick-attack',7,0,None),('wing-attack',12,0,None),('roost',18,1,None),('feather-dance',22,1,[17,18])])
family('rattata',[19,20],['Duelista','Debilitador'],[
 ('bite',1,0,None),('tail-whip',3,1,None),('quick-attack',7,0,None),('scary-face',12,1,[20]),('hyper-fang',16,0,None),('crunch',24,0,[20])])
family('pikachu',[25,26],['Artillero','Paralizador'],[
 ('thunder-shock',1,0,None),('growl',3,1,None),('thunder-wave',7,1,None),('spark',11,1,None),('agility',15,1,None),('nuzzle',18,1,None),('thunderbolt',24,0,None)])
family('geodude',[74,75,76],['Baluarte','Rompelineas'],[
 ('rock-throw',1,1,None),('defense-curl',3,0,None),('rock-tomb',9,1,None),('bulldoze',15,1,None),('protect',18,0,None),('earthquake',30,1,[75,76])])
family('onix',[95],['Muro','Controlador'],[
 ('bind',1,1,None),('harden',3,0,None),('rock-throw',7,1,None),('rock-tomb',10,1,None),('screech',14,0,None),('dragon-breath',18,1,None),('iron-tail',26,0,None)])
# Tactical geometry and resource costs; power/type/category remain the real move data.
specs={
 'vine-whip':(1,2),'growl':(1,2),'mega-drain':(2,2),'poison-powder':(2,2),'razor-leaf':(2,2),'giga-drain':(3,2),
 'ember':(1,3),'metal-claw':(1,1),'flame-burst':(3,2),'slash':(2,1),'flamethrower':(4,3),'wing-attack':(1,1),
 'water-gun':(1,3),'withdraw':(1,0),'bite':(1,1),'water-pulse':(2,3),'protect':(1,0),'surf':(4,2),
 'string-shot':(1,2),'bug-bite':(1,1),'harden':(1,0),'confusion':(1,3),'stun-spore':(2,2),'gust':(1,2),'psybeam':(2,3),
 'poison-sting':(1,2),'twineedle':(2,1),'pin-missile':(2,3),'agility':(1,0),'poison-jab':(2,1),
 'quick-attack':(1,1),'roost':(2,0),'feather-dance':(2,2),'tail-whip':(1,2),'scary-face':(2,2),'hyper-fang':(2,1),'crunch':(2,1),
 'thunder-shock':(1,3),'thunder-wave':(2,2),'spark':(2,1),'nuzzle':(2,1),'thunderbolt':(3,3),
 'rock-throw':(1,2),'defense-curl':(1,0),'rock-tomb':(2,2),'bulldoze':(3,2),'earthquake':(4,2),
 'bind':(1,2),'screech':(2,2),'dragon-breath':(2,2),'iron-tail':(3,1)}
changes={'growl':('attack',-1),'tail-whip':('defense',-1),'scary-face':('speed',-2),'string-shot':('speed',-1),'agility':('speed',1),'defense-curl':('defense',1),'harden':('defense',1),'feather-dance':('attack',-2),'screech':('defense',-2),'rock-tomb':('speed',-1),'bulldoze':('speed',-1)}
status={'poison-powder':('poison',100),'stun-spore':('paralysis',100),'thunder-wave':('paralysis',100)}
secondary={'poison-sting':('poison',30),'twineedle':('poison',20),'poison-jab':('poison',30),'ember':('burn',10),'flamethrower':('burn',10),'flame-burst':('burn',10),'spark':('paralysis',30),'nuzzle':('paralysis',100),'thunder-shock':('paralysis',10),'thunderbolt':('paralysis',10),'dragon-breath':('paralysis',30)}
moves={}
for identity,(cost,distance) in specs.items():
    p=source('https://pokeapi.co/api/v2/move/'+identity)
    name=next(n['name'] for n in p['names'] if n['language']['name']=='es')
    category=p['damage_class']['name'];kind='damage';target='enemy'
    if identity in status:kind='status'
    elif identity in changes and category=='status':kind='stages';target='self' if changes[identity][1]>0 else 'enemy'
    elif identity in ['mega-drain','giga-drain']:kind='drain'
    elif identity=='protect':kind='guard';target='self'
    elif identity=='withdraw':kind='stages';target='self'
    elif identity=='roost':kind='heal';target='self'
    elif identity in ['flame-burst','surf','bulldoze','earthquake']:kind='area-damage'
    power=p['power'] or 0
    if identity in ['twineedle','pin-missile']:power*=2 # explicit two-hit aggregate adaptation
    d=dict(id=identity,name=name,type=p['type']['name'],power=power,category=category,accuracy=p['accuracy'] or 100,cost=cost,range=distance,kind=kind,target=target,secondary=None,embers=identity=='flame-burst',description=name+' · adaptación táctica. PT y alcance propios del juego.')
    if identity in status:
        ailment,chance=status[identity];d['effect']=dict(kind=ailment,chance=chance,duration=3);d['powder']=identity.endswith('powder') or identity=='stun-spore'
    if identity in secondary:
        ailment,chance=secondary[identity];d['secondary']=dict(kind=ailment,chance=chance,duration=3)
    if identity in changes:d['statChange']=dict(stat=changes[identity][0],stages=changes[identity][1])
    if identity=='withdraw':d['statChange']=dict(stat='defense',stages=1)
    if identity=='roost':d['description']='Respiro: recupera un cuarto de los PS máximos. Adaptación táctica; conserva el tipo.'
    if identity=='quick-attack':d['description']='Ataque Rápido: golpe de corto alcance por 1 PT. No cambia la cola fija de iniciativa.'
    if identity in ['twineedle','pin-missile']:d['description']+=' Dos impactos agregados en una sola tirada.'
    if identity in changes:
        stat,stages=changes[identity];d['description']+=f' {stat}: {stages:+d} etapas; límite táctico de -2 a +2.'
    if kind=='drain':d['description']+=' Recupera la mitad del daño causado.'
    if kind=='area-damage':d['description']+=' Área en cruz: también alcanza a aliados.'
    if identity in status:d['description']+=' Estado durante tres activaciones del objetivo; respeta inmunidades.'
    moves[identity]=d
    print(name,flush=True)
# Pidgey has no Growl in the canonical repertoire: use Feather Dance as the support unlock.
families[5]['learnset']=[e for e in families[5]['learnset'] if e['id']!='growl']
# Full source move lists verify that every selected species/move combination exists somewhere in modern Kanto games.
for record in base['species']:
    p=source('https://pokeapi.co/api/v2/pokemon/'+str(record['id']))
    record['baseStats']={s['stat']['name']:s['base_stat'] for s in p['stats']}
    family_data=next(f for f in families if record['id'] in f['members'])
    allowed={m['move']['name'] for m in p['moves']}
    # Data-level adaptation of availability is labelled; do not silently claim exact cartridge learn levels.
    for entry in family_data['learnset']:
        if record['id'] in entry['forms'] and entry['id'] not in allowed:
            raise ValueError(f"{record['name']} cannot learn {entry['id']}")
base.update(version=2,families=families,moves=moves,levelCap=100,xpRewards=[220,350,500,650],enemyLevels=[[4],[6,5],[8,8,7],[12,14]],evolutions={'1':[2,16],'2':[3,32],'4':[5,16],'5':[6,36],'7':[8,16],'8':[9,36],'10':[11,7],'11':[12,10],'13':[14,7],'14':[15,10],'16':[17,18],'17':[18,36],'19':[20,20],'25':[26,20],'74':[75,25],'75':[76,36]})
# Kenney original PNGs, CC0; no edits to upstream bytes.
archive_url='https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip'
archive=fetch(archive_url);print('Kenney ZIP files:',flush=True)
z=zipfile.ZipFile(io.BytesIO(archive))
print(len(z.namelist()),'files; importing two original transparent PNGs',flush=True)
# Asset names chosen from the official pack after inspection.
for suffix,name in [('star_01.png','miss.png'),('circle_01.png','immune.png')]:
    candidates=[n for n in z.namelist() if n.endswith('/'+suffix) and '/PNG' not in n] or [n for n in z.namelist() if n.endswith('/'+suffix)]
    assert candidates,(suffix,z.namelist())
    put('assets/progression/'+name,z.read(candidates[0]),archive_url+'#'+candidates[0])
license_path=next(n for n in z.namelist() if n.lower().endswith('license.txt'))
put('licenses/Kenney-Particle-Pack-CC0.txt',z.read(license_path),archive_url+'#'+license_path)
put('data/progression.json',(json.dumps(base,ensure_ascii=False,indent=2)+'\n').encode(), 'Curated tactical rules; PokeAPI/SpriteCollab source hashes in progression-provenance.json')
manifest=dict(version=1,spriteCommit=LOCK['sprites']['commit'],kenneyArchiveSha256=hashlib.sha256(archive).hexdigest(),files=files,sources=sources)
(DEST/'data/progression-provenance.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
