# Estado y próximos pasos

Actualizado el 27 de octubre de 2026. Versión jugable **0.34.1**, entrega privada Windows. El [plan acumulado](history/PLAN_SPRINTS_2026-10-27.md) y los informes por sprint son historial, no una lista de trabajo pendiente.

## Comprobado

| Entrega | Evidencia | Alcance real |
| --- | --- | --- |
|0.34.0 — campaña | [Verificación](qa/sprint-34/verification.json), [informe](SPRINT_34_TACTICAL_QUALITY.md) |58 lugares,57 combates,8 medallas y 7.861 órdenes legales automatizadas; Liga → aves → Mew/Mewtwo. |
|0.34.1 — interfaz | [Verificación](qa/sprint-34-ui-1/verification.json), [cambios](UI_PRECOMBAT_0.34.1.md) |1.958 comprobaciones de previa,46 de regresión y 270 de iconos por build; fuente y EXE coinciden:4.548 en total. |
| Validación 0.34.1 | [Registro](qa/sprint-34-ui-1/release.json) | Sin errores ni avisos nuevos;65 avisos heredados. No acredita otro PC ni sesión humana. |

Se conserva el balance aceptado. Los intentos fallidos y límites del jugador automático constan en los informes. La limpieza documental no modifica el ejecutable ni sus reglas.

## Antes de una primera beta pública

| Pendiente | Criterio de cierre |
| --- | --- |
| Otro ordenador físico | Arranque sin Godot/sin conexión, sonido, guardado/recuperación, resoluciones y DPI reales. Resultado fechado y especificaciones. |
| Jugadores externos | Comprender menús, preparación y objetivos sin acompañamiento; probar principio/mitad/final y registrar bloqueos. [Protocolo](PLAYTEST_0.34.md). |
| Procedencia/permisos | Resolver alcance de distribución de sprites/retratos, muestras originales de sonido y demás contenido. [Inventario](LICENCIAS.md). Hashes/créditos no acreditan permiso sobre la IP. |
| Canal y contacto | Elegir dónde ofrecer el ZIP y contacto del creador. No inventar correos ni reutilizar los de otros proyectos. Publicar el juego no exige abrir el repo. |
| Artefacto definitivo | Verificaciones pertinentes, avisos conservados, ZIP/SHA-256 comprobados y versión/commit anotados. [Procedimiento](DEPLOY.md). |
| Autorización final | El creador indica cuándo y dónde publicar. No se ha publicado ni cambiado visibilidad. |

No se fija un objetivo de FPS, duración o éxito de los tres iniciales sin medirlo. Las pruebas son una base para la beta, no evidencia de recepción pública, viralidad o accesibilidad con lector audible.

## Retirado deliberadamente

| Antes | Ahora |
| --- | --- |
| Amenazas/T y cobertura rival automática | Fichas de rivales y terreno, sin promesa de intención enemiga. |
| Roles rígidos | Repertorios por especie y cuatro técnicas preparadas. |
| PT al atacar | PP al equipar y básico gratuito. |
| Caramelos/piedras/cables y pestaña Entrenar | EXP restante desde Equipo → Ficha y evolución por nivel/elección gratuita al umbral. |
| Tres iniciales aleatorios y finales excluyentes | Un inicial de Oak; Liga/rival → aves → Mew/Mewtwo. |
| Servidor obligatorio | Ejecutable offline y perfil local. |

No reintroducir estas funciones por leer una descripción antigua. [Reglas](REGLAS_ACTUALES.md) · [Arquitectura](ARCHITECTURE.md) · [Índice](README.md).
