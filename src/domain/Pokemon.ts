import { DamageAction, DrainAction, GuardAction, StatusAction, AreaDamageAction, AreaStatusAction, PushAction } from './actions.ts';
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
    if (species.id !== this.speciesId || ((species.legendary || species.mythical) && team !== 'enemy') || species.types.some(type => !(POKEMON_TYPES as readonly string[]).includes(type)))
      throw new Error('Especie incompatible con su clase táctica.');
    const maxHp = Math.round(35 + species.baseStats.hp / 3);
    return {
      ...position, id: species.id, speciesId: species.id, heldItem: null, name: species.name, team, types: [...species.types] as PokemonType[],
      budget: this.movement, remaining: this.movement, facing: team === 'ally' ? 4 : 0,
      maxHp, hp: maxHp, attack: species.baseStats.attack, defense: species.baseStats.defense,
      specialAttack: species.baseStats['special-attack'], specialDefense: species.baseStats['special-defense'],
      speed: species.baseStats.speed, range: this.action('basic')!.definition.range,
      profile: species.types.includes('flying') ? 'fly' : species.types.includes('water') ? 'swim' : species.types.includes('grass') ? 'grass' : 'ground',
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
      new AreaDamageAction(action('flamethrower', 'Lanzallamas', 'Área en cruz: afecta también a aliados, deja ascuas; 10 % de quemadura.', 'fire', 3, 2), 70, 'special', { kind: 'burn', chance: 10, duration: 3 }, true),
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
      new AreaStatusAction(action('poison-powder', 'Polvo Veneno', 'Polvo en cruz, incluidos aliados. Planta, Veneno y Acero son inmunes.', 'poison', 1, 2, 75), { kind: 'poison', chance: 100, duration: 3 }, true),
      new DamageAction(action('confusion', 'Confusión', 'Daño especial Psíquico; adaptación sin estado de confusión.', 'psychic', 2, 2), 50, 'special'),
    ]);
  }
}
export class Geodude extends Pokemon {
  constructor() {
    super(74, 'Resistencia y ataque físico', 3, [
      new DamageAction(action('basic', 'Placaje', 'Ataque físico básico de tipo Normal.', 'normal', 0, 1), 40, 'physical'),
      new PushAction(action('rock-throw', 'Lanzarrocas', 'Daño de Roca y empuje de una casilla si el destino está libre.', 'rock', 1, 2, 90), 50, 'physical'),
      new GuardAction(action('harden', 'Fortaleza', 'Recibe la mitad del daño hasta su próxima activación.', 'normal', 1, 0, 100, 'self')),
    ]);
  }
}
class EvolvedPokemon extends Pokemon {
  constructor(id: number, family: Pokemon, signature: TacticalAction) {
    super(id, family.role, family.movement, [family.actions[0], family.actions[1], signature]);
  }
}
class Articuno extends Pokemon {
  constructor() { super(144, 'Escarcha y resistencia', 4, [
    new DamageAction(action('basic', 'Nieve Polvo', 'Daño especial de Hielo.', 'ice', 0, 2), 40, 'special'),
    new AreaDamageAction(action('ice-beam', 'Rayo Hielo', 'Hielo en cruz, también aliados.', 'ice', 3, 2), 70, 'special'),
    new GuardAction(action('mist', 'Neblina', 'Protege a un compañero o a sí mismo.', 'ice', 1, 1, 100, 'friendly')),
  ]); }
}
class Mewtwo extends Pokemon {
  constructor() { super(150, 'Presión especial y control de líneas', 4, [
    new DamageAction(action('basic', 'Confusión', 'Daño especial Psíquico.', 'psychic', 0, 2), 50, 'special'),
    new AreaDamageAction(action('psychic', 'Psíquico', 'Cruz psíquica, incluidos aliados.', 'psychic', 3, 2), 80, 'special'),
    new GuardAction(action('barrier', 'Barrera', 'Reduce el daño recibido hasta su siguiente activación.', 'psychic', 1, 0, 100, 'self')),
  ]); }
}
class Magnemite extends Pokemon {
  constructor() { super(81, 'Resistencia de Acero y parálisis', 3, [
    new DamageAction(action('basic', 'Impactrueno', 'Daño especial eléctrico.', 'electric', 0, 2),40,'special'),
    new DamageAction(action('magnet-bomb', 'Bomba Imán', 'Daño físico de Acero.', 'steel', 2, 2),60,'physical'),
    new StatusAction(action('thunder-wave','Onda Trueno','Reduce movimiento y próxima iniciativa.','electric',2,2,90),{kind:'paralysis',chance:100,duration:3}),
  ]); }
}
class Oddish extends Pokemon {
  constructor() { super(43, 'Drenaje y veneno', 3, [
    new DrainAction(action('basic','Absorber','Recupera la mitad del daño efectivo.','grass',0,2),30,'special'),
    new AreaStatusAction(action('poison-powder','Polvo Veneno','Polvo en cruz, también aliados.','poison',1,2,75),{kind:'poison',chance:100,duration:3},true),
    new DrainAction(action('mega-drain','Megaagotar','Drenaje especial de Planta.','grass',2,2),50,'special'),
  ]); }
}
class Mew extends Pokemon {
  constructor() { super(151, 'Movilidad y versatilidad', 6, [
    new DamageAction(action('basic', 'Destructor', 'Ataque físico Normal.', 'normal', 0, 1), 40, 'physical'),
    new DrainAction(action('giga-drain', 'Gigadrenado', 'Recupera la mitad del daño efectivo.', 'grass', 2, 2), 60, 'special'),
    new PushAction(action('ancient-power', 'Poder Pasado', 'Presión de Roca y desplazamiento de una casilla.', 'rock', 2, 2), 60, 'special'),
  ]); }
}
class Zapdos extends Pokemon {
  constructor() { super(145, 'Velocidad y parálisis', 5, [
    new DamageAction(action('basic', 'Impactrueno', 'Daño especial eléctrico.', 'electric', 0, 2), 40, 'special'),
    new AreaDamageAction(action('discharge', 'Chispazo', 'Cruz eléctrica, también aliados.', 'electric', 3, 2), 60, 'special', {kind:'paralysis',chance:10,duration:3}),
    new StatusAction(action('thunder-wave', 'Onda Trueno', 'Reduce movimiento y próxima iniciativa.', 'electric', 2, 2, 90), {kind:'paralysis',chance:100,duration:3}),
  ]); }
}
class Moltres extends Pokemon {
  constructor() { super(146, 'Presión de fuego', 4, [
    new DamageAction(action('basic', 'Ascuas', 'Daño especial de Fuego.', 'fire', 0, 2), 40, 'special'),
    new AreaDamageAction(action('flamethrower', 'Lanzallamas', 'Cruz de fuego y ascuas; también aliados.', 'fire', 3, 2), 70, 'special', {kind:'burn',chance:10,duration:3}, true),
    new PushAction(action('wing-attack', 'Ataque Ala', 'Empuja una casilla.', 'flying', 1, 1), 60, 'physical'),
  ]); }
}
const registry: ReadonlyMap<number, Pokemon> = new Map<number, Pokemon>([
  new Bulbasaur(), new Charmander(), new Squirtle(), new Pikachu(), new Butterfree(), new Geodude(),
  new Articuno(), new Zapdos(), new Moltres(),
  new Mewtwo(), new Mew(),
  new Magnemite(), new Oddish(),
  ...[2, 3].map(id => new EvolvedPokemon(id, new Bulbasaur(), new AreaDamageAction(action('razor-leaf', 'Hoja Afilada', 'Hojas en cruz; alcanza también a aliados.', 'grass', 2, 2, 95), 55, 'physical'))),
  ...[5, 6].map(id => new EvolvedPokemon(id, new Charmander(), new PushAction(action('dragon-tail', 'Cola Dragón', 'Desplaza al objetivo una casilla.', 'dragon', 2, 1, 90), 60, 'physical'))),
  ...[8, 9].map(id => new EvolvedPokemon(id, new Squirtle(), new AreaDamageAction(action('surf', 'Surf', 'Agua en cruz; alcanza también a aliados.', 'water', 3, 2), 65, 'special'))),
  new EvolvedPokemon(26, new Pikachu(), new AreaDamageAction(action('discharge', 'Chispazo', 'Cruz eléctrica, incluidos aliados; 10 % de parálisis.', 'electric', 3, 2), 60, 'special', { kind: 'paralysis', chance: 10, duration: 3 })),
  ...[75, 76].map(id => new EvolvedPokemon(id, new Geodude(), new AreaDamageAction(action('bulldoze', 'Terratemblor', 'Tierra en cruz; alcanza también a aliados.', 'ground', 2, 2), 60, 'physical'))),
].map(pokemon => [pokemon.speciesId, pokemon]));
export function pokemonFor(id: number): Pokemon {
  const pokemon = registry.get(id);
  if (!pokemon)
    throw new Error(`No existe perfil táctico para la especie ${id}.`);
  return pokemon;
}
