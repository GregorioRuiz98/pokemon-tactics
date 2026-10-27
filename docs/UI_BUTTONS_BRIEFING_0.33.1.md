# Botones y reconocimiento del rival — 0.33.1

La preparación muestra automáticamente el equipo enemigo antes de comenzar. Las tarjetas incluyen retrato, nombre, nivel, tipos y habilidad; los refuerzos se identifican cuando están presentes en el encuentro. Clic o Tab/Enter abre la ficha, con PS, movimiento, estadísticas, naturaleza, habilidad y movimientos equipados, incluido el básico. Las técnicas conservan potencia, precisión, alcance, área y efectos del catálogo de esa partida.

La información procede de las unidades ya generadas, no de una segunda tirada ni de una plantilla de especie. Consultar o cerrar no consume azar ni guarda órdenes. Escape devuelve el foco a la tarjeta. El botón y el atajo de comenzar siguen disponibles directamente; no hay otra confirmación obligatoria. El panel desaparece al empezar y se recupera al cargar un guardado durante la preparación.

Los botones comparten marcos completos, relieve, esquinas perfiladas, detalles interiores y estados diferenciados de selección, pulsación y desactivación. Jade para acciones principales, tinta para herramientas y marfil para opciones. El cursor de órdenes distingue foco y reposo. Son controles nativos; los adornos solo se redibujan al interactuar, sin bucle de animación ni imágenes adicionales. Se conservan fuentes legibles, alto contraste y controles de teclado.

En ventanas pequeñas con texto al 150 %, el panel deja libre la columna de preparación y permite desplazarse por las tarjetas. Las fichas largas tienen desplazamiento vertical. La barra de cámara vuelve a su altura normal después de reducir el tamaño del texto.

## Verificación

- Prueba nativa `godot:qa:briefing`: nueva partida, entrada, consulta por ratón/teclado, cierre, guardado/carga y comienzo; después, fixtures de presentación de los 58 encuentros reales, incluidos Brock y los dos encuentros legendarios. No equivale a volver a jugar la campaña completa.
- Regresiones `godot:qa:review` y `godot:qa:symbols`: equipo/PC numerosos, bibliotecas de movimientos, iconos, combate y tienda. Versiones fuente y ejecutable Windows; resultados y capturas en `docs/qa/sprint-33-ui-1`.
- Validación de recursos y scripts, lint y comparación de archivos protegidos contra `745552d`. Los resultados exactos se registran en `verification.json` y `release.json` al empaquetar.

Se mantienen campaña26/capítulo30/combate23 y los guardados de 0.33.0. No cambian reglas, enemigos, EXP, precios ni balance. Se reutilizan retratos e iconos locales con sus créditos existentes; no hay nuevas descargas al jugar ni dependencias.

El ejecutable se entrega sin publicación pública. Quedan pendientes las pruebas con personas y otros equipos físicos; la carga síncrona de diarios largos señalada en 0.33.0 sigue fuera de este cambio visual.
