"""Offline authoring of edition22. No encounter/economy/learnset changes.

Coordinates are explicit in the 16-cell design space. 24-cell maps extend the
same landmarks, adding connected outer approaches. Never run at game startup.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT/'godot/data'

# id | material | title | recognizable landmark | blocks x,y,prop | height rectangles
# Props: oak, pine, bush, log, rock, pillar, fence, railing, desk, server,
# bin, statue, tomb, cottage, turbine, crystal. Solid props share solid LOS rules.
SPECS = '''route-1|meadow|Camino de Paleta|Camino de tierra entre Paleta y Ciudad Verde; lomas suaves y hierba lateral.|2,3,bush;12,10,fence;3,12,fence|9,9,12,11,1
route-2|forest|Linde del Bosque Verde|El camino se estrecha al entrar en el bosque, con un desvío junto al talud.|3,3,oak;4,3,oak;7,4,oak;12,9,oak;11,10,log|9,10,12,12,1
forest|forest|Claros del Bosque Verde|Troncos sólidos, dos claros conectados, maleza y una terraza al este.|3,3,oak;4,4,oak;7,3,oak;7,4,oak;8,10,oak;9,10,oak;12,8,oak;12,9,oak;6,12,log;3,6,oak|9,8,11,9,1;10,9,11,9,2
brock|stone|Gimnasio de Plateada|Estatuas de entrada, grupos de roca y plataforma del líder entre pasos laterales.|2,6,statue;12,6,statue;7,3,rock;7,4,rock;7,7,rock;7,10,rock;10,10,rock|8,2,12,4,1;9,2,11,3,2
route-3|rock|Terrazas de la Ruta 3|Sendero al pie de las montañas, salientes y acceso oriental a Monte Moon.|3,4,rock;6,3,rock;10,9,rock;11,10,rock;12,11,rock|7,2,12,4,1;9,2,12,3,2
mt-moon|cave|Cámaras de Monte Moon|Galerías de roca, cámara de fósiles y pasos alrededor de grandes columnas.|6,3,rock;6,4,rock;7,7,pillar;8,10,rock;9,10,rock;12,8,crystal;3,5,rock|9,9,12,12,1;10,10,12,11,2
route-4|rock|Salida de Monte Moon|La boca de la cueva queda arriba; el camino desciende hacia Celeste.|3,3,rock;4,3,rock;6,4,rock;11,11,bush|2,2,7,4,1;2,2,5,3,2
cerulean-rival|city|Plaza de Ciudad Celeste|Plaza de piedra, canal lateral y jardines ante el Puente Pepita.|3,4,bush;12,8,pillar;12,10,bush;6,11,fence|9,2,12,3,1
route-24|bridge|Puente Pepita|Puente ancho sobre el canal y una orilla de tierra conectada por ambos extremos.|6,3,railing;6,4,railing;9,8,railing;9,9,railing|6,2,9,12,1
route-25|meadow|Camino de Bill|Laberinto suave de setos, costa y la casa de Bill al fondo.|3,3,bush;4,4,bush;7,4,bush;10,8,bush;12,2,cottage|10,10,12,12,1
misty|water|Gimnasio de Ciudad Celeste|Dos piscinas separadas por pasarelas, acceso terrestre continuo y plataforma de Misty.|2,4,statue;12,11,statue|7,2,8,12,1
route-5|meadow|Cuesta de la guardería|Camino descendente, cercado de la guardería y entrada al paso subterráneo.|2,3,cottage;6,4,fence;7,4,fence;12,10,bush|2,2,6,5,1
route-6|meadow|Estanque de la Ruta 6|Salida del túnel, estanque lateral y aproximación abierta a Ciudad Carmín.|3,3,pillar;6,11,bush;12,8,fence|9,10,12,12,1
ss-anne|wood|Cubierta del S. S. Anne|Cubierta de madera con camarotes, barandillas y escaleras a la toldilla.|2,3,railing;3,3,railing;7,4,desk;11,10,railing;12,10,railing|9,2,13,4,1;11,2,13,3,2
surge|industrial|Gimnasio de Ciudad Carmín|Hileras de papeleras, máquinas eléctricas y pasos abiertos entre ellas.|6,3,bin;6,4,bin;8,7,bin;8,8,bin;10,9,bin;12,2,turbine|10,2,12,3,1
route-11|meadow|Pradera de Carmín|Pradera ancha, árboles dispersos y entrada a la Cueva Diglett.|2,3,rock;6,4,bush;11,9,oak;12,11,fence|2,11,6,13,1
diglett-cave|cave|Túnel de Diglett|Un corredor de tierra comunica dos bocas; la cámara central permite rodear al rival.|5,3,rock;6,3,rock;7,4,rock;10,10,rock;11,10,rock;12,9,rock|9,11,12,12,1
route-22|meadow|Camino hacia la Liga|Pradera con estanque y puerta de la Liga; el mismo terreno se revisita ante el rival.|3,3,oak;7,4,bush;11,10,fence;12,10,fence|9,2,12,3,1
route-9|rock|Recodos de la Ruta 9|Zigzag de roca entre terrazas y pasos laterales a distinta altura.|6,3,rock;6,4,rock;7,7,rock;8,10,rock;12,8,rock|8,2,12,4,1;10,2,12,3,2;9,10,12,12,1
route-10|meadow|Ribera del Túnel Roca|Río lateral, postes del tendido eléctrico y entrada de cueva en la ladera.|3,3,pillar;6,4,pillar;12,9,rock|10,2,13,4,1
rock-tunnel|cave|Galerías del Túnel Roca|Cavernas profundas con pilares y rampas visibles; la oscuridad no cambia precisión.|3,4,rock;6,3,pillar;7,7,rock;9,9,pillar;12,8,rock;12,11,crystal|8,2,12,4,1;9,2,12,3,2;2,11,6,12,1
route-8|meadow|Setos de Lavanda|Hierba cercada, paso subterráneo y senda hacia Azulona.|3,3,fence;4,3,fence;7,4,bush;12,9,fence;12,10,fence|10,10,12,12,1
route-7|city|Entrada a Azulona|Tramo urbano corto con parterres y acceso al paso subterráneo.|3,4,pillar;6,3,bush;11,10,fence|2,11,6,12,1
erika|forest|Jardín de Erika|Senderos entre parterres y grandes árboles del gimnasio de Azulona.|3,3,oak;6,4,bush;8,4,oak;6,10,log;11,8,oak|9,10,12,12,1
rocket-hideout|industrial|Almacén Rocket|Cajas, servidores y dos terminales operativos; acaba una activación sobre cada terminal.|3,4,server;6,3,desk;8,10,server;11,10,desk|10,2,12,3,1
tower-rival|haunted|Vestíbulo de la Torre Pokémon|Primer piso amplio, lápidas a los lados y encuentro con el rival ante la escalera.|3,3,tomb;6,4,tomb;11,10,tomb;12,8,pillar|9,2,12,3,1
pokemon-tower|haunted|Cámara de Marowak|Anillo de lápidas en torno a una plataforma ceremonial conectada por dos accesos.|3,4,tomb;6,3,tomb;8,10,tomb;11,8,tomb;12,11,tomb|7,6,9,8,1;8,7,8,7,2
fuji-rescue|haunted|Último piso de la Torre|Fuji espera en un claro de lápidas; conserva sus cuatro puntos de protección hasta la ronda 4.|3,4,tomb;7,3,pillar;10,10,tomb;12,8,tomb|10,2,12,3,1
route-12|bridge|Pasarela de los pescadores|Pasarelas de madera junto al agua y una orilla seca para rodear el encuentro.|6,3,railing;6,4,railing;9,9,railing;9,10,railing|6,2,9,12,1
route-13|meadow|Cercados de la costa|Vallas y setos dibujan pasos conectados; la zona central conserva espacio para desplegarse.|6,3,fence;6,4,fence;7,7,fence;10,9,fence;10,10,fence;12,8,bush|2,11,6,12,1
route-14|meadow|Corredor de hierba alta|Pradera longitudinal con arboleda oriental y una senda despejada.|12,3,oak;12,4,oak;12,8,oak;12,9,oak;6,11,bush|2,2,5,4,1
route-15|meadow|Terrazas de Fucsia|Dos caminos paralelos, superior e inferior, unidos por pendientes transitables.|7,3,fence;7,4,fence;7,10,bush;12,11,fence|8,2,12,4,1;9,2,12,3,2
route-16|city|Entrada al Camino de Bicis|Límite urbano, caseta del acceso y carretera que comienza a descender.|2,3,cottage;6,4,fence;12,9,fence|2,2,6,4,1
route-17|road|Camino de Bicis|Carretera ancha en terrazas descendentes con arcenes; no hay deslizamiento automático.|3,3,fence;3,4,fence;12,9,fence;12,10,fence|2,2,13,4,1;2,2,13,3,2;2,5,13,6,1
route-18|meadow|Salida del Camino de Bicis|Carretera llana, pequeños parterres y acceso occidental a Ciudad Fucsia.|3,3,fence;6,4,bush;12,8,oak|9,10,12,12,1
safari|forest|Entrada de la Zona Safari|Visita narrativa: entrada, estanque y arboleda. No añade otro combate ni captura.|3,3,cottage;6,4,oak;12,8,oak;11,11,bush|9,10,12,12,1
koga|wood|Dojo de Koga|Paneles del dojo visibles, pasillos de rodeo y las zonas de humo y veneno ya conocidas.|6,3,pillar;6,4,pillar;10,8,pillar;10,9,pillar;12,2,statue|9,10,12,12,1
silph-rival|industrial|Pasillos de Silph|Oficinas con escritorios, servidores y un corredor ancho ante el rival.|3,3,desk;6,4,desk;8,10,server;11,10,desk|10,2,12,3,1
silph-giovanni|industrial|Sala de juntas de Silph|Despacho de la presidencia, alfombra central y plataforma de Giovanni.|3,4,desk;6,3,server;10,10,desk;12,8,server|8,2,12,4,1
sabrina|psychic|Cámaras de Sabrina|Salas conectadas por transportadores emparejados; la salida ocupada impide el transporte.|7,3,pillar;7,4,pillar;7,5,pillar;7,9,pillar;7,10,pillar;7,11,pillar|10,9,12,11,1
route-19|sand|Playa de Fucsia|Franja de arena, agua a ambos lados y rocas que separan calas conectadas.|3,3,rock;6,4,rock;11,10,rock|9,10,12,12,1
route-20|water|Islotes del sur|Islas rocosas y pasos de piedra mantienen una ruta terrestre continua entre orillas.|3,4,rock;7,4,rock;10,9,rock;12,11,rock|9,9,12,12,1;10,10,11,11,2
seafoam|ice|Cámaras de las Islas Espuma|Cueva de hielo con agua, cristales y terrazas transitables; el hielo no desliza.|3,3,crystal;6,4,rock;8,10,crystal;12,8,rock|8,2,12,4,1;9,2,12,3,2
route-21|sand|Costa de Pueblo Paleta|Costa cálida con arena, pequeñas islas y vista hacia Paleta.|3,4,bush;6,3,rock;12,10,rock|9,10,12,12,1
pokemon-mansion|ruin|Mansión Pokémon|Laboratorio abandonado, estatuas, escritorios y restos de una galería superior.|3,3,statue;6,4,desk;8,10,server;12,8,pillar;12,11,statue|9,10,12,12,1;11,11,12,12,2
blaine|industrial|Laboratorio de Blaine|Salas tecnológicas del gimnasio, monitores y fuego residual claramente señalado.|3,3,desk;6,4,server;8,10,desk;12,8,turbine|9,2,12,4,1
giovanni-gym|stone|Gimnasio de Ciudad Verde|Suelo geométrico, estatuas y plataformas de roca; las trampas conservan su señalización.|3,3,statue;6,3,rock;6,4,rock;9,9,rock;9,10,rock|7,5,9,6,1;8,5,8,5,2
power-plant|industrial|Central de Energía|Turbinas averiadas y pasillos técnicos. Zapdos espera junto a las otras aves al final.|3,3,turbine;6,4,server;8,10,turbine;12,8,server;12,11,desk|9,10,12,12,1
league-rival|meadow|Regreso a la Ruta 22|La misma pradera y puerta de la Liga, ahora con el equipo final del rival.|3,3,oak;7,4,bush;11,10,fence;12,10,fence|9,2,12,3,1
route-23|stone|Puertas de las ocho medallas|Puertas de piedra escalonadas y ascenso a la Calle Victoria.|3,3,pillar;6,4,pillar;12,8,pillar;12,11,pillar|8,2,12,4,1;10,2,12,3,2
victory-road|cave|Ascenso de Calle Victoria|Cámaras y terrazas con varios accesos; todas las casillas de salida están conectadas.|3,4,rock;6,3,rock;7,7,pillar;9,10,rock;12,8,rock|8,2,13,5,1;10,2,13,3,2;2,11,6,12,1
lorelei|ice|Cámara de Lorelei|Piscinas laterales, columnas heladas y plataforma formal del Alto Mando.|3,3,crystal;6,4,pillar;12,8,crystal;11,10,pillar|8,2,12,4,1
bruno|stone|Dojo de Bruno|Sala de entrenamiento de piedra, grandes rocas y ascenso central al Alto Mando.|3,4,rock;6,3,rock;8,10,rock;12,8,pillar|8,2,12,4,1;9,2,11,3,2
agatha|haunted|Cámara de Agatha|Lápidas monumentales alrededor de un espacio abierto de combate.|3,3,tomb;6,4,tomb;8,10,tomb;12,8,tomb;12,11,pillar|9,2,12,4,1
lance|league|Cámara de Lance|Entrada curva entre pilares y una arena amplia con plataforma del maestro dragón.|3,3,pillar;6,3,pillar;6,4,statue;12,8,pillar;12,11,statue|8,2,12,4,1;9,2,11,3,2
champion|league|Sala del Campeón|Sala ceremonial simétrica, emblema central y columnas fuera de las líneas principales.|3,3,pillar;12,3,pillar;3,12,statue;12,12,statue|8,2,12,4,1;9,2,11,3,2
legendary-birds|birds|Santuario de las tres aves|Tres sectores de hielo, electricidad y fuego unidos por rampas y un claro central. Primera prueba legendaria.|3,3,crystal;6,4,turbine;12,8,rock;8,10,pillar|2,2,5,4,1;9,2,12,4,1;9,10,12,12,1;10,2,12,3,2
legendary-origin|origin|Caverna del origen|Anillo de agua, cristales y pasos de roca; Mew y Mewtwo aguardan después de las tres aves.|3,3,crystal;6,4,crystal;8,10,crystal;12,8,pillar;12,11,crystal|8,2,12,4,1;9,2,11,3,2
'''

# Larger masses define chambers and silhouettes, rather than scattering the same
# few props on a recolored floor. The deployment/contact corridor is reserved.
MASSES = {
    'forest':[(2,2,4,3),(11,10,13,12),(2,11,3,12)],
    'mt-moon':[(2,2,5,4),(10,10,13,13),(11,7,13,8)],
    'diglett-cave':[(2,2,5,5),(11,9,13,13),(6,11,8,13)],
    'rock-tunnel':[(2,2,5,4),(8,9,10,11),(11,7,13,8)],
    'seafoam':[(2,2,4,4),(11,10,13,13),(6,11,8,12)],
    'victory-road':[(2,2,5,4),(7,10,9,13),(11,7,13,8)],
    'pokemon-mansion':[(2,2,4,5),(11,9,13,12),(7,3,8,3)],
    'rocket-hideout':[(2,2,4,4),(11,10,13,12)],
    'silph-rival':[(2,2,5,4),(10,10,13,12)],
    'silph-giovanni':[(2,2,4,4),(11,10,13,12)],
    'route-9':[(2,2,5,3),(7,10,10,11),(12,7,13,8)],
    'route-3':[(2,2,4,3),(11,10,13,12)],
    'route-23':[(2,2,4,4),(11,10,13,12)],
    'brock':[(2,2,4,3),(11,10,13,12)],
    'bruno':[(2,2,4,3),(10,10,12,12)],
}

def dump(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':'))+'\n', encoding='utf-8')

def build():
    journey = json.loads((DATA/'journey-24.json').read_text(encoding='utf-8-sig'))
    arenas = json.loads((DATA/'adventure.json').read_text(encoding='utf-8-sig'))['arenas']
    for loc in journey:
        if loc['id'] in ['legendary-birds', 'legendary-origin']:
            loc.pop('path', None)
            loc['optional'] = False
            loc['requires'] = ['champion' if loc['id']=='legendary-birds' else 'legendary-birds']
            loc['story'] = ('Tras vencer a la Liga y al rival, Articuno, Zapdos y Moltres combaten juntos en un santuario de hielo, tormenta y fuego. Después podrás preparar el equipo para Mew y Mewtwo. No hay captura legendaria.' if loc['id']=='legendary-birds' else 'Tras superar a las tres aves, Mew y Mewtwo te esperan juntos en la caverna del origen. Este encuentro culmina la aventura. No hay captura legendaria.')
    dump(DATA/'journey-26.json', journey)
    layouts = {}
    for line in SPECS.strip().splitlines():
        identity, material, title, landmark, blocks, terraces = line.split('|')
        record = {'material': material, 'title': title, 'landmark': landmark, 'maps': {}}
        if identity=='legendary-birds': record['enemySpawns'] = {'144':[4,4], '145':[9,5], '146':[12,9]}
        if identity=='legendary-origin': record['enemySpawns'] = {'151':[8,6], '150':[11,3]}
        for size in [16, 24]:
            offset = (size-16)//2
            board = [[0]*size for _ in range(size)]
            heights = [[0]*size for _ in range(size)]
            props, paths = {}, []
            setup = arenas.get(identity, {})
            protected = {(x+offset,y+offset) for y in range(8,11) for x in range(2,6)}
            protected |= {(x+offset,y+offset) for x,y in [(8,6),(9,5),(10,4),(10,6),(11,5),(11,3)]}
            for pair in setup.get('portals', []):
                protected |= {(pair[0]+offset,pair[1]+offset),(pair[2]+offset,pair[3]+offset)}
            protected |= {(x+offset,y+offset) for x,y in setup.get('points', [])}
            protected |= {(x+offset,y+offset) for x,y in record.get('enemySpawns',{}).values()}
            # Every edge is a solid boundary. Sparse visible props avoid a wall of canopies.
            boundary_prop = 'oak' if material in ['forest','meadow'] else 'rock' if material in ['rock','cave','sand','water','ice','origin'] else 'pillar'
            for y in range(size):
                for x in range(size):
                    if x in [0,size-1] or y in [0,size-1]:
                        board[y][x] = 2
                        if (x+y)%2==0: props[f'{x},{y}'] = boundary_prop
                    elif material in ['forest','meadow'] and x in [1,2,size-3,size-2]: board[y][x] = 1
            for entry in terraces.split(';'):
                if not entry: continue
                x1,y1,x2,y2,h = map(int, entry.split(','))
                for y in range(y1+offset,y2+offset+1):
                    for x in range(x1+offset,x2+offset+1): heights[y][x] = h
            for entry in blocks.split(';'):
                if not entry: continue
                sx,sy,prop = entry.split(','); x,y = int(sx)+offset,int(sy)+offset
                assert (x,y) not in protected, (identity,x,y)
                board[y][x] = 1 if prop=='bush' else 2; props[f'{x},{y}'] = prop
            for x1,y1,x2,y2 in MASSES.get(identity,[]):
                for sy in range(y1,y2+1):
                    for sx in range(x1,x2+1):
                        x,y=sx+offset,sy+offset
                        if (x,y) in protected: continue
                        board[y][x]=2
                        if material=='forest': props[f'{x},{y}']='oak'
                        else: heights[y][x]=max(heights[y][x],1)
            # The initial protected ally/enemy/mission coordinates are deliberate authored floor.
            for x,y in protected: board[y][x] = 0; heights[y][x] = min(1,heights[y][x])
            water = {
                'route-24':[(x,y) for x in [4,5,10,11] for y in range(3,12)],
                'route-12':[(x,y) for x in [4,5,10,11] for y in range(3,12)],
                'misty':[(x,y) for x in [6,9,10] for y in [3,4,6,7,9,10,11]],
                'route-6':[(10,10),(11,10),(10,11),(11,11)],
                'route-22':[(10,11),(11,11),(12,11),(11,12)],
                'league-rival':[(10,11),(11,11),(12,11),(11,12)],
                'cerulean-rival':[(x,12) for x in range(6,12)],
                'route-10':[(12,y) for y in range(5,12)],
                'route-19':[(2,y) for y in range(3,12)]+[(12,y) for y in range(3,10)],
                'route-20':[(x,y) for x in range(3,13) for y in [3,11] if x not in [6,7,8]],
                'seafoam':[(6,11),(7,11),(8,11),(6,12),(7,12)],
                'route-21':[(2,y) for y in range(4,12)]+[(12,y) for y in range(4,9)],
                'lorelei':[(x,y) for x in [2,12] for y in range(5,12)],
                'legendary-origin':[(x,y) for x,y in [(3,5),(4,5),(5,5),(6,5),(7,5),(10,8),(10,9),(11,9),(11,10),(10,11),(9,11),(8,11),(7,11)]],
            }.get(identity, [])
            if identity=='legendary-origin':
                water += [(x,y) for x in range(2,14) for y in range(2,14)
                          if (x in [2,3,12,13] or y in [2,3,12,13])
                          and x not in [6,7,8,9] and y not in [6,7,8,9]]
            if identity=='ss-anne': water += [(x,y) for x in [1,14] for y in range(1,15)]
            for x,y in water:
                x+=offset; y+=offset
                if (x,y) not in protected and board[y][x]!=2: board[y][x]=3
            # Continuous dry approaches (2 tiles wide), with alternating arcs per location.
            # These are surfaces, never forced movement or a hidden stat bonus.
            direction = journey.index(next(l for l in journey if l['id']==identity))%3
            for y in range(1,size-1):
                cx = 7+offset if material in ['bridge','road'] else 5+offset+(1 if (y+direction)//4%2 else 0)
                for x in [cx,cx+1]:
                    if 0<x<size-1 and board[y][x]!=2 and f'{x},{y}' not in props:
                        board[y][x]=0; paths.append(f'{x},{y}')
            # Preserve published field/portal/mission effects, now on legible ground.
            for kind,x,y in setup.get('fields',[]):
                x+=offset; y+=offset
                assert board[y][x]!=2, (identity,kind,x,y)
            record['maps'][str(size)] = {'board':board,'heights':heights,'props':props,'paths':paths}
        layouts[identity] = record
    assert list(layouts)==[l['id'] for l in journey]
    # Revisit intentionally retains identical terrain, not a regenerated biome template.
    layouts['league-rival']['maps'] = layouts['route-22']['maps']
    dump(DATA/'kanto-landscapes.json', layouts)
    return layouts

if __name__=='__main__':
    result=build()
    print(json.dumps({'locations':len(result),'layouts':sum(len(r['maps']) for r in result.values()),'sha256':hashlib.sha256((DATA/'kanto-landscapes.json').read_bytes()).hexdigest()}))
