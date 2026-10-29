# Sprint 41 — Pokédex y verificación del ejecutable

29 de octubre de2026. Producto1.0.0-rc.4; etapaQA41. Campaña30/capítulo34/combate25,
sin cambios de reglas, recursos ni balance.

## Corrección BETA-03

La ficha reutilizaba el diálogo global de la aplicación mientras Entrenador ya
ocupaba la ventana exclusiva del juego. Godot rechazaba una segunda ventana
exclusiva hermana. `trainer_panel.gd` ahora conserva una ficha hija propia y
`collection_browser.gd` la abre en ese contexto. La ficha se reutiliza y se
oculta al cerrar el padre; no se cambia el diálogo de compras o movimientos.

`qa_dex_dialog.gd` inicia un combate normal y comprueba inspección sin modificar
estado, RNG ni diario; teclado y ratón; Escape; retorno del foco; búsqueda;
cierre del padre;1280×900/100% y1024×720/150%.72 comprobaciones por build.

## Campaña completa desde la interfaz

`qa_candidate_journey.gd` ejecuta las10.277 órdenes originales de una simulación
legal de la edición30. Usa los manejadores normales de la interfaz y sus
guardados; no inyecta estados, victorias, PS, dinero ni capturas. Compara el
estado final con la simulación y comprueba perfil, legendarios, diario completo
sin certificado y nuevo inicial Zapdos de nivel5 mediante el selector real.
Los tiempos de recuperación de campaña y del inicial siguiente se registran
por separado. Es un recorrido automático, no una sesión humana.

```sh
npm run godot:prepare:candidate:journey
npm run godot:qa:dex
npm run godot:qa:candidate:journey
npm run godot:export
npm run godot:qa:dex:export
npm run godot:qa:candidate:journey:export
npm run godot:package
npm run godot:check:candidate
```

La preparación requiere el diario original de la simulación de RC3 o uno
reproducido con `npm run godot:simulate:relief`. Verifica comandos, estado final
y hash del catálogo antes de crear la estrategia de prueba fuera de Git.

Evidencia de esta revisión: `docs/qa/sprint-41/`. El empaquetador exige resultados
fuente/EXE coincidentes y posteriores a la compilación, junto a lint y
validación sin errores ni avisos nuevos. Las pruebas de terreno y motor de RC3
son evidencia previa del código conservado; no se presentan como repetidas.

Siguen pendientes jugadores externos, otro ordenador físico, audio escuchado
y DPI real. El ZIP se prepara localmente; no hay publicación automática.

## Resultado

Proyecto y EXE superan20.574 comprobaciones de campaña y72 de Pokédex cada uno. Se ejecutan10.277 órdenes,58 lugares,57 combates y8 medallas, con los dos desafíos legendarios en orden. Coinciden el estado final y la aventura siguiente con Zapdos de nivel5. La lectura íntegra sin certificado tardó62.422ms en fuente y85.145ms en EXE en este PC; no son tiempos normales de carga con certificado.

Lint y validación:0 errores,65 avisos heredados y0 nuevos. Motores, datos, pruebas y recursos publicados conservan sus archivos. No se repite el banco de reglas de RC3 porque esta revisión solo cambia la interfaz.
