# Desarrollo nativo — Windows 1.0.0-rc.6

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

Salidas relativas a raíz: `../releases/tactical-chronicles-kanto-1.0.0-rc.6/`; QA: `../../work/qa-sprint-43/`. Partidas reales: `%APPDATA%/PokemonTacticsLab`; no usarlas en ensayos.

[Notas acumuladas](../docs/history/GODOT_README_2026-10-27.md) · [Web 0.12.0](../docs/WEB_LEGACY.md).

La candidata usa `application/config/qa_stage=43` para separar número de sprint y versión del producto. La versión Windows numérica es 1.0.0.6; campaña30/combate25 añade mapas sin sobrescribir los motores publicados. `godot:test:package` comprueba el contrato del empaquetador; `godot:check:candidate` extrae el ZIP y prueba arranque con perfil aislado en el mismo PC. La reproducción completa puede tardar varios minutos y no es una sesión humana.

Historial: para la revisión de presentación RC2 se exigieron las suites de perfil
(`godot:qa:profile` y `godot:qa:profile:export`), colección, usabilidad de cierre
y revisión, en fuente y EXE. El recorrido completo de campaña sigue siendo
evidencia previa de RC1; no se presenta como repetido en RC2.

## Relieve RC3

`npm run godot:verify:relief` verifica dos aproximaciones y accesos por tierra en los58 diseños. `npm run godot:test:relief` comprueba116 escenarios, IA y compatibilidad. `npm run godot:simulate:relief` recorre Kanto con órdenes legales; `npm run godot:qa:relief` y `npm run godot:qa:relief:export` comparan apertura natural y116 vistas de prueba. El empaquetador RC3 es `tools/godot/package-relief.py`; exige esta evidencia y la campaña final del catálogo exacto, no reutiliza resultados RC2. [Detalle](../docs/SPRINT_40_RELIEF.md).

## Correcciones RC4

`npm run godot:qa:dex` y `npm run godot:qa:dex:export` comprueban ficha anidada, teclado/ratón, foco, búsqueda y texto150%. `npm run godot:prepare:candidate:journey` prepara el diario legal de la simulación previa; si no existe, genera uno con `npm run godot:simulate:relief`. `npm run godot:qa:candidate:journey` y `npm run godot:qa:candidate:journey:export` ejecutan las10.277 órdenes desde la interfaz y verifican guardados, perfil y próximo inicial. El empaquetador RC4 es `tools/godot/package-stability.py`; las reglas continúan en edición30.

## Informes RC5

`npm run godot:qa:feedback` y `npm run godot:qa:feedback:export` verifican el formulario en perfiles aislados: Inicio y combate natural, teclado/ratón, Escape/foco, texto150%, copia, UTF-8 y URI de correo. No abren ni envían correo. En Windows la comprobación real del portapapeles necesita una sesión interactiva con acceso al escritorio. `tools/godot/package-feedback.py` exige estas pruebas y la regresión de Pokédex en ambas compilaciones. La campaña completa deRC4 se conserva como evidencia histórica de reglas sin cambios. [Uso](../docs/FEEDBACK.md).

## Nombre RC6

Pokémon: Tactical Chronicles — Kanto. Las rutas de distribución se definen con `config/artifact_slug` y `config/executable_name`. `godot:qa:feedback` añade portada, controles y lectura de un guardado/perfil RC5; busca la muestra aislada en `../../work/qa-sprint-42/feedback-source` o en `BRANDING_LEGACY_DIR`. Si falta, ejecuta el EXE RC5 con `--feedback-qa-dir=RUTA_AISLADA` y sus variables APPDATA/LOCALAPPDATA también aisladas. No uses partidas personales. [Detalles](../docs/RELEASE_1_0_RC6.md).
