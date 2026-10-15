export const INITIAL_SPECIES = [1, 4, 7, 25, 12, 74] as const;
export const CATALOG_SPECIES = [...INITIAL_SPECIES, 2, 3, 5, 6, 8, 9, 26, 75, 76, 81, 43, 23, 109, 63, 96, 37, 27, 144, 145, 146, 150, 151];
export const BOSS_SPECIES: number[] = [144, 145, 146, 150, 151];
export const STAT_KEYS = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'] as const;
export type StatKey = typeof STAT_KEYS[number];
export type AnimationName = 'Idle' | 'Walk';
export interface AnimationData {
  width: number; height: number; columns: number; rows: number; frames: number;
  durations: number[]; anchorX: number; anchorY: number; path: string;
}
export interface PokemonSpecies {
  id: number; name: string; types: string[]; baseStats: Record<StatKey, number>;
  legendary: boolean; mythical: boolean;
  animations: Record<AnimationName, AnimationData>; authors: string[]; sources: string[];
}

export const TYPE_NAMES: Record<string, string> = {
  normal: 'Normal', fire: 'Fuego', water: 'Agua', electric: 'Eléctrico', grass: 'Planta',
  ice: 'Hielo', fighting: 'Lucha', poison: 'Veneno', ground: 'Tierra', flying: 'Volador',
  psychic: 'Psíquico', bug: 'Bicho', rock: 'Roca', ghost: 'Fantasma', dragon: 'Dragón',
  dark: 'Siniestro', steel: 'Acero', fairy: 'Hada',
};
export const STAT_NAMES: Record<StatKey, string> = {
  hp: 'PS', attack: 'Ataque', defense: 'Defensa', 'special-attack': 'At. especial',
  'special-defense': 'Def. especial', speed: 'Velocidad',
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
function positive(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value > 0;
}

// Fail before rendering if a local import is incomplete or malformed.
export function validateCatalog(value: unknown): PokemonSpecies[] {
  if (!Array.isArray(value) || value.length !== CATALOG_SPECIES.length) throw new Error('Catálogo incompleto.');
  const seen = new Set<number>();
  for (const item of value) {
    if (!isRecord(item) || !positive(item.id) || !CATALOG_SPECIES.includes(item.id) || seen.has(item.id)) throw new Error('Especie desconocida o duplicada.');
    seen.add(item.id);
    if (typeof item.name !== 'string' || !item.name.trim() || item.name.length > 50 || typeof item.legendary !== 'boolean' || typeof item.mythical !== 'boolean' || ((item.legendary || item.mythical) !== BOSS_SPECIES.includes(item.id))) throw new Error('Especie no válida para el campamento.');
    if (!Array.isArray(item.types) || item.types.length < 1 || item.types.length > 2 || item.types.some(t => typeof t !== 'string' || !Object.hasOwn(TYPE_NAMES, t))) throw new Error('Tipos no válidos.');
    if (!isRecord(item.baseStats) || STAT_KEYS.some(key => !positive((item.baseStats as Record<string, unknown>)[key]))) throw new Error('Estadísticas incompletas.');
    if (!isRecord(item.animations)) throw new Error('Faltan animaciones.');
    for (const name of ['Idle', 'Walk']) {
      const animation = item.animations[name];
      if (!isRecord(animation) || !['width', 'height', 'columns', 'rows', 'frames'].every(key => positive(animation[key]))) throw new Error('Geometría no válida.');
      if (animation.rows !== 8 || Number(animation.frames) > Number(animation.columns) || !Array.isArray(animation.durations) || animation.durations.length !== animation.frames || !animation.durations.every(positive)) throw new Error('Fotogramas no válidos.');
      if (animation.path !== `assets/pokemon/${item.id}/${name}.png`) throw new Error('Ruta de recurso no local.');
      if (typeof animation.anchorX !== 'number' || typeof animation.anchorY !== 'number' || !Number.isFinite(animation.anchorX) || !Number.isFinite(animation.anchorY) || animation.anchorX < 0 || animation.anchorX > Number(animation.width) || animation.anchorY < 0 || animation.anchorY > Number(animation.height)) throw new Error('Ancla no válida.');
    }
    if (!Array.isArray(item.authors) || !item.authors.length || item.authors.some(a => typeof a !== 'string') || !Array.isArray(item.sources) || item.sources.some(s => typeof s !== 'string' || !s.startsWith('https://pokeapi.co/'))) throw new Error('Procedencia incompleta.');
  }
  return value as PokemonSpecies[];
}
