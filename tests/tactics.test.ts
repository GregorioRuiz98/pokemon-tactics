import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { createBattle, attackPlan, attackInBattle, finishTurn, chooseTacticalCommand, applyCommand, activeUnit, living } from '../src/rules/battle.ts';
import type { Battle, RuleResult } from '../src/rules/battle.ts';
import { tileCost, routesFrom, planMove, commitMove } from '../src/rules/movement.ts';
import type { Unit, Facing } from '../src/rules/movement.ts';
import { attackSide, positionalAccuracy, FACINGS, FACING_VECTORS } from '../src/rules/position.ts';
import { fieldDamage } from '../src/rules/terrain.ts';
const catalog = validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json', import.meta.url), 'utf8')));
const next = (result: RuleResult): Battle => { assert(result.ok, result.ok ? '' : result.reason); return result.state; };
const board = () => Array.from({ length: 8 }, () => Array(8).fill(0));
function duel(actorId = 74, targetId = 7, seed = 'position'): Battle {
  const state = createBattle(catalog, seed);
  state.board = board();
  state.units = [state.units.find(unit => unit.id === actorId)!, state.units.find(unit => unit.id === targetId)!];
  Object.assign(state.units[0], { x: 3, y: 3, team: 'ally', tp: 5 });
  Object.assign(state.units[1], { x: 4, y: 3, team: 'enemy', hp: 200, maxHp: 200 });
  state.queue = [actorId, targetId];
  return state;
}
function successfulPush(state: Battle): Battle {
  for (let i = 0; i < 80; i++) {
    const input = { ...state, rng: i * 1291 };
    const result = attackInBattle(input, state.units[1].id, 'rock-throw');
    assert(result.ok);
    if (result.hit)
      return result.state;
  }
  throw new Error('No successful fixture roll.');
}
test('position rotates correctly in four directions; diagonal ties use the facing axis', () => {
  for (const facing of FACINGS) {
    const target = { x: 3, y: 3, facing }, vector = FACING_VECTORS[facing];
    const front = { x: 3 + vector.x, y: 3 + vector.y };
    const rear = { x: 3 - vector.x, y: 3 - vector.y };
    const flank = { x: 3 + vector.y, y: 3 - vector.x };
    assert.equal(attackSide(front, target), 'front');
    assert.equal(attackSide(rear, target), 'rear');
    assert.equal(attackSide(flank, target), 'flank');
    assert.equal(attackSide({ x: front.x + vector.y, y: front.y - vector.x }, target), 'front');
    assert.equal(attackSide({ x: rear.x + vector.y, y: rear.y - vector.x }, target), 'rear');
  }
  assert.deepEqual(['front', 'flank', 'rear'].map(side => positionalAccuracy(100, side as 'front' | 'flank' | 'rear')), [85, 95, 100]);
  assert.equal(positionalAccuracy(75, 'front'), 60);
});
test('the target facing determines the forecast, while damage and RNG stay unchanged by inspection', () => {
  const state = duel(), target = state.units[1];
  const expected: [
    Facing,
    number
  ][] = [[6, 75], [4, 85], [2, 90]];
  for (const [facing, accuracy] of expected) {
    target.facing = facing;
    const before = structuredClone(state), plan = attackPlan(state, 7, undefined, 'rock-throw');
    assert(plan.ok);
    assert.equal(plan.accuracy, accuracy);
    assert.equal(plan.hits.length, 1);
    assert.deepEqual(state, before);
  }
});
test('finishing chooses a cardinal facing, preserves it through other turns and rejects invalid input', () => {
  let state = duel();
  const original = structuredClone(state), rng = state.rng;
  assert.equal(finishTurn(state, 5 as Facing).ok, false);
  assert.deepEqual(state, original);
  state = next(finishTurn(state, 4));
  assert.equal(state.units[0].facing, 4);
  assert.equal(state.rng, rng);
  state = next(finishTurn(state, 6));
  assert.equal(state.units[0].facing, 4);
  assert.equal(state.units[1].facing, 6);
  assert.deepEqual(original.units[0].facing, createBattle(catalog).units.find(unit => unit.id === 74)!.facing);
});
test('allied corridors can be crossed, occupied destinations and enemy corridors cannot', () => {
  const corridor = [[0, 1, 0, 0]];
  const units: Unit[] = [
    { id: 1, x: 0, y: 0, facing: 2, budget: 4, remaining: 4, team: 'ally' },
    { id: 4, x: 1, y: 0, facing: 2, budget: 4, remaining: 4, team: 'ally' },
  ];
  const snapshot = structuredClone(units), plan = planMove(corridor, units, 1, { x: 3, y: 0 });
  assert(plan.ok);
  assert.equal(plan.route.cost, 4);
  assert.deepEqual(plan.route.path.map(point => point.x), [0, 1, 2, 3]);
  assert.equal(planMove(corridor, units, 1, { x: 1, y: 0 }).ok, false);
  assert.deepEqual(units, snapshot);
  units[1].team = 'enemy';
  assert.equal(commitMove(corridor, units, 1, { x: 3, y: 0 }).ok, false);
  assert(!routesFrom(corridor, units, 1).has('3,0'));
});
test('movement profiles preserve terrain costs and occupancy for grass, water and flying units', () => {
  const terrain = [[0, 1, 3, 0]], base: Unit = { id: 1, x: 0, y: 0, facing: 2, budget: 5, remaining: 5, team: 'ally' };
  assert.equal(tileCost(terrain, { x: 1, y: 0 }, 'grass'), 1);
  assert.equal(tileCost(terrain, { x: 1, y: 0 }, 'ground'), 2);
  for (const profile of ['swim', 'fly'] as const) {
    const plan = planMove(terrain, [{ ...base, profile }], 1, { x: 3, y: 0 });
    assert(plan.ok);
    assert.equal(plan.route.cost, profile === 'fly' ? 3 : 4);
    assert.equal(tileCost([[2]], { x: 0, y: 0 }, profile), Infinity);
    const blockers = [{ ...base, profile }, { ...base, id: 4, x: 2, team: 'enemy' as const }];
    assert.equal(planMove(terrain, blockers, 1, { x: 3, y: 0 }).ok, false);
  }
  for (const profile of ['ground', 'grass'] as const)
    assert.equal(planMove(terrain, [{ ...base, profile }], 1, { x: 3, y: 0 }).ok, false);
});
test('water is transparent to shots even for ground actors; rocks and intermediate units block them', () => {
  const state = duel(4, 7);
  state.units[0].x = 1;
  state.units[1].x = 3;
  state.board = board();
  (state.board as number[][])[3][2] = 3;
  assert(attackPlan(state, 7).ok);
  (state.board as number[][])[3][2] = 2;
  assert.equal(attackPlan(state, 7).ok, false);
  (state.board as number[][])[3][2] = 0;
  const ally = createBattle(catalog).units.find(unit => unit.id === 1)!;
  state.units.push({ ...ally, x: 2, y: 3 });
  assert.equal(attackPlan(state, 7).ok, false);
});
test('pushes use cardinal displacement, keep facing and are predicted before confirmation', () => {
  for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1]]) {
    const state = duel(), target = state.units[1];
    target.x = 3 + dx;
    target.y = 3 + dy;
    const forecast = attackPlan(state, 7, undefined, 'rock-throw');
    assert(forecast.ok && forecast.push);
    const input = structuredClone(state), after = successfulPush(state);
    assert.equal(after.units[1].x, target.x + (dx ? Math.sign(dx) : 0));
    assert.equal(after.units[1].y, target.y + (dx ? 0 : Math.sign(dy)));
    assert.equal(after.units[1].facing, target.facing);
    assert.deepEqual(state, input);
  }
});
test('push cannot place a target out of bounds, on another unit or on incompatible water/rock', () => {
  const state = duel(), target = state.units[1];
  const ally = createBattle(catalog).units.find(unit => unit.id === 1)!;
  state.units.push({ ...ally, x: 5, y: 3 });
  let plan = attackPlan(state, 7, undefined, 'rock-throw');
  assert(plan.ok && !plan.push && plan.pushReason?.includes('unidad'));
  state.units.pop();
  (state.board as number[][])[3][5] = 3;
  plan = attackPlan(state, 7, undefined, 'rock-throw');
  assert(plan.ok && plan.push); // Squirtle can land in water.
  target.profile = 'ground';
  plan = attackPlan(state, 7, undefined, 'rock-throw');
  assert(plan.ok && !plan.push);
  (state.board as number[][])[3][5] = 2;
  target.profile = 'fly';
  plan = attackPlan(state, 7, undefined, 'rock-throw');
  assert(plan.ok && !plan.push);
  target.x = 7;
  state.units[0].x = 6;
  plan = attackPlan(state, 7, undefined, 'rock-throw');
  assert(plan.ok && !plan.push);
  target.hp = 1;
  plan = attackPlan(state, 7, undefined, 'rock-throw');
  assert(plan.ok && !plan.push && plan.pushReason?.includes('cae'));
});
test('area preview includes collateral allies exactly once; each hit uses its own stats, aim and type', () => {
  const state = createBattle(catalog);
  state.board = board();
  state.queue = [4, 25, 7, 1, 74, 12];
  const positions = new Map([[4, [3, 1]], [25, [3, 3]], [7, [4, 3]], [1, [2, 3]], [74, [3, 4]], [12, [7, 7]]]);
  for (const unit of state.units) {
    const p = positions.get(unit.id)!;
    unit.x = p[0];
    unit.y = p[1];
    unit.hp = unit.maxHp = 200;
    unit.tp = 5;
  }
  const snapshot = structuredClone(state), plan = attackPlan(state, 25, undefined, 'flamethrower');
  assert(plan.ok);
  assert.equal(plan.tiles.length, 5);
  assert.deepEqual(plan.hits.map(hit => hit.targetId), [1, 7, 25, 74]);
  assert.equal(plan.hits.find(hit => hit.targetId === 1)!.multiplier, 2);
  assert.equal(plan.hits.find(hit => hit.targetId === 7)!.multiplier, 0.5);
  const result = attackInBattle(state, 25, 'flamethrower');
  assert(result.ok);
  assert.equal(result.state.units.find(unit => unit.id === 4)!.tp, 2);
  assert.equal(result.hits!.length, 4);
  for (const hit of result.hits!) {
    const before = state.units.find(unit => unit.id === hit.targetId)!;
    assert.equal(result.state.units.find(unit => unit.id === hit.targetId)!.hp, before.hp - hit.damage);
    assert.equal(hit.damage, hit.hit ? plan.hits.find(effect => effect.targetId === hit.targetId)!.damage : 0);
  }
  assert.deepEqual(state, snapshot);
});
test('area excludes rocks, off-board cells and its caster; status immunities remain per-target', () => {
  const state = duel(12, 7), ally = createBattle(catalog).units.find(unit => unit.id === 1)!;
  state.units[0].x = 0;
  state.units[0].y = 1;
  state.units[1].x = 0;
  state.units[1].y = 0;
  state.units.push({ ...ally, x: 1, y: 0 });
  let plan = attackPlan(state, 7, undefined, 'poison-powder');
  assert(plan.ok);
  assert.equal(plan.tiles.length, 3);
  assert.deepEqual(plan.hits.map(hit => hit.targetId), [1, 7]);
  assert.equal(plan.hits.find(hit => hit.targetId === 1)!.status, null);
  assert(plan.hits.find(hit => hit.targetId === 7)!.status);
  (state.board as number[][])[0][1] = 2;
  plan = attackPlan(state, 7, undefined, 'poison-powder');
  assert(plan.ok);
  assert.deepEqual(plan.hits.map(hit => hit.targetId), [7]);
});
test('embers only occupy soil/grass, never stack, expire at round R+2 and spare Fire/flying units', () => {
  let state = duel(4, 7);
  state.units[0].x = 2;
  (state.board as number[][])[3][5] = 3;
  (state.board as number[][])[4][4] = 2;
  state = next(attackInBattle(state, 7, 'flamethrower'));
  assert.equal(state.fields.length, 3);
  assert(state.fields.every(field => field.expires === 3));
  assert.equal(new Set(state.fields.map(field => `${field.x},${field.y}`)).size, state.fields.length);
  assert.equal(fieldDamage(state.units[1], state.fields), 4);
  assert.equal(fieldDamage({ ...state.units[1], types: ['fire'] }, state.fields), 0);
  assert.equal(fieldDamage({ ...state.units[1], profile: 'fly' }, state.fields), 0);
  state = next(finishTurn(state));
  const before = state.units[1].hp;
  state.units[1].guarded = true;
  state = next(finishTurn(state));
  assert.equal(state.units[1].hp, before - 4);
  assert.equal(state.round, 2);
  assert.equal(state.fields.length, 3);
  while (state.round < 3)
    state = next(finishTurn(state));
  assert.equal(state.fields.length, 0);
});
test('terrain death resolves the last ally, and missed area orders still spend PT and leave embers', () => {
  const dying = duel(1, 7);
  dying.units[0].hp = 4;
  dying.fields = [{ x: 3, y: 3, kind: 'embers', expires: 3 }];
  assert.equal(next(finishTurn(dying, 2)).outcome, 'defeat');
  const fire = duel(4, 7);
  let missed = false;
  for (let i = 0; i < 60; i++) {
    const result = attackInBattle({ ...fire, rng: i * 8821 }, 7, 'flamethrower');
    assert(result.ok);
    if (!result.hit) {
      assert.equal(result.state.units[0].tp, 2);
      assert(result.state.fields.length > 0);
      missed = true;
      break;
    }
  }
  assert(missed);
});
test('AI avoids costly collateral, exits hazards after acting and never spends forecast RNG', () => {
  const state = duel(4, 7), ally = createBattle(catalog).units.find(unit => unit.id === 1)!;
  state.units.push({ ...ally, x: 4, y: 4, hp: 1 });
  const snapshot = structuredClone(state), command = chooseTacticalCommand(state);
  assert(command.kind !== 'attack' || command.actionId !== 'flamethrower');
  assert.deepEqual(state, snapshot);
  const hazard = duel(1, 7);
  hazard.acted = true;
  hazard.fields = [{ x: 3, y: 3, kind: 'embers', expires: 3 }];
  const escape = chooseTacticalCommand(hazard);
  assert.equal(escape.kind, 'move');
  assert.equal(fieldDamage(activeUnit(next(applyCommand(hazard, escape)))!, hazard.fields), 0);
});
test('many seeded simulations keep legal occupancy/profile routes, finish and replay exactly', () => {
  for (const composition of ['starters', 'mixed'] as const)
    for (let seed = 0; seed < 10; seed++) {
      const simulate = () => {
        let state = createBattle(catalog, `tactics-${seed}`, seed % 2 ? 0.1 : 0.05, composition), count = 0;
        while (state.outcome === 'playing' && count++ < 300) {
          state = next(applyCommand(state, chooseTacticalCommand(state)));
          const units = living(state);
          assert.equal(new Set(units.map(unit => `${unit.x},${unit.y}`)).size, units.length);
          assert(units.every(unit => Number.isFinite(tileCost(state.board, unit, unit.profile))));
          assert.equal(new Set(state.queue).size, state.queue.length);
        }
        assert.notEqual(state.outcome, 'playing');
        return state;
      };
      assert.deepEqual(simulate(), simulate());
    }
});
