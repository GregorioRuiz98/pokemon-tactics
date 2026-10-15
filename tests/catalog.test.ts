import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';

const fixture = () => JSON.parse(readFileSync(new URL('../public/data/pokemon.json', import.meta.url), 'utf8'));

test('snapshot contains all six starter candidates and preserves their modern types', () => {
  const catalog = validateCatalog(fixture());
  assert.equal(catalog.length, 20);
  assert.deepEqual(catalog.find(p => p.id === 1)?.types, ['grass', 'poison']);
  assert.deepEqual(catalog.find(p => p.id === 12)?.types, ['bug', 'flying']);
  assert.equal(catalog.find(p => p.id === 25)?.baseStats.speed, 90);
});
test('rejects missing and duplicate species', () => {
  assert.throws(() => validateCatalog(fixture().slice(1)), /incompleto/);
  const data = fixture(); data[1] = data[0];
  assert.throws(() => validateCatalog(data), /duplicada/);
});
test('legendary and mythical flags cannot enter the initial catalog', () => {
  for (const flag of ['legendary', 'mythical']) {
    const data = fixture(); data[0][flag] = true;
    assert.throws(() => validateCatalog(data), /no válida/);
  }
});
test('rejects invalid or incomplete sprite geometry before Phaser renders it', () => {
  for (const bad of [{rows: 1}, {frames: 999}, {anchorY: -1}, {durations: [0]}, {width: 0}]) {
    const data = fixture(); Object.assign(data[0].animations.Idle, bad);
    assert.throws(() => validateCatalog(data));
  }
});
test('blocks external and traversal sprite paths', () => {
  for (const path of ['https://pokeapi.co/image.png', '../assets/Idle.png']) {
    const data = fixture(); data[0].animations.Idle.path = path;
    assert.throws(() => validateCatalog(data), /no local/);
  }
});
test('rejects missing statistics and attribution', () => {
  const data = fixture(); delete data[0].baseStats.speed;
  assert.throws(() => validateCatalog(data), /Estadísticas/);
  const withoutCredits = fixture(); withoutCredits[0].authors = [];
  assert.throws(() => validateCatalog(withoutCredits), /Procedencia/);
});
