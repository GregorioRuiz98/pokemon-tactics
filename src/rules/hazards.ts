import type { Combatant } from '../domain/combatant.ts';
import type { Point } from './movement.ts';
import { same } from './movement.ts';
export type BoardHazard = Point & { kind: 'ice' | 'electric' | 'fire' | 'poison' | 'psychic' | 'ground' };
export const HAZARD_NAMES = { ice: 'Escarcha', electric: 'Corriente', fire: 'Fumarola', poison: 'Miasma', psychic: 'Pulso', ground: 'Arena' };
export const HAZARD_IMMUNITY: Record<BoardHazard['kind'], string[]> = {
  ice: ['ice'], electric: ['electric', 'ground'], fire: ['fire'], poison: ['poison', 'steel'], psychic: ['psychic', 'dark'], ground: ['ground', 'rock', 'steel'],
};
export function zoneDamage(unit: Combatant, zones: readonly BoardHazard[] = [], round = 1): number {
  const zone = zones.find(point => same(point, unit));
  return round < 2 || !zone || unit.profile === 'fly' || HAZARD_IMMUNITY[zone.kind].some(type => unit.types.includes(type as typeof unit.types[number])) ? 0 : 4;
}
