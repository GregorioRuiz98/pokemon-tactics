import './tactical.css';
import {
  validateCatalog,
  TYPE_NAMES,
  STAT_NAMES,
  STAT_KEYS,
} from './data/catalog';
import type { PokemonSpecies } from './data/catalog';
import { BoardScene } from './game/BoardScene';
import { startGame } from './game/main';
import {
  TRAINING_BOARD,
  TERRAIN,
  initialUnits,
  key,
  same,
  coordinate,
  routesFrom,
  planMove,
  commitMove,
} from './rules/movement';
import type { Point, Route } from './rules/movement';
import { ROLES } from './rules/design';

const app = document.querySelector<HTMLDivElement>('#app')!;
document.title='El claro de Kanto · Pokémon Tactics';
const esc = (value: string) =>
  value.replace(
    /[&<>"']/g,
    (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[
        c
      ]!,
  );
const url = (path: string) => `${import.meta.env.BASE_URL}${path}`;

function render(catalog: PokemonSpecies[]): void {
  let units = initialUnits(),
    selected = 1,
    pending: Point | null = null,
    hover: Point | null = null;
  let ready = false,
    moving = false;
  const preference = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = preference.matches;
  let routes = new Map<string, Route>();
  let cursor = 41;
  app.innerHTML = `
    <header class="topbar"><a class="brand" href="./"><span class="brand-symbol" aria-hidden="true">✦</span><span>POKÉMON <strong>TACTICS</strong></span></a><span class="build-label">ENSAYO TÁCTICO <span>01</span></span><a class="quiet camp-link" href="?view=camp">Campamento ↗</a></header>
    <main class="tactical-main">
      <section class="intro"><div><p class="eyebrow">CUADERNO DE EXPEDICIÓN / 002</p><h1>El claro de Kanto<span>.</span></h1><p class="lede">Traza tu camino. Cada casilla cuenta.</p></div><span class="trial-label">PRÁCTICA DE MOVIMIENTO</span></section>
      <div class="tactical-layout">
        <section class="battlefield" aria-label="Zona de ensayo">
          <div class="panel-bar"><span><i aria-hidden="true"></i> CLARO DEL BOSQUE</span><span>8 × 8 · N ↑</span></div>
          <div class="board-frame"><div class="board-shell">
            <div id="game-container" aria-hidden="true"></div>
            <div id="board-grid" role="grid" aria-label="Tablero de movimiento" aria-rowcount="8" aria-colcount="8" aria-describedby="board-help">${TRAINING_BOARD.map((row, y) => `<div role="row">${row.map((_, x) => `<button role="gridcell" data-cell="${x},${y}" tabindex="${y * 8 + x === cursor ? 0 : -1}" aria-label="${coordinate({ x, y })}" disabled></button>`).join('')}</div>`).join('')}</div>
          </div></div>
          <div class="terrain-legend"><span><i class="swatch ground"></i>Suelo · 1</span><span><i class="swatch brush"></i>Maleza · 2</span><span><i class="swatch blocked"></i>Roca / agua · bloqueado</span><span><i class="swatch reachable"></i>Alcanzable</span></div>
          <p id="board-help">Selecciona un Pokémon y un destino. Flechas para recorrer el tablero; Enter para elegir; Escape para cancelar.</p>
        </section>
        <aside class="tactical-dossier" aria-label="Ficha y movimiento">
          <p class="eyebrow">COMPAÑERO SELECCIONADO <span id="dex-number"></span></p>
          <h2 id="unit-name"></h2><div id="unit-types" class="type-list"></div>
          <div class="movement-meter"><span>MOVIMIENTO RESTANTE</span><strong><span id="remaining"></span><small id="budget"></small></strong><div id="movement-pips" aria-hidden="true"></div></div>
          <div class="position-line"><span>Posición <b id="position"></b></span><span>Orientación <b id="facing"></b></span></div>
          <div class="move-order"><p class="tiny-label">ORDEN DE MOVIMIENTO</p><p id="route-summary">Elige una casilla resaltada.</p><p id="route-path"></p><div class="order-buttons"><button id="confirm" disabled>Confirmar movimiento</button><button id="cancel" class="quiet" disabled>Cancelar</button></div></div>
          <p id="feedback" role="status" aria-live="polite">Preparando el tablero…</p>
          <details class="unit-details"><summary>Ficha y estadísticas</summary><p id="unit-role"></p><dl id="unit-stats"></dl></details>
          <p class="trial-note">Perfil terrestre de ensayo para las seis especies. El presupuesto se recupera al reiniciar.</p>
        </aside>
      </div>
      <div id="resource-status" role="status">Cargando recursos…</div>
      <section class="training-roster" aria-label="Pokémon del ensayo">${catalog.map((p) => `<button data-unit="${p.id}" aria-pressed="false"><img src="${url(`assets/pokemon/${p.id}/thumbnail.png`)}" alt="" width="48" height="48"><span><strong>${esc(p.name)}</strong><small data-unit-info="${p.id}"></small></span></button>`).join('')}</section>
      <div class="trial-tools"><button class="quiet" id="reset">Reiniciar ensayo</button><button class="quiet" id="pause" aria-pressed="${paused}">${paused ? 'Reanudar' : 'Pausar'} animaciones</button><a href="${url('CREDITS.md')}" target="_blank" rel="noreferrer">Créditos y licencias ↗</a></div>
    </main><footer><span>Proyecto fan · Prototipo en desarrollo</span><span>SPRINT 01 / Tablero y desplazamiento</span></footer>`;
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) =>
    document.querySelector<T>(selector)!;
  const cells = [
    ...document.querySelectorAll<HTMLButtonElement>('[data-cell]'),
  ];
  const unitButtons = [
    ...document.querySelectorAll<HTMLButtonElement>('[data-unit]'),
  ];
  const feedback = (message: string) => {
    $('#feedback').textContent = message;
  };
  const point = (button: HTMLButtonElement): Point => {
    const [x, y] = button.dataset.cell!.split(',').map(Number);
    return { x, y };
  };
  const scene = new BoardScene(catalog, {
    progress: (f) => {
      $('#resource-status').textContent =
        `Cargando recursos… ${Math.round(f * 100)} %`;
    },
    ready: (missing) => {
      ready = true;
      const status = $('#resource-status');
      if (missing.length) {
        status.textContent =
          'Faltan algunas animaciones; puedes seguir con los marcadores. ';
        const retry = document.createElement('button');
        retry.textContent = 'Volver a cargar';
        retry.addEventListener('click', () => location.reload());
        status.append(retry);
      } else status.hidden = true;
      scene.setPaused(paused);
      refresh();
      feedback('Selecciona un destino para Bulbasaur.');
    },
  });
  function refreshPaths(): void {
    routes = routesFrom(TRAINING_BOARD, units, selected);
  }
  function paintBoard(): void {
    const active = units.find((u) => u.id === selected)!;
    const destination = pending ?? hover;
    const route = destination ? routes.get(key(destination)) : undefined;
    const showRoute =
      route && route.cost <= active.remaining ? route : undefined;
    let cumulative = 0;
    const costs = new Map<string, number>();
    showRoute?.path.slice(1).forEach((p) => {
      cumulative +=
        TERRAIN[TRAINING_BOARD[p.y][p.x] as keyof typeof TERRAIN].cost;
      costs.set(key(p), cumulative);
    });
    cells.forEach((button) => {
      const p = point(button),
        cellKey = key(p),
        unit = units.find((u) => same(u, p));
      const terrain = TERRAIN[TRAINING_BOARD[p.y][p.x] as keyof typeof TERRAIN];
      const reachable =
        !unit && (routes.get(cellKey)?.cost ?? Infinity) <= active.remaining;
      const chosen = !!unit && unit.id === selected;
      button.className = `tile ${reachable ? 'can-reach' : ''} ${chosen ? 'selected-unit' : ''} ${costs.has(cellKey) ? 'path-tile' : ''} ${destination && same(p, destination) && showRoute ? 'destination' : ''} ${unit ? 'occupied' : ''}`;
      button.disabled = !ready || moving;
      button.setAttribute(
        'aria-selected',
        String(chosen || (!!pending && same(p, pending))),
      );
      const pokemon = unit ? catalog.find((s) => s.id === unit.id) : null;
      button.setAttribute(
        'aria-label',
        `${coordinate(p)}, ${terrain.name}${pokemon ? `, ${pokemon.name}` : ''}${reachable ? `, alcanzable, coste ${routes.get(cellKey)!.cost}` : ''}${chosen ? ', seleccionado' : ''}${costs.has(cellKey) ? `, trayectoria, coste acumulado ${costs.get(cellKey)}` : ''}`,
      );
      button.innerHTML = `<span class="tile-coordinate">${coordinate(p)}</span>${unit ? `<span class="tile-unit">${esc(pokemon!.name)}</span>` : ''}${costs.has(cellKey) ? `<span class="path-cost">${costs.get(cellKey)}</span>` : ''}${chosen ? '<span class="unit-pointer" aria-hidden="true">▼</span>' : ''}`;
    });
  }
  function refresh(): void {
    const unit = units.find((u) => u.id === selected)!,
      pokemon = catalog.find((p) => p.id === selected)!;
    $('#unit-name').textContent = pokemon.name;
    $('#dex-number').textContent = `#${String(selected).padStart(3, '0')}`;
    $('#unit-types').innerHTML = pokemon.types
      .map((t) => `<span class="type type-${t}">${TYPE_NAMES[t]}</span>`)
      .join('');
    $('#remaining').textContent = String(unit.remaining);
    $('#budget').textContent = ` / ${unit.budget}`;
    $('#movement-pips').innerHTML = Array.from(
      { length: unit.budget },
      (_, i) => `<i class="${i < unit.remaining ? 'available' : ''}"></i>`,
    ).join('');
    $('#position').textContent = coordinate(unit);
    $('#facing').textContent = { 0: 'Sur', 2: 'Este', 4: 'Norte', 6: 'Oeste' }[
      unit.facing
    ];
    $('#unit-role').textContent =
      `${ROLES[selected].name} (propuesto). ${ROLES[selected].description}`;
    $('#unit-stats').innerHTML = STAT_KEYS.map(
      (k) =>
        `<div><dt>${STAT_NAMES[k]}</dt><dd>${pokemon.baseStats[k]}</dd></div>`,
    ).join('');
    const plan = pending
      ? planMove(TRAINING_BOARD, units, selected, pending)
      : null;
    $('#route-summary').textContent = moving
      ? 'En movimiento…'
      : plan?.ok
        ? `${coordinate(unit)} → ${coordinate(pending!)} · ${plan.route.cost} puntos`
        : unit.remaining
          ? 'Elige una casilla resaltada.'
          : 'Sin movimiento restante.';
    $('#route-path').textContent = plan?.ok
      ? plan.route.path.map(coordinate).join(' → ')
      : 'La maleza cuesta el doble que el suelo.';
    $<HTMLButtonElement>('#confirm').disabled = !ready || moving || !plan?.ok;
    $<HTMLButtonElement>('#cancel').disabled = !ready || moving || !pending;
    $<HTMLButtonElement>('#reset').disabled = !ready || moving;
    $<HTMLButtonElement>('#pause').disabled = !ready;
    unitButtons.forEach((button) => {
      const id = Number(button.dataset.unit),
        u = units.find((v) => v.id === id)!;
      button.disabled = !ready || moving;
      button.setAttribute('aria-pressed', String(id === selected));
      $(`[data-unit-info="${id}"]`).textContent =
        `${coordinate(u)} · ${u.remaining}/${u.budget} mov.`;
    });
    paintBoard();
  }
  function choose(id: number): void {
    if (!ready || moving) return;
    selected = id;
    pending = null;
    hover = null;
    refreshPaths();
    refresh();
    feedback(
      `${catalog.find((p) => p.id === id)!.name} seleccionado. Elige un destino.`,
    );
  }
  function cancel(): void {
    if (moving) return;
    pending = null;
    hover = null;
    refresh();
    feedback('Orden cancelada. No se ha gastado movimiento.');
  }
  cells.forEach((button, index) => {
    button.addEventListener('click', () => {
      if (!ready || moving) return;
      const p = point(button),
        occupant = units.find((u) => same(u, p));
      if (occupant) {
        choose(occupant.id);
        return;
      }
      const plan = planMove(TRAINING_BOARD, units, selected, p);
      pending = plan.ok ? p : null;
      hover = null;
      refresh();
      feedback(
        plan.ok
          ? `Destino ${coordinate(p)}. Confirma o cancela la orden.`
          : plan.reason,
      );
    });
    button.addEventListener('pointerenter', () => {
      if (!moving) {
        hover = point(button);
        paintBoard();
      }
    });
    button.addEventListener('pointerleave', () => {
      hover = null;
      if (!moving) paintBoard();
    });
    button.addEventListener('focus', () => {
      cells[cursor].tabIndex = -1;
      cursor = index;
      button.tabIndex = 0;
    });
    button.addEventListener('keydown', (event) => {
      const p = point(button),
        delta = (
          {
            ArrowLeft: [-1, 0],
            ArrowRight: [1, 0],
            ArrowUp: [0, -1],
            ArrowDown: [0, 1],
          } as Record<string, number[]>
        )[event.key];
      if (delta) {
        event.preventDefault();
        const x = Math.max(0, Math.min(7, p.x + delta[0])),
          y = Math.max(0, Math.min(7, p.y + delta[1]));
        cells[y * 8 + x].focus();
      }
      if (event.key === 'Escape') {
        event.preventDefault();
        cancel();
      }
    });
  });
  unitButtons.forEach((b) =>
    b.addEventListener('click', () => choose(Number(b.dataset.unit))),
  );
  $('#cancel').addEventListener('click', cancel);
  const cancelOnEscape = (event: KeyboardEvent): void => {
    if (event.key === 'Escape' && pending && !moving) {
      event.preventDefault();
      cancel();
    }
  };
  document.addEventListener('keydown', cancelOnEscape);
  $('#confirm').addEventListener('click', () => {
    void confirm();
  });
  async function confirm(): Promise<void> {
    if (!ready || moving || !pending) return;
    const result = commitMove(TRAINING_BOARD, units, selected, pending);
    if (!result.ok) {
      pending = null;
      refresh();
      feedback(result.reason);
      return;
    }
    const destination = { ...pending };
    moving = true;
    hover = null;
    refresh();
    feedback('Desplazando al Pokémon…');
    await scene.move(selected, result.route.path, preference.matches || paused);
    units = result.units;
    pending = null;
    moving = false;
    scene.sync(units);
    refreshPaths();
    refresh();
    feedback(
      `${catalog.find((p) => p.id === selected)!.name} llegó a ${coordinate(destination)}. Coste: ${result.route.cost}.`,
    );
    cells[destination.y * 8 + destination.x].focus();
  }
  $('#reset').addEventListener('click', () => {
    if (!ready || moving) return;
    units = initialUnits();
    selected = 1;
    pending = null;
    hover = null;
    scene.sync(units);
    refreshPaths();
    refresh();
    feedback('Ensayo reiniciado: posiciones y movimiento restaurados.');
  });
  function setPaused(value: boolean): void {
    paused = value;
    scene.setPaused(value);
    $('#pause').setAttribute('aria-pressed', String(value));
    $('#pause').textContent = `${value ? 'Reanudar' : 'Pausar'} animaciones`;
  }
  $('#pause').addEventListener('click', () => setPaused(!paused));
  const motionChanged = (event: MediaQueryListEvent) =>
    setPaused(event.matches);
  preference.addEventListener('change', motionChanged);
  document
    .querySelectorAll<HTMLImageElement>('.training-roster img')
    .forEach((img) =>
      img.addEventListener('error', () => {
        img.hidden = true;
      }),
    );
  scene.sync(units);
  refreshPaths();
  refresh();
  const game = startGame(scene, { width: 512, height: 512 });
  import.meta.hot?.dispose(() => {
    document.removeEventListener('keydown', cancelOnEscape);
    preference.removeEventListener('change', motionChanged);
    game.destroy(true);
  });
}
async function boot(): Promise<void> {
  try {
    const response = await fetch(url('data/pokemon.json'), {
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok)
      throw new Error(`No se pudo cargar el catálogo (${response.status}).`);
    const catalog = validateCatalog(await response.json());
    await document.fonts.load('16px "Pixelify Sans"');
    render(catalog);
  } catch (error) {
    app.innerHTML = `<main class="failure"><p class="eyebrow">POKÉMON TACTICS</p><h1>No pudimos abrir el tablero</h1><p>${esc(error instanceof Error ? error.message : 'Error de recursos locales.')}</p><button id="retry">Volver a intentar</button></main>`;
    document
      .querySelector('#retry')!
      .addEventListener('click', () => location.reload());
  }
}
void boot();
