# Limpieza de repositorio y documentación — 27 de octubre de 2026

Base: `6229eed01079d7a4bdca46eb805f3ae2c4156568`, juego 0.34.1. Cambio documental y de herramientas locales; no modifica escenas, lógica, datos, recursos ni balance.

## Cambios

- README centrado en Windows; prototipo web identificado por separado.
- Índice de documentación, arquitectura vigente y estado real de lanzamiento. Producto e instrucciones de desarrollo dejan de acumular requisitos contradictorios.
- Nueve documentos originales conservados literalmente en `history/`, además del historial de Git. Los motores antiguos y las pruebas/evidencias no se borran: sostienen guardados y reproducción de errores.
- Guías de Windows, portfolio y entrega actualizadas; inventario de licencias con audio original y fuentes oficiales. No se añade una licencia global al contenido ajeno.
- El paquete incluye los informes enlazados y los mapas actuales; su documentación se valida dentro del propio paquete. La guía duplicada ya no anuncia 0.33.0 y el empaquetado actual no necesita leer un LEEME de la antigua entrega 0.26.0.
- Exclusiones Git para builds, registros, perfiles, partidas y claves locales. Comprobador de rutas indexadas, enlaces mantenidos, scripts documentados y coherencia de versiones, con pruebas propias.

## Verificación

Ejecutadas: `npm run check:repo`, `npm run test:repo-check`, `npm run godot:verify` y revisión del diff. Resultado local en [repository-check.json](qa/repository-check.json). El comprobador tiene seis casos de prueba sobre rutas sensibles, enlaces, escapes y comandos. No usa servicios externos.

La comprobación de rutas no es un escaneo del contenido ni del historial en busca de secretos; los enlaces remotos y sus fragmentos tampoco se validan automáticamente. Las copias históricas se excluyen de la validación de enlaces porque conservan las rutas originales de su documento.

El EXE permanece idéntico al probado en 0.34.1. Se actualiza la documentación del ZIP y su checksum; el SHA del EXE y los hashes finales constan en [registro de entrega](qa/sprint-34-ui-1/release.json). Las pruebas de juego anteriores se reutilizan porque no cambia código jugable, no se presentan como ejecutadas de nuevo.

## Pendientes reales

Pruebas con jugadores y otro PC físico, revisión de permisos de distribución y elección de contacto/canal público. Fuente canónica: [Estado](PLAN_SPRINTS.md). No se publica ni se cambia visibilidad. La revisión de documentación no convierte estos pendientes en superados.
