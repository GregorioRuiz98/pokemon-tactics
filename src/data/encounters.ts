import type { PokemonSpecies } from './catalog.ts';
import { runMap } from './run-maps.ts';
import { atLevel } from '../domain/progression.ts';
import { pokemonFor } from '../domain/Pokemon.ts';
import { createEncounter } from '../rules/battle.ts';
import { ZONES } from './zones.ts';
import { INITIAL_SPECIES } from './catalog.ts';
export function mapTrial(catalog: readonly PokemonSpecies[], id: string, seed = 'map-trial') {
  const zone = ZONES.find(zone=>zone.maps.includes(id));
  if (!zone) throw new Error('Escenario de ensayo desconocido.');
  const map = runMap(id), enemies = zone.enemies[zone.maps.indexOf(id)];
  return createEncounter(catalog, seed, .05, map.board, INITIAL_SPECIES.map((speciesId,index)=>({id:index+1,speciesId,
    hp:pokemonFor(speciesId).createCombatant(catalog.find(p=>p.id===speciesId)!,'ally',{x:0,y:0}).maxHp})), enemies, {hazards:map.hazards});
}
export function bossTrial(catalog: readonly PokemonSpecies[], id: 'birds' | 'psychic', seed = 'boss-trial', speciesIds = [3,6,9,26,12,76]) {
  const map = runMap(id);
  const allies = speciesIds.map((speciesId,index) => ({ id:index+1, speciesId, xp:120, heldItem:null,
    hp: atLevel(pokemonFor(speciesId).createCombatant(catalog.find(p=>p.id===speciesId)!, 'ally', {x:0,y:0}),3).maxHp }));
  return createEncounter(catalog, seed, .05, map.board, allies, id === 'birds' ? [144,145,146] : [150,151], {progression:true,hazards:map.hazards});
}
