import { effectiveness } from '../rules/types.ts';
import { statusImmunity } from './combatant.ts';
import type { Combatant, StatusKind } from './combatant.ts';
import type { PokemonType } from '../data/type-chart.ts';
export type ActionTarget = 'enemy' | 'friendly' | 'self';
export type ActionDefinition = {
  id: string;
  name: string;
  description: string;
  type: PokemonType;
  cost: number;
  range: number;
  accuracy: number;
  target: ActionTarget;
};
export type StatusEffect = {
  kind: StatusKind;
  chance: number;
  duration: number;
};
export type ActionEffect = {
  damage: number;
  heal: number;
  multiplier: number;
  stab: number;
  category: 'physical' | 'special' | 'status';
  guard: boolean;
  status: StatusEffect | null;
  statusReason: string | null;
};
const emptyEffect = (): ActionEffect => ({ damage: 0, heal: 0, multiplier: 1, stab: 1, category: 'status', guard: false, status: null, statusReason: null });
export abstract class TacticalAction {
  readonly definition: Readonly<ActionDefinition>;
  constructor(definition: ActionDefinition) {
    if (!definition.id || !definition.name || !Number.isInteger(definition.cost) || definition.cost < 0 || !Number.isInteger(definition.range) || definition.range < 0 || definition.range > 2 || definition.accuracy <= 0 || definition.accuracy > 100)
      throw new Error('Acción táctica no válida.');
    this.definition = Object.freeze({ ...definition });
  }
  abstract preview(actor: Combatant, target: Combatant): ActionEffect;
}
export class DamageAction extends TacticalAction {
  readonly power: number;
  readonly category: 'physical' | 'special';
  readonly secondary: Readonly<StatusEffect> | null;
  constructor(definition: ActionDefinition, power: number, category: 'physical' | 'special', secondary: StatusEffect | null = null) {
    super(definition);
    this.power = power;
    this.category = category;
    this.secondary = secondary ? Object.freeze({ ...secondary }) : null;
  }
  preview(actor: Combatant, target: Combatant): ActionEffect {
    const multiplier = effectiveness(this.definition.type, target.types);
    const stab = actor.types.includes(this.definition.type) ? 1.5 : 1;
    const attack = this.category === 'physical' ? actor.attack * (actor.status?.kind === 'burn' ? 0.5 : 1) : actor.specialAttack;
    const defense = this.category === 'physical' ? target.defense : target.specialDefense;
    const raw = Math.max(5, 12 + attack * 0.18 - defense * 0.1) * (this.power / 40);
    const damage = multiplier === 0 ? 0 : Math.min(target.hp, Math.max(1, Math.round(raw * multiplier * stab * (target.guarded ? 0.5 : 1))));
    const statusReason = this.secondary ? (multiplier === 0 ? 'Inmune al movimiento.' : statusImmunity(target, this.secondary.kind)) : null;
    return { ...emptyEffect(), category: this.category, damage, multiplier, stab, status: this.secondary && !statusReason && damage < target.hp ? { ...this.secondary } : null, statusReason };
  }
}
export class DrainAction extends DamageAction {
  override preview(actor: Combatant, target: Combatant): ActionEffect {
    const effect = super.preview(actor, target);
    return { ...effect, heal: Math.min(actor.maxHp - actor.hp, Math.floor(effect.damage / 2)) };
  }
}
export class StatusAction extends TacticalAction {
  readonly effect: Readonly<StatusEffect>;
  readonly powder: boolean;
  constructor(definition: ActionDefinition, effect: StatusEffect, powder = false) {
    super(definition);
    this.effect = Object.freeze({ ...effect });
    this.powder = powder;
  }
  preview(_actor: Combatant, target: Combatant): ActionEffect {
    // Non-damaging moves do not use every damage resistance: poison powder can hit Ground.
    const typeImmune = this.definition.type === 'electric' && effectiveness(this.definition.type, target.types) === 0;
    const powderImmune = this.powder && target.types.includes('grass');
    const statusReason = typeImmune ? 'Inmune al movimiento eléctrico.' : powderImmune ? 'Los tipos Planta son inmunes al polvo.' : statusImmunity(target, this.effect.kind);
    return { ...emptyEffect(), multiplier: typeImmune ? 0 : 1, status: statusReason ? null : { ...this.effect }, statusReason };
  }
}
export class GuardAction extends TacticalAction {
  preview(_actor: Combatant, _target: Combatant): ActionEffect {
    return { ...emptyEffect(), guard: true };
  }
}
