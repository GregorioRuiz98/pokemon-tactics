import { readFileSync, readdirSync, statSync } from 'node:fs';
import { resolve, relative, sep } from 'node:path';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
const dist=resolve(process.argv[2]||'dist');
const manifest=JSON.parse(readFileSync(resolve(dist,'release-manifest.json'),'utf8'));
const info=JSON.parse(readFileSync(resolve(dist,'release.json'),'utf8'));
assert.equal(info.version,manifest.version);assert.equal(info.saveSchema,3);assert.deepEqual(info.finales,['birds','psychic']);
const seen=new Set();
for(const entry of manifest.files) {
  const path=resolve(dist,entry.path),rel=relative(dist,path);
  assert(rel&&!rel.startsWith('..')&&!rel.startsWith(sep),'Invalid release path');assert(!seen.has(entry.path),'Duplicate file');seen.add(entry.path);
  const data=readFileSync(path);assert.equal(data.length,entry.bytes);assert.equal(createHash('sha256').update(data).digest('hex'),entry.sha256,entry.path);
}
const actual=[];
function visit(directory){for(const name of readdirSync(directory)){const file=resolve(directory,name);if(statSync(file).isDirectory())visit(file);else actual.push(relative(dist,file).split(sep).join('/'));}}
visit(dist);assert.deepEqual(actual.filter(path=>path!=='release-manifest.json').sort(),[...seen].sort());
for(const path of ['index.html','legal.html','privacy.html','CREDITS.md','data/pokemon.json','assets/audio/hit.wav','licenses/jsfxr-UNLICENSE.txt'])assert(seen.has(path),'Missing '+path);
const provenance=JSON.parse(readFileSync(resolve(dist,'data/provenance.json'),'utf8'));
for(const file of provenance.files.filter(file=>file.path.startsWith('public/')))assert.equal(createHash('sha256').update(readFileSync(resolve(dist,file.path.slice(7)))).digest('hex'),file.sha256,file.path);
console.log(`Verified release ${manifest.version}: ${seen.size} files, exact inventory and asset provenance.`);
