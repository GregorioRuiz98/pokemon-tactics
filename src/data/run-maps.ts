import { TACTICAL_BOARD } from '../rules/terrain.ts';
import type { Board } from '../rules/movement.ts';
import type { BoardHazard } from '../rules/hazards.ts';

export type RunMap = { id: string; name: string; description: string; board: Board; hazards?: BoardHazard[] };
export const RUN_MAPS: readonly RunMap[] = [
  {id:'caldera',name:'Caldera de Canela',description:'Fumarolas entre muros de piedra. Fuego y voladores evitan su daño.',board:[
    [0,0,0,0,0,0,0,0],[0,0,2,0,0,0,0,0],[0,0,0,0,2,0,0,0],[0,0,2,0,0,2,0,0],
    [0,0,0,0,0,0,0,0],[0,2,0,0,0,0,2,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:3,y:3,kind:'fire'},{x:4,y:3,kind:'fire'},{x:3,y:4,kind:'fire'},{x:4,y:4,kind:'fire'}]},
  {id:'kiln',name:'Hornos de la isla',description:'Tres accesos entre fumarolas; rodear permite evitar áreas de fuego.',board:[
    [0,0,0,0,0,0,0,0],[0,0,0,2,0,0,0,0],[0,2,0,0,0,0,0,0],[0,0,0,2,0,0,0,0],
    [0,0,2,0,0,0,2,0],[0,0,0,0,2,0,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:2,y:3,kind:'fire'},{x:4,y:4,kind:'fire'},{x:5,y:3,kind:'fire'}]},
  {id:'badlands',name:'Tierras de Verde',description:'Arena entre rocas y rutas de tierra firme. Tierra, Roca, Acero y voladores inmunes.',board:[
    [0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0],[0,0,2,0,0,0,0,0],[0,0,0,0,0,2,0,0],
    [0,2,0,0,2,0,0,0],[0,0,0,0,0,0,2,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:2,y:4,kind:'ground'},{x:3,y:4,kind:'ground'},{x:4,y:3,kind:'ground'}]},
  {id:'canyon',name:'Desfiladero final',description:'Pasos estrechos, arena y líneas cortadas; reorganiza antes del santuario o laboratorio.',board:[
    [0,0,0,0,0,0,0,0],[0,0,2,0,0,0,0,0],[0,0,2,0,2,0,0,0],[0,0,0,0,2,0,0,0],
    [0,0,2,0,0,0,0,0],[0,0,2,0,0,2,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:3,y:3,kind:'ground'},{x:3,y:4,kind:'ground'},{x:5,y:3,kind:'ground'}]},
  {id:'marsh',name:'Marisma de Fucsia',description:'Maleza, pequeños charcos y miasma. Veneno, Acero y voladores evitan el peligro.',board:[
    [0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0],[0,1,1,0,0,0,0,0],[0,3,1,0,1,0,0,0],
    [0,1,0,0,1,0,0,0],[0,0,0,1,0,3,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:2,y:3,kind:'poison'},{x:3,y:4,kind:'poison'},{x:4,y:4,kind:'poison'}]},
  {id:'foundry',name:'Patio de antídotos',description:'Columnas estrechan las líneas de tiro; el miasma obliga a recolocarse.',board:[
    [0,0,0,0,0,0,0,0],[0,0,2,0,0,0,0,0],[0,0,0,0,2,0,0,0],[0,2,0,0,0,2,0,0],
    [0,0,0,2,0,0,0,0],[0,0,0,0,0,2,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:2,y:4,kind:'poison'},{x:4,y:3,kind:'poison'},{x:5,y:4,kind:'poison'}]},
  {id:'dojo',name:'Patio de Azafrán',description:'Pasillos cortos y pulsos psíquicos en cruces. Usa cobertura y flancos.',board:[
    [0,0,0,0,0,0,0,0],[0,0,0,2,0,0,0,0],[0,2,0,0,0,0,0,0],[0,0,0,2,0,2,0,0],
    [0,0,0,0,0,0,0,0],[0,2,0,0,2,0,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:2,y:3,kind:'psychic'},{x:4,y:3,kind:'psychic'},{x:3,y:4,kind:'psychic'}]},
  {id:'mirrors',name:'Galería de espejos',description:'Bloques de cobertura dividen el avance; los pulsos dejan corredores seguros.',board:[
    [0,0,0,0,0,0,0,0],[0,2,0,0,0,0,0,0],[0,0,0,2,0,0,0,0],[0,0,2,0,0,0,2,0],
    [0,0,0,0,2,0,0,0],[0,0,2,0,0,0,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:3,y:3,kind:'psychic'},{x:4,y:2,kind:'psychic'},{x:4,y:5,kind:'psychic'}]},
  {id:'power',name:'Central de Carmín',description:'Muros cortan disparos; corriente en el centro desde ronda 2. Eléctrico, Tierra y voladores inmunes.',board:[
    [0,0,0,0,0,0,0,0],[0,0,0,2,0,0,0,0],[0,0,2,0,0,0,0,0],[0,0,0,0,0,2,0,0],
    [0,0,2,0,0,0,0,0],[0,0,0,0,0,2,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:3,y:3,kind:'electric'},{x:4,y:3,kind:'electric'},{x:3,y:4,kind:'electric'}]},
  {id:'switchyard',name:'Patio de transformadores',description:'Cruza los carriles entre bloques; corrientes alternan con pasos seguros.',board:[
    [0,0,0,0,0,0,0,0],[0,0,2,0,0,0,0,0],[0,0,0,0,2,0,0,0],[0,2,0,0,0,0,0,0],
    [0,0,0,2,0,0,0,0],[0,0,0,0,0,0,2,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],hazards:[{x:2,y:3,kind:'electric'},{x:4,y:4,kind:'electric'},{x:6,y:3,kind:'electric'}]},
  {id:'garden',name:'Jardín de Azulona',description:'Maleza densa en el centro. Planta y voladores la atraviesan mejor.',board:[
    [0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0],[0,0,1,1,1,0,0,0],[0,1,1,0,1,1,0,0],
    [0,1,1,1,1,0,0,0],[0,0,1,0,1,1,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]]},
  {id:'grove',name:'Arboleda interior',description:'Macizos que cortan líneas y maleza por los flancos; preserva rutas de retirada.',board:[
    [0,0,0,0,0,0,0,0],[0,1,0,0,0,0,0,0],[0,1,2,0,0,0,0,0],[0,1,0,1,0,2,0,0],
    [0,0,0,1,1,0,0,0],[0,1,1,0,2,0,1,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]]},
  {id:'canal',name:'Canales de Celeste',description:'Dos canales y puentes centrales: nadar abre rutas por los flancos.',board:[
    [0,0,0,0,0,0,0,0],[0,3,3,0,0,0,0,0],[0,3,3,0,0,0,0,0],[0,3,3,0,0,3,3,0],
    [0,0,0,0,0,0,0,0],[0,3,3,0,0,3,3,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0],
  ]},
  { id: 'psychic', name: 'Laboratorio del origen', description: 'Mewtwo presiona a distancia; Mew cruza el sector natural. Pulsos psíquicos: 4 PS desde ronda 2; Psíquico y Siniestro inmunes.',
    board: [[0,0,0,0,0,0,0,0],[0,0,2,0,0,0,0,0],[0,1,0,2,0,0,0,0],[0,1,0,0,0,2,0,0],[0,1,1,0,0,0,0,0],[0,0,0,0,2,0,1,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],
    hazards: [{x:3,y:4,kind:'psychic'},{x:4,y:4,kind:'psychic'},{x:4,y:3,kind:'psychic'},{x:6,y:3,kind:'psychic'},{x:6,y:4,kind:'psychic'}] },
  { id: 'birds', name: 'Santuario de las tres aves', description: 'Articuno, Zapdos y Moltres juntos. Sectores de escarcha, corriente y fumarolas: 4 PS al cerrar turno desde ronda 2. Volar y afinidades protegen.',
    board: [[0,0,0,0,0,0,0,0],[0,0,0,2,0,0,0,0],[0,0,0,0,0,0,0,0],[0,0,2,0,0,2,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0]],
    hazards: [{x:1,y:2,kind:'ice'},{x:1,y:3,kind:'ice'},{x:2,y:4,kind:'ice'},{x:3,y:2,kind:'electric'},{x:4,y:3,kind:'electric'},{x:4,y:4,kind:'electric'},{x:6,y:2,kind:'fire'},{x:6,y:3,kind:'fire'},{x:5,y:4,kind:'fire'}] },
  { id: 'quarry', name: 'Cantera', description: 'Pasos entre roca y maleza.', board: [
    [0,0,0,0,2,0,2,0], [0,0,1,0,0,0,0,2], [0,1,2,0,0,1,0,0], [0,0,2,0,2,1,0,0],
    [0,1,2,0,0,0,0,0], [0,0,0,0,1,0,2,0], [0,0,0,0,0,0,1,0], [0,0,0,0,0,0,0,0],
  ] },
  { id: 'pass', name: 'Paso de piedra', description: 'Un corredor central y rutas por los flancos.', board: [
    [0,0,0,2,0,0,0,0], [0,0,1,2,0,0,0,0], [0,1,0,0,0,0,0,0], [0,0,0,2,0,2,1,0],
    [0,0,0,0,0,0,1,0], [0,1,0,2,0,2,0,0], [0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0],
  ] },
  { id: 'pond', name: 'Cantera inundada', description: 'El agua favorece a acuáticos y voladores.', board: TACTICAL_BOARD },
];
export function runMap(id: string) {
  const map = RUN_MAPS.find(map => map.id === id);
  if (!map) throw new Error('Mapa desconocido.');
  return map;
}
