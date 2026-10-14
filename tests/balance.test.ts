import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { pokemonFor } from '../src/domain/Pokemon.ts';
const catalog = validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json',import.meta.url),'utf8')));
test('sprint 4 HP, move definitions, powers and all target previews remain exactly unchanged', () => {
  const fixture = JSON.parse(readFileSync(new URL('./fixtures/combat-v0.4.json', import.meta.url), 'utf8'));
  const actual = catalog.map(species => {
    const profile = pokemonFor(species.id), actor = profile.createCombatant(species, 'ally', { x:0,y:0 });
    return { speciesId: species.id, maxHp: actor.maxHp, actions: profile.actions.map(action => ({
      definition: action.definition,
      power: 'power' in action ? action.power : null,
      category: 'category' in action ? action.category : null,
      previews: catalog.filter(p => p.id !== species.id).map(target => ({ speciesId:target.id, effect:action.preview(actor,pokemonFor(target.id).createCombatant(target,'enemy',{x:1,y:0})) })),
    })) };
  });
  assert.deepEqual(actual, fixture);
});
