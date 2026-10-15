import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { createRun, enterRoom, leaveService, enterEncounter, performRunEvent, completeEncounter, withBattle, maximumHp, replayRun } from '../src/rules/run.ts';
import { validateRun, RunStore, SAVE_KEY } from '../src/data/run-store.ts';
import { createRun as createV2 } from '../src/rules/run-v2.ts';
import { applyCommand, chooseTacticalCommand } from '../src/rules/battle.ts';
import { levelFor, atLevel } from '../src/domain/progression.ts';
import { pokemonFor } from '../src/domain/Pokemon.ts';
const catalog = validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json', import.meta.url), 'utf8')));
test('evolution consumes one compatible item, preserves identity/XP/HP/gear and changes a tactical action', () => {
  let run = enterRoom(createRun(catalog, 'evolution', .05, 7), 'shop-0', catalog);
  run = performRunEvent(run, { kind: 'buy', itemId: 'rare-candy' }, catalog);
  const member = run.roster.find(m => [1, 4, 7, 74].includes(m.speciesId))!;
  const before = structuredClone(member), oldActions = pokemonFor(member.speciesId).actions;
  run = performRunEvent(run, { kind: 'evolve', memberId: member.id }, catalog);
  const evolved = run.roster.find(m => m.id === member.id)!;
  assert.equal(evolved.hp, before.hp); assert.equal(evolved.xp, before.xp); assert.equal(evolved.heldItem, before.heldItem);
  assert.notEqual(evolved.speciesId, before.speciesId); assert.notEqual(pokemonFor(evolved.speciesId).actions[2].definition.id, oldActions[2].definition.id);
  assert.equal(run.bag['rare-candy'], 0); assert.throws(() => performRunEvent(run, { kind: 'evolve', memberId: member.id }, catalog));
  assert.throws(() => performRunEvent(run, { kind: 'evolve', memberId: 999 }, catalog));
  assert.deepEqual(validateRun(run, catalog), run);
});
test('actual battle contribution grants individual XP once, independently of last hit, and replay preserves it', () => {
  let run = enterEncounter(leaveService(enterRoom(createRun(catalog, 'route-79', .05, 7), 'shop-0', catalog), catalog), '1-1', catalog);
  let battle = run.battle!;
  for (let i = 0; battle.outcome === 'playing' && i < 1000; i++) {
    const result = applyCommand(battle, chooseTacticalCommand(battle)!); assert(result.ok); battle = result.state;
  }
  assert.equal(battle.outcome, 'victory');
  run = completeEncounter(withBattle(run, battle), catalog);
  assert(run.roster.every(m => m.xp >= 20)); assert(run.roster.some(m => m.xp > 20));
  assert.throws(() => completeEncounter(run, catalog));
  assert.deepEqual(replayRun(catalog, run.seed, run.variance, run.events, 7), run);
  assert.deepEqual(validateRun(run, catalog), run);
});
test('simplified levels cap at five, increase effective stats and never heal persistent current HP', () => {
  assert.deepEqual([0, 59, 60, 120, 239, 240, 999].map(levelFor), [1, 1, 2, 3, 4, 5, 5]);
  const original = pokemonFor(1).createCombatant(catalog.find(p => p.id === 1)!, 'ally', { x: 0, y: 0 });
  assert.equal(atLevel(original, 3).maxHp, original.maxHp + 10);
  assert.equal(maximumHp(catalog, 1, 120), original.maxHp + 10); assert.equal(original.hp, original.maxHp);
});
test('schema two migrations preserve the original battleless journal and retain its backup', () => {
  const data = new Map<string,string>(); const old = createV2(catalog, 'old-v2');
  const raw = JSON.stringify({ schema: 'pokemon-tactics/run', version: 2, run: old }); data.set(SAVE_KEY, raw);
  const storage = { getItem: (k:string) => data.get(k) ?? null, setItem: (k:string,v:string) => { data.set(k,v); }, removeItem: (k:string) => { data.delete(k); } };
  const store = new RunStore(storage, catalog), read = store.read(); assert.equal(read.kind, 'valid');
  if (read.kind === 'valid') { assert.equal(read.run.edition, 6); assert(read.run.roster.every(m => m.xp === 0)); assert.equal(store.write(read.run), 'saved'); }
  assert.equal(data.get('pokemon-tactics.run.v2-backup'), raw);
});
