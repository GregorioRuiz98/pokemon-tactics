// Explicit maintenance import; the game never fetches PokéAPI at runtime.
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const sources = JSON.parse(readFileSync(new URL('./sources.lock.json', import.meta.url), 'utf8')).pokeapi;
const vendor = new URL('./vendor/pokeapi/', import.meta.url);
const files = ['items.csv', 'item_names.csv'];
for (const file of files) {
  const response = await fetch(`${sources.raw}/data/v2/csv/${file}`);
  if (!response.ok) throw new Error(`No se pudo importar ${file}: ${response.status}`);
  writeFileSync(new URL(file, vendor), Buffer.from(await response.arrayBuffer()));
}
const csvRows = file => {
  const text = readFileSync(new URL(file, vendor), 'utf8');
  const rows = []; let row = [], field = '', quoted = false;
  for (let i = 0; i < text.length; i++) {
    const character = text[i];
    if (character === '"') { if (quoted && text[i + 1] === '"') { field += '"'; i++; } else quoted = !quoted; }
    else if (character === ',' && !quoted) { row.push(field); field = ''; }
    else if (character === '\n' && !quoted) { row.push(field.replace(/\r$/, '')); rows.push(row); row = []; field = ''; }
    else field += character;
  }
  if (field || row.length) { row.push(field); rows.push(row); }
  return rows.slice(1);
};
const selected = ['potion', 'super-potion', 'leftovers', 'assault-vest', 'heavy-duty-boots'];
const items = csvRows('items.csv'), names = csvRows('item_names.csv');
const metadata = Object.fromEntries(selected.map(identifier => {
  const item = items.find(row => row[1] === identifier);
  const name = item && names.find(row => row[0] === item[0] && row[1] === '7')?.[2];
  if (!item || !name) throw new Error(`Falta el objeto o nombre español de ${identifier}.`);
  return [identifier, { pokeApiId: Number(item[0]), name }];
}));
writeFileSync(new URL('../src/data/item-metadata.ts', import.meta.url), `// Generated from the pinned PokeAPI CSVs by tools/import-items.mjs.\nexport const ITEM_METADATA = ${JSON.stringify(metadata, null, 2)} as const;\n`);
writeFileSync(new URL('items-sources.json', vendor), JSON.stringify({ repository: sources.repository, commit: sources.commit,
  sha256: Object.fromEntries(files.map(file => [file, createHash('sha256').update(readFileSync(new URL(file, vendor))).digest('hex')])) }, null, 2) + '\n');
console.log('Cinco objetos y sus nombres españoles importados desde el commit fijado de PokéAPI.');
