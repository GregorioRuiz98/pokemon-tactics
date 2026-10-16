import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, mkdirSync, writeFileSync, cpSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { gunzipSync } from 'node:zlib';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const project = resolve(root, 'godot');
const work = resolve(root, '../../work/qa-sprint-14-shop');
const output = resolve(root, '../releases/pokemon-tactics-0.14.2/windows');
const operation = process.argv[2] ?? 'test';
const binary = process.env.GODOT_BIN ?? resolve(root, '../../work/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe');
mkdirSync(work, { recursive: true });
function run(executable, args, label, cwd = root) {
  const logIndex = args.indexOf('--log-file');
  if (logIndex >= 0) writeFileSync(args[logIndex + 1], '');
  const result = spawnSync(executable, args, { cwd, encoding: 'utf8', windowsHide: true, timeout: 240_000, maxBuffer: 12 * 1024 * 1024 });
  const log = (result.stdout ?? '') + (result.stderr ?? '') + (logIndex >= 0 && existsSync(args[logIndex + 1]) ? '\n' + readFileSync(args[logIndex + 1], 'utf8') : '');
  writeFileSync(resolve(work, `${label}.log`), log);
  const clean = log.replace(/\x1b\[[0-9;]*m/g, '');
  const summary = [...new Set(clean.split(/\r?\n/).filter(line => /Godot Engine|^\{|^QA |ERROR:|SCRIPT ERROR:|Parse Error|Imported|Shader|OpenGL/.test(line)))];
  console.log(summary.join('\n'));
  if (result.error || result.status !== 0 || /(?:SCRIPT ERROR:|Parse Error|^ERROR:)/m.test(clean)) throw new Error(`${label} failed; see ${resolve(work, `${label}.log`)}${result.error ? ': ' + result.error.message : ''}`);
  return clean;
}
function verifyUi(directory) {
  const report = JSON.parse(readFileSync(resolve(directory, 'ui-result.json'), 'utf8'));
  if (report.failures.length || report.completed.length !== 4 || !report.playerOrders || !report.friendlyFireChecked || !report.movementRevisions || !report.lockedRevisionChecks) throw new Error('Native UI regression failed.');
  for (const file of report.screenshots) if (!existsSync(resolve(directory, file))) throw new Error('Missing screenshot: ' + file);
  console.log(`UI verified: ${report.assertions} assertions, ${report.playerOrders} player orders, four completed battles.`);
}
function verifyCampaign(directory) {
  const report=JSON.parse(readFileSync(resolve(directory,'campaign-ui-result.json'),'utf8'));
  if(report.failures.length || report.completed.length !== 3 || !report.completed.some(entry=>entry.phase==='complete')) throw new Error('Campaign UI failed.');
  for(const file of report.screenshots) if(!existsSync(resolve(directory,file))) throw new Error('Missing campaign screenshot.');
}
function verify() {
  const manifest = JSON.parse(readFileSync(resolve(project, 'data/provenance.json'), 'utf8'));
  for (const entry of manifest.files) {
    for (const [path, hash] of [[resolve(root, entry.source), entry.sourceSha256], [resolve(project, entry.target), entry.sha256]]) {
      if (createHash('sha256').update(readFileSync(path)).digest('hex') !== hash) throw new Error(`Asset hash mismatch: ${path}`);
    }
    if (entry.target.endsWith('.wav')) {
      const source = readFileSync(resolve(root, entry.source)), native = readFileSync(resolve(project, entry.target));
      if (native.length % 2 || native.readUInt32LE(4) !== native.length - 8) throw new Error('Invalid native RIFF container: ' + entry.target);
      const samples = source.readUInt32LE(40);
      if (native.readUInt32LE(40) !== samples || !source.subarray(44, 44 + samples).equals(native.subarray(44, 44 + samples))) throw new Error('Audio samples changed: ' + entry.target);
    }
  }
  for (const entry of manifest.ruleSources) {
    if (createHash('sha256').update(readFileSync(resolve(root, entry.source))).digest('hex') !== entry.sha256) throw new Error(`Reference is stale: ${entry.source}. Run npm run godot:import and review the differences.`);
  }
  const portraits = JSON.parse(readFileSync(resolve(project, 'data/portraits.json'), 'utf8'));
  for (const record of portraits.records) for (const file of record.files) {
    if (createHash('sha256').update(readFileSync(resolve(project, file.target))).digest('hex') !== file.sha256) throw new Error('Portrait hash mismatch: ' + file.target);
  }
  console.log('Verified six portraits and individual credits from ' + portraits.commit);
  const kanto = JSON.parse(readFileSync(resolve(project, 'data/kanto-provenance.json'),'utf8'));
  for (const entry of kanto.files) if (createHash('sha256').update(readFileSync(resolve(project,entry.target))).digest('hex') !== entry.sha256) throw new Error('Kanto hash mismatch: '+entry.target);
  console.log('Verified '+kanto.files.length+' Kanto source/asset files.');
  for (const name of ['progression-provenance','feedback-provenance','shop-provenance']) {
    const extra=JSON.parse(readFileSync(resolve(project,'data/'+name+'.json'),'utf8'));
    for (const entry of extra.files) if(createHash('sha256').update(readFileSync(resolve(project,entry.target))).digest('hex') !== entry.sha256) throw new Error('Progression resource hash mismatch: '+entry.target);
    console.log('Verified '+extra.files.length+' files in '+name+'.');
  }
  const fixtures = JSON.parse(gunzipSync(readFileSync(resolve(project, 'tests/parity.json.gz'))).toString('utf8'));
  console.log(`Verified ${manifest.files.length} assets and ${manifest.ruleSources.length} reference source hashes; ${fixtures.games.length} complete battles.`);
}
if (operation === 'verify') { verify(); process.exit(0); }
if (!['qa-export','qa-campaign-export'].includes(operation)) {
  if (!existsSync(binary)) throw new Error('Godot not found. Set GODOT_BIN to the standard Godot 4.7.2 executable.');
  const version = spawnSync(binary, ['--version'], { encoding: 'utf8', windowsHide: true });
  if (version.status !== 0 || !version.stdout.startsWith('4.7.2.stable.')) throw new Error('Expected Godot 4.7.2 stable.');
}
const common = ['--path', project, '--log-file', resolve(work, `engine-${operation}.log`)];
if (operation === 'test-shop') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/shop.gd','--','--save-dir='+work],'shop-core');
} else if (operation === 'test-progression') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/progression.gd','--','--save-dir='+work],'progression-core');
} else if (operation === 'test-campaign-edges') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/campaign_edges.gd','--','--save-dir='+work],'campaign-edges');
} else if (operation === 'test-campaign') {
  verify();
  run(binary, ['--headless', ...common, '--script', 'res://tests/campaign.gd', '--', '--save-dir=' + work], 'campaign-core');
} else if (operation === 'test') {
  verify();
  run(binary, ['--headless', ...common, '--script', 'res://tests/parity.gd', '--', `--save-dir=${work}`], 'parity');
} else if (operation === 'qa-campaign') {
  verify();
  run(binary, [...common, '--position', '-10000,-10000', '--audio-driver', 'Dummy', '--', '--campaign-qa-dir=' + resolve(work, 'campaign-source')], 'campaign-source');
  verifyCampaign(resolve(work,'campaign-source'));
} else if (operation === 'qa-campaign-export') {
  run(resolve(output, 'PokemonTactics.exe'), ['--position','-10000,-10000','--audio-driver','Dummy','--log-file',resolve(work,'engine-campaign-release.log'),'--','--campaign-qa-dir='+resolve(work,'campaign-release')], 'campaign-release', output);
  verifyCampaign(resolve(work,'campaign-release'));
} else if (operation === 'qa') {
  verify();
  run(binary, [...common, '--position', '-10000,-10000', '--audio-driver', 'Dummy', '--', `--qa-dir=${resolve(work, 'source')}`], 'ui-source');
  verifyUi(resolve(work, 'source'));
} else if (operation === 'editor-import') {
  verify();
  run(binary, ['--headless', ...common, '--import'], 'editor-import');
} else if (operation === 'export') {
  verify();
  mkdirSync(output, { recursive: true });
  run(binary, ['--headless', ...common, '--export-release', 'Windows Desktop', resolve(output, 'PokemonTactics.exe')], 'export-windows');
  cpSync(resolve(project, 'licenses'), resolve(output, 'licenses'), { recursive: true });
  cpSync(resolve(project, 'CREDITS.md'), resolve(output, 'CREDITS.md'));
  writeFileSync(resolve(output, 'LEEME.txt'), 'Pokémon Tactics 0.14.2 — Paleta hasta Brock · offline\n\nAbre PokemonTactics.exe. No necesitas Godot, Node ni un servidor.\nElige un inicial de Oak y recorre Ruta 1, Ruta 2, Bosque Verde y Brock.\nEXP por victoria, niveles y estadísticas. Cuatro movimientos preparados + básico neutro.\nEvolución: nivel requerido + un Caramelo Raro. Preparar movimientos es gratis.\nBrock entrega Onix. Tres ofertas MT/equipables por tienda; renovar cuesta 25, 50, 75… ₽.\nUn equipable por Pokémon; MT de un uso, con compatibilidad indicada.\nNueva campaña para estas reglas; archivos anteriores conservan su edición.\nEl resto de Kanto aún no está implementado. Laboratorio anterior accesible desde el menú.\n\nPasa el cursor para prever. Clic en casilla azul: mover; clic en enemigo: básico.\n1/2/3/4/5: movimientos; A: menú de habilidades; R: rectificar solo movimiento, antes de actuar; F: orientar desde tablero.\nFlechas/Enter: casillas; clic derecho/Esc: cancelar selección; F8: continuar; F1: menú.\nEl menú de órdenes aparece a la derecha en turnos aliados. Solo se confirma un ataque con riesgo para aliados.\nCampaña: %APPDATA%/PokemonTacticsLab/kanto-save.json.\nLaboratorio independiente: laboratory-save.json\nCréditos y licencias acompañan al ejecutable.\n', 'utf8');
  const digest = createHash('sha256').update(readFileSync(resolve(output, 'PokemonTactics.exe'))).digest('hex');
  writeFileSync(resolve(output, 'SHA256SUMS.txt'), `${digest}  PokemonTactics.exe\n`);
  console.log(`Windows executable: ${resolve(output, 'PokemonTactics.exe')}\nSHA256: ${digest}`);
} else if (operation === 'qa-export') {
  const release = resolve(output, 'PokemonTactics.exe');
  if (!existsSync(release)) throw new Error('Run npm run godot:export first.');
  run(release, ['--position', '-10000,-10000', '--audio-driver', 'Dummy', '--log-file', resolve(work, 'engine-release.log'), '--', `--qa-dir=${resolve(work, 'release')}`], 'ui-release', output);
  verifyUi(resolve(work, 'release'));
} else {
  throw new Error(`Unknown operation: ${operation}`);
}
