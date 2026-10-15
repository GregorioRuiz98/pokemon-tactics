// Explicit local import: never download assets or rewrite the web catalogue.
import { readFileSync, writeFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pokemonFor } from '../../src/domain/Pokemon.ts';
import { atLevel } from '../../src/domain/progression.ts';
import { POKEMON_TYPES, TYPE_CHART } from '../../src/data/type-chart.ts';
import { createEncounter, createBattle, chooseTacticalCommand, applyCommand, hashSeed, random, attackPlan, activeUnit } from '../../src/rules/battle.ts';
import { routesFrom } from '../../src/rules/movement.ts';
import { TACTICAL_BOARD } from '../../src/rules/terrain.ts';
import { DamageAction, DrainAction, StatusAction, AreaDamageAction, AreaStatusAction, PushAction, GuardAction } from '../../src/domain/actions.ts';
import type { PokemonSpecies } from '../../src/data/catalog.ts';
import type { Battle } from '../../src/rules/battle.ts';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const target = resolve(root, 'godot');
const ids = [1, 4, 7, 25, 12, 74];
const catalog: PokemonSpecies[] = JSON.parse(readFileSync(resolve(root, 'public/data/pokemon.json'), 'utf8'));
const records: { source: string; target: string; sha256: string; sourceSha256: string; modification?: string }[] = [];
function copy(source: string, destination: string) {
  mkdirSync(dirname(resolve(target, destination)), { recursive: true });
  copyFileSync(resolve(root, source), resolve(target, destination));
  const sha256 = createHash('sha256').update(readFileSync(resolve(root, source))).digest('hex');
  records.push({ source, target: destination, sha256, sourceSha256: sha256 });
}
function json(file: string, value: unknown) {
  mkdirSync(dirname(resolve(target, file)), { recursive: true });
  writeFileSync(resolve(target, file), file.endsWith('.gz') ? gzipSync(Buffer.from(JSON.stringify(value) + '\n'), { level: 9 }) : JSON.stringify(value, null, 2) + '\n');
}
function actions(id: number, ruleset: number) {
  const unit = { ruleset } as Parameters<ReturnType<typeof pokemonFor>['actionsFor']>[0];
  return pokemonFor(id).actionsFor(unit).map(action => ({
    ...action.definition,
    kind: action instanceof DrainAction ? 'drain' : action instanceof AreaDamageAction ? 'area-damage' : action instanceof PushAction ? 'push' : action instanceof AreaStatusAction ? 'area-status' : action instanceof StatusAction ? 'status' : action instanceof GuardAction ? 'guard' : 'damage',
    ...(action instanceof DamageAction ? { power: action.power, category: action.category, secondary: action.secondary } : {}),
    ...(action instanceof StatusAction ? { effect: action.effect, powder: action.powder } : {}),
    embers: action.leavesEmbers(),
  }));
}
const species = ids.map(id => {
  const source = catalog.find(p => p.id === id)!;
  for (const file of ['Idle.png', 'Walk.png', 'thumbnail.png', 'credits.txt', 'AnimData.xml'])
    copy(`public/assets/pokemon/${id}/${file}`, `assets/pokemon/${id}/${file}`);
  return { ...source, role: pokemonFor(id).role, movement: pokemonFor(id).movement, actions: { classic: actions(id, 6), current: actions(id, 14) } };
});
for (const file of ['select.wav', 'hit.wav', 'victory.wav']) copy(`public/assets/audio/${file}`, `assets/audio/${file}`);
// RIFF chunks require an even byte boundary. jsfxr's odd-length 8-bit victory
// data omits its final padding byte; add container padding without changing PCM.
for (const entry of records.filter(record => record.target.endsWith('.wav'))) {
  const bytes = readFileSync(resolve(target, entry.target));
  if (bytes.length % 2 === 1) {
    const padded = Buffer.concat([bytes, Buffer.from([0])]);
    padded.writeUInt32LE(padded.length - 8, 4);
    writeFileSync(resolve(target, entry.target), padded);
    entry.sha256 = createHash('sha256').update(padded).digest('hex');
    entry.modification = 'One RIFF padding byte and updated RIFF length; PCM data and chunk length unchanged.';
  }
}
copy('public/assets/fonts/PixelifySans.ttf', 'assets/fonts/PixelifySans.ttf');
copy('CREDITS.md', 'licenses/web-CREDITS.md');
for (const file of ['SpriteCollab-CC-BY-NC-4.0.md', 'PokeAPI-BSD-3-Clause.txt', 'PixelifySans-OFL.txt', 'jsfxr-UNLICENSE.txt', 'EasyStar-MIT.txt', 'heap-PSF.md']) copy(`public/licenses/${file}`, `licenses/${file}`);
json('data/laboratory.json', { version: '0.13.0', sourceRuleset: 14, board: TACTICAL_BOARD, species, types: POKEMON_TYPES, typeChart: TYPE_CHART });
const ruleSources = ['src/domain/Pokemon.ts', 'src/domain/actions.ts', 'src/domain/combatant.ts', 'src/domain/items.ts', 'src/domain/progression.ts', 'src/rules/battle.ts', 'src/rules/movement.ts', 'src/rules/position.ts', 'src/rules/terrain.ts', 'src/rules/hazards.ts', 'src/data/type-chart.ts', 'public/data/pokemon.json', 'tools/godot/import-lab.ts'].map(source => ({ source, sha256: createHash('sha256').update(readFileSync(resolve(root, source))).digest('hex') }));
json('data/provenance.json', { origin: 'Existing local assets; documented RIFF padding adaptation for Godot', files: records, ruleSources });
export function initial(seed: string, variance = 0.05, composition = 'starters', mode = 'current'): Battle {
  if (mode === 'classic') return createBattle(catalog, seed, variance, composition as 'starters' | 'mixed');
  const allies = composition === 'starters' ? [1, 4, 7] : [25, 12, 74];
  const enemies = composition === 'starters' ? [25, 12, 74] : [1, 4, 7];
  const state = createEncounter(catalog, seed, variance, TACTICAL_BOARD, allies.map((id, index) => ({ id: index + 1, speciesId: id, hp: atLevel(pokemonFor(id).createCombatant(catalog.find(p => p.id === id)!, 'ally', { x: 1, y: 6 }), 1, 14).hp })), enemies, { ruleset: 14 });
  state.composition = composition as 'starters' | 'mixed';
  return state;
}
export function comparable(state: Battle) { const { log, ...rest } = state; return rest; }
const games: unknown[] = [];
for (const mode of ['classic', 'current']) for (const composition of ['starters', 'mixed']) for (const variance of [0.05, 0.1]) for (const seed of ['godot-13', 'Kanto-ñ-🌱']) {
  let state = initial(seed, variance, composition, mode);
  const first = comparable(state), steps: unknown[] = [];
  for (let turn = 0; state.outcome === 'playing' && turn < 360; turn++) {
    const command = chooseTacticalCommand(state), result = applyCommand(state, command);
    if (!result.ok) throw new Error(result.reason);
    state = result.state;
    steps.push({ command, expected: comparable(state) });
  }
  if (state.outcome === 'playing') throw new Error('Reference did not finish.');
  games.push({ seed, mode, variance, composition, initial: first, steps });
}
const scenarios: unknown[] = [];
function scenario(name: string, state: Battle, command?: Parameters<typeof applyCommand>[1]) {
  const plans = state.units.filter(u => u.hp > 0).flatMap(target => pokemonFor(activeUnit(state)!.speciesId).actionsFor(activeUnit(state)).map(action => ({ target: target.id, action: action.definition.id, expected: attackPlan(state, target.id, undefined, action.definition.id) })));
  const movement = [...routesFrom(state.board, state.units.filter(u => u.hp > 0), activeUnit(state)!.id)].map(([key, route]) => ({ key, route }));
  const result = command ? applyCommand(state, command) : null;
  scenarios.push({ name, state, plans, movement, ...(command ? { command, result: result?.ok ? { ...result, state: comparable(result.state) } : result } : {}) });
}
for (const actorId of [1, 4, 7, 25, 12, 74]) {
  const state = initial('preview', 0.05, 'starters', 'classic');
  state.queue = [actorId, ...state.queue.filter(id => id !== actorId)];
  const actor = activeUnit(state)!;
  actor.x = 3; actor.y = 5; actor.tp = 5; actor.hp = Math.max(1, actor.hp - 12);
  const others = state.units.filter(u => u.id !== actorId);
  const positions = [[3, 4], [4, 5], [4, 4], [2, 5], [5, 5]];
  others.forEach((u, i) => { [u.x, u.y] = positions[i]; u.facing = [0, 2, 4, 6][i % 4] as 0 | 2 | 4 | 6; });
  scenario(`actions-${actorId}`, state);
  for (const action of pokemonFor(actorId).actionsFor(actor)) {
    const target = state.units.find(unit => attackPlan(state, unit.id, undefined, action.definition.id).ok);
    if (!target) throw new Error('No legal resolution fixture for ' + action.definition.id);
    scenario(`resolve-${actorId}-${action.definition.id}`, state, { kind: 'attack', target: target.id, actionId: action.definition.id });
  }
}
const afflictions = initial('status');
activeUnit(afflictions)!.status = { kind: 'poison', remaining: 2 };
afflictions.fields = [{ x: activeUnit(afflictions)!.x, y: activeUnit(afflictions)!.y, kind: 'embers', expires: 3 }];
scenario('status-and-field', afflictions, { kind: 'finish', facing: 6 });
const rng = ['abc', 'ñ', '🌱', 'kanto-001'].map(seed => { const value = { rng: hashSeed(seed) }; return { seed, hash: value.rng, values: Array.from({ length: 20 }, () => random(value)), final: value.rng }; });
json('tests/parity.json.gz', { games, scenarios, rng });
console.log(`Imported ${species.length} species, ${records.length} assets (${records.filter(record => record.modification).length} documented container adaptation); ${games.length} complete reference battles and ${scenarios.length} rule scenarios.`);
