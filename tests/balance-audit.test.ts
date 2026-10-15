import test from 'node:test';
import assert from 'node:assert/strict';
import { mean, quantile, wilson, pairedInterval } from '../tools/balance/statistics.ts';
import { campaign, POLICIES, catalog } from '../tools/balance/campaign.ts';
import { simulateFight } from '../tools/balance/telemetry.ts';
import { mapTrial } from '../src/data/encounters.ts';

test('audit intervals handle empty samples, boundaries and paired identical outcomes',()=>{
  assert.equal(wilson(0,0),null);
  assert(wilson(0,20)![0] <= 1e-12); assert.equal(wilson(20,20)![1],1);
  const interval=wilson(50,100)!;assert(interval[0]<.5&&interval[1]>.5);assert(Math.abs(interval[0]+interval[1]-1)<1e-12);
  assert.deepEqual(pairedInterval([0,0,0]),[0,0]);assert.deepEqual(pairedInterval([.5,.5,.5]),[.5,.5]);
  assert.equal(mean([2,4,6]),4);assert.equal(quantile([0,10],.5),5);
});
test('observational telemetry preserves real battle resolution and accounts for each HP change',()=>{
  const initial=mapTrial(catalog,'quarry','audit-test'),before=structuredClone(initial);
  const a=simulateFight(initial),b=simulateFight(initial);
  assert.deepEqual(initial,before);assert.deepEqual(a,b);
  assert.notEqual(a.metrics.outcome,'playing');
  for(const unit of a.metrics.units)assert.equal(unit.startHp-unit.received-unit.statusDamage-unit.fieldDamage-unit.zoneDamage+unit.drain+unit.leftovers,unit.endHp);
});
test('campaign policies are reproducible and both finales use the same entered-party checkpoint',()=>{
  const policy=POLICIES.find(p=>p.id==='six')!;
  const a=campaign('balance-v012-0',policy),b=campaign('balance-v012-0',policy);assert.deepEqual(a,b);
  assert(a.reachedFinal);assert.equal(a.branches.length,8);
  for(const destination of ['birds','psychic'])assert.deepEqual(a.finals[destination]!.units.filter(u=>u.team==='ally').map(u=>({id:u.id,speciesId:u.speciesId,hp:u.startHp,held:u.held})),a.checkpoint.map(m=>({id:m.id,speciesId:m.speciesId,hp:m.hp,held:m.heldItem})));
});
