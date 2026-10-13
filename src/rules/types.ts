import { POKEMON_TYPES, TYPE_CHART } from '../data/type-chart.ts';
import type { PokemonType } from '../data/type-chart.ts';
export function effectiveness(attack: PokemonType, defenders: readonly PokemonType[]): number {
  const row = TYPE_CHART[POKEMON_TYPES.indexOf(attack)];
  if (!row || defenders.length < 1 || defenders.length > 2 || new Set(defenders).size !== defenders.length)
    throw new Error('Tipos de combate no válidos.');
  return defenders.reduce((multiplier, type) => {
    const factor = row[POKEMON_TYPES.indexOf(type)];
    if (factor === undefined)
      throw new Error('Tipo desconocido.');
    return multiplier * factor;
  }, 1);
}
