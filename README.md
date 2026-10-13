# Pokémon Tactics — sprint 3 · POO y habilidades

Combate local 3 contra 3 sobre un tablero 8×8, con iniciativa por velocidad, tabla moderna de tipos, habilidades, puntos tácticos y estados. La versión 0.3.0 utiliza POO: clase base de Pokémon, seis especializaciones y acciones polimórficas. Las órdenes permanecen integradas en el escenario, con retrato de unidad activa, ficha de objetivo y previsión central. El ensayo y el campamento siguen disponibles en Opciones. Desarrollo según el [plan por sprints](docs/PLAN_SPRINTS.md).

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

- La cola superior indica quién actúa. Los enemigos se resuelven automáticamente; las órdenes solo se dan a la unidad aliada activa.
- **Mover** permite elegir una casilla y confirmar la ruta; **Acciones** y los tres botones de habilidades permiten elegir un objetivo compatible y confirmar daño, precisión, coste y efecto mostrado. **Cancelar** o Escape descarta la orden.
- Cada Pokémon dispone de básico gratuito y dos habilidades. PT: 2 iniciales, +1 al comenzar su activación, máximo 5. Confirmar consume PT y acción también al fallar; cancelar no gasta nada.
- Veneno, quemadura y parálisis duran tres activaciones propias; las fichas muestran duración y protección. Las reglas y adaptaciones están en [SPRINT_3.md](docs/SPRINT_3.md).
- Cada activación permite un desplazamiento continuo y una acción, en ambos órdenes. **Terminar turno** renuncia a lo que quede.
- Suelo cuesta 1 y maleza 2; rocas, agua y otras unidades bloquean el paso. El ataque a distancia también comprueba los obstáculos intermedios.
- Inspeccionar una unidad en tablero, cola o lista muestra PS, posición y estadísticas; no cambia de quién es el turno.
- Flechas recorren la cuadrícula; Enter/Espacio eligen una casilla o unidad. Foco visible y animaciones pausables; movimiento reducido omite transiciones.
- Opciones abre semilla, variación ±5 %/±10 %, composición, reinicio y registro. Los cambios se aplican al reiniciar. Una misma semilla y las mismas órdenes reproducen los resultados. Escape o pulsar fuera cierra el menú.
- Las bajas abandonan tablero y cola. Victoria/derrota permiten volver a combatir con la configuración elegida.

Dos composiciones fijas de prueba: **Iniciales** (Bulbasaur, Charmander, Squirtle) y **Control** (Pikachu, Butterfree, Geodude); el otro trío es el bando enemigo. Cambia composición en Opciones y reinicia para compararlas. Daño y costes siguen siendo provisionales. Progresión de run, guardado, orientación final manual y paso a través de aliados permanecen pendientes.

Prueba sugerida con `kanto-001`, ±5 % e Iniciales: espera a Charmander, selecciona Lanzallamas y pulsa un enemigo resaltado. Revisa daño, coste de 3 PT y efectividad; cancela para conservar todo o confirma y después mueve. Con Squirtle, selecciona Cobertura y su propia casilla para protegerlo. Después compara el equipo Control y sus estados.

Prototipos anteriores: ensayo en `?view=training`, campamento en `?view=camp`.

## Prueba de navegador reproducible

Con el servidor de desarrollo activo en otra terminal:

```powershell
npm.cmd run test:browser
```

Ejecuta 19 comprobaciones de habilidades, combate y HUD, y conserva capturas en `docs/qa/sprint-3`. Incluye que los controles no cubran casillas en escritorio, ventana de poca altura y móvil. La prueba controla al jugador mediante una política determinista de pruebas y comprueba cada estado con las reglas; no añade un modo automático al juego.

`npm.cmd run test:browser:training` ejecuta las 18 comprobaciones del ensayo anterior. Usa Playwright 1.64.0 y Edge instalado en Windows. En otros sistemas, instalar Chromium con `npx playwright install chromium`. No envía capturas a servicios externos. El servidor debe estar activo: estos comandos no lo arrancan. `TACTICS_URL` permite ejecutar la prueba de combate contra otra URL local, por ejemplo la vista previa en el puerto 4173.

## Organización

- `src/data`: modelo y validación del catálogo.
- `src/domain`: POO de Pokémon y acciones, con estado serializable separado del comportamiento. Contrato en [ARCHITECTURE.md](docs/ARCHITECTURE.md).
- `src/rules`: movimiento, tabla de tipos y orquestación del combate independientes de Phaser.
- `src/rules/movement.ts`: navegación, costes, ocupación y confirmación independientes del motor.
- `src/rules/battle.ts`: iniciativa reproducible, activaciones, PT, resolución de acciones/estados, bajas y política táctica.
- `src/game`: escenas de campamento y tablero, y arranque Phaser.
- `src/main.ts`: entrada y selección de pantalla; `src/camp.ts` conserva la galería.
- `src/tactical.ts` y `src/tactical.css`: controles y presentación del tablero.
- `src/battle.ts` y `src/battle.css`: interacción y presentación del combate.
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

Consultar [cierre del sprint 3](docs/SPRINT_3.md), [arquitectura POO](docs/ARCHITECTURE.md), [créditos](CREDITS.md), [decisiones](docs/DECISIONS.md), [cierre del sprint 2](docs/SPRINT_2.md) y [ajuste del HUD](docs/SPRINT_2_HUD.md). Los recursos de terceros mantienen sus licencias y derechos; la licencia MIT del motor no cubre los personajes Pokémon.
