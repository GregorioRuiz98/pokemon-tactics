# Sprint 4 — Posición y terreno táctico

14 de octubre de 2026. Versión **0.4.0**, rama `codex/sprint-4`.

## Entrega

- Orientación final manual: Terminar turno abre cuatro direcciones y Confirmar orientación. La elección se previsualiza y se conserva al pasar a otras unidades; cancelar mantiene el estado y no consume aleatoriedad. Flecha cardinal visible en cada unidad.
- Precisión por frente, flanco y espalda, aplicada también a cada afectado por área. La previsión indica el ángulo y la precisión final.
- Rutas que atraviesan aliados, con destino siempre libre y enemigos bloqueando. Previsión, confirmación e IA comparten EasyStar y sus costes. El movimiento vuelve a validar ocupación al confirmar.
- Perfiles terrestres, de hierba, acuáticos y voladores. Bulbasaur atraviesa maleza por 1; Squirtle cruza agua por 1; Butterfree cruza agua y maleza por 1. Roca sigue siendo obstáculo para todos. Las estadísticas, sprites y especies son los ya importados.
- Mapa Charca de Kanto 8×8 con agua central, paso terrestre, maleza y obstáculos. Se conservan ambas composiciones de prueba y el ensayo anterior.
- Lanzallamas y Polvo Veneno afectan una cruz; incluyen aliados, excluyen al lanzador y resuelven cada unidad una sola vez. Lanzarrocas empuja una casilla si el objetivo sobrevive y el destino es legal. La previsión muestra daños a aliados y destinos/impedimentos de empuje.
- Lanzallamas deja ascuas sobre suelo y maleza. Se dibujan con primitivas de Phaser, sin assets nuevos; el HUD expone su riesgo.
- IA valora daños según tipos, precisión y área, penaliza daño a aliados, usa costes del perfil, evita acabar sobre aliados y compara exposición/ascuas. Puede retirarse después de actuar y elige orientación defensiva. No muestra órdenes futuras ni consume tiradas al decidir.

## Reglas provisionales para probar

- Precisión final: base −15 puntos porcentuales de frente, −5 de flanco y base por espalda; limitada a 5–100 %. Un básico de 100 % queda en 85/95/100 %. No cambia el daño por ángulo.
- La proyección del atacante sobre el eje hacia el que mira el defensor decide el ángulo. Si domina el eje perpendicular, es flanco. En un empate diagonal manda el eje de orientación: frente o espalda. La regla no contiene tiradas.
- Todas las acciones conservan alcance Manhattan 0/1/2. Agua y maleza dejan pasar disparos; roca y unidades intermedias los bloquean. Para una diagonal de alcance 2 se requieren libres ambas esquinas. Cruz: centro y cuatro adyacentes, descartando roca y límites. El agua puede recibir el ataque de área, pero no ascuas.
- La precisión se tira por afectado en orden estable de ID. Las inmunidades y estados se calculan individualmente; PT y acción se gastan una vez. La potencia de Lanzallamas pasa de 90 a 70 para probar su nueva área. Son adaptaciones tácticas, pendientes de equilibrio.
- Empuje de una casilla por el eje dominante entre atacante y objetivo; empate diagonal horizontal. No cambia la orientación del empujado, no atraviesa ocupantes, no provoca daño de choque y no se ejecuta si falla, hay inmunidad o el objetivo cae por daño. El perfil del objetivo determina si puede aterrizar en agua.
- Ascuas: 4 PS al terminar la activación sobre la casilla; Fuego y voladores no reciben ese daño. No se acumulan, se renuevan al lanzar otra área y desaparecen al comenzar la ronda R+2 respecto al lanzamiento. Se crean incluso si fallan las tiradas del área. Guardar protección no reduce el daño de terreno.
- Si se agotan puntos al cruzar un aliado, la IA elige la última casilla libre alcanzada; nunca confirma una casilla ocupada. Las unidades del ensayo, que no tienen bando/perfil táctico, conservan su ocupación y coste anteriores.

## Recursos y estructura

Se reutilizan EasyStar, Phaser, la tabla local de PokéAPI, los seis sprites y los escenarios de QA previos. No se añaden dependencias, descargas, cuentas ni servicios. `AreaDamageAction`, `AreaStatusAction` y `PushAction` amplían las acciones de POO. Posición y terreno están en `src/rules/position.ts` y `terrain.ts`, separados del dibujo. `Battle.fields` sigue siendo serializable.

## Comprobaciones

| Comprobación | Resultado |
| --- | --- |
| Dominio/reglas/datos | 49 pruebas aprobadas, incluidas 35 anteriores y 14 de tácticas |
| Simulaciones | 20 escenarios, dos composiciones y variación 5/10 %; cada uno repetido exactamente, sin solapamientos ni terreno inválido |
| TypeScript y build | Correctos; permanece el aviso conocido del tamaño de Phaser |
| Integridad | 33 hashes originales y 2 CSV de tipos verificados; sin modificar sprites |
| Navegador de desarrollo | 19 comprobaciones aprobadas |
| Producción local | Las mismas 19 comprobaciones aprobadas contra la compilación final en 4173 |
| Ensayo de movimiento | 18 comprobaciones de regresión aprobadas |

Las comprobaciones de navegador comparan PS, posición, PT, estados, presupuesto restante, orientación, perfil y campos con las reglas tras cada orden. Incluyen orientación/cancelación/foco, área, tránsito aliado, agua, empuje real, victorias/derrotas, repetición, recursos lentos/erróneos y marcadores cuando falta un sprite. Evidencia en `docs/qa/sprint-4`. No hay linter ni cobertura configurados; no se ejecutó una auditoría WCAG completa. Solo Edge/Chromium probado.

Capturas de escritorio y móvil revisadas; la prueba comprueba previsiones activas en 1440×1000, 1280×768, 900×1000 y 390×844. La QA detectó un selector de orientación que coincidía también con fichas de unidades: se limitó a `#facing-controls`, se verificó el foco y se repitió la prueba. Las nuevas rutas requirieron que la prueba se aproximara legalmente antes de seleccionar un área.

## Feedback y alcance

La prueba con política determinista y `kanto-001` da victoria de Iniciales en 2 rondas y derrota de Control en 2. Esperar con Iniciales y `portfolio`, ±10 %, da derrota en 4. Son pruebas de funcionamiento; el mapa, el daño de área y la diferencia entre equipos requieren valoración del jugador.

Entrega completada técnicamente. Pendiente de feedback: probar al menos dos aproximaciones al agua y al paso terrestre, orientar para proteger la espalda y decidir cuándo un área compensa el riesgo a aliados. Sprint 5 permanece pendiente: ruta, PS persistentes, inicio aleatorio y guardado. No se inicia automáticamente.

Feedback posterior del usuario: las bajas son demasiado rápidas para el 3v3 actual. Pide mantener por ahora los parámetros y el juego tal como están, hasta definir mejor el diseño. Revisar o sustituir movimientos tempranos demasiado potentes, especialmente Lanzallamas en Charmander, queda como opción futura; no se implementa ni se modifica el equilibrio por este feedback.
