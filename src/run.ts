import './run.css';
import { validateCatalog } from './data/catalog.ts';
import type { PokemonSpecies } from './data/catalog.ts';
import { runMap } from './data/run-maps.ts';
import { RunStore } from './data/run-store.ts';
import type { SaveRead } from './data/run-store.ts';
import { pokemonFor } from './domain/Pokemon.ts';
import { createRun, availableNodes, enterEncounter, completeEncounter, withBattle, ROUTE_LENGTH } from './rules/run.ts';
import type { Run } from './rules/run.ts';
import { mountBattle } from './battle';

const app = document.querySelector<HTMLDivElement>('#app')!;
const asset = (path: string) => `${import.meta.env.BASE_URL}${path}`;
const escape = (value: string) => value.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
const $ = <T extends HTMLElement = HTMLElement>(selector: string): T => app.querySelector<T>(selector)!;
let catalog: PokemonSpecies[], store: RunStore, saved: SaveRead, run: Run | null = null;
let disposeView: (() => void) | null = null;
let saveUnavailable = false;
const notice = document.createElement('div');
notice.id = 'save-notice';
notice.setAttribute('role', 'status');
notice.hidden = true;
app.before(notice);
function cleanup(): void { disposeView?.(); disposeView = null; }
function warning(): void {
  notice.hidden = !saveUnavailable;
  notice.innerHTML = saveUnavailable ? 'Guardado local no disponible. Puedes seguir jugando, pero recargar perderá el progreso nuevo. <button id="retry-save">Reintentar guardado</button>' : '';
  notice.querySelector('button')?.addEventListener('click', () => { if (run) persist(run); });
}
function conflict(): void {
  cleanup();
  app.innerHTML = `<main class="run-main run-error"><h1>La partida cambió en otra pestaña</h1><p>Abre el guardado más reciente para continuar desde él.</p><button class="run-primary" id="reload-save">Cargar último guardado</button></main>`;
  $('#reload-save').addEventListener('click', () => location.reload());
  $('#reload-save').focus();
}
function persist(next: Run): boolean {
  const result = store.write(next);
  if (result === 'conflict') { conflict(); return false; }
  run = next;
  saveUnavailable = result === 'unavailable';
  warning();
  return true;
}
const species = (id: number) => catalog.find(species => species.id === id)!;
const maximum = (speciesId: number): number => pokemonFor(speciesId).createCombatant(species(speciesId), 'ally', { x: 0, y: 0 }).maxHp;
const portrait = (id: number, size = 40) => `<img src="${asset(`assets/pokemon/${id}/thumbnail.png`)}" alt="" width="${size}" height="${size}">`;
function party(): string {
  return `<section class="run-party" aria-labelledby="party-title"><h2 id="party-title">Tu equipo</h2><ul>${run!.roster.map(member => {
    const max = maximum(member.speciesId);
    return `<li data-member="${member.id}" data-hp="${member.hp}" class="${member.hp === 0 ? 'lost' : ''}">${portrait(member.speciesId, 64)}<div><h3>${escape(species(member.speciesId).name)}</h3><p>${member.hp > 0 ? `${member.hp}/${max} PS` : 'Perdido en esta partida'}</p><div class="run-health" aria-hidden="true"><i style="width:${member.hp / max * 100}%"></i></div><small>${pokemonFor(member.speciesId).role}</small></div></li>`;
  }).join('')}</ul><p>Los PS se conservan. Una baja es definitiva durante esta partida.</p><p>Estados y PT se restablecen al entrar en otro combate.</p><details><summary>Reglas de esta prueba</summary><p>Seis encuentros. Sin tiendas, objetos de curación ni reclutamiento todavía. Los movimientos y el daño conservan los valores del sprint 4.</p></details></section>`;
}
function frame(title: string, content: string, subtitle: string): void {
  cleanup();
  app.innerHTML = `<main class="run-main"><header class="run-topbar"><a class="run-brand" href="${import.meta.env.BASE_URL}">POKÉMON <span>TACTICS</span></a><span>Prototipo local · 0.5</span><button id="run-menu">Menú</button></header><div class="run-heading"><div><h1 tabindex="-1">${title}</h1><p>${subtitle}</p></div>${run ? `<span class="run-seed">Semilla <strong>${escape(run.seed)}</strong> · ±${run.variance * 100} %</span>` : ''}</div>${content}<footer class="run-footer"><span>Proyecto de fans · sin afiliación oficial</span><a href="?view=battle">Combate de ensayo</a><a href="${asset('CREDITS.md')}" target="_blank" rel="noreferrer">Créditos</a></footer></main>`;
  $('#run-menu').addEventListener('click', menu);
  $('h1').focus({ preventScroll: true });
}
function menu(): void {
  cleanup();
  const current = run ?? (saved.kind === 'valid' ? saved.run : null);
  const broken = saved.kind === 'invalid' || saved.kind === 'incompatible';
  const survivors = current?.battle ? current.battle.units.filter(unit => unit.team === 'ally' && unit.hp > 0).length : current?.roster.filter(member => member.hp > 0).length;
  app.innerHTML = `<main class="run-main run-menu"><header class="run-topbar"><a class="run-brand" href="${import.meta.env.BASE_URL}">POKÉMON <span>TACTICS</span></a><span>Prototipo local · sprint 5</span></header><section class="run-intro"><h1>Elige tu camino.<br><span>Cuida a tu equipo.</span></h1><p>Una ruta táctica por las canteras de Kanto. Tres compañeros al azar, seis encuentros y cada baja cuenta.</p><div class="starter-pool" aria-label="Seis especies disponibles">${catalog.map(p => `<span>${portrait(p.id, 56)}${escape(p.name)}</span>`).join('')}</div><p class="pool-caption">Pool inicial de prueba · sin legendarios</p></section><section class="run-launch" aria-label="Comenzar o continuar">${current ? `<div class="continue-run"><h2>${current.status === 'victory' || current.status === 'defeat' ? 'Partida terminada' : 'Tu partida'}</h2><p>${current.path.length}/${ROUTE_LENGTH} encuentros superados · ${survivors}/3 compañeros en pie</p><p>Semilla ${escape(current.seed)}</p><button class="run-primary" id="continue-run">${current.status === 'combat' ? 'Continuar combate' : current.status === 'route' ? 'Continuar ruta' : 'Ver resultado'}</button></div>` : ''}${broken ? `<div class="save-problem" role="alert"><h2>${saved.kind === 'incompatible' ? 'Guardado de otra versión' : 'No se pudo leer el guardado'}</h2><p>Se conserva en este navegador. Para iniciar una nueva partida, descártalo explícitamente.</p><button id="discard-save">Descartar guardado</button></div>` : ''}<form id="new-run"><h2>${current ? 'Otra partida' : 'Nueva partida'}</h2><label for="run-seed">Semilla <span>(opcional)</span></label><input id="run-seed" maxlength="64" placeholder="Se generará al empezar" autocomplete="off"><label for="run-variance">Variación de iniciativa</label><select id="run-variance"><option value="0.05">±5 %</option><option value="0.1">±10 %</option></select><p>La misma semilla reproduce equipo, ruta y tiradas.</p><button class="${current ? '' : 'run-primary'}" type="submit" ${broken ? 'disabled' : ''}>${current ? 'Preparar nueva partida' : 'Empezar partida'}</button><div id="replace-save" hidden><p>Esto reemplazará tu partida actual y su progreso.</p><button type="button" id="confirm-new">Reemplazar y empezar</button><button type="button" id="cancel-new">Conservar partida</button></div></form><p class="run-scope">Final provisional de prueba. Tiendas, objetos y jefes legendarios llegarán en sus próximos sprints.</p></section><footer class="run-footer"><span>Proyecto de fans · sin afiliación oficial</span><a href="?view=battle">Combate de ensayo</a><a href="${asset('CREDITS.md')}" target="_blank" rel="noreferrer">Créditos</a></footer></main>`;
  $('#continue-run')?.addEventListener('click', () => { run = current; show(); });
  $('#discard-save')?.addEventListener('click', () => {
    const result = store.discard();
    if (result === 'conflict') { conflict(); return; }
    if (result === 'unavailable') { saveUnavailable = true; warning(); return; }
    saved = { kind: 'empty' }; menu();
  });
  const start = () => {
    const seed = $<HTMLInputElement>('#run-seed').value || `kanto-${crypto.getRandomValues(new Uint32Array(1))[0].toString(16)}`;
    const next = createRun(catalog, seed, Number($<HTMLSelectElement>('#run-variance').value));
    if (persist(next)) { saved = { kind: 'valid', run: next }; show(); }
  };
  $('#new-run').addEventListener('submit', event => {
    event.preventDefault();
    if (broken) return;
    if (current) { $('#replace-save').hidden = false; $('#confirm-new').focus(); }
    else start();
  });
  $('#confirm-new').addEventListener('click', start);
  $('#cancel-new').addEventListener('click', () => { $('#replace-save').hidden = true; $('#new-run button[type="submit"]').focus(); });
}
function route(): void {
  const current = run!, choices = new Set(availableNodes(current).map(node => node.id));
  const layers = Array.from({ length: ROUTE_LENGTH }, (_, i) => current.nodes.filter(node => node.floor === i + 1));
  const map = `<section class="route-stage" aria-labelledby="route-title"><h2 id="route-title">Ruta de roca</h2><p id="route-help">Elige el próximo encuentro conectado. El final de arriba cierra esta prueba.</p><div class="route-map"><svg id="route-lines" aria-hidden="true"></svg>${layers.map((nodes, index) => `<div class="route-layer"><span class="route-floor">${index + 1}</span>${nodes.map(node => {
    const cleared = current.path.includes(node.id), available = choices.has(node.id), skipped = node.floor <= current.path.length && !cleared;
    const map = runMap(node.mapId), label = node.floor === ROUTE_LENGTH ? 'Final de prueba' : map.name;
    const state = cleared ? 'Superado' : available ? 'Disponible' : skipped ? 'Ruta descartada' : 'Pendiente';
    return `<button class="route-node ${cleared ? 'cleared' : available ? 'available' : skipped ? 'skipped' : ''}" data-node="${node.id}" ${available ? '' : 'disabled'} aria-describedby="route-help" aria-label="Tramo ${node.floor}, ${label}, ${state}; enemigos ${escape(node.enemies.map(id => species(id).name).join(', '))}"><strong>${label}</strong><span class="node-enemies">${node.enemies.map(id => portrait(id, 32)).join('')}</span><small>${state}</small><span class="node-terrain">${map.description}</span></button>`;
  }).join('')}</div>`).join('')}</div><p class="route-progress">${current.path.length}/${ROUTE_LENGTH} encuentros superados</p></section>`;
  frame('Tu próxima batalla', `<div class="run-layout">${party()}${map}</div>`, 'No hay curación entre salas en esta prueba. Elige terreno y rivales con tu equipo en mente.');
  app.querySelectorAll<HTMLButtonElement>('[data-node]').forEach(button => button.addEventListener('click', () => {
    if (persist(enterEncounter(current, button.dataset.node!, catalog))) show();
  }));
  const draw = () => {
    const area = $('.route-map'), rect = area.getBoundingClientRect(), svg = $('#route-lines');
    svg.setAttribute('viewBox', `0 0 ${rect.width} ${rect.height}`);
    svg.innerHTML = current.nodes.flatMap(node => node.next.map(id => {
      const from = $(`[data-node="${node.id}"]`).getBoundingClientRect(), to = $(`[data-node="${id}"]`).getBoundingClientRect();
      const visited = current.path.includes(node.id) && current.path.includes(id);
      return `<line x1="${from.left + from.width / 2 - rect.left}" y1="${from.top - rect.top}" x2="${to.left + to.width / 2 - rect.left}" y2="${to.bottom - rect.top}" class="${visited ? 'visited' : ''}"/>`;
    })).join('');
  };
  const observer = new ResizeObserver(draw);
  observer.observe($('.route-map'));
  draw();
  disposeView = () => observer.disconnect();
}
function result(): void {
  const current = run!, won = current.status === 'victory';
  const survivors = current.roster.filter(member => member.hp > 0).length;
  frame(won ? 'Ruta superada' : 'El equipo ha caído', `<div class="run-layout">${party()}<section class="run-ending"><h2>${won ? 'Has llegado al final de la prueba' : 'Cada elección deja huella'}</h2><p>${won ? 'Este encuentro cierra el prototipo de ruta. Los finales con legendarios se incorporarán después.' : 'Los compañeros perdidos no pueden volver durante esta partida. Puedes empezar otra con una nueva semilla.'}</p><table><caption>Recorrido de la partida</caption><thead><tr><th>Tramo</th><th>Escenario</th><th>Rondas</th><th>Resultado</th></tr></thead><tbody>${current.history.map(record => `<tr><td>${record.nodeId.split('-')[0]}</td><td>${runMap(current.nodes.find(node => node.id === record.nodeId)!.mapId).name}</td><td>${record.round}</td><td>${record.outcome === 'victory' ? 'Victoria' : 'Derrota'}</td></tr>`).join('')}</tbody></table><button class="run-primary" id="result-menu">Volver al menú</button></section></div>`, `${current.path.length}/${ROUTE_LENGTH} encuentros superados · ${survivors}/3 compañeros en pie`);
  $('#result-menu').addEventListener('click', menu);
}
function show(): void {
  if (!run) { menu(); return; }
  if (run.status === 'route') { route(); return; }
  if (run.status !== 'combat') { result(); return; }
  cleanup();
  const node = run.nodes.find(node => node.id === run!.currentNodeId)!;
  disposeView = mountBattle(catalog, {
    initial: run.battle!, title: `TRAMO ${node.floor}/${ROUTE_LENGTH} · ${node.floor === ROUTE_LENGTH ? 'FINAL DE PRUEBA' : runMap(node.mapId).name.toUpperCase()}`,
    onState: state => persist(withBattle(run!, state)),
    onExit: menu,
    onComplete: () => { if (persist(completeEncounter(run!))) show(); },
  });
}
async function boot(): Promise<void> {
  app.innerHTML = '<main class="run-main"><p role="status">Cargando la ruta…</p></main>';
  try {
    const response = await fetch(asset('data/pokemon.json'), { signal: AbortSignal.timeout(10000) });
    if (!response.ok) throw new Error('No se pudo cargar el catálogo local.');
    catalog = validateCatalog(await response.json());
    await document.fonts.load('16px "Pixelify Sans"');
    let storage: Storage | null;
    try { storage = localStorage; } catch { storage = null; }
    store = new RunStore(storage, catalog);
    saved = store.read();
    saveUnavailable = saved.kind === 'unavailable';
    warning();
    menu();
  } catch (error) {
    app.innerHTML = `<main class="run-main run-error"><h1>No pudimos abrir la ruta</h1><p>${escape(error instanceof Error ? error.message : 'Error de recursos locales.')}</p><button id="retry" class="run-primary">Volver a intentar</button></main>`;
    $('#retry').addEventListener('click', () => location.reload());
  }
}
import.meta.hot?.dispose(() => { cleanup(); notice.remove(); });
void boot();
