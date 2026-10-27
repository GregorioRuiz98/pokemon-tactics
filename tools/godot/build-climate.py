"""Build new-edition data from existing, cached public sources. No network or old files."""
from pathlib import Path
import csv, hashlib, json

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'godot/data'
sources = []

def source(path, url):
    raw = path.read_bytes()
    sources.append({'url':url,'sha256':hashlib.sha256(raw).hexdigest()})
    return raw

species_csv = ROOT / '../../work/economy-sources/pokemon_species.csv'
lock = json.loads((ROOT/'tools/sources.lock.json').read_text())
rates = {r['id']:int(r['gender_rate']) for r in csv.DictReader(source(species_csv,lock['pokeapi']['raw']+'/data/v2/csv/pokemon_species.csv').decode('utf-8-sig').splitlines()) if int(r['id'])<=151}
compatible = {k:[] for k in ['sunny-day','rain-dance','sandstorm']}
for dex in range(1,152):
    url = f'https://pokeapi.co/api/v2/pokemon/{dex}'
    path = ROOT/'tools/cache'/hashlib.sha256(url.encode()).hexdigest()
    pokemon = json.loads(source(path,url))
    for entry in pokemon['moves']:
        name = entry['move']['name']
        if name in compatible and any(v['move_learn_method']['name']=='machine' and v['version_group']['name'] in ['sun-moon','ultra-sun-ultra-moon','sword-shield','scarlet-violet'] for v in entry['version_group_details']): compatible[name].append(dex)

descriptions = {
'chlorophyll':'Sol: Velocidad ×2 en la próxima cola; sin activaciones adicionales.',
'swift-swim':'Lluvia: Velocidad ×2 en la próxima cola; sin activaciones adicionales.',
'hydration':'Lluvia: cura el estado principal al terminar su activación; sin PS.',
'leaf-guard':'Sol: impide estados principales nuevos; no cura los existentes.',
'sand-veil':'Arena: recibe un 20 % menos de daño a distancia y evita el daño climático. Adaptación.',
'cloud-nine':'Aura de 3 casillas: anula el clima para aliados y rivales visibles. Adaptación.',
'run-away':'Atraviesa rivales al moverse, sin acabar encima; ignora Trampa Arena e Imán. Adaptación.',
'rivalry':'Potencia +25 % frente al mismo sexo y −25 % frente al opuesto; sin efecto contra Pokémon sin sexo.',
'cute-charm':'Contacto de sexo opuesto: 30 % de Encanto por 2 activaciones; el atacante causa 20 % menos de daño al poseedor. Adaptación.',
'magic-guard':'Evita daño residual de estados, clima, terrenos y Vidaesfera; no evita costes propios ni las otras consecuencias de estados.',
'competitive':'Una reducción de atributos causada por un rival da +2 Ataque especial, una vez por acción enemiga, hasta el límite.',
'inner-focus':'Impide amedrentamiento, Intimidación y el empuje de Hedor.',
'arena-trap':'Salir de una casilla adyacente cuesta +1 movimiento a enemigos terrestres; no afecta a Fuga o Levitación. Adaptación.',
'pickup':'Si sobrevive: 25 % de encontrar una Poción al ganar; una tirada por equipo y encuentro. Adaptación.',
'liquid-ooze':'Absorber sus PS daña al beneficiario en vez de curarlo por la cantidad que habría recuperado.',
'oblivious':'Impide Mofa, Intimidación y Encanto.',
'magnet-pull':'Aura de 2 casillas: los enemigos Acero pagan +1 movimiento por paso dentro del aura; Fuga lo evita. Adaptación.',
'early-bird':'El sueño disminuye dos pasos al terminar su activación, sin conceder inmunidad.',
'stench':'Contacto: 10 % de empujar una casilla libre, una comprobación por acción y sin daño de choque. Adaptación.',
'sticky-hold':'El rival no puede retirar su equipable ni empujarlo o atraerlo; conserva movimiento voluntario. Adaptación.',
'cursed-body':'Al recibir daño: 30 % de anular esa técnica en la próxima activación del atacante; nunca el básico. Incluye protección temporal frente a repetición.',
'forewarn':'Al desplegarse marca la técnica rival de mayor potencia; recibe un 25 % menos de daño de esa técnica. Adaptación.',
'neutralizing-gas':'Aura de 2 casillas: suprime otras habilidades de aliados y rivales visibles; no repite bonificaciones de entrada. Adaptación.',
'natural-cure':'Terminar su activación sin usar una acción cura su estado principal; puede haberse movido. Adaptación.',
'scrappy':'Sus movimientos Normal y Lucha alcanzan a Fantasma; conserva las demás resistencias.',
'sniper':'El multiplicador de crítico pasa de ×1,5 a ×2,25.',
'illuminate':'Aura de 2 casillas: los aliados ignoran la penalización del humo; no atraviesan paredes. Adaptación.',
'trace':'Al comenzar copia una habilidad válida del rival más cercano; sin cadenas de Calco ni Gas Reactivo.',
'download':'Al comenzar: +1 Ataque si el rival más cercano tiene menor Defensa que Defensa especial; en otro caso +1 Ataque especial. Una vez por combate.',
'pressure':'Enemigos que comienzan a 2 casillas visibles: −1 movimiento, mínimo 1 y sin acumular fuentes. Adaptación.',
'dry-skin':'Absorbe Agua: +25 % PS; recibe un 25 % más de potencia Fuego. Al terminar: lluvia cura 1/8 PS; sol daña 1/8 PS.'}
weather_text = {'sun':'Fuego ×1,5; Agua ×0,5.','rain':'Agua ×1,5; Fuego ×0,5. Trueno no falla por precisión.','sand':'Daño de 1/16 PS al terminar la activación, salvo Roca, Tierra y Acero. Defensa especial de Roca ×1,5.'}
moves = {}
for identity,name,kind,type_name in [('sunny-day','Día Soleado','sun','fire'),('rain-dance','Danza Lluvia','rain','water'),('sandstorm','Tormenta Arena','sand','rock')]:
    moves[identity] = {'id':identity,'name':name,'type':type_name,'category':'status','kind':'weather','special':'weather','weather':kind,'target':'self','shape':'U','shapeName':'Clima global','range':0,'contactRange':0,'power':0,'accuracy':100,'cost':0,'loadoutCost':2,'permanentStages':True,'neverMiss':True,'changes':[],'description':'Cambia el clima durante lo que queda de ronda y tres rondas completas. '+weather_text[kind]}
result = {'version':25,'genderRates':rates,'abilities':descriptions,'moves':moves,'compatible':compatible,'encounters':{'forest':'rain','route-3':'sun','route-4':'sand','route-9':'rain','route-17':'sun','route-19':'rain','route-20':'rain','route-21':'sun'}}
raw=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()
(DATA/'climate.json').write_bytes(raw)
(DATA/'climate-provenance.json').write_text(json.dumps({'sources':sources,'description':'Existing PokéAPI snapshots; original gender rates and Gen7–9 weather machine compatibility. All tactical ability adaptations authored for edition25.','files':[{'target':'data/climate.json','sha256':hashlib.sha256(raw).hexdigest()}]},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'species':len(rates),'abilities':len(descriptions),'moves':len(moves),'compatibility':{k:len(v) for k,v in compatible.items()}}))
