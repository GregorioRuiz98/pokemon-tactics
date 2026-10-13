import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { Pokemon, pokemonFor, Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree, Geodude } from '../src/domain/Pokemon.ts';
import { TacticalAction, DamageAction, DrainAction, StatusAction, GuardAction } from '../src/domain/actions.ts';
import { effectiveSpeed } from '../src/domain/combatant.ts';
import { createBattle, attackPlan, attackInBattle, finishTurn, activeUnit, chooseTacticalCommand, applyCommand } from '../src/rules/battle.ts';
import type { Battle, RuleResult } from '../src/rules/battle.ts';
const catalog = validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json', import.meta.url), 'utf8')));
const next = (result: RuleResult): Battle => { assert(result.ok); return result.state; };
function pair(actorId: number, targetId: number, seed = 'skills'): Battle {
  const state = createBattle(catalog, seed);
  state.board = Array.from({ length: 8 }, () => Array(8).fill(0));
  state.units = [state.units.find(u => u.id === actorId)!, state.units.find(u => u.id === targetId)!];
  Object.assign(state.units[0], { x: 1, y: 1, team: 'ally', tp: 5 });
  Object.assign(state.units[1], { x: 2, y: 1, team: 'enemy', tp: 5 });
  state.queue = [actorId, targetId];
  return state;
}
test('six species inherit common Pokémon behavior and compose three polymorphic actions each', () => {
  const subclasses = [Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree, Geodude];
  for (const Species of subclasses) {
    const pokemon = new Species();
    assert(pokemon instanceof Pokemon);
    assert.equal(pokemon.actions.length, 3);
    assert.equal(new Set(pokemon.actions.map(a => a.definition.id)).size, 3);
    assert.equal(pokemon.action('basic')!.definition.cost, 0);
    for (const ability of pokemon.actions)
      assert(ability instanceof TacticalAction);
    const species = catalog.find(s => s.id === pokemon.speciesId)!;
    const unit = pokemon.createCombatant(species, 'ally', { x: 0, y: 0 });
    assert.deepEqual(unit.types, species.types);
    assert.equal(unit.specialAttack, species.baseStats['special-attack']);
  }
  assert(pokemonFor(1).action('mega-drain') instanceof DrainAction);
  assert(pokemonFor(1).action('mega-drain') instanceof DamageAction);
  assert(pokemonFor(12).action('poison-powder') instanceof StatusAction);
  assert(pokemonFor(74).action('harden') instanceof GuardAction);
  assert.throws(() => pokemonFor(999));
  assert.throws(() => pokemonFor(1).createCombatant(catalog.find(s => s.id === 4)!, 'ally', { x: 0, y: 0 }));
});
test('state stays JSON-serializable and previews, AI and rejected actions preserve all values', () => {
  const state = pair(4, 7), snapshot = structuredClone(state);
  for (let i = 0; i < 4; i++) {
    attackPlan(state, 7, undefined, 'flamethrower');
    chooseTacticalCommand(state);
  }
  assert.deepEqual(JSON.parse(JSON.stringify(state)), state);
  assert.deepEqual(state, snapshot);
  assert.equal(attackInBattle(state, 7, 'not-learned').ok, false);
  state.units[0].tp = 0;
  const empty = structuredClone(state);
  assert.equal(attackInBattle(state, 7, 'flamethrower').ok, false);
  assert.equal(attackInBattle(state, 4).ok, false);
  assert.deepEqual(state, empty);
  assert.equal(attackPlan(state, 7).ok, true);
});
test('PT regenerates exactly once per activation, caps at five and spending consumes the action', () => {
  let state = createBattle(catalog);
  assert.equal(activeUnit(state)!.tp, 3);
  for (const unit of state.units.filter(u => u.id !== state.queue[0]))
    assert.equal(unit.tp, 2);
  for (let i = 0; i < 48; i++) {
    const pointsBefore = new Map(state.units.map(u => [u.id, u.tp]));
    state = next(finishTurn(state));
    const actor = activeUnit(state)!;
    assert.equal(actor.tp, Math.min(5, pointsBefore.get(actor.id)! + 1));
    assert(state.units.every(u => u.tp <= 5));
  }
  state = pair(1, 74);
  const after = next(attackInBattle(state, 74, 'vine-whip'));
  assert.equal(after.units[0].tp, 4);
  assert(after.acted);
  assert.equal(attackInBattle(after, 74).ok, false);
  assert.equal(state.units[0].tp, 5);
});
test('physical and special attacks read their matching stats, type affinity and burn modifiers', () => {
  const state = pair(1, 74), actor = state.units[0], target = state.units[1];
  const physical = pokemonFor(1).action('vine-whip')!;
  const special = pokemonFor(1).action('mega-drain')!;
  const physicalBase = physical.preview(actor, target).damage;
  const specialBase = special.preview(actor, target).damage;
  const strongSpecial = { ...actor, specialAttack: actor.specialAttack + 30 };
  assert.equal(physical.preview(strongSpecial, target).damage, physicalBase);
  target.hp = target.maxHp = 500;
  assert(special.preview(strongSpecial, target).damage > special.preview(actor, target).damage);
  assert.equal(physical.preview(actor, { ...target, specialDefense: 900 }).damage, physical.preview(actor, target).damage);
  actor.status = { kind: 'burn', remaining: 3 };
  assert(physical.preview(actor, target).damage < physical.preview({ ...actor, status: null }, target).damage);
  assert.equal(special.preview(actor, target).damage, special.preview({ ...actor, status: null }, target).damage);
  assert(specialBase > 0);
  const forecast = attackPlan(state, target.id, undefined, 'mega-drain');
  assert(forecast.ok);
  assert.equal(forecast.multiplier, 4);
  assert.equal(forecast.stab, 1.5);
});
test('damaging type immunity gives zero damage and no secondary status, while a confirmed order still costs PT', () => {
  const state = pair(25, 74), forecast = attackPlan(state, 74, undefined, 'thunder-shock');
  assert(forecast.ok);
  assert.equal(forecast.damage, 0);
  assert.equal(forecast.multiplier, 0);
  assert.equal(forecast.status, null);
  const after = next(attackInBattle(state, 74, 'thunder-shock'));
  assert.equal(after.units[1].hp, state.units[1].hp);
  assert.equal(after.units[0].tp, 4);
});
test('status-only moves reject type immunity and existing states; powder ignores damage resistances', () => {
  const electric = pair(25, 74);
  assert.equal(attackPlan(electric, 74, undefined, 'thunder-wave').ok, false);
  electric.units[1].types = ['electric'];
  assert.equal(attackPlan(electric, 74, undefined, 'thunder-wave').ok, false);
  const powder = pair(12, 74);
  assert.equal(attackPlan(powder, 74, undefined, 'poison-powder').ok, true);
  for (const types of [['poison'], ['steel'], ['grass']] as const) {
    powder.units[1].types = [...types];
    assert.equal(attackPlan(powder, 74, undefined, 'poison-powder').ok, false);
  }
  const burn = pair(4, 7);
  burn.units[1].types = ['fire'];
  assert.equal(attackPlan(burn, 7, undefined, 'will-o-wisp').ok, false);
  burn.units[1].types = ['water'];
  burn.units[1].status = { kind: 'poison', remaining: 2 };
  assert.equal(attackPlan(burn, 7, undefined, 'will-o-wisp').ok, false);
});
test('hit and miss rolls replay by seed; both spend PT/action, only successful hits apply effects', () => {
  let hits = 0, misses = 0;
  for (let i = 0; i < 40; i++) {
    const state = pair(4, 7, `accuracy-${i}`);
    const result = attackInBattle(state, 7, 'will-o-wisp');
    assert(result.ok);
    assert.deepEqual(result, attackInBattle(state, 7, 'will-o-wisp'));
    assert.equal(result.state.units[0].tp, 3);
    assert.equal(result.state.acted, true);
    assert.notEqual(result.state.rng, state.rng);
    if (result.hit) {
      hits++;
      assert.equal(result.state.units[1].status!.kind, 'burn');
    }
    else {
      misses++;
      assert.equal(result.state.units[1].status, null);
    }
  }
  assert(hits > 0 && misses > 0);
});
test('poison and burn tick after the affected activation and expire after three; poison deaths resolve outcome', () => {
  for (const kind of ['poison', 'burn'] as const) {
    let state = pair(1, 74);
    state.units[0].status = { kind, remaining: 3 };
    const initialHp = state.units[0].hp, tick = Math.floor(state.units[0].maxHp / (kind === 'poison' ? 8 : 16));
    for (let turn = 0; turn < 3; turn++) {
      state.queue = [1, 74];
      state = next(finishTurn(state));
      assert.equal(state.units[0].hp, initialHp - tick * (turn + 1));
      assert.equal(state.units[0].status?.remaining ?? 0, 2 - turn);
    }
  }
  const dying = pair(1, 74);
  dying.units[0].hp = 1;
  dying.units[0].status = { kind: 'poison', remaining: 3 };
  const result = next(finishTurn(dying));
  assert.equal(result.outcome, 'defeat');
  assert.deepEqual(result.queue, []);
});
test('paralysis preserves the current queue, reduces movement on activation and speed at the next round', () => {
  let state = pair(25, 7);
  const queue = [...state.queue], initiative = structuredClone(state.initiative);
  state = next(attackInBattle(state, 7, 'thunder-wave'));
  assert.equal(state.units[1].status?.kind, 'paralysis');
  assert.deepEqual(state.queue, queue);
  assert.deepEqual(state.initiative, initiative);
  state = next(finishTurn(state));
  assert.equal(activeUnit(state)!.id, 7);
  assert.equal(activeUnit(state)!.remaining, 2);
  state = next(finishTurn(state));
  const entry = state.initiative.find(i => i.id === 7)!;
  const speed = effectiveSpeed(state.units[1]);
  assert(entry.score >= speed * 0.95 && entry.score <= speed * 1.05);
});
test('guard accepts self/allies, halves both damage classes and expires at the protected next activation', () => {
  let state = pair(7, 4);
  state.units[1].team = 'ally';
  const enemy = createBattle(catalog).units.find(u => u.id === 74)!;
  state.units.push({ ...enemy, x: 3, y: 1 });
  state.queue = [7, 74, 4];
  const target = state.units[1], attack = pokemonFor(74).action('rock-throw')!;
  const before = attack.preview(state.units[2], target).damage;
  const special = pokemonFor(4).action('basic')!, specialBefore = special.preview(target, target).damage;
  state = next(attackInBattle(state, 4, 'cover'));
  assert(state.units[1].guarded);
  assert(attack.preview(state.units[2], state.units[1]).damage < before);
  assert(special.preview(state.units[1], state.units[1]).damage < specialBefore);
  assert.equal(attackPlan({ ...state, acted: false }, 74, undefined, 'cover').ok, false);
  state = next(finishTurn(state));
  assert(state.units[1].guarded);
  state = next(finishTurn(state));
  assert.equal(activeUnit(state)!.id, 4);
  assert.equal(state.units[1].guarded, false);
  const self = pair(74, 4);
  assert.equal(attackPlan(self, 74, undefined, 'harden').ok, true);
  assert.equal(attackPlan(self, 4, undefined, 'harden').ok, false);
});
test('drain heals from actual capped damage, never overkill, and respects max HP', () => {
  const state = pair(1, 74);
  state.units[0].hp -= 20;
  state.units[1].hp = 10;
  const plan = attackPlan(state, 74, undefined, 'mega-drain');
  assert(plan.ok);
  assert.equal(plan.damage, 10);
  assert.equal(plan.heal, 5);
  const result = next(attackInBattle(state, 74, 'mega-drain'));
  assert.equal(result.units[0].hp, state.units[0].hp + 5);
  state.units[0].hp = state.units[0].maxHp - 1;
  const capped = attackPlan(state, 74, undefined, 'mega-drain');
  assert(capped.ok);
  assert.equal(capped.heal, 1);
});
test('both compositions expose all six profiles, simulations terminate and preserve exact seeded replay', () => {
  for (const composition of ['starters', 'mixed'] as const)
    for (const seed of ['kanto-001', 'portfolio', 'statuses']) {
      const simulate = () => {
        let state = createBattle(catalog, seed, 0.05, composition), count = 0;
        assert.equal(state.units.filter(u => u.team === 'ally').length, 3);
        while (state.outcome === 'playing' && count++ < 500)
          state = next(applyCommand(state, chooseTacticalCommand(state)));
        assert.notEqual(state.outcome, 'playing');
        assert(count < 500);
        return state;
      };
      assert.deepEqual(simulate(), simulate());
    }
});
