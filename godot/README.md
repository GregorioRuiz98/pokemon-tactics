# Desarrollo nativo — Windows 0.35.0

[Reglas](../docs/REGLAS_ACTUALES.md) · [Jugar/recuperar](../docs/PLAYTEST_WINDOWS.md) · [Arquitectura](../docs/ARCHITECTURE.md) · [Estado](../docs/PLAN_SPRINTS.md)

Proyecto `project.godot`, entrada `scenes/campaign.tscn`. El laboratorio conserva `scenes/laboratory.tscn` y su guardado independiente. Campaña 28/capítulo 32/combate 24; versión nativa en `project.godot`, no en la versión web de npm.

## Requisitos de desarrollo

Git, Godot 4.7.2 estándar, Node 24 y Python 3.10 o posterior en PATH. Entorno comprobado: Python 3.12.10 y Node 24.13.0. Verificación/empaquetado usan bibliotecas estándar; sin plugins Godot obligatorios.

Desde la raíz configura el binario descargado. Ejemplo PowerShell; sustituye la ruta por la real:

```powershell
$env:GODOT_BIN = 'C:\Herramientas\Godot_v4.7.2-stable_win64_console.exe'
npm run check:repo
npm run test:repo-check
npm run godot:verify
npm run godot:prepare
```

Abre `godot/project.godot` en el editor y ejecuta la escena principal. Exportar requiere las plantillas oficiales 4.7.2. Estos comandos no instalan servicios ni plantillas automáticamente.

Los importadores de arte/especies que usan Pillow son tareas separadas; no hacen falta para jugar ni verificar los recursos incluidos. No reimportes ni regeneres manifiestos publicados para ocultar cambios.

## Pruebas pertinentes

```sh
npm run godot:test:collection
npm run godot:qa:collection
npm run godot:test:quality
npm run godot:qa:briefing
npm run godot:qa:review
npm run godot:qa:symbols
```

`test:collection` comprueba colección, iniciales, migración, guardados y legendarios; `test:quality` conserva la comprobación del combate publicado. Las suites UI prueban controles, vistas y guardados aislados. `qa:quality` añade los 58 escenarios y carga de una partida histórica larga; `simulate:quality` recorre la campaña mediante órdenes legales y puede tardar mucho más. No son requisitos para corregir un enlace documental.

Scripts completos en `package.json`; los de entregas antiguas continúan por compatibilidad. No confundir su edición con la actual ni ejecutar todos sin motivo.

## Exportar y preparar

```sh
npm run godot:export
npm run godot:qa:collection:export
npm run godot:qa:briefing:export
npm run godot:qa:review:export
npm run godot:qa:symbols:export
npm run godot:package
```

El runner comprueba exactamente Godot 4.7.2 estable. Las herramientas de QA del EXE también comprueban el editor; el jugador que abre el EXE no lo necesita. El empaquetado requiere evidencias fuente/EXE y lint/validación según [Entrega](../docs/DEPLOY.md).

Salidas relativas a raíz: `../releases/pokemon-tactics-0.35.0/`; QA: `../../work/qa-sprint-35/`. Partidas reales: `%APPDATA%/PokemonTacticsLab`; no usarlas en ensayos.

[Notas acumuladas](../docs/history/GODOT_README_2026-10-27.md) · [Web 0.12.0](../docs/WEB_LEGACY.md).
