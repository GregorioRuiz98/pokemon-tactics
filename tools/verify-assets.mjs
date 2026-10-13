import { readFileSync, existsSync } from 'node:fs';
import { resolve, relative, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import { validateCatalog } from '../src/data/catalog.ts';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const readJson = path => JSON.parse(readFileSync(resolve(root, path), 'utf8'));
const catalog = validateCatalog(readJson('public/data/pokemon.json'));
const manifest = readJson('public/data/provenance.json');
const paths = new Set();
for (const file of manifest.files) {
  const absolute = resolve(root, file.path);
  assert(!relative(root, absolute).startsWith('..'), 'Manifest path escapes project');
  assert(!paths.has(file.path), `Duplicate provenance: ${file.path}`);
  paths.add(file.path);
  const hash = createHash('sha256').update(readFileSync(absolute)).digest('hex');
  assert.equal(hash, file.sha256, `Resource changed: ${file.path}`);
  assert(file.source && file.license, `Incomplete provenance: ${file.path}`);
}
for (const pokemon of catalog) {
  for (const animation of Object.values(pokemon.animations)) {
    const path = `public/${animation.path}`;
    assert(paths.has(path), `Uncredited sheet: ${path}`);
    const png = readFileSync(resolve(root, path));
    assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
    assert.equal(png.readUInt32BE(16), animation.width * animation.columns);
    assert.equal(png.readUInt32BE(20), animation.height * animation.rows);
  }
  assert(existsSync(resolve(root, `public/assets/pokemon/${pokemon.id}/credits.txt`)));
}
console.log(`${catalog.length} species, 12 sheets and ${paths.size} provenance hashes verified.`);
