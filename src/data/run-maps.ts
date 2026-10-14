import { TACTICAL_BOARD } from '../rules/terrain.ts';
import type { Board } from '../rules/movement.ts';

export const RUN_MAPS: readonly { id: string; name: string; description: string; board: Board }[] = [
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
