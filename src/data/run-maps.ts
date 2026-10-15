import { TACTICAL_BOARD } from '../rules/terrain.ts';
import type { Board } from '../rules/movement.ts';
import type { BoardHazard } from '../rules/hazards.ts';

export type RunMap = { id: string; name: string; description: string; board: Board; hazards?: BoardHazard[] };
export const RUN_MAPS: readonly RunMap[] = [
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
