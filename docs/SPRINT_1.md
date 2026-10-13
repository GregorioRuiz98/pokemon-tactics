# Sprint 1 — Tablero y desplazamiento

Estado: **completado técnicamente**, 13 de octubre de 2026. Versión 0.1.0, rama `codex/sprint-1`. Pendiente de impresión del usuario sobre control y legibilidad; sprint 2 todavía no iniciado.

## Entrega

- Tablero 8×8 con suelo, maleza, rocas y agua; seis unidades de ensayo con posiciones fijas.
- Selección por tablero o lista, ficha de datos reales y casillas alcanzables.
- Búsqueda de caminos reutilizada de EasyStar 0.4.4, con costes y ocupación. Sin diagonales ni paso a través de otras unidades.
- Trayectoria previa al señalar un destino, coste acumulado por casilla y confirmación/cancelación explícitas. Se revalida la orden al confirmar.
- Desplazamiento animado con orientación cardinal, bloqueo de nuevas órdenes durante el recorrido, pausa/reanudación y opción de movimiento reducido.
- Presupuesto por unidad, varias órdenes hasta agotarlo y reinicio de posiciones/presupuestos.
- Cuadrícula accesible por teclado: flechas, Enter/Espacio, Escape y foco visible. El foco vuelve a la casilla de destino.
- Campamento del sprint 0 conservado en `?view=camp`, con selección y animaciones.
- Prueba de navegador reproducible en `tools/browser-sprint1.cjs`; Playwright es una dependencia de desarrollo.

## Verificación ejecutada

| Comprobación | Resultado |
| --- | --- |
| `npm.cmd test` | 12 pruebas aprobadas: 6 de catálogo y 6 de movimiento |
| Reglas de navegación | Desvío con menor coste, obstáculos, ocupación, esquinas sin diagonal, límites y destino sin camino |
| Integridad del estado | Previsualizar no altera unidades; confirmar descuenta puntos; órdenes antiguas se revalidan |
| `npm.cmd run verify:assets` | 6 especies, 12 hojas y 33 hashes originales verificados |
| `npm.cmd run build` | Correcta; incluye TypeScript sin errores |
| `node tools/browser-sprint1.cjs` | 18 comprobaciones aprobadas en Edge headless con Playwright; `qa/sprint-1/browser-results.json` |
| Flujo de navegador | Selección de seis unidades, trayectoria/cancelación, destinos inválidos, gasto acumulado, agotamiento, cuatro orientaciones y reinicio |
| Accesibilidad de interacción | Flechas y Enter completan el movimiento; Escape cancela desde cuadrícula y controles; foco visible y movimiento reducido comprobados |
| Pausa | Reposo queda estático; desplazamiento admite pausa y continúa al reanudar |
| Estados de recursos | Carga lenta, catálogo vacío/error con recuperación y hoja ausente con marcador funcional y recarga |
| Vistas | 1440×1000, 900×1000 y 390×844 sin desbordamiento horizontal; capturas de escritorio/móvil revisadas |
| Visitas correctas | Sin errores JavaScript/consola, solicitudes externas ni miniaturas rotas |
| Producción local | Tablero, ruta B6→B4 de coste 3 y acceso al campamento comprobados en `127.0.0.1:4173`; `qa/sprint-1/production-results.json` |
| Acabado | Detector de Impeccable sin hallazgos; capturas `desktop-route.png` y `mobile-route.png` revisadas |

La primera ejecución de la prueba de recuperación se detuvo por consultar un elemento antes de que existiera tras la recarga. Se corrigió la espera de la prueba; la ejecución completa posterior pasó. No hay linter ni cobertura configurados, ni se presentan como ejecutados.

## Probar en local

Arrancar con `npm.cmd ci` y `npm.cmd run dev`; abrir `http://127.0.0.1:5173/`.

1. Bulbasaur empieza en B6 con 4 puntos. Señalar B4 muestra B6→B5→B4: maleza 2 + suelo 1 = 3.
2. Elegir B4 y cancelar conserva posición y presupuesto. Repetir y confirmar deja a Bulbasaur en B4 con 1 punto.
3. Moverlo a A4 consume el punto restante. Una nueva orden se rechaza.
4. Reiniciar restaura el ensayo; seleccionar H1 permite comprobar un destino sin camino.
5. Probar el mismo recorrido con teclado y el enlace al campamento.

En otra terminal, con el servidor activo, `npm.cmd run test:browser` ejecuta la prueba reproducible. Requiere Edge en Windows o Chromium instalado para Playwright en otros sistemas; detalles en README.

## Recursos reutilizados y límites

Se mantienen todos los sprites, miniaturas, fuente y datos del sprint 0. EasyStar y su dependencia heap se incluyen con versiones fijas, integridad del registro npm y licencias locales; atribución en CREDITS.md. No se han descargado más especies ni un catálogo de terrenos.

Todas las unidades usan perfil terrestre; presupuesto 3 para Geodude, 5 para Pikachu y 4 para el resto. Son valores de ensayo. Volar, afinidades de terreno y balance definitivo siguen pendientes.

No hay rondas, iniciativa, combate, enemigos, daño ni progreso de run en esta entrega. El objetivo era validar el control del desplazamiento. El presupuesto solo se recupera al reiniciar el ensayo.

Phaser sigue generando el aviso conocido de tamaño de bloque (aproximadamente 1,66 MB sin comprimir, 374 kB gzip). Solo se ha probado Edge/Chromium; Firefox, Safari, dispositivos móviles reales y lector de pantalla quedan pendientes. La vista de 390 px comprueba presentación e interacción básica, no garantiza todavía el soporte móvil final.

## Próximo sprint

Sprint 2: rondas, iniciativa por velocidad con varianza y combate básico 3 contra 3. Reutilizar las reglas de navegación; conservar la semilla para reproducir resultados. Iniciar únicamente cuando se solicite.
