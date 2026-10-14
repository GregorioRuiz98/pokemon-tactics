import type { Unit } from '../rules/movement.ts';
import type { PokemonType } from '../data/type-chart.ts';
import type { HeldItemId } from './items.ts';
export type Team = 'ally' | 'enemy';
export type StatusKind = 'poison' | 'burn' | 'paralysis';
export type MajorStatus = {
  kind: StatusKind;
  remaining: number;
};
// Values only: class instances never enter a save/replay snapshot.
export type Combatant = Unit & {
  speciesId: number;
  heldItem: HeldItemId | null;
  name: string;
  team: Team;
  types: PokemonType[];
  hp: number;
  maxHp: number;
  attack: number;
  defense: number;
  specialAttack: number;
  specialDefense: number;
  speed: number;
  range: number;
  tp: number;
  maxTp: number;
  status: MajorStatus | null;
  guarded: boolean;
};
export const STATUS_NAMES: Record<StatusKind, string> = { poison: 'Veneno', burn: 'Quemadura', paralysis: 'Parálisis' };
export const effectiveSpeed = (unit: Combatant): number => unit.speed * (unit.status?.kind === 'paralysis' ? 0.5 : 1);
export const movementBudget = (unit: Combatant): number => unit.status?.kind === 'paralysis' ? Math.max(1, Math.floor(unit.budget / 2)) : unit.budget;
export function statusImmunity(unit: Combatant, kind: StatusKind): string | null {
  if (kind === 'poison' && unit.types.some(type => type === 'poison' || type === 'steel'))
    return 'Inmune al veneno por su tipo.';
  if (kind === 'burn' && unit.types.includes('fire'))
    return 'Inmune a quemadura por su tipo.';
  if (kind === 'paralysis' && unit.types.includes('electric'))
    return 'Inmune a parálisis por su tipo.';
  if (unit.status)
    return 'Ya tiene un estado principal.';
  return null;
}
