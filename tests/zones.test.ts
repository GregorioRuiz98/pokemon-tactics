import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { ZONES } from '../src/data/zones.ts';
import { validateCatalog } from '../src/data/catalog.ts';
import { runMap } from '../src/data/run-maps.ts';
import { mapTrial } from '../src/data/encounters.ts';
import { applyCommand, chooseTacticalCommand } from '../src/rules/battle.ts';
import { tileCost } from '../src/rules/movement.ts';
import { createRun, enterRoom, leaveService, availableNodes, performRunEvent } from '../src/rules/run.ts';
import { validateRun } from '../src/data/run-store.ts';
const catalog=validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json',import.meta.url),'utf8')));
for(const zone of ZONES) test(zone.name+': both maps deploy legally and complete using real tactical commands',()=>{
  assert.equal(new Set(zone.maps).size,2);
  for(const mapId of zone.maps) {
    let b=mapTrial(catalog,mapId);assert.equal(b.board.length,8);assert(b.board.every(row=>row.length===8));
    b.units.forEach(unit=>assert(Number.isFinite(tileCost(b.board,unit,unit.profile))));
    assert((runMap(mapId).hazards??[]).every(point=>[0,1].includes(b.board[point.y][point.x])));
    for(let i=0;i<2000&&b.outcome==='playing';i++){const r=applyCommand(b,chooseTacticalCommand(b)!);assert(r.ok);b=r.state;}
    assert.notEqual(b.outcome,'playing');
  }
});
test('campaign editions preserve ordered gym themes, two maps per zone and exclusive finales',()=>{
  for(let edition=10;edition<=13;edition++) {
    let run=createRun(catalog,'themes',.05,edition);const count=Math.min(ZONES.length,(edition-9)*2);
    for(let floor=0;floor<count;floor++) {
      run=leaveService(enterRoom(run,'shop-'+floor,catalog),catalog);
      const choices=availableNodes(run);assert.deepEqual(choices.map(n=>n.mapId),ZONES[floor].maps);
      run=enterRoom(run,choices[0].id,catalog);
      run=performRunEvent(run,{kind:'result',nodeId:run.currentNodeId!,outcome:'victory',round:1,hp:run.roster.map(m=>({id:m.id,hp:m.hp})),contribution:run.roster.map(m=>({id:m.id,points:0}))},catalog);
      assert.deepEqual(validateRun(run,catalog),run);
    }
    run=leaveService(enterRoom(run,'shop-'+count,catalog),catalog);
    assert.deepEqual(new Set(availableNodes(run).map(n=>n.mapId)),new Set(['birds','psychic']));
  }
});
