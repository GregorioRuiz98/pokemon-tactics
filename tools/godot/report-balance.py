"""Summarise the fixed native audit; never change game parameters or omit losses."""
import collections, hashlib, json, pathlib, statistics

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / '../../work/qa-sprint-22/balance-native.json'
TARGET = ROOT / 'docs/reports/balance-native-0.22'
audit = json.loads(SOURCE.read_text(encoding='utf-8'))
assert len(audit['results']) == 29 and not audit['failures'], 'Audit incomplete or contains invalid orders/replays'
for name, expected in audit['sourceSha256'].items():
    assert hashlib.sha256((ROOT/'godot'/name).read_bytes()).hexdigest() == expected, f'Changed source: {name}'
TARGET.mkdir(parents=True, exist_ok=True)
(TARGET/'results.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
names = {1:'Bulbasaur',4:'Charmander',7:'Squirtle'}
opening = [r for r in audit['results'] if r['sample']=='opening']
full = [r for r in audit['results'] if r['sample']=='full']
lines = ['# Balance nativo 0.22 · ensayo automático', '',
 'Se ejecutaron 29 recorridos con las reglas reales: 24 arranques (las mismas ocho semillas para cada inicial) y cinco campañas extendidas. No se descartan derrotas. La estrategia automática comparte la IA de combate con el rival; compra curación, Revivir y niveles, prepara cuatro movimientos y usa el PC. Antes de la Liga entrena principalmente tres miembros; después prepara seis con cobertura entre los Pokémon que realmente posee. No compra MT ni equipables. No se modifica dinero, equipo, azar o estadísticas para conseguir victorias.', '',
 'El arranque conserva una política deliberadamente sencilla: curar, sin comprar niveles ni cambiar movimientos en las primeras cuatro zonas. Las cifras comparan este bot bajo condiciones fijas; **no estiman la probabilidad de victoria de una persona** ni la diversión. Los recorridos completos usan una sola semilla por configuración, por lo que tampoco permiten inferencia estadística sobre la campaña.', '',
 '## Arranque hasta Brock', '',
 '| Inicial | Brock derrotado | Derrotas antes de Brock | Derrotas en Brock | Órdenes medianas |',
 '| --- | ---: | ---: | ---: | ---: |']
opening_summary = []
for starter in names:
    rows=[r for r in opening if r['starter']==starter]
    won=sum('brock' in r['cleared'] for r in rows)
    early=sum(r['phase']=='defeat' and r['lastLocation']!='brock' for r in rows)
    brock=sum(r['phase']=='defeat' and r['lastLocation']=='brock' for r in rows)
    lines.append(f"| {names[starter]} | {won}/8 | {early}/8 | {brock}/8 | {statistics.median(r['orders'] for r in rows):g} |")
    opening_summary.append({'starter':starter,'runs':8,'wonBrock':won,'lostBeforeBrock':early,'lostBrock':brock})
lines += ['', '## Campañas extendidas', '',
 '| Inicial / mapa / final | Resultado | Último encuentro | Medallas | Bajas acumuladas | Caramelos usados | Dinero final |',
 '| --- | --- | --- | ---: | ---: | ---: | ---: |']
for r in full:
    outcome='Límite diagnóstico de 50 rondas' if r.get('stalled') else ('Final superado' if r['phase']=='ending' else ('Derrota' if r['phase']=='defeat' else r['phase']))
    lines.append(f"| {names[r['starter']]} /{r['mapSize']} /{r['path']} | {outcome} | {r['lastLocation']} | {r['medals']} | {r['knockedOut']} | {r['candies']} | {r['money']} ₽ |")
fights=[dict(f, configuration=f"{names[r['starter']]} /{r['mapSize']} /{r['path']}") for r in full for f in r['fights']]
rounds=[f['rounds'] for f in fights]
attacks=sum(r['allyAttacks'] for r in full)
basic=sum(r['allyBasic'] for r in full)
hits=sum(r['hits'] for r in full)
misses=sum(r['misses'] for r in full)
one=sum(r['fullHpOneHitKO'] for r in full)
knocked=sum(f['enemyKO'] for f in fights)
long=sorted(fights,key=lambda f:f['rounds'],reverse=True)[:8]
lines += ['', '## Ritmo y recursos observados', '',
 f'- {len(fights)} combates registrados en los recorridos extendidos; mediana {statistics.median(rounds):g} rondas, máximo{max(rounds)}. Un combate que supera50 rondas se detiene únicamente en el ensayo y se informa como atasco; el juego no impone ese límite.',
 f'- {basic}/{attacks} órdenes aliadas de ataque usaron el básico ({basic/max(attacks,1):.1%}). Este denominador también incluye órdenes de apoyo/curación.',
 f'- {misses}/{hits+misses} impactos de movimientos ofensivos fallaron ({misses/max(hits+misses,1):.1%}); se excluyen apoyo y retroceso. Incluye ambos equipos y objetivos múltiples, por lo que no equivale a una precisión universal.',
 f'- {one} bajas enemigas de un golpe desde PS completos frente a {knocked} bajas enemigas totales registradas. No incluye bajas desde PS parcialmente perdidos ni estima todas las situaciones de daño.', '',
 '| Combates más largos del ensayo extendido | Rondas | Resultado |', '| --- | ---: | --- |']
for f in long: lines.append(f"| {f['id']} ·{f['configuration']} | {f['rounds']} | {f['outcome']} |")
lines += ['', '## Cambios recomendados para la siguiente prueba humana', '',
 '1. **Priorizar el primer reclutamiento.** Comparar el arranque de los tres iniciales antes de revisar jefes tardíos. Probar, como alternativas separadas, un primer encuentro más seguro o preparar/cubrir mejor al inicial. No se aplican estas propuestas en 0.22.',
 '2. **Reducir tareas repetitivas de tienda.** La preparación automática necesita muchos Caramelos y operaciones. Valorar compra/uso por cantidad, con coste y cap visibles, conservando exactamente la economía. Medir clics y comprensión con una persona antes de cambiar precios.',
 '3. **Revisar IA, recuperación y estancamientos antes de nerfear daño global.** Comparar los encuentros largos con equipos humanos que utilicen MT, equipables, estados y flanqueo. La IA de este ensayo omite parte de esas herramientas y puede valorar mal una situación; una derrota automática no prueba que sea imposible.',
 '4. **Elegir tamaño por decisiones y duración.** La comparación 16/24 usa la misma semilla e inicial para el final psíquico, pero las trayectorias pueden divergir. No se concluye que más casillas impliquen más diversión.',
 '5. **Contrastar la reserva de cinco recuperaciones.** El sprint 21 encontró un ensayo de aves de más de 84 rondas sin límite y otro de 26 con él, con preparación distinta. Motiva evitar recuperación infinita; no demuestra por sí solo que cinco sea el valor óptimo.', '',
 'No se cambian potencias, precisión, estadísticas generales, precios o tablas de encuentro para mejorar estas cifras. La entrega conserva las reglas de los sprints anteriores mediante su edición. Las 29 habilidades normales pendientes y el arte provisional siguen fuera de una afirmación de acabado final.', '',
 '## Reproducir y continuar', '',
 'Desde el repositorio, `npm run godot:simulate:balance` ejecuta los 29 recorridos con Godot 4.7.2 y guarda `work/qa-sprint-22/balance-native.json` fuera de Git. `python tools/godot/report-balance.py` comprueba número de muestras, ausencia de errores y hashes de las fuentes antes de generar este informe. Las semillas, compras, movimientos, encuentros, finales y hashes están en [results.json](results.json). Los diarios de campañas completas se conservan como evidencia local; no son guardados humanos.', '',
 'Prueba manual pendiente: [guía Windows y sesiones propuestas](../../PLAYTEST_WINDOWS.md). Registrar semilla, inicial, tamaño, encuentro y guardado, especialmente en una derrota temprana o una pelea sin decisiones.']
(TARGET/'INFORME.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(TARGET/'summary.json').write_text(json.dumps({'runs':29,'failures':audit['failures'],'opening':opening_summary,'extendedRuns':len(full),'fights':len(fights),'medianRounds':statistics.median(rounds),'maximumRounds':max(rounds),'allyBasicFraction':basic/max(attacks,1),'offensiveMissFraction':misses/max(hits+misses,1)},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'runs':29,'opening':opening_summary,'fullOutcomes':[(r['starter'],r['mapSize'],r['path'],r['phase'],r.get('stalled',False)) for r in full]},ensure_ascii=False))
