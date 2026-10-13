import './tactical.css';
import './battle.css';
import { validateCatalog, TYPE_NAMES } from './data/catalog';
import type { PokemonSpecies } from './data/catalog';
import { pokemonFor } from './domain/Pokemon';
import { STATUS_NAMES, effectiveSpeed, movementBudget } from './domain/combatant';
import type { Combatant } from './domain/combatant';
import type { Composition } from './rules/battle';
import { BoardScene } from './game/BoardScene';
import { startGame } from './game/main';
import {
  key,
  same,
  coordinate,
  TERRAIN,
  routesFrom,
  planMove,
  tileCost,
} from './rules/movement';
import type { Point, Route, Facing } from './rules/movement';
import { FACINGS, FACING_ARROWS, FACING_NAMES, SIDE_NAMES } from './rules/position';
import { PROFILE_NAMES, fieldDamage } from './rules/terrain';
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
  let selectedAction = 'basic';
  const statusText = (unit: Combatant): string => `${unit.status ? `${STATUS_NAMES[unit.status.kind]} · ${unit.status.remaining} activaciones` : 'Sin estado'}${unit.guarded ? ' · Protegido' : ''}`;
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
        <header class="game-topbar"><h1 id="game-title">POKÉMON <span>TACTICS</span></h1><div class="battle-counts"><span id="ally-count"></span><span id="enemy-count"></span></div><button class="hud-utility" id="pause" aria-pressed="${paused}" disabled>${paused ? 'Reanudar' : 'Pausar'} animaciones</button><details id="game-options"><summary>Opciones</summary><div class="options-panel"><h2>Opciones de combate</h2><form id="battle-settings"><label for="seed">Semilla<input id="seed" name="seed" maxlength="64" value="kanto-001" autocomplete="off"></label><label for="variance">Variación<select id="variance"><option value="0.05">±5 %</option><option value="0.1">±10 %</option></select></label><label class="composition-setting" for="composition">Composición<select id="composition"><option value="starters">Iniciales: Bulbasaur, Charmander, Squirtle</option><option value="mixed">Control: Pikachu, Butterfree, Geodude</option></select></label><p>Los cambios se aplican al reiniciar. PT: 2 iniciales, +1 al activar, máximo 5. Estados: tres activaciones propias.</p><button id="restart" type="submit" disabled>Reiniciar combate</button></form><section class="training-roster battle-roster" aria-label="Unidades del combate">${state.units.map((u) => `<button data-unit="${u.id}" data-team="${u.team}" aria-pressed="false"><img src="${asset(`assets/pokemon/${u.id}/thumbnail.png`)}" alt="" width="32" height="32"><span><strong>${escape(u.name)}</strong><small data-unit-info="${u.id}"></small></span></button>`).join('')}</section><nav class="battle-nav" aria-label="Prototipos"><a href="?view=training">Ensayo de movimiento</a><a href="?view=camp">Campamento</a><a href="${asset('CREDITS.md')}" target="_blank" rel="noreferrer">Créditos y licencias</a></nav><details class="battle-log"><summary>Registro de combate</summary><ol id="combat-log"></ol></details></div></details></header>
        <section class="initiative-strip" aria-labelledby="initiative-title"><div class="round-label"><h2 id="initiative-title">Ronda <span id="round"></span></h2><span>CHARCA DE KANTO</span></div><ol id="initiative"></ol></section>
        <div id="resource-status" class="game-resource" role="status">Cargando recursos…</div>
        <section class="battlefield" aria-label="Tablero de combate">
          <div class="board-shell"><div id="game-container" aria-hidden="true"></div><div id="board-grid" role="grid" aria-label="Tablero de combate" aria-rowcount="8" aria-colcount="8" aria-describedby="board-help">${state.board.map((row, y) => `<div role="row">${row.map((_, x) => `<button role="gridcell" data-cell="${x},${y}" tabindex="${y * 8 + x === cursor ? 0 : -1}" disabled></button>`).join('')}</div>`).join('')}</div><div id="battle-result" hidden><h2 id="result-title" tabindex="-1"></h2><p id="result-description"></p><button id="play-again">Volver a combatir</button></div></div>
          <div class="terrain-legend"><span>A · Aliado</span><span>E · Enemigo</span><span>Suelo 1 / maleza 2</span><span>Roca bloquea · agua: acuáticos/voladores</span><span>Aliados atravesables · ↑ orientación</span></div>
        </section>
        <div class="hud-bottom">
          <aside class="actor-hud hud-window" aria-label="Unidad activa"><div class="hud-unit-heading"><img id="actor-portrait" src="${asset(`assets/pokemon/${activeUnit(state)!.id}/thumbnail.png`)}" alt="" width="72" height="72"><div><p id="turn-owner"></p><h2 id="actor-name"></h2><p id="turn-status"></p></div></div><div class="hud-health"><strong id="actor-hp"></strong><div id="actor-health" class="health-track" aria-hidden="true"></div></div><div class="activation-resources"><span id="move-available"></span><span id="action-available"></span><strong id="actor-tp"></strong></div><p id="actor-stats"></p><p id="actor-status" class="unit-status"></p></aside>
          <section class="orders-hud" aria-label="Órdenes de combate"><div class="battle-actions"><button id="mode-move" aria-pressed="true">Mover</button><button id="mode-attack" aria-pressed="false">Acciones</button><button id="finish-turn" disabled>Terminar turno</button></div><div id="facing-controls" aria-label="Orientación final" hidden>${FACINGS.map(facing => `<button data-facing="${facing}" aria-pressed="false">${FACING_ARROWS[facing]} ${FACING_NAMES[facing]}</button>`).join('')}</div><div class="skill-actions" aria-label="Habilidades de la unidad activa"><button data-skill-slot="0" aria-pressed="true"></button><button data-skill-slot="1" aria-pressed="false"></button><button data-skill-slot="2" aria-pressed="false"></button></div><p id="ability-description"></p><div class="order-preview"><div id="attack-forecast" hidden><span>DAÑO <strong id="forecast-damage"></strong></span><span>ACIERTO <strong id="forecast-accuracy"></strong></span></div><p id="forecast-effect"></p><p id="order-summary">Espera tu turno.</p><p id="order-detail"></p><div class="order-buttons"><button id="confirm" disabled>Confirmar orden</button><button id="cancel" disabled>Cancelar</button></div></div><p id="feedback" role="status" aria-live="polite">Cargando el combate…</p></section>
          <aside class="target-hud hud-window" aria-labelledby="inspect-name"><p class="target-label">FICHA CONSULTADA</p><div class="hud-unit-heading"><img id="inspect-portrait" src="${asset(`assets/pokemon/${inspected}/thumbnail.png`)}" alt="" width="64" height="64"><div><h3 id="inspect-name"></h3><span id="inspect-team"></span><div id="inspect-types" class="type-list"></div></div></div><div class="health-readout"><strong id="inspect-hp"></strong><span id="inspect-position"></span></div><div id="inspect-health" class="health-track" aria-hidden="true"></div><p id="inspect-stats"></p><p id="inspect-status" class="unit-status"></p><ul id="area-forecast" aria-label="Unidades afectadas por el área" hidden></ul></aside>
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
    const forecast = pending?.kind === 'attack' ? attackPlan(state, pending.target, undefined, pending.actionId) : null;
    const area = new Set(forecast?.ok ? forecast.tiles.map(key) : []);
    const push = forecast?.ok ? forecast.push : null;
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
        pending?.kind !== 'finish' &&
        !state.moved &&
        !unit &&
        (routes.get(key(p))?.cost ?? Infinity) <= actor.remaining;
      const attackable =
        !!unit && playerTurn() && pending?.kind !== 'finish' && !state.acted && attackPlan(state, unit.id, undefined, selectedAction).ok;
      button.disabled = !ready || busy;
      button.className = `tile ${unit ? 'occupied team-' + unit.team : ''} ${unit && actor && unit.id === actor.id ? 'active-unit' : ''} ${unit?.id === inspected ? 'inspected' : ''} ${mode === 'move' && reachable ? 'can-reach' : ''} ${mode === 'attack' && attackable ? 'can-attack' : ''} ${costs.has(key(p)) ? 'path-tile' : ''} ${destination && same(p, destination) && route && route.cost <= actor!.remaining ? 'destination' : ''} ${pending?.kind === 'attack' && pending.target === unit?.id ? 'attack-target' : ''} ${area.has(key(p)) ? 'effect-area' : ''} ${push && same(push, p) ? 'push-destination' : ''} ${state.fields.some(field => same(field, p)) ? 'ember-tile' : ''}`;
      button.setAttribute(
        'aria-selected',
        String(!!unit && unit.id === inspected),
      );
      button.setAttribute(
        'aria-label',
        `${coordinate(p)}, ${terrain.name}${unit ? `, ${unit.name}, ${unit.team === 'ally' ? 'aliado' : 'enemigo'}, ${unit.hp} de ${unit.maxHp} PS, ${statusText(unit)}, mira al ${FACING_NAMES[unit.facing]}` : ''}${unit && actor && unit.id === actor.id ? ', turno activo' : ''}${reachable ? `, alcanzable, coste ${routes.get(key(p))!.cost}` : ''}${attackable ? ', objetivo válido' : ''}${area.has(key(p)) ? ', área de efecto' : ''}${state.fields.some(field => same(field, p)) ? ', ascuas: daño al cerrar turno' : ''}${push && same(push, p) ? ', destino del empuje' : ''}`,
      );
      button.innerHTML = `<span class="tile-coordinate">${coordinate(p)}</span>${unit ? `<span class="team-marker" aria-hidden="true">${unit.team === 'ally' ? 'A' : 'E'}</span><span class="tile-unit">${escape(unit.name)}</span><span class="tile-health" aria-hidden="true"><i style="width:${(unit.hp / unit.maxHp) * 100}%"></i></span>` : ''}${costs.has(key(p)) ? `<span class="path-cost">${costs.get(key(p))}</span>` : ''}`;
      if (unit) {
        const facing = pending?.kind === 'finish' && unit.id === actor?.id ? pending.facing ?? unit.facing : unit.facing;
        button.insertAdjacentHTML('beforeend', `<span class="facing-marker ${pending?.kind === 'finish' && unit.id === actor?.id ? 'facing-preview' : ''}" aria-hidden="true">${FACING_ARROWS[facing]}</span>`);
      }
    });
  }
  const tileCostAt = (p: Point) =>
    tileCost(state.board, p, activeUnit(state)?.profile);
  function refresh(): void {
    const actor = activeUnit(state),
      canOrder = playerTurn(),
      root = $('#battle-root');
    if (actor && !pokemonFor(actor.id).action(selectedAction)) selectedAction = 'basic';
    root.dataset.active = String(actor?.id ?? '');
    root.dataset.team = actor?.team ?? '';
    root.dataset.round = String(state.round);
    root.dataset.outcome = state.outcome;
    root.dataset.busy = String(busy);
    root.dataset.moved = String(state.moved);
    root.dataset.acted = String(state.acted);
    root.dataset.fields = JSON.stringify(state.fields);
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
      `${pokemonFor(actorCard.id).role} · ${PROFILE_NAMES[actorCard.profile ?? 'ground']} · mira al ${FACING_NAMES[actorCard.facing]} · velocidad ${effectiveSpeed(actorCard)}`;
    $('#actor-tp').textContent = `PT ${actorCard.tp}/${actorCard.maxTp}`;
    $('#actor-status').textContent = statusText(actorCard);
    $('#actor-health').innerHTML =
      `<i style="width:${(actorCard.hp / actorCard.maxHp) * 100}%"></i>`;
    $('#move-available').textContent = actor
      ? state.moved
        ? 'Desplazamiento usado'
        : `Movimiento ${actor.remaining}/${movementBudget(actor)}`
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
    document.querySelectorAll<HTMLButtonElement>('[data-skill-slot]').forEach((button, index) => {
      const ability = pokemonFor(actorCard.id).actions[index].definition;
      button.dataset.action = ability.id;
      button.textContent = `${ability.name} · ${ability.cost} PT`;
      button.title = `${TYPE_NAMES[ability.type]} · alcance ${ability.range} · acierto ${ability.accuracy} %`;
      button.disabled = !canOrder || state.acted || actorCard.tp < ability.cost;
      button.setAttribute('aria-pressed', String(mode === 'attack' && selectedAction === ability.id));
    });
    const selected = pokemonFor(actorCard.id).action(selectedAction)?.definition;
    $('#ability-description').textContent = selected
      ? `${TYPE_NAMES[selected.type]} · alcance ${selected.range} · ${selected.description}` : '';
    $<HTMLButtonElement>('#confirm').disabled = !canOrder || !pending;
    $<HTMLButtonElement>('#cancel').disabled = !canOrder || !pending;
    $<HTMLButtonElement>('#finish-turn').disabled = !canOrder;
    $<HTMLButtonElement>('#restart').disabled = !ready || busy;
    $<HTMLButtonElement>('#play-again').disabled = !ready || busy;
    $<HTMLButtonElement>('#pause').disabled = !ready;
    $('.order-buttons').hidden = !pending;
    $('#facing-controls').hidden = pending?.kind !== 'finish';
    $('.skill-actions').hidden = pending?.kind === 'finish';
    $('#ability-description').hidden = pending?.kind === 'finish';
    document.querySelectorAll<HTMLButtonElement>('#facing-controls [data-facing]').forEach(button => {
      button.disabled = !canOrder;
      button.setAttribute('aria-pressed', String(pending?.kind === 'finish' && (pending.facing ?? actor?.facing) === Number(button.dataset.facing)));
    });
    $('#area-forecast').innerHTML = '';
    $('#area-forecast').hidden = true;
    $('#attack-forecast').hidden = pending?.kind !== 'attack';
    $('#forecast-effect').hidden = pending?.kind !== 'attack';
    if (pending?.kind === 'finish' && actor) {
      const facing = pending.facing ?? actor.facing;
      $('#order-summary').textContent = `Orientarse al ${FACING_NAMES[facing]} y terminar`;
      $('#order-detail').textContent = `Frente: −15 puntos de precisión; flanco: −5; espalda: precisión base. ${fieldDamage(actor, state.fields) ? `Ascuas: perderá ${fieldDamage(actor, state.fields)} PS al cerrar turno.` : 'Elige una dirección y confirma.'}`;
      $('#confirm').textContent = 'Confirmar orientación';
    } else if (pending?.kind === 'move' && actor) {
      const route = routes.get(key(pending.destination))!;
      $('#order-summary').textContent =
        `${coordinate(actor)} → ${coordinate(pending.destination)} · ${route.cost} puntos`;
      $('#order-detail').textContent = route.path.map(coordinate).join(' → ');
      $('#confirm').textContent = 'Confirmar movimiento';
    } else if (pending?.kind === 'attack') {
      const targetId = pending.target;
      const target = state.units.find((u) => u.id === targetId)!;
      const plan = attackPlan(state, target.id, undefined, pending.actionId);
      $('#forecast-damage').textContent = plan.ok ? String(plan.damage) : '—';
      $('#forecast-accuracy').textContent = plan.ok ? `${plan.accuracy} %` : '—';
      $('#forecast-effect').textContent = plan.ok
        ? `${plan.cost} PT · ${plan.category === 'physical' ? 'Físico' : plan.category === 'special' ? 'Especial' : 'Apoyo/estado'}${plan.category !== 'status' ? ` · eficacia ×${plan.multiplier}${plan.stab > 1 ? ' · afinidad ×1,5' : ''}` : ''}${plan.side ? ` · ${SIDE_NAMES[plan.side]}` : ''}` : '';
      $('#order-summary').textContent = `${plan.ok ? plan.name : 'Acción'} → ${target.name}`;
      $('#order-detail').textContent = plan.ok
        ? `${plan.guard ? 'Mitad de daño hasta su próxima activación' : `Si acierta: ${target.hp} → ${target.hp - plan.damage} PS`}${plan.heal ? ` · recupera ${plan.heal} PS` : ''}${plan.status ? ` · ${STATUS_NAMES[plan.status.kind]} ${plan.status.chance} % al acertar, ${plan.status.duration} activaciones` : ''}${plan.statusReason ? ` · ${plan.statusReason}` : ''}${plan.damage === target.hp ? ' · fuera de combate' : ''}${plan.push ? ` · empuje a ${coordinate(plan.push)}` : ''}${plan.pushReason ? ` · ${plan.pushReason}` : ''}${plan.embers.length ? ' · deja ascuas: 4 PS al cerrar turno' : ''}`
        : plan.reason;
      $('#confirm').textContent = 'Confirmar ataque';
      if (plan.ok && plan.tiles.length > 1) {
        $('#area-forecast').hidden = false;
        $('#area-forecast').innerHTML = `<li><strong>Área en cruz · incluye aliados</strong></li>${plan.hits.map(hit => {
          const affected = state.units.find(unit => unit.id === hit.targetId)!;
          return `<li class="${affected.team === actor?.team ? 'collateral' : ''}">${escape(affected.name)}${affected.team === actor?.team ? ' · ALIADO' : ''}: ${hit.damage} PS · ${hit.accuracy} %${hit.status ? ` · ${STATUS_NAMES[hit.status.kind]} ${hit.status.chance} % al acertar` : ''}${hit.statusReason ? ` · ${escape(hit.statusReason)}` : ''}</li>`;
        }).join('')}`;
      }
    } else {
      $('#order-summary').textContent = !actor
        ? 'La batalla ha terminado.'
        : !canOrder
          ? 'El enemigo está actuando.'
          : state.moved && state.acted
            ? 'Activación completa.'
            : mode === 'move'
              ? 'Elige un destino resaltado.'
              : 'Elige un objetivo resaltado.';
      $('#order-detail').textContent = actor
        ? `Puedes mover y usar una acción en cualquier orden.`
        : '';
      $('#confirm').textContent = 'Confirmar orden';
    }
    const selectedTarget = pending?.kind === 'attack' ? pending.target : inspected;
    const unit = state.units.find((u) => u.id === selectedTarget)!;
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
      `AT ${unit.attack} / DF ${unit.defense} · AE ${unit.specialAttack} / DE ${unit.specialDefense} · PT ${unit.tp}/${unit.maxTp}`;
    $('#inspect-status').textContent = statusText(unit);
    $('#inspect-status').textContent += ` · ${FACING_ARROWS[unit.facing]} ${FACING_NAMES[unit.facing]}${fieldDamage(unit, state.fields) ? ' · Ascuas: 4 PS al cerrar turno' : ''}`;
    unitButtons.forEach((button) => {
      const unit = state.units.find(
        (u) => u.id === Number(button.dataset.unit),
      )!;
      button.disabled = !ready || busy;
      button.setAttribute('aria-pressed', String(unit.id === inspected));
      button.dataset.hp = String(unit.hp);
      button.dataset.team = unit.team;
      button.dataset.tp = String(unit.tp);
      button.dataset.status = unit.status?.kind ?? '';
      button.dataset.duration = String(unit.status?.remaining ?? 0);
      button.dataset.guarded = String(unit.guarded);
      button.dataset.facing = String(unit.facing);
      button.dataset.profile = unit.profile ?? 'ground';
      button.dataset.remaining = String(unit.remaining);
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
      if (pending?.kind === 'finish') { refresh(); return; }
      const actor = activeUnit(state)!;
      hover = null;
      pending = null;
      if (unit && (mode === 'attack' || unit.team !== actor.team)) {
        const plan = attackPlan(state, unit.id, undefined, selectedAction);
        if (plan.ok) {
          pending = { kind: 'attack', target: unit.id, actionId: selectedAction };
          mode = 'attack';
          say(`${plan.name} sobre ${unit.name}: confirma o cancela.`);
        } else say(plan.reason);
      } else if (!unit) {
        if (mode === 'attack') {
          say('Elige una unidad compatible con la habilidad seleccionada.');
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
  document.querySelectorAll<HTMLButtonElement>('[data-skill-slot]').forEach(button => {
    button.addEventListener('click', () => {
      selectedAction = button.dataset.action!;
      mode = 'attack';
      pending = null;
      hover = null;
      refresh();
    });
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
    if (command.kind === 'attack') for (const hit of result.hits ?? []) {
      if (hit.hit && hit.damage > 0) await scene.hit(hit.targetId, preference.matches || paused);
      if (hit.push) await scene.move(hit.targetId, [state.units.find(unit => unit.id === hit.targetId)!, hit.push], preference.matches || paused);
    }
    if (token !== generation) return;
    state = result.state;
    busy = false;
    scene.sync(living(state));
    scene.showFields(state.fields);
    refreshPaths();
    if (state.moved) mode = 'attack';
    if (state.acted) mode = 'move';
    if (command.kind === 'finish') {
      mode = 'move';
      selectedAction = 'basic';
      inspected = activeUnit(state)?.id ?? inspected;
    }
    refresh();
    say(state.log[state.log.length - 1]);
    if (state.outcome !== 'playing') $('#result-title').focus();
    else if (command.kind === 'finish') focusActor();
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
    if (!playerTurn()) return;
    pending = { kind: 'finish', facing: activeUnit(state)!.facing };
    hover = null;
    refresh();
    document.querySelector<HTMLButtonElement>('#facing-controls [data-facing][aria-pressed="true"]')!.focus();
    say('Elige la orientación final y confirma para ceder el turno. Cancelar conserva la dirección anterior.');
  });
  document.querySelectorAll<HTMLButtonElement>('#facing-controls [data-facing]').forEach(button => button.addEventListener('click', () => {
    if (!playerTurn() || pending?.kind !== 'finish') return;
    pending = { kind: 'finish', facing: Number(button.dataset.facing) as Facing };
    refresh();
  }));
  function restart(): void {
    if (!ready || busy) return;
    generation++;
    state = createBattle(
      catalog,
      $<HTMLInputElement>('#seed').value,
      Number($<HTMLSelectElement>('#variance').value),
      $<HTMLSelectElement>('#composition').value as Composition,
    );
    $<HTMLInputElement>('#seed').value = state.seed;
    inspected = state.units.find(unit => unit.team === 'ally')!.id;
    pending = null;
    hover = null;
    mode = 'move';
    selectedAction = 'basic';
    scene.sync(living(state));
    scene.showFields(state.fields);
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
  scene.showFields(state.fields);
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
