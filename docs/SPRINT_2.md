# Sprint 2 — Rondas, iniciativa y combate básico

Estado: **completado técnicamente**, 13 de octubre de 2026. Versión 0.2.0, rama `codex/sprint-2`. Pendiente de feedback de juego; sprint 3 todavía no iniciado.

## Entrega

- Combate 3 contra 3 con Bulbasaur, Charmander y Squirtle contra Pikachu, Butterfree y Geodude.
- Cola visible por velocidad real, variación ±5 % o ±10 %, semilla y desempate reproducibles. Una activación por unidad viva y ronda.
- Un desplazamiento continuo y una acción, en ambos órdenes; ruta/ataque se confirman o cancelan. Terminar turno permite esperar o renunciar a recursos pendientes.
- Ataque básico cuerpo a cuerpo/a distancia, previsión de daño, PS, disparos bloqueados, bajas y retirada de ocupación/turnos futuros.
- IA que se acerca, ataca o espera; sin intenciones futuras mostradas. Reinicio invalida órdenes enemigas programadas.
- Victoria/derrota, registro de acciones y reinicio con la misma u otra configuración.
- Ficha consultable sin cambiar la activación, PS sobre casillas, identificación textual de bandos, teclado, foco y movimiento reducido.
- Campamento y ensayo anteriores conservados. Ningún recurso de especie ni paquete nuevo.

## Verificación ejecutada

| Comprobación | Resultado |
| --- | --- |
| `npm.cmd test` | 21 pruebas aprobadas: 9 de combate y 12 anteriores |
| Iniciativa | Límites de variación, reproducción durante varias rondas y una activación por unidad/ronda |
| Activaciones | Ataque/movimiento en ambos órdenes; rechazo de segundo uso; previsualización sin mutación ni consumo de PRNG |
| Bajas y resultados | Retirada de cola y ocupación, fin de ronda sin bloqueo, victoria/derrota inmediata y órdenes finales rechazadas |
| IA | Ataque legal, navegación y espera sin camino; varias simulaciones 3 contra 3 terminan y reproducen sus estados |
| `npm.cmd run verify:assets` | 6 especies, 12 hojas y 33 hashes originales verificados |
| `npm.cmd run build` | Correcta, incluye TypeScript sin errores |
| `node --experimental-strip-types tools/browser-sprint2.cjs` | 20 comprobaciones en Edge con Playwright; informe en `qa/sprint-2/browser-results.json` |
| Producción local | Las mismas 20 comprobaciones pasan contra `127.0.0.1:4173`; resultados de desarrollo preservados en `qa/sprint-2/development-results.json` |
| Combates completos en navegador | Victoria en 7 rondas con `kanto-001`; repetición idéntica. Derrota en 5 rondas al esperar con `portfolio`, ±10 % |
| Reinicio y estado | Configuración reproducida y bucle enemigo anterior cancelado; inspeccionar no transfiere el turno |
| Regresión del ensayo | 18 comprobaciones del sprint 1 aprobadas, incluida pausa durante movimiento; informe copiado a `qa/sprint-2/regression-sprint1.json` |
| Carga/errores | Recursos retrasados, catálogo vacío/recarga y hoja ausente con marcador móvil comprobados |
| Vistas | Escritorio 1440×1000, intermedia 900×1000 y estrecha 390×844 sin desbordamiento horizontal; ataque completado en estrecha |
| Visitas correctas | Sin errores JavaScript/consola ni peticiones a servicios externos |
| Acabado | Capturas de tablero, ataque y resultados revisadas; detector de Impeccable sin hallazgos |

No hay linter ni cobertura configurados: no se presentan como ejecutados. La prueba de navegador emplea una política de jugador de pruebas, junto a las mismas reglas que validan cada estado. El juego solo automatiza a los enemigos.

## Demostración local

Arranque: `npm.cmd ci`, `npm.cmd run dev`; abrir `http://127.0.0.1:5173/`.

1. Con semilla `kanto-001` y ±5 %, los dos primeros enemigos se acercan. El primer aliado activo es Charmander en D7.
2. Elegir Pikachu en D5 muestra 17 PS de daño. Cancelar conserva salud, movimiento y acción.
3. Confirmar el ataque consume la acción; mover a E7 sigue disponible. Terminar turno da paso a la siguiente unidad.
4. Con Squirtle, probar mover y después atacar. Concentrar ataques permite terminar la batalla; esperar todos los turnos permite comprobar la derrota.
5. Reiniciar con la misma semilla y las mismas órdenes reproduce la partida. Semilla/variación editadas se aplican al reiniciar.

`npm.cmd run test:browser` ejecuta las pruebas del combate; `npm.cmd run test:browser:training`, las del ensayo. Necesitan un servidor activo y Edge en Windows o Chromium de Playwright en otros sistemas. La variable `TACTICS_URL` apunta la prueba de combate a otra URL local.

## Valores provisionales y límites

- PS: `round(35 + PS_base / 3)`; daño físico básico: `max(5, round(12 + ataque_base × 0.18 − defensa_base × 0.10))`, limitado a PS restantes.
- Precisión 100 %, alcance 1/2 y perfiles terrestres. Los tipos modernos se muestran, pero todavía no modifican el daño.
- Una sola batalla de composición fija. Sin habilidades, estados, puntos tácticos, equipo aleatorio, progresión, objetos, run ni guardado.
- IA determinista básica; no constituye todavía un desafío equilibrado ni una evaluación de diversión.
- Phaser conserva el aviso de tamaño de bloque, aproximadamente 1,66 MB sin comprimir y 374 kB gzip.
- Solo Edge/Chromium probado; Firefox, Safari, móvil real y lector de pantalla pendientes.

## Próximo sprint

Sprint 3: identidades, tabla de tipos moderna, daño físico/especial, habilidades, puntos tácticos y estados iniciales. Mantener el combate reproducible y validar las seis especies antes de ampliar contenido.
