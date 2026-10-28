# Desarrollo nativo — Windows 1.0.0-rc.3

[Reglas](../docs/REGLAS_ACTUALES.md) · [Jugar/recuperar](../docs/PLAYTEST_WINDOWS.md) · [Arquitectura](../docs/ARCHITECTURE.md) · [Estado](../docs/PLAN_SPRINTS.md)

Proyecto `project.godot`, entrada `scenes/campaign.tscn`. El laboratorio conserva `scenes/laboratory.tscn` y su guardado independiente. Campaña 30/capítulo 34/combate 25; versión nativa en `project.godot`, no en la versión web de npm.

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
npm run godot:verify:relief
npm run godot:test:relief
npm run godot:test:relief:compat
npm run godot:simulate:relief
npm run godot:test:relief:replay
npm run godot:qa:relief
```

`test:collection` comprueba colección, iniciales, migración, guardados y legendarios; `test:quality` conserva la comprobación del combate publicado. Las suites UI prueban controles, vistas y guardados aislados. `qa:quality` añade los 58 escenarios y carga de una partida histórica larga; `simulate:quality` recorre la campaña mediante órdenes legales y puede tardar mucho más. No son requisitos para corregir un enlace documental.

Scripts completos en `package.json`; los de entregas antiguas continúan por compatibilidad. No confundir su edición con la actual ni ejecutar todos sin motivo.

## Exportar y preparar

```sh
npm run godot:export
npm run godot:qa:relief:export
npm run godot:package
npm run godot:check:candidate
```

El runner comprueba exactamente Godot 4.7.2 estable. Las herramientas de QA del EXE también comprueban el editor; el jugador que abre el EXE no lo necesita. El empaquetado requiere evidencias fuente/EXE y lint/validación según [Entrega](../docs/DEPLOY.md).

Salidas relativas a raíz: `../releases/pokemon-tactics-1.0.0-rc.3/`; QA: `../../work/qa-sprint-40/`. Partidas reales: `%APPDATA%/PokemonTacticsLab`; no usarlas en ensayos.

[Notas acumuladas](../docs/history/GODOT_README_2026-10-27.md) · [Web 0.12.0](../docs/WEB_LEGACY.md).

La candidata usa `application/config/qa_stage=40` para separar número de sprint y versión del producto. La versión Windows numérica es 1.0.0.3; campaña30/combate25 añade mapas sin sobrescribir los motores publicados. `godot:test:package` comprueba el contrato del empaquetador; `godot:check:candidate` extrae el ZIP y prueba arranque con perfil aislado en el mismo PC. La reproducción completa puede tardar varios minutos y no es una sesión humana.

Historial: para la revisión de presentación RC2 se exigieron las suites de perfil
(`godot:qa:profile` y `godot:qa:profile:export`), colección, usabilidad de cierre
y revisión, en fuente y EXE. El recorrido completo de campaña sigue siendo
evidencia previa de RC1; no se presenta como repetido en RC2.

## Relieve RC3

`npm run godot:verify:relief` verifica dos aproximaciones y accesos por tierra en los58 diseños. `npm run godot:test:relief` comprueba116 escenarios, IA y compatibilidad. `npm run godot:simulate:relief` recorre Kanto con órdenes legales; `npm run godot:qa:relief` y `npm run godot:qa:relief:export` comparan apertura natural y116 vistas de prueba. El empaquetador RC3 es `tools/godot/package-relief.py`; exige esta evidencia y la campaña final del catálogo exacto, no reutiliza resultados RC2. [Detalle](../docs/SPRINT_40_RELIEF.md).
