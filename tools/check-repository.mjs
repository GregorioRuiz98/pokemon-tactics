import { readFileSync, readdirSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve, relative, isAbsolute, sep, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

export const currentDocs = [
  'README.md', 'AGENTS.md', 'PRODUCT.md', 'godot/README.md', 'godot/AGENTS.md',
  'docs/README.md', 'docs/ARCHITECTURE.md', 'docs/PLAN_SPRINTS.md',
  'docs/DEPLOY.md', 'docs/WEB_LEGACY.md', 'docs/LICENCIAS.md',
  'docs/PORTFOLIO.md', 'docs/PLAYTEST_WINDOWS.md', 'docs/REGLAS_ACTUALES.md',
  'docs/history/README.md', 'docs/REPO_CLEANUP_2026-10-27.md', 'docs/SPRINT_35_COLLECTION.md',
  'docs/SPRINT_36_CLOSURE.md', 'docs/SPRINT_37_USABILITY.md', 'docs/RELEASE_1_0_RC1.md',
  'docs/BETA_1_0.md', 'docs/PLANTILLA_BETA.md',
  'docs/SPRINT_38_RC.md',
  'docs/RELEASE_1_0_RC2.md',
  'docs/BETA_RC2_2026-10-28.md',
  'docs/RELEASE_1_0_RC3.md', 'docs/SPRINT_40_RELIEF.md', 'docs/MAPAS_RELIEVE.md',
  'docs/RELEASE_1_0_RC4.md', 'docs/SPRINT_41_STABILITY.md',
  'docs/RELEASE_1_0_RC5.md', 'docs/FEEDBACK.md',
];

export function windowsVersion(version) {
  const match = /^(\d+)\.(\d+)\.(\d+)(?:-rc\.(\d+))?$/.exec(version);
  if (!match) throw new Error('Unsupported native version: ' + version);
  const parts = [match[1], match[2], match[3], match[4] ?? '0'].map(Number);
  if (parts.some(value => value > 65535)) throw new Error('Windows version component exceeds 65535');
  return parts.join('.');
}

export function forbiddenPath(name) {
  const path = name.replaceAll('\\', '/');
  const base = path.split('/').at(-1);
  if (/(^|\/)(node_modules|\.godot|__pycache__)(\/|$)/.test(path) || /^(work|dist|tools\/cache)\//.test(path)) return 'generated directory';
  if (/\.(exe|pck|zip|log|tmp|bak|pyc|verified|verification-key|pem|pfx|p12|key)$/i.test(base)) return 'build, runtime data or key';
  if ((/^\.env(?:\.|$)/.test(base) && base !== '.env.example') || base === 'export_credentials.cfg') return 'local configuration or credentials';
  if (/^(kanto-save.*|laboratory-save.*|trainer-profile|controls)\.json(?:[.-].*)?$/i.test(base)) return 'personal game data';
  return null;
}

export function prose(content) {
  return content.replace(/```[^\n]*\n[\s\S]*?```/g, '').replace(/`[^`\n]*`/g, '');
}

export function localLinks(content) {
  return [...prose(content).matchAll(/!?\[[^\]]*\]\((<[^>]+>|[^\s()]+)(?:\s+"[^"]*")?\)/g)].map(match => match[1].replace(/^<|>$/g, ''));
}

export function resolveLink(root, document, target) {
  if (!target || target.startsWith('#') || /^(https?:|mailto:|data:|app:|codex:)/i.test(target)) return null;
  if (/^[a-z]:[\\/]/i.test(target) || target.startsWith('/') || target.startsWith('\\')) throw new Error('absolute local link');
  const decoded = decodeURIComponent(target.split('#')[0].split('?')[0]);
  if (/^[a-z]:[\\/]/i.test(decoded) || decoded.startsWith('/') || decoded.startsWith('\\')) throw new Error('absolute local link');
  const path = resolve(dirname(resolve(root, document)), decoded);
  const rel = relative(resolve(root), path);
  if (rel === '..' || rel.startsWith('..' + sep) || isAbsolute(rel)) throw new Error('link outside repository');
  return path;
}

export function inspectDocument(root, document, scripts) {
  const failures = [];
  const content = readFileSync(resolve(root, document), 'utf8');
  let links = 0;
  for (const target of localLinks(content)) {
    try {
      const path = resolveLink(root, document, target);
      if (path) { links++; if (!existsSync(path)) failures.push(`${document}: missing link ${target}`); }
    } catch (error) { failures.push(`${document}: ${error.message}: ${target}`); }
  }
  const commands = [...content.matchAll(/npm run ([a-z][a-z0-9:_-]*)/gi)].map(match => match[1]);
  for (const command of commands) if (!Object.hasOwn(scripts, command)) failures.push(`${document}: unknown npm script ${command}`);
  return { links, commands: commands.length, failures };
}

export function auditBundle(root, scripts = {}) {
  const errors = [];
  const directory = resolve(root, 'Documentacion');
  const documents = new Set(['LEEME.txt', 'CREDITS.md', 'Documentacion/REGLAS_ACTUALES.md', 'Documentacion/PLAYTEST_WINDOWS.md', 'Documentacion/GUIA_DE_PRUEBA.md']);
  if (existsSync(directory)) for (const name of readdirSync(directory)) if (name.endsWith('.md')) documents.add('Documentacion/' + name);
  let links = 0;
  for (const document of documents) {
    if (!existsSync(resolve(root, document))) { errors.push(`Missing player document: ${document}`); continue; }
    const result = inspectDocument(root, document, scripts);
    links += result.links; errors.push(...result.failures);
  }
  return { ok: !errors.length, documents: documents.size, localLinks: links, errors, scope: 'Player documentation presence and local links only; no executable launch or external URL check.' };
}

export function audit(root) {
  const errors = [];
  const git = spawnSync('git', ['ls-files', '-z'], { cwd: root, encoding: 'utf8', windowsHide: true, env: { ...process.env, GIT_CONFIG_GLOBAL: process.platform === 'win32' ? 'NUL' : '/dev/null', GIT_CONFIG_NOSYSTEM: '1' } });
  if (git.status !== 0) throw new Error('Run this check in a Git checkout; Git is required.');
  const files = git.stdout.split('\0').filter(Boolean);
  for (const name of files) {
    const reason = forbiddenPath(name);
    if (reason) errors.push(`${name}: ${reason}`);
    if (!existsSync(resolve(root, name))) errors.push(`${name}: indexed file absent from checkout`);
  }
  const manifest = JSON.parse(readFileSync(resolve(root, 'package.json'), 'utf8'));
  const lock = JSON.parse(readFileSync(resolve(root, 'package-lock.json'), 'utf8'));
  if (manifest.version !== lock.version || manifest.version !== lock.packages[''].version) errors.push('Web package/lock versions differ');
  let links = 0, commands = 0;
  for (const doc of currentDocs) {
    if (!existsSync(resolve(root, doc))) { errors.push(`Missing maintained document: ${doc}`); continue; }
    const result = inspectDocument(root, doc, manifest.scripts);
    links += result.links; commands += result.commands; errors.push(...result.failures);
  }
  for (const [script, command] of Object.entries(manifest.scripts)) {
    for (const match of command.matchAll(/\b(tools\/[\w./-]+\.(?:mjs|cjs|ts|py))\b/g)) {
      if (!existsSync(resolve(root, match[1]))) errors.push(`${script}: missing entry point ${match[1]}`);
    }
  }
  const project = readFileSync(resolve(root, 'godot/project.godot'), 'utf8');
  const version = project.match(/config\/version="([^"]+)"/)?.[1];
  if (!version) errors.push('Missing native version');
  else {
    const presets = readFileSync(resolve(root, 'godot/export_presets.cfg'), 'utf8');
    for (const fragment of [`pokemon-tactics-${version}/windows`, `file_version="${windowsVersion(version)}"`, `product_version="${windowsVersion(version)}"`]) if (!presets.includes(fragment)) errors.push(`Export version differs: ${fragment}`);
    for (const doc of ['README.md', 'godot/README.md', 'docs/PLAYTEST_WINDOWS.md', 'docs/REGLAS_ACTUALES.md', 'docs/LEEME_WINDOWS.txt']) if (!readFileSync(resolve(root, doc), 'utf8').includes(version)) errors.push(`${doc}: missing current native version ${version}`);
  }
  return { ok: errors.length === 0, version, indexedFiles: files.length, maintainedDocuments: currentDocs.length, localLinks: links, documentedCommands: commands, errors, scope: 'Local indexed-path hygiene, maintained links, script entry points and version consistency. No network, secret-content/history scan, campaign replay or external hardware test.' };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
    const bundleIndex = process.argv.indexOf('--bundle');
    if (bundleIndex >= 0 && !process.argv[bundleIndex + 1]) throw new Error('--bundle needs a directory');
    const report = bundleIndex >= 0
      ? auditBundle(resolve(root, process.argv[bundleIndex + 1]), JSON.parse(readFileSync(resolve(root, 'package.json'), 'utf8')).scripts)
      : audit(root);
    const reportIndex = process.argv.indexOf('--report');
    if (reportIndex >= 0) {
      const target = process.argv[reportIndex + 1];
      if (!target) throw new Error('--report needs a path');
      const path = resolve(root, target);
      const rel = relative(root, path);
      if (rel === '..' || rel.startsWith('..' + sep) || isAbsolute(rel)) throw new Error('Report must stay inside repository');
      mkdirSync(dirname(path), { recursive: true });
      writeFileSync(path, JSON.stringify(report, null, 2) + '\n');
    }
    console.log(JSON.stringify(report, null, 2));
    process.exitCode = report.ok ? 0 : 1;
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
