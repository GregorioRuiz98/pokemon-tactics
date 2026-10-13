import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  createBattle,
  activeUnit,
  living,
  finishTurn,
  moveInBattle,
  attackInBattle,
  attackPlan,
  chooseTacticalCommand,
  applyCommand,
} from '../src/rules/battle.ts';
import type { Battle } from '../src/rules/battle.ts';
import { validateCatalog } from '../src/data/catalog.ts';
const catalog = validateCatalog(
  JSON.parse(
    readFileSync(
      new URL('../public/data/pokemon.json', import.meta.url),
      'utf8',
    ),
  ),
);
const next = (result: ReturnType<typeof finishTurn>): Battle => {
  assert(result.ok);
  return result.state;
};
const duel = (): Battle => {
  const state = createBattle(catalog);
  state.board = Array.from({ length: 8 }, () => Array(8).fill(0));
  state.units = state.units.filter((u) => [4, 74].includes(u.id));
  Object.assign(state.units[0], { x: 1, y: 1 });
  Object.assign(state.units[1], { x: 2, y: 1 });
  state.queue = [4, 74];
  state.initiative = state.initiative.filter((i) => [4, 74].includes(i.id));
  return state;
};
test('seed reproduces scores and later rounds, speed rolls stay within configured variance', () => {
  for (const variance of [0.05, 0.1]) {
    let a = createBattle(catalog, 'replay', variance),
      b = createBattle(catalog, 'replay', variance);
    for (let i = 0; i < 25; i++) {
      assert.deepEqual(a, b);
      for (const entry of a.initiative) {
        const speed = a.units.find((u) => u.id === entry.id)!.speed;
        assert(
          entry.score >= speed * (1 - variance) &&
            entry.score <= speed * (1 + variance),
        );
      }
      a = next(finishTurn(a));
      b = next(finishTurn(b));
    }
  }
  assert.notDeepEqual(
    createBattle(catalog, 'a').initiative,
    createBattle(catalog, 'b').initiative,
  );
});
test('each living unit activates once per round; waiting resets a new round without duplicates', () => {
  let state = createBattle(catalog);
  const order = [...state.queue],
    rng = state.rng;
  for (const id of order) {
    assert.equal(activeUnit(state)!.id, id);
    assert.equal(state.rng, rng);
    state = next(finishTurn(state));
  }
  assert.equal(state.round, 2);
  assert.equal(new Set(state.queue).size, 6);
  assert.deepEqual(state.completed, []);
});
test('movement and attack are legal in either order, each at most once, without mutating input', () => {
  for (const first of ['move', 'attack']) {
    const original = duel(),
      snapshot = structuredClone(original);
    let state =
      first === 'move'
        ? next(moveInBattle(original, { x: 1, y: 2 }))
        : next(attackInBattle(original, 74));
    state =
      first === 'move'
        ? next(attackInBattle(state, 74))
        : next(moveInBattle(state, { x: 1, y: 2 }));
    assert(state.moved && state.acted);
    assert.deepEqual(original, snapshot);
    assert.equal(moveInBattle(state, { x: 0, y: 2 }).ok, false);
    assert.equal(attackInBattle(state, 74).ok, false);
    const finished = next(finishTurn(state));
    assert.equal(finished.moved, false);
    assert.equal(finished.acted, false);
  }
});
test('attack previews do not consume action or random numbers; illegal attacks reject safely', () => {
  const state = duel(),
    snapshot = structuredClone(state);
  assert.equal(attackPlan(state, 74).ok, true);
  assert.deepEqual(state, snapshot);
  assert.equal(attackInBattle(state, 4).ok, false);
  assert.equal(attackInBattle(state, 999).ok, false);
  state.units[1].x = 7;
  assert.equal(attackInBattle(state, 74).ok, false);
  state.units[1].hp = 0;
  assert.equal(attackInBattle(state, 74).ok, false);
});
test('ranged attacks respect intervening rock and occupied squares', () => {
  const state = duel();
  state.units[1].x = 3;
  state.board = [
    [0, 0, 0, 0],
    [0, 0, 2, 0],
  ];
  assert.equal(attackPlan(state, 74).ok, false);
  state.board = [
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ];
  assert.equal(attackPlan(state, 74).ok, true);
  state.units.push({ ...state.units[0], id: 7, x: 2 });
  assert.equal(attackPlan(state, 74).ok, false);
});
test('killed future units leave occupancy and the remaining queue, allowing the round to finish', () => {
  let state = createBattle(catalog);
  state.board = Array.from({ length: 8 }, () => Array(8).fill(0));
  state.queue = [4, 74, 1];
  Object.assign(
    state.units.find((u) => u.id === 4)!,
    { x: 1, y: 1 },
  );
  Object.assign(
    state.units.find((u) => u.id === 74)!,
    { x: 2, y: 1, hp: 1 },
  );
  state = next(attackInBattle(state, 74));
  assert.deepEqual(state.queue, [4, 1]);
  assert(!living(state).some((u) => u.id === 74));
  state = next(moveInBattle(state, { x: 2, y: 1 }));
  state = next(finishTurn(state));
  assert.equal(activeUnit(state)!.id, 1);
  state = next(finishTurn(state));
  assert.equal(state.round, 2);
  assert(!state.queue.includes(74));
});
test('last opposing casualty resolves victory/defeat immediately and locks further commands', () => {
  for (const outcome of ['victory', 'defeat']) {
    const state = duel();
    if (outcome === 'defeat') {
      state.units[0].team = 'enemy';
      state.units[1].team = 'ally';
    }
    state.units[1].hp = 1;
    const result = next(attackInBattle(state, 74));
    assert.equal(result.outcome, outcome);
    assert.deepEqual(result.queue, []);
    assert.equal(finishTurn(result).ok, false);
    assert.equal(moveInBattle(result, { x: 0, y: 0 }).ok, false);
    assert.equal(attackInBattle(result, 74).ok, false);
  }
});
test('tactical policy attacks in range, navigates around obstacles and waits when trapped', () => {
  let state = duel();
  assert.equal(chooseTacticalCommand(state).kind, 'attack');
  state.units[1].x = 7;
  state.units[1].y = 7;
  assert.equal(chooseTacticalCommand(state).kind, 'move');
  state.units[0].x = 0;
  state.units[0].y = 0;
  state.board = [
    [0, 2, 0],
    [2, 0, 0],
    [0, 0, 0],
  ];
  assert.equal(chooseTacticalCommand(state).kind, 'finish');
});
test('several seeded 3v3 simulations terminate and replay exactly', () => {
  for (const seed of ['kanto-001', 'portfolio', 'trial-10']) {
    const simulate = () => {
      let state = createBattle(catalog, seed);
      let commands = 0;
      while (state.outcome === 'playing' && commands < 500) {
        state = next(applyCommand(state, chooseTacticalCommand(state)));
        commands++;
      }
      assert.notEqual(state.outcome, 'playing');
      assert(commands < 500);
      return state;
    };
    assert.deepEqual(simulate(), simulate());
  }
});
