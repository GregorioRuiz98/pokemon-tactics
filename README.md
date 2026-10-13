# Pokémon Tactics — sprint 2

Combate local 3 contra 3 sobre un tablero 8×8, con iniciativa por velocidad, movimiento, ataque básico y victoria/derrota. El ensayo de movimiento y el campamento siguen disponibles desde la barra superior. Desarrollo según el [plan por sprints](docs/PLAN_SPRINTS.md).

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
- **Mover** permite elegir una casilla y confirmar la ruta; **Ataque básico** permite elegir un enemigo y confirmar el daño mostrado. **Cancelar** o Escape descarta la orden.
- Cada activación permite un desplazamiento continuo y una acción, en ambos órdenes. **Terminar turno** renuncia a lo que quede.
- Suelo cuesta 1 y maleza 2; rocas, agua y otras unidades bloquean el paso. El ataque a distancia también comprueba los obstáculos intermedios.
- Inspeccionar una unidad en tablero, cola o lista muestra PS, posición y estadísticas; no cambia de quién es el turno.
- Flechas recorren la cuadrícula; Enter/Espacio eligen una casilla o unidad. Foco visible y animaciones pausables; movimiento reducido omite transiciones.
- Semilla y variación ±5 %/±10 % se aplican al reiniciar. Una misma semilla y las mismas órdenes reproducen los resultados.
- Las bajas abandonan tablero y cola. Victoria/derrota permiten volver a combatir con la configuración elegida.

Aliados: Bulbasaur, Charmander y Squirtle; enemigos: Pikachu, Butterfree y Geodude. Composición fija de prueba, perfiles terrestres, daño físico simplificado y precisión 100 %. La tabla de tipos, habilidades, puntos tácticos, estados, progreso de run y guardado pertenecen a los siguientes sprints.

Prueba sugerida con `kanto-001`, ±5 %: espera el primer turno de Charmander. Pikachu se habrá acercado a D5. Haz clic en él para previsualizar un ataque de 17 PS; cancela y comprueba que conserva su salud. Confirma después el ataque, mueve a Charmander a E7 y termina turno. El registro inferior recoge las acciones realizadas.

Prototipos anteriores: ensayo en `?view=training`, campamento en `?view=camp`.

## Prueba de navegador reproducible

Con el servidor de desarrollo activo en otra terminal:

```powershell
npm.cmd run test:browser
```

Ejecuta 20 comprobaciones del combate y conserva capturas en `docs/qa/sprint-2`. La prueba controla al jugador mediante una política determinista de pruebas y comprueba cada estado con las reglas; no añade un modo automático al juego.

`npm.cmd run test:browser:training` ejecuta las 18 comprobaciones del ensayo anterior. Usa Playwright 1.64.0 y Edge instalado en Windows. En otros sistemas, instalar Chromium con `npx playwright install chromium`. No envía capturas a servicios externos. El servidor debe estar activo: estos comandos no lo arrancan. `TACTICS_URL` permite ejecutar la prueba de combate contra otra URL local, por ejemplo la vista previa en el puerto 4173.

## Organización

- `src/data`: modelo y validación del catálogo.
- `src/rules`: parámetros provisionales e identidades propuestas, sin combate implementado.
- `src/rules/movement.ts`: navegación, costes, ocupación y confirmación independientes del motor.
- `src/rules/battle.ts`: iniciativa reproducible, activaciones, ataques, bajas y política táctica.
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

Consultar [créditos](CREDITS.md), [decisiones](docs/DECISIONS.md) y [cierre del sprint 2](docs/SPRINT_2.md). Los recursos de terceros mantienen sus licencias y derechos; la licencia MIT del motor no cubre los personajes Pokémon.
