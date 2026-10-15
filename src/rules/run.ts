import type { PokemonSpecies } from '../data/catalog.ts';
import { INITIAL_SPECIES } from '../data/catalog.ts';
import { atLevel, levelFor, EVOLUTIONS } from '../domain/progression.ts';
import { zonesForEdition } from '../data/zones.ts';
import { runMap } from '../data/run-maps.ts';
import { pokemonFor } from '../domain/Pokemon.ts';
import { emptyBag, HealingItem, HeldItem, ITEMS, itemFor } from '../domain/items.ts';
import type { Bag, HeldItemId, ItemId } from '../domain/items.ts';
import { createEncounter, hashSeed, random } from './battle.ts';
import type { Battle } from './battle.ts';
import { createRun as createLegacyRun } from './legacy-run.ts';
import type { Run as LegacyRun } from './legacy-run.ts';

export type RunMember = { id: number; speciesId: number; hp: number; xp: number; heldItem: HeldItemId | null };
export type DepartedMember = RunMember & { reason: 'fallen' | 'released' };
export type RecruitOffer = { id: string; speciesId: number; price: number };
export type RunNode = { id: string; floor: number; kind: 'combat' | 'shop' | 'recruit'; next: string[]; mapId: string; enemies: number[]; offers: RecruitOffer[] };
export type RunRecord = { nodeId: string; outcome: 'victory' | 'defeat'; round: number; hp: { id: number; hp: number }[]; contribution?: { id: number; points: number }[] };
export type RunEvent =
  | { kind: 'enter'; nodeId: string }
  | { kind: 'leave' }
  | { kind: 'buy'; itemId: ItemId }
  | { kind: 'heal'; itemId: ItemId; memberId: number }
  | { kind: 'evolve'; memberId: number }
  | { kind: 'equip'; itemId: HeldItemId | null; memberId: number }
  | { kind: 'recruit'; offerId: string; replaceId: number | null }
  | ({ kind: 'result' } & RunRecord);
export type Run = {
  edition: number; seed: string; variance: number; status: 'route' | 'combat' | 'service' | 'victory' | 'defeat';
  roster: RunMember[]; departed: DepartedMember[]; nextMemberId: number;
  nodes: RunNode[]; path: string[]; history: RunRecord[]; currentNodeId: string | null; battle: Battle | null;
  money: number; bag: Bag; purchases: Record<string, Partial<Bag>>; recruited: string[]; events: RunEvent[];
};
export const CURRENT_EDITION = 13;
export const ROUTE_LENGTH = 6;
export const TEAM_LIMIT = 6;
export const STARTING_MONEY = 240;
export const VICTORY_REWARD = 100;
export const RECRUIT_PRICE = 80;
export const EVENT_LIMIT = 10000;
export const SHOP_STOCK: Bag = { potion: 4, 'super-potion': 2, leftovers: 1, 'assault-vest': 1, 'heavy-duty-boots': 1, 'rare-candy': 2, 'thunder-stone': 1 };
export const normalizeSeed = (seed: string): string => seed.trim().slice(0, 64) || 'kanto-001';
export const encounterSeed = (run: Pick<Run, 'seed'>, nodeId: string): string => `${hashSeed(run.seed).toString(16)}-${nodeId}`;
export const completedCombats = (run: Run): number => run.history.filter(record => record.outcome === 'victory').length;
export const maximumHp = (catalog: readonly PokemonSpecies[], speciesId: number, xp = 0): number => {
  const species = catalog.find(species => species.id === speciesId);
  if (!species) throw new Error('Especie desconocida.');
  return atLevel(pokemonFor(speciesId).createCombatant(species, 'ally', { x: 0, y: 0 }), levelFor(xp)).maxHp;
};
export const routeLength = (run: Run): number => Math.max(...run.nodes.map(node => node.floor));
export const nodeStep = (node: RunNode): number => node.kind === 'combat' ? node.floor * 2 : node.floor * 2 + 1;
export const currentNode = (run: Run): RunNode | undefined => run.nodes.find(node => node.id === run.currentNodeId);
export function createRun(catalog: readonly PokemonSpecies[], seed: string, variance = .05, edition = 6): Run {
  // Keep the existing team, combat maps and encounter seeds unchanged.
  const legacy = createLegacyRun(catalog, seed, variance);
  const rng = { rng: hashSeed(`services:${legacy.seed}`) };
  const pick = <T>(values: readonly T[]): T => values[Math.floor(random(rng) * values.length)];
  let nodes: RunNode[] = legacy.nodes.map(node => ({ ...node, kind: 'combat', offers: [],
    next: node.floor === ROUTE_LENGTH ? [] : [`shop-${node.floor}`, `recruit-${node.floor}`] }));
  const zones = edition >= 10 ? zonesForEdition(edition) : [];
  if (edition >= 10) {
    nodes = zones.flatMap((zone,index)=>zone.maps.map((mapId,branch)=>({id: 'zone-'+(index+1)+'-'+(branch+1),floor:index+1,kind:'combat' as const,mapId,enemies:[...zone.enemies[branch]],offers:[],next:['shop-'+(index+1),'recruit-'+(index+1)]})));
  }
  const stages = edition >= 10 ? zones.length : ROUTE_LENGTH;
  if (edition >= 8) {
    nodes.filter(node => node.floor === stages).forEach(node => { node.next = ['shop-'+stages, 'recruit-'+stages]; });
    if (edition >= 9) nodes.push({ id: 'final-psychic', floor: stages+1, kind: 'combat', next: [], mapId: 'psychic', enemies: [150,151], offers: [] });
    nodes.push({ id: 'final-birds', floor: stages+1, kind: 'combat', next: [], mapId: 'birds', enemies: [144,145,146], offers: [] });
  }
  for (let floor = 0; floor < (edition >= 8 ? stages+1 : ROUTE_LENGTH); floor++) {
    const next = nodes.filter(node => node.kind === 'combat' && node.floor === floor + 1).map(node => node.id);
    const candidates: number[] = [];
    const pool = floor === 0 ? INITIAL_SPECIES.filter(id => !legacy.roster.some(member => member.speciesId === id)) : [...new Set([...INITIAL_SPECIES, ...zones.flatMap(zone=>zone.enemies.flat()).filter(id=>![2,3,5,6,8,9,26,75,76].includes(id))])];
    while (candidates.length < 3) candidates.push(pick(pool.filter(id => !candidates.includes(id))));
    nodes.push({ id: `shop-${floor}`, floor, kind: 'shop', mapId: '', enemies: [], offers: [], next });
    nodes.push({ id: `recruit-${floor}`, floor, kind: 'recruit', mapId: '', enemies: [], next,
      offers: candidates.map((speciesId, index) => ({ id: `recruit-${floor}:${index}`, speciesId, price: RECRUIT_PRICE })) });
  }
  return { edition, seed: legacy.seed, variance, status: 'route', roster: legacy.roster.map(member => ({ ...member, xp: 0, heldItem: null })),
    departed: [], nextMemberId: 4, nodes, path: [], history: [], currentNodeId: null, battle: null,
    money: STARTING_MONEY, bag: { ...emptyBag(), potion: 1 }, purchases: {}, recruited: [], events: [] };
}
export function availableNodes(run: Run): RunNode[] {
  if (run.status !== 'route') return [];
  const last = run.path.at(-1);
  const ids = last ? run.nodes.find(node => node.id === last)!.next : ['shop-0', 'recruit-0'];
  return run.nodes.filter(node => ids.includes(node.id));
}
export function remainingStock(run: Run, itemId: ItemId): number {
  const node = currentNode(run);
  return node?.kind === 'shop' ? SHOP_STOCK[itemId] - (run.purchases[node.id]?.[itemId] ?? 0) : 0;
}
function requireRule(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
function readyMember(run: Run, memberId: number): RunMember {
  requireRule(run.status === 'route' || run.status === 'service', 'La gestión del equipo solo está disponible fuera de combate.');
  const member = run.roster.find(member => member.id === memberId && member.hp > 0);
  requireRule(member, 'Este Pokémon ya no está en el equipo. Los perdidos no pueden revivir.');
  return member;
}
function returnEquipment(run: Run, member: RunMember): void {
  if (member.heldItem) { run.bag[member.heldItem]++; member.heldItem = null; }
}
function recordResult(run: Run, event: Extract<RunEvent, { kind: 'result' }>): void {
  const node = currentNode(run);
  requireRule(run.status === 'combat' && node?.kind === 'combat' && node.id === event.nodeId, 'No hay un combate pendiente de resolver.');
  requireRule(Number.isInteger(event.round) && event.round > 0 && event.round <= 100000 && ['victory', 'defeat'].includes(event.outcome), 'Resultado no válido.');
  requireRule(Array.isArray(event.hp) && event.hp.length === run.roster.length, 'Faltan miembros en el resultado.');
  run.roster.forEach((member, index) => {
    const entry = event.hp[index];
    requireRule(entry?.id === member.id && Number.isInteger(entry.hp) && entry.hp >= 0 && entry.hp <= run.battle!.units.find(unit => unit.id === member.id)!.maxHp, 'PS del resultado no válidos.');
    member.hp = entry.hp;
  });
  requireRule(event.outcome === 'defeat' ? run.roster.every(member => member.hp === 0) : run.roster.some(member => member.hp > 0), 'El resultado no coincide con los supervivientes.');
  if (run.edition >= 7) {
    requireRule(Array.isArray(event.contribution) && event.contribution.length === run.roster.length, 'Falta la contribución individual.');
    run.roster.forEach((member, index) => {
      const receipt = event.contribution![index];
      requireRule(receipt.id === member.id && Number.isInteger(receipt.points) && receipt.points >= 0 && receipt.points <= event.round * 30, 'Contribución no válida.');
      if (member.hp > 0 && event.outcome === 'victory') member.xp = Math.min(240, member.xp + 20 + Math.min(40, receipt.points));
    });
  }
  const fallen = run.roster.filter(member => member.hp === 0);
  fallen.forEach(member => { returnEquipment(run, member); run.departed.push({ ...member, reason: 'fallen' }); });
  run.roster = run.roster.filter(member => member.hp > 0);
  run.history.push({ nodeId: event.nodeId, round: event.round, outcome: event.outcome, hp: structuredClone(event.hp), ...(event.contribution ? { contribution: structuredClone(event.contribution) } : {}) });
  if (event.outcome === 'victory') { run.path.push(node.id); run.money += VICTORY_REWARD; }
  run.status = event.outcome === 'defeat' ? 'defeat' : node.next.length === 0 ? 'victory' : 'route';
  run.currentNodeId = null; run.battle = null;
}
// One transition implementation serves gameplay and save replay. It consumes no battle RNG.
function applyEvent(run: Run, event: RunEvent, catalog: readonly PokemonSpecies[]): void {
  requireRule(typeof event === 'object' && event !== null, 'Operación no válida.');
  switch (event.kind) {
    case 'enter': {
      const node = availableNodes(run).find(node => node.id === event.nodeId);
      requireRule(node, 'Esta sala no está conectada a tu ruta.');
      run.currentNodeId = node.id;
      if (node.kind === 'combat') {
        run.battle = createEncounter(catalog, encounterSeed(run, node.id), run.variance, runMap(node.mapId).board, run.roster, node.enemies, { progression: run.edition >= 7, hazards: runMap(node.mapId).hazards });
        run.status = 'combat';
      } else run.status = 'service';
      break;
    }
    case 'leave': {
      const node = currentNode(run);
      requireRule(run.status === 'service' && node && node.kind !== 'combat', 'No hay una sala de servicios abierta.');
      run.path.push(node.id); run.currentNodeId = null; run.status = 'route';
      break;
    }
    case 'buy': {
      const item = itemFor(event.itemId), node = currentNode(run);
      requireRule(run.status === 'service' && node?.kind === 'shop', 'Solo puedes comprar en la tienda.');
      requireRule(remainingStock(run, item.id) > 0, 'Esta oferta está agotada.');
      requireRule(run.money >= item.price, 'No tienes dinero suficiente.');
      run.money -= item.price; run.bag[item.id]++;
      const purchases = run.purchases[node.id] ?? {};
      purchases[item.id] = (purchases[item.id] ?? 0) + 1; run.purchases[node.id] = purchases;
      break;
    }
    case 'heal': {
      const member = readyMember(run, event.memberId), item = itemFor(event.itemId);
      requireRule(item instanceof HealingItem && run.bag[item.id] > 0, 'No tienes ese consumible curativo.');
      const recovery = item.restored(member.hp, maximumHp(catalog, member.speciesId, member.xp));
      requireRule(recovery > 0, 'Este Pokémon ya tiene todos sus PS.');
      member.hp += recovery; run.bag[item.id]--;
      break;
    }
    case 'evolve': {
      const member = readyMember(run, event.memberId), evolution = EVOLUTIONS[member.speciesId];
      requireRule(run.edition >= 7 && evolution, 'Esta especie no tiene evolución disponible.');
      requireRule(run.bag[evolution.item] > 0, 'No tienes el objeto evolutivo compatible.');
      member.speciesId = evolution.target; run.bag[evolution.item]--;
      // Preserve absolute current HP: evolution and levels never replace healing.
      member.hp = Math.min(member.hp, maximumHp(catalog, member.speciesId, member.xp));
      break;
    }
    case 'equip': {
      const member = readyMember(run, event.memberId);
      requireRule(event.itemId !== member.heldItem, 'Ese objeto ya está equipado.');
      if (event.itemId !== null) {
        const item = itemFor(event.itemId);
        requireRule(item instanceof HeldItem && run.bag[item.id] > 0, 'No tienes ese objeto equipable en la bolsa.');
        run.bag[item.id]--;
      }
      returnEquipment(run, member); member.heldItem = event.itemId;
      break;
    }
    case 'recruit': {
      const node = currentNode(run);
      requireRule(run.status === 'service' && node?.kind === 'recruit', 'Solo puedes reclutar en una sala de reclutamiento.');
      const offer = node.offers.find(offer => offer.id === event.offerId);
      requireRule(offer && !run.recruited.includes(offer.id), 'Esta oferta ya no está disponible.');
      requireRule(run.money >= offer.price, 'No tienes dinero suficiente.');
      if (event.replaceId !== null) {
        const replaced = run.roster.find(member => member.id === event.replaceId);
        requireRule(replaced, 'El equipo está completo. Elige a quién sustituir y confirma.');
        returnEquipment(run, replaced);
        run.departed.push({ ...replaced, reason: 'released' });
        run.roster = run.roster.filter(member => member.id !== replaced.id);
      } else requireRule(run.roster.length < TEAM_LIMIT, 'El equipo está completo. Elige a quién sustituir y confirma.');
      run.money -= offer.price; run.recruited.push(offer.id);
      run.roster.push({ id: run.nextMemberId++, speciesId: offer.speciesId, hp: maximumHp(catalog, offer.speciesId), xp: 0, heldItem: null });
      break;
    }
    case 'result': recordResult(run, event); break;
    default: throw new Error('Operación desconocida.');
  }
}
export function performRunEvent(run: Run, event: RunEvent, catalog: readonly PokemonSpecies[]): Run {
  requireRule(run.events.length < EVENT_LIMIT, 'El registro de esta partida está completo.');
  const next = structuredClone(run);
  applyEvent(next, event, catalog);
  next.events.push(structuredClone(event));
  return next;
}
export function replayRun(catalog: readonly PokemonSpecies[], seed: string, variance: number, events: readonly RunEvent[], edition = 6): Run {
  requireRule(Array.isArray(events) && events.length <= EVENT_LIMIT, 'Registro de operaciones no válido.');
  const run = createRun(catalog, seed, variance, edition);
  events.forEach(event => applyEvent(run, event, catalog));
  run.events = structuredClone([...events]);
  return run;
}
export const enterRoom = (run: Run, nodeId: string, catalog: readonly PokemonSpecies[]): Run => performRunEvent(run, { kind: 'enter', nodeId }, catalog);
export function enterEncounter(run: Run, nodeId: string, catalog: readonly PokemonSpecies[]): Run {
  requireRule(run.nodes.find(node => node.id === nodeId)?.kind === 'combat', 'Esta sala no es un combate.');
  return enterRoom(run, nodeId, catalog);
}
export const leaveService = (run: Run, catalog: readonly PokemonSpecies[]): Run => performRunEvent(run, { kind: 'leave' }, catalog);
export function withBattle(run: Run, battle: Battle): Run {
  requireRule(run.status === 'combat' && run.battle && battle.seed === run.battle.seed, 'Combate ajeno a la partida.');
  return { ...run, battle: structuredClone(battle) };
}
export function completeEncounter(run: Run, catalog: readonly PokemonSpecies[]): Run {
  requireRule(run.status === 'combat' && run.battle && run.battle.outcome !== 'playing' && run.currentNodeId, 'El combate todavía no ha terminado.');
  return performRunEvent(run, { kind: 'result', nodeId: run.currentNodeId, outcome: run.battle.outcome, round: run.battle.round,
    hp: run.roster.map(member => ({ id: member.id, hp: run.battle!.units.find(unit => unit.team === 'ally' && unit.id === member.id)!.hp })),
    ...(run.edition >= 7 ? { contribution: run.roster.map(member => ({ id: member.id, points: run.battle!.contributions?.[member.id] ?? 0 })) } : {}) }, catalog);
}
export function migrateLegacyRun(legacy: LegacyRun, catalog: readonly PokemonSpecies[]): Run {
  let run = createRun(catalog, legacy.seed, legacy.variance);
  for (const record of legacy.history) {
    const floor = Number(record.nodeId.split('-')[0]);
    run = leaveService(enterRoom(run, `shop-${floor - 1}`, catalog), catalog);
    run = enterEncounter(run, record.nodeId, catalog);
    run = performRunEvent(run, { kind: 'result', ...record, hp: run.roster.map(member => ({ id: member.id, hp: record.hp[member.id - 1] })) }, catalog);
  }
  if (legacy.status === 'combat') {
    const floor = Number(legacy.currentNodeId!.split('-')[0]);
    run = leaveService(enterRoom(run, `shop-${floor - 1}`, catalog), catalog);
    run = enterEncounter(run, legacy.currentNodeId!, catalog);
    const battle = structuredClone(legacy.battle!);
    battle.units.forEach(unit => { unit.heldItem = null; });
    run = withBattle(run, battle);
  }
  return run;
}
export const shopItems = (): readonly typeof ITEMS[number][] => ITEMS;
