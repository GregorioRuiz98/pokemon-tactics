import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { gunzipSync } from 'node:zlib';
import assert from 'node:assert/strict';
import { createRun, encounterSeed } from '../../src/rules/run.ts';
import { createEncounter, hashSeed, random } from '../../src/rules/battle.ts';
import { runMap } from '../../src/data/run-maps.ts';
import { catalog } from './campaign.ts';
import { simulateFight } from './telemetry.ts';
import { mean, wilson, pairedInterval } from './statistics.ts';
const root=resolve(process.argv[2]??'docs/reports/balance-2026-10-15');
const references=JSON.parse(gunzipSync(readFileSync(resolve(root,'trio.json.gz'))).toString('utf8'));
const results:{seed:string;variant:string;mapId:string;outcome:'playing'|'victory'|'defeat';rounds:number;deaths:number}[]=[];
for(let index=0;index<references.length;index++) {
  const seed=`balance-v012-${index}`,run=createRun(catalog,seed,.05,14);
  const branch=Math.floor(random({rng:hashSeed(`audit-route:${seed}`)})*2);
  const node=run.nodes.find(n=>n.id===`zone-1-${branch+1}`)!;
  for(const variant of ['current','two-enemies','no-graveler'] as const) {
    const enemies=variant==='two-enemies'?node.enemies.filter(id=>id!==75):variant==='no-graveler'?node.enemies.map(id=>id===75?74:id):node.enemies;
    const battle=createEncounter(catalog,encounterSeed(run,node.id),.05,runMap(node.mapId).board,run.roster,enemies,{progression:true,ruleset:14});
    const {metrics}=simulateFight(battle);
    if(variant==='current')assert.equal(metrics.outcome,references[index].fights[0].outcome,'Counterfactual control must reproduce current opening');
    results.push({seed,variant,mapId:node.mapId,outcome:metrics.outcome,rounds:metrics.rounds,deaths:metrics.units.filter(u=>u.team==='ally'&&u.endHp===0).length});
  }
}
const current=results.filter(r=>r.variant==='current');
const summary=['current','two-enemies','no-graveler'].map(variant=>{
  const rows=results.filter(r=>r.variant===variant),wins=rows.filter(r=>r.outcome==='victory').length;
  const delta=rows.map((r,i)=>Number(r.outcome==='victory')-Number(current[i].outcome==='victory'));
  return {variant,n:rows.length,wins,rate:wins/rows.length,ci:wilson(wins,rows.length),deaths:mean(rows.map(r=>r.deaths)),rounds:mean(rows.map(r=>r.rounds)),difference:mean(delta),differenceCI:pairedInterval(delta)};
});
writeFileSync(resolve(root,'opening-probe.json'),JSON.stringify({scope:'Isolated first fight with the original three starters; no changes to campaign rules or parameters',summary,results},null,2)+'\n');
console.log(JSON.stringify(summary));
