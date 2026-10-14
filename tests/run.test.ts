import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { RUN_MAPS } from '../src/data/run-maps.ts';
import { pokemonFor } from '../src/domain/Pokemon.ts';
import { createEncounter, activeUnit, applyCommand, chooseTacticalCommand } from '../src/rules/battle.ts';
import { tileCost } from '../src/rules/movement.ts';
import { createRun, availableNodes, enterEncounter, completeEncounter, withBattle } from '../src/rules/run.ts';
import { RunStore, SAVE_KEY, SAVE_VERSION, validateRun } from '../src/data/run-store.ts';
import type { StorageLike } from '../src/data/run-store.ts';
import type { Run } from '../src/rules/run.ts';
const catalog = validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json', import.meta.url), 'utf8')));
const json = <T>(value: T): T => JSON.parse(JSON.stringify(value));
class Memory implements StorageLike {
  value: string | null = null;
  getItem(): string | null { return this.value; }
  setItem(_key: string, value: string): void { this.value = value; }
  removeItem(): void { this.value = null; }
}
// Synthetic terminal snapshots isolate the between-room contract from combat tactics.
function finishFixture(run: Run, hp: number[]): Run {
  const battle = structuredClone(run.battle!);
  battle.units.forEach(unit => { unit.hp = unit.team === 'enemy' ? 0 : hp[unit.id - 1]; });
  battle.queue = [];
  battle.outcome = hp.some(value => value > 0) ? 'victory' : 'defeat';
  if (battle.outcome === 'defeat') battle.units.find(unit => unit.team === 'enemy')!.hp = 1;
  return completeEncounter(withBattle(run, battle));
}
test('seed reproduces a nonlegendary three-species team, six-layer DAG and progressively unlocked maps', () => {
  const teams = new Set<string>();
  for (let seed = 0; seed < 40; seed++) {
    const run = createRun(catalog, `team-${seed}`);
    assert.deepEqual(run, createRun(catalog, `team-${seed}`));
    assert.equal(new Set(run.roster.map(member => member.speciesId)).size, 3);
    assert(run.roster.some(member => [7,74].includes(member.speciesId)));
    assert(run.roster.every(member => !catalog.find(p => p.id === member.speciesId)!.legendary));
    assert.equal(run.nodes.length, 10);
    assert.equal(run.nodes[0].mapId, 'quarry');
    assert(run.nodes.filter(node => node.floor < 4).every(node => node.mapId !== 'pond'));
    run.nodes.forEach(node => node.next.forEach(id => assert.equal(run.nodes.find(n => n.id === id)!.floor, node.floor + 1)));
    teams.add(run.roster.map(member => member.speciesId).join(','));
  }
  assert(teams.size > 10);
});
test('maps allow all six deployments and encounters distinguish repeated species across teams', () => {
  for (const map of RUN_MAPS) {
    const encounter = createEncounter(catalog, 'duplicate', .05, map.board,
      [{ id: 1, speciesId: 74, hp: 45 }, { id: 2, speciesId: 7, hp: 40 }, { id: 3, speciesId: 1, hp: 30 }], [74,7,1]);
    assert.equal(new Set(encounter.units.map(unit => unit.id)).size, 6);
    assert.deepEqual(encounter.units.map(unit => unit.speciesId), [74,7,1,74,7,1]);
    encounter.units.forEach(unit => assert(Number.isFinite(tileCost(encounter.board, unit, unit.profile))));
    const actor = activeUnit(encounter)!;
    assert.equal(pokemonFor(actor.speciesId).speciesId, actor.speciesId);
    assert(applyCommand(encounter, chooseTacticalCommand(encounter)).ok);
  }
});
test('between rooms HP and deaths persist; surviving members start with fresh statuses/PT; branches cannot be skipped', () => {
  const original = createRun(catalog, 'persist');
  assert.throws(() => enterEncounter(original, '2-1', catalog));
  let run = enterEncounter(original, '1-1', catalog);
  assert.throws(() => completeEncounter(run));
  run = finishFixture(run, [0, 12, 22]);
  assert.equal(run.status, 'route');
  assert.deepEqual(run.roster.map(member => member.hp), [0,12,22]);
  assert.deepEqual(availableNodes(run).map(node => node.id), ['2-1','2-2']);
  assert.throws(() => completeEncounter(run));
  run = enterEncounter(run, '2-2', catalog);
  const allies = run.battle!.units.filter(unit => unit.team === 'ally');
  assert.deepEqual(allies.map(unit => unit.id), [2,3]);
  assert.deepEqual(allies.map(unit => unit.hp), [12,22]);
  assert(allies.every(unit => unit.status === null && !unit.guarded && unit.tp === (activeUnit(run.battle!)?.id === unit.id ? 3 : 2)));
  assert.deepEqual(original.path, []);
  assert.throws(() => enterEncounter(run, '2-1', catalog));
});
test('complete team loss ends the run and clearing the sixth encounter resolves the provisional final', () => {
  let run = createRun(catalog, 'endings');
  const loss = finishFixture(enterEncounter(run, '1-1', catalog), [0,0,0]);
  assert.equal(loss.status, 'defeat');
  assert.equal(loss.history[0].outcome, 'defeat');
  assert.deepEqual(availableNodes(loss), []);
  for (let floor = 1; floor <= 6; floor++) run = finishFixture(enterEncounter(run, `${floor}-1`, catalog), [20,20,20]);
  assert.equal(run.status, 'victory');
  assert.equal(run.path.length, 6);
  assert.equal(run.history.length, 6);
  assert.deepEqual(validateRun(json(run), catalog), run);
});
test('versioned save roundtrips route, ongoing commands and terminal fights without restoring HP or RNG', () => {
  const memory = new Memory(), store = new RunStore(memory, catalog);
  assert.equal(store.read().kind, 'empty');
  let run = enterEncounter(createRun(catalog, 'saved-fight'), '1-1', catalog);
  let commands = 0;
  while (run.battle!.outcome === 'playing') {
    const result = applyCommand(run.battle!, chooseTacticalCommand(run.battle!));
    assert(result.ok);
    run = withBattle(run, result.state);
    assert.deepEqual(validateRun(json(run), catalog), run);
    assert.equal(store.write(run), 'saved');
    const reloaded = new RunStore(memory, catalog).read();
    assert.equal(reloaded.kind, 'valid');
    if (reloaded.kind === 'valid') assert.deepEqual(reloaded.run, run);
    assert(++commands < 300);
  }
  run = completeEncounter(run);
  assert.deepEqual(validateRun(run, catalog), run);
  assert.equal(store.write(run), 'saved');
  assert.equal(new RunStore(memory, catalog).read().kind, 'valid');
});
test('corrupt/incompatible saves remain intact; malformed route, dead revival and illegal combat state reject', () => {
  const memory = new Memory(), store = new RunStore(memory, catalog);
  for (const raw of ['{', JSON.stringify({ schema:'pokemon-tactics/run',version:999,run:{} })]) {
    memory.value = raw;
    assert.equal(store.read().kind, raw === '{' ? 'invalid' : 'incompatible');
    assert.equal(memory.value, raw);
  }
  const route = finishFixture(enterEncounter(createRun(catalog, 'corrupt'), '1-1', catalog), [0,12,20]);
  const corruptions = [
    (r: Run) => { r.roster[0].hp = 10; },
    (r: Run) => { r.path.push('3-1'); },
    (r: Run) => { r.nodes[0].next = ['6-1']; },
    (r: Run) => { r.roster[1].speciesId = 150; },
  ];
  corruptions.forEach(change => { const r = structuredClone(route); change(r); assert.throws(() => validateRun(r, catalog)); });
  const combat = enterEncounter(route, '2-1', catalog);
  const invalidBattle = [
    (r: Run) => { r.battle!.units[0].hp = -1; },
    (r: Run) => { r.battle!.units[0].x = 99; },
    (r: Run) => { r.battle!.units[0].attack = 999; },
    (r: Run) => { r.battle!.queue = []; },
    (r: Run) => { r.battle!.units[1].x = r.battle!.units[0].x; r.battle!.units[1].y = r.battle!.units[0].y; },
    (r: Run) => { r.battle!.fields.push({ x:0,y:0,kind:'embers',expires:r.battle!.round }); },
  ];
  invalidBattle.forEach(change => { const r = structuredClone(combat); change(r); assert.throws(() => validateRun(r, catalog)); });
  assert.equal(store.discard(), 'saved');
  assert.equal(memory.value, null);
});
test('unavailable storage/quota is reported; stale tabs cannot overwrite a newer save', () => {
  const run = createRun(catalog, 'tabs'), memory = new Memory();
  const first = new RunStore(memory, catalog), second = new RunStore(memory, catalog);
  first.read(); second.read();
  assert.equal(first.write(run), 'saved');
  assert.equal(second.write(createRun(catalog, 'newer')), 'conflict');
  assert.equal(second.discard(), 'conflict');
  second.read();
  assert.equal(second.write(run), 'saved');
  const disabled = new RunStore(null, catalog);
  assert.equal(disabled.read().kind, 'unavailable');
  assert.equal(disabled.write(run), 'unavailable');
  const quota = new RunStore({ getItem: () => null, setItem: () => { throw new Error('quota'); }, removeItem: () => {} }, catalog);
  quota.read(); assert.equal(quota.write(run), 'unavailable');
  assert.equal(SAVE_KEY, 'pokemon-tactics.run');
  assert.equal(SAVE_VERSION, 1);
});
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
