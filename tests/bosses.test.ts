import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { bossTrial } from '../src/data/encounters.ts';
import { zoneDamage } from '../src/rules/hazards.ts';
import { createRun } from '../src/rules/run.ts';
import { applyCommand, chooseTacticalCommand } from '../src/rules/battle.ts';
import { pokemonFor } from '../src/domain/Pokemon.ts';
const catalog=validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json',import.meta.url),'utf8')));
test('three birds deploy together, have distinct kits and cannot be created as allies or recruited',()=>{
  const battle=bossTrial(catalog,'birds');assert.deepEqual(battle.units.filter(u=>u.team==='enemy').map(u=>u.speciesId),[144,145,146]);
  assert.equal(new Set([144,145,146].map(id=>pokemonFor(id).actions[1].definition.id)).size,3);
  for(const id of [144,145,146]) assert.throws(()=>pokemonFor(id).createCombatant(catalog.find(p=>p.id===id)!,'ally',{x:0,y:0}));
  for(let i=0;i<30;i++) {const run=createRun(catalog,'boss-'+i,.05,8);assert(run.roster.every(m=>m.speciesId<144));assert(run.nodes.flatMap(n=>n.offers).every(o=>o.speciesId<144));}
});
test('arena hazards are dormant in round one and do not hit any allied deployment tile',()=>{
  const b=bossTrial(catalog,'birds');for(const unit of b.units.filter(u=>u.team==='ally')) {assert.equal(zoneDamage(unit,b.hazards,1),0);assert.equal(zoneDamage(unit,b.hazards,2),0);}
  const unit={...b.units[0],x:1,y:2,profile:'ground' as const,types:['normal' as const]};assert.equal(zoneDamage(unit,b.hazards,1),0);assert.equal(zoneDamage(unit,b.hazards,2),4);
});
test('bird encounters terminate deterministically with several compositions, including a defeat',()=>{
  const outcomes=[];
  for(const ids of [[3,6,9,26,12,76],[3,9,76],[1]]) {
    let b=bossTrial(catalog,'birds','boss-test',ids);
    for(let i=0;i<2000&&b.outcome==='playing';i++){const r=applyCommand(b,chooseTacticalCommand(b)!);assert(r.ok);b=r.state;}
    assert.notEqual(b.outcome,'playing');outcomes.push(b.outcome);
  }
  assert(outcomes.includes('victory'));assert(outcomes.includes('defeat'));
});
