# Arquitectura actual

Mapa de la campaña Windows. Las reglas están en [Reglas actuales](REGLAS_ACTUALES.md); comprobaciones y pendientes en [Estado](PLAN_SPRINTS.md).

| Necesidad | Ubicación | Observación |
| --- | --- | --- |
| Entrada | `godot/scenes/campaign.tscn`, `godot/ui/campaign.gd` | Menús, viaje y coordinación; guarda antes del feedback. |
| Motor vigente | `godot/core/closing_run.gd`, `tactics_quality_battle.gd` | Campaña 29/capítulo 33/combate 24; extiende motores publicados. |
| Guardados | `godot/core/closing_store.gd`, `collection_store.gd` y stores anteriores | Replay, estados canónicos, copias y conflictos. |
| Mapas/contexto | `godot/core/tactics_opening.gd`, `godot/data/tactics-opening.json` |58 localizaciones,16/24 casillas; [catálogo](MAPAS_0.34.csv). |
| Previa/estilo | `godot/ui/encounter_preview.gd`, `game_skin.gd`, `move_symbols.gd` | Consulta sin cambiar estado/RNG. |
| Perfil/logros | `godot/core/collection_profile.gd`, `collection_profile_store.gd`, `godot/ui/trainer_session.gd` | Independientes del diario de campaña. |
| Recursos | `godot/data/`, `godot/assets/`, `godot/art/`, `godot/licenses/` | Locales, con hashes/autores/condiciones. |
| Pruebas | `godot/tests/`, `godot/ui/qa_*.gd`, `tools/godot/` | Perfiles aislados, suites actuales e históricas. |
| Evidencia | `docs/qa/`, `docs/reports/` | Capturas y diarios históricos consumidos por pruebas. |
| Web | `src/`, `public/`, `tests/` |0.12.0 independiente; [guía](WEB_LEGACY.md). |

## Estado, comportamiento y versiones

Estado serializable y órdenes separados de la representación. Acciones compuestas y reglas compartidas entre jugador, IA y previsión; tipos/evoluciones son datos. Consultas, animaciones y sonidos no consumen el azar de la partida.

La UI acepta una orden, persiste el resultado y después presenta feedback. La revisión impide callbacks obsoletos. Los motores antiguos se eligen por edición del guardado: no son código muerto que se pueda borrar por no aparecer en una importación directa.

Actualización explícita entre encuentros y con copia; combates en curso conservan sus reglas. La validación certificada acelera lecturas comprobadas sin eliminar el diario; sin certificado se reproduce completo. Los auxiliares no son una cuenta ni protección frente a edición deliberada del propio ordenador.

## Distribución

El exportador incrusta recursos en el EXE. El paquete añade documentación y avisos; el jugador no necesita código, Node, Python ni Godot. `GODOT_BIN`, plantillas y herramientas son requisitos de desarrollo.

ZIP fuera del repo; sin perfiles QA ni guardados personales. [Guía de entrega](DEPLOY.md) e [inventario de licencias](LICENCIAS.md).

[Arquitectura web anterior](history/ARCHITECTURE_WEB_2026-10-27.md), conservada para interpretar sus pruebas.

Colección 0.35: `collection_catalog.gd` unifica familias/umbrales publicados sin cambiarlos. El perfil v2 conserva obtenidos (`dex`) y vistos (`seen`), normaliza los identificadores JSON y deriva iniciales por línea. `collection_store.gd` añade eventos recuperables a la bandeja existente; el diario de campaña continúa siendo la fuente del replay. Las consultas de Pokédex y ofertas no consumen RNG.

Cierre1.0: `closing_run.gd` congela las ofertas de cada mostrador en el estado; `closing_store.gd` conserva replay y actualización explícita hasta edición29. Códigos KT36. La UI construye solo la pestaña visible y agrupa preferencias; el lector asíncrono bloquea órdenes durante la reconstrucción. La etapa QA38 es independiente de la versión1.0.0-rc.1.
