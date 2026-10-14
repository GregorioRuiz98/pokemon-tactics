import type { PokemonSpecies } from './catalog.ts';
import { runMap } from './run-maps.ts';
import { pokemonFor } from '../domain/Pokemon.ts';
import { supportsEmbers } from '../rules/terrain.ts';
import { tileCost, key } from '../rules/movement.ts';
import { replayRun, migrateLegacyRun, encounterSeed } from '../rules/run.ts';
import { validateLegacyRun } from './legacy-run-store.ts';
import type { Run } from '../rules/run.ts';
import type { Battle } from '../rules/battle.ts';

export const SAVE_KEY = 'pokemon-tactics.run';
export const SAVE_VERSION = 2;
export const LEGACY_BACKUP_KEY = 'pokemon-tactics.run.v1-backup';
export type StorageLike = Pick<Storage, 'getItem' | 'setItem' | 'removeItem'>;
export type SaveRead = { kind: 'valid'; run: Run; migrated?: true } | { kind: 'empty' | 'invalid' | 'incompatible' | 'unavailable' };
export type SaveWrite = 'saved' | 'unavailable' | 'conflict';
const object = (value: unknown): value is Record<string, unknown> => typeof value === 'object' && value !== null && !Array.isArray(value);
const integer = (value: unknown, min: number, max: number): value is number => typeof value === 'number' && Number.isInteger(value) && value >= min && value <= max;
const equal = (a: unknown, b: unknown): boolean => JSON.stringify(a) === JSON.stringify(b);
function requireValid(condition: unknown): asserts condition {
  if (!condition) throw new Error('Guardado no válido.');
}
function validateBattle(value: unknown, run: Run, catalog: readonly PokemonSpecies[]): void {
  requireValid(object(value));
  const battle = value as unknown as Battle;
  const node = run.nodes.find(node => node.id === run.currentNodeId)!;
  requireValid(battle.seed === encounterSeed(run, node.id) && battle.variance === run.variance && battle.composition === 'run');
  requireValid(equal(battle.board, runMap(node.mapId).board) && integer(battle.rng, 0, 0xffffffff) && integer(battle.round, 1, 100000));
  const expected = [
    ...run.roster.filter(member => member.hp > 0).map(member => ({ ...member, team: 'ally' as const })),
    ...node.enemies.map((speciesId, index) => ({ id: 1000 + index, speciesId, team: 'enemy' as const })),
  ];
  requireValid(Array.isArray(battle.units) && battle.units.length === expected.length);
  const occupied = new Set<string>();
  for (let index = 0; index < expected.length; index++) {
    const unit = battle.units[index], template = expected[index];
    requireValid(object(unit) && unit.id === template.id && unit.speciesId === template.speciesId && unit.team === template.team);
    requireValid(unit.heldItem === ('heldItem' in template ? template.heldItem : null));
    const species = catalog.find(species => species.id === unit.speciesId)!;
    const original = pokemonFor(unit.speciesId).createCombatant(species, unit.team, { x: 0, y: 0 });
    for (const field of ['name', 'types', 'maxHp', 'attack', 'defense', 'specialAttack', 'specialDefense', 'speed', 'range', 'budget', 'maxTp', 'profile'] as const)
      requireValid(equal(unit[field], original[field]));
    requireValid(integer(unit.hp, 0, unit.maxHp) && integer(unit.tp, 0, unit.maxTp) && integer(unit.remaining, 0, unit.budget));
    requireValid(integer(unit.x, 0, 7) && integer(unit.y, 0, 7) && [0, 2, 4, 6].includes(unit.facing));
    requireValid(typeof unit.guarded === 'boolean');
    requireValid(unit.status === null || (object(unit.status) && ['burn', 'poison', 'paralysis'].includes(unit.status.kind) && integer(unit.status.remaining, 1, 3)));
    if (unit.hp > 0) {
      requireValid(Number.isFinite(tileCost(battle.board, unit, unit.profile)) && !occupied.has(key(unit)));
      occupied.add(key(unit));
    }
  }
  const ids = battle.units.map(unit => unit.id);
  const list = (value: unknown): value is number[] => Array.isArray(value) && value.every(id => ids.includes(id)) && new Set(value).size === value.length;
  requireValid(Array.isArray(battle.initiative) && battle.initiative.length > 0 && battle.initiative.length <= ids.length);
  requireValid(battle.initiative.every(entry => object(entry) && ids.includes(entry.id) && Number.isFinite(entry.score) && entry.score > 0 && typeof entry.tie === 'number' && entry.tie >= 0 && entry.tie < 1));
  requireValid(new Set(battle.initiative.map(entry => entry.id)).size === battle.initiative.length);
  requireValid(list(battle.queue) && list(battle.completed) && battle.completed.every(id => battle.initiative.some(entry => entry.id === id)));
  const living = battle.units.filter(unit => unit.hp > 0);
  const outcome = !living.some(unit => unit.team === 'ally') ? 'defeat' : !living.some(unit => unit.team === 'enemy') ? 'victory' : 'playing';
  requireValid(battle.outcome === outcome);
  const queue = battle.initiative.map(entry => entry.id).filter(id => living.some(unit => unit.id === id) && !battle.completed.includes(id));
  requireValid(outcome === 'playing' ? queue.length > 0 && equal(queue, battle.queue) : battle.queue.length === 0);
  requireValid(typeof battle.moved === 'boolean' && typeof battle.acted === 'boolean');
  requireValid(Array.isArray(battle.fields) && battle.fields.length <= 64 && new Set(battle.fields.map(key)).size === battle.fields.length);
  requireValid(battle.fields.every(field => object(field) && field.kind === 'embers' && integer(field.x, 0, 7) && integer(field.y, 0, 7) && integer(field.expires, battle.round + 1, battle.round + 2) && supportsEmbers(battle.board, field)));
  requireValid(Array.isArray(battle.log) && battle.log.length <= 40 && battle.log.every(line => typeof line === 'string' && line.length < 1000));
}
// Validate before any DOM/Phaser use. This is corruption handling, not an anti-cheat boundary.
export function validateRun(value: unknown, catalog: readonly PokemonSpecies[]): Run {
  requireValid(object(value));
  const run = value as unknown as Run;
  requireValid(typeof run.seed === 'string' && run.seed.trim() === run.seed && run.seed.length > 0 && run.seed.length <= 64 && [0.05, 0.1].includes(run.variance));
  const replayed = replayRun(catalog, run.seed, run.variance, run.events);
  // Replaying legal transactions reconstructs money, stock, bag, equipment, IDs and route.
  requireValid(equal({ ...run, battle: null }, { ...replayed, battle: null }));
  if (run.status === 'combat') {
    validateBattle(run.battle, run, catalog);
  } else {
    requireValid(run.battle === null);
  }
  return structuredClone(run);
}
export class RunStore {
  private lastRaw: string | null = null;
  private pendingBackup: string | null = null;
  private readonly storage: StorageLike | null;
  private readonly catalog: readonly PokemonSpecies[];
  constructor(storage: StorageLike | null, catalog: readonly PokemonSpecies[]) {
    this.storage = storage;
    this.catalog = catalog;
  }
  read(): SaveRead {
    try {
      if (!this.storage) return { kind: 'unavailable' };
      this.lastRaw = this.storage.getItem(SAVE_KEY);
      if (this.lastRaw === null) return { kind: 'empty' };
      if (this.lastRaw.length > 5000000) return { kind: 'invalid' };
      const envelope: unknown = JSON.parse(this.lastRaw);
      if (!object(envelope) || envelope.schema !== 'pokemon-tactics/run') return { kind: 'invalid' };
      if (envelope.version === 1) {
        const run = migrateLegacyRun(validateLegacyRun(envelope.run, this.catalog), this.catalog);
        validateRun(run, this.catalog);
        this.pendingBackup = this.lastRaw;
        return { kind: 'valid', run, migrated: true };
      }
      if (envelope.version !== SAVE_VERSION) return { kind: 'incompatible' };
      return { kind: 'valid', run: validateRun(envelope.run, this.catalog) };
    } catch {
      // Keep unreadable saves intact until the player explicitly discards them.
      return { kind: this.lastRaw === null ? 'unavailable' : 'invalid' };
    }
  }
  write(run: Run): SaveWrite {
    try {
      if (!this.storage) return 'unavailable';
      if (this.storage.getItem(SAVE_KEY) !== this.lastRaw) return 'conflict';
      if (this.pendingBackup !== null && this.storage.getItem(LEGACY_BACKUP_KEY) === null)
        this.storage.setItem(LEGACY_BACKUP_KEY, this.pendingBackup);
      const raw = JSON.stringify({ schema: 'pokemon-tactics/run', version: SAVE_VERSION, run });
      this.storage.setItem(SAVE_KEY, raw);
      this.lastRaw = raw;
      this.pendingBackup = null;
      return 'saved';
    } catch { return 'unavailable'; }
  }
  discard(): SaveWrite {
    try {
      if (!this.storage) return 'unavailable';
      if (this.storage.getItem(SAVE_KEY) !== this.lastRaw) return 'conflict';
      this.storage.removeItem(SAVE_KEY);
      this.lastRaw = null;
      this.pendingBackup = null;
      return 'saved';
    } catch { return 'unavailable'; }
  }
}
