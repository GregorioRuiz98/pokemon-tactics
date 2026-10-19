import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, mkdirSync, writeFileSync, cpSync, readdirSync, renameSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { gunzipSync } from 'node:zlib';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const project = resolve(root, 'godot');
const nativeVersion = readFileSync(resolve(project, 'project.godot'),'utf8').match(/config\/version="([^"]+)"/)[1];
const chapter = Number(nativeVersion.split('.')[1]);
const qaLabel = nativeVersion === '0.22.1' ? '22-ui' : String(chapter);
const work = resolve(root, `../../work/qa-sprint-${qaLabel}`);
const output = resolve(root, `../releases/pokemon-tactics-${nativeVersion}/windows`);
const operation = process.argv[2] ?? 'test';
const binary = process.env.GODOT_BIN ?? resolve(root, '../../work/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe');
mkdirSync(work, { recursive: true });
function run(executable, args, label, cwd = root) {
  const logIndex = args.indexOf('--log-file');
  if (logIndex >= 0) writeFileSync(args[logIndex + 1], '');
  const result = spawnSync(executable, args, { cwd, encoding: 'utf8', windowsHide: true, timeout: label==='simulate-balance' ? 1_800_000 : label.startsWith('journey-ui-') || label==='test-journey' ? 900_000 : 300_000, maxBuffer: 12 * 1024 * 1024 });
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
  for (const name of ['progression-provenance','feedback-provenance','shop-provenance','letsgo-provenance','traits-provenance','expedition-provenance',...readdirSync(resolve(project,'data')).filter(n => /^journey-\d+-provenance\.json$/.test(n)).map(n=>n.slice(0,-5))]) {
    const extra=JSON.parse(readFileSync(resolve(project,'data/'+name+'.json'),'utf8'));
    for (const entry of extra.files) if(createHash('sha256').update(readFileSync(resolve(project,entry.target))).digest('hex') !== entry.sha256) throw new Error('Progression resource hash mismatch: '+entry.target);
    console.log('Verified '+extra.files.length+' files in '+name+'.');
  }
  const fixtures = JSON.parse(gunzipSync(readFileSync(resolve(project, 'tests/parity.json.gz'))).toString('utf8'));
  console.log(`Verified ${manifest.files.length} assets and ${manifest.ruleSources.length} reference source hashes; ${fixtures.games.length} complete battles.`);
}
if (operation === 'verify') { verify(); process.exit(0); }
if (!['qa-export','qa-campaign-export','qa-scale-export','qa-roster-export','qa-journey-export','qa-journey-psychic-export','qa-interface-export'].includes(operation)) {
  if (!existsSync(binary)) throw new Error('Godot not found. Set GODOT_BIN to the standard Godot 4.7.2 executable.');
  const version = spawnSync(binary, ['--version'], { encoding: 'utf8', windowsHide: true });
  if (version.status !== 0 || !version.stdout.startsWith('4.7.2.stable.')) throw new Error('Expected Godot 4.7.2 stable.');
}
const common = ['--path', project, '--log-file', resolve(work, `engine-${operation}.log`)];
if (operation === 'test-release' || operation === 'simulate-balance') {
  verify();
  if (operation === 'simulate-balance') {
    const previous = readdirSync(work).filter(name => name === 'balance-native.json' || name === 'balance-champion-24.json' || /^balance-[147]-(16|24)-(birds|psychic)\.json$/.test(name));
    if (previous.length) {
      const archive = resolve(work, `balance-history-${Date.now()}`);
      mkdirSync(archive);
      for (const name of previous) renameSync(resolve(work, name), resolve(archive, name));
    }
  }
  run(binary,['--headless',...common,'--script',operation==='test-release'?'res://tests/release_checks.gd':'res://tests/balance_native.gd','--','--save-dir='+work],operation);
} else if (operation === 'test-journey' || operation === 'test-expedition-abilities' || operation === 'test-finale') {
  verify();
  run(binary,['--headless',...common,'--script',operation==='test-journey'?'res://tests/journey.gd':(operation==='test-finale'?'res://tests/finale_rules.gd':'res://tests/expedition_abilities.gd'),'--','--save-dir='+work,'--chapter='+ (process.env.KANTO_CHAPTER ?? String(chapter))],operation);
} else if (operation === 'qa-interface' || operation === 'qa-interface-export') {
  const exported = operation.endsWith('export');
  if (!exported) verify();
  const directory = resolve(work, exported ? 'interface-release' : 'interface-source');
  const args = [...(exported ? [] : common),'--position','-10000,-10000','--audio-driver','Dummy','--','--interface-qa-dir='+directory];
  run(exported ? resolve(output,'PokemonTactics.exe') : binary,args,'interface-ui-'+(exported?'release':'source'),exported ? output : root);
  const report = JSON.parse(readFileSync(resolve(directory,'interface-ui-result.json'),'utf8'));
  if (report.failures.length || !report.battlePaused || !report.savePreserved) throw new Error('Interface regression failed.');
} else if (operation === 'test-expedition') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/expedition.gd','--','--save-dir='+work,'--chapter='+ (process.env.KANTO_CHAPTER ?? String(chapter))],'expedition-core');
} else if (['qa-journey','qa-journey-export','qa-journey-psychic','qa-journey-psychic-export','qa-interface-export'].includes(operation)) {
  const exported = operation.endsWith('export');
  const psychic = operation.includes('psychic');
  if (!exported) verify();
  const directory = resolve(work,(psychic ? 'journey-psychic-' : 'journey-')+(exported ? 'release' : 'source'));
  if (psychic && qaLabel==='22-ui') cpSync(resolve(root,'../../work/qa-sprint-22/balance-champion-24.json'),resolve(work,'balance-champion-24.json'));
  const args = [...(exported ? [] : common),'--position','-10000,-10000','--audio-driver','Dummy','--','--journey-qa-dir='+directory,...(psychic ? ['--journey-final=psychic'] : [])];
  run(exported ? resolve(output,'PokemonTactics.exe') : binary,args,'journey-ui-'+(psychic?'psychic-':'')+(exported?'release':'source'),exported ? output : root);
  const report = JSON.parse(readFileSync(resolve(directory,'journey-ui-result.json'),'utf8'));
  if(report.failures.length || report.phase==='defeat' || !report.cleared.length) throw new Error('Journey UI failed.');
} else if (operation === 'test-roster') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/roster.gd','--','--save-dir='+work],'roster-core');
} else if (operation === 'qa-roster' || operation === 'qa-roster-export') {
  const exported = operation === 'qa-roster-export';
  if (!exported) verify();
  const directory = resolve(work,exported ? 'roster-release' : 'roster-source');
  const args = [...(exported ? [] : common),'--position','-10000,-10000','--audio-driver','Dummy','--','--roster-qa-dir='+directory];
  run(exported ? resolve(output,'PokemonTactics.exe') : binary,args,'roster-ui-'+(exported?'release':'source'),exported ? output : root);
  const report = JSON.parse(readFileSync(resolve(directory,'roster-ui-result.json'),'utf8'));
  if(report.failures.length || !report.pcUsed || !report.overflowChecked) throw new Error('Roster UI failed.');
} else if (operation === 'test-scale') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/scale.gd','--','--save-dir='+work],'scale-core');
} else if (operation === 'qa-scale' || operation === 'qa-scale-export') {
  const exported = operation === 'qa-scale-export';
  if (!exported) verify();
  const directory = resolve(work,exported ? 'scale-release' : 'scale-source');
  const args = [...(exported ? [] : common),'--position','-10000,-10000','--audio-driver','Dummy','--','--scale-qa-dir='+directory];
  run(exported ? resolve(output,'PokemonTactics.exe') : binary,args,'scale-ui-'+(exported?'release':'source'),exported ? output : root);
  const report = JSON.parse(readFileSync(resolve(directory,'scale-ui-result.json'),'utf8'));
  if(report.failures.length || report.completed.length!==2) throw new Error('Scale UI failed.');
} else if (operation === 'test-traits-journey') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/traits_journey.gd','--','--save-dir='+work],'traits-journeys');
} else if (operation === 'test-traits') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/traits.gd','--','--save-dir='+work],'traits-core');
} else if (operation === 'test-revive') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/revive.gd','--','--save-dir='+work],'revive-core');
} else if (operation === 'test-gym-caps') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/gym_caps.gd','--','--save-dir='+work],'gym-caps-core');
} else if (operation === 'test-level-hp') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/level_hp.gd','--','--save-dir='+work],'level-hp-core');
} else if (operation === 'test-tactics-journey') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/tactics_journey.gd','--','--save-dir='+work],'tactics-journeys');
} else if (operation === 'test-tactics') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/tactics.gd','--','--save-dir='+work],'tactics-core');
} else if (operation === 'test-letsgo-journey') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/letsgo_journey.gd','--','--save-dir='+work],'letsgo-journey');
} else if (operation === 'test-letsgo') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/letsgo.gd','--','--save-dir='+work],'letsgo-core');
} else if (operation === 'test-growth') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/growth.gd','--','--save-dir='+work],'growth-core');
} else if (operation === 'test-shop') {
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
  if (chapter >= 22) {
    cpSync(resolve(root, 'docs/PLAYTEST_WINDOWS.md'), resolve(output, 'GUIA_DE_PRUEBA.md'));
    const report = readFileSync(resolve(root, 'docs/reports/balance-native-0.22/INFORME.md'), 'utf8')
      .replace('(results.json)', '(BALANCE_RESULTADOS.json)').replace('(../../PLAYTEST_WINDOWS.md)', '(GUIA_DE_PRUEBA.md)');
    writeFileSync(resolve(output, 'INFORME_BALANCE.md'), report);
    cpSync(resolve(root, 'docs/reports/balance-native-0.22/results.json'), resolve(output, 'BALANCE_RESULTADOS.json'));
  }
  const route = JSON.parse(readFileSync(resolve(project,`data/journey-${Math.min(chapter,21)}.json`),'utf8'));
  const end = route.filter(n=>!n.optional && !n.finale).at(-1).name;
  writeFileSync(resolve(output, 'LEEME.txt'), `Pokémon Tactics ${nativeVersion} — Kanto offline

Abre PokemonTactics.exe. No necesitas editor, Node ni servidor.
Contenido: ${route.length} lugares; historia hasta ${end}.
Elige inicial de Oak. Mapa de destinos, capturas locales únicas, tiendas, PC de reserva y seis plazas de equipo.
Para continuar una campaña0.16 o posterior, carga y pulsa Continuar aventura en el mapa, tienda o final del tramo. Conserva copia y diario. Una batalla pendiente conserva su edición hasta terminar.
Guardado automático local: %APPDATA%/PokemonTacticsLab/kanto-save.json. No borres ni sustituyas el archivo para actualizar.
Cuatro movimientos preparados más básico neutro. EXP y Caramelos25 ₽ suben niveles con límite del siguiente gimnasio. PS actuales recuperan el aumento de PS máximos.
Evolución automática por nivel; piedras/Cable Vínculo80 ₽ cuando corresponda. Pikachu20 y Graveler36 son excepciones adaptadas.
Sin curación gratuita; usa objetos fuera de combate. Revivir150 ₽ devuelve50% PS. Perder acaba la campaña aunque haya reservas vivas.
Mapas16/24 con alturas. Clic en azul: mover; clic en rival: básico. Habilidades integradas; R rectifica solo movimiento antes de actuar. F orienta y termina. Flechas/Enter y Escape disponibles.
Rueda/+/-: zoom; botón central: cámara; C unidad; Combate/Mapa encuadran. G/H cuadrícula/alturas.
Datos/repertorios LGPE combinados, sin movimientos de los iniciales especiales; historia/equipos de entrenadores de Rojo. PT/alcances y efectos complejos son adaptaciones visibles en ficha. Habilidades pendientes están etiquetadas; sin clima ni huida.
Dos finales excluyentes tras la Liga: tres aves juntas o Mew/Mewtwo. Legendarios nunca reclutables. Recuperación, Respiro, Amortiguador y Descanso tienen cinco usos por combate además de PT. Actualizar una campaña ya terminada conserva su final.
Consulta GUIA_DE_PRUEBA.md e INFORME_BALANCE.md para controles, sesiones propuestas y límites de las simulaciones.49/78 habilidades normales activas;29 pendientes y terreno provisional. Dificultad y diversión requieren pruebas humanas.
No hay conexión de red, cuentas ni servicios al jugar. Créditos/licencias acompañan la entrega. Publicación pública aplazada.
`, 'utf8');
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
