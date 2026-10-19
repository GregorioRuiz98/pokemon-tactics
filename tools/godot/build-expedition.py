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

add('route-9','Ruta 9 · hacia Túnel Roca','surge cut','kanto-route-9',chapter=18,count=5)
add('route-10','Ruta 10 · sendero de la central','route-9','kanto-route-10',chapter=18,count=5)
add('rock-tunnel','Túnel Roca · paso a Lavanda','route-10','rock-tunnel','cave',chapter=18,count=5,grants=['lavender-reached'],story='Cruzas los desniveles de Túnel Roca y llegas a Pueblo Lavanda. La oscuridad y el recorrido se resumen; no se exige ocupar un movimiento con Destello.')
add('route-8','Ruta 8 · salida de Lavanda','rock-tunnel','kanto-route-8',chapter=18)
add('route-7','Ruta 7 · llegada a Azulona','route-8','kanto-route-7',chapter=18)
add('erika','Ciudad Azulona · Erika','route-7','kanto-route-7','grass',chapter=18,leader=True,team=team('Erika'),medal='Medalla Arcoíris',grants=['badge-rainbow','fresh-water'],story='Erika dirige su jardín de Pokémon Planta. La visita al centro comercial y el Agua Fresca para los guardias quedan resumidos al completar el gimnasio.')
add('rocket-hideout','Guarida Rocket · Giovanni','route-7','kanto-route-7','rocket',chapter=18,team=team('Giovanni',0),grants=['silph-scope'],story='Sigues al Rocket del Casino y te enfrentas a Giovanni. Al vencer recuperas el Scope Silph. La recompensa salvaje procede de Ruta 7, acceso a Azulona; no se capturan sus Pokémon de entrenador.')
add('tower-rival','Torre Pokémon · rival','lavender-reached','pokemon-tower','ghost',chapter=18,rivalTeams=rivals('Rival2',3),story='Tu rival te espera en la Torre Pokémon. La tabla de captura corresponde a las plantas salvajes de la torre, no a su equipo.')
add('pokemon-tower','Torre Pokémon · el espíritu de Marowak','tower-rival silph-scope','pokemon-tower','ghost',chapter=18,count=5,grants=['marowak-rest'],story='El Scope identifica los espíritus. En este encuentro de la torre, la historia de Marowak se resume al vencer a los habitantes del tablero; no se concede una captura legendaria ni un segundo premio al revisitar.')
add('fuji-rescue','Torre Pokémon · rescate de Fuji','pokemon-tower','pokemon-tower','ghost',chapter=18,team=[dict(speciesId=41,level=25),dict(speciesId=42,level=25),dict(speciesId=109,level=26),dict(speciesId=96,level=26)],grants=['poke-flute'],story='Expulsas al último grupo Rocket y rescatas al Sr. Fuji. Te entrega la Poké Flauta, que permitirá abrir los caminos hacia Fucsia. Composición táctica de dos grupos Rocket de la torre; recompensa salvaje local.')

# Both roads to Fuchsia remain available; they are alternatives, not mandatory detours.
add('route-12','Ruta 12 · el puente de Snorlax','poke-flute','kanto-route-12','water',chapter=19,optional=True,story='La Poké Flauta despeja el puente. El combate usa habitantes de la ruta; Snorlax no se añade como captura garantizada.')
for number in [13,14,15]: add(f'route-{number}',f'Ruta {number} · camino de Fucsia',f'route-{number-1}',f'kanto-route-{number}',chapter=19,optional=True,count=5)
add('route-16','Ruta 16 · carril bici','poke-flute bike','kanto-route-16',chapter=19,optional=True)
for number in [17,18]: add(f'route-{number}',f'Ruta {number} · carril bici',f'route-{number-1}',f'kanto-route-{number}',chapter=19,optional=True,count=5)
add('safari','Fucsia · visita a Safari','poke-flute','kanto-route-15','grass',chapter=19,kind='story',requiresAny=['route-15','route-18'],grants=['surf','strength'],story='Recuperas los dientes del guarda y llegas a la casa secreta: consigues Fuerza y Surf. Visita narrativa sin combate, captura ni curación. Let’s Go no tiene tabla Safari; no se inventa una para este evento.')
add('koga','Ciudad Fucsia · Koga','safari','kanto-route-15','ghost',chapter=19,leader=True,team=team('Koga'),medal='Medalla Alma',grants=['badge-soul'],story='Koga defiende su gimnasio de veneno. Su Weezing43 es la recompensa insignia; Surf ya permite explorar el mar, sin ocupar movimientos.')
add('silph-rival','Silph S. A. · rival','fresh-water poke-flute','kanto-route-7','rocket',chapter=19,rivalTeams=rivals('Rival2',6),story='El Agua Fresca abre Azafrán. Te infiltras en Silph y tu rival te reta de nuevo. Captura de Ruta 7, acceso de la ciudad; no hay tabla salvaje en el edificio.')
add('silph-giovanni','Silph S. A. · Giovanni','silph-rival','kanto-route-7','rocket',chapter=19,team=team('Giovanni',1),grants=['silph-liberated'],story='Derrotas a Giovanni y liberas Silph. Se resume la tarjeta y los teletransportadores. La captura usa la zona de acceso Ruta 7.')
add('sabrina','Ciudad Azafrán · Sabrina','silph-liberated','kanto-route-7','psychic',chapter=19,leader=True,team=team('Sabrina'),medal='Medalla Pantano',grants=['badge-marsh'])
add('route-19','Ruta 19 · salida al mar','badge-soul surf','kanto-sea-route-19','water',chapter=19,optional=True,count=5)
add('route-20','Ruta 20 · travesía a Islas Espuma','route-19','kanto-sea-route-20','water',chapter=19,optional=True,count=5)
add('seafoam','Islas Espuma · paso a Canela','route-20 strength','seafoam-islands','ice',chapter=19,optional=True,count=5,story='Surf y Fuerza permiten atravesar las islas. Articuno se reserva para el desafío legendario; las capturas son salvajes no legendarios de Let’s Go.')
add('route-21','Ruta 21 · desde Paleta','badge-soul surf','kanto-sea-route-21','water',chapter=19,optional=True,count=5)
add('pokemon-mansion','Mansión Pokémon · llave secreta','sabrina','pokemon-mansion','fire',chapter=19,requiresAny=['seafoam','route-21'],count=5,grants=['secret-key'],story='Llegas a Canela por mar y exploras la mansión. Sus diarios evocan la investigación de Mew; encuentras la llave del gimnasio. No hay captura legendaria.')
add('blaine','Isla Canela · Blaine','secret-key','pokemon-mansion','fire',chapter=19,leader=True,team=team('Blaine'),medal='Medalla Volcán',grants=['badge-volcano'])
add('giovanni-gym','Ciudad Verde · Giovanni','badge-rock badge-cascade badge-thunder badge-rainbow badge-soul badge-marsh badge-volcano','kanto-route-22','ground',chapter=19,leader=True,team=team('Giovanni',2),medal='Medalla Tierra',grants=['badge-earth'],story='Con siete medallas regresas a Ciudad Verde. Giovanni revela su identidad como líder; Rhydon50 es su insignia. La Medalla Tierra abre la Liga.')
add('power-plant','Central de Energía · desvío','route-10 surf','kanto-power-plant','rocket',chapter=19,optional=True,count=5,story='Exploras las instalaciones junto a Ruta 10. Zapdos se reserva para el desafío legendario; aquí combates y capturas habitantes no legendarios.')

badges='badge-rock badge-cascade badge-thunder badge-rainbow badge-soul badge-marsh badge-volcano badge-earth'
add('league-rival','Ruta 22 · último reto del rival',badges,'kanto-route-22',chapter=20,rivalTeams=rivals('Rival2',9),story='Con ocho medallas, tu rival mide tus fuerzas antes de la Liga. Es un acontecimiento distinto del encuentro salvaje único de Ruta 22; no reinicia aquella captura.')
add('route-23','Ruta 23 · controles de medallas','league-rival','kanto-route-23','ground',chapter=20,count=5)
add('victory-road','Calle Victoria','route-23 strength surf','kanto-victory-road-1','cave',chapter=20,count=6,grants=['league-access'])
for identity,label,party,requires,biome in [('lorelei','Lorelei','Lorelei','league-access','ice'),('bruno','Bruno','Bruno','lorelei','ground'),('agatha','Agatha','Agatha','bruno','ghost'),('lance','Lance','Lance','agatha','dragon')]:
    add(identity,'Alto Mando · '+label,requires,'kanto-victory-road-1',biome,chapter=20,team=team(party),story='Combate del Alto Mando con su equipo de Rojo. Después hay captura de la zona de acceso Calle Victoria y tienda. No se restauran PS gratuitamente, y una derrota termina la campaña.')
add('champion','Liga Pokémon · rival campeón','lance','kanto-victory-road-1','dragon',chapter=20,rivalTeams=rivals('Rival3',0),grants=['champion'],story='Tu rival ya es campeón. Vence a su equipo de seis para entrar en el Hall de la Fama. Después de la captura de Calle Victoria y la tienda se cierra la historia principal; los legendarios esperan al siguiente desafío.')

add('legendary-birds','Santuario de los tres cielos','champion','kanto-victory-road-1','legends-birds',chapter=21,optional=True,finale=True,path='birds',team=[dict(speciesId=i,level=70) for i in [144,145,146]],story='Tras la Liga eliges un santuario donde convergen hielo, tormenta y fuego. Articuno, Zapdos y Moltres combaten juntos. Desafío táctico alternativo original: los tres no se reúnen así en Rojo. No hay captura legendaria.')
add('legendary-origin','Cueva Celeste · el origen','champion','cerulean-cave','legends-psychic',chapter=21,optional=True,finale=True,path='psychic',team=[dict(speciesId=i,level=75) for i in [151,150]],story='La aventura culmina en una cueva de agua y cristales. Mew y Mewtwo combaten juntos en este final alternativo, inspirado en los diarios de la Mansión. Mew no era un encuentro normal de Rojo. No hay captura legendaria.')

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
