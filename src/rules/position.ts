import type { Facing, Point } from './movement.ts';
export const FACINGS = [4, 2, 0, 6] as const;
export const FACING_NAMES: Record<Facing, string> = { 4: 'Norte', 2: 'Este', 0: 'Sur', 6: 'Oeste' };
export const FACING_ARROWS: Record<Facing, string> = { 4: '↑', 2: '→', 0: '↓', 6: '←' };
export const FACING_VECTORS: Record<Facing, Point> = { 4: { x: 0, y: -1 }, 2: { x: 1, y: 0 }, 0: { x: 0, y: 1 }, 6: { x: -1, y: 0 } };
export type AttackSide = 'front' | 'flank' | 'rear';
export const SIDE_NAMES: Record<AttackSide, string> = { front: 'Frente', flank: 'Flanco', rear: 'Espalda' };
export function attackSide(origin: Point, target: Point & {
  facing: Facing;
}): AttackSide {
  const vector = FACING_VECTORS[target.facing];
  const dx = origin.x - target.x, dy = origin.y - target.y;
  const forward = dx * vector.x + dy * vector.y;
  const lateral = dx * vector.y - dy * vector.x;
  // Diagonal ties belong to the facing axis: front or rear, never a hidden random tie.
  return Math.abs(forward) >= Math.abs(lateral) ? forward >= 0 ? 'front' : 'rear' : 'flank';
}
export const positionalAccuracy = (base: number, side: AttackSide): number => Math.max(5, Math.min(100, base - (side === 'front' ? 15 : side === 'flank' ? 5 : 0)));
