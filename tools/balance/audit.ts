import { readFileSync, writeFileSync, readdirSync, mkdirSync, existsSync } from 'node:fs';
import { resolve, relative } from 'node:path';
import { gzipSync, gunzipSync } from 'node:zlib';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { campaign, itemProbe, POLICIES, catalog } from './campaign.ts';
import type { FightMetric } from './telemetry.ts';
import { mean, sum, quantile, wilson, pairedInterval } from './statistics.ts';
type Campaign = ReturnType<typeof campaign>;
const count=Number(process.env.BALANCE_SEEDS??200),microCount=Number(process.env.BALANCE_MICRO_SEEDS??100);
assert(Number.isInteger(count)&&count>0&&count<=2000);assert(Number.isInteger(microCount)&&microCount>0&&microCount<=2000);
const output=resolve(process.env.BALANCE_OUT??'docs/reports/balance-2026-10-15');mkdirSync(output,{recursive:true});
const env={...process.env,GIT_CONFIG_GLOBAL:process.platform==='win32'?'NUL':'/dev/null',GIT_CONFIG_NOSYSTEM:'1'};
const sourceCommit=execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8',env}).trim();
function sourceHashes(directory:string):Record<string,string> {
  const hashes:Record<string,string>={};
  for(const entry of readdirSync(directory,{withFileTypes:true})) {
    const path=resolve(directory,entry.name);
    if(entry.isDirectory())Object.assign(hashes,sourceHashes(path));
    else hashes[relative(process.cwd(),path).replaceAll('\\','/')]=createHash('sha256').update(readFileSync(path)).digest('hex');
  }
  return hashes;
}
const hashes=sourceHashes('src');
const previous=process.env.BALANCE_REUSE==='1'&&existsSync(resolve(output,'summary.json'))?JSON.parse(readFileSync(resolve(output,'summary.json'),'utf8')):null;
if(previous){assert.deepEqual(previous.metadata.sourceHashes,hashes);assert.equal(previous.metadata.seeds,count);}
const results:Campaign[]=[];
for(const policy of POLICIES) {
  const cache=resolve(output,`${policy.id}.json.gz`);
  if(previous&&existsSync(cache)&&previous.metadata.policies.some((p:{id:string})=>p.id===policy.id)){
    assert.deepEqual(previous.metadata.policies.find((p:{id:string})=>p.id===policy.id),policy);
    const cached:Campaign[]=JSON.parse(gunzipSync(readFileSync(cache)).toString('utf8'));
    assert.equal(cached.length,count);cached.forEach((row,i)=>{assert.equal(row.seed,`balance-v012-${i}`);assert.equal(row.policy,policy.id);});
    assert.deepEqual(campaign(cached[0].seed,policy),cached[0]);results.push(...cached);console.log(`${policy.id}: reusing ${count} validated seed results`);continue;
  }
  const rows:Campaign[]=[];
  for(let seed=0;seed<count;seed++) {
    rows.push(campaign(`balance-v012-${seed}`,policy));
    if((seed+1)%40===0||seed===count-1)console.log(`${policy.id}: ${seed+1}/${count}`);
  }
  results.push(...rows);
  writeFileSync(resolve(output,`${policy.id}.json.gz`),gzipSync(JSON.stringify(rows)));
}
const allFights=(run:Campaign):FightMetric[]=>[...run.fights,...Object.values(run.finals).filter((fight):fight is NonNullable<typeof fight>=>fight!==null)];
const aggregateFight=(fights:FightMetric[])=>{
  const units=fights.flatMap(f=>f.units),allies=units.filter(u=>u.team==='ally');
  return {n:fights.length,unresolved:fights.filter(f=>f.outcome==='playing').length,wins:fights.filter(f=>f.outcome==='victory').length,
    rounds:mean(fights.map(f=>f.rounds)),medianRounds:quantile(fights.map(f=>f.rounds),.5),p90Rounds:quantile(fights.map(f=>f.rounds),.9),
    startingAllies:mean(fights.map(f=>f.allies)),deaths:sum(allies.map(u=>Number(u.endHp===0))),
    deathsPerFight:mean(fights.map(f=>f.units.filter(u=>u.team==='ally'&&u.endHp===0).length)),
    hpAtEntry:mean(allies.map(u=>u.startHp/u.maxHp)),damageReceived:sum(allies.map(u=>u.received)),
    friendlyReceived:sum(allies.map(u=>u.friendlyReceived)),drain:sum(allies.map(u=>u.drain)),leftovers:sum(allies.map(u=>u.leftovers)),
    vestPrevented:sum(allies.map(u=>u.vestPrevented)),bootsPrevented:sum(allies.map(u=>u.bootsPrevented)),
    incomingHits:sum(allies.map(u=>u.incomingHits)),fullHpHits:sum(allies.map(u=>u.fullHpHits)),oneHits:sum(allies.map(u=>u.oneHits)),
    diedBeforeActivation:allies.filter(u=>u.diedBeforeActivation).length,
    deathsBeforeFirstCommand:sum(fights.map(f=>f.alliedDeathsBeforeFirstCommand)),
    statusDamage:sum(allies.map(u=>u.statusDamage)),fieldDamage:sum(allies.map(u=>u.fieldDamage)),zoneDamage:sum(allies.map(u=>u.zoneDamage))};
};
const baseline=results.filter(r=>r.policy==='six');
const overall=(run:Campaign)=>mean(['birds','psychic'].map(id=>Number(run.finals[id]?.outcome==='victory')));
const summaries=POLICIES.map(policy=>{
  const rows=results.filter(r=>r.policy===policy.id),reached=rows.filter(r=>r.reachedFinal);
  const finals=Object.fromEntries(['birds','psychic'].map(destination=>{
    const wins=rows.filter(r=>r.finals[destination]?.outcome==='victory').length;
    const fights=reached.map(r=>r.finals[destination]!);
    return [destination,{...aggregateFight(fights),total:rows.length,rate:wins/rows.length,ci:wilson(wins,rows.length),conditionalRate:reached.length?wins/reached.length:0,conditionalCI:wilson(wins,reached.length)}];
  }));
  return {id:policy.id,label:policy.label,n:rows.length,reached:reached.length,reachRate:reached.length/rows.length,finals,
    averageWin:mean(rows.map(overall)),differenceVsSix:mean(rows.map((r,i)=>overall(r)-overall(baseline[i]))),differenceCI:pairedInterval(rows.map((r,i)=>overall(r)-overall(baseline[i]))),
    meanClearedZones:mean(rows.map(r=>r.fights.filter(f=>f.outcome==='victory').length)),
    meanRecruits:mean(rows.map(r=>r.management.recruits)),meanEvolutions:mean(rows.map(r=>r.management.evolutions)),
    meanMoneyAtStop:mean(rows.map(r=>r.money)),meanFinalMembers:mean(reached.map(r=>r.checkpoint.length)),
    meanFinalLevel:mean(reached.flatMap(r=>r.checkpoint.map(m=>m.level))),
    unresolvedCampaigns:rows.filter(r=>r.unresolvedRun).length,healing:sum(rows.map(r=>r.management.healed)),nominalHealing:sum(rows.map(r=>r.management.nominalHealing)),
    healingWaste:sum(rows.map(r=>r.management.nominalHealing-r.management.healed)),healingSpend:sum(rows.map(r=>r.management.spentHealing)),
    gearSpend:sum(rows.map(r=>r.management.spentGear)),evolutionSpend:sum(rows.map(r=>r.management.spentEvolution)),
    equippedCampaigns:rows.filter(r=>r.management.equipOperations>0).length,
    combats:aggregateFight(rows.flatMap(allFights)),
    examples:{birds:rows.filter(r=>r.finals.birds?.outcome==='victory').slice(0,4).map(r=>r.seed),psychic:rows.filter(r=>r.finals.psychic?.outcome==='victory').slice(0,4).map(r=>r.seed),earlyDefeat:rows.filter(r=>r.fights.length<=2&&!r.reachedFinal).slice(0,4).map(r=>r.seed)},
  };
});
const maps=[...new Set(baseline.flatMap(r=>r.fights.map(f=>f.mapId)))].map(mapId=>({mapId,...aggregateFight(baseline.flatMap(r=>r.fights.filter(f=>f.mapId===mapId)))}));
const floors=Array.from({length:8},(_,i)=>({floor:i+1,...aggregateFight(baseline.flatMap(r=>r.fights.filter(f=>f.floor===i+1)))}));
const species=Object.fromEntries(['ally','enemy'].map(team=>{
  const units=results.flatMap(r=>allFights(r).flatMap(f=>f.units)).filter(u=>u.team===team);
  return [team,[...new Set(units.map(u=>u.speciesId))].map(id=>{
    const rows=units.filter(u=>u.speciesId===id),activations=sum(rows.map(u=>u.activations));
    return {id,name:catalog.find(p=>p.id===id)!.name,appearances:rows.length,activations,deaths:rows.filter(u=>u.endHp===0).length,
      damage:sum(rows.map(u=>u.dealt)),damagePerActivation:activations?sum(rows.map(u=>u.dealt))/activations:0,
      healing:sum(rows.map(u=>u.drain+u.leftovers)),statusApplied:sum(rows.map(u=>u.statusApplied)),guards:sum(rows.map(u=>u.guards)),
      entryHp:mean(rows.map(u=>u.startHp/u.maxHp)),beforeActivation:rows.filter(u=>u.diedBeforeActivation).length,
      statusDamage:sum(rows.map(u=>u.statusDamage)),zoneDamage:sum(rows.map(u=>u.zoneDamage)),oneHits:sum(rows.map(u=>u.oneHits))};
  }).sort((a,b)=>b.damagePerActivation-a.damagePerActivation)];
}));
const actionRows=results.flatMap(r=>allFights(r).flatMap(f=>f.actions));
const actions=[...new Set(actionRows.map(a=>`${a.team}:${a.speciesId}:${a.actionId}`))].map(key=>{
  const rows=actionRows.filter(a=>`${a.team}:${a.speciesId}:${a.actionId}`===key),first=rows[0];
  return {...first,uses:sum(rows.map(a=>a.uses)),rolls:sum(rows.map(a=>a.rolls)),hits:sum(rows.map(a=>a.hits)),misses:sum(rows.map(a=>a.misses)),damage:sum(rows.map(a=>a.damage)),collateral:sum(rows.map(a=>a.collateral)),kills:sum(rows.map(a=>a.kills)),drain:sum(rows.map(a=>a.drain)),statusApplied:sum(rows.map(a=>a.statusApplied)),guards:sum(rows.map(a=>a.guards))};
});
const initialTeams=[...new Set(baseline.map(r=>r.initial.map(m=>m.speciesId).sort((a,b)=>a-b).join('-')))].map(key=>{
  const rows=baseline.filter(r=>r.initial.map(m=>m.speciesId).sort((a,b)=>a-b).join('-')===key);
  return {key,n:rows.length,reach:rows.filter(r=>r.reachedFinal).length,win:mean(rows.map(overall))};
}).sort((a,b)=>b.win-a.win);
const pairedFinals={n:baseline.filter(r=>r.reachedFinal).length,
  birdOnly:baseline.filter(r=>r.finals.birds?.outcome==='victory'&&r.finals.psychic?.outcome==='defeat').length,
  psychicOnly:baseline.filter(r=>r.finals.psychic?.outcome==='victory'&&r.finals.birds?.outcome==='defeat').length,
  difference:mean(baseline.map(r=>Number(r.finals.birds?.outcome==='victory')-Number(r.finals.psychic?.outcome==='victory'))),
  ci:pairedInterval(baseline.map(r=>Number(r.finals.birds?.outcome==='victory')-Number(r.finals.psychic?.outcome==='victory')))};
const reuseMicro=previous&&previous.micro.length===16&&previous.micro.every((m:{n:number})=>m.n===microCount);
const micro=reuseMicro?[...previous.micro]:[];
if(!reuseMicro)for(const ids of [[3,9,76],[3,6,9,26]])for(const destination of ['birds','psychic'] as const) {
  const byItem:Record<string,FightMetric[]>={none:[],leftovers:[],'assault-vest':[],'heavy-duty-boots':[]};
  for(let i=0;i<microCount;i++)for(const item of [null,'leftovers','assault-vest','heavy-duty-boots'] as const)byItem[item??'none'].push(itemProbe(`item-probe-${i}`,destination,ids,item));
  for(const [item,fights] of Object.entries(byItem))micro.push({composition:ids.join('-'),destination,item,...aggregateFight(fights),differenceVsNone:mean(fights.map((f,i)=>Number(f.outcome==='victory')-Number(byItem.none[i].outcome==='victory'))),differenceCI:pairedInterval(fights.map((f,i)=>Number(f.outcome==='victory')-Number(byItem.none[i].outcome==='victory')))});
  console.log(`item probe: ${ids.join('-')} / ${destination}`);
}
assert.deepEqual(sourceHashes('src'),hashes,'Gameplay sources changed during audit');
const metadata={release:'0.12.0',edition:14,variance:.05,sourceCommit,sourceHashes:hashes,seeds:count,policies:POLICIES,prefixes:results.length,finalTrials:results.reduce((total,r)=>total+Number(r.reachedFinal)*2,0),prefixBattles:results.reduce((total,r)=>total+r.fights.length,0),microBattles:microCount*16,unresolvedPrefix:results.filter(r=>r.fights.some(f=>f.outcome==='playing')).length,unresolvedFinals:results.reduce((sum,r)=>sum+Object.values(r.finals).filter(f=>f?.outcome==='playing').length,0),invalidSaves:0,roundCap:100,commandCap:3000,catalogSha256:createHash('sha256').update(readFileSync('public/data/pokemon.json')).digest('hex'),seedPrefix:'balance-v012-',bootstrapResamples:1500};
writeFileSync(resolve(output,'summary.json'),JSON.stringify({metadata,policies:summaries,floors,maps,species,actions,initialTeams,pairedFinals,micro},null,2)+'\n');
const header='policy,seed,reached_final,zones_won,birds,psychic,money,healed,healing_waste,recruits,evolutions,gear_spent';
writeFileSync(resolve(output,'campaigns.csv'),header+'\n'+results.map(r=>[r.policy,r.seed,Number(r.reachedFinal),r.fights.filter(f=>f.outcome==='victory').length,r.finals.birds?.outcome??'not_reached',r.finals.psychic?.outcome??'not_reached',r.money,r.management.healed,r.management.nominalHealing-r.management.healed,r.management.recruits,r.management.evolutions,r.management.spentGear].join(',')).join('\n')+'\n');
const unresolved=results.filter(r=>r.unresolvedRun).map(r=>({seed:r.seed,policy:r.policy,node:r.unresolvedRun!.currentNodeId,battleSeed:r.unresolvedRun!.battle!.seed,round:r.unresolvedRun!.battle!.round,units:r.unresolvedRun!.battle!.units.map(u=>({speciesId:u.speciesId,team:u.team,hp:u.hp,x:u.x,y:u.y})),log:r.unresolvedRun!.battle!.log}));
writeFileSync(resolve(output,'unresolved.json'),JSON.stringify(unresolved,null,2)+'\n');
for(const [index,r] of results.filter(r=>r.unresolvedRun).slice(0,3).entries())writeFileSync(resolve(output,`unresolved-save-${index+1}.json`),JSON.stringify({schema:'pokemon-tactics/run',version:3,run:r.unresolvedRun},null,2)+'\n');
console.log('DONE '+JSON.stringify(metadata,(_key,value)=>_key==='sourceHashes'?undefined:value));
