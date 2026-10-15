import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { gunzipSync } from 'node:zlib';
import { createHash } from 'node:crypto';
import type { campaign } from './campaign.ts';
const root=resolve(process.argv[2]??'docs/reports/balance-2026-10-15');
const summary=JSON.parse(readFileSync(resolve(root,'summary.json'),'utf8'));
type Campaign=ReturnType<typeof campaign>;
let prefixes=0,battles=0,finals=0,unresolved=0;
const seeds=new Map<string,{branches:number[];initial:Campaign['initial']}>();
for(const policy of summary.policies) {
  const rows:Campaign[]=JSON.parse(gunzipSync(readFileSync(resolve(root,policy.id+'.json.gz'))).toString('utf8'));
  assert.equal(rows.length,summary.metadata.seeds);prefixes+=rows.length;
  assert.equal(rows.filter(r=>r.reachedFinal).length,policy.reached);
  for(const destination of ['birds','psychic'])assert.equal(rows.filter(r=>r.finals[destination]?.outcome==='victory').length,policy.finals[destination].wins);
  for(const row of rows) {
    assert.equal(row.policy,policy.id);
    const plan={branches:row.branches,initial:row.initial};
    if(seeds.has(row.seed))assert.deepEqual(plan,seeds.get(row.seed));else seeds.set(row.seed,plan);
    assert(row.fights.every(f=>f.allies<=summary.metadata.policies.find((p:{id:string})=>p.id===policy.id).limit));
    battles+=row.fights.length;unresolved+=Number(row.fights.some(f=>f.outcome==='playing'));
    for(const fight of Object.values(row.finals))if(fight) {
      finals++;assert(row.reachedFinal);
      assert.deepEqual(fight.units.filter(u=>u.team==='ally').map(u=>({id:u.id,speciesId:u.speciesId,hp:u.startHp,held:u.held})),row.checkpoint.map(m=>({id:m.id,speciesId:m.speciesId,hp:m.hp,held:m.heldItem})));
    }
    for(const fight of [...row.fights,...Object.values(row.finals).filter(f=>f!==null)])for(const u of fight!.units)assert.equal(u.startHp-u.received-u.statusDamage-u.fieldDamage-u.zoneDamage+u.drain+u.leftovers,u.endHp);
  }
}
assert.equal(prefixes,summary.metadata.prefixes);assert.equal(battles,summary.metadata.prefixBattles);assert.equal(finals,summary.metadata.finalTrials);assert.equal(unresolved,summary.metadata.unresolvedPrefix);
for(const [path,hash] of Object.entries(summary.metadata.sourceHashes))assert.equal(createHash('sha256').update(readFileSync(path)).digest('hex'),hash,path);
assert.equal(createHash('sha256').update(readFileSync('public/data/pokemon.json')).digest('hex'),summary.metadata.catalogSha256);
console.log(`Verified ${prefixes} campaign prefixes, ${battles} zone battles and ${finals} paired finales; HP accounting, raw aggregates and gameplay source hashes match.`);
