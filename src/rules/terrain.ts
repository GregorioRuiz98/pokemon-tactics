import type { Board, Point } from './movement.ts';
import { same } from './movement.ts';
import type { Combatant } from '../domain/combatant.ts';
import { heldItemFor } from '../domain/items.ts';
export type TerrainField = Point & {
  kind: 'embers';
  expires: number;
};
export const PROFILE_NAMES = { ground: 'Terrestre', grass: 'Afinidad con hierba', swim: 'Acuático', fly: 'Volador' } as const;
export const TACTICAL_BOARD: Board = [
  [0, 0, 1, 0, 0, 0, 2, 0],
  [0, 1, 1, 0, 3, 0, 0, 2],
  [0, 1, 2, 0, 3, 1, 0, 0],
  [0, 0, 2, 0, 3, 1, 3, 0],
  [0, 1, 2, 0, 3, 0, 3, 0],
  [0, 0, 0, 0, 1, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 1, 0],
  [0, 0, 0, 0, 0, 0, 0, 0],
];
export const blocksSight = (board: Board, point: Point): boolean => ![0, 1, 3].includes(board[point.y]?.[point.x]);
export const supportsEmbers = (board: Board, point: Point): boolean => [0, 1].includes(board[point.y]?.[point.x]);
export function fieldDamage(unit: Combatant, fields: readonly TerrainField[]): number {
  return unit.types.includes('fire') || unit.profile === 'fly' || heldItemFor(unit.heldItem)?.blocksEmbers() ? 0 : fields.some(field => same(field, unit)) ? 4 : 0;
}
