import './tactical.css';
import './battle.css';
import { validateCatalog, TYPE_NAMES } from './data/catalog';
import type { PokemonSpecies } from './data/catalog';
import { BoardScene } from './game/BoardScene';
import { startGame } from './game/main';
import {
  key,
  same,
  coordinate,
  TERRAIN,
  routesFrom,
  planMove,
} from './rules/movement';
import type { Point, Route } from './rules/movement';
import {
  createBattle,
  activeUnit,
  living,
  attackPlan,
  applyCommand,
  chooseTacticalCommand,
} from './rules/battle';
import type { TacticalCommand } from './rules/battle';

const app = document.querySelector<HTMLDivElement>('#app')!;
const asset = (path: string) => `${import.meta.env.BASE_URL}${path}`;
const escape = (value: string) =>
  value.replace(
    /[&<>"']/g,
    (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[
        c
      ]!,
  );
function render(catalog: PokemonSpecies[]): void {
  let state = createBattle(catalog),
    inspected = 1,
    mode: 'move' | 'attack' = 'move';
  let pending: TacticalCommand | null = null,
    hover: Point | null = null;
  let ready = false,
    busy = false,
    generation = 0,
    enemyGeneration: number | null = null;
  let routes = new Map<string, Route>(),
    cursor = 49;
  const preference = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = preference.matches;
  app.innerHTML = `
    <main id="battle-root" class="battle-main">
      <section id="gameplay" class="gameplay" aria-labelledby="game-title">
        <header class="game-topbar"><h1 id="game-title">POKÉMON <span>TACTICS</span></h1><div class="battle-counts"><span id="ally-count"></span><span id="enemy-count"></span></div><button class="hud-utility" id="pause" aria-pressed="${paused}" disabled>${paused ? 'Reanudar' : 'Pausar'} animaciones</button><details id="game-options"><summary>Opciones</summary><div class="options-panel"><h2>Opciones de combate</h2><form id="battle-settings"><label for="seed">Semilla<input id="seed" name="seed" maxlength="64" value="kanto-001" autocomplete="off"></label><label for="variance">Variación<select id="variance"><option value="0.05">±5 %</option><option value="0.1">±10 %</option></select></label><p>Los cambios se aplican al reiniciar.</p><button id="restart" type="submit" disabled>Reiniciar combate</button></form><section class="training-roster battle-roster" aria-label="Unidades del combate">${state.units.map((u) => `<button data-unit="${u.id}" data-team="${u.team}" aria-pressed="false"><img src="${asset(`assets/pokemon/${u.id}/thumbnail.png`)}" alt="" width="32" height="32"><span><strong>${escape(u.name)}</strong><small data-unit-info="${u.id}"></small></span></button>`).join('')}</section><nav class="battle-nav" aria-label="Prototipos"><a href="?view=training">Ensayo de movimiento</a><a href="?view=camp">Campamento</a><a href="${asset('CREDITS.md')}" target="_blank" rel="noreferrer">Créditos y licencias</a></nav><details class="battle-log"><summary>Registro de combate</summary><ol id="combat-log"></ol></details></div></details></header>
        <section class="initiative-strip" aria-labelledby="initiative-title"><div class="round-label"><h2 id="initiative-title">Ronda <span id="round"></span></h2><span>CLARO DE KANTO</span></div><ol id="initiative"></ol></section>
        <div id="resource-status" class="game-resource" role="status">Cargando recursos…</div>
        <section class="battlefield" aria-label="Tablero de combate">
          <div class="board-shell"><div id="game-container" aria-hidden="true"></div><div id="board-grid" role="grid" aria-label="Tablero de combate" aria-rowcount="8" aria-colcount="8" aria-describedby="board-help">${state.board.map((row, y) => `<div role="row">${row.map((_, x) => `<button role="gridcell" data-cell="${x},${y}" tabindex="${y * 8 + x === cursor ? 0 : -1}" disabled></button>`).join('')}</div>`).join('')}</div><div id="battle-result" hidden><h2 id="result-title" tabindex="-1"></h2><p id="result-description"></p><button id="play-again">Volver a combatir</button></div></div>
          <div class="terrain-legend"><span>A · Aliado</span><span>E · Enemigo</span><span>Suelo 1 / maleza 2</span><span>Roca y agua bloquean</span></div>
        </section>
        <div class="hud-bottom">
          <aside class="actor-hud hud-window" aria-label="Unidad activa"><div class="hud-unit-heading"><img id="actor-portrait" src="${asset(`assets/pokemon/${activeUnit(state)!.id}/thumbnail.png`)}" alt="" width="72" height="72"><div><p id="turn-owner"></p><h2 id="actor-name"></h2><p id="turn-status"></p></div></div><div class="hud-health"><strong id="actor-hp"></strong><div id="actor-health" class="health-track" aria-hidden="true"></div></div><div class="activation-resources"><span id="move-available"></span><span id="action-available"></span></div><p id="actor-stats"></p></aside>
          <section class="orders-hud" aria-label="Órdenes de combate"><div class="battle-actions"><button id="mode-move" aria-pressed="true">Mover</button><button id="mode-attack" aria-pressed="false">Ataque básico</button><button id="finish-turn" disabled>Terminar turno</button></div><div class="order-preview"><div id="attack-forecast" hidden><span>DAÑO <strong id="forecast-damage"></strong></span><span>ACIERTO <strong>100 %</strong></span></div><p id="order-summary">Espera tu turno.</p><p id="order-detail"></p><div class="order-buttons"><button id="confirm" disabled>Confirmar orden</button><button id="cancel" disabled>Cancelar</button></div></div><p id="feedback" role="status" aria-live="polite">Cargando el combate…</p></section>
          <aside class="target-hud hud-window" aria-labelledby="inspect-name"><p class="target-label">FICHA CONSULTADA</p><div class="hud-unit-heading"><img id="inspect-portrait" src="${asset(`assets/pokemon/${inspected}/thumbnail.png`)}" alt="" width="64" height="64"><div><h3 id="inspect-name"></h3><span id="inspect-team"></span><div id="inspect-types" class="type-list"></div></div></div><div class="health-readout"><strong id="inspect-hp"></strong><span id="inspect-position"></span></div><div id="inspect-health" class="health-track" aria-hidden="true"></div><p id="inspect-stats"></p></aside>
        </div>
        <p id="board-help">Flechas: recorrer · Enter: elegir · Escape: cancelar. Una acción y un desplazamiento por turno.</p>
      </section>
    </main>`;
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) =>
    document.querySelector<T>(selector)!;
  const cells = [
    ...document.querySelectorAll<HTMLButtonElement>('[data-cell]'),
  ];
  const unitButtons = [
    ...document.querySelectorAll<HTMLButtonElement>('[data-unit]'),
  ];
  const point = (button: HTMLButtonElement): Point => {
    const [x, y] = button.dataset.cell!.split(',').map(Number);
    return { x, y };
  };
  const say = (message: string): void => {
    $('#feedback').textContent = message;
  };
  const playerTurn = (): boolean =>
    ready && !busy && activeUnit(state)?.team === 'ally';
  const scene = new BoardScene(
    catalog,
    {
      progress: (f) => {
        $('#resource-status').textContent =
          `Cargando recursos… ${Math.round(f * 100)} %`;
      },
      ready: (missing) => {
        ready = true;
        const status = $('#resource-status');
        if (missing.length) {
          status.textContent =
            'Faltan animaciones. Puedes jugar con marcadores. ';
          const retry = document.createElement('button');
          retry.textContent = 'Volver a cargar';
          retry.addEventListener('click', () => location.reload());
          status.append(retry);
        } else status.hidden = true;
        scene.setPaused(paused);
        refreshPaths();
        refresh();
        say('Comienza el combate. La cola se mantiene durante esta ronda.');
        scheduleEnemies();
      },
    },
    state.board,
  );
  function refreshPaths(): void {
    const actor = activeUnit(state);
    routes = actor
      ? routesFrom(state.board, living(state), actor.id)
      : new Map();
  }
  function paint(): void {
    const actor = activeUnit(state);
    const destination =
      pending?.kind === 'move' ? pending.destination : pending ? null : hover;
    const route =
      actor && destination && !state.moved
        ? routes.get(key(destination))
        : undefined;
    const costs = new Map<string, number>();
    let cost = 0;
    if (route && route.cost <= actor!.remaining)
      route.path.slice(1).forEach((p) => {
        cost += tileCostAt(p);
        costs.set(key(p), cost);
      });
    cells.forEach((button) => {
      const p = point(button),
        unit = living(state).find((u) => same(u, p)),
        terrain = TERRAIN[state.board[p.y][p.x] as keyof typeof TERRAIN];
      const reachable =
        !!actor &&
        playerTurn() &&
        !state.moved &&
        !unit &&
        (routes.get(key(p))?.cost ?? Infinity) <= actor.remaining;
      const attackable =
        !!unit && playerTurn() && !state.acted && attackPlan(state, unit.id).ok;
      button.disabled = !ready || busy;
      button.className = `tile ${unit ? 'occupied team-' + unit.team : ''} ${unit && actor && unit.id === actor.id ? 'active-unit' : ''} ${unit?.id === inspected ? 'inspected' : ''} ${mode === 'move' && reachable ? 'can-reach' : ''} ${mode === 'attack' && attackable ? 'can-attack' : ''} ${costs.has(key(p)) ? 'path-tile' : ''} ${destination && same(p, destination) && route && route.cost <= actor!.remaining ? 'destination' : ''} ${pending?.kind === 'attack' && pending.target === unit?.id ? 'attack-target' : ''}`;
      button.setAttribute(
        'aria-selected',
        String(!!unit && unit.id === inspected),
      );
      button.setAttribute(
        'aria-label',
        `${coordinate(p)}, ${terrain.name}${unit ? `, ${unit.name}, ${unit.team === 'ally' ? 'aliado' : 'enemigo'}, ${unit.hp} de ${unit.maxHp} PS` : ''}${unit && actor && unit.id === actor.id ? ', turno activo' : ''}${reachable ? `, alcanzable, coste ${routes.get(key(p))!.cost}` : ''}${attackable ? ', atacable' : ''}`,
      );
      button.innerHTML = `<span class="tile-coordinate">${coordinate(p)}</span>${unit ? `<span class="team-marker" aria-hidden="true">${unit.team === 'ally' ? 'A' : 'E'}</span><span class="tile-unit">${escape(unit.name)}</span><span class="tile-health" aria-hidden="true"><i style="width:${(unit.hp / unit.maxHp) * 100}%"></i></span>` : ''}${costs.has(key(p)) ? `<span class="path-cost">${costs.get(key(p))}</span>` : ''}`;
    });
  }
  const tileCostAt = (p: Point) =>
    TERRAIN[state.board[p.y][p.x] as keyof typeof TERRAIN].cost;
  function refresh(): void {
    const actor = activeUnit(state),
      canOrder = playerTurn(),
      root = $('#battle-root');
    root.dataset.active = String(actor?.id ?? '');
    root.dataset.team = actor?.team ?? '';
    root.dataset.round = String(state.round);
    root.dataset.outcome = state.outcome;
    root.dataset.busy = String(busy);
    root.dataset.moved = String(state.moved);
    root.dataset.acted = String(state.acted);
    $('#round').textContent = String(state.round);
    $('#ally-count').textContent =
      `${living(state).filter((u) => u.team === 'ally').length}/3 aliados`;
    $('#enemy-count').textContent =
      `${living(state).filter((u) => u.team === 'enemy').length}/3 enemigos`;
    $('#turn-status').textContent = actor
      ? `${actor.team === 'ally' ? 'TU TURNO' : 'TURNO ENEMIGO'} · ${actor.name}`
      : state.outcome === 'victory'
        ? 'ZONA DESPEJADA'
        : 'COMBATE TERMINADO';
    $('#turn-owner').textContent = actor
      ? actor.team === 'ally'
        ? 'ACTIVACIÓN DEL JUGADOR'
        : 'ACTIVACIÓN ENEMIGA'
      : 'RESULTADO';
    $('#actor-name').textContent =
      actor?.name ?? (state.outcome === 'victory' ? 'Victoria' : 'Derrota');
    const actorCard =
      actor ??
      state.units.find((unit) => unit.team === 'ally' && unit.hp > 0) ??
      state.units[0];
    $('.actor-hud').dataset.team = actorCard.team;
    $<HTMLImageElement>('#actor-portrait').src = asset(
      `assets/pokemon/${actorCard.id}/thumbnail.png`,
    );
    $('#actor-hp').textContent = `PS ${actorCard.hp}/${actorCard.maxHp}`;
    $('#actor-stats').textContent =
      `Velocidad ${actorCard.speed} · alcance ${actorCard.range}`;
    $('#actor-health').innerHTML =
      `<i style="width:${(actorCard.hp / actorCard.maxHp) * 100}%"></i>`;
    $('#move-available').textContent = actor
      ? state.moved
        ? 'Desplazamiento usado'
        : `Movimiento ${actor.remaining}/${actor.budget}`
      : 'Combate finalizado';
    $('#action-available').textContent = actor
      ? state.acted
        ? 'Acción usada'
        : '1 acción disponible'
      : '';
    $('#action-available').hidden = !actor;
    $('#move-available').classList.toggle('spent', state.moved);
    $('#action-available').classList.toggle('spent', state.acted);
    $('#initiative').innerHTML = state.initiative
      .map((entry) => {
        const unit = state.units.find((u) => u.id === entry.id)!,
          done = state.completed.includes(unit.id),
          fainted = unit.hp <= 0;
        return `<li class="${unit.team} ${actor?.id === unit.id ? 'current' : ''} ${done ? 'done' : ''} ${fainted ? 'fainted' : ''}"><button data-inspect="${unit.id}" aria-label="${escape(unit.name)}, ${unit.team === 'ally' ? 'aliado' : 'enemigo'}, iniciativa ${entry.score.toFixed(1)}${actor?.id === unit.id ? ', activo' : ''}${done ? ', activación completada' : ''}${fainted ? ', fuera de combate' : ''}"><img src="${asset(`assets/pokemon/${unit.id}/thumbnail.png`)}" alt="" width="28" height="28"><span>${escape(unit.name)}<small>${fainted ? 'Fuera' : done ? 'Hecho' : `${entry.score.toFixed(1)} vel.`}</small></span></button></li>`;
      })
      .join('');
    document
      .querySelectorAll<HTMLButtonElement>('[data-inspect]')
      .forEach((button) =>
        button.addEventListener('click', () => {
          inspected = Number(button.dataset.inspect);
          refresh();
        }),
      );
    $<HTMLButtonElement>('#mode-move').disabled = !canOrder || state.moved;
    $<HTMLButtonElement>('#mode-attack').disabled = !canOrder || state.acted;
    $('#mode-move').setAttribute('aria-pressed', String(mode === 'move'));
    $('#mode-attack').setAttribute('aria-pressed', String(mode === 'attack'));
    $<HTMLButtonElement>('#confirm').disabled = !canOrder || !pending;
    $<HTMLButtonElement>('#cancel').disabled = !canOrder || !pending;
    $<HTMLButtonElement>('#finish-turn').disabled = !canOrder;
    $<HTMLButtonElement>('#restart').disabled = !ready || busy;
    $<HTMLButtonElement>('#play-again').disabled = !ready || busy;
    $<HTMLButtonElement>('#pause').disabled = !ready;
    $('.order-buttons').hidden = !pending;
    $('#attack-forecast').hidden = pending?.kind !== 'attack';
    if (pending?.kind === 'move' && actor) {
      const route = routes.get(key(pending.destination))!;
      $('#order-summary').textContent =
        `${coordinate(actor)} → ${coordinate(pending.destination)} · ${route.cost} puntos`;
      $('#order-detail').textContent = route.path.map(coordinate).join(' → ');
      $('#confirm').textContent = 'Confirmar movimiento';
    } else if (pending?.kind === 'attack') {
      const targetId = pending.target;
      const target = state.units.find((u) => u.id === targetId)!;
      const plan = attackPlan(state, target.id);
      $('#forecast-damage').textContent = plan.ok ? String(plan.damage) : '—';
      $('#order-summary').textContent = `Ataque básico → ${target.name}`;
      $('#order-detail').textContent = plan.ok
        ? `${plan.damage} PS de daño · objetivo ${target.hp} → ${target.hp - plan.damage} PS${plan.damage === target.hp ? ' · fuera de combate' : ''}`
        : plan.reason;
      $('#confirm').textContent = 'Confirmar ataque';
    } else {
      $('#order-summary').textContent = !actor
        ? 'La batalla ha terminado.'
        : !canOrder
          ? 'El enemigo está actuando.'
          : state.moved && state.acted
            ? 'Activación completa.'
            : mode === 'move'
              ? 'Elige un destino resaltado.'
              : 'Elige un enemigo en alcance.';
      $('#order-detail').textContent = actor
        ? `Alcance básico ${actor.range}. Puedes mover y atacar en cualquier orden.`
        : '';
      $('#confirm').textContent = 'Confirmar orden';
    }
    const unit = state.units.find((u) => u.id === inspected)!;
    $<HTMLImageElement>('#inspect-portrait').src = asset(
      `assets/pokemon/${unit.id}/thumbnail.png`,
    );
    $('.target-hud').dataset.team = unit.team;
    $('.target-label').textContent =
      pending?.kind === 'attack' ? 'OBJETIVO' : 'FICHA CONSULTADA';
    $('#inspect-name').textContent = unit.name;
    $('#inspect-team').textContent =
      unit.team === 'ally' ? 'Aliado' : 'Enemigo';
    $('#inspect-types').innerHTML = catalog
      .find((p) => p.id === unit.id)!
      .types.map((t) => `<span class="type type-${t}">${TYPE_NAMES[t]}</span>`)
      .join('');
    $('#inspect-hp').textContent = `${unit.hp}/${unit.maxHp} PS`;
    $('#inspect-position').textContent =
      unit.hp > 0 ? coordinate(unit) : 'Fuera de combate';
    $('#inspect-health').innerHTML =
      `<i style="width:${(unit.hp / unit.maxHp) * 100}%"></i>`;
    $('#inspect-stats').textContent =
      `Velocidad base ${unit.speed} · alcance ${unit.range} · movimiento ${unit.budget}`;
    unitButtons.forEach((button) => {
      const unit = state.units.find(
        (u) => u.id === Number(button.dataset.unit),
      )!;
      button.disabled = !ready || busy;
      button.setAttribute('aria-pressed', String(unit.id === inspected));
      button.dataset.hp = String(unit.hp);
      button.dataset.x = String(unit.x);
      button.dataset.y = String(unit.y);
      $(`[data-unit-info="${unit.id}"]`).textContent =
        unit.hp > 0
          ? `${unit.hp}/${unit.maxHp} PS · ${coordinate(unit)}`
          : 'Fuera de combate';
      button.classList.toggle('fainted', unit.hp <= 0);
    });
    $('#combat-log').innerHTML = state.log
      .map((line) => `<li>${escape(line)}</li>`)
      .join('');
    $('#battle-result').hidden = state.outcome === 'playing';
    if (state.outcome !== 'playing') {
      $('#result-title').textContent =
        state.outcome === 'victory' ? 'Victoria' : 'Derrota';
      $('#result-description').textContent =
        state.outcome === 'victory'
          ? `Zona despejada en ${state.round} rondas. ${living(state).filter((u) => u.team === 'ally').length} ${living(state).filter((u) => u.team === 'ally').length === 1 ? 'compañero' : 'compañeros'} en pie.`
          : `El equipo ha caído en la ronda ${state.round}. Prueba otra posición o concentra tus ataques.`;
    }
    paint();
  }
  function cancel(): void {
    if (!playerTurn()) return;
    pending = null;
    hover = null;
    refresh();
    say('Orden cancelada. Se conservan movimiento y acción.');
    focusActor();
  }
  cells.forEach((button, index) => {
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
        cells[
          Math.max(0, Math.min(7, p.y + delta[1])) * 8 +
            Math.max(0, Math.min(7, p.x + delta[0]))
        ].focus();
      }
    });
    button.addEventListener('pointerenter', () => {
      if (playerTurn() && mode === 'move' && !pending) {
        hover = point(button);
        paint();
      }
    });
    button.addEventListener('pointerleave', () => {
      hover = null;
      if (!busy) paint();
    });
    button.addEventListener('click', () => {
      const p = point(button),
        unit = living(state).find((u) => same(u, p));
      if (unit) inspected = unit.id;
      if (!playerTurn()) {
        refresh();
        return;
      }
      const actor = activeUnit(state)!;
      hover = null;
      pending = null;
      if (unit?.team !== actor.team && unit) {
        const plan = attackPlan(state, unit.id);
        if (plan.ok) {
          pending = { kind: 'attack', target: unit.id };
          mode = 'attack';
          say(`Atacar a ${unit.name}: confirma o cancela.`);
        } else say(plan.reason);
      } else if (!unit) {
        if (mode === 'attack') {
          say('Elige una unidad enemiga para atacar.');
        } else if (state.moved) {
          say('Ya has usado tu desplazamiento.');
        } else {
          const plan = planMove(state.board, living(state), actor.id, p);
          if (plan.ok) {
            pending = { kind: 'move', destination: p };
            say(`Mover a ${coordinate(p)}: confirma o cancela.`);
          } else say(plan.reason);
        }
      } else
        say(
          `${unit.name}: ficha consultada. La activación sigue siendo de ${actor.name}.`,
        );
      refresh();
    });
  });
  unitButtons.forEach((button) =>
    button.addEventListener('click', () => {
      inspected = Number(button.dataset.unit);
      refresh();
      $<HTMLDetailsElement>('#game-options').open = false;
    }),
  );
  $('#mode-move').addEventListener('click', () => {
    mode = 'move';
    pending = null;
    hover = null;
    refresh();
  });
  $('#mode-attack').addEventListener('click', () => {
    mode = 'attack';
    pending = null;
    hover = null;
    refresh();
  });
  $('#cancel').addEventListener('click', cancel);
  const onEscape = (event: KeyboardEvent) => {
    const options = $<HTMLDetailsElement>('#game-options');
    if (event.key === 'Escape' && options.open) {
      event.preventDefault();
      options.open = false;
      options.querySelector<HTMLElement>('summary')!.focus();
      return;
    }
    if (event.key === 'Escape' && pending && playerTurn()) {
      event.preventDefault();
      cancel();
    }
  };
  document.addEventListener('keydown', onEscape);
  const closeOptions = (event: PointerEvent): void => {
    const options = $<HTMLDetailsElement>('#game-options');
    if (
      options.open &&
      event.target instanceof Node &&
      !options.contains(event.target)
    )
      options.open = false;
  };
  document.addEventListener('pointerdown', closeOptions);
  async function execute(
    command: TacticalCommand,
    token = generation,
  ): Promise<void> {
    const actor = activeUnit(state);
    if (!actor) return;
    const result = applyCommand(state, command);
    if (!result.ok) {
      say(result.reason);
      return;
    }
    busy = true;
    pending = null;
    hover = null;
    refresh();
    if (command.kind === 'move' && result.route)
      await scene.move(
        actor.id,
        result.route.path,
        preference.matches || paused,
      );
    if (command.kind === 'attack')
      await scene.hit(command.target, preference.matches || paused);
    if (token !== generation) return;
    state = result.state;
    busy = false;
    scene.sync(living(state));
    refreshPaths();
    if (state.moved) mode = 'attack';
    if (state.acted) mode = 'move';
    if (command.kind === 'finish') {
      mode = 'move';
      inspected = activeUnit(state)?.id ?? inspected;
    }
    refresh();
    say(state.log[state.log.length - 1]);
    if (state.outcome !== 'playing') $('#result-title').focus();
    else if (command.kind === 'move') {
      const unit = activeUnit(state)!;
      cells[unit.y * 8 + unit.x].focus();
    }
  }
  function focusActor(): void {
    const actor = activeUnit(state);
    if (actor?.team === 'ally') cells[actor.y * 8 + actor.x].focus();
  }
  async function runEnemies(token: number): Promise<void> {
    if (enemyGeneration === token) return;
    enemyGeneration = token;
    try {
      while (
        token === generation &&
        ready &&
        state.outcome === 'playing' &&
        activeUnit(state)?.team === 'enemy'
      ) {
        await new Promise((resolve) =>
          setTimeout(resolve, preference.matches ? 50 : 360),
        );
        if (token !== generation) break;
        await execute(chooseTacticalCommand(state), token);
      }
    } finally {
      if (token === generation && enemyGeneration === token) {
        enemyGeneration = null;
        refresh();
        focusActor();
      }
    }
  }
  function scheduleEnemies(): void {
    if (ready && activeUnit(state)?.team === 'enemy')
      void runEnemies(generation);
  }
  $('#confirm').addEventListener('click', () => {
    if (playerTurn() && pending) void execute(pending).then(scheduleEnemies);
  });
  $('#finish-turn').addEventListener('click', () => {
    if (playerTurn())
      void execute({ kind: 'finish' }).then(() => {
        scheduleEnemies();
        focusActor();
      });
  });
  function restart(): void {
    if (!ready || busy) return;
    generation++;
    state = createBattle(
      catalog,
      $<HTMLInputElement>('#seed').value,
      Number($<HTMLSelectElement>('#variance').value),
    );
    $<HTMLInputElement>('#seed').value = state.seed;
    inspected = 1;
    pending = null;
    hover = null;
    mode = 'move';
    scene.sync(living(state));
    refreshPaths();
    refresh();
    say(`Nuevo combate: semilla ${state.seed}.`);
    scheduleEnemies();
  }
  $('#battle-settings').addEventListener('submit', (event) => {
    event.preventDefault();
    restart();
    $<HTMLDetailsElement>('#game-options').open = false;
  });
  $('#play-again').addEventListener('click', restart);
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
  scene.sync(living(state));
  refreshPaths();
  refresh();
  const game = startGame(scene, { width: 512, height: 512 });
  import.meta.hot?.dispose(() => {
    generation++;
    document.removeEventListener('keydown', onEscape);
    document.removeEventListener('pointerdown', closeOptions);
    preference.removeEventListener('change', motionChanged);
    game.destroy(true);
  });
}
async function boot(): Promise<void> {
  try {
    const response = await fetch(asset('data/pokemon.json'), {
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok)
      throw new Error(`No se pudo cargar el catálogo (${response.status}).`);
    const catalog = validateCatalog(await response.json());
    await document.fonts.load('16px "Pixelify Sans"');
    render(catalog);
  } catch (error) {
    app.innerHTML = `<main class="failure"><h1>No pudimos abrir el combate</h1><p>${escape(error instanceof Error ? error.message : 'Error de recursos locales.')}</p><button id="retry">Volver a intentar</button></main>`;
    document
      .querySelector('#retry')!
      .addEventListener('click', () => location.reload());
  }
}
void boot();
