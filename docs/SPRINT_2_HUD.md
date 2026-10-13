# Ajuste del sprint 2 — HUD dentro del gameplay

14 de octubre de 2026. Versión **0.2.1**, rama `codex/sprint-2`.

El usuario pidió integrar los botones dentro del gameplay y aportó una captura de RPG táctico como referencia. Este trabajo es un ajuste de presentación del sprint 2; el sprint 3 sigue pendiente.

## Entrega

- Marco único de juego: tablero protagonista, ronda/cola compacta arriba y órdenes dentro de la franja inferior del escenario.
- Retrato, PS, movimiento, acción y datos de la unidad activa en una esquina; ficha consultada/objetivo en la opuesta.
- Previsión central con daño, precisión y cambio de PS del objetivo; confirmar/cancelar aparece al elegir una orden.
- Mover, ataque básico y terminar turno integrados en el HUD. Todas las casillas quedan libres de controles.
- Opciones agrupa semilla, variación, reinicio, unidades, registro y accesos a ensayo/campamento. Escape o pulsar fuera cierra el menú; Escape devuelve el foco a su apertura.
- En estrecho, paneles y órdenes se reordenan dentro del mismo marco, inmediatamente bajo el mapa. Se conserva scroll nativo, teclado y movimiento reducido.
- Retratos reutilizados de las miniaturas locales. Sin nuevos paquetes, recursos externos ni modificaciones de sprites.

## Comprobaciones ejecutadas

| Comprobación | Resultado |
| --- | --- |
| Build / TypeScript | Correctos |
| Pruebas de reglas | 21 aprobadas |
| Integridad de recursos | 6 especies, 12 hojas y 33 hashes verificados |
| Navegador de desarrollo | 22 comprobaciones de combate y HUD aprobadas |
| Producción local, puerto 4173 | Las mismas 22 comprobaciones aprobadas |
| Flujo completo | Victoria, derrota, repetición de semilla, órdenes en ambos sentidos, cancelación, reinicio y recuperación |
| Geometría | HUD no cubre casillas en 1440×1000, 1280×768, 900×1000 y 390×844 |
| Menú y foco | Escape cierra Opciones y devuelve foco; cancelación devuelve al tablero |
| Recursos gráficos | Retratos cargados con dimensiones reales; marcador funcional si falla una hoja de animación |
| Visitas correctas | Sin errores JavaScript/consola ni solicitudes externas |
| Revisión visual | Escritorio y móvil revisados; capturas en `qa/sprint-2-hud` |

El detector de Impeccable señaló retratos sin `src` en el HTML inicial, aunque se asignaba al refrescar. Se añadieron fuentes locales desde el primer render; la prueba de navegador comprueba su carga. El informe original del detector se conserva, sin presentarlo como una revisión limpia posterior.

No se configuró ni ejecutó un linter o una auditoría WCAG completa. Solo Edge/Chromium probado; otros navegadores y dispositivos reales pendientes. Se mantiene el aviso conocido del tamaño de Phaser.

## Alcance conservado

La vista sigue siendo superior, con las reglas y valores provisionales del sprint 2. La referencia guía la composición del HUD; no cambia perspectiva, iniciativa, daño, precisión, IA ni recursos por activación. Tabla de tipos, habilidades y estados pertenecen al sprint 3.
