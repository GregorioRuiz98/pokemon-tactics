"""Build append-only chapter snapshots from the reviewed story graph and Red teams."""
import argparse,hashlib,json,pathlib,re,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
from import_resources import fetch
COMMIT='af519899719f0754965776faac0e836a3b906e6d'
URL=f'https://raw.githubusercontent.com/pret/pokered/{COMMIT}/data/trainers/parties.asm'
text=fetch(URL).decode();parties={};current=''
for line in text.splitlines():
    if re.match(r'^\w+Data:',line):current=line.split('Data:')[0];parties[current]=[]
    if line.strip().startswith('db ') and current:
        values=[v.strip() for v in line.strip()[3:].split(',')]
        if values[0]=='$FF':team=[(int(values[i]),values[i+1]) for i in range(1,len(values)-1,2)]
        else:team=[(int(values[0]),v) for v in values[1:-1]]
        parties[current].append(team)
species=json.loads((ROOT/'godot/data/letsgo.json').read_text(encoding='utf-8'))['species']+json.loads((ROOT/'godot/data/expedition.json').read_text(encoding='utf-8'))['species']
# Pokédex IDs/names are factual; English constants follow the pinned trainer source.
ids={}
for i in range(1,152):
    url=f'https://pokeapi.co/api/v2/pokemon/{i}';p=json.loads(fetch(url));ids[p['name'].upper().replace('-','_')]=i
def team(name,index=0):return [dict(speciesId=ids[name],level=level) for level,name in parties[name][index]]
def rivals(name,start):return [team(name,start+i) for i in range(3)]
nodes=[]
def add(identity,name,requires,table,biome='route',chapter=17,**kw):
    node=dict(id=identity,name=name,requires=requires.split() if requires else [],captureTable=table,captureOrigin=name,biome=biome,chapter=chapter,count=kw.pop('count',4),story=kw.pop('story','Encuentro único de la zona. Las capturas y niveles siguen la tabla combinada de Let’s Go; la geometría y las probabilidades son tácticas.'))
    node.update(kw);nodes.append(node);return node
legacy=json.loads((ROOT/'godot/data/kanto-route.json').read_text(encoding='utf-8'))
for index,old in enumerate(legacy):
    node=add(old['id'],old['name'],'' if index==0 else legacy[index-1]['id'],old['captureTable'],old['id'],count=len(old['enemies']),story=old['story'])
    if old['id']=='brock':node.update(leader=True,team=team('Brock'),medal='Medalla Roca',grants=['badge-rock'])
add('route-3','Ruta 3','brock','kanto-route-3',story='Dejas Plateada y sus entrenadores de montaña. Las laderas de Ruta 3 conducen a Monte Moon.')
add('mt-moon','Monte Moon','route-3','mt-moon','cave',story='Entre Clefairy, Paras y Zubat descubres a unos Rocket disputándose fósiles. La salida lleva a Ruta 4.',count=5,grants=['moon-crossed'])
add('route-4','Ruta 4 · llegada a Celeste','mt-moon','kanto-route-4')
add('cerulean-rival','Celeste · reencuentro con el rival','route-4','kanto-route-4',rivalTeams=rivals('Rival1',6),story='El rival presume de sus capturas y te reta antes del Puente Pepita. Su inicial contrarresta al que elegiste con Oak.')
add('route-24','Ruta 24 · Puente Pepita','cerulean-rival','kanto-route-24',grants=['nugget-bridge'])
add('route-25','Ruta 25 · la casa de Bill','route-24','kanto-route-25',grants=['ss-ticket'],story='Tras recorrer la ruta ayudas a Bill a recuperar su aspecto humano. Te entrega el billete del S. S. Anne; la visita se resume después del combate.')
add('misty','Ciudad Celeste · Misty','route-4','kanto-route-4','water',leader=True,team=team('Misty'),medal='Medalla Cascada',grants=['badge-cascade'],story='Misty defiende su gimnasio acuático con Staryu y Starmie. Ganar concede medalla y su Pokémon insignia.')
add('route-5','Ruta 5 · camino subterráneo','misty','kanto-route-5')
add('route-6','Ruta 6 · llegada a Carmín','route-5','kanto-route-6')
add('ss-anne','S. S. Anne · rival y capitán','route-6 ss-ticket','kanto-route-6','ship',rivalTeams=rivals('Rival2',0),grants=['cut'],story='El billete de Bill permite embarcar. Tras vencer al rival ayudas al capitán y obtienes Corte. No hace falta ocupar un movimiento de combate con una MO.')
add('surge','Ciudad Carmín · Lt. Surge','ss-anne cut','kanto-route-6','rocket',leader=True,team=team('LtSurge'),medal='Medalla Trueno',grants=['badge-thunder','bike'],story='El gimnasio eléctrico de Carmín culmina el tramo. El recorrido por la ciudad resume también el bono del Club de Fans y la bicicleta, que abre futuros desvíos.')
add('route-11','Ruta 11 · desvío de Carmín','route-6','kanto-route-11',optional=True)
add('diglett-cave','Cueva Diglett','route-11','digletts-cave','cave',optional=True,count=3)
add('route-22','Ruta 22 · desvío de Ciudad Verde','route-1','kanto-route-22',optional=True,count=3)

def build(chapter):
    result=[]
    for source in nodes:
        if source['chapter']>chapter:continue
        node=dict(source)
        enemies=node.get('team') or (node['rivalTeams'][0] if 'rivalTeams' in node else [])
        average=sum(m['level'] for m in enemies)/len(enemies) if enemies else min(50,5+len(result))
        node['xp']=[220,350,500,650][len(result)] if len(result)<4 else int(220+average*28);node['money']=150 if len(result)<4 else int(150+average*12)
        node['board']=[[0]*12 for _ in range(10)]
        node['enemies']=[m['speciesId'] for m in enemies] if enemies else [19]*node['count']
        result.append(node)
    output=ROOT/f'godot/data/journey-{chapter}.json';output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    manifest=ROOT/f'godot/data/journey-{chapter}-provenance.json';manifest.write_text(json.dumps({'pokeredCommit':COMMIT,'trainerSource':{'url':URL,'sha256':hashlib.sha256(text.encode()).hexdigest()},'files':[{'target':f'data/journey-{chapter}.json','sha256':hashlib.sha256(output.read_bytes()).hexdigest()}]},indent=2)+'\n',encoding='utf-8')
    print('Built chapter',chapter,len(result),'locations')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--chapter',type=int,default=17);build(parser.parse_args().chapter)
