# Pokémon Tactics — sprint 0

Campamento local con seis especies, estadísticas base reales, selección mediante ratón o teclado y vista de animaciones direccionales. Es el primer paso del [plan por sprints](docs/PLAN_SPRINTS.md).

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

- Seleccionar cualquiera de los seis Pokémon en el campamento o en la lista inferior.
- Tabulador/Enter para navegar; flechas izquierda/derecha dentro de la lista de compañeros.
- Reposo/Paso cambia la animación; N/E/S/O cambia su dirección. Paso es una vista previa, no movimiento por el tablero.
- Pausar/Reanudar controla todas las animaciones. Se respeta la preferencia de movimiento reducido.
- Créditos abre procedencia, licencias y autores. Escape cierra el diálogo.

La galería no crea todavía un equipo. Los roles son propuestas de diseño. Combate, rutas, reclutamiento, evoluciones, inventario y guardado pertenecen a sprints posteriores.

## Organización

- `src/data`: modelo y validación del catálogo.
- `src/rules`: parámetros provisionales e identidades propuestas, sin combate implementado.
- `src/game`: escena y arranque Phaser.
- `src/main.ts` y `src/style.css`: interfaz accesible y presentación.
- `public/data`: instantánea local de datos y manifiesto de procedencia.
- `public/assets`: sprites, miniaturas y fuente.
- `public/licenses`: licencias de terceros.
- `tools`: importación reproducible y verificación de integridad.
- `tests`: validación del contrato de datos.
- `docs`: decisiones y cierre de sprint.

## Actualizar recursos deliberadamente

Solo para mantenimiento, no para arrancar: Python 3.12 o posterior y Pillow 12.3.0. El importador reutiliza funciones MIT de PokéSurvivor sin ejecutarlo como juego.

```powershell
python -m pip install -r tools/requirements.txt
python tools/import_resources.py
npm.cmd run verify:assets
```

Las versiones de repositorios están fijadas en `tools/sources.lock.json`. PokéAPI no ofrece una versión en estos endpoints: las respuestas se cachean en `tools/cache` y la instantánea resultante queda incluida y verificada por hashes. Una reimportación sin esa caché puede actualizar datos; revisar su diff. No borrar la caché como parte de un arranque normal.

Consultar [créditos](CREDITS.md), [decisiones](docs/DECISIONS.md) y [cierre del sprint](docs/SPRINT_0.md). Los recursos de terceros mantienen sus licencias y derechos; la licencia MIT del motor no cubre los personajes Pokémon.
