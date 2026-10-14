# Sprint 5 — Ruta y consecuencias persistentes

14 de octubre de 2026. Versión **0.5.0**, rama `codex/sprint-5`.

## Entrega

- Menú de nueva partida, semilla opcional, variación 5/10 % y continuación. El reemplazo de un guardado requiere confirmación en la propia interfaz.
- Tres Pokémon iniciales aleatorios, distintos y no legendarios, dentro del catálogo actual. Variedad provisional de defensa y ofensiva/control; selección reproducible por semilla.
- Ruta de roca con bifurcaciones: diez nodos, seis encuentros por partida. Cantera, Paso de piedra y Cantera inundada se introducen según tramo. Enemigos y terreno visibles; no se anuncian decisiones futuras de la IA.
- PS persistentes, bajas definitivas y despliegue solo de supervivientes. Perder todo el equipo termina la partida. Estados, protección y PT se restablecen por sala, sin curación automática.
- Guardado local versionado. Se guarda cada orden aceptada antes de animarla, permitiendo continuar una pelea con sus PS, RNG, cola, posiciones, PT y estados exactos. Guardar y salir desmonta la escena e invalida callbacks/IA pendientes.
- Guardados corruptos o incompatibles se conservan hasta descartarlos explícitamente. Quota o almacenamiento bloqueado permite jugar en memoria con aviso y reintento. Las pestañas desactualizadas no pueden reemplazar un guardado nuevo.
- Resultado de partida y resumen de encuentros. El sexto combate cierra esta prueba; no representa los futuros finales legendarios.

## Recursos y arquitectura

Se reutilizan Phaser, EasyStar, PokéAPI local, SpriteCollab, Pixelify Sans, el tablero inundado y las reglas del sprint 4. Dos mapas adicionales se dibujan con las mismas primitivas. No se incorporan dependencias, descargas ni especies nuevas. Fuentes/licencias en `CREDITS.md` y `tools/sources.lock.json`.

`id` identifica cada unidad y `speciesId` selecciona clases, datos y texturas: dos Geodude pueden coexistir en bandos diferentes con sprites independientes. El estado sigue serializable; comportamiento en el registro POO. `src/rules/run.ts` controla generación y transiciones; `src/data/run-store.ts`, validación y almacenamiento; `src/run.ts`, vistas y host del combate. Contrato actualizado en `ARCHITECTURE.md`.

## Comprobaciones

| Comprobación | Resultado |
| --- | --- |
| Dominio/reglas/datos | 57 pruebas aprobadas: 49 anteriores y 8 de ruta/guardado/regresión |
| Parámetros conservados | Instantánea del sprint 4 compara PS máximos, definiciones, costes, precisiones, potencias y previsiones contra todos los demás objetivos |
| Simulación de rutas | 100 partidas deterministas completas hasta victoria/derrota; sin transiciones ni finales inválidos |
| Tipos y compilación | Correctos; permanece el aviso conocido del tamaño del bloque de Phaser |
| Recursos | 33 hashes originales y 2 CSV de tipos verificados; sprites intactos |
| Navegador de desarrollo | 18 comprobaciones de ruta, incluidas seis peleas reales hasta victoria y una derrota real |
| Producción local | 18 comprobaciones de ruta contra la compilación en 4173 |
| Regresión de combate | 19 comprobaciones aprobadas, con ambos equipos, orientación, terreno, áreas y recursos incompletos |
| Ensayo de movimiento | 18 comprobaciones aprobadas; conserva la galería y los marcadores |
| Ciclo de vida | Texto de catálogo escapado, salida durante carga de sprites y recarga durante una animación normal |
| Diseño | Detector manual de Impeccable sin hallazgos; escritorio y móvil revisados |

La QA valida estado contra las reglas tras cada orden, continuación dentro y fuera del combate, bajas que no vuelven a desplegarse, ramas, final, cancelación de reemplazo, corrupción/incompatibilidad, almacenamiento bloqueado/quota, conflictos de pestañas y catálogo inválido. La revisión detectó una semilla larga que desbordaba el menú móvil; se corrigió con salto de texto. Evidencia en `docs/qa/sprint-5`, con regresiones separadas para conservar capturas históricas.

Solo Edge/Chromium probado. No hay linter ni cobertura configurados y no se ejecutó una auditoría completa de accesibilidad. Los finales aislados de algunas pruebas de reglas utilizan snapshots sintéticos; la prueba de navegador alcanza victoria/derrota mediante órdenes legales reales, sin inyectar resultados ni modificar daños.

## Prueba local y pendientes

Abrir `http://127.0.0.1:5173`, comenzar, superar una sala, volver a la ruta y recargar. PS y bajas deben conservarse. La semilla `route-79`, ±5 %, alcanza el final con la política táctica existente tomando la segunda rama en los tramos 2–5; otras órdenes pueden producir otro resultado. Se mantiene el combate aislado en `?view=battle` para comparar composiciones.

Las 100 simulaciones usan la misma política táctica para ambos bandos: 1 victoria completa, 99 derrotas. **No mide la tasa de victoria de jugadores.** Evidencia del desgaste de una ruta sin curación; no se ajustaron parámetros ni repertorios, incluido Lanzallamas, por instrucción del usuario. La valoración de diversión y duración requiere prueba manual.

Sprint 5 completado técnicamente. Sprint 6 pendiente: recompensas/dinero, tienda, consumibles curativos solo fuera de combate, reclutamiento hasta seis con sustitución y un objeto equipado por miembro. Experiencia, evoluciones y jefes quedan para sus sprints. No se publica la web ni se inicia el sprint siguiente automáticamente.
