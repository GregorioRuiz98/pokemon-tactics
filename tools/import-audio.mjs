// Explicit resource maintenance. Generated WAVs are local; no library/network needed while playing.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
const commit='b7b6aa27d62f8f356db267276bf54b451555c49d';
const root=new URL('../',import.meta.url),vendor=new URL('tools/vendor/jsfxr/',root);
mkdirSync(vendor,{recursive:true});mkdirSync(new URL('public/assets/audio/',root),{recursive:true});
const files=[];
for(const file of ['sfxr.js','riffwave.js','UNLICENSE']) {
  const source=`https://raw.githubusercontent.com/chr15m/jsfxr/${commit}/${file}`,response=await fetch(source);
  if(!response.ok)throw new Error(source+': '+response.status);
  const data=Buffer.from(await response.arrayBuffer());writeFileSync(new URL(file,vendor),data);
  files.push({file,source,sha256:createHash('sha256').update(data).digest('hex')});
}
writeFileSync(new URL('package.json',vendor),'\u007b"type":"commonjs"\u007d\n');
writeFileSync(new URL('sources.json',vendor),JSON.stringify({repository:'https://github.com/chr15m/jsfxr',commit,license:'Unlicense',files},null,2)+'\n');
writeFileSync(new URL('public/licenses/jsfxr-UNLICENSE.txt',root),readFileSync(new URL('UNLICENSE',vendor)));
const {sfxr}=createRequire(import.meta.url)('./vendor/jsfxr/sfxr.js');
const manifest=JSON.parse(readFileSync(new URL('public/data/provenance.json',root),'utf8'));
manifest.files=manifest.files.filter(file=>!file.path.startsWith('public/assets/audio/'));
let seed=7441;const originalRandom=Math.random;Math.random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
try {
  for(const [name,preset] of [['select','blipSelect'],['hit','hitHurt'],['victory','powerUp']]) {
    const sound=sfxr.generate(preset);sound.sound_vol=.16;
    const data=Buffer.from(sfxr.toWave(sound).dataURI.split(',')[1],'base64'),path=`public/assets/audio/${name}.wav`;
    writeFileSync(new URL(path,root),data);manifest.files.push({path,source:`https://github.com/chr15m/jsfxr/tree/${commit}`,license:'Unlicense',authors:['Eric Fredricksen','Chris McCormick','Dr. Petter','Pedro Ladaria'],modification:`Seeded ${preset} preset; volume 0.16; WAV generated locally`,sha256:createHash('sha256').update(data).digest('hex')});
  }
} finally {Math.random=originalRandom;}
writeFileSync(new URL('public/data/provenance.json',root),JSON.stringify(manifest,null,2)+'\n');
console.log('Three local WAV effects generated with pinned jsfxr (Unlicense).');
