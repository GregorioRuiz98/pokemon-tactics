import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { RunStore, SAVE_KEY, SAVE_VERSION, LEGACY_BACKUP_KEY, validateRun } from '../src/data/run-store.ts';
import type { StorageLike } from '../src/data/run-store.ts';
import { createRun, enterRoom, enterEncounter, leaveService, availableNodes, completeEncounter, withBattle, performRunEvent, replayRun, VICTORY_REWARD, STARTING_MONEY } from '../src/rules/run.ts';
import type { Run, RunEvent } from '../src/rules/run.ts';
import { createRun as createLegacyRun, enterEncounter as enterLegacy, completeEncounter as completeLegacy, withBattle as withLegacyBattle } from '../src/rules/legacy-run.ts';
import { activeUnit, applyCommand, chooseTacticalCommand } from '../src/rules/battle.ts';
const catalog = validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json', import.meta.url), 'utf8')));
const roundtrip = <T>(value: T): T => JSON.parse(JSON.stringify(value));
const act = (run: Run, event: RunEvent) => performRunEvent(run, event, catalog);
function startingBattle(seed = 'route-79'): Run { return enterEncounter(leaveService(enterRoom(createRun(catalog, seed), 'shop-0', catalog), catalog), '1-1', catalog); }
// Synthetic receipts isolate economic consequences; browser QA completes real battles.
function victory(run: Run, hp?: number[]): Run {
  const battle = structuredClone(run.battle!);
  battle.units.forEach(unit => { unit.hp = unit.team === 'enemy' ? 0 : hp?.[run.roster.findIndex(member => member.id === unit.id)] ?? unit.hp; });
  battle.queue = []; battle.outcome = 'victory';
  return completeEncounter(withBattle(run, battle), catalog);
}
class Memory implements StorageLike {
  values = new Map<string,string>();
  getItem(key: string): string | null { return this.values.get(key) ?? null; }
  setItem(key: string,value: string): void { this.values.set(key,value); }
  removeItem(key: string): void { this.values.delete(key); }
}
test('six-combat route adds connected shop/recruit choices while preserving prior teams and maps', () => {
  const teams = new Set<string>();
  for(let seed=0;seed<30;seed++) {
    const run=createRun(catalog,`team-${seed}`),legacy=createLegacyRun(catalog,`team-${seed}`);
    assert.deepEqual(run,createRun(catalog,`team-${seed}`));
    assert.deepEqual(run.roster.map(member=>member.speciesId),legacy.roster.map(member=>member.speciesId));
    assert.equal(run.nodes.length,22);
    assert.deepEqual(availableNodes(run).map(node=>node.kind),['shop','recruit']);
    assert(run.nodes.filter(node=>node.kind==='recruit').every(node=>new Set(node.offers.map(offer=>offer.speciesId)).size===3));
    assert(run.nodes.flatMap(node=>node.offers).every(offer=>catalog.some(species=>species.id===offer.speciesId && !species.legendary && !species.mythical)));
    legacy.nodes.forEach(node=>{const current=run.nodes.find(current=>current.id===node.id)!;assert.deepEqual(current.enemies,node.enemies);assert.equal(current.mapId,node.mapId);});
    teams.add(run.roster.map(member=>member.speciesId).join(','));
  }
  assert(teams.size>10);
  assert.throws(()=>enterEncounter(createRun(catalog,'skip'),'1-1',catalog));
});
test('limited stock and affordable prices govern purchases, reject combat purchases and preserve input', () => {
  const initial=enterRoom(createRun(catalog,'shop'),'shop-0',catalog);
  const bought=act(initial,{kind:'buy',itemId:'leftovers'});
  assert.equal(bought.money,120);assert.equal(bought.bag.leftovers,1);assert.equal(initial.bag.leftovers,0);
  assert.throws(()=>act(bought,{kind:'buy',itemId:'leftovers'}),/agotada/);
  const empty=act(bought,{kind:'buy',itemId:'assault-vest'});
  assert.throws(()=>act(empty,{kind:'buy',itemId:'potion'}),/dinero/);
  assert.throws(()=>act(startingBattle(),{kind:'buy',itemId:'potion'}),/tienda/);
  const closed=leaveService(bought,catalog);
  assert.throws(()=>enterRoom(closed,'shop-0',catalog));
  assert.throws(()=>enterRoom(closed,'recruit-0',catalog));
});
test('one victory grants one reward; continuing or reloading cannot grant it twice', () => {
  const result=victory(startingBattle());
  assert.equal(result.money,STARTING_MONEY+VICTORY_REWARD);
  assert.throws(()=>completeEncounter(result,catalog));
  assert.throws(()=>act(result,{kind:'result',...result.history[0]}));
  assert.deepEqual(validateRun(roundtrip(result),catalog),result);
});
test('healing caps at maximum, consumes once, rejects full HP, absent/dead members and combat', () => {
  let run=victory(startingBattle(),[0,12,22]);
  assert.equal(run.roster.length,2);assert.equal(run.departed[0].reason,'fallen');
  run=enterRoom(run,'shop-1',catalog);
  run=act(run,{kind:'buy',itemId:'super-potion'});
  const wounded=run.roster[0],before=run.bag['super-potion'];
  run=act(run,{kind:'heal',itemId:'super-potion',memberId:wounded.id});
  assert.equal(run.roster[0].hp,48);assert.equal(run.bag['super-potion'],before-1);
  assert.throws(()=>act(run,{kind:'heal',itemId:'potion',memberId:wounded.id}),/todos/);
  assert.throws(()=>act(run,{kind:'heal',itemId:'potion',memberId:1}),/revivir/);
  const battle=enterEncounter(leaveService(run,catalog),'2-1',catalog);
  assert.throws(()=>act(battle,{kind:'heal',itemId:'potion',memberId:wounded.id}),/fuera/);
});
test('equipment swaps return the previous item, never duplicate it, and cannot change during combat', () => {
  let run=enterRoom(createRun(catalog,'gear'),'shop-0',catalog);
  run=act(run,{kind:'buy',itemId:'leftovers'});run=act(run,{kind:'buy',itemId:'heavy-duty-boots'});
  run=act(run,{kind:'equip',itemId:'leftovers',memberId:1});
  assert.equal(run.bag.leftovers,0);assert.equal(run.roster[0].heldItem,'leftovers');
  assert.throws(()=>act(run,{kind:'equip',itemId:'leftovers',memberId:1}),/equipado/);
  run=act(run,{kind:'equip',itemId:'heavy-duty-boots',memberId:1});
  assert.equal(run.bag.leftovers,1);assert.equal(run.bag['heavy-duty-boots'],0);
  run=act(run,{kind:'equip',itemId:null,memberId:1});assert.equal(run.bag['heavy-duty-boots'],1);
  const battle=enterEncounter(leaveService(run,catalog),'1-1',catalog);
  assert.throws(()=>act(battle,{kind:'equip',itemId:'leftovers',memberId:1}));
});
test('fallen equipment returns to the bag and the dead identity never redeploys', () => {
  let run=enterRoom(createRun(catalog,'fallen'),'shop-0',catalog);
  run=act(run,{kind:'buy',itemId:'leftovers'});run=act(run,{kind:'equip',itemId:'leftovers',memberId:1});
  run=victory(enterEncounter(leaveService(run,catalog),'1-1',catalog),[0,20,20]);
  assert.equal(run.bag.leftovers,1);assert.equal(run.departed[0].heldItem,null);
  run=enterRoom(run,'recruit-1',catalog);
  const offer=run.nodes.find(node=>node.id==='recruit-1')!.offers[0];
  run=act(run,{kind:'recruit',offerId:offer.id,replaceId:null});
  assert.equal(run.roster.at(-1)!.id,4);assert(!run.roster.some(member=>member.id===1));
  run=enterEncounter(leaveService(run,catalog),'2-1',catalog);
  assert(!run.battle!.units.some(unit=>unit.id===1));
});
test('three limited recruits expand to six; all six deploy with independent identities and legal positions', () => {
  let run=enterRoom(createRun(catalog,'six'),'recruit-0',catalog);
  const offers=run.nodes.find(node=>node.id==='recruit-0')!.offers;
  offers.forEach(offer=>{run=act(run,{kind:'recruit',offerId:offer.id,replaceId:null});});
  assert.equal(run.roster.length,6);assert.equal(run.money,0);
  assert.throws(()=>act(run,{kind:'recruit',offerId:offers[0].id,replaceId:null}),/disponible/);
  const battle=enterEncounter(leaveService(run,catalog),'1-1',catalog);
  assert.equal(battle.battle!.units.filter(unit=>unit.team==='ally').length,6);
  assert.equal(new Set(battle.battle!.units.map(unit=>unit.id)).size,9);
  assert.deepEqual(validateRun(roundtrip(battle),catalog),battle);
});
test('full roster replacements require a valid member, preserve new identity and recover held gear', () => {
  let run=enterRoom(createRun(catalog,'replace'),'recruit-0',catalog);
  run.nodes.find(node=>node.id==='recruit-0')!.offers.forEach(offer=>{run=act(run,{kind:'recruit',offerId:offer.id,replaceId:null});});
  run=victory(enterEncounter(leaveService(run,catalog),'1-1',catalog));
  run=enterRoom(run,'shop-1',catalog);run=act(run,{kind:'buy',itemId:'heavy-duty-boots'});run=act(run,{kind:'equip',itemId:'heavy-duty-boots',memberId:1});
  run=victory(enterEncounter(leaveService(run,catalog),'2-1',catalog));
  run=enterRoom(run,'recruit-2',catalog);const offer=run.nodes.find(node=>node.id==='recruit-2')!.offers[0];
  assert.throws(()=>act(run,{kind:'recruit',offerId:offer.id,replaceId:null}),/completo/);
  run=act(run,{kind:'recruit',offerId:offer.id,replaceId:1});
  assert.equal(run.roster.length,6);assert.equal(run.bag['heavy-duty-boots'],1);
  assert.equal(run.departed.find(member=>member.id===1)!.reason,'released');assert.equal(run.roster.at(-1)!.id,7);
  assert.deepEqual(validateRun(roundtrip(run),catalog),run);
});
test('ledger replay exactly reconstructs stock, bag, money, equipment and roster; tampering rejects', () => {
  let run=enterRoom(createRun(catalog,'ledger'),'shop-0',catalog);run=act(run,{kind:'buy',itemId:'potion'});
  assert.deepEqual(replayRun(catalog,run.seed,run.variance,run.events),run);
  const changes=[(r:Run)=>{r.money++;},(r:Run)=>{r.bag.potion++;},(r:Run)=>{r.roster[0].hp--;},(r:Run)=>{r.purchases['shop-0'].potion=3;},(r:Run)=>{r.nodes[0].enemies=[150];}];
  changes.forEach(change=>{const corrupt=structuredClone(run);change(corrupt);assert.throws(()=>validateRun(corrupt,catalog));});
  assert.deepEqual(validateRun(roundtrip(run),catalog),run);
});
test('local save reloads every legal combat command with the exact ongoing HP, queue, items and RNG', () => {
  const memory=new Memory(),store=new RunStore(memory,catalog);assert.equal(store.read().kind,'empty');let run=startingBattle('saved-fight');let commands=0;
  while(run.battle!.outcome==='playing') {
    const result=applyCommand(run.battle!,chooseTacticalCommand(run.battle!));assert(result.ok);run=withBattle(run,result.state);
    assert.equal(store.write(run),'saved');const read=new RunStore(memory,catalog).read();assert.equal(read.kind,'valid');if(read.kind==='valid')assert.deepEqual(read.run,run);assert(++commands<300);
  }
  run=completeEncounter(run,catalog);assert.deepEqual(validateRun(roundtrip(run),catalog),run);
});
test('legacy ongoing save migrates once with an original backup, preserving battle RNG/HP and prior losses', () => {
  const legacy=enterLegacy(createLegacyRun(catalog,'old'),'1-1',catalog),memory=new Memory();
  const original=JSON.stringify({schema:'pokemon-tactics/run',version:1,run:legacy});memory.setItem(SAVE_KEY,original);
  const store=new RunStore(memory,catalog),read=store.read();assert.equal(read.kind,'valid');
  if(read.kind==='valid') {
    assert.equal(read.migrated,true);assert.equal(read.run.battle!.rng,legacy.battle!.rng);assert.deepEqual(read.run.battle!.units.map(unit=>unit.hp),legacy.battle!.units.map(unit=>unit.hp));
    assert.equal(store.write(read.run),'saved');assert.equal(memory.getItem(LEGACY_BACKUP_KEY),original);
    const second=new RunStore(memory,catalog).read();assert.equal(second.kind,'valid');if(second.kind==='valid'){assert.equal(second.migrated,undefined);assert.deepEqual(second.run,read.run);}
  }
  assert.equal(SAVE_VERSION,2);
});
test('corrupt/incompatible saves remain untouched, stale tabs cannot overwrite, and unavailable storage is explicit', () => {
  const memory=new Memory();for(const raw of ['{',JSON.stringify({schema:'pokemon-tactics/run',version:999})]){memory.setItem(SAVE_KEY,raw);assert.equal(new RunStore(memory,catalog).read().kind,raw==='{'?'invalid':'incompatible');assert.equal(memory.getItem(SAVE_KEY),raw);}
  memory.removeItem(SAVE_KEY);const first=new RunStore(memory,catalog),second=new RunStore(memory,catalog);first.read();second.read();first.write(createRun(catalog,'tabs'));
  assert.equal(second.write(createRun(catalog,'other')),'conflict');assert.equal(second.discard(),'conflict');
  assert.equal(new RunStore(null,catalog).read().kind,'unavailable');assert.equal(new RunStore(null,catalog).write(createRun(catalog,'blocked')),'unavailable');
});
test('six cleared encounters end the run, while total loss ends it without a defeat reward or revival', () => {
  let run=createRun(catalog,'final');for(let floor=1;floor<=6;floor++){run=leaveService(enterRoom(run,`shop-${floor-1}`,catalog),catalog);run=victory(enterEncounter(run,`${floor}-1`,catalog));}
  assert.equal(run.status,'victory');assert.equal(run.history.length,6);assert.equal(run.money,840);assert.deepEqual(validateRun(roundtrip(run),catalog),run);
  let loss=startingBattle('loss');const battle=structuredClone(loss.battle!);battle.units.filter(unit=>unit.team==='ally').forEach(unit=>unit.hp=0);battle.outcome='defeat';battle.queue=[];loss=completeEncounter(withBattle(loss,battle),catalog);
  assert.equal(loss.status,'defeat');assert.equal(loss.roster.length,0);assert.equal(loss.departed.length,3);assert.equal(loss.money,STARTING_MONEY);assert.deepEqual(availableNodes(loss),[]);assert.deepEqual(validateRun(roundtrip(loss),catalog),loss);
});
test('optional replacement before six members retains team size and returns the outgoing gear',()=>{
  let run=enterRoom(createRun(catalog,'early-replace'),'shop-0',catalog);
  run=act(run,{kind:'buy',itemId:'heavy-duty-boots'});run=act(run,{kind:'equip',itemId:'heavy-duty-boots',memberId:1});
  run=victory(enterEncounter(leaveService(run,catalog),'1-1',catalog));run=enterRoom(run,'recruit-1',catalog);
  run=act(run,{kind:'recruit',offerId:run.nodes.find(node=>node.id==='recruit-1')!.offers[0].id,replaceId:1});
  assert.equal(run.roster.length,3);assert.equal(run.bag['heavy-duty-boots'],1);assert.equal(run.roster.at(-1)!.id,4);assert.deepEqual(validateRun(roundtrip(run),catalog),run);
});
test('legacy route with previous casualties migrates HP and exactly one reward per completed encounter',()=>{
  let legacy=createLegacyRun(catalog,'legacy-loss');
  for(const node of ['1-1','2-2']){
    legacy=enterLegacy(legacy,node,catalog);const battle=structuredClone(legacy.battle!);
    battle.units.forEach(unit=>{unit.hp=unit.team==='enemy'||unit.id===1?0:unit.id===2?11:22;});battle.outcome='victory';battle.queue=[];
    legacy=completeLegacy(withLegacyBattle(legacy,battle));
  }
  const memory=new Memory();memory.setItem(SAVE_KEY,JSON.stringify({schema:'pokemon-tactics/run',version:1,run:legacy}));
  const store=new RunStore(memory,catalog),read=store.read();assert.equal(read.kind,'valid');
  if(read.kind==='valid'){
    assert.equal(read.run.money,440);assert.deepEqual(read.run.roster.map(member=>member.hp),[11,22]);assert.equal(read.run.departed[0].id,1);
    store.write(read.run);const again=new RunStore(memory,catalog).read();assert.equal(again.kind,'valid');if(again.kind==='valid')assert.equal(again.run.money,440);
  }
});
test('save validation rejects impossible battle positions, altered base stats and forged held items',()=>{
  const run=startingBattle('invalid-battle');
  for(const change of [(r:Run)=>{r.battle!.units[0].x=99;},(r:Run)=>{r.battle!.units[0].attack=999;},(r:Run)=>{r.battle!.units[0].heldItem='leftovers';},(r:Run)=>{r.battle!.queue=[];}]){
    const invalid=structuredClone(run);change(invalid);assert.throws(()=>validateRun(invalid,catalog));
  }
});
test('migration backup quota failure preserves the original; retry writes the full new save and backup',()=>{
  const memory=new Memory(),legacy=createLegacyRun(catalog,'quota-migration'),raw=JSON.stringify({schema:'pokemon-tactics/run',version:1,run:legacy});memory.setItem(SAVE_KEY,raw);
  let blocked=true;const storage={getItem:(key:string)=>memory.getItem(key),setItem:(key:string,value:string)=>{if(blocked)throw new Error('quota');memory.setItem(key,value);},removeItem:(key:string)=>memory.removeItem(key)};
  const store=new RunStore(storage,catalog),read=store.read();assert.equal(read.kind,'valid');
  if(read.kind==='valid'){assert.equal(store.write(read.run),'unavailable');assert.equal(memory.getItem(SAVE_KEY),raw);blocked=false;assert.equal(store.write(read.run),'saved');assert.equal(memory.getItem(LEGACY_BACKUP_KEY),raw);assert.equal(new RunStore(memory,catalog).read().kind,'valid');}
});
