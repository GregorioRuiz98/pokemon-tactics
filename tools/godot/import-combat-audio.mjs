// Offline sound design using the already pinned, Unlicense jsfxr synthesizer.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
const { sfxr } = createRequire(import.meta.url)('../vendor/jsfxr/sfxr.js');
const root = new URL('../../', import.meta.url);
const destination = new URL('godot/assets/combat/', root);
mkdirSync(destination, { recursive: true });
// wave, frequency, slide, sustain, decay, vibrato. All timings stay short.
const recipes = {
  normal:[3,.25,-.25,.08,.13,0], fighting:[3,.18,-.4,.12,.18,0],
  fire:[3,.32,-.18,.22,.3,0], water:[2,.32,-.28,.22,.3,.22],
  electric:[0,.5,-.1,.14,.19,.7], grass:[3,.48,.2,.12,.22,0],
  ice:[2,.7,-.06,.12,.32,.1], rock:[3,.12,-.2,.15,.2,0],
  ground:[3,.08,-.12,.22,.28,0], flying:[3,.52,-.32,.12,.25,0],
  poison:[2,.18,.1,.2,.28,.5], psychic:[2,.36,.22,.2,.32,.6],
  ghost:[2,.13,-.08,.24,.32,.65], dark:[1,.16,-.25,.13,.22,.2],
  bug:[0,.32,.2,.08,.18,.6], dragon:[1,.22,.16,.2,.3,.25],
  steel:[2,.6,-.35,.09,.25,.3], fairy:[2,.55,.18,.13,.32,.3],
  heal:[2,.32,.25,.2,.36,.15], buff:[0,.25,.3,.1,.28,.1],
  debuff:[2,.35,-.3,.13,.27,.2], impact:[3,.16,-.4,.06,.14,0],
  critical:[1,.32,-.28,.07,.22,.12], miss:[3,.5,.3,.05,.17,0],
  immune:[2,.16,-.2,.1,.23,.05], guard:[2,.45,-.05,.08,.3,.1],
};
const files=[];
let seed=2217;
const originalRandom=Math.random;
Math.random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0; return seed/4294967296;};
try {
  for (const [name, values] of Object.entries(recipes)) {
    const parameters=sfxr.generate('blipSelect');
    Object.assign(parameters, {wave_type:values[0],p_base_freq:values[1],p_freq_ramp:values[2],p_env_attack:.015,p_env_sustain:values[3],p_env_decay:values[4],p_vib_strength:values[5],p_vib_speed:.4,p_env_punch:.12,sound_vol:.22,sample_size:16,sample_rate:44100});
    let bytes=Buffer.from(sfxr.toWave(parameters).dataURI.split(',')[1],'base64');
    if(bytes.readUInt16LE(34)!==16 || bytes.toString('ascii',36,40)!=='data') throw new Error('Unexpected WAV format');
    const samples=bytes.readUInt32LE(40)/2;
    let peak=1;
    for(let i=0;i<samples;i++) peak=Math.max(peak,Math.abs(bytes.readInt16LE(44+i*2)));
    for(let i=0;i<samples;i++) {
      const fade=Math.min(1,i/88,(samples-1-i)/353);
      bytes.writeInt16LE(Math.round(bytes.readInt16LE(44+i*2)/peak*6553*fade),44+i*2);
    }
    if(bytes.length%2){bytes=Buffer.concat([bytes,Buffer.from([0])]);bytes.writeUInt32LE(bytes.length-8,4);}
    writeFileSync(new URL(name+'.wav',destination),bytes);
    files.push({id:name,path:'res://assets/combat/'+name+'.wav',sha256:createHash('sha256').update(bytes).digest('hex'),parameters,mastering:'Peak ceiling 0.2; 2ms attack and 8ms release fade; PCM16 mono 44100Hz'});
  }
} finally {Math.random=originalRandom;}
writeFileSync(new URL('manifest.json',destination),JSON.stringify({version:1,seed:2217,generator:'tools/godot/import-combat-audio.mjs',source:JSON.parse(readFileSync(new URL('tools/vendor/jsfxr/sources.json',root),'utf8')),license:'Unlicense',files},null,2)+'\n');
console.log(`Generated ${files.length} deterministic attack cues offline.`);
