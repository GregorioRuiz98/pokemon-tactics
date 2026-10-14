import EasyStar from 'easystarjs';

export type Point = { x: number; y: number };
export type Facing = 0 | 2 | 4 | 6;
export type MovementProfile = 'ground' | 'grass' | 'swim' | 'fly';
export type Unit = Point & {
  id: number;
  speciesId?: number;
  budget: number;
  remaining: number;
  facing: Facing;
  team?: 'ally' | 'enemy';
  profile?: MovementProfile;
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
export function tileCost(board: Board, p: Point, profile: MovementProfile = 'ground'): number {
  if (!Number.isInteger(p.x) || !Number.isInteger(p.y)) return Infinity;
  const tile = board[p.y]?.[p.x];
  if (tile === 0) return 1;
  if (tile === 1) return profile === 'grass' || profile === 'fly' ? 1 : 2;
  if (tile === 3 && (profile === 'swim' || profile === 'fly')) return 1;
  return Infinity;
}
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
  if (!unit || !Number.isFinite(tileCost(board, unit, unit.profile))) return routes;
  const finder = new EasyStar.js();
  finder.setGrid(board.map((row) => [...row]));
  const passable = [0, 1, 3].filter(tile => Number.isFinite(tileCost([[tile]], { x: 0, y: 0 }, unit.profile)));
  finder.setAcceptableTiles(passable);
  passable.forEach(tile => finder.setTileCost(tile, tileCost([[tile]], { x: 0, y: 0 }, unit.profile)));
  finder.disableDiagonals();
  finder.enableSync();
  const occupied = new Set(units.filter((u) => u.id !== id).map(key));
  units
    .filter((u) => u.id !== id && (!unit.team || u.team !== unit.team))
    .forEach((u) => finder.avoidAdditionalPoint(u.x, u.y));
  board.forEach((row, y) =>
    row.forEach((_, x) => {
      const destination = { x, y };
      if (
        !Number.isFinite(tileCost(board, destination, unit.profile)) ||
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
            cost: path.slice(1).reduce((sum, p) => sum + tileCost(board, p, unit.profile), 0),
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
  if (!Number.isFinite(tileCost(board, destination, unit.profile)))
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
  const dx = b.x - a.x, dy = b.y - a.y;
  return Math.abs(dx) >= Math.abs(dy) && dx !== 0 ? dx > 0 ? 2 : 6 : dy < 0 ? 4 : 0;
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
