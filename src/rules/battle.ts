import {
  commitMove,
  coordinate,
  facingFrom,
  key,
  routesFrom,
  same,
  tileCost,
  TRAINING_BOARD,
} from './movement.ts';
import type { Board, Point, Route, Unit } from './movement.ts';
import type { PokemonSpecies } from '../data/catalog.ts';

export type Team = 'ally' | 'enemy';
export type Combatant = Unit & {
  name: string;
  team: Team;
  hp: number;
  maxHp: number;
  attack: number;
  defense: number;
  speed: number;
  range: number;
};
export type Initiative = { id: number; score: number; tie: number };
export type Battle = {
  seed: string;
  rng: number;
  variance: number;
  round: number;
  board: Board;
  units: Combatant[];
  initiative: Initiative[];
  queue: number[];
  completed: number[];
  moved: boolean;
  acted: boolean;
  outcome: 'playing' | 'victory' | 'defeat';
  log: string[];
};
export const living = (state: Battle): Combatant[] =>
  state.units.filter((u) => u.hp > 0);
export const activeUnit = (state: Battle): Combatant | undefined =>
  state.outcome === 'playing'
    ? state.units.find((u) => u.id === state.queue[0] && u.hp > 0)
    : undefined;
export const distance = (a: Point, b: Point): number =>
  Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
const copy = (state: Battle): Battle => ({
  ...state,
  units: state.units.map((u) => ({ ...u })),
  initiative: state.initiative.map((i) => ({ ...i })),
  queue: [...state.queue],
  completed: [...state.completed],
  log: [...state.log],
});
function note(state: Battle, message: string): void {
  state.log = [...state.log, message].slice(-40);
}
function hashSeed(seed: string): number {
  let value = 2166136261;
  for (const character of seed)
    value = Math.imul(value ^ character.charCodeAt(0), 16777619);
  return value >>> 0;
}
function random(state: Battle): number {
  state.rng = (state.rng + 0x6d2b79f5) >>> 0;
  let value = state.rng;
  value = Math.imul(value ^ (value >>> 15), value | 1);
  value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
  return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
}
function newRound(state: Battle): void {
  state.round++;
  state.initiative = living(state)
    .sort((a, b) => a.id - b.id)
    .map((u) => ({
      id: u.id,
      score: u.speed * (1 + (random(state) * 2 - 1) * state.variance),
      tie: random(state),
    }))
    .sort((a, b) => b.score - a.score || a.tie - b.tie || a.id - b.id);
  state.queue = state.initiative.map((i) => i.id);
  state.completed = [];
  state.moved = false;
  state.acted = false;
  state.units.forEach((u) => {
    if (u.hp > 0) u.remaining = u.budget;
  });
  note(state, `Ronda ${state.round}: nueva cola de iniciativa.`);
}
export function createBattle(
  catalog: readonly PokemonSpecies[],
  seed = 'kanto-001',
  variance = 0.05,
): Battle {
  if (![0.05, 0.1].includes(variance))
    throw new Error('La variación debe ser 5 % o 10 %.');
  const positions: [number, Team, number, number, number, number][] = [
    [1, 'ally', 1, 6, 4, 1],
    [4, 'ally', 3, 6, 4, 2],
    [7, 'ally', 2, 7, 4, 2],
    [25, 'enemy', 5, 1, 5, 1],
    [12, 'enemy', 6, 2, 4, 2],
    [74, 'enemy', 5, 4, 3, 1],
  ];
  const units = positions.map(([id, team, x, y, budget, range]): Combatant => {
    const species = catalog.find((p) => p.id === id);
    if (!species) throw new Error(`Falta la especie ${id}.`);
    const maxHp = Math.round(35 + species.baseStats.hp / 3);
    return {
      id,
      team,
      x,
      y,
      budget,
      remaining: budget,
      range,
      name: species.name,
      maxHp,
      hp: maxHp,
      attack: species.baseStats.attack,
      defense: species.baseStats.defense,
      speed: species.baseStats.speed,
      facing: team === 'ally' ? 4 : 0,
    };
  });
  const normalizedSeed = seed.trim().slice(0, 64) || 'kanto-001';
  const state: Battle = {
    seed: normalizedSeed,
    rng: hashSeed(normalizedSeed),
    variance,
    round: 0,
    board: TRAINING_BOARD,
    units,
    initiative: [],
    queue: [],
    completed: [],
    moved: false,
    acted: false,
    outcome: 'playing',
    log: [],
  };
  newRound(state);
  return state;
}
export type RuleResult =
  | { ok: true; state: Battle; route?: Route; damage?: number }
  | { ok: false; reason: string };
export function moveInBattle(state: Battle, destination: Point): RuleResult {
  const actor = activeUnit(state);
  if (!actor) return { ok: false, reason: 'El combate ha terminado.' };
  if (state.moved)
    return {
      ok: false,
      reason: 'Ya has usado el desplazamiento de esta activación.',
    };
  const result = commitMove(state.board, living(state), actor.id, destination);
  if (!result.ok) return result;
  const next = copy(state),
    moved = result.units.find((u) => u.id === actor.id)!;
  Object.assign(
    next.units.find((u) => u.id === actor.id)!,
    moved,
  );
  next.moved = true;
  note(
    next,
    `${actor.name} se mueve a ${coordinate(destination)} (${result.route.cost} puntos).`,
  );
  return { ok: true, state: next, route: result.route };
}
export const basicDamage = (actor: Combatant, target: Combatant): number =>
  Math.max(5, Math.round(12 + actor.attack * 0.18 - target.defense * 0.1));
function clearShot(
  state: Battle,
  actor: Combatant,
  target: Combatant,
): boolean {
  const dx = target.x - actor.x,
    dy = target.y - actor.y;
  if (distance(actor, target) === 1) return true;
  const intermediates: Point[] =
    dx === 0
      ? [{ x: actor.x, y: actor.y + Math.sign(dy) }]
      : dy === 0
        ? [{ x: actor.x + Math.sign(dx), y: actor.y }]
        : [
            { x: target.x, y: actor.y },
            { x: actor.x, y: target.y },
          ];
  return intermediates.every(
    (p) =>
      Number.isFinite(tileCost(state.board, p)) &&
      !living(state).some((u) => u.id !== actor.id && same(u, p)),
  );
}
export type AttackPlan =
  { ok: true; damage: number } | { ok: false; reason: string };
export function attackPlan(
  state: Battle,
  targetId: number,
  origin?: Point,
): AttackPlan {
  const active = activeUnit(state),
    target = state.units.find((u) => u.id === targetId);
  if (!active) return { ok: false, reason: 'El combate ha terminado.' };
  if (state.acted)
    return { ok: false, reason: 'Ya has usado la acción de esta activación.' };
  const actor = origin ? { ...active, ...origin } : active;
  if (!target || target.hp <= 0)
    return { ok: false, reason: 'El objetivo ya no está en combate.' };
  if (target.team === actor.team)
    return { ok: false, reason: 'El ataque básico requiere un enemigo.' };
  if (distance(actor, target) > actor.range)
    return {
      ok: false,
      reason: `Fuera de alcance: ${actor.range} casilla${actor.range === 1 ? '' : 's'}.`,
    };
  if (!clearShot(state, actor, target))
    return {
      ok: false,
      reason: 'El terreno u otra unidad bloquea el disparo.',
    };
  return { ok: true, damage: Math.min(target.hp, basicDamage(actor, target)) };
}
export function attackInBattle(state: Battle, targetId: number): RuleResult {
  const plan = attackPlan(state, targetId);
  if (!plan.ok) return plan;
  const next = copy(state),
    actor = activeUnit(next)!,
    target = next.units.find((u) => u.id === targetId)!;
  target.hp = Math.max(0, target.hp - plan.damage);
  actor.facing = facingFrom(actor, target);
  next.acted = true;
  note(
    next,
    `${actor.name} golpea a ${target.name}: ${plan.damage} PS.${target.hp === 0 ? ' Fuera de combate.' : ''}`,
  );
  next.queue = next.queue.filter((id) =>
    next.units.some((u) => u.id === id && u.hp > 0),
  );
  next.outcome = !living(next).some((u) => u.team === 'enemy')
    ? 'victory'
    : !living(next).some((u) => u.team === 'ally')
      ? 'defeat'
      : 'playing';
  if (next.outcome !== 'playing') {
    next.queue = [];
    note(
      next,
      next.outcome === 'victory'
        ? 'Victoria: zona despejada.'
        : 'Derrota: el equipo ha caído.',
    );
  }
  return { ok: true, state: next, damage: plan.damage };
}
export function finishTurn(state: Battle): RuleResult {
  const actor = activeUnit(state);
  if (!actor) return { ok: false, reason: 'El combate ha terminado.' };
  const next = copy(state);
  note(next, `${actor.name} termina su activación.`);
  next.completed.push(actor.id);
  next.queue = next.queue
    .slice(1)
    .filter((id) => next.units.some((u) => u.id === id && u.hp > 0));
  next.moved = false;
  next.acted = false;
  if (!next.queue.length) newRound(next);
  return { ok: true, state: next };
}
export type TacticalCommand =
  | { kind: 'attack'; target: number }
  | { kind: 'move'; destination: Point }
  | { kind: 'finish' };
// Deterministic tactical policy, used by enemies and as a simulation policy in tests.
export function chooseTacticalCommand(state: Battle): TacticalCommand {
  const actor = activeUnit(state);
  if (!actor) return { kind: 'finish' };
  const targets = living(state)
    .filter((u) => u.team !== actor.team)
    .sort((a, b) => a.hp - b.hp || a.id - b.id);
  if (!state.acted) {
    const target = targets.find((t) => attackPlan(state, t.id).ok);
    if (target) return { kind: 'attack', target: target.id };
  }
  if (state.moved || state.acted) return { kind: 'finish' };
  const routes = routesFrom(state.board, living(state), actor.id);
  const approaches: { route: Route; target: Combatant }[] = [];
  for (const route of routes.values())
    for (const target of targets) {
      if (
        route.cost > 0 &&
        attackPlan(state, target.id, route.path[route.path.length - 1]).ok
      )
        approaches.push({ route, target });
    }
  approaches.sort(
    (a, b) =>
      a.route.cost - b.route.cost ||
      a.target.hp - b.target.hp ||
      a.target.id - b.target.id ||
      key(a.route.path.at(-1)!).localeCompare(key(b.route.path.at(-1)!)),
  );
  const approach = approaches[0];
  if (!approach) return { kind: 'finish' };
  let spent = 0,
    destination: Point = actor;
  for (const step of approach.route.path.slice(1)) {
    const cost = tileCost(state.board, step);
    if (spent + cost > actor.remaining) break;
    spent += cost;
    destination = step;
  }
  return same(destination, actor)
    ? { kind: 'finish' }
    : { kind: 'move', destination };
}
export function applyCommand(
  state: Battle,
  command: TacticalCommand,
): RuleResult {
  return command.kind === 'move'
    ? moveInBattle(state, command.destination)
    : command.kind === 'attack'
      ? attackInBattle(state, command.target)
      : finishTurn(state);
}
