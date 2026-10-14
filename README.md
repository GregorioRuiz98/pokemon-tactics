# Pokémon Tactics — sprint 6 · Tienda, reclutamiento y objetos

Roguelike táctico local sobre tableros 8×8, con iniciativa por velocidad, tabla moderna de tipos, habilidades, puntos tácticos y estados. La versión 0.6.0 añade dinero, tiendas, curación fuera de combate, reclutamiento y objetos equipados a la ruta de seis encuentros. El equipo empieza con tres Pokémon aleatorios y puede crecer hasta seis; todos los vivos se despliegan. PS y bajas persisten. Conserva la POO, el HUD integrado y el guardado local, incluida actualización de partidas del sprint 5. Desarrollo según el [plan por sprints](docs/PLAN_SPRINTS.md).

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
- En la ruta, elige una visita de tienda o reclutamiento antes de cada combate. Elegir una excluye la otra en ese tramo; cerrar la visita impide volver. Se ven escenario, enemigos y PS del equipo. El sexto combate es un final provisional, sin los jefes legendarios definitivos.
- PS y bajas se conservan; los perdidos salen del equipo y quedan registrados. Estados, protección y PT se restablecen al entrar en otro combate. Los consumibles solo se usan fuera de combate y no reviven.
- **Comprar/Candidatos** y **Bolsa y equipo** alternan las vistas de cada visita. La bolsa también se abre desde la ruta. Elegir Pokémon muestra la recuperación de PS antes de usar una poción; equipar otro objeto devuelve el anterior.
- **Reclutar** incorpora un miembro nuevo; las ofertas se pueden usar una sola vez. **Sustituir** permite liberar a un miembro y recuperar su objeto, con confirmación y cancelación/Escape. Con seis miembros, incorporar otro exige sustitución. Puede haber miembros de la misma especie con identidades distintas.
- Los objetos equipados se recuperan en la bolsa al caer el portador, como ha decidido el usuario. Reclutar otro Pokémon de esa especie crea un miembro nuevo; no restaura la identidad perdida.
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

El **combate de ensayo** en `?view=battle` conserva dos composiciones fijas: **Iniciales** (Bulbasaur, Charmander, Squirtle) y **Control** (Pikachu, Butterfree, Geodude); el otro trío es el bando enemigo. Cambia composición en Opciones y reinicia para compararlas. Daño, PS, precisión, costes y repertorios base conservan los valores del sprint 4. Los equipables añaden sus efectos propios. El equilibrio espera a completar las mecánicas; experiencia, evoluciones y jefes siguen pendientes.

Prueba sugerida: entra en tienda, compra una poción y un equipable; abre la bolsa y equipa. Tras combatir, cura a un superviviente y visita reclutamiento. Recarga durante la visita para comprobar saldo, PS y ofertas. La semilla `route-79`, ±5 %, reproduce el recorrido anterior si se cierran los servicios sin gastar y se siguen las mismas órdenes; añadir miembros, curar o equipar puede cambiar decisiones de la IA y resultados.

Propuestas económicas iniciales: 240 monedas y una Poción; 100 monedas por victoria, 80 por recluta. Poción: 40 monedas, 20 PS; Superpoción: 90, 50 PS. Restos: 120, recupera 1/16 de PS máximos al cerrar turno; Chaleco Asalto: 110, defensa especial ×1,5 e impide estado/apoyo; Botas Gruesas: 80, adaptación que evita ascuas de casilla. Restos se aplica después del daño y no revive. Un equipado por miembro; sin ventas, evolución ni objetos rompibles todavía.

Prototipos anteriores: ensayo en `?view=training`, campamento en `?view=camp`.

## Prueba de navegador reproducible

Con el servidor de desarrollo activo en otra terminal:

```powershell
npm.cmd run test:browser
```

Ejecuta 18 comprobaciones de tienda, curación, reclutamiento, seis aliados, sustituciones, ruta, guardado y móvil, con evidencia en `docs/qa/sprint-6`. Recorre seis combates reales y valida cada orden contra las reglas. El caso de sustitución con seis miembros usa un checkpoint sintético validado; no añade un modo automático al juego.

`npm.cmd run test:browser:combat` ejecuta las 19 comprobaciones del combate anterior; `npm.cmd run test:browser:training`, las 18 del ensayo. Usan Playwright 1.64.0 y Edge instalado en Windows. En otros sistemas, instalar Chromium con `npx playwright install chromium`. No envían capturas a servicios externos. El servidor debe estar activo: estos comandos no lo arrancan. `TACTICS_URL` permite ejecutar ruta y combate contra otra URL local, por ejemplo la vista previa en el puerto 4173; `TACTICS_QA_DIR` cambia la carpeta de evidencia.

Guardado: `localStorage`, clave `pokemon-tactics.run`, esquema versión 2. Registra operaciones para reconstruir saldo, bolsa, ofertas y miembros. Las partidas válidas de versión 1 se actualizan conservando PS y RNG; se guarda una copia anterior en `pokemon-tactics.run.v1-backup`. Las visitas anteriores a peleas ya iniciadas se consideran cerradas. Cada victoria antigua recibe su recompensa una vez al actualizar.

No se sincroniza entre navegadores, perfiles, dispositivos o puertos. Borrar datos del navegador elimina guardado y copia. Si falla el almacenamiento puedes jugar en memoria con aviso; **Reintentar guardado** intenta conservar el progreso nuevo. No hay cuentas ni nube. La validación detecta corrupción; no es un sistema contra trampas.

`npm.cmd run test:browser:lifecycle` comprueba el escape de nombres del catálogo, salir durante la carga de sprites y recargar durante una animación normal de movimiento.

## Organización

- `src/data`: modelo y validación del catálogo.
- `src/domain`: POO de Pokémon y acciones, con estado serializable separado del comportamiento. Contrato en [ARCHITECTURE.md](docs/ARCHITECTURE.md).
- `src/rules`: movimiento, tabla de tipos y orquestación del combate independientes de Phaser.
- `src/rules/movement.ts`: navegación, costes, ocupación y confirmación independientes del motor.
- `src/rules/battle.ts`: iniciativa reproducible, activaciones, PT, resolución espacial de acciones/estados, bajas y política táctica.
- `src/rules/run.ts`: generación reproducible, conexiones, encuentros y consecuencias entre salas.
- `src/data/run-store.ts`: guardado versionado, validación y detección de pestañas desactualizadas; `run-maps.ts`, tres escenarios reutilizando el tablero existente.
- `src/domain/items.ts`: consumibles y equipables polimórficos; datos de nombres/IDs importados en `src/data/item-metadata.ts`.
- `src/rules/legacy-run.ts` y `src/data/legacy-run-store.ts`: generación y validación de versión 1 para migración.
- `src/rules/position.ts` y `terrain.ts`: orientación, ángulos, campos temporales y mapa táctico.
- `src/game`: escenas de campamento y tablero, y arranque Phaser.
- `src/main.ts`: entrada y selección de pantalla; `src/camp.ts` conserva la galería.
- `src/tactical.ts` y `src/tactical.css`: controles y presentación del tablero.
- `src/battle.ts` y `src/battle.css`: interacción y presentación del combate.
- `src/run.ts` y `src/run.css`: menú, ruta, equipo y resultado de la partida; montaje/desmontaje del combate.
- `src/run-management.ts`: tienda, candidatos, previsión de curación y gestión del hueco equipado.
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

Los nombres e IDs de cinco objetos se importan explícitamente con `node tools/import-items.mjs` desde el mismo commit fijado de PokéAPI. Las copias de `items.csv` y `item_names.csv` conservan hashes en `items-sources.json`. El juego usa el módulo generado y no consulta la API al jugar. Precios y efectos tácticos son propios del prototipo.

Consultar [cierre del sprint 6](docs/SPRINT_6.md), [cierre del sprint 5](docs/SPRINT_5.md), [arquitectura POO](docs/ARCHITECTURE.md), [créditos](CREDITS.md) y [decisiones](docs/DECISIONS.md). Los recursos de terceros mantienen sus licencias y derechos; la licencia MIT del motor no cubre los personajes Pokémon.
