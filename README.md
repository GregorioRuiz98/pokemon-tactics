# Pokémon Tactics — sprint 1

Tablero local 8×8 con seis Pokémon, terrenos, selección, trayectoria previa y desplazamiento confirmado. El campamento de especies sigue disponible desde la barra superior. Desarrollo según el [plan por sprints](docs/PLAN_SPRINTS.md).

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

- Seleccionar un Pokémon en el tablero o en la lista inferior; señalar una casilla muestra la trayectoria previa.
- Elegir un destino y pulsar **Confirmar movimiento**; **Cancelar** o Escape descarta la orden sin gastar puntos.
- Suelo cuesta 1 punto por casilla y maleza 2; rocas, agua y otras unidades bloquean el paso. El coste mostrado es acumulado; no se cobra la casilla de origen.
- Flechas recorren la cuadrícula; Enter/Espacio eligen una unidad o destino. El foco vuelve al destino después de moverse.
- Reiniciar ensayo restaura posiciones y presupuesto. Los presupuestos son provisionales: Geodude 3, Pikachu 5 y el resto 4; todos usan perfil terrestre.
- Pausar/Reanudar controla reposo y desplazamiento. Con movimiento reducido, los desplazamientos se resuelven sin transición.
- Campamento abre `?view=camp`, con los controles de animación y orientación del sprint 0.

Es un ensayo de movimiento: no hay rondas, combate, daño, IA ni run todavía. No genera un equipo aleatorio. Los roles son propuestas de diseño; volar y afinidades de terreno se incorporarán cuando corresponda.

Prueba sugerida: selecciona Bulbasaur en B6 y elige B4. La ruta pasa por maleza en B5 y cuesta 3 puntos. Cancela para comprobar que conserva sus 4 puntos; repite y confirma para llegar a B4 con 1. H1 permite comprobar un destino sin camino.

## Prueba de navegador reproducible

Con el servidor de desarrollo activo en otra terminal:

```powershell
npm.cmd run test:browser
```

Usa Playwright 1.64.0 y Edge instalado en Windows. En otros sistemas, instalar Chromium con `npx playwright install chromium` antes de ejecutarla. Conserva capturas e informe de 18 comprobaciones en `docs/qa/sprint-1`. No incorpora servicios externos ni envía capturas. El servidor debe estar activo: este comando no lo arranca.

## Organización

- `src/data`: modelo y validación del catálogo.
- `src/rules`: parámetros provisionales e identidades propuestas, sin combate implementado.
- `src/rules/movement.ts`: navegación, costes, ocupación y confirmación independientes del motor.
- `src/game`: escenas de campamento y tablero, y arranque Phaser.
- `src/main.ts`: entrada y selección de pantalla; `src/camp.ts` conserva la galería.
- `src/tactical.ts` y `src/tactical.css`: controles y presentación del tablero.
- `public/data`: instantánea local de datos y manifiesto de procedencia.
- `public/assets`: sprites, miniaturas y fuente.
- `public/licenses`: licencias de terceros.
- `tools`: importación reproducible y verificación de integridad.
- `tests`: validación del catálogo y reglas de movimiento.
- `docs`: decisiones y cierre de sprint.

## Actualizar recursos deliberadamente

Solo para mantenimiento, no para arrancar: Python 3.12 o posterior y Pillow 12.3.0. El importador reutiliza funciones MIT de PokéSurvivor sin ejecutarlo como juego.

```powershell
python -m pip install -r tools/requirements.txt
python tools/import_resources.py
npm.cmd run verify:assets
```

Las versiones de repositorios están fijadas en `tools/sources.lock.json`. PokéAPI no ofrece una versión en estos endpoints: las respuestas se cachean en `tools/cache` y la instantánea resultante queda incluida y verificada por hashes. Una reimportación sin esa caché puede actualizar datos; revisar su diff. No borrar la caché como parte de un arranque normal.

Consultar [créditos](CREDITS.md), [decisiones](docs/DECISIONS.md) y [cierre del sprint 1](docs/SPRINT_1.md). Los recursos de terceros mantienen sus licencias y derechos; la licencia MIT del motor no cubre los personajes Pokémon.
