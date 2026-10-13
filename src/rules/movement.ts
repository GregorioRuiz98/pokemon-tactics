import EasyStar from 'easystarjs';

export type Point = { x: number; y: number };
export type Facing = 0 | 2 | 4 | 6;
export type Unit = Point & {
  id: number;
  budget: number;
  remaining: number;
  facing: Facing;
};
export type Board = readonly (readonly number[])[];
export const TERRAIN = {
  0: { name: 'Suelo', cost: 1 },
  1: { name: 'Maleza', cost: 2 },
  2: { name: 'Roca', cost: Infinity },
  3: { name: 'Agua', cost: Infinity },
} as const;
export const TRAINING_BOARD: Board = [
  [0, 0, 0, 0, 0, 0, 2, 0],
  [0, 1, 1, 0, 0, 0, 0, 2],
  [0, 1, 2, 2, 0, 1, 0, 0],
  [0, 0, 2, 0, 0, 1, 3, 3],
  [0, 1, 2, 0, 1, 0, 3, 3],
  [0, 0, 0, 0, 1, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 1, 0],
  [0, 0, 0, 0, 0, 0, 0, 0],
];
export const key = (p: Point): string => `${p.x},${p.y}`;
export const same = (a: Point, b: Point): boolean => a.x === b.x && a.y === b.y;
export const coordinate = (p: Point): string =>
  `${String.fromCharCode(65 + p.x)}${p.y + 1}`;
export const tileCost = (board: Board, p: Point): number =>
  Number.isInteger(p.x) && Number.isInteger(p.y)
    ? (TERRAIN[board[p.y]?.[p.x] as keyof typeof TERRAIN]?.cost ?? Infinity)
    : Infinity;
export function initialUnits(): Unit[] {
  return [
    [1, 1, 5, 4],
    [4, 3, 6, 4],
    [7, 2, 7, 4],
    [25, 5, 6, 5],
    [12, 1, 7, 4],
    [74, 5, 4, 3],
  ].map(([id, x, y, budget]) => ({
    id,
    x,
    y,
    budget,
    remaining: budget,
    facing: 4,
  }));
}
export type Route = { path: Point[]; cost: number };
export type MovePlan =
  { ok: true; route: Route } | { ok: false; reason: string };

// EasyStar owns navigation. This adapter owns terrain, occupancy and movement budget.
export function routesFrom(
  board: Board,
  units: readonly Unit[],
  id: number,
): Map<string, Route> {
  const unit = units.find((u) => u.id === id);
  const routes = new Map<string, Route>();
  if (!unit || !Number.isFinite(tileCost(board, unit))) return routes;
  const finder = new EasyStar.js();
  finder.setGrid(board.map((row) => [...row]));
  finder.setAcceptableTiles([0, 1]);
  finder.setTileCost(0, 1);
  finder.setTileCost(1, 2);
  finder.disableDiagonals();
  finder.enableSync();
  const occupied = new Set(units.filter((u) => u.id !== id).map(key));
  units
    .filter((u) => u.id !== id)
    .forEach((u) => finder.avoidAdditionalPoint(u.x, u.y));
  board.forEach((row, y) =>
    row.forEach((_, x) => {
      const destination = { x, y };
      if (
        !Number.isFinite(tileCost(board, destination)) ||
        occupied.has(key(destination))
      )
        return;
      if (same(unit, destination)) {
        routes.set(key(destination), { path: [destination], cost: 0 });
        return;
      }
      finder.findPath(unit.x, unit.y, x, y, (path) => {
        if (path)
          routes.set(key(destination), {
            path,
            cost: path.slice(1).reduce((sum, p) => sum + tileCost(board, p), 0),
          });
      });
    }),
  );
  finder.calculate();
  return routes;
}
export function planMove(
  board: Board,
  units: readonly Unit[],
  id: number,
  destination: Point,
): MovePlan {
  const unit = units.find((u) => u.id === id);
  if (!unit) return { ok: false, reason: 'Selecciona un Pokémon.' };
  if (same(unit, destination))
    return { ok: false, reason: 'Ya está en esa casilla.' };
  if (!Number.isFinite(tileCost(board, destination)))
    return { ok: false, reason: 'Ese terreno bloquea el paso.' };
  if (units.some((u) => u.id !== id && same(u, destination)))
    return { ok: false, reason: 'Casilla ocupada por otro Pokémon.' };
  const route = routesFrom(board, units, id).get(key(destination));
  if (!route) return { ok: false, reason: 'No hay camino hasta esa casilla.' };
  if (route.cost > unit.remaining)
    return {
      ok: false,
      reason: `Necesita ${route.cost} puntos; quedan ${unit.remaining}.`,
    };
  return { ok: true, route };
}
export function facingFrom(a: Point, b: Point): Facing {
  return b.x > a.x ? 2 : b.x < a.x ? 6 : b.y < a.y ? 4 : 0;
}
// Recalculate on confirmation so an old preview cannot bypass a changed board or occupancy.
export function commitMove(
  board: Board,
  units: readonly Unit[],
  id: number,
  destination: Point,
): { ok: true; units: Unit[]; route: Route } | { ok: false; reason: string } {
  const plan = planMove(board, units, id, destination);
  if (!plan.ok) return plan;
  const { path, cost } = plan.route;
  return {
    ok: true,
    route: plan.route,
    units: units.map((u) =>
      u.id === id
        ? {
            ...u,
            ...destination,
            remaining: u.remaining - cost,
            facing: facingFrom(path[path.length - 2], destination),
          }
        : { ...u },
    ),
  };
}
