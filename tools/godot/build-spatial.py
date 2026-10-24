"""Compile the reviewed move table into the new, isolated spatial ruleset."""
from pathlib import Path
import csv,json
ROOT=Path(__file__).resolve().parents[2]
rows=list(csv.DictReader((ROOT/'docs/reports/moves-2026-10-24/movimientos.csv').open(encoding='utf-8-sig'),delimiter=';'))
data={}
for row in rows:
    if row['Ámbito']!='Actual':continue
    identity=row['ID']
    data[identity]={'shape':row['Forma'],'reviewPriority':row['Prioridad'],'spatialDescription':row['Propuesta'],'spatialRisk':row['Riesgo / contrapartida']}

def patch(ids,**values):
    for identity in ids.split():data[identity].update(values)

patch('smokescreen',field='smoke',special='field',category='status',kind='spatial',changes=[])
patch('poison-gas',field='poison',special='field',category='status',kind='spatial')
patch('smog',field='poison',areaScale=0.65,secondary=None)
patch('sludge',field='mud',areaScale=0.7)
patch('fire-spin',field='fire',areaScale=0.6)
patch('stealth-rock',field='rocks',special='field',category='status',kind='spatial',changes=[])
patch('string-shot',field='web',special='field',category='status',kind='spatial',changes=[])
patch('mist',field='mist',special='field',kind='spatial',target='ground',changes=[])
patch('light-screen',field='light-screen',special='field',kind='spatial',target='ground',changes=[])
patch('reflect',field='reflect',special='field',kind='spatial',target='ground',changes=[])
patch('barrier',field='wall',special='field',kind='spatial',target='ground',changes=[])
patch('haze',special='haze',kind='spatial',target='ground',includeUser=True)
patch('clear-smog',clearStages=True)
patch('hydro-pump surf iron-tail strength mega-punch mega-kick body-slam stomp crabhammer gust roar',pushDistance=1)
patch('whirlwind dragon-tail',pushDistance=2)
patch('roar whirlwind',kind='spatial',category='status',target='ground',power=0,changes=[],special='push')
patch('gust whirlwind',dispel=True)
patch('gust',pushFirst=True)
patch('water-gun scald surf hydro-pump',extinguish=True)
patch('vine-whip',pullDistance=1,range=2,contactRange=2)
patch('poison-sting',range=2,contactRange=2)
patch('bind wrap clamp constrict',special='bound')
patch('seismic-toss submission',special='throw',pushDistance=2)
patch('helping-hand',special='help',kind='spatial',target='friendly',range=2,contactRange=2,changes=[])
patch('soft-boiled',target='friendly',healTarget=True,range=2,contactRange=2)
patch('disable taunt encore yawn',kind='spatial',target='enemy',range=2,contactRange=2,changes=[])
for identity in 'disable taunt encore yawn'.split():data[identity]['special']=identity
patch('substitute conversion metronome mirror-move bide rage',kind='spatial',changes=[])
for identity in 'substitute conversion metronome mirror-move bide rage'.split():data[identity]['special']=identity
patch('mimic',special='mimic',kind='spatial',target='enemy',range=2,contactRange=2,changes=[])
patch('metronome mirror-move bide',target='ground',range=3,contactRange=3)
patch('teleport',special='teleport',kind='spatial',target='ground',range=3,contactRange=3,changes=[])
patch('splash',special='teleport',kind='spatial',target='ground',range=1,contactRange=1,changes=[])
patch('splash',shape='TP')
patch('counter mirror-coat',special='counter')
patch('brick-break',breakScreen=True)
patch('feint',pierceGuard=True)
patch('fake-out',special='fake-out')
patch('pay-day',special='pay-day')
patch('take-down double-edge flare-blitz skull-bash',approach=2,pushDistance=1,range=3,contactRange=1)
patch('drill-peck drill-run megahorn',approach=2,range=3,contactRange=1)
patch('jump-kick high-jump-kick',approach=1,jump=True,range=2,contactRange=1)
patch('fly sky-attack dig',approach=3,jump=True,range=4,contactRange=1)
patch('dig',underground=True)
patch('u-turn',retreat=True)
patch('waterfall',approach=2,range=3,contactRange=1)
patch('barrage pin-missile spike-cannon bonemerang',sharedDamageBudget=True)
patch('tri-attack',randomStatusChance=20)
descriptions={
 'barrier':'Crea una barrera temporal de tres casillas libres. Bloquea movimiento y visión; Q/E gira su orientación.',
 'splash':'Salta a una casilla adyacente libre gastando la acción. No da protección.',
 'psychic':'Impacto psíquico en una cruz de cinco casillas a alcance tres.',
 'leech-seed':'Planta Drenadoras en un objetivo a dos casillas. No crea una trampa de suelo.',
 'pay-day':'Proyecta monedas a un objetivo. Otorga 25 ₽ adicionales al ganar, una sola vez por encuentro.',
 'metronome':'Elige al confirmar entre Ascuas, Bola Sombra e Impactrueno. La previsión muestra el intervalo posible; no enseña el resultado del sorteo.',
 'mimic':'Copia el último movimiento válido del objetivo en la ranura de Mimético hasta acabar el combate.',
 'bide':'Acumula daño tras prepararse. Desde la siguiente activación puede devolver el doble a un rival, hasta sus propios PS máximos. Hay que liberarlo antes de que caduque.',
 'conversion':'Adopta hasta acabar el combate el tipo del primer movimiento ofensivo preparado.',
 'substitute':'Paga un cuarto de sus PS máximos para crear un escudo de esos PS. Absorbe impactos y efectos directos durante tres activaciones.',
 'roar':'Grito en cono que empuja una casilla a las unidades alcanzadas. No da protección.',
 'gust':'Ráfaga en línea de dos casillas. Empuja una casilla al primer rival y disipa humo y gas en el corredor.',
 'body-slam':'Golpe individual que puede paralizar y empuja una casilla si queda libre.',
 'stomp':'Golpe individual que empuja una casilla si queda libre.',
 'crabhammer':'Golpe individual que empuja una casilla si queda libre.',
 'facade':'Golpe individual con el doble de potencia si el usuario tiene un estado principal.',
 'foul-play':'Golpe individual que usa el Ataque del rival para calcular su potencia.',
 'low-kick':'Golpe individual; conserva la potencia táctica adaptada, sin cálculo por peso.',
 'night-shade':'Daño individual con la adaptación actual, sin fórmula nueva ligada al nivel.',
 'psywave':'Ataque individual con la adaptación actual, sin fórmula nueva ligada al nivel.',
 'sonic-boom':'Onda en línea de tres casillas. Conserva la fórmula de daño táctica existente.',
}
for identity,description in descriptions.items():data[identity]['spatialDescription']=description
shape_names={'U':'usuario','S1':'individual','S2':'individual a dos casillas','S3':'individual a tres casillas','S2A':'aliado próximo','C0':'cruz cercana','C1':'cruz de cinco casillas','R1':'ocho casillas alrededor','D2':'rombo de radio dos','L2':'línea de dos','L3':'línea de tres','L4':'línea de cuatro','F0':'barrido frontal','F3':'franja transversal','K2':'cono corto','T4':'abanico','W6':'ola de seis casillas','X5':'aspa','DAI7':'estrella de siete casillas','WALL3':'pantalla de tres casillas','DASH':'aproximación y golpe','JUMP':'salto y golpe','TP':'destino libre','THROW':'lanzamiento dirigido','RETREAT':'golpe y retirada','VARIABLE':'técnica aleatoria'}
for identity,entry in data.items():
    entry['id']=identity
    shape=entry['shape']
    entry['shapeName']=shape_names[shape]
    if shape in ['S3','S2','S2A']:entry.setdefault('range',3 if shape=='S3' else 2);entry.setdefault('contactRange',entry['range'])
    if shape in ['L2','L3','L4']:entry.update(range=int(shape[1:]),contactRange=int(shape[1:]))
    if shape in ['C1','F3','WALL3','VARIABLE']:entry.setdefault('range',3);entry.setdefault('contactRange',entry['range'])
    if shape in ['K2','W6','T4']:entry.setdefault('range',2);entry.setdefault('contactRange',entry['range'])
    if shape in ['C0','R1','D2','F0','X5','DAI7']:entry.setdefault('range',3);entry.setdefault('contactRange',entry['range'])
    if shape not in ['U','S1','S2','S3','S2A','DASH','JUMP','TP','RETREAT','THROW','VARIABLE']:
        entry['spatialArea']=True
        entry.setdefault('areaScale',0.8)
        entry.setdefault('costFloor',3 if shape in ['C1','L3','F3','F0','K2','C0','T4','L2','X5'] else 4)
    if entry.get('field'):entry['costFloor']=4 if entry['field']=='wall' else 3
    if identity in ['explosion','self-destruct']:entry['costFloor']=5
    if identity in ['sleep-powder','spore','sing']:entry['statusDuration']=1
    if identity in ['metronome','substitute','mirror-move']:entry['costFloor']=3
    if identity=='basic':entry.update(costFloor=0,areaScale=1.0)
assert len(data)==212
result={'edition':19,'combatEdition':18,'zoneRounds':2,'moves':data,'metronomePool':['ember','shadow-ball','thunder-shock'],'notes':'Audit accepted 2026-10-24. Alternatives resolved in SPRINT_23_SPATIAL.md. Legacy editions stay frozen.'}
(ROOT/'godot/data/spatial.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (ROOT/'docs/reports/moves-2026-10-24/aplicacion-0.23.csv').open('w',encoding='utf-8-sig',newline='') as report:
    columns=['ID','Forma aplicada','Zona','Especial','Empuje','Atracción','PT mínimo','Daño de área','Estado breve','Descripción aplicada']
    writer=csv.DictWriter(report,fieldnames=columns,delimiter=';');writer.writeheader()
    for identity,entry in data.items():
        writer.writerow(dict(zip(columns,[identity,entry['shapeName'],entry.get('field',''),entry.get('special',''),entry.get('pushDistance',0),entry.get('pullDistance',0),entry.get('costFloor',0),entry.get('areaScale',1),entry.get('statusDuration',''),entry['spatialDescription']])))
print('Spatial definitions:',len(data))
