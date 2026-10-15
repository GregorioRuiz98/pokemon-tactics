import assert from 'node:assert/strict';
import { activeUnit, applyCommand, attackPlan, chooseTacticalCommand } from '../../src/rules/battle.ts';
import type { Battle } from '../../src/rules/battle.ts';
import { pokemonFor } from '../../src/domain/Pokemon.ts';
import { fieldDamage } from '../../src/rules/terrain.ts';
import { zoneDamage } from '../../src/rules/hazards.ts';

export type UnitMetric = {
  id: number; speciesId: number; team: string; held: string | null;
  startHp: number; maxHp: number; endHp: number; activations: number;
  dealt: number; collateral: number; received: number; kills: number;
  rolls: number; hits: number; damagingHits: number; incomingHits: number; friendlyReceived: number; fullHpHits: number; oneHits: number; misses: number;
  drain: number; leftovers: number; vestPrevented: number; bootsPrevented: number;
  statusDamage: number; fieldDamage: number; zoneDamage: number;
  statusApplied: number; guards: number; diedBeforeActivation: boolean;
};
export type ActionMetric = {
  speciesId: number; team: string; actionId: string; name: string; cost: number;
  uses: number; rolls: number; hits: number; misses: number; damage: number;
  collateral: number; kills: number; drain: number; statusApplied: number; guards: number;
};
export type FightMetric = {
  outcome: Battle['outcome']; stopReason: 'round-cap'|'command-cap'|null; rounds: number; commands: number;
  allies: number; enemies: number; alliedDeathsBeforeFirstCommand: number;
  units: UnitMetric[]; actions: ActionMetric[];
};

// Observes copies returned by the real rules; no alternate combat formula or RNG.
export function simulateFight(initial: Battle): { battle: Battle; metrics: FightMetric } {
  let battle = structuredClone(initial), commands = 0, firstAllyCommand = false;
  const seen = new Set<string>(), actions = new Map<string, ActionMetric>();
  const units = new Map<number, UnitMetric>(battle.units.map(unit => [unit.id, {
    id: unit.id, speciesId: unit.speciesId, team: unit.team, held: unit.heldItem,
    startHp: unit.hp, maxHp: unit.maxHp, endHp: unit.hp, activations: 0,
    dealt: 0, collateral: 0, received: 0, kills: 0,
    rolls: 0, hits: 0, damagingHits: 0, incomingHits: 0, friendlyReceived: 0, fullHpHits: 0, oneHits: 0, misses: 0,
    drain: 0, leftovers: 0, vestPrevented: 0, bootsPrevented: 0,
    statusDamage: 0, fieldDamage: 0, zoneDamage: 0,
    statusApplied: 0, guards: 0, diedBeforeActivation: false,
  }]));
  let alliedDeathsBeforeFirstCommand = 0;
  while (battle.outcome === 'playing' && commands < 3000 && battle.round <= 100) {
    const actor = activeUnit(battle)!;
    const own = units.get(actor.id)!;
    const activation = `${battle.round}:${actor.id}`;
    if (!seen.has(activation)) { seen.add(activation); own.activations++; }
    if (actor.team === 'ally') firstAllyCommand = true;
    const command = chooseTacticalCommand(battle);
    const plan = command.kind === 'attack' ? attackPlan(battle, command.target, undefined, command.actionId ?? 'basic') : null;
    const result = applyCommand(battle, command);
    assert(result.ok, result.ok ? '' : result.reason);
    const afterActor = result.state.units.find(unit => unit.id === actor.id)!;
    if (command.kind === 'attack') {
      assert(plan?.ok);
      const action = pokemonFor(actor.speciesId).action(command.actionId ?? 'basic', actor)!;
      const key = `${actor.team}:${actor.speciesId}:${action.definition.id}`;
      const metric = actions.get(key) ?? {
        speciesId: actor.speciesId, team: actor.team, actionId: action.definition.id,
        name: action.definition.name, cost: action.definition.cost,
        uses: 0, rolls: 0, hits: 0, misses: 0, damage: 0, collateral: 0,
        kills: 0, drain: 0, statusApplied: 0, guards: 0,
      };
      metric.uses++;
      for (const hit of result.hits ?? []) {
        const before = battle.units.find(unit => unit.id === hit.targetId)!;
        const after = result.state.units.find(unit => unit.id === hit.targetId)!;
        const target = units.get(hit.targetId)!;
        metric.rolls++; own.rolls++;
        if (!hit.hit) { metric.misses++; own.misses++; continue; }
        metric.hits++; own.hits++;
        if (hit.damage > 0) {
          target.received += hit.damage; target.incomingHits++; own.damagingHits++;
          if (actor.team === before.team) target.friendlyReceived += hit.damage;
          if (actor.team === before.team) { own.collateral += hit.damage; metric.collateral += hit.damage; }
          else { own.dealt += hit.damage; metric.damage += hit.damage; }
          if (before.hp === before.maxHp) target.fullHpHits++;
          if (before.hp === before.maxHp && after.hp === 0) target.oneHits++;
          if (after.hp === 0) { own.kills++; metric.kills++; }
          if (before.heldItem === 'assault-vest') {
            const without = action.preview(actor, { ...before, heldItem: null });
            target.vestPrevented += Math.max(0, without.damage - hit.damage);
          }
        }
        if (!before.status && after.status) { own.statusApplied++; metric.statusApplied++; }
        if (!before.guarded && after.guarded) { own.guards++; metric.guards++; }
      }
      const drain = Math.max(0, afterActor.hp - actor.hp);
      own.drain += drain; metric.drain += drain;
      actions.set(key, metric);
    }
    if (command.kind === 'finish') {
      const tick = actor.status?.kind === 'poison' ? Math.max(1, Math.floor(actor.maxHp / 8))
        : actor.status?.kind === 'burn' ? Math.max(1, Math.floor(actor.maxHp / 16)) : 0;
      const status = Math.min(actor.hp, tick);
      let remaining = actor.hp - status;
      const fields = Math.min(remaining, fieldDamage(actor, battle.fields)); remaining -= fields;
      const zones = Math.min(remaining, zoneDamage(actor, battle.hazards, battle.round)); remaining -= zones;
      own.statusDamage += status; own.fieldDamage += fields; own.zoneDamage += zones;
      const recovery = afterActor.hp - remaining;
      assert(recovery >= 0, 'Telemetry HP accounting failed');
      own.leftovers += recovery;
      if (actor.heldItem === 'heavy-duty-boots' && actor.hp > status) {
        own.bootsPrevented += Math.min(actor.hp - status, Math.max(0,
          fieldDamage({ ...actor, heldItem: null }, battle.fields) - fieldDamage(actor, battle.fields)));
      }
    }
    for (const before of battle.units) {
      const after = result.state.units.find(unit => unit.id === before.id)!;
      if (before.hp > 0 && after.hp === 0) {
        const metric = units.get(before.id)!;
        metric.diedBeforeActivation = metric.activations === 0;
        if (before.team === 'ally' && !firstAllyCommand) alliedDeathsBeforeFirstCommand++;
      }
    }
    battle = result.state; commands++;
  }

  battle.units.forEach(unit => {
    const metric=units.get(unit.id)!; metric.endHp=unit.hp;
    assert.equal(metric.startHp-metric.received-metric.statusDamage-metric.fieldDamage-metric.zoneDamage+metric.drain+metric.leftovers,unit.hp,'Telemetry must conserve HP');
  });
  return { battle, metrics: {
    outcome: battle.outcome, stopReason: battle.outcome === 'playing' ? (battle.round > 100 ? 'round-cap' : 'command-cap') : null, rounds: battle.round, commands,
    allies: initial.units.filter(unit => unit.team === 'ally').length,
    enemies: initial.units.filter(unit => unit.team === 'enemy').length,
    alliedDeathsBeforeFirstCommand, units: [...units.values()], actions: [...actions.values()],
  } };
}
