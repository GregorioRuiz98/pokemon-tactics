# Decisiones de preparación

13 de octubre de 2026.

- Base adaptada de `phaserjs/template-vite-ts`, commit registrado en `tools/sources.lock.json`. Se conservan enfoque de arranque, configuración de TypeScript y separación del motor en la compilación. Se retiran escenas de ejemplo y llamadas de telemetría. Vite queda fijado al parche 6.4.4 compatible; Phaser 4.0.0 y TypeScript 5.7.3.
- Datos reales de Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude. El catálogo se valida al cargar. No se generan aún los tres miembros aleatorios de una partida.
- Reutilización directa de `parse_animdata`, `resolve` y `ground_anchor` del importador MIT de PokéSurvivor. El archivo original permanece en `tools/vendor` con versión fija. El adaptador limita la descarga a seis especies normales y dos animaciones.
- Recursos SpriteCollab originales sin recolorear; miniaturas derivadas del primer fotograma. Suelo de la escena dibujado mediante primitivas; no requiere un tileset para esta galería.
- Las coordenadas de sprite representan el punto de apoyo obtenido de las hojas de sombra. Duraciones de animación convertidas desde ticks de 60 Hz. El marco incluye ocho direcciones; la UI ofrece cuatro cardinales.
- Solo carga local durante la ejecución. Font local. Sin cuentas, analítica, claves, nube ni persistencia de partidas.
- Guardado, tabla de efectividad, daño, iniciativa y tablero se incorporarán en sus sprints. Los tipos y estadísticas mostrados ya son los datos modernos.
- El primer objetivo es PC. La galería se revisa también en 390 px para evitar desbordamientos, sin comprometer soporte completo de juego móvil.
- La carpeta del proyecto tiene un repositorio Git propio en `codex/sprint-0`. La inspección inicial detectó un repositorio ajeno en la carpeta personal; no se cambió su configuración ni contenido.

Valores de iniciativa, puntos tácticos, estados y duración siguen siendo propuestas del plan. No se han convertido en mecánicas por aparecer en esta documentación.

## Sprint 1

- EasyStar 0.4.4 se integra como dependencia fija: A* con costes de terreno, cuatro direcciones y ocupantes excluidos. En 64 casillas la búsqueda síncrona de rutas es suficiente; no se implementa un algoritmo propio paralelo. Versión e integridad en package-lock.json, licencia local.
- Todas las unidades usan perfil terrestre provisional. Suelo 1, maleza 2, rocas y agua infranqueables. Geodude dispone de 3 puntos, Pikachu 5, el resto 4; son parámetros para probar legibilidad y control, pendientes de equilibrio.
- El coste se cobra al confirmar, con una nueva validación del camino y la ocupación. La trayectoria previa y su cancelación no alteran estado. Durante el desplazamiento se bloquean órdenes; pausa/reanudación permanece accesible.
- El ensayo permite repartir el presupuesto entre varios desplazamientos hasta reiniciar. El sprint 2 sustituirá este contexto libre por activaciones y rondas.
- Los sprites y estadísticas del sprint 0 se reutilizan sin nuevas descargas de especies. El terreno se dibuja con primitivas de Phaser. La cuadrícula HTML aporta nombres de casilla, selección y teclado equivalentes al canvas.
- Playwright 1.64.0 queda como dependencia de desarrollo, con prueba de navegador reproducible. No se incluye en el juego de producción.
