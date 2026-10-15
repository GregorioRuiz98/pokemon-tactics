import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { bossTrial } from '../src/data/encounters.ts';
import { zoneDamage } from '../src/rules/hazards.ts';
import { createRun, enterRoom, leaveService, availableNodes, performRunEvent, completeEncounter, withBattle } from '../src/rules/run.ts';
import { validateRun } from '../src/data/run-store.ts';
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
test('psychic finale has two complementary enemies and terminates with a developed team',()=>{
  let b=bossTrial(catalog,'psychic');assert.deepEqual(b.units.filter(u=>u.team==='enemy').map(u=>u.speciesId),[150,151]);
  assert(pokemonFor(151).movement>pokemonFor(150).movement);
  for(let i=0;i<2000&&b.outcome==='playing';i++){const r=applyCommand(b,chooseTacticalCommand(b)!);assert(r.ok);b=r.state;}
  assert.equal(b.outcome,'victory');
  for(const id of [150,151])assert.throws(()=>pokemonFor(id).createCombatant(catalog.find(p=>p.id===id)!,'ally',{x:0,y:0}));
});
test('both destination choices survive replay, exclude the other finale and cannot pay twice',()=>{
  for(const destination of ['final-birds','final-psychic']) {
    let run=createRun(catalog,'choice',.05,9);
    // Synthetic receipts isolate route/persistence; boss combats above use real commands.
    for(let floor=0;floor<6;floor++) {
      run=leaveService(enterRoom(run,'shop-'+floor,catalog),catalog);
      run=enterRoom(run,availableNodes(run)[0].id,catalog);
      run=performRunEvent(run,{kind:'result',nodeId:run.currentNodeId!,outcome:'victory',round:1,hp:run.roster.map(m=>({id:m.id,hp:m.hp})),contribution:run.roster.map(m=>({id:m.id,points:0}))},catalog);
    }
    run=leaveService(enterRoom(run,'shop-6',catalog),catalog);
    assert.equal(availableNodes(run).length,2);
    run=enterRoom(run,destination,catalog);assert.deepEqual(validateRun(run,catalog),run);
    assert.throws(()=>enterRoom(run,destination==='final-birds'?'final-psychic':'final-birds',catalog));
    const b=structuredClone(run.battle!);b.units.filter(u=>u.team==='enemy').forEach(u=>{u.hp=0;});b.outcome='victory';b.queue=[];
    run=completeEncounter(withBattle(run,b),catalog);assert.equal(run.status,'victory');assert.equal(run.history.length,7);
    assert.equal(availableNodes(run).length,0);assert.throws(()=>completeEncounter(run,catalog));assert.deepEqual(validateRun(run,catalog),run);
  }
});
