import type { Combatant } from './combatant.ts';

export const MAX_LEVEL = 5;
export const levelFor = (xp: number): number => Math.min(MAX_LEVEL, 1 + Math.floor(xp / 60));
export const xpToNext = (xp: number): number => levelFor(xp) === MAX_LEVEL ? 0 : levelFor(xp) * 60 - xp;
export function atLevel(unit: Combatant, level = 1): Combatant {
  if (!Number.isInteger(level) || level < 1 || level > MAX_LEVEL) throw new Error('Nivel no válido.');
  const gain = level - 1;
  return { ...unit, maxHp: unit.maxHp + gain * 5, hp: unit.hp + gain * 5,
    attack: unit.attack + gain * 4, defense: unit.defense + gain * 4,
    specialAttack: unit.specialAttack + gain * 4, specialDefense: unit.specialDefense + gain * 4 };
}
export const EVOLUTIONS: Readonly<Record<number, { target: number; item: 'rare-candy' | 'thunder-stone' }>> = {
  1: { target: 2, item: 'rare-candy' }, 2: { target: 3, item: 'rare-candy' },
  4: { target: 5, item: 'rare-candy' }, 5: { target: 6, item: 'rare-candy' },
  7: { target: 8, item: 'rare-candy' }, 8: { target: 9, item: 'rare-candy' },
  25: { target: 26, item: 'thunder-stone' },
  74: { target: 75, item: 'rare-candy' }, 75: { target: 76, item: 'rare-candy' },
};
