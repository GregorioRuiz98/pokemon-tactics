# Balance nativo 0.22 · ensayo automático

Se ejecutaron 29 recorridos con las reglas reales: 24 arranques (las mismas ocho semillas para cada inicial) y cinco campañas extendidas. No se descartan derrotas. La estrategia automática comparte la IA de combate con el rival; compra curación, Revivir y niveles, prepara cuatro movimientos y usa el PC. Antes de la Liga entrena principalmente tres miembros; después prepara seis con cobertura entre los Pokémon que realmente posee. No compra MT ni equipables. No se modifica dinero, equipo, azar o estadísticas para conseguir victorias.

El arranque conserva una política deliberadamente sencilla: curar, sin comprar niveles ni cambiar movimientos en las primeras cuatro zonas. Las cifras comparan este bot bajo condiciones fijas; **no estiman la probabilidad de victoria de una persona** ni la diversión. Los recorridos completos usan una sola semilla por configuración, por lo que tampoco permiten inferencia estadística sobre la campaña.

## Arranque hasta Brock

| Inicial | Brock derrotado | Derrotas antes de Brock | Derrotas en Brock | Órdenes medianas |
| --- | ---: | ---: | ---: | ---: |
| Bulbasaur | 4/8 | 3/8 | 1/8 | 208.5 |
| Charmander | 0/8 | 7/8 | 1/8 | 30 |
| Squirtle | 0/8 | 8/8 | 0/8 | 28 |

## Campañas extendidas

| Inicial / mapa / final | Resultado | Último encuentro | Medallas | Bajas acumuladas | Caramelos usados | Dinero final |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| Bulbasaur /16 /birds | Final superado | legendary-birds | 8 | 24 | 99 | 6475 ₽ |
| Charmander /16 /birds | Derrota | route-2 | 0 | 2 | 0 | 270 ₽ |
| Squirtle /16 /birds | Derrota | route-1 | 0 | 1 | 0 | 120 ₽ |
| Bulbasaur /16 /psychic | Final superado | legendary-origin | 8 | 22 | 129 | 5785 ₽ |
| Bulbasaur /24 /psychic | Final superado | legendary-origin | 8 | 17 | 95 | 5765 ₽ |

## Ritmo y recursos observados

- 165 combates registrados en los recorridos extendidos; mediana 7 rondas, máximo26. Un combate que supera50 rondas se detiene únicamente en el ensayo y se informa como atasco; el juego no impone ese límite.
- 808/5928 órdenes aliadas de ataque usaron el básico (13.6%). Este denominador también incluye órdenes de apoyo/curación.
- 110/8512 impactos de movimientos ofensivos fallaron (1.3%); se excluyen apoyo y retroceso. Incluye ambos equipos y objetivos múltiples, por lo que no equivale a una precisión universal.
- 4 bajas enemigas de un golpe desde PS completos frente a 683 bajas enemigas totales registradas. No incluye bajas desde PS parcialmente perdidos ni estima todas las situaciones de daño.

| Combates más largos del ensayo extendido | Rondas | Resultado |
| --- | ---: | --- |
| legendary-birds ·Bulbasaur /16 /birds | 26 | victory |
| sabrina ·Bulbasaur /16 /birds | 23 | victory |
| sabrina ·Bulbasaur /16 /psychic | 23 | victory |
| silph-rival ·Bulbasaur /16 /birds | 17 | victory |
| silph-rival ·Bulbasaur /16 /psychic | 17 | victory |
| silph-giovanni ·Bulbasaur /16 /birds | 15 | victory |
| silph-giovanni ·Bulbasaur /16 /psychic | 15 | victory |
| giovanni-gym ·Bulbasaur /16 /birds | 14 | victory |

## Cambios recomendados para la siguiente prueba humana

1. **Priorizar el primer reclutamiento.** Comparar el arranque de los tres iniciales antes de revisar jefes tardíos. Probar, como alternativas separadas, un primer encuentro más seguro o preparar/cubrir mejor al inicial. No se aplican estas propuestas en 0.22.
2. **Reducir tareas repetitivas de tienda.** La preparación automática necesita muchos Caramelos y operaciones. Valorar compra/uso por cantidad, con coste y cap visibles, conservando exactamente la economía. Medir clics y comprensión con una persona antes de cambiar precios.
3. **Revisar IA, recuperación y estancamientos antes de nerfear daño global.** Comparar los encuentros largos con equipos humanos que utilicen MT, equipables, estados y flanqueo. La IA de este ensayo omite parte de esas herramientas y puede valorar mal una situación; una derrota automática no prueba que sea imposible.
4. **Elegir tamaño por decisiones y duración.** La comparación 16/24 usa la misma semilla e inicial para el final psíquico, pero las trayectorias pueden divergir. No se concluye que más casillas impliquen más diversión.
5. **Contrastar la reserva de cinco recuperaciones.** El sprint 21 encontró un ensayo de aves de más de 84 rondas sin límite y otro de 26 con él, con preparación distinta. Motiva evitar recuperación infinita; no demuestra por sí solo que cinco sea el valor óptimo.

No se cambian potencias, precisión, estadísticas generales, precios o tablas de encuentro para mejorar estas cifras. La entrega conserva las reglas de los sprints anteriores mediante su edición. Las 29 habilidades normales pendientes y el arte provisional siguen fuera de una afirmación de acabado final.

## Reproducir y continuar

Desde el repositorio, `npm run godot:simulate:balance` ejecuta los 29 recorridos con Godot 4.7.2 y guarda `work/qa-sprint-22/balance-native.json` fuera de Git. `python tools/godot/report-balance.py` comprueba número de muestras, ausencia de errores y hashes de las fuentes antes de generar este informe. Las semillas, compras, movimientos, encuentros, finales y hashes están en [results.json](results.json). Los diarios de campañas completas se conservan como evidencia local; no son guardados humanos.

Prueba manual pendiente: [guía Windows y sesiones propuestas](../../PLAYTEST_WINDOWS.md). Registrar semilla, inicial, tamaño, encuentro y guardado, especialmente en una derrota temprana o una pelea sin decisiones.
