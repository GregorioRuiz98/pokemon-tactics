import './style.css';
import { INITIAL_SPECIES, STAT_KEYS, STAT_NAMES, TYPE_NAMES, validateCatalog } from './data/catalog';
import type { AnimationName, PokemonSpecies } from './data/catalog';
import { ROLES } from './rules/design';
import { CampScene } from './game/CampScene';
import { startGame } from './game/main';

const app = document.querySelector<HTMLDivElement>('#app')!;
document.title = 'Campamento de Kanto · Pokémon Tactics';
const assetUrl = (path: string) => `${import.meta.env.BASE_URL}${path}`;
const escape = (value: string) => value.replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]!);

async function loadCatalog(): Promise<PokemonSpecies[]> {
  const response = await fetch(assetUrl('data/pokemon.json'), { signal: AbortSignal.timeout(10000) });
  if (!response.ok) throw new Error(`No se pudo cargar el catálogo (${response.status}).`);
  return validateCatalog(await response.json());
}

function showFailure(message: string): void {
  app.innerHTML = `<main class="failure"><span class="eyebrow">POKÉMON TACTICS</span><h1>No pudimos abrir el campamento</h1><p>${escape(message)}</p><button id="retry">Volver a intentar</button></main>`;
  document.querySelector('#retry')?.addEventListener('click', () => location.reload());
}

function render(catalog: PokemonSpecies[]): void {
  let selected = catalog[0].id;
  let animation: AnimationName = 'Idle';
  let direction = 0;
  const motionPreference = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = motionPreference.matches;

  app.innerHTML = `
    <header class="topbar">
      <a class="brand" href="./" aria-label="Pokémon Tactics, inicio"><span class="brand-symbol" aria-hidden="true">✦</span><span>POKÉMON <strong>TACTICS</strong></span></a>
      <span class="build-label">PROTOTIPO LOCAL <span>00</span></span>
      <button class="quiet" id="open-credits">Créditos <span aria-hidden="true">↗</span></button>
    </header>
    <main>
      <section class="intro" aria-labelledby="camp-title">
        <div><p class="eyebrow">CUADERNO DE EXPEDICIÓN / 001</p><h1 id="camp-title">Campamento de Kanto<span>.</span></h1><p class="lede">Conoce a tus futuros compañeros.</p></div>
        <div class="camp-counter"><strong>06</strong><span>ESPECIES<br>POR DESCUBRIR</span></div>
      </section>
      <div class="camp-layout">
        <section class="stage-panel" aria-label="Campamento">
          <div class="panel-bar"><span><i aria-hidden="true"></i> ZONA DE REUNIÓN</span><span>VISTA DE ESPECIES</span></div>
          <div class="stage-wrap">
            <div id="game-container" role="img" aria-label="Seis Pokémon reunidos. Usa los botones de compañeros para seleccionarlos."></div>
            <div id="load-status" role="status">Preparando el campamento…</div>
          </div>
          <div class="stage-note"><span>Selecciona un compañero para conocerlo</span><span aria-hidden="true">↙ 01 — 06</span></div>
        </section>
        <aside class="dossier" aria-label="Ficha del Pokémon seleccionado">
          <p class="eyebrow">FICHA DE COMPAÑERO <span id="dex-number"></span></p>
          <div id="species-heading" aria-live="polite"></div>
          <div id="species-types" class="type-list"></div>
          <div class="role-block"><span class="tiny-label">ROL PROPUESTO</span><h3 id="role-name"></h3><p id="role-description"></p></div>
          <div class="stats-heading"><span class="tiny-label">ESTADÍSTICAS BASE</span><span>KANTO MODERNO</span></div>
          <dl id="stats" class="stats"></dl>
          <p class="dossier-foot">Las habilidades llegarán en próximos sprints.</p>
        </aside>
      </div>
      <section class="companions" aria-labelledby="companions-title">
        <div class="section-label"><h2 id="companions-title">Compañeros</h2><span>ELIGE UNA ESPECIE</span></div>
        <div class="roster">${catalog.map(p => `<button class="companion" data-species="${p.id}" aria-pressed="false"><span class="roster-number">${String(p.id).padStart(3,'0')}</span><img src="${assetUrl(`assets/pokemon/${p.id}/thumbnail.png`)}" alt="" width="64" height="64"><span class="companion-name">${escape(p.name)}</span><span class="companion-role">${escape(ROLES[p.id].name)}</span><span class="selection-mark" aria-hidden="true">↗</span></button>`).join('')}</div>
      </section>
      <section class="preview-controls" aria-label="Vista de animaciones">
        <div class="control-group"><span class="tiny-label">ANIMACIÓN</span><div class="segmented"><button data-animation="Idle" aria-pressed="true">Reposo</button><button data-animation="Walk" aria-pressed="false">Paso</button></div></div>
        <div class="control-group"><span class="tiny-label">ORIENTACIÓN</span><div class="segmented compass">${[[4,'N','Norte'],[2,'E','Este'],[0,'S','Sur'],[6,'O','Oeste']].map(([row,label,name]) => `<button data-direction="${row}" aria-label="Mirar al ${name}" aria-pressed="${row===0}">${label}</button>`).join('')}</div></div>
        <button class="quiet pause-control" id="pause" aria-pressed="${paused}">${paused ? 'Reanudar animaciones' : 'Pausar animaciones'}</button>
      </section>
    </main>
    <footer><span>Proyecto fan · Prototipo en desarrollo</span><span>SPRINT 00 <span aria-hidden="true">/</span> Preparación y recursos</span></footer>
    <dialog id="credits-dialog" aria-labelledby="credits-title"><div class="dialog-header"><span class="eyebrow">HECHO CON RECURSOS DE LA COMUNIDAD</span><button class="quiet" id="close-credits" aria-label="Cerrar créditos">Cerrar ×</button></div><h2 id="credits-title">Créditos y procedencia</h2><p>Este campamento reutiliza recursos públicos y conserva sus atribuciones.</p><h3>Sprites</h3><p><a href="https://github.com/PMDCollab/SpriteCollab" target="_blank" rel="noreferrer">SpriteCollab</a> · CC BY-NC 4.0. Las miniaturas se han recortado del primer fotograma; las hojas originales no se han modificado.</p><ul>${catalog.map(p=>`<li><strong>${escape(p.name)}</strong>: ${p.authors.map(escape).join(', ')}</li>`).join('')}</ul><h3>Código, datos y tipografía</h3><ul><li>Phaser y plantilla Vite/TypeScript · MIT.</li><li>Utilidades de importación de JPTER78 / PokéSurvivor · MIT.</li><li>Datos de especies y estadísticas: PokéAPI, guardados localmente.</li><li>Pixelify Sans · SIL Open Font License 1.1.</li></ul><p><a href="${assetUrl('data/provenance.json')}" target="_blank">Ver manifiesto de procedencia</a> · <a href="${assetUrl('CREDITS.md')}" target="_blank">Créditos completos y licencias</a></p><h3>Proyecto independiente</h3><p>Pokémon pertenece a sus respectivos titulares. Este proyecto fan no está afiliado ni aprobado por Nintendo, Creatures, GAME FREAK o The Pokémon Company.</p><h3>Privacidad local</h3><p>Esta versión no tiene cuentas, analítica ni guardado de partidas. Los recursos del campamento se cargan desde el mismo servidor local.</p></dialog>`;

  const scene = new CampScene(catalog, {
    select,
    progress: fraction => { document.querySelector('#load-status')!.textContent = `Preparando el campamento… ${Math.round(fraction*100)} %`; },
    ready: missing => {
      const status = document.querySelector<HTMLDivElement>('#load-status')!;
      if (missing.length) {
        status.className = 'partial-status';
        status.replaceChildren(document.createTextNode('Algunas animaciones no están disponibles. '));
        const retry = document.createElement('button');
        retry.textContent = 'Volver a cargar';
        retry.addEventListener('click', () => location.reload());
        status.append(retry);
      } else status.hidden = true;
      document.querySelectorAll<HTMLButtonElement>('.preview-controls button').forEach(button => button.disabled = false);
    },
  });

  function syncScene(): void { scene.configure(selected, animation, direction, paused); }
  function select(id: number): void {
    const pokemon = catalog.find(p => p.id === id);
    if (!pokemon) return;
    selected = id;
    document.querySelector('#dex-number')!.textContent = `N.º ${String(id).padStart(3,'0')}`;
    document.querySelector('#species-heading')!.innerHTML = `<h2>${escape(pokemon.name)}</h2>`;
    document.querySelector('#species-types')!.innerHTML = pokemon.types.map(type => `<span class="type type-${type}">${TYPE_NAMES[type]}</span>`).join('');
    document.querySelector('#role-name')!.textContent = ROLES[id].name;
    document.querySelector('#role-description')!.textContent = ROLES[id].description;
    document.querySelector('#stats')!.innerHTML = STAT_KEYS.map(key => `<div class="stat"><dt>${STAT_NAMES[key]}</dt><dd><span class="stat-track" aria-hidden="true"><span style="width:${Math.min(100, pokemon.baseStats[key]/1.5)}%"></span></span><strong>${pokemon.baseStats[key]}</strong></dd></div>`).join('');
    document.querySelectorAll<HTMLButtonElement>('[data-species]').forEach(button => button.setAttribute('aria-pressed', String(Number(button.dataset.species)===id)));
    syncScene();
  }
  const rosterButtons = [...document.querySelectorAll<HTMLButtonElement>('[data-species]')];
  rosterButtons.forEach((button,index) => {
    button.addEventListener('click', () => select(Number(button.dataset.species)));
    button.addEventListener('keydown', event => {
      if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
      event.preventDefault();
      const next = rosterButtons[(index + (event.key==='ArrowRight' ? 1 : -1) + rosterButtons.length)%rosterButtons.length];
      next.focus(); next.click();
    });
  });
  document.querySelectorAll<HTMLButtonElement>('[data-animation]').forEach(button => button.addEventListener('click', () => {
    animation = button.dataset.animation as AnimationName;
    document.querySelectorAll<HTMLButtonElement>('[data-animation]').forEach(b => b.setAttribute('aria-pressed', String(b===button)));
    syncScene();
  }));
  document.querySelectorAll<HTMLButtonElement>('[data-direction]').forEach(button => button.addEventListener('click', () => {
    direction = Number(button.dataset.direction);
    document.querySelectorAll<HTMLButtonElement>('[data-direction]').forEach(b => b.setAttribute('aria-pressed', String(b===button)));
    syncScene();
  }));
  const pause = document.querySelector<HTMLButtonElement>('#pause')!;
  function updatePause(): void {
    pause.setAttribute('aria-pressed', String(paused));
    pause.textContent = paused ? 'Reanudar animaciones' : 'Pausar animaciones';
    syncScene();
  }
  pause.addEventListener('click', () => { paused = !paused; updatePause(); });
  motionPreference.addEventListener('change', event => { paused = event.matches; updatePause(); });
  const dialog = document.querySelector<HTMLDialogElement>('#credits-dialog')!;
  document.querySelector('#open-credits')!.addEventListener('click', () => dialog.showModal());
  document.querySelector('#close-credits')!.addEventListener('click', () => dialog.close());
  document.querySelectorAll<HTMLImageElement>('.companion img').forEach(img => img.addEventListener('error', () => { img.hidden = true; }));
  document.querySelectorAll<HTMLButtonElement>('.preview-controls button').forEach(button => button.disabled = true);
  select(selected);
  const game = startGame(scene);
  import.meta.hot?.dispose(() => game.destroy(true));
}

async function boot(): Promise<void> {
  try {
    const catalog = await loadCatalog();
    await document.fonts.load('16px "Pixelify Sans"');
    render(catalog.filter(species=>(INITIAL_SPECIES as readonly number[]).includes(species.id)));
  } catch (error) {
    showFailure(error instanceof Error ? error.message : 'No se pudieron leer los recursos locales.');
  }
}
void boot();
