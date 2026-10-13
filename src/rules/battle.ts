import { commitMove, coordinate, facingFrom, key, routesFrom, same, tileCost, TRAINING_BOARD } from './movement.ts';
import type { Board, Point, Route } from './movement.ts';
import type { PokemonSpecies } from '../data/catalog.ts';
import { pokemonFor } from '../domain/Pokemon.ts';
import { effectiveSpeed, movementBudget, STATUS_NAMES } from '../domain/combatant.ts';
import type { Combatant, Team } from '../domain/combatant.ts';
import type { ActionEffect } from '../domain/actions.ts';
export type { Combatant, Team } from '../domain/combatant.ts';
export type Composition = 'starters' | 'mixed';
export type Initiative = {
  id: number;
  score: number;
  tie: number;
};
export type Battle = {
  seed: string;
  rng: number;
  variance: number;
  composition: Composition;
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
export const living = (state: Battle): Combatant[] => state.units.filter(u => u.hp > 0);
export const activeUnit = (state: Battle): Combatant | undefined => state.outcome === 'playing' ? state.units.find(u => u.id === state.queue[0] && u.hp > 0) : undefined;
export const distance = (a: Point, b: Point): number => Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
const copy = (state: Battle): Battle => structuredClone(state);
function note(state: Battle, message: string): void { state.log = [...state.log, message].slice(-40); }
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
function beginActivation(state: Battle): void {
  const actor = activeUnit(state);
  if (!actor)
    return;
  actor.tp = Math.min(actor.maxTp, actor.tp + 1);
  actor.guarded = false;
  actor.remaining = movementBudget(actor);
  state.moved = false;
  state.acted = false;
}
function newRound(state: Battle): void {
  state.round++;
  state.initiative = living(state).sort((a, b) => a.id - b.id).map(u => ({
    id: u.id, score: effectiveSpeed(u) * (1 + (random(state) * 2 - 1) * state.variance), tie: random(state),
  })).sort((a, b) => b.score - a.score || a.tie - b.tie || a.id - b.id);
  state.queue = state.initiative.map(i => i.id);
  state.completed = [];
  state.units.forEach(u => { if (u.hp > 0)
    u.remaining = movementBudget(u); });
  note(state, `Ronda ${state.round}: nueva cola de iniciativa.`);
  beginActivation(state);
}
export function createBattle(catalog: readonly PokemonSpecies[], seed = 'kanto-001', variance = 0.05, composition: Composition = 'starters'): Battle {
  if (![0.05, 0.1].includes(variance))
    throw new Error('La variación debe ser 5 % o 10 %.');
  if (!['starters', 'mixed'].includes(composition))
    throw new Error('Composición no válida.');
  const allies = composition === 'starters' ? [1, 4, 7] : [25, 12, 74];
  const enemies = composition === 'starters' ? [25, 12, 74] : [1, 4, 7];
  const positions: [
    number,
    Team,
    number,
    number
  ][] = [
    [allies[0], 'ally', 1, 6], [allies[1], 'ally', 3, 6], [allies[2], 'ally', 2, 7],
    [enemies[0], 'enemy', 5, 1], [enemies[1], 'enemy', 6, 2], [enemies[2], 'enemy', 5, 4],
  ];
  const units = positions.map(([id, team, x, y]) => {
    const species = catalog.find(p => p.id === id);
    if (!species)
      throw new Error(`Falta la especie ${id}.`);
    return pokemonFor(id).createCombatant(species, team, { x, y });
  });
  const normalizedSeed = seed.trim().slice(0, 64) || 'kanto-001';
  const state: Battle = { seed: normalizedSeed, rng: hashSeed(normalizedSeed), variance, composition, round: 0, board: TRAINING_BOARD, units, initiative: [], queue: [], completed: [], moved: false, acted: false, outcome: 'playing', log: [] };
  newRound(state);
  return state;
}
export type RuleResult = {
  ok: true;
  state: Battle;
  route?: Route;
  damage?: number;
  hit?: boolean;
} | {
  ok: false;
  reason: string;
};
export function moveInBattle(state: Battle, destination: Point): RuleResult {
  const actor = activeUnit(state);
  if (!actor)
    return { ok: false, reason: 'El combate ha terminado.' };
  if (state.moved)
    return { ok: false, reason: 'Ya has usado el desplazamiento de esta activación.' };
  const result = commitMove(state.board, living(state), actor.id, destination);
  if (!result.ok)
    return result;
  const next = copy(state);
  const moved = result.units.find(u => u.id === actor.id)!;
  Object.assign(next.units.find(u => u.id === actor.id)!, { x: moved.x, y: moved.y, remaining: moved.remaining, facing: moved.facing });
  next.moved = true;
  note(next, `${actor.name} se mueve a ${coordinate(destination)} (${result.route.cost} puntos).`);
  return { ok: true, state: next, route: result.route };
}
export const basicDamage = (actor: Combatant, target: Combatant): number => pokemonFor(actor.id).action('basic')!.preview(actor, target).damage;
function clearShot(state: Battle, actor: Combatant, target: Combatant): boolean {
  const dx = target.x - actor.x, dy = target.y - actor.y;
  if (distance(actor, target) <= 1)
    return true;
  const intermediates: Point[] = dx === 0 ? [{ x: actor.x, y: actor.y + Math.sign(dy) }] : dy === 0 ? [{ x: actor.x + Math.sign(dx), y: actor.y }] : [{ x: target.x, y: actor.y }, { x: actor.x, y: target.y }];
  return intermediates.every(p => Number.isFinite(tileCost(state.board, p)) && !living(state).some(u => u.id !== actor.id && same(u, p)));
}
export type AttackPlan = ({
  ok: true;
  actionId: string;
  name: string;
  cost: number;
  accuracy: number;
} & ActionEffect) | {
  ok: false;
  reason: string;
};
export function attackPlan(state: Battle, targetId: number, origin?: Point, actionId = 'basic'): AttackPlan {
  const active = activeUnit(state), target = state.units.find(u => u.id === targetId);
  if (!active)
    return { ok: false, reason: 'El combate ha terminado.' };
  if (state.acted)
    return { ok: false, reason: 'Ya has usado la acción de esta activación.' };
  const action = pokemonFor(active.id).action(actionId);
  if (!action)
    return { ok: false, reason: 'Este Pokémon no conoce esa habilidad.' };
  const definition = action.definition;
  if (active.tp < definition.cost)
    return { ok: false, reason: `Necesita ${definition.cost} PT; quedan ${active.tp}.` };
  const actor = origin ? { ...active, ...origin } : active;
  if (!target || target.hp <= 0)
    return { ok: false, reason: 'El objetivo ya no está en combate.' };
  if (definition.target === 'enemy' && target.team === actor.team)
    return { ok: false, reason: 'Esta acción requiere un enemigo.' };
  if (definition.target === 'friendly' && target.team !== actor.team)
    return { ok: false, reason: 'Esta acción requiere un aliado o a sí mismo.' };
  if (definition.target === 'self' && target.id !== actor.id)
    return { ok: false, reason: 'Esta acción solo se aplica a sí mismo.' };
  if (distance(actor, target) > definition.range)
    return { ok: false, reason: `Fuera de alcance: ${definition.range} casillas.` };
  if (!clearShot(state, actor, target))
    return { ok: false, reason: 'El terreno u otra unidad bloquea el disparo.' };
  const effect = action.preview(actor, target);
  if (effect.category === 'status' && effect.statusReason)
    return { ok: false, reason: effect.statusReason };
  if (effect.guard && target.guarded)
    return { ok: false, reason: 'El objetivo ya está protegido.' };
  return { ok: true, actionId, name: definition.name, cost: definition.cost, accuracy: definition.accuracy, ...effect };
}
function resolveCasualties(state: Battle): void {
  state.queue = state.queue.filter(id => state.units.some(u => u.id === id && u.hp > 0));
  state.outcome = !living(state).some(u => u.team === 'enemy') ? 'victory' : !living(state).some(u => u.team === 'ally') ? 'defeat' : 'playing';
  if (state.outcome !== 'playing') {
    state.queue = [];
    note(state, state.outcome === 'victory' ? 'Victoria: zona despejada.' : 'Derrota: el equipo ha caído.');
  }
}
export function attackInBattle(state: Battle, targetId: number, actionId = 'basic'): RuleResult {
  const plan = attackPlan(state, targetId, undefined, actionId);
  if (!plan.ok)
    return plan;
  const next = copy(state), actor = activeUnit(next)!, target = next.units.find(u => u.id === targetId)!;
  actor.tp -= plan.cost;
  next.acted = true;
  if (actor.id !== target.id)
    actor.facing = facingFrom(actor, target);
  const hit = plan.accuracy === 100 || random(next) * 100 < plan.accuracy;
  if (!hit) {
    note(next, `${actor.name} usa ${plan.name} y falla contra ${target.name} (${plan.cost} PT).`);
    return { ok: true, state: next, damage: 0, hit: false };
  }
  target.hp = Math.max(0, target.hp - plan.damage);
  actor.hp = Math.min(actor.maxHp, actor.hp + plan.heal);
  if (plan.guard)
    target.guarded = true;
  if (plan.status && target.hp > 0 && (plan.status.chance === 100 || random(next) * 100 < plan.status.chance)) {
    target.status = { kind: plan.status.kind, remaining: plan.status.duration };
    note(next, `${target.name}: ${STATUS_NAMES[plan.status.kind]} (${plan.status.duration} activaciones).`);
  }
  note(next, `${actor.name} usa ${plan.name} sobre ${target.name}: ${plan.damage} PS, ${plan.cost} PT${plan.multiplier !== 1 ? `, eficacia ×${plan.multiplier}` : ''}.${plan.heal ? ` Recupera ${plan.heal} PS.` : ''}${plan.guard ? ' Protección hasta la próxima activación del objetivo.' : ''}${target.hp === 0 ? ' Fuera de combate.' : ''}`);
  resolveCasualties(next);
  return { ok: true, state: next, damage: plan.damage, hit: true };
}
export function finishTurn(state: Battle): RuleResult {
  const active = activeUnit(state);
  if (!active)
    return { ok: false, reason: 'El combate ha terminado.' };
  const next = copy(state), actor = activeUnit(next)!;
  note(next, `${actor.name} termina su activación.`);
  if (actor.status) {
    const status = actor.status;
    const damage = status.kind === 'paralysis' ? 0 : Math.max(1, Math.floor(actor.maxHp / (status.kind === 'poison' ? 8 : 16)));
    actor.hp = Math.max(0, actor.hp - damage);
    note(next, `${actor.name}: ${STATUS_NAMES[status.kind]}${damage ? `, pierde ${damage} PS` : ''}.${actor.hp === 0 ? ' Fuera de combate.' : ''}`);
    actor.status = status.remaining > 1 ? { ...status, remaining: status.remaining - 1 } : null;
    if (!actor.status)
      note(next, `${actor.name}: termina ${STATUS_NAMES[status.kind]}.`);
  }
  next.completed = [...next.completed, actor.id];
  next.queue = next.queue.slice(1);
  next.moved = false;
  next.acted = false;
  resolveCasualties(next);
  if (next.outcome === 'playing') {
    if (!next.queue.length)
      newRound(next);
    else
      beginActivation(next);
  }
  return { ok: true, state: next };
}
export type TacticalCommand = {
  kind: 'attack';
  target: number;
  actionId?: string;
} | {
  kind: 'move';
  destination: Point;
} | {
  kind: 'finish';
};
function actionScore(state: Battle, target: Combatant, plan: AttackPlan): number {
  if (!plan.ok)
    return 0;
  if (plan.guard)
    return target.hp < target.maxHp * 0.7 && living(state).some(u => u.team !== target.team && distance(u, target) <= 2) ? 9 : 0;
  return (plan.damage + (plan.damage === target.hp ? 15 : 0) + plan.heal * 0.5 + (plan.status ? 8 * plan.status.chance / 100 : 0)) * plan.accuracy / 100;
}
// Same polymorphic action rules for player forecasts, enemy orders and deterministic simulations.
export function chooseTacticalCommand(state: Battle): TacticalCommand {
  const actor = activeUnit(state);
  if (!actor)
    return { kind: 'finish' };
  const targets = living(state).sort((a, b) => a.hp - b.hp || a.id - b.id);
  const actions = pokemonFor(actor.id).actions;
  const available = targets.flatMap(target => actions.map(action => {
    const id = action.definition.id, plan = attackPlan(state, target.id, undefined, id);
    return { target, id, score: actionScore(state, target, plan) };
  })).filter(option => option.score > 0).sort((a, b) => b.score - a.score || a.target.hp - b.target.hp || a.target.id - b.target.id || a.id.localeCompare(b.id));
  if (!state.acted && available[0])
    return { kind: 'attack', target: available[0].target.id, actionId: available[0].id };
  if (state.moved || state.acted)
    return { kind: 'finish' };
  const routes = routesFrom(state.board, living(state), actor.id);
  const approaches: {
    route: Route;
    target: Combatant;
    score: number;
  }[] = [];
  for (const route of routes.values())
    for (const target of targets.filter(u => u.team !== actor.team)) {
      if (route.cost <= 0)
        continue;
      const score = Math.max(...actions.filter(a => a.definition.target === 'enemy').map(a => actionScore(state, target, attackPlan(state, target.id, route.path.at(-1), a.definition.id))));
      if (score > 0)
        approaches.push({ route, target, score });
    }
  approaches.sort((a, b) => a.route.cost - b.route.cost || b.score - a.score || a.target.hp - b.target.hp || a.target.id - b.target.id || key(a.route.path.at(-1)!).localeCompare(key(b.route.path.at(-1)!)));
  const approach = approaches[0];
  if (!approach)
    return { kind: 'finish' };
  let spent = 0, destination: Point = actor;
  for (const step of approach.route.path.slice(1)) {
    const cost = tileCost(state.board, step);
    if (spent + cost > actor.remaining)
      break;
    spent += cost;
    destination = step;
  }
  return same(destination, actor) ? { kind: 'finish' } : { kind: 'move', destination };
}
export function applyCommand(state: Battle, command: TacticalCommand): RuleResult {
  return command.kind === 'move' ? moveInBattle(state, command.destination) : command.kind === 'attack' ? attackInBattle(state, command.target, command.actionId) : finishTurn(state);
}
