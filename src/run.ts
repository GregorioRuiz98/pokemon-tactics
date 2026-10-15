import './run.css';
import { INITIAL_SPECIES, validateCatalog } from './data/catalog.ts';
import type { PokemonSpecies } from './data/catalog.ts';
import { runMap } from './data/run-maps.ts';
import { RunStore } from './data/run-store.ts';
import type { SaveRead } from './data/run-store.ts';
import { levelFor } from './domain/progression.ts';
import { createRun, maximumHp, CURRENT_EDITION, routeLength, availableNodes, enterRoom, leaveService, completeEncounter, withBattle, completedCombats, currentNode, nodeStep, performRunEvent, TEAM_LIMIT, VICTORY_REWARD } from './rules/run.ts';
import type { Run, RunEvent } from './rules/run.ts';
import { itemFor } from './domain/items.ts';
import type { ItemId } from './domain/items.ts';
import { managementHtml, serviceHtml, bindManagement } from './run-management';
import { mountBattle } from './battle';

const app = document.querySelector<HTMLDivElement>('#app')!;
const asset = (path: string) => `${import.meta.env.BASE_URL}${path}`;
const escape = (value: string) => value.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
const $ = <T extends HTMLElement = HTMLElement>(selector: string): T => app.querySelector<T>(selector)!;
let catalog: PokemonSpecies[], store: RunStore, saved: SaveRead, run: Run | null = null;
let disposeView: (() => void) | null = null;
let saveUnavailable = false;
let selectedMemberId = 1, managing = false, pendingRecruitId: string | null = null;
let lastFeedback = '', migrationNotice = '';
let recruitFocusSelector = '';
const notice = document.createElement('div');
notice.id = 'save-notice';
notice.setAttribute('role', 'status');
notice.hidden = true;
app.before(notice);
function cleanup(): void { disposeView?.(); disposeView = null; }
function warning(): void {
  notice.hidden = !saveUnavailable;
  notice.innerHTML = saveUnavailable ? 'Guardado local no disponible. Puedes seguir jugando, pero recargar perderá el progreso nuevo. <button id="retry-save">Reintentar guardado</button>' : '';
  notice.querySelector('button')?.addEventListener('click', () => {
    if (run && persist(run) && !saveUnavailable && migrationNotice.includes('en memoria')) {
      migrationNotice = 'Partida actualizada al sprint 10A. Se conserva una copia del guardado anterior; PS y tiradas se mantienen.';
      const message = app.querySelector<HTMLElement>('.migration-notice');
      if (message) message.textContent = migrationNotice;
    }
  });
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
const maximum = (speciesId: number, xp = 0): number => maximumHp(catalog, speciesId, xp);
const portrait = (id: number, size = 40) => `<img src="${asset(`assets/pokemon/${id}/thumbnail.png`)}" alt="" width="${size}" height="${size}">`;
function party(): string {
  return `<section class="run-party" aria-labelledby="party-title"><h2 id="party-title">Tu equipo</h2><ul>${run!.roster.map(member => {
    const max = maximum(member.speciesId, member.xp);
    return `<li data-member="${member.id}" data-hp="${member.hp}" data-held="${member.heldItem ?? ''}">${portrait(member.speciesId, 48)}<div><h3>${escape(species(member.speciesId).name)} <small class="member-number">#${member.id}</small></h3><p>${member.hp}/${max} PS · Nv. ${levelFor(member.xp)} · ${member.xp} EXP</p><div class="run-health" aria-hidden="true"><i style="width:${member.hp / max * 100}%"></i></div><small>${member.heldItem ? itemFor(member.heldItem).name : 'Sin objeto equipado'}</small></div></li>`;
  }).join('')}</ul>${run!.roster.length === 0 ? '<p>No quedan compañeros en pie.</p>' : `<p>${run!.roster.length}/${TEAM_LIMIT} miembros · Todos los vivos se despliegan.</p>`}<p>PS persistentes. Los perdidos no reviven; su objeto vuelve a la bolsa.</p>${run!.departed.length ? `<details class="departed-members"><summary>Registro: ${run!.departed.filter(member => member.reason === 'fallen').length} bajas · ${run!.departed.filter(member => member.reason === 'released').length} liberados</summary><ul>${run!.departed.map(member => `<li data-departed="${member.id}" class="${member.reason === 'fallen' ? 'lost' : ''}">${portrait(member.speciesId, 32)}<span>${escape(species(member.speciesId).name)} #${member.id}<small>${member.reason === 'fallen' ? 'Perdido en esta partida' : 'Liberado al sustituirlo'}</small></span></li>`).join('')}</ul></details>` : ''}<details><summary>Reglas de esta prueba</summary><p>Una visita de servicios antes de cada zona y del final. Al entrar a combate se restablecen estados y PT. Daño y movimientos conservan los valores base actuales.</p></details></section>`;
}
function frame(title: string, content: string, subtitle: string): void {
  cleanup();
  app.innerHTML = `<main class="run-main"><header class="run-topbar"><a class="run-brand" href="${import.meta.env.BASE_URL}">POKÉMON <span>TACTICS</span></a><span>Prototipo local · 0.10</span>${run ? `<strong id="run-money">${run.money} monedas</strong>` : ''}<button id="run-menu">Menú</button></header><div class="run-heading"><div><h1 tabindex="-1">${title}</h1><p>${subtitle}</p></div>${run ? `<span class="run-seed">Semilla <strong>${escape(run.seed)}</strong> · ±${run.variance * 100} %</span>` : ''}</div><p id="management-feedback" class="management-feedback" role="status" aria-live="polite">${escape(lastFeedback)}</p>${content}<footer class="run-footer"><span>Proyecto de fans · sin afiliación oficial</span><a href="?view=battle">Combate de ensayo</a><a href="?view=battle&boss=birds">Ensayar aves</a><a href="?view=battle&boss=psychic">Ensayar laboratorio</a><a href="${asset('CREDITS.md')}" target="_blank" rel="noreferrer">Créditos</a></footer></main>`;
  $('#run-menu').addEventListener('click', menu);
  $('h1').focus({ preventScroll: true });
}
function menu(): void {
  cleanup();
  const current = run ?? (saved.kind === 'valid' ? saved.run : null);
  const broken = saved.kind === 'invalid' || saved.kind === 'incompatible';
  const survivors = current?.battle ? current.battle.units.filter(unit => unit.team === 'ally' && unit.hp > 0).length : current?.roster.filter(member => member.hp > 0).length;
  app.innerHTML = `<main class="run-main run-menu"><header class="run-topbar"><a class="run-brand" href="${import.meta.env.BASE_URL}">POKÉMON <span>TACTICS</span></a><span>Prototipo local · sprint 10A</span></header><section class="run-intro"><h1>Elige tu camino.<br><span>Cuida a tu equipo.</span></h1><p>Una ruta táctica por Kanto. Tres compañeros al azar, decisiones de equipo y dos destinos legendarios.</p><div class="starter-pool" aria-label="Seis especies disponibles">${catalog.filter(p => INITIAL_SPECIES.includes(p.id as typeof INITIAL_SPECIES[number])).map(p => `<span>${portrait(p.id, 56)}${escape(p.name)}</span>`).join('')}</div><p class="pool-caption">Pool inicial de prueba · sin legendarios</p></section><section class="run-launch" aria-label="Comenzar o continuar">${migrationNotice ? `<p class="migration-notice">${escape(migrationNotice)}</p>` : ''}${current ? `<div class="continue-run"><h2>${current.status === 'victory' || current.status === 'defeat' ? 'Partida terminada' : 'Tu partida'}</h2><p>${completedCombats(current)}/${routeLength(current)} encuentros superados · ${survivors}/6 compañeros en pie</p><p>Semilla ${escape(current.seed)}</p><button class="run-primary" id="continue-run">${current.status === 'combat' ? 'Continuar combate' : current.status === 'route' ? 'Continuar ruta' : current.status === 'service' ? 'Continuar visita' : 'Ver resultado'}</button></div>` : ''}${broken ? `<div class="save-problem" role="alert"><h2>${saved.kind === 'incompatible' ? 'Guardado de otra versión' : 'No se pudo leer el guardado'}</h2><p>Se conserva en este navegador. Para iniciar una nueva partida, descártalo explícitamente.</p><button id="discard-save">Descartar guardado</button></div>` : ''}<form id="new-run"><h2>${current ? 'Otra partida' : 'Nueva partida'}</h2><label for="run-seed">Semilla <span>(opcional)</span></label><input id="run-seed" maxlength="64" placeholder="Se generará al empezar" autocomplete="off"><label for="run-variance">Variación de iniciativa</label><select id="run-variance"><option value="0.05">±5 %</option><option value="0.1">±10 %</option></select><p>La misma semilla reproduce equipo, ruta y tiradas.</p><button class="${current ? '' : 'run-primary'}" type="submit" ${broken ? 'disabled' : ''}>${current ? 'Preparar nueva partida' : 'Empezar partida'}</button><div id="replace-save" hidden><p>Esto reemplazará tu partida actual y su progreso.</p><button type="button" id="confirm-new">Reemplazar y empezar</button><button type="button" id="cancel-new">Conservar partida</button></div></form><p class="run-scope">Tienda, reclutamiento, experiencia y evolución. Dos finales alternativos: las tres aves o Mew y Mewtwo.</p></section><footer class="run-footer"><span>Proyecto de fans · sin afiliación oficial</span><a href="?view=battle">Combate de ensayo</a><a href="${asset('CREDITS.md')}" target="_blank" rel="noreferrer">Créditos</a></footer></main>`;
  $('#continue-run')?.addEventListener('click', () => { run = current; show(); });
  $('#discard-save')?.addEventListener('click', () => {
    const result = store.discard();
    if (result === 'conflict') { conflict(); return; }
    if (result === 'unavailable') { saveUnavailable = true; warning(); return; }
    saved = { kind: 'empty' }; menu();
  });
  const start = () => {
    const seed = $<HTMLInputElement>('#run-seed').value || `kanto-${crypto.getRandomValues(new Uint32Array(1))[0].toString(16)}`;
    const next = createRun(catalog, seed, Number($<HTMLSelectElement>('#run-variance').value), CURRENT_EDITION);
    if (persist(next)) { saved = { kind: 'valid', run: next }; managing = false; pendingRecruitId = null; selectedMemberId = 1; lastFeedback = ''; migrationNotice = ''; show(); }
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
  if (managing) {
    frame('Prepara a tu equipo', `<div class="run-layout">${party()}<div>${managementHtml(current, catalog, selectedMemberId)}<button id="back-to-route">Volver a la ruta</button></div></div>`, 'Usa consumibles o cambia el objeto equipado antes de entrar al próximo combate.');
    $('#back-to-route').addEventListener('click', () => { managing = false; show(); });
    bindTeam(); return;
  }
  const layers = Array.from({ length: routeLength(current) * 2 }, (_, i) => current.nodes.filter(node => nodeStep(node) === i + 1));
  const nextStep = Math.min(...availableNodes(current).map(nodeStep));
  const map = `<section class="route-stage" aria-labelledby="route-title"><div class="route-tools"><h2 id="route-title">Ruta de Kanto</h2><button id="open-bag">Bolsa y equipo</button></div><p id="route-help">Una visita de tienda o reclutamiento antes de cada combate. Elegir una excluye la otra en ese tramo.</p><div class="route-scroll" tabindex="0" aria-label="Ruta completa, desplazamiento vertical"><div class="route-map"><svg id="route-lines" aria-hidden="true"></svg>${layers.map(nodes => `<div class="route-layer">${nodes.map(node => {
    const cleared = current.path.includes(node.id), available = choices.has(node.id), skipped = nodeStep(node) < nextStep && !cleared;
    const map = node.kind === 'combat' ? runMap(node.mapId) : null;
    const label = node.kind === 'shop' ? 'Tienda' : node.kind === 'recruit' ? 'Reclutamiento' : map!.name;
    const state = cleared ? 'Superado' : available ? 'Disponible' : skipped ? 'Ruta descartada' : 'Pendiente';
    const portraits = node.kind === 'combat' ? node.enemies : node.offers.map(offer => offer.speciesId);
    return `<button class="route-node ${node.kind} ${cleared ? 'cleared' : available ? 'available' : skipped ? 'skipped' : ''}" data-node="${node.id}" ${available ? '' : 'disabled'} aria-describedby="route-help" aria-label="${label}, ${state}${node.kind === 'combat' ? `; enemigos ${escape(node.enemies.map(id => species(id).name).join(', '))}` : ''}"><strong>${label}</strong>${portraits.length ? `<span class="node-enemies">${portraits.map(id => portrait(id, 32)).join('')}</span>` : '<span class="service-caption">Pociones y equipables</span>'}<small>${state}</small><span class="node-terrain">${map?.description ?? 'Visita limitada a este tramo'}</span></button>`;
  }).join('')}</div>`).join('')}</div></div><p class="route-progress">${completedCombats(current)}/${routeLength(current)} encuentros superados</p></section>`;
  frame('Elige tu próximo paso', `<div class="run-layout">${party()}${map}</div>`, 'Invierte en compañeros o recursos. Puedes curar y equipar al equipo desde la bolsa antes de combatir.');
  $('#open-bag').addEventListener('click', () => { managing = true; show(); });
  app.querySelectorAll<HTMLButtonElement>('[data-node]').forEach(button => button.addEventListener('click', () => {
    if (persist(enterRoom(current, button.dataset.node!, catalog))) { pendingRecruitId = null; lastFeedback = ''; show(); }
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
  const available = app.querySelector<HTMLElement>('.route-node.available')!;
  const pane = $('.route-scroll');
  pane.scrollTop = Math.max(0, available.getBoundingClientRect().top - $('.route-map').getBoundingClientRect().top - pane.clientHeight * .5);
  disposeView = () => observer.disconnect();
}
function perform(event: RunEvent, message: string, focus: string): void {
  try {
    const next = performRunEvent(run!, event, catalog);
    if (!persist(next)) return;
    lastFeedback = message; pendingRecruitId = null; show();
    const target = app.querySelector<HTMLElement>(focus);
    (target && !target.matches(':disabled') ? target : app.querySelector<HTMLElement>('#manage-member, #tab-service'))?.focus({ preventScroll: true });
  } catch (error) {
    lastFeedback = error instanceof Error ? error.message : 'No se pudo completar esta operación.';
    $('#management-feedback').textContent = lastFeedback;
  }
}
function bindTeam(): void {
  bindManagement(app, selectedMemberId, id => { selectedMemberId = id; show(); $('#manage-member').focus({ preventScroll: true }); }, perform);
}
function service(): void {
  const current = run!, node = currentNode(current)!;
  frame(node.kind === 'shop' ? 'Compra para el camino' : 'Amplía tu equipo', `<div class="run-layout">${party()}<div class="service-content"><nav class="service-nav" aria-label="Gestión de la visita"><button id="tab-service" aria-pressed="${!managing}">${node.kind === 'shop' ? 'Comprar' : 'Candidatos'}</button><button id="tab-bag" aria-pressed="${managing}">Bolsa y equipo</button></nav>${managing ? managementHtml(current, catalog, selectedMemberId) : serviceHtml(current, catalog, pendingRecruitId)}<button class="run-primary" id="leave-service">Cerrar visita y continuar</button><p class="service-close-note">Esta sala quedará cerrada; sus ofertas no volverán a aparecer en este tramo.</p></div></div>`, node.kind === 'shop' ? 'Las compras se añaden a tu bolsa. Elige cómo gastar el saldo de esta partida.' : 'Puedes incorporar hasta seis miembros. Con el equipo completo, elige y confirma una sustitución.');
  $('#tab-service').addEventListener('click', () => { managing = false; show(); $('#tab-service').focus({ preventScroll: true }); });
  $('#tab-bag').addEventListener('click', () => { managing = true; pendingRecruitId = null; show(); $('#manage-member').focus(); });
  bindTeam();
  app.querySelectorAll<HTMLButtonElement>('[data-buy]').forEach(button => button.addEventListener('click', () => {
    const itemId = button.dataset.buy as ItemId;
    perform({ kind: 'buy', itemId }, `${itemFor(itemId).name} añadido a la bolsa.`, `[data-buy="${itemId}"]`);
  }));
  app.querySelectorAll<HTMLButtonElement>('[data-recruit]').forEach(button => button.addEventListener('click', () => {
    const offerId = button.dataset.recruit!;
    if (current.roster.length === TEAM_LIMIT) { pendingRecruitId = offerId; recruitFocusSelector = `[data-recruit="${offerId}"]`; show(); $('#replace-member').focus(); }
    else perform({ kind: 'recruit', offerId, replaceId: null }, 'Nuevo compañero incorporado al equipo.', '#leave-service');
  }));
  app.querySelectorAll<HTMLButtonElement>('[data-replace-recruit]').forEach(button => button.addEventListener('click', () => {
    pendingRecruitId = button.dataset.replaceRecruit!; recruitFocusSelector = `[data-replace-recruit="${pendingRecruitId}"]`; show(); $('#replace-member').focus();
  }));
  $('#confirm-recruit')?.addEventListener('click', () => {
    if (pendingRecruitId) perform({ kind: 'recruit', offerId: pendingRecruitId, replaceId: Number($<HTMLSelectElement>('#replace-member').value) }, 'Sustitución registrada. El objeto del miembro saliente vuelve a la bolsa.', '#leave-service');
  });
  $('#cancel-recruit')?.addEventListener('click', cancelRecruit);
  $('#leave-service').addEventListener('click', () => {
    if (persist(leaveService(current, catalog))) { pendingRecruitId = null; managing = false; lastFeedback = 'Visita cerrada. Elige el próximo combate.'; show(); }
  });
}
function cancelRecruit(): void {
  const id = pendingRecruitId; pendingRecruitId = null; show();
  app.querySelector<HTMLElement>(recruitFocusSelector || `[data-recruit="${id}"]`)?.focus();
}
const onEscape = (event: KeyboardEvent): void => {
  if (event.key === 'Escape' && pendingRecruitId) { event.preventDefault(); cancelRecruit(); }
};
document.addEventListener('keydown', onEscape);
function result(): void {
  const current = run!, won = current.status === 'victory';
  const survivors = current.roster.filter(member => member.hp > 0).length;
  frame(won ? 'Ruta superada' : 'El equipo ha caído', `<div class="run-layout">${party()}<section class="run-ending"><h2>${won ? 'Has llegado al final de la prueba' : 'Cada elección deja huella'}</h2><p>${won ? 'Has despejado el destino de esta partida. El equipo superviviente y el recorrido quedan registrados.' : 'Los compañeros perdidos no pueden volver durante esta partida. Puedes empezar otra con una nueva semilla.'}</p><table><caption>Recorrido de la partida</caption><thead><tr><th>Tramo</th><th>Escenario</th><th>Rondas</th><th>Resultado</th></tr></thead><tbody>${current.history.map(record => `<tr><td>${record.nodeId.split('-')[0]}</td><td>${runMap(current.nodes.find(node => node.id === record.nodeId)!.mapId).name}</td><td>${record.round}</td><td>${record.outcome === 'victory' ? 'Victoria' : 'Derrota'}</td></tr>`).join('')}</tbody></table><button class="run-primary" id="result-menu">Volver al menú</button></section></div>`, `${completedCombats(current)}/${routeLength(current)} encuentros superados · ${survivors}/6 compañeros en pie`);
  $('#result-menu').addEventListener('click', menu);
}
function show(): void {
  if (!run) { menu(); return; }
  selectedMemberId = run.roster.find(member => member.id === selectedMemberId)?.id ?? run.roster[0]?.id ?? 0;
  if (run.status === 'route') { route(); return; }
  if (run.status === 'service') { service(); return; }
  if (run.status !== 'combat') { result(); return; }
  cleanup();
  const node = run.nodes.find(node => node.id === run!.currentNodeId)!;
  disposeView = mountBattle(catalog, {
    initial: run.battle!, title: `TRAMO ${node.floor}/${routeLength(run!)} · ${runMap(node.mapId).name.toUpperCase()}`,
    onState: state => persist(withBattle(run!, state)),
    onExit: menu,
    onComplete: () => {
      const won = run!.battle!.outcome === 'victory';
      if (persist(completeEncounter(run!, catalog))) { managing = false; lastFeedback = won ? `Victoria: +${VICTORY_REWARD} monedas. PS y bajas registrados.` : 'Derrota: el equipo ha caído. Sus objetos equipados vuelven a la bolsa.'; show(); }
    },
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
    if (saved.kind === 'valid' && saved.migrated) {
      if (!persist(saved.run)) return;
      migrationNotice = saveUnavailable ? 'Partida anterior adaptada en memoria. El guardado original sigue intacto.' : 'Partida actualizada al sprint 10A. Se conserva una copia del guardado anterior; PS y tiradas se mantienen.';
    }
    saveUnavailable = saved.kind === 'unavailable';
    warning();
    menu();
  } catch (error) {
    app.innerHTML = `<main class="run-main run-error"><h1>No pudimos abrir la ruta</h1><p>${escape(error instanceof Error ? error.message : 'Error de recursos locales.')}</p><button id="retry" class="run-primary">Volver a intentar</button></main>`;
    $('#retry').addEventListener('click', () => location.reload());
  }
}
import.meta.hot?.dispose(() => { cleanup(); notice.remove(); document.removeEventListener('keydown', onEscape); });
void boot();
