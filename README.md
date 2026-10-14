# Pokémon Tactics — sprint 5 · Ruta y consecuencias

Roguelike táctico local sobre tableros 8×8, con iniciativa por velocidad, tabla moderna de tipos, habilidades, puntos tácticos y estados. La versión 0.5.0 enlaza seis encuentros mediante una ruta con bifurcaciones y tres mapas. El equipo inicial tiene tres Pokémon aleatorios de las seis especies disponibles; los PS y las bajas persisten. El guardado local permite continuar incluso durante un combate. Conserva la POO y el HUD integrado en el escenario. Desarrollo según el [plan por sprints](docs/PLAN_SPRINTS.md).

Repositorio: [GregorioRuiz98/pokemon-tactics](https://github.com/GregorioRuiz98/pokemon-tactics). Cada sprint terminado se registra y sube tras sus comprobaciones; el procedimiento está en [AGENTS.md](AGENTS.md).

## Arranque

Requiere Node.js 24 y npm. Desde esta carpeta:

```powershell
npm.cmd ci
npm.cmd run dev
```

Abrir `http://127.0.0.1:5173`. Para detener el servidor, Ctrl+C. En sistemas que no sean Windows, usar `npm` en lugar de `npm.cmd`.

## Comprobaciones y compilación

```powershell
npm.cmd test
npm.cmd run verify:assets
npm.cmd run build
npm.cmd run preview
```

La compilación se guarda en `dist/` y la vista previa se sirve en `http://127.0.0.1:4173`. `build` incluye la comprobación de tipos. No necesita Python, claves ni conexiones a PokéAPI: todos los datos y recursos necesarios ya están incluidos. Instalar dependencias sí requiere red o una caché de npm disponible. No abrir `index.html` mediante `file://`.

## Controles y alcance

- **Empezar partida** genera equipo y ruta; la semilla opcional permite reproducirlos. **Continuar** abre el guardado del mismo navegador y origen. Preparar otra partida no reemplaza el progreso hasta confirmar.
- En la ruta, elige una sala disponible conectada al último encuentro superado. Se ven escenario, enemigos y PS del equipo. El sexto combate es un final provisional; no representa los jefes legendarios definitivos.
- PS y bajas se conservan entre salas; los miembros perdidos no vuelven a desplegarse. Estados, protección y PT se restablecen al entrar en otro combate. Aún no hay tiendas, objetos curativos ni reclutamiento: se implementarán en el sprint 6.
- **Guardar y salir** vuelve al menú. Cada orden aceptada se guarda antes de su animación. Recargar no reinicia el encuentro, las tiradas ni sus bajas. Se muestran errores de almacenamiento, guardados corruptos/incompatibles y conflictos con otras pestañas.
- La cola superior indica quién actúa. Los enemigos se resuelven automáticamente; las órdenes solo se dan a la unidad aliada activa.
- **Mover** permite elegir una casilla y confirmar la ruta; **Acciones** y los tres botones de habilidades permiten elegir un objetivo compatible y confirmar daño, precisión, coste y efecto mostrado. **Cancelar** o Escape descarta la orden.
- Cada Pokémon dispone de básico gratuito y dos habilidades. PT: 2 iniciales, +1 al comenzar su activación, máximo 5. Confirmar consume PT y acción también al fallar; cancelar no gasta nada.
- Veneno, quemadura y parálisis duran tres activaciones propias; las fichas muestran duración y protección. Las reglas y adaptaciones están en [SPRINT_3.md](docs/SPRINT_3.md).
- Cada activación permite un desplazamiento continuo y una acción, en ambos órdenes. **Terminar turno** abre la orientación final: elige dirección y confirma para renunciar a lo que quede. Cancelar conserva el turno y la orientación.
- Suelo cuesta 1; maleza 2, o 1 para Bulbasaur/Butterfree. Squirtle y Butterfree cruzan agua por 1; rocas bloquean a todos. Se atraviesan aliados, pero el destino debe estar libre; enemigos bloquean. Roca y unidades intermedias bloquean disparos, agua no.
- El ángulo reduce la precisión base: −15 puntos de frente, −5 de flanco, sin reducción por espalda. Las flechas indican orientación.
- Lanzallamas y Polvo Veneno cubren una cruz, incluidos aliados. La previsión lista cada afectado. Lanzarrocas empuja una casilla legal. Lanzallamas deja ascuas: 4 PS al cerrar turno, salvo Fuego/voladores; caducan al comienzo de la segunda ronda siguiente.
- Inspeccionar una unidad en tablero, cola o lista muestra PS, posición y estadísticas; no cambia de quién es el turno.
- Flechas recorren la cuadrícula; Enter/Espacio eligen una casilla o unidad. Foco visible y animaciones pausables; movimiento reducido omite transiciones.
- Opciones abre unidades, registro y prototipos. Solo el **combate de ensayo** permite cambiar semilla, variación ±5 %/±10 %, composición y reiniciar. Una misma semilla y las mismas órdenes reproducen los resultados. Escape o pulsar fuera cierra el menú.
- Las bajas abandonan tablero y cola. Victoria permite continuar la ruta; perder todo el equipo termina la partida.

El **combate de ensayo** en `?view=battle` conserva dos composiciones fijas: **Iniciales** (Bulbasaur, Charmander, Squirtle) y **Control** (Pikachu, Butterfree, Geodude); el otro trío es el bando enemigo. Cambia composición en Opciones y reinicia para compararlas. Daño, PS, precisión, costes y repertorios conservan los valores del sprint 4 por instrucción del usuario. Experiencia, reclutamiento, objetos y evolución siguen pendientes.

Prueba sugerida: empieza una partida, supera una sala y comprueba los PS al volver a la ruta. Recarga y continúa; un miembro perdido debe seguir fuera. La semilla `route-79`, ±5 %, permite probar seis encuentros completables con los valores actuales; no garantiza victoria con otras órdenes. La curación pendiente hace esta ruta exigente. Cambia de bifurcación para comparar terreno y rivales.

Prototipos anteriores: ensayo en `?view=training`, campamento en `?view=camp`.

## Prueba de navegador reproducible

Con el servidor de desarrollo activo en otra terminal:

```powershell
npm.cmd run test:browser
```

Ejecuta 18 comprobaciones de ruta, guardado, bifurcaciones, bajas, victoria/derrota, errores y móvil, y conserva capturas en `docs/qa/sprint-5`. Recorre seis combates reales con la semilla `route-79`, valida cada orden contra las reglas y comprueba continuación durante el combate. La política de pruebas no añade un modo automático al juego.

`npm.cmd run test:browser:combat` ejecuta las 19 comprobaciones del combate anterior; `npm.cmd run test:browser:training`, las 18 del ensayo. Usan Playwright 1.64.0 y Edge instalado en Windows. En otros sistemas, instalar Chromium con `npx playwright install chromium`. No envían capturas a servicios externos. El servidor debe estar activo: estos comandos no lo arrancan. `TACTICS_URL` permite ejecutar ruta y combate contra otra URL local, por ejemplo la vista previa en el puerto 4173; `TACTICS_QA_DIR` cambia la carpeta de evidencia.

Guardado: `localStorage`, clave `pokemon-tactics.run`, esquema versión 1. No se sincroniza entre navegadores, perfiles, dispositivos o puertos. Borrar datos del navegador elimina el guardado. Si falla el almacenamiento puedes jugar en memoria, con aviso; **Reintentar guardado** intenta conservar el progreso nuevo. No hay cuentas ni nube.

`npm.cmd run test:browser:lifecycle` comprueba el escape de nombres del catálogo, salir durante la carga de sprites y recargar durante una animación normal de movimiento.

## Organización

- `src/data`: modelo y validación del catálogo.
- `src/domain`: POO de Pokémon y acciones, con estado serializable separado del comportamiento. Contrato en [ARCHITECTURE.md](docs/ARCHITECTURE.md).
- `src/rules`: movimiento, tabla de tipos y orquestación del combate independientes de Phaser.
- `src/rules/movement.ts`: navegación, costes, ocupación y confirmación independientes del motor.
- `src/rules/battle.ts`: iniciativa reproducible, activaciones, PT, resolución espacial de acciones/estados, bajas y política táctica.
- `src/rules/run.ts`: generación reproducible, conexiones, encuentros y consecuencias entre salas.
- `src/data/run-store.ts`: guardado versionado, validación y detección de pestañas desactualizadas; `run-maps.ts`, tres escenarios reutilizando el tablero existente.
- `src/rules/position.ts` y `terrain.ts`: orientación, ángulos, campos temporales y mapa táctico.
- `src/game`: escenas de campamento y tablero, y arranque Phaser.
- `src/main.ts`: entrada y selección de pantalla; `src/camp.ts` conserva la galería.
- `src/tactical.ts` y `src/tactical.css`: controles y presentación del tablero.
- `src/battle.ts` y `src/battle.css`: interacción y presentación del combate.
- `src/run.ts` y `src/run.css`: menú, ruta, equipo y resultado de la partida; montaje/desmontaje del combate.
- `public/data`: instantánea local de datos y manifiesto de procedencia.
- `public/assets`: sprites, miniaturas y fuente.
- `public/licenses`: licencias de terceros.
- `tools`: importación reproducible y verificación de integridad.
- `tests`: validación del catálogo y reglas de movimiento/combate.
- `docs`: decisiones y cierre de sprint.

## Actualizar recursos deliberadamente

Solo para mantenimiento, no para arrancar: Python 3.12 o posterior y Pillow 12.3.0. El importador reutiliza funciones MIT de PokéSurvivor sin ejecutarlo como juego.

```powershell
python -m pip install -r tools/requirements.txt
python tools/import_resources.py
npm.cmd run verify:assets
```

Las versiones de repositorios están fijadas en `tools/sources.lock.json`. PokéAPI no ofrece una versión en estos endpoints: las respuestas se cachean en `tools/cache` y la instantánea resultante queda incluida y verificada por hashes. Una reimportación sin esa caché puede actualizar datos; revisar su diff. No borrar la caché como parte de un arranque normal.

La tabla de tipos se regenera sin red con `node tools/import-types.mjs`, desde los CSV originales fijados en `tools/vendor/pokeapi`. La prueba de tipos compara las 324 relaciones con esos datos y comprueba sus hashes.

Consultar [cierre del sprint 5](docs/SPRINT_5.md), [cierre del sprint 4](docs/SPRINT_4.md), [arquitectura POO](docs/ARCHITECTURE.md), [créditos](CREDITS.md) y [decisiones](docs/DECISIONS.md). Los recursos de terceros mantienen sus licencias y derechos; la licencia MIT del motor no cubre los personajes Pokémon.
