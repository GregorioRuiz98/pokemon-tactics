import { commitMove, coordinate, facingFrom, key, routesFrom, same, tileCost } from './movement.ts';
import type { Board, Point, Route, Facing } from './movement.ts';
import { attackSide, FACINGS, FACING_NAMES, FACING_VECTORS, positionalAccuracy } from './position.ts';
import type { AttackSide } from './position.ts';
import { TACTICAL_BOARD, blocksSight, supportsEmbers, fieldDamage } from './terrain.ts';
import type { TerrainField } from './terrain.ts';
import type { PokemonSpecies } from '../data/catalog.ts';
import { pokemonFor } from '../domain/Pokemon.ts';
import { atLevel, levelFor } from '../domain/progression.ts';
import { heldItemFor } from '../domain/items.ts';
import type { HeldItemId } from '../domain/items.ts';
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
  composition: Composition | 'run';
  round: number;
  board: Board;
  fields: TerrainField[];
  units: Combatant[];
  initiative: Initiative[];
  queue: number[];
  completed: number[];
  moved: boolean;
  acted: boolean;
  outcome: 'playing' | 'victory' | 'defeat';
  contributions?: Record<number, number>;
  log: string[];
};
export const living = (state: Battle): Combatant[] => state.units.filter(u => u.hp > 0);
export const activeUnit = (state: Battle): Combatant | undefined => state.outcome === 'playing' ? state.units.find(u => u.id === state.queue[0] && u.hp > 0) : undefined;
export const distance = (a: Point, b: Point): number => Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
const copy = (state: Battle): Battle => structuredClone(state);
function note(state: Battle, message: string): void { state.log = [...state.log, message].slice(-40); }
export function hashSeed(seed: string): number {
  let value = 2166136261;
  for (const character of seed)
    value = Math.imul(value ^ character.charCodeAt(0), 16777619);
  return value >>> 0;
}
export function random(state: { rng: number }): number {
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
  state.fields = state.fields.filter(field => field.expires > state.round);
  state.initiative = living(state).sort((a, b) => a.id - b.id).map(u => ({
    id: u.id, score: effectiveSpeed(u) * (1 + (random(state) * 2 - 1) * state.variance), tie: random(state),
  })).sort((a, b) => b.score - a.score || a.tie - b.tie || a.id - b.id);
  state.queue = state.initiative.map(i => i.id);
  state.completed = [];
  state.units.forEach(u => {
    if (u.hp > 0)
      u.remaining = movementBudget(u);
  });
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
  const state: Battle = { seed: normalizedSeed, rng: hashSeed(normalizedSeed), variance, composition, round: 0, board: TACTICAL_BOARD, fields: [], units, initiative: [], queue: [], completed: [], moved: false, acted: false, outcome: 'playing', log: [] };
  newRound(state);
  return state;
}
// Instance IDs identify units; species IDs select data, actions and shared textures.
export function createEncounter(catalog: readonly PokemonSpecies[], seed: string, variance: number, board: Board,
  allies: readonly { id: number; speciesId: number; hp: number; heldItem?: HeldItemId | null; xp?: number }[], enemies: readonly number[], options: { progression?: boolean } = {}): Battle {
  if (![0.05, 0.1].includes(variance) || allies.length < 1 || allies.length > 6 || enemies.length !== 3)
    throw new Error('Encuentro no válido.');
  const allyPositions = [{ x: 1, y: 6 }, { x: 3, y: 6 }, { x: 2, y: 7 }, { x: 0, y: 6 }, { x: 4, y: 6 }, { x: 4, y: 7 }];
  const enemyPositions = [{ x: 5, y: 1 }, { x: 6, y: 2 }, { x: 5, y: 4 }];
  const create = (id: number, speciesId: number, team: Team, position: Point, hp?: number): Combatant => {
    const species = catalog.find(p => p.id === speciesId);
    if (!species) throw new Error(`Falta la especie ${speciesId}.`);
    const xp = team === 'ally' ? allies.find(member => member.id === id)?.xp ?? 0 : 0;
    const unit = atLevel(pokemonFor(speciesId).createCombatant(species, team, position), options.progression ? levelFor(xp) : 1);
    unit.id = id;
    if (hp !== undefined) {
      if (!Number.isInteger(hp) || hp < 1 || hp > unit.maxHp) throw new Error('PS iniciales no válidos.');
      unit.hp = hp;
    }
    if (!Number.isFinite(tileCost(board, unit, unit.profile))) throw new Error('Despliegue bloqueado.');
    return unit;
  };
  const units = [
    ...allies.map((member, index) => {
      const unit = create(member.id, member.speciesId, 'ally', allyPositions[index], member.hp);
      heldItemFor(member.heldItem);
      return { ...unit, heldItem: member.heldItem ?? null };
    }),
    ...enemies.map((speciesId, index) => create(1000 + index, speciesId, 'enemy', enemyPositions[index])),
  ];
  if (new Set(units.map(unit => unit.id)).size !== units.length) throw new Error('Identidades duplicadas.');
  const state: Battle = { seed, rng: hashSeed(seed), variance, composition: 'run', ...(options.progression ? { contributions: {} } : {}), round: 0, board, fields: [], units,
    initiative: [], queue: [], completed: [], moved: false, acted: false, outcome: 'playing', log: [] };
  newRound(state);
  return state;
}
export type RuleResult = {
  ok: true;
  state: Battle;
  route?: Route;
  damage?: number;
  hit?: boolean;
  hits?: {
    targetId: number;
    hit: boolean;
    damage: number;
    push?: Point;
  }[];
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
export const basicDamage = (actor: Combatant, target: Combatant): number => pokemonFor(actor.speciesId).action('basic')!.preview(actor, target).damage;
function clearShot(state: Battle, actor: Combatant, target: Combatant): boolean {
  const dx = target.x - actor.x, dy = target.y - actor.y;
  if (distance(actor, target) <= 1)
    return true;
  const intermediates: Point[] = dx === 0 ? [{ x: actor.x, y: actor.y + Math.sign(dy) }] : dy === 0 ? [{ x: actor.x + Math.sign(dx), y: actor.y }] : [{ x: target.x, y: actor.y }, { x: actor.x, y: target.y }];
  return intermediates.every(p => !blocksSight(state.board, p) && !living(state).some(u => u.id !== actor.id && same(u, p)));
}
export type HitPlan = ActionEffect & {
  targetId: number;
  accuracy: number;
  side: AttackSide | null;
  push: Point | null;
  pushReason: string | null;
};
export type AttackPlan = ({
  ok: true;
  actionId: string;
  name: string;
  cost: number;
  accuracy: number;
  side: AttackSide | null;
  push: Point | null;
  pushReason: string | null;
  hits: HitPlan[];
  tiles: Point[];
  embers: Point[];
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
  const action = pokemonFor(active.speciesId).action(actionId);
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
  if (effect.category === 'status' && heldItemFor(actor.heldItem)?.allowsStatus() === false)
    return { ok: false, reason: 'Chaleco Asalto impide acciones de estado y apoyo.' };
  if (effect.category === 'status' && effect.statusReason)
    return { ok: false, reason: effect.statusReason };
  if (effect.guard && target.guarded)
    return { ok: false, reason: 'El objetivo ya está protegido.' };
  const tiles = action.affectedTiles(target).filter(point => !blocksSight(state.board, point));
  const area = tiles.length > 1;
  const hits: HitPlan[] = living(state).filter(unit => tiles.some(point => same(point, unit)) && (!area || unit.id !== actor.id)).sort((a, b) => a.id - b.id).map(unit => {
    const preview = action.preview(actor, unit);
    const side = definition.target === 'enemy' ? attackSide(actor, unit) : null;
    const accuracy = side ? positionalAccuracy(definition.accuracy, side) : definition.accuracy;
    let push: Point | null = null, pushReason: string | null = null;
    if (action.displacement()) {
      const vector = FACING_VECTORS[facingFrom(actor, unit)];
      const destination = { x: unit.x + vector.x, y: unit.y + vector.y };
      if (preview.damage === 0)
        pushReason = 'Inmune: no hay empuje.';
      else if (preview.damage >= unit.hp)
        pushReason = 'Si acierta, cae antes del empuje.';
      else if (!Number.isFinite(tileCost(state.board, destination, unit.profile)))
        pushReason = 'El borde o terreno bloquea el empuje.';
      else if (living(state).some(occupant => same(occupant, destination)))
        pushReason = 'Una unidad bloquea el empuje.';
      else
        push = destination;
    }
    return { ...preview, targetId: unit.id, accuracy, side, push, pushReason };
  });
  const primary = hits.find(hit => hit.targetId === targetId)!;
  return { ok: true, actionId, name: definition.name, cost: definition.cost, ...primary, hits, tiles, embers: action.leavesEmbers() ? tiles.filter(point => supportsEmbers(state.board, point)) : [] };
}
function resolveCasualties(state: Battle): void {
  state.queue = state.queue.filter(id => state.units.some(u => u.id === id && u.hp > 0));
  state.outcome = !living(state).some(u => u.team === 'ally') ? 'defeat' : !living(state).some(u => u.team === 'enemy') ? 'victory' : 'playing';
  if (state.outcome !== 'playing') {
    state.queue = [];
    note(state, state.outcome === 'victory' ? 'Victoria: zona despejada.' : 'Derrota: el equipo ha caído.');
  }
}
export function attackInBattle(state: Battle, targetId: number, actionId = 'basic'): RuleResult {
  const plan = attackPlan(state, targetId, undefined, actionId);
  if (!plan.ok)
    return plan;
  const next = copy(state), actor = activeUnit(next)!, primary = next.units.find(unit => unit.id === targetId)!;
  actor.tp -= plan.cost;
  next.acted = true;
  if (next.contributions) next.contributions[actor.id] = (next.contributions[actor.id] ?? 0) + 8;
  if (actor.id !== primary.id)
    actor.facing = facingFrom(actor, primary);
  const hits: NonNullable<Extract<RuleResult, {
    ok: true;
  }>['hits']> = [];
  note(next, `${actor.name} usa ${plan.name} (${plan.cost} PT).`);
  for (const forecast of plan.hits) {
    const target = next.units.find(unit => unit.id === forecast.targetId)!;
    const hit = forecast.accuracy === 100 || random(next) * 100 < forecast.accuracy;
    if (!hit) {
      note(next, `${target.name}: el ataque falla (${forecast.accuracy} %).`);
      hits.push({ targetId: target.id, hit: false, damage: 0 });
      continue;
    }
    target.hp = Math.max(0, target.hp - forecast.damage);
    actor.hp = Math.min(actor.maxHp, actor.hp + forecast.heal);
    if (forecast.guard)
      target.guarded = true;
    if (forecast.status && target.hp > 0 && (forecast.status.chance === 100 || random(next) * 100 < forecast.status.chance)) {
      target.status = { kind: forecast.status.kind, remaining: forecast.status.duration };
      note(next, `${target.name}: ${STATUS_NAMES[forecast.status.kind]} (${forecast.status.duration} activaciones).`);
    }
    if (forecast.push && target.hp > 0)
      Object.assign(target, forecast.push);
    hits.push({ targetId: target.id, hit: true, damage: forecast.damage, ...(forecast.push && target.hp > 0 ? { push: forecast.push } : {}) });
    note(next, `${target.name}: ${forecast.damage} PS${forecast.multiplier !== 1 ? `, eficacia ×${forecast.multiplier}` : ''}.${forecast.heal ? ` Recupera ${forecast.heal} PS.` : ''}${forecast.guard ? ' Protegido hasta su próxima activación.' : ''}${forecast.push && target.hp > 0 ? ` Empujado a ${coordinate(forecast.push)}.` : ''}${target.hp === 0 ? ' Fuera de combate.' : ''}`);
  }
  for (const point of plan.embers) {
    const field: TerrainField = { x: point.x, y: point.y, kind: 'embers', expires: state.round + 2 };
    next.fields = [...next.fields.filter(existing => !same(existing, point)), field];
  }
  if (plan.embers.length)
    note(next, `Ascuas en ${plan.embers.map(coordinate).join(', ')}: 4 PS al cerrar turno; duran hasta la ronda ${state.round + 2}.`);
  resolveCasualties(next);
  const hit = hits.find(entry => entry.targetId === targetId)!;
  return { ok: true, state: next, damage: hit.damage, hit: hit.hit, hits };
}
export function finishTurn(state: Battle, facing?: Facing): RuleResult {
  const active = activeUnit(state);
  if (!active)
    return { ok: false, reason: 'El combate ha terminado.' };
  if (facing !== undefined && !(FACINGS as readonly number[]).includes(facing))
    return { ok: false, reason: 'Elige una orientación cardinal válida.' };
  const next = copy(state), actor = activeUnit(next)!;
  actor.facing = facing ?? actor.facing;
  note(next, `${actor.name} termina su activación mirando al ${FACING_NAMES[actor.facing]}.`);
  if (actor.status) {
    const status = actor.status;
    const damage = status.kind === 'paralysis' ? 0 : Math.max(1, Math.floor(actor.maxHp / (status.kind === 'poison' ? 8 : 16)));
    actor.hp = Math.max(0, actor.hp - damage);
    note(next, `${actor.name}: ${STATUS_NAMES[status.kind]}${damage ? `, pierde ${damage} PS` : ''}.${actor.hp === 0 ? ' Fuera de combate.' : ''}`);
    actor.status = status.remaining > 1 ? { ...status, remaining: status.remaining - 1 } : null;
    if (!actor.status)
      note(next, `${actor.name}: termina ${STATUS_NAMES[status.kind]}.`);
  }
  const hazard = actor.hp > 0 ? fieldDamage(actor, next.fields) : 0;
  if (hazard) {
    actor.hp = Math.max(0, actor.hp - hazard);
    note(next, `${actor.name}: ascuas, pierde ${hazard} PS.${actor.hp === 0 ? ' Fuera de combate.' : ''}`);
  }
  const recovery = heldItemFor(actor.heldItem)?.endTurnRecovery(actor) ?? 0;
  if (recovery) {
    actor.hp += recovery;
    note(next, `${actor.name}: Restos, recupera ${recovery} PS.`);
  }
  if (next.contributions) next.contributions[actor.id] = (next.contributions[actor.id] ?? 0) + 2;
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
  facing?: Facing;
};
function actionScore(state: Battle, target: Combatant, plan: AttackPlan): number {
  if (!plan.ok)
    return 0;
  const actor = activeUnit(state)!;
  if (plan.guard)
    return target.hp < target.maxHp * 0.7 && living(state).some(unit => unit.team !== target.team && distance(unit, target) <= 2) ? 9 : 0;
  return plan.hits.reduce((sum, hit) => {
    const affected = state.units.find(unit => unit.id === hit.targetId)!;
    const benefit = hit.damage + (hit.damage >= affected.hp ? 15 : 0) + (hit.status ? 8 * hit.status.chance / 100 : 0) + (hit.push ? 3 : 0);
    return sum + benefit * hit.accuracy / 100 * (affected.team === actor.team ? -2 : 1) + hit.heal * 0.5;
  }, 0);
}
function dangerAt(state: Battle, actor: Combatant, point: Point): number {
  const placed = { ...actor, ...point };
  const exposure = living(state).filter(unit => unit.team !== actor.team).reduce((sum, enemy) => {
    const reach = pokemonFor(enemy.speciesId).action('basic')!;
    return sum + (distance(enemy, placed) <= reach.definition.range + movementBudget(enemy) ? reach.preview(enemy, placed).damage / (distance(enemy, placed) + 1) : 0);
  }, 0);
  return fieldDamage(placed, state.fields) * 2 + exposure * 0.3;
}
export function chooseFacing(state: Battle, actor: Combatant): Facing {
  return [...FACINGS].sort((a, b) => {
    const exposure = (facing: Facing) => living(state).filter(unit => unit.team !== actor.team).reduce((sum, enemy) => {
      const basic = pokemonFor(enemy.speciesId).action('basic')!;
      return sum + basic.preview(enemy, actor).damage * positionalAccuracy(basic.definition.accuracy, attackSide(enemy, { ...actor, facing })) / (distance(enemy, actor) + 1);
    }, 0);
    return exposure(a) - exposure(b) || Number(b === actor.facing) - Number(a === actor.facing) || FACINGS.indexOf(a) - FACINGS.indexOf(b);
  })[0];
}
function affordableDestination(state: Battle, actor: Combatant, route: Route): Point {
  let spent = 0, destination: Point = actor;
  for (const step of route.path.slice(1)) {
    const cost = tileCost(state.board, step, actor.profile);
    if (spent + cost > actor.remaining)
      break;
    spent += cost;
    // Allies can be crossed, but a budget may never leave the mover on top of one.
    if (!living(state).some(unit => unit.id !== actor.id && same(unit, step)))
      destination = step;
  }
  return destination;
}
// Player and AI share routes, aim, polymorphic effects and legal destinations. No forecast consumes RNG.
export function chooseTacticalCommand(state: Battle): TacticalCommand {
  const actor = activeUnit(state);
  if (!actor)
    return { kind: 'finish' };
  const finish: TacticalCommand = { kind: 'finish', facing: chooseFacing(state, actor) };
  const targets = living(state).sort((a, b) => a.hp - b.hp || a.id - b.id);
  const actions = pokemonFor(actor.speciesId).actions;
  if (!state.acted) {
    const available = targets.flatMap(target => actions.map(action => {
      const id = action.definition.id, plan = attackPlan(state, target.id, undefined, id);
      return { target, id, score: actionScore(state, target, plan) };
    })).filter(option => option.score > 0).sort((a, b) => b.score - a.score || a.target.hp - b.target.hp || a.target.id - b.target.id || a.id.localeCompare(b.id));
    if (available[0])
      return { kind: 'attack', target: available[0].target.id, actionId: available[0].id };
  }
  if (state.moved)
    return finish;
  const routes = routesFrom(state.board, living(state), actor.id);
  if (state.acted) {
    const safer = [...routes.values()].filter(route => route.cost > 0 && route.cost <= actor.remaining).map(route => ({ route, danger: dangerAt(state, actor, route.path.at(-1)!) })).sort((a, b) => a.danger - b.danger || a.route.cost - b.route.cost || key(a.route.path.at(-1)!).localeCompare(key(b.route.path.at(-1)!)));
    return safer[0] && safer[0].danger + 2 < dangerAt(state, actor, actor) ? { kind: 'move', destination: safer[0].route.path.at(-1)! } : finish;
  }
  const approaches: {
    route: Route;
    target: Combatant;
    score: number;
    destination: Point;
  }[] = [];
  for (const route of routes.values())
    for (const target of targets.filter(unit => unit.team !== actor.team)) {
      if (route.cost <= 0)
        continue;
      const destination = affordableDestination(state, actor, route);
      if (same(destination, actor))
        continue;
      const value = Math.max(...actions.filter(action => action.definition.target === 'enemy').map(action => actionScore(state, target, attackPlan(state, target.id, route.path.at(-1), action.definition.id))));
      if (value > 0)
        approaches.push({ route, target, destination, score: value / (1 + route.cost * 0.3) - dangerAt(state, actor, destination) });
    }
  approaches.sort((a, b) => b.score - a.score || a.route.cost - b.route.cost || a.target.hp - b.target.hp || a.target.id - b.target.id || key(a.destination).localeCompare(key(b.destination)));
  return approaches[0] ? { kind: 'move', destination: approaches[0].destination } : finish;
}
export function applyCommand(state: Battle, command: TacticalCommand): RuleResult {
  return command.kind === 'move' ? moveInBattle(state, command.destination) : command.kind === 'attack' ? attackInBattle(state, command.target, command.actionId) : finishTurn(state, command.facing);
}
