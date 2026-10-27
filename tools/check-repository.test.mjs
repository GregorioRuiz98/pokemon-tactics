import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, unlinkSync, rmdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { forbiddenPath, localLinks, resolveLink, inspectDocument, auditBundle } from './check-repository.mjs';

test('local builds, profiles and secrets are rejected without rejecting pinned fixtures', () => {
  for (const name of ['godot/.godot/imported/foo', 'work/result.json', 'tools/cache/a', '.env', '.env.local', 'godot/export_credentials.cfg', 'windows/game.exe', 'bundle.zip', 'save.json.verification-key', 'trainer-profile.json', 'kanto-save.json', 'trainer-profile.json.damaged-123', 'kanto-save.json.before-new-123', 'private.pem']) assert.ok(forbiddenPath(name), name);
  for (const name of ['.env.example', 'godot/tests/parity.json.gz', 'godot/data/kanto-sources/1.json', 'godot/assets/pokemon/1/credits.txt', 'docs/qa/sprint-34/campaign-journal.json']) assert.equal(forbiddenPath(name), null, name);
});

test('player bundle checks do not resolve missing documents against the source checkout', () => {
  const root = mkdtempSync(join(tmpdir(), 'tactics-bundle-check-'));
  const files = ['LEEME.txt', 'CREDITS.md', 'Documentacion/REGLAS_ACTUALES.md', 'Documentacion/PLAYTEST_WINDOWS.md', 'Documentacion/GUIA_DE_PRUEBA.md'];
  try {
    mkdirSync(join(root, 'Documentacion'));
    for (const file of files) writeFileSync(join(root, file), '# Player guide\n');
    writeFileSync(join(root, 'Documentacion/PLAYTEST_WINDOWS.md'), '[missing report](UI_PRECOMBAT_0.34.1.md)\n');
    const result = auditBundle(root);
    assert.equal(result.ok, false);
    assert.equal(result.errors.length, 1);
    assert.ok(result.errors[0].includes('UI_PRECOMBAT_0.34.1.md'));
    writeFileSync(join(root, 'Documentacion/PLAYTEST_WINDOWS.md'), '[rules](REGLAS_ACTUALES.md)\n');
    assert.equal(auditBundle(root).ok, true);
    writeFileSync(join(root, 'CREDITS.md'), 'npm run known-command\n');
    assert.equal(auditBundle(root, { 'known-command': 'node tool.mjs' }).ok, true);
    assert.equal(auditBundle(root).ok, false);
  } finally {
    for (const file of files) unlinkSync(join(root, file));
    rmdirSync(join(root, 'Documentacion')); rmdirSync(root);
  }
});

test('extracts real links and ignores code examples', () => {
  assert.deepEqual(localLinks('[a](a.md) ![image](x.png) `[fake](missing)`\n```md\n[x](lost)\n```\n[b](<with space.md>)'), ['a.md', 'x.png', 'with space.md']);
});

test('resolves encoded filenames and ignores web/fragment targets', () => {
  const root = resolve('fixture');
  assert.equal(resolveLink(root, 'docs/index.md', '../with%20space.md#intro'), join(root, 'with space.md'));
  for (const target of ['#intro', 'https://example.org/a', 'mailto:test@example.org']) assert.equal(resolveLink(root, 'README.md', target), null);
});

test('refuses escaping paths, machine-specific paths and malformed escapes', () => {
  const root = resolve('fixture');
  for (const target of ['../../lost.md', '/absolute.md', 'C:/private/file.md', '\\private\\a', '%ZZ']) assert.throws(() => resolveLink(root, 'README.md', target));
  assert.throws(() => resolveLink(root, 'README.md', encodeURIComponent(join(root, 'local.md'))));
});

test('reports broken links and invalid commands, while valid directories and scripts pass', () => {
  const root = mkdtempSync(join(tmpdir(), 'tactics-doc-check-'));
  try {
    mkdirSync(join(root, 'docs'));
    writeFileSync(join(root, 'README.md'), '[dir](docs/) [missing](gone.md)\nnpm run check:repo\nnpm run invented\n');
    const result = inspectDocument(root, 'README.md', { 'check:repo': 'node tools/check-repository.mjs' });
    assert.equal(result.links, 2); assert.equal(result.commands, 2);
    assert.equal(result.failures.length, 2);
    assert.ok(result.failures.some(value => value.includes('gone.md')));
    assert.ok(result.failures.some(value => value.includes('invented')));
  } finally {
    unlinkSync(join(root, 'README.md'));
    rmdirSync(join(root, 'docs'));
    rmdirSync(root);
  }
});
