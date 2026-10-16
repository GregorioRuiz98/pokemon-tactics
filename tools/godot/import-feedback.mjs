// Deterministic offline generator using the project's existing pinned jsfxr.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
const {sfxr}=createRequire(import.meta.url)('../vendor/jsfxr/sfxr.js');
const root=new URL('../../',import.meta.url),files=[];
let seed=16514;const previous=Math.random;
Math.random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
try {
 for(const [name,preset] of [['miss','jump'],['immune','blipSelect'],['level-up','powerUp']]) {
  const sound=sfxr.generate(preset);sound.sound_vol=.16;
  if(name==='miss'){sound.wave_type=3;sound.p_env_sustain=.08;sound.p_env_decay=.16;}
  if(name==='immune'){sound.p_base_freq=.18;sound.p_freq_ramp=-.2;}
  let bytes=Buffer.from(sfxr.toWave(sound).dataURI.split(',')[1],'base64');
  if(bytes.length%2){bytes=Buffer.concat([bytes,Buffer.from([0])]);bytes.writeUInt32LE(bytes.length-8,4);}
  const target='assets/audio/'+name+'.wav';writeFileSync(new URL('godot/'+target,root),bytes);
  files.push({target,source:'tools/vendor/jsfxr/sfxr.js',preset,seed:16514,sha256:createHash('sha256').update(bytes).digest('hex'),license:'Unlicense',modification:'Deterministic native WAV; PCM volume 0.16; RIFF padding corrected'});
 }
} finally {Math.random=previous;}
writeFileSync(new URL('godot/data/feedback-provenance.json',root),JSON.stringify({version:1,files},null,2)+'\n');
console.log('Generated miss, immune and level-up WAVs with existing jsfxr.');
