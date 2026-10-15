type Sound = 'select' | 'hit' | 'victory';
const KEY = 'pokemon-tactics.volume';
let volume = .25;
try { const value = localStorage.getItem(KEY); if (value !== null && Number.isFinite(Number(value))) volume = Math.max(0,Math.min(1,Number(value))); } catch { /* Sound remains available without storage. */ }
const sounds = new Map<Sound,HTMLAudioElement>();
export function playSound(name: Sound): void {
  if (!volume) return;
  const sound=sounds.get(name)??new Audio(`${import.meta.env.BASE_URL}assets/audio/${name}.wav`);
  sounds.set(name,sound);sound.volume=volume;sound.currentTime=0;
  void sound.play().catch(()=>{ /* Autoplay can be blocked until the first gesture. */ });
}
export const soundControls = (): string => `<label class="sound-control" for="game-volume">Sonido <output id="volume-value">${Math.round(volume*100)} %</output><input id="game-volume" type="range" min="0" max="100" step="5" value="${Math.round(volume*100)}" aria-describedby="volume-help"></label><small id="volume-help">0 % silencia los efectos.</small>`;
export function bindSound(root: HTMLElement): void {
  root.querySelector<HTMLInputElement>('#game-volume')?.addEventListener('input',event=>{
    volume=Number((event.target as HTMLInputElement).value)/100;
    root.querySelector<HTMLOutputElement>('#volume-value')!.value=`${Math.round(volume*100)} %`;
    sounds.forEach(sound=>{sound.volume=volume;});
    try {localStorage.setItem(KEY,String(volume));} catch { /* Preference stays in memory. */ }
  });
  root.querySelector('#game-volume')?.addEventListener('change',()=>playSound('select'));
}
