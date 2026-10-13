import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { POKEMON_TYPES, TYPE_CHART } from '../src/data/type-chart.ts';
import { effectiveness } from '../src/rules/types.ts';
test('all 324 modern type relations match the pinned upstream CSV; provenance hashes are intact', () => {
  const root = new URL('../tools/vendor/pokeapi/', import.meta.url);
  const source = JSON.parse(readFileSync(new URL('sources.json', root), 'utf8'));
  for (const file of source.files)
    assert.equal(createHash('sha256').update(readFileSync(new URL(file.file, root))).digest('hex'), file.sha256);
  const rows = readFileSync(new URL('type_efficacy.csv', root), 'utf8').trim().split(/\r?\n/).slice(1).map(line => line.split(',').map(Number));
  assert.equal(POKEMON_TYPES.length, 18);
  assert.equal(TYPE_CHART.length, 18);
  for (let a = 1; a <= 18; a++)
    for (let d = 1; d <= 18; d++) {
      assert.equal(effectiveness(POKEMON_TYPES[a - 1], [POKEMON_TYPES[d - 1]]), rows.find(row => row[0] === a && row[1] === d)![2] / 100);
    }
});
test('double weaknesses, double resistances and immunities multiply correctly', () => {
  assert.equal(effectiveness('water', ['rock', 'ground']), 4);
  assert.equal(effectiveness('rock', ['bug', 'flying']), 4);
  assert.equal(effectiveness('grass', ['grass', 'poison']), 0.25);
  assert.equal(effectiveness('electric', ['water', 'ground']), 0);
  assert.equal(effectiveness('normal', ['ghost']), 0);
  assert.equal(effectiveness('dragon', ['fairy']), 0);
  assert.equal(effectiveness('poison', ['steel']), 0);
  assert.equal(effectiveness('ghost', ['steel']), 1);
  assert.equal(effectiveness('dark', ['steel']), 1);
  assert.throws(() => effectiveness('water', []));
  assert.throws(() => effectiveness('water', ['rock', 'rock']));
});
