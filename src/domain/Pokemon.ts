import { DamageAction, DrainAction, GuardAction, StatusAction } from './actions.ts';
import type { TacticalAction, ActionDefinition } from './actions.ts';
import type { PokemonSpecies } from '../data/catalog.ts';
import type { Combatant, Team } from './combatant.ts';
import type { Point } from '../rules/movement.ts';
import { POKEMON_TYPES } from '../data/type-chart.ts';
import type { PokemonType } from '../data/type-chart.ts';
const action = (id: string, name: string, description: string, type: PokemonType, cost: number, range: number, accuracy = 100, target: ActionDefinition['target'] = 'enemy'): ActionDefinition => ({ id, name, description, type, cost, range, accuracy, target });
export abstract class Pokemon {
  readonly speciesId: number;
  readonly role: string;
  readonly movement: number;
  readonly actions: readonly TacticalAction[];
  protected constructor(speciesId: number, role: string, movement: number, actions: TacticalAction[]) {
    this.speciesId = speciesId;
    this.role = role;
    this.movement = movement;
    this.actions = Object.freeze([...actions]);
  }
  action(id: string): TacticalAction | undefined { return this.actions.find(action => action.definition.id === id); }
  createCombatant(species: PokemonSpecies, team: Team, position: Point): Combatant {
    if (species.id !== this.speciesId || species.legendary || species.mythical || species.types.some(type => !(POKEMON_TYPES as readonly string[]).includes(type)))
      throw new Error('Especie incompatible con su clase táctica.');
    const maxHp = Math.round(35 + species.baseStats.hp / 3);
    return {
      ...position, id: species.id, name: species.name, team, types: [...species.types] as PokemonType[],
      budget: this.movement, remaining: this.movement, facing: team === 'ally' ? 4 : 0,
      maxHp, hp: maxHp, attack: species.baseStats.attack, defense: species.baseStats.defense,
      specialAttack: species.baseStats['special-attack'], specialDefense: species.baseStats['special-defense'],
      speed: species.baseStats.speed, range: this.action('basic')!.definition.range,
      tp: 2, maxTp: 5, status: null, guarded: false,
    };
  }
}
export class Bulbasaur extends Pokemon {
  constructor() {
    super(1, 'Desgaste y recuperación', 4, [
      new DamageAction(action('basic', 'Placaje', 'Ataque físico básico de tipo Normal.', 'normal', 0, 1), 40, 'physical'),
      new DamageAction(action('vine-whip', 'Látigo Cepa', 'Golpea a dos casillas con sus lianas.', 'grass', 1, 2), 45, 'physical'),
      new DrainAction(action('mega-drain', 'Megaagotar', 'Absorbe la mitad del daño causado como PS.', 'grass', 2, 2), 40, 'special'),
    ]);
  }
}
export class Charmander extends Pokemon {
  constructor() {
    super(4, 'Ofensiva especial y quemadura', 4, [
      new DamageAction(action('basic', 'Ascuas', 'Ataque especial básico de tipo Fuego.', 'fire', 0, 2), 40, 'special'),
      new DamageAction(action('flamethrower', 'Lanzallamas', 'Gran daño; 10 % de quemadura si sobrevive.', 'fire', 3, 2), 90, 'special', { kind: 'burn', chance: 10, duration: 3 }),
      new StatusAction(action('will-o-wisp', 'Fuego Fatuo', 'Quema: daño al cerrar turno y mitad de ataque físico.', 'fire', 2, 2, 85), { kind: 'burn', chance: 100, duration: 3 }),
    ]);
  }
}
export class Squirtle extends Pokemon {
  constructor() {
    super(7, 'Defensa y cobertura', 4, [
      new DamageAction(action('basic', 'Pistola Agua', 'Ataque especial básico de tipo Agua.', 'water', 0, 2), 40, 'special'),
      new DamageAction(action('water-pulse', 'Hidropulso', 'Daño especial de Agua; adaptación sin confusión.', 'water', 2, 2), 60, 'special'),
      new GuardAction(action('cover', 'Cobertura', 'Protege a un aliado cercano o a sí mismo: recibe la mitad del daño hasta su próxima activación.', 'normal', 1, 1, 100, 'friendly')),
    ]);
  }
}
export class Pikachu extends Pokemon {
  constructor() {
    super(25, 'Movilidad y parálisis', 5, [
      new DamageAction(action('basic', 'Ataque Rápido', 'Ataque físico básico de tipo Normal; no altera la cola.', 'normal', 0, 1), 40, 'physical'),
      new DamageAction(action('thunder-shock', 'Impactrueno', 'Daño eléctrico; 10 % de parálisis si sobrevive.', 'electric', 1, 2), 40, 'special', { kind: 'paralysis', chance: 10, duration: 3 }),
      new StatusAction(action('thunder-wave', 'Onda Trueno', 'Mitad de velocidad en la próxima ronda y mitad de movimiento.', 'electric', 2, 2, 90), { kind: 'paralysis', chance: 100, duration: 3 }),
    ]);
  }
}
export class Butterfree extends Pokemon {
  constructor() {
    super(12, 'Control y cobertura de tipos', 4, [
      new DamageAction(action('basic', 'Tornado', 'Ataque especial básico de tipo Volador.', 'flying', 0, 2), 40, 'special'),
      new StatusAction(action('poison-powder', 'Polvo Veneno', 'Envenena durante tres activaciones; Planta, Veneno y Acero son inmunes.', 'poison', 1, 2, 75), { kind: 'poison', chance: 100, duration: 3 }, true),
      new DamageAction(action('confusion', 'Confusión', 'Daño especial Psíquico; adaptación sin estado de confusión.', 'psychic', 2, 2), 50, 'special'),
    ]);
  }
}
export class Geodude extends Pokemon {
  constructor() {
    super(74, 'Resistencia y ataque físico', 3, [
      new DamageAction(action('basic', 'Placaje', 'Ataque físico básico de tipo Normal.', 'normal', 0, 1), 40, 'physical'),
      new DamageAction(action('rock-throw', 'Lanzarrocas', 'Daño físico de Roca a dos casillas.', 'rock', 1, 2, 90), 50, 'physical'),
      new GuardAction(action('harden', 'Fortaleza', 'Recibe la mitad del daño hasta su próxima activación.', 'normal', 1, 0, 100, 'self')),
    ]);
  }
}
const registry: ReadonlyMap<number, Pokemon> = new Map<number, Pokemon>([
  new Bulbasaur(), new Charmander(), new Squirtle(), new Pikachu(), new Butterfree(), new Geodude(),
].map(pokemon => [pokemon.speciesId, pokemon]));
export function pokemonFor(id: number): Pokemon {
  const pokemon = registry.get(id);
  if (!pokemon)
    throw new Error(`No existe perfil táctico para la especie ${id}.`);
  return pokemon;
}
