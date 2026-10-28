"""Build the explicit, deterministic terrain catalogue of campaign edition 30.

Only writes new relief-maps.json. Published catalogues and original art stay intact.
Coordinates are authored on 16x16, centred without rescaling on 24x24 boards.
"""
from pathlib import Path
import csv
import json

ROOT = Path(__file__).resolve().parents[2]
# identity: landform, material, landmark, obstacle, distinguishing motif
DESIGNS = {
 'route-1': ('meadow','meadow','La loma de Paleta','bush','path'),
 'route-2': ('ridge','forest','La puerta del bosque','oak','grove'),
 'forest': ('groves','forest','El roble de los tres claros','oak','grove'),
 'brock': ('quarry','rock','El estrado de Onix','rock','fossil'),
 'route-3': ('ridge','rock','El espolón de Monte Moon','rock','path'),
 'mt-moon': ('excavation','rock','La excavación de fósiles','pillar','fossil'),
 'route-4': ('descent','rock','La salida sobre Celeste','rock','path'),
 'cerulean-rival': ('plaza','industrial','La fuente de Celeste','statue','canal'),
 'route-24': ('bridge','wood','El Puente Pepita','railing','bridge'),
 'route-25': ('garden','meadow','El jardín de Bill','cottage','flowers'),
 'misty': ('pools','water','La piscina de las tres pasarelas','railing','pool'),
 'route-5': ('descent','meadow','La cuesta de la guardería','fence','fields'),
 'route-6': ('wetland','meadow','Las dos orillas del estanque','bush','pool'),
 'ss-anne': ('deck','wood','La toldilla del S. S. Anne','railing','deck'),
 'surge': ('factory','industrial','El generador de Carmín','bin','circuit'),
 'route-11': ('meadow','meadow','La pradera de las tres franjas','bush','fields'),
 'diglett-cave': ('gorge','rock','Las bocas del túnel','rock','tunnel'),
 'route-22': ('ridge','meadow','El mirador de la Liga','fence','path'),
 'route-9': ('switchback','rock','Los recodos de la montaña','rock','path'),
 'route-10': ('wetland','rock','La ribera del Túnel Roca','turbine','canal'),
 'rock-tunnel': ('gorge','rock','El pozo del Túnel Roca','pillar','tunnel'),
 'route-8': ('garden','meadow','Los setos de Lavanda','fence','flowers'),
 'route-7': ('plaza','industrial','Las puertas de Azulona','cottage','path'),
 'erika': ('garden','forest','El jardín escalonado de Erika','bush','flowers'),
 'rocket-hideout': ('factory','industrial','Los almacenes de Giovanni','server','circuit'),
 'tower-rival': ('tower','haunted','El vestíbulo de las lápidas','tomb','tombs'),
 'pokemon-tower': ('tower','haunted','El santuario de Marowak','tomb','tombs'),
 'fuji-rescue': ('tower','haunted','La escalinata de Fuji','pillar','tombs'),
 'route-12': ('bridge','wood','Las pasarelas de los pescadores','railing','bridge'),
 'route-13': ('coast','meadow','Los cercados del acantilado','fence','fields'),
 'route-14': ('groves','forest','El corredor de hierba alta','oak','fields'),
 'route-15': ('terraces','meadow','Los bancales de Fucsia','fence','fields'),
 'route-16': ('road','industrial','La cuesta del Camino de Bicis','fence','road'),
 'route-17': ('descent','industrial','El descenso del Camino de Bicis','railing','road'),
 'route-18': ('road','meadow','El rellano de Fucsia','fence','road'),
 'safari': ('wetland','meadow','Las lagunas de la Zona Safari','bush','pool'),
 'koga': ('dojo','wood','El patio elevado de Koga','pillar','dojo'),
 'silph-rival': ('office','industrial','Las pasarelas de Silph','desk','circuit'),
 'silph-giovanni': ('office','industrial','La sala de juntas','server','circuit'),
 'sabrina': ('psychic','psychic','Los atrios de Sabrina','crystal','rune'),
 'route-19': ('coast','meadow','Las dunas de Fucsia','rock','shore'),
 'route-20': ('islands','meadow','El archipiélago del sur','rock','shore'),
 'seafoam': ('ice','ice','Las galerías de hielo','crystal','ice'),
 'route-21': ('coast','meadow','La costa de Paleta','cottage','shore'),
 'pokemon-mansion': ('ruins','haunted','Las escaleras de la mansión','statue','ruins'),
 'blaine': ('volcano','volcanic','La caldera del laboratorio','turbine','magma'),
 'giovanni-gym': ('quarry','rock','El anfiteatro de Giovanni','pillar','fossil'),
 'power-plant': ('factory','industrial','El patio de turbinas','turbine','circuit'),
 'league-rival': ('ridge','meadow','El último mirador de Kanto','statue','path'),
 'route-23': ('gates','league','Las ocho puertas de la Liga','pillar','gates'),
 'victory-road': ('switchback','rock','El ascenso de Calle Victoria','rock','fossil'),
 'lorelei': ('ice','ice','El anfiteatro helado','crystal','ice'),
 'bruno': ('dojo','rock','Las terrazas del dojo','rock','dojo'),
 'agatha': ('tower','haunted','El círculo de las lápidas','tomb','tombs'),
 'lance': ('dragon','league','Las alas de la cámara dragón','statue','rune'),
 'champion': ('throne','league','La escalinata del Campeón','pillar','crown'),
 'legendary-birds': ('sanctuary','birds','Los tres santuarios','crystal','sectors'),
 'legendary-origin': ('crater','origin','La sima del origen','crystal','rune'),
}
PALETTES = {'meadow':['819c61','53664b'], 'forest':['557f52','394e38'], 'rock':['b5a080','75604e'],
 'industrial':['91a4ac','526673'], 'wood':['b79568','625142'], 'water':['84b5b8','506f80'],
 'haunted':['8e829f','53495f'], 'psychic':['aa8cb8','665273'], 'ice':['badbe0','718fa4'],
 'volcanic':['9d7762','594a47'], 'league':['a5b4c5','5c6b83'], 'birds':['b2bdba','697b82'], 'origin':['9e9fc1','5d5d80']}

def line(a,b):
    x,y=a; out=[a]
    # Deterministic orthogonal raster; paths never rely on diagonal movement.
    while (x,y)!=b:
        if x!=b[0] and (y==b[1] or abs(b[0]-x)>=abs(b[1]-y)):x+=1 if b[0]>x else -1
        else:y+=1 if b[1]>y else -1
        out.append((x,y))
    return out

def build(identity, row, index):
    form,material,landmark,prop,motif=DESIGNS[identity]
    h=[[0]*16 for _ in range(16)]; board=[[0]*16 for _ in range(16)]; props={}; paths=set()
    def rect(x0,y0,x1,y1,height=None,tile=None):
        for y in range(y0,y1+1):
            for x in range(x0,x1+1):
                if height is not None:h[y][x]=height
                if tile is not None:board[y][x]=tile
    # Broad landforms, kept as explicit cells in the shipped catalogue.
    for y in range(16):
        for x in range(16):
            if form in ['ridge','switchback','terraces','quarry','gates','throne']:v=max(0,min(3,(x+14-y)//5-1))
            elif form=='descent':v=max(0,min(3,(18-x+y)//6-1))
            elif form in ['excavation','crater','gorge']:v=min(3,max(abs(x-8),abs(y-7))//2)
            elif form in ['tower','dragon','dojo','psychic','office','deck','factory']:v=2 if y<=5 else 1 if y<=8 else 0
            elif form in ['coast','islands','wetland','bridge','pools','ice','sanctuary']:v=0 if x<=5 else 1 if x<=10 else 2
            else:v=1 if (x-10)**2+(y-4)**2<30 else 0
            h[y][x]=v
    if form in ['quarry','throne','gates']:rect(9,2,13,6,3)
    if form=='garden':rect(8,3,12,6,2);rect(10,4,11,5,3)
    if form=='groves':rect(6,3,10,6,2);rect(10,9,13,12,1)
    if form=='switchback':rect(6,4,9,8,2);rect(11,2,13,5,3)
    if form=='tower':rect(9,2,13,5,3)
    if form=='crater':rect(6,5,10,9,0);rect(11,2,13,5,3)
    if form=='sanctuary':rect(3,2,5,4,3);rect(8,2,10,4,2);rect(12,6,14,9,3)
    if form in ['meadow','plaza','road']:rect(10,2,13,4,2)
    if form=='volcano':rect(6,5,11,10,0);rect(10,2,13,5,3)
    if form=='ruins':rect(3,2,6,5,2);rect(10,3,13,6,3)
    water_forms=['bridge','pools','wetland','coast','islands','ice']
    if form in water_forms:
        if form in ['bridge','islands']:rect(6,1,9,14,0,3)
        elif form in ['pools','ice']:rect(6,3,8,6,0,3);rect(10,8,12,12,0,3)
        elif form=='wetland':rect(7,5,10,10,0,3)
        else:rect(10,9,14,14,0,3)
    # Multiple entrances into each major elevation; surface routes are 2 cells wide.
    origin=(4,9); goal=(11,5)
    via_a=[origin,(7,9),(10,8),goal]
    via_b=[origin,(3,5),(7,3),goal]
    if form in ['bridge','islands']:via_a=[origin,(7,9),(10,9),goal];via_b=[origin,(4,3),(10,3),goal]
    if form in ['gorge','excavation','crater']:via_a=[origin,(7,10),(10,9),goal];via_b=[origin,(3,5),(7,4),goal]
    def corridor(points,width=1):
        cells=[]
        for a,b in zip(points,points[1:]):cells+=line(a,b)[int(bool(cells)):]
        first=h[cells[0][1]][cells[0][0]];last=h[cells[-1][1]][cells[-1][0]]
        last=max(first-len(cells)+1,min(first+len(cells)-1,last))
        for i,(x,y) in enumerate(cells):
            value=round(first+(last-first)*i/max(1,len(cells)-1))
            for dx in range(width+1):
                if 0<x+dx<15:
                    h[y][x+dx]=value;board[y][x+dx]=0;paths.add((x+dx,y));props.pop(f'{x+dx},{y}',None)
    corridor(via_a);corridor(via_b)
    # Solid landmarks and thematic scenery stay out of the approach routes.
    landmark_at=(8,7)
    if form in ['bridge','islands','coast','pools','ice']:landmark_at=(12,7)
    if form in ['throne','tower','gates','dojo']:landmark_at=(8,2)
    for x,y in [(2,3),(3,3),(12,10),(13,10),(7,6),(8,6),(8,7),(8,8),(6,12),(7,12)]:
        # Identity changes distribution as well as colours, without randomness.
        if ((x+y+index)%3==0 and (x,y)!=landmark_at) or (x,y) in paths or board[y][x]==3:continue
        board[y][x]=2;props[f'{x},{y}']=prop
    lx,ly=landmark_at
    if (lx,ly) not in paths and board[ly][lx]!=3:board[ly][lx]=2;props[f'{lx},{ly}']=prop
    if form in ['groves','garden']:
        for x,y in [(2,1),(3,1),(5,2),(5,3),(5,4),(10,10),(11,10),(12,11),(13,11),(13,12),(2,12),(3,13),(4,13),(8,13),(9,13)]:
            if (x,y) not in paths:board[y][x]=2;props[f'{x},{y}']=prop
    if form in ['deck','factory','office','tower','dojo','ruins']:
        for x,y in [(2,2),(3,2),(12,2),(13,2),(2,6),(13,6),(2,13),(13,13)]:
            if (x,y) not in paths:board[y][x]=2;props[f'{x},{y}']=prop
    if form in ['bridge','islands','pools','wetland','coast','ice']:
        for x,y in [(5,2),(10,2),(5,6),(10,6),(5,12),(10,12),(13,4),(3,13)]:
            if (x,y) not in paths and board[y][x]!=3:board[y][x]=2;props[f'{x},{y}']=prop
    if form in ['road','descent','terraces','meadow']:
        for y in [4,6,12]:
            for x in range(2,14):
                if (x,y) not in paths and board[y][x]==0:board[y][x]=1
    allies=[(4,9),(3,9),(4,10),(2,9),(3,10),(2,10)]
    enemies=[(10,5),(11,4),(12,5),(10,3),(12,3),(11,6)]
    if identity=='route-1':enemies=[(8,6),(9,5),(10,6),(10,4),(11,5),(11,3)]
    if identity=='legendary-birds':enemies=[(4,3),(9,3),(13,7)]
    if identity=='legendary-origin':enemies=[(9,7),(12,4)]
    deployment=[(x,y) for y in range(8,12) for x in range(2,6)]
    # Authored connector to each actual possible spawn. Heights remain terraces.
    for cell in enemies:corridor([goal,cell],0)
    if form=='sanctuary':
        corridor([origin,(2,6),(2,3),enemies[0]])
        corridor([(10,9),(14,10),enemies[2]])
    if form=='crater':corridor([origin,(5,11),(9,11),enemies[0]])
    for x,y in deployment+allies+enemies:
        board[y][x]=0;props.pop(f'{x},{y}',None)
    # The named landmark must exist, not merely be a title over a path.
    candidates=[landmark_at]+[(x,y) for y in range(2,14) for x in range(2,14)]
    for x,y in candidates:
        if (x,y) not in paths and (x,y) not in deployment+allies+enemies and board[y][x]!=3:
            landmark_at=(x,y);board[y][x]=2;props[f'{x},{y}']=prop;break
    plans={'bridge':'Cruza por el puente alto o busca la otra conexión entre las orillas.',
      'quarry':'Dos rampas dan acceso al estrado; los salientes cortan las líneas de tiro.',
      'groves':'Tres claros conectados; las arboledas interrumpen la visión entre ellos.',
      'crater':'Rodea la sima o desciende al centro para cambiar de flanco.',
      'sanctuary':'Tres santuarios elevados rodean el cruce central; elige tu aproximación.',
      'deck':'Las escaleras conectan cubierta y toldilla; las barandillas delimitan los pasos.',
      'pools':'Pasarelas y orillas conectan las piscinas; disputa los accesos elevados.'}
    plan=plans.get(form,'Dos accesos conectan las cotas; usa los desniveles y la cobertura para cambiar de flanco.')
    return dict(title=row['titulo'],landmark=landmark,form=form,material=material,motif=motif,
      palette=PALETTES[material],board=board,heights=h,props=props,paths=[f'{x},{y}' for x,y in sorted(paths)],
      allies=allies,enemies=enemies,deployment=deployment,landmarkCell=landmark_at,
      plan=plan,context=row['contexto'],speaker=row['personaje'])

def main():
    with (ROOT/'docs/MAPAS_0.34.csv').open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
    assert set(DESIGNS)=={r['zona'] for r in rows}
    data={r['zona']:build(r['zona'],r,i) for i,r in enumerate(rows)}
    (ROOT/'godot/data/relief-maps.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    print(f'Authored {len(data)} deterministic terrain layouts; no published catalogue modified.')

if __name__=='__main__':main()
