import type { PokemonSpecies } from '../data/catalog.ts';
import { INITIAL_SPECIES } from '../data/catalog.ts';
import { runMap } from '../data/run-maps.ts';
import { pokemonFor } from '../domain/Pokemon.ts';
import { createEncounter, hashSeed, random } from './battle.ts';
import type { Battle } from './battle.ts';

export type RunMember = { id: number; speciesId: number; hp: number };
export type RunNode = { id: string; floor: number; next: string[]; mapId: string; enemies: number[] };
export type RunRecord = { nodeId: string; outcome: 'victory' | 'defeat'; round: number; hp: number[] };
export type Run = {
  seed: string; variance: number; status: 'route' | 'combat' | 'victory' | 'defeat';
  roster: RunMember[]; nodes: RunNode[]; path: string[]; history: RunRecord[];
  currentNodeId: string | null; battle: Battle | null;
};
export const ROUTE_LENGTH = 6;
export const normalizeSeed = (seed: string): string => seed.trim().slice(0, 64) || 'kanto-001';
export const encounterSeed = (run: Run, nodeId: string): string => `${hashSeed(run.seed).toString(16)}-${nodeId}`;
export function createRun(catalog: readonly PokemonSpecies[], seed: string, variance = 0.05): Run {
  if (![0.05, 0.1].includes(variance)) throw new Error('Variación no válida.');
  const normalized = normalizeSeed(seed), rng = { rng: hashSeed(normalized) };
  const pick = <T>(values: readonly T[]): T => values[Math.floor(random(rng) * values.length)];
  const team = [pick([7, 74]), pick([4, 12, 25])];
  team.push(pick(INITIAL_SPECIES.filter(id => !team.includes(id))));
  const roster = team.map((speciesId, index) => {
    const species = catalog.find(species => species.id === speciesId);
    if (!species) throw new Error('Catálogo incompleto.');
    return { id: index + 1, speciesId, hp: pokemonFor(speciesId).createCombatant(species, 'ally', { x: 0, y: 0 }).maxHp };
  });
  const nodes: RunNode[] = [];
  const widths = [1, 2, 2, 2, 2, 1];
  for (let floor = 0; floor < ROUTE_LENGTH; floor++) {
    for (let branch = 0; branch < widths[floor]; branch++) {
      // Introduce terrain progressively. Encounters keep the existing three-enemy format.
      const pool = floor === 0 ? ['quarry'] : floor < 3 ? ['quarry', 'pass'] : ['quarry', 'pass', 'pond'];
      const companions = [...INITIAL_SPECIES.filter(id => id !== 74)];
      const first = pick(companions);
      const second = pick(companions.filter(id => id !== first));
      nodes.push({ id: `${floor + 1}-${branch + 1}`, floor: floor + 1,
        next: floor === ROUTE_LENGTH - 1 ? [] : Array.from({ length: widths[floor + 1] }, (_, b) => `${floor + 2}-${b + 1}`),
        mapId: pick(pool), enemies: [first, second, 74] });
    }
  }
  return { seed: normalized, variance, status: 'route', roster, nodes, path: [], history: [], currentNodeId: null, battle: null };
}
export function availableNodes(run: Run): RunNode[] {
  if (run.status !== 'route') return [];
  const last = run.path.at(-1);
  const ids = last ? run.nodes.find(node => node.id === last)!.next : ['1-1'];
  return run.nodes.filter(node => ids.includes(node.id));
}
export function enterEncounter(run: Run, nodeId: string, catalog: readonly PokemonSpecies[]): Run {
  const node = availableNodes(run).find(node => node.id === nodeId);
  if (!node) throw new Error('Esta sala no está conectada a tu ruta.');
  const battle = createEncounter(catalog, encounterSeed(run, nodeId), run.variance, runMap(node.mapId).board,
    run.roster.filter(member => member.hp > 0), node.enemies);
  return { ...structuredClone(run), status: 'combat', currentNodeId: nodeId, battle };
}
export function withBattle(run: Run, battle: Battle): Run {
  if (run.status !== 'combat' || !run.battle || battle.seed !== run.battle.seed) throw new Error('Combate ajeno a la partida.');
  return { ...run, battle: structuredClone(battle) };
}
export function completeEncounter(run: Run): Run {
  if (run.status !== 'combat' || !run.battle || run.battle.outcome === 'playing' || !run.currentNodeId)
    throw new Error('El combate todavía no ha terminado.');
  const battle = run.battle, next = structuredClone(run);
  next.roster.forEach(member => {
    const unit = battle.units.find(unit => unit.team === 'ally' && unit.id === member.id);
    if (unit) member.hp = unit.hp;
  });
  next.history.push({ nodeId: run.currentNodeId, outcome: battle.outcome === 'victory' ? 'victory' : 'defeat', round: battle.round, hp: next.roster.map(member => member.hp) });
  if (battle.outcome === 'victory') next.path.push(run.currentNodeId);
  next.status = battle.outcome === 'defeat' ? 'defeat' : next.path.length === ROUTE_LENGTH ? 'victory' : 'route';
  next.battle = null;
  next.currentNodeId = null;
  return next;
}
