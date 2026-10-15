import type { PokemonSpecies } from './catalog.ts';
import { runMap } from './run-maps.ts';
import { atLevel } from '../domain/progression.ts';
import { pokemonFor } from '../domain/Pokemon.ts';
import { createEncounter } from '../rules/battle.ts';
export function bossTrial(catalog: readonly PokemonSpecies[], id: 'birds' | 'psychic', seed = 'boss-trial', speciesIds = [3,6,9,26,12,76]) {
  const map = runMap(id);
  const allies = speciesIds.map((speciesId,index) => ({ id:index+1, speciesId, xp:120, heldItem:null,
    hp: atLevel(pokemonFor(speciesId).createCombatant(catalog.find(p=>p.id===speciesId)!, 'ally', {x:0,y:0}),3).maxHp }));
  return createEncounter(catalog, seed, .05, map.board, allies, id === 'birds' ? [144,145,146] : [150,151], {progression:true,hazards:map.hazards});
}
