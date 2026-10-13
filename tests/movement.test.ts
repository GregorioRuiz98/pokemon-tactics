import test from 'node:test';
import assert from 'node:assert/strict';
import {
  commitMove,
  initialUnits,
  planMove,
  routesFrom,
  TRAINING_BOARD,
  tileCost,
} from '../src/rules/movement.ts';
import type { Unit } from '../src/rules/movement.ts';
const unit = (x = 0, y = 0, budget = 6): Unit => ({
  id: 1,
  x,
  y,
  budget,
  remaining: budget,
  facing: 0,
});

test('weighted navigation chooses a cheaper detour, charges destination not origin', () => {
  const board = [
    [0, 1, 1, 1, 0],
    [0, 0, 0, 0, 0],
  ];
  const route = routesFrom(board, [unit()], 1).get('4,0')!;
  assert.equal(route.cost, 6);
  assert.equal(route.path.length, 7);
  assert.equal(routesFrom([[1, 0]], [unit()], 1).get('1,0')!.cost, 1);
});
test('cannot cross obstacles, occupied corridors or diagonally cut corners', () => {
  assert.equal(
    planMove(
      [
        [0, 2],
        [2, 0],
      ],
      [unit()],
      1,
      { x: 1, y: 1 },
    ).ok,
    false,
  );
  const blocker = { ...unit(1, 0), id: 4 };
  assert.equal(
    planMove([[0, 0, 0]], [unit(), blocker], 1, { x: 2, y: 0 }).ok,
    false,
  );
  assert.equal(
    planMove([[0, 0, 0]], [unit(), blocker], 1, { x: 1, y: 0 }).ok,
    false,
  );
});
test('preview is immutable; confirmation consumes budget and cannot spend it twice', () => {
  const units = [unit(0, 0, 2)];
  const snapshot = structuredClone(units);
  assert.equal(planMove([[0, 0, 0, 0]], units, 1, { x: 2, y: 0 }).ok, true);
  assert.deepEqual(units, snapshot);
  const result = commitMove([[0, 0, 0, 0]], units, 1, { x: 2, y: 0 });
  assert(result.ok);
  assert.equal(result.units[0].remaining, 0);
  assert.equal(result.units[0].facing, 2);
  assert.equal(
    commitMove([[0, 0, 0, 0]], result.units, 1, { x: 3, y: 0 }).ok,
    false,
  );
  assert.deepEqual(units, snapshot);
});
test('confirmation rechecks occupancy instead of trusting a previous preview', () => {
  assert.equal(planMove([[0, 0, 0]], [unit()], 1, { x: 2, y: 0 }).ok, true);
  assert.equal(
    commitMove([[0, 0, 0]], [unit(), { ...unit(2, 0), id: 4 }], 1, {
      x: 2,
      y: 0,
    }).ok,
    false,
  );
});
test('invalid bounds, same origin, absent units and excessive costs reject safely', () => {
  for (const destination of [
    { x: -1, y: 0 },
    { x: 1.2, y: 0 },
    { x: NaN, y: 0 },
    { x: 0, y: 3 },
    { x: 0, y: 0 },
    { x: 2, y: 0 },
  ]) {
    assert.equal(
      planMove([[0, 1, 0]], [unit(0, 0, 1)], 1, destination).ok,
      false,
    );
  }
  assert.equal(planMove([[0]], [], 1, { x: 0, y: 0 }).ok, false);
});
test('training setup has six distinct legal positions and a genuinely unreachable tile', () => {
  const units = initialUnits();
  assert.equal(new Set(units.map((u) => `${u.x},${u.y}`)).size, 6);
  assert(units.every((u) => Number.isFinite(tileCost(TRAINING_BOARD, u))));
  const result = planMove(TRAINING_BOARD, units, 1, { x: 7, y: 0 });
  assert(!result.ok && result.reason.includes('No hay camino'));
  units[0].remaining = 0;
  assert.equal(initialUnits()[0].remaining, 4);
});
