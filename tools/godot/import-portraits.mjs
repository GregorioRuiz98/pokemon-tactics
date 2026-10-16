// Explicit asset import. Never called by the game or the normal build.
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const source = JSON.parse(await readFile(resolve(root, 'tools/sources.lock.json'), 'utf8')).sprites;
const records = await Promise.all([1, 4, 7, 25, 12, 74].map(async id => {
  const files = await Promise.all(['Normal.png', 'credits.txt'].map(async name => {
    const url = `${source.raw}/portrait/${String(id).padStart(4, '0')}/${name}`;
    const response = await fetch(url);
    if (!response.ok) throw new Error(`${response.status}: ${url}`);
    const bytes = Buffer.from(await response.arrayBuffer());
    if (name.endsWith('.png') && bytes.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a') throw new Error('Invalid PNG: ' + url);
    const target = `assets/portraits/${id}/${name}`;
    await mkdir(dirname(resolve(root, 'godot', target)), { recursive: true });
    await writeFile(resolve(root, 'godot', target), bytes);
    return { url, target, sha256: createHash('sha256').update(bytes).digest('hex'), ...(name === 'credits.txt' ? { credits: bytes.toString('utf8') } : {}) };
  }));
  return { id, files };
}));
await writeFile(resolve(root, 'godot/data/portraits.json'), JSON.stringify({ repository: source.repository, commit: source.commit, license: 'licenses/SpriteCollab-CC-BY-NC-4.0.md', records }, null, 2) + '\n');
console.log(`Imported ${records.length} original-size portraits and their individual credits from ${source.commit}.`);
