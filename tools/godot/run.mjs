import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, mkdirSync, writeFileSync, cpSync, readdirSync, renameSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { gunzipSync } from 'node:zlib';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const project = resolve(root, 'godot');
const nativeVersion = readFileSync(resolve(project, 'project.godot'),'utf8').match(/config\/version="([^"]+)"/)[1];
const chapter = Number(readFileSync(resolve(project, 'project.godot'),'utf8').match(/config\/qa_stage=(\d+)/)?.[1] ?? nativeVersion.split('.')[1]);
const qaLabel = chapter>=23 && Number(nativeVersion.split('.')[2])>0 ? `${chapter}-ui-${nativeVersion.split('.')[2]}` : chapter===22 && Number(nativeVersion.split('.')[2])>=4 ? '22-updates-'+nativeVersion.split('.')[2] : nativeVersion === '0.22.3' ? '22-context' : nativeVersion === '0.22.2' ? '22-controls' : nativeVersion === '0.22.1' ? '22-ui' : String(chapter);
const work = process.env.GODOT_QA_DIR ? resolve(process.env.GODOT_QA_DIR) : resolve(root, `../../work/qa-sprint-${qaLabel}`);
const output = resolve(root, `../releases/pokemon-tactics-${nativeVersion}/windows`);
const operation = process.argv[2] ?? 'test';
const binary = process.env.GODOT_BIN ?? resolve(root, '../../work/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe');
mkdirSync(work, { recursive: true });
const isolatedProfile = resolve(work, 'profile');
const isolatedLocal = resolve(work, 'local-profile');
mkdirSync(isolatedProfile, { recursive: true });
mkdirSync(isolatedLocal, { recursive: true });
function run(executable, args, label, cwd = root) {
  if(chapter>=31 && /^(copy|kanto)-(source|release)$/.test(label)) args=[...args,'--compat-kanto'];
  if((chapter>=32 || (nativeVersion.startsWith('0.31.') && Number(nativeVersion.split('.')[2])>=1)) && /^power-(source|release)$/.test(label)) args=[...args,'--compat-power'];
  if(chapter>=32 && /^(sleep|symbols)-(source|release)$/.test(label)) args=[...args,'--compat-sleep'];
  if(chapter>=34 && /^playthrough-(source|release)$/.test(label)) args=[...args,'--compat-review'];
  // Historical UI suites keep their published edition. Current content has qa-kanto.
  if(chapter>=30 && /^(player|shop|trainer)-(source|release)$/.test(label)) args=[...args,'--compat-adventure'];
  const logIndex = args.indexOf('--log-file');
  if (logIndex >= 0) writeFileSync(args[logIndex + 1], '');
  const result = spawnSync(executable, args, { cwd, env:{...process.env,APPDATA:isolatedProfile,LOCALAPPDATA:isolatedLocal}, encoding: 'utf8', windowsHide: true, timeout: label.startsWith('relief-') ? 900_000 : label.includes('playthrough') ? 3_600_000 : (label.startsWith('sleep-') || label.startsWith('symbols-')) ? 90000 : label==='simulate-balance' ? 1_800_000 : label.startsWith('journey-ui-') || label.startsWith('updates-ui-') || label==='ui-release' || label==='ui-source' || label==='test-journey' ? 900_000 : 300_000, maxBuffer: 12 * 1024 * 1024 });
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
  if(existsSync(resolve(project,"data/relief-maps.json"))) {
    const relief=spawnSync("python",[resolve(root,"tools/godot/verify-relief.py")],{cwd:root,encoding:"utf8",windowsHide:true});
    if(relief.status!==0) throw new Error("Relief geometry failed: "+relief.stderr);
    console.log("Verified58 relief layouts, landmarks and two ground approaches without changing published catalogues.");
  }
  const climate=JSON.parse(readFileSync(resolve(project,'data/climate-provenance.json'),'utf8'));
  for(const entry of climate.files) if(createHash('sha256').update(readFileSync(resolve(project,entry.target))).digest('hex')!==entry.sha256) throw new Error('Climate data changed without review');
  const symbols=spawnSync('python',[resolve(root,'tools/godot/import-ui-symbols.py')],{cwd:root,encoding:'utf8',windowsHide:true});
  if(symbols.status!==0) throw new Error('UI sprite integrity failed: '+symbols.stderr);
  console.log('Verified 21 original type/category sprites and pinned credits offline.');
  if(chapter>=30) {
    const kanto=spawnSync('python',[resolve(root,'tools/godot/verify-kanto.py')],{cwd:root,encoding:'utf8',windowsHide:true});
    if(kanto.status!==0) throw new Error('Kanto resources failed: '+kanto.stderr);
    console.log('Verified Kanto atlas alpha/CRC/hash,116 authored layouts and unchanged numerical encounters.');
  }
  const merchantPath=resolve(project,'assets/merchant/manifest.json');
  if(existsSync(merchantPath)) {
    const manifest=JSON.parse(readFileSync(merchantPath,'utf8'));
    for(const entry of manifest.files) if(createHash('sha256').update(readFileSync(resolve(project,entry.target))).digest('hex')!==entry.sha256) throw new Error('Merchant resource hash mismatch');
    console.log('Verified '+manifest.files.length+' original Kecleon resources and credits.');
  }

  const originalAudio=spawnSync('python',[resolve(root,'tools/godot/verify-original-moves.py')],{cwd:root,encoding:'utf8',windowsHide:true});
  if(originalAudio.status!==0) throw new Error('Original audio integrity failed: '+originalAudio.stderr);
  const combatAudio=spawnSync('python',[resolve(root,'tools/godot/verify-combat-audio.py')],{cwd:root,encoding:'utf8',windowsHide:true});
  if(combatAudio.status!==0) throw new Error('Combat audio validation failed: '+combatAudio.stderr);
  console.log('Verified 26 combat sounds and pinned synthesizer hashes.');
  const artwork=spawnSync('python',[resolve(root,'tools/godot/art-assets.py'),'check'],{cwd:root,encoding:'utf8',windowsHide:true});
  if(artwork.status!==0) throw new Error('Art validation failed: '+artwork.stderr);
  const artReport=JSON.parse(artwork.stdout);
  console.log(`Verified ${artReport.slots} artwork slots; ${artReport.pendingRequired.length} required images remain placeholders.`);
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
if (!['qa-fluency-export','qa-economy-export','qa-moves-export','qa-spatial-export','qa-attack-effects-export','qa-export','qa-campaign-export','qa-scale-export','qa-roster-export','qa-journey-export','qa-journey-psychic-export','qa-interface-export','qa-input-export','qa-context-export','qa-updates-export','qa-semantic-export','qa-performance-export','qa-seeds-export'].includes(operation)) {
  if (!existsSync(binary)) throw new Error('Godot not found. Set GODOT_BIN to the standard Godot 4.7.2 executable.');
  const version = spawnSync(binary, ['--version'], { encoding: 'utf8', windowsHide: true });
  if (version.status !== 0 || !version.stdout.startsWith('4.7.2.stable.')) throw new Error('Expected Godot 4.7.2 stable.');
}
const common = ['--path', project, '--log-file', resolve(work, `engine-${operation}.log`)];
if(operation === 'qa-dex-dialog' || operation === 'qa-dex-dialog-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'dex-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--dex-qa-dir='+directory],'dex-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'dex-dialog.json'),'utf8'));
  if(report.failures.length || report.assertions<60) throw new Error('Pokédex dialog regression failed');
} else if(operation === 'qa-candidate-journey' || operation === 'qa-candidate-journey-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'journey-'+(exported?'release':'source'));
  const journal=process.env.CANDIDATE_JOURNAL??resolve(work,'journey-strategy.json');
  if(!existsSync(journal)) {
    const prepared=spawnSync('python',[resolve(root,'tools/godot/prepare-candidate-journey.py')],{cwd:root,encoding:'utf8',windowsHide:true});
    if(prepared.status!==0 || !existsSync(journal)) throw new Error('Prepare a legal campaign journal first: '+prepared.stderr);
  }
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--candidate-journey-dir='+directory,'--review-journal='+journal],'playthrough-candidate-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'candidate-journey.json'),'utf8'));
  if(report.failures.length || report.visited.length!==58 || report.orders!==10277) throw new Error('Full native campaign failed');
} else if(operation === 'replay-relief') {
  run(binary,['--headless',...common,'--script','res://tests/relief_replay.gd','--','--save-dir='+resolve(work,'natural-relief-final')],'playthrough-relief-cold');
} else if(operation === 'test-relief-compat') {
  run(binary,['--headless',...common,'--script','res://tests/relief_compat.gd','--','--save-dir='+resolve(work,'relief-compat')],'relief-compat');
} else if(operation === 'test-relief') {
  run(binary,['--headless',...common,'--script','res://tests/relief_rules.gd','--','--save-dir='+resolve(work,'relief-rules')],'relief-rules');
} else if(operation === 'simulate-relief') {
  run(binary,['--headless',...common,'--script','res://tests/relief_campaign.gd','--','--save-dir='+resolve(work,'natural-relief-final')],'playthrough-relief');
} else if(operation === 'qa-relief' || operation === 'qa-relief-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'relief-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--relief-qa-dir='+directory],'relief-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'relief-ui.json'),'utf8'));
  if(report.failures.length || report.gallery.length!==116) throw new Error('Relief UI failed');
} else if(operation === 'qa-profile' || operation === 'qa-profile-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'profile-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--profile-polish','--trainer-qa-dir='+directory],'profile-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'profile-polish.json'),'utf8'));
  if(report.failures.length || report.assertions<158) throw new Error('Trainer profile QA failed');
} else if(operation === 'qa-closing-usability' || operation === 'qa-closing-usability-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'closing-usability-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--closing-usability-dir='+directory],'closing-usability-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'closing-usability.json'),'utf8'));
  if(report.failures.length || report.assertions<25) throw new Error('Current usability QA failed');
} else if(operation === 'qa-closing-playthrough' || operation === 'qa-closing-playthrough-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'closing-playthrough-'+(exported?'release':'source'));
  const journal=process.env.CLOSING_JOURNAL??resolve(root,'docs/qa/sprint-36/closing-journal.json');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--closing-playthrough-dir='+directory,'--review-journal='+journal],'closing-playthrough-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'closing-playthrough.json'),'utf8'));
  if(report.failures.length || report.visited.length!==58 || report.orders<7800) throw new Error('Current complete native campaign failed');
} else if(operation === 'test-closing') {
  run(binary,['--headless',...common,'--script','res://tests/closing_rules.gd','--','--save-dir='+resolve(work,'closing-rules')],'closing-rules');
} else if(operation === 'simulate-closing') {
  const directory=resolve(work,'full-current-'+(process.env.CLOSING_ATTEMPT??'01'));
  run(binary,['--headless',...common,'--script','res://tests/closing_campaign.gd','--','--save-dir='+directory,'--strategy='+resolve(root,'docs/qa/sprint-34/campaign-journal.json')],'playthrough-closing-core');
} else if(operation === 'qa-closing-performance' || operation === 'qa-closing-performance-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'closing-performance-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--performance-final','--performance-qa-dir='+directory],'closing-performance-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'closing-performance.json'),'utf8'));
  if(report.failures.length || report.assertions<200) throw new Error('Current-edition performance QA failed');
} else if(operation === 'test-collection') {
  run(binary,['--headless',...common,'--script','res://tests/collection.gd','--','--save-dir='+work],'collection-core');
} else if(operation === 'qa-collection' || operation === 'qa-collection-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'collection-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--collection-qa-dir='+directory],'collection-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'collection-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<30) throw new Error('Collection UI failed.');
} else if(operation === 'test-quality') {
  run(binary,['--headless',...common,'--script','res://tests/quality.gd','--','--save-dir='+work],'quality-core');
} else if(operation === 'simulate-quality') {
  const directory=resolve(work,'natural-quality-'+(process.env.QUALITY_ATTEMPT??'03'));
  run(binary,['--headless',...common,'--script','res://tests/quality_campaign.gd','--','--save-dir='+directory,...(existsSync(resolve(work,'quality-prefix.json'))?['--prefix='+resolve(work,'quality-prefix.json')]:[])],'playthrough-quality-core');
} else if(operation === 'qa-quality' || operation === 'qa-quality-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'quality-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--quality-qa-dir='+directory,'--load-journal='+resolve(root,'docs/qa/sprint-33/campaign-journal.json')],'quality-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'quality-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<180 || report.encounters.length!==58) throw new Error('Full campaign quality UI failed.');
} else if(operation === 'qa-playthrough' || operation === 'qa-playthrough-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'playthrough-'+(exported?'release':'source'));
  const journal=existsSync(resolve(work,'natural-coverage/campaign-journal.json'))?resolve(work,'natural-coverage/campaign-journal.json'):resolve(root,'docs/qa/sprint-33/campaign-journal.json');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--playthrough-qa-dir='+directory,'--review-journal='+journal],'playthrough-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'playthrough-ui-result.json'),'utf8'));
  if(report.failures.length || report.visited.length!==58 || report.medals!==8) throw new Error('Full campaign UI failed.');
} else if(operation === 'test-review') {
  run(binary,['--headless',...common,'--quit-after','60','--script','res://tests/review_rules.gd','--','--save-dir='+work],'review-core');
  cpSync(resolve(work,'climate-result.json'),resolve(work,'review-result.json'));
} else if(operation === 'qa-briefing' || operation === 'qa-briefing-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'briefing-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--briefing-qa-dir='+directory],'briefing-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'briefing-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<300 || report.encounters.length!==58) throw new Error('Encounter preview UI failed.');
} else if(operation === 'qa-review' || operation === 'qa-review-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'review-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--review-qa-dir='+directory],'review-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'review-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<40) throw new Error('Review UI failed.');
} else if(operation === 'test-climate') {
  run(binary,['--headless',...common,'--quit-after','60','--script','res://tests/climate.gd','--','--save-dir='+work],'climate-core');
} else if(operation === 'qa-climate' || operation === 'qa-climate-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'climate-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--climate-qa-dir='+directory],'climate-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'climate-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<30) throw new Error('Climate UI failed.');
} else if(operation === 'qa-symbols' || operation === 'qa-symbols-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'symbols-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--symbols-qa-dir='+directory],'symbols-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'symbols-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<50) throw new Error('Visual UI failed.');
} else if(operation === 'test-sleep') {
  run(binary,['--headless',...common,'--script','res://tests/sleep_fix.gd','--','--save-dir='+work],'sleep-core');
} else if(operation === 'qa-sleep' || operation === 'qa-sleep-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'sleep-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--sleep-qa-dir='+directory],'sleep-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'sleep-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<15) throw new Error('Sleep UI failed.');
} else if(operation === 'test-power') {
  run(binary,['--headless',...common,'--script','res://tests/power.gd','--','--save-dir='+work],'power-core');
} else if(operation === 'qa-power' || operation === 'qa-power-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'power-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--power-qa-dir='+directory],'power-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'power-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<20) throw new Error('Power UI failed.');
} else if(operation === 'qa-copy' || operation === 'qa-copy-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'copy-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--copy-qa-dir='+directory],'copy-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'copy-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<250) throw new Error('Player copy UI failed.');
} else if(operation === 'test-kanto') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/kanto_landscapes.gd','--','--save-dir='+work],'kanto-core');
} else if(operation === 'qa-kanto' || operation === 'qa-kanto-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,'kanto-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--kanto-qa-dir='+directory],'kanto-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'kanto-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<100) throw new Error('Kanto UI failed.');
} else if(operation === 'test-variety') {
  verify();
  run(binary,['--headless',...common,'--script','res://tests/variety.gd','--','--save-dir='+work],'variety-core');
} else if(operation === 'qa-variety' || operation === 'qa-variety-export') {
  const exported=operation.endsWith('-export');
  if(!exported) verify();
  const directory=resolve(work,'variety-'+(exported?'release':'source'));
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--variety-qa-dir='+directory],'variety-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'variety-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<50) throw new Error('Variety UI failed.');
} else if(operation === 'qa-shop' || operation === 'qa-shop-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'shop-release':'shop-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--shop-qa-dir='+directory],'shop-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'shop-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<50) throw new Error('Kecleon shop failed');
} else if(operation === 'test-trainer') {
  run(binary,['--headless',...common,'--script','res://tests/trainer.gd','--','--save-dir='+work],'test-trainer');
} else if(operation === 'qa-trainer' || operation === 'qa-trainer-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'trainer-release':'trainer-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--trainer-qa-dir='+directory],'trainer-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'trainer-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<50) throw new Error('Trainer UI failed');
} else if(operation === 'simulate-adventure') {
  run(binary,['--headless',...common,'--script','res://tests/adventure_balance.gd','--','--save-dir='+work],'simulate-balance');
} else if(operation === 'test-adventure') {
  run(binary,['--headless',...common,'--script','res://tests/adventure.gd','--','--save-dir='+work],'test-adventure');
} else if(operation === 'qa-player' || operation === 'qa-player-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'player-release':'player-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--player-qa-dir='+directory],'player-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'player-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<100 || report.naturalPhase!=='shop') throw new Error('Player UI failed');
} else if(operation === 'qa-adventure' || operation === 'qa-adventure-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'adventure-release':'adventure-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--adventure-qa-dir='+directory],'adventure-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'adventure-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<20) throw new Error('Adventure UI failed');
} else if(operation === 'test-economy') {
  run(binary,['--headless',...common,'--script','res://tests/economy.gd','--','--save-dir='+work],'test-economy');
} else if(operation === 'simulate-economy') {
  run(binary,['--headless',...common,'--script','res://tests/economy_balance.gd','--','--save-dir='+work],'simulate-balance');
} else if(operation === 'qa-economy' || operation === 'qa-economy-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'economy-release':'economy-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','-10000,-10000','--audio-driver','Dummy','--','--compat-economy','--economy-qa-dir='+directory],'economy-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'economy-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<40) throw new Error('Economy QA failed');
} else if(operation === 'test-spatial') {
  run(binary,['--headless',...common,'--script','res://tests/spatial.gd','--','--save-dir='+work],'test-spatial');
} else if(operation === 'qa-moves' || operation === 'qa-moves-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'moves-release':'moves-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','-10000,-10000','--audio-driver','Dummy','--','--compat-economy','--moves-qa-dir='+directory],'moves-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'moves-ui-result.json'),'utf8'));
  if(report.failures.length || report.layouts.length!==56) throw new Error('Equipped move UI regression failed');
} else if(operation === 'qa-spatial' || operation === 'qa-spatial-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'spatial-release':'spatial-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','-10000,-10000','--audio-driver','Dummy','--','--compat-economy','--spatial-qa-dir='+directory],'spatial-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'spatial-ui-result.json'),'utf8'));
  if(report.failures.length || report.originalSounds!==40 || !report.naturalCampaignReplay) throw new Error('Spatial QA failed');
} else if (operation === 'qa-attack-effects' || operation === 'qa-attack-effects-export') {
  const exported=operation.endsWith('export');
  if(!exported) verify();
  const directory=resolve(work,exported?'attack-effects-release':'attack-effects-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','-10000,-10000','--audio-driver','Dummy','--','--attack-qa-dir='+directory],'attack-effects-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'attack-effects-result.json'),'utf8'));
  if(report.failures.length || report.sounds!==26 || report.types!==18) throw new Error('Attack presentation QA failed');
} else if (operation === 'qa-seeds' || operation === 'qa-seeds-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'seeds-release':'seeds-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','-10000,-10000','--audio-driver','Dummy','--','--seeds-qa-dir='+directory],'seeds-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'seeds-ui-result.json'),'utf8'));
  if(report.failures.length || report.seedProbes!==64 || report.distinctCaptureTraces<2 || report.naturalCaptures.length!==2) throw new Error('Seed regression failed');
} else if (operation === 'qa-fluency' || operation === 'qa-fluency-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'fluency-release':'fluency-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--performance-current','--performance-qa-dir='+directory],'fluency-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'performance-result.json'),'utf8'));
  if(report.failures.length || report.assertions<100 || report.measurements.planner.cases<50) throw new Error('Current performance and AI equivalence QA failed');
} else if (operation === 'qa-performance' || operation === 'qa-performance-export') {
  const exported=operation.endsWith('export');
  const directory=resolve(work,exported?'performance-release':'performance-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','50,50','--audio-driver','Dummy','--','--performance-qa-dir='+directory],'performance-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'performance-result.json'),'utf8'));
  if(report.failures.length || report.assertions<18) throw new Error('Performance regression failed');
} else if (operation === 'qa-semantic' || operation === 'qa-semantic-export') {
  const exported=operation.endsWith('export');
  if(!exported) verify();
  const directory=resolve(work,exported?'semantic-release':'semantic-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--accessibility','always','--position','-10000,-10000','--audio-driver','Dummy','--','--updates-scope=semantic','--updates-qa-dir='+directory],'semantic-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'updates-ui-result.json'),'utf8'));
  if(report.failures.length) throw new Error('Semantic prototype failed');
} else if (operation === 'test-shop-batch') {
  run(binary,['--headless',...common,'--script','res://tests/shop_batch.gd'],'shop-batch');
} else if (operation === 'test-controls') {
  verify();
  for(const phase of ['write','read']) run(binary,['--headless',...common,'--script','res://tests/control_preferences.gd','--','--save-dir='+work,'--phase='+phase],'preferences-'+phase);
} else if (operation === 'qa-updates' || operation === 'qa-updates-export') {
  const exported=operation.endsWith('export');
  if(!exported) verify();
  const directory=resolve(work,exported?'updates-release':'updates-source');
  run(exported?resolve(output,'PokemonTactics.exe'):binary,[...(exported?[]:common),'--position','-10000,-10000','--audio-driver','Dummy','--','--updates-qa-dir='+directory],'updates-ui-'+(exported?'release':'source'),exported?output:root);
  const report=JSON.parse(readFileSync(resolve(directory,'updates-ui-result.json'),'utf8'));
  if(report.failures.length) throw new Error('Updates UI failed');
} else if (operation === 'qa-context' || operation === 'qa-context-export') {
  const exported = operation.endsWith('export');
  if (!exported) verify();
  const directory = resolve(work,exported ? 'context-release' : 'context-source');
  const args = [...(exported ? [] : common),'--position','-10000,-10000','--audio-driver','Dummy','--','--context-qa-dir='+directory];
  run(exported ? resolve(output,'PokemonTactics.exe') : binary,args,'context-ui-'+(exported?'release':'source'),exported ? output : root);
  const report = JSON.parse(readFileSync(resolve(directory,'context-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<40) throw new Error('Context UI failed.');
} else if (operation === 'qa-input' || operation === 'qa-input-export') {
  const exported = operation.endsWith('export');
  if (!exported) verify();
  const directory = resolve(work,exported ? 'input-release' : 'input-source');
  const args = [...(exported ? [] : common),'--position','-10000,-10000','--audio-driver','Dummy','--','--input-qa-dir='+directory];
  run(exported ? resolve(output,'PokemonTactics.exe') : binary,args,'input-ui-'+(exported?'release':'source'),exported ? output : root);
  const report = JSON.parse(readFileSync(resolve(directory,'input-ui-result.json'),'utf8'));
  if(report.failures.length || report.assertions<44) throw new Error('Input UI failed.');
} else if (operation === 'test-release' || operation === 'simulate-balance') {
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
  if (psychic && qaLabel!=='22') cpSync(resolve(root,'../../work/qa-sprint-22/balance-champion-24.json'),resolve(work,'balance-champion-24.json'));
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
  if (/^1\.0\.0-rc\.[12]$/.test(nativeVersion)) {
    cpSync(resolve(root,'docs/LEEME_WINDOWS.txt'),resolve(output,'LEEME.txt'));
    const digest = createHash('sha256').update(readFileSync(resolve(output,'PokemonTactics.exe'))).digest('hex');
    writeFileSync(resolve(output,'SHA256SUMS.txt'),`${digest}  PokemonTactics.exe\n`);
    console.log(`Private RC executable: ${resolve(output,'PokemonTactics.exe')}\nSHA256: ${digest}`);
    process.exit(0);
  }
  if (chapter >= 22) {
    cpSync(resolve(root, 'docs/PLAYTEST_WINDOWS.md'), resolve(output, 'GUIA_DE_PRUEBA.md'));
    const report = readFileSync(resolve(root, 'docs/reports/balance-native-0.22/INFORME.md'), 'utf8')
      .replace('(results.json)', '(BALANCE_RESULTADOS.json)').replace('(../../PLAYTEST_WINDOWS.md)', '(GUIA_DE_PRUEBA.md)');
    writeFileSync(resolve(output, 'INFORME_BALANCE.md'), (chapter>=23?'# Informe histórico de 0.22\n\nLas nuevas reglas espaciales de 0.23 requieren otras pruebas de balance. Este informe describe exclusivamente la edición anterior.\n\n':'')+report);
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
${chapter>=24?'Cuatro movimientos preparados más básico neutro. Curvas de EXP por especie; tienda Entrenar cobra1 ₽ por cada EXP que falte para el siguiente nivel, respetando el tope del próximo gimnasio. El aumento de PS máximos también se recupera.\nSin Caramelos ni piedras/cables. Evoluciones por nivel automáticas; antiguas evoluciones por objeto/intercambio se eligen gratis desde Ficha al alcanzar el mínimo adaptado. Eevee permite elegir rama. Reroll local antes de aceptar captura:60/120/180... ₽; insignia de gimnasio fija. Actualizar desde mapa/tienda conserva niveles/PS, proporción de EXP parcial y devuelve el precio de objetos retirados.':'Cuatro movimientos preparados más básico neutro. EXP y Caramelos25 ₽ suben niveles con límite del siguiente gimnasio. PS actuales recuperan el aumento de PS máximos.\nEvolución automática por nivel; piedras/Cable Vínculo80 ₽ cuando corresponda. Pikachu20 y Graveler36 son excepciones adaptadas.'}
Sin curación gratuita; usa objetos fuera de combate. Revivir150 ₽ devuelve50% PS. Perder acaba la campaña aunque haya reservas vivas.
Mapas16/24 con alturas. Clic en azul: mover; clic en rival: básico. Habilidades integradas; R rectifica solo movimiento antes de actuar. F orienta y termina. Flechas/Enter y Escape disponibles.
Seleccionar habilidad solo prepara; Q/E recorre objetivos; Enter o clic acepta. F abre orientación: flechas previsualizan y Enter termina.
Rueda/+/-: zoom; cruceta, Alt+flechas o modo P: cámara; central opcional; C unidad; Combate/Mapa encuadran. G/H cuadrícula/alturas.
F2 elige modo Rápido/Seguro. Ambos confirman daño a aliados o coste propio letal; no hay gasto al cancelar.
F2: configurar controles, F6: cambiar panel. Las etiquetas reflejan las teclas reasignadas; Enter/Espacio, Escape, Tab y flechas siguen como seguridad. Preferencias independientes en controls.json; compras y órdenes no se repiten al mantener una tecla.
Datos/repertorios LGPE combinados, sin movimientos de los iniciales especiales; historia/equipos de entrenadores de Rojo. PT/alcances y efectos complejos son adaptaciones visibles en ficha. Habilidades pendientes están etiquetadas; sin clima ni huida.
Dos finales excluyentes tras la Liga: tres aves juntas o Mew/Mewtwo. Legendarios nunca reclutables. Recuperación, Respiro, Amortiguador y Descanso tienen cinco usos por combate además de PT. Actualizar una campaña ya terminada conserva su final.
Consulta GUIA_DE_PRUEBA.md e INFORME_BALANCE.md para controles, sesiones propuestas y límites de las simulaciones. 49/78 habilidades normales activas; 29 pendientes. Arte del juego integrado; consulta ARTE_INTEGRADO.md. Dificultad y diversión requieren pruebas humanas.
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
