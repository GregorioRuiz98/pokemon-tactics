import type { Combatant } from './combatant.ts';
import { ITEM_METADATA } from '../data/item-metadata.ts';
export const ITEM_IDS = ['potion', 'super-potion', 'leftovers', 'assault-vest', 'heavy-duty-boots', 'rare-candy', 'thunder-stone'] as const;
export type ItemId = typeof ITEM_IDS[number];
export type HeldItemId = 'leftovers' | 'assault-vest' | 'heavy-duty-boots';
export abstract class Item {
  readonly id: ItemId;
  readonly name: string;
  readonly price: number;
  readonly description: string;
  protected constructor(id: ItemId, name: string, price: number, description: string) {
    this.id = id; this.name = ITEM_METADATA[id].name; this.price = price; this.description = description;
    if (name !== this.name) throw new Error('El nombre del objeto no coincide con el catálogo importado.');
  }
}
export class HealingItem extends Item {
  readonly recovery: number;
  constructor(id: 'potion' | 'super-potion', name: string, price: number, recovery: number) {
    super(id, name, price, `Recupera hasta ${recovery} PS. Solo fuera de combate; no revive.`);
    this.recovery = recovery;
  }
  restored(hp: number, maximum: number, scale = 1): number { return Math.min(maximum - hp, this.recovery * scale); }
}
export class EvolutionItem extends Item {
  constructor(id: 'rare-candy' | 'thunder-stone', name: string) {
    super(id, name, 100, id === 'rare-candy' ? 'Adaptación: evoluciona una etapa de una familia compatible. No cura.' : 'Evoluciona a Pikachu en Raichu. No cura.');
  }
}
export abstract class HeldItem extends Item {
  declare readonly id: HeldItemId;
  specialDefense(unit: Combatant): number { return unit.specialDefense; }
  endTurnRecovery(_unit: Combatant): number { return 0; }
  allowsStatus(): boolean { return true; }
  blocksEmbers(): boolean { return false; }
}
class Leftovers extends HeldItem {
  constructor() { super('leftovers', 'Restos', 120, 'Recupera 1/16 de los PS máximos al cerrar su turno si sigue vivo.'); }
  override endTurnRecovery(unit: Combatant): number { return unit.hp > 0 ? Math.min(unit.maxHp - unit.hp, Math.max(1, Math.floor(unit.maxHp / 16))) : 0; }
}
class AssaultVest extends HeldItem {
  constructor() { super('assault-vest', 'Chaleco Asalto', 110, 'Defensa especial ×1,5. Impide acciones de estado y apoyo mientras esté equipado.'); }
  override specialDefense(unit: Combatant): number { return unit.specialDefense * 1.5; }
  override allowsStatus(): boolean { return false; }
}
class HeavyDutyBoots extends HeldItem {
  constructor() { super('heavy-duty-boots', 'Botas Gruesas', 80, 'Adaptación táctica: evita daño de ascuas de la casilla; no evita quemadura ni veneno.'); }
  override blocksEmbers(): boolean { return true; }
}
export const ITEMS: readonly Item[] = Object.freeze([
  new HealingItem('potion', 'Poción', 40, 20), new HealingItem('super-potion', 'Superpoción', 90, 50),
  new EvolutionItem('rare-candy', 'Caramelo Raro'), new EvolutionItem('thunder-stone', 'Piedra Trueno'),
  new Leftovers(), new AssaultVest(), new HeavyDutyBoots(),
]);
export function itemFor(id: ItemId): Item {
  const item = ITEMS.find(item => item.id === id);
  if (!item) throw new Error('Objeto desconocido.');
  return item;
}
export function heldItemFor(id: HeldItemId | null | undefined): HeldItem | null {
  if (id === null || id === undefined) return null;
  const item = itemFor(id);
  if (!(item instanceof HeldItem)) throw new Error('Este objeto no se puede equipar.');
  return item;
}
export type Bag = Record<ItemId, number>;
export const emptyBag = (): Bag => ({ potion: 0, 'super-potion': 0, leftovers: 0, 'assault-vest': 0, 'heavy-duty-boots': 0, 'rare-candy': 0, 'thunder-stone': 0 });
