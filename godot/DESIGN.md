# Laboratorio táctico — menú flotante 0.13.2

Referencia del usuario: menú vertical de órdenes a la derecha dentro de la escena, retratos y estadísticas en las esquinas inferiores. Sustituye la franja de botones de 0.13.1. Paleta de paneles azul petróleo/cian, selección dorada, texto marfil y fuente local Pixelify Sans.

El menú se muestra automáticamente durante activaciones aliadas. Principal: Habilidades, Rectificar movimiento, Orientar y terminar. Habilidades abre los tres movimientos; al elegir objetivo solo permanece Volver. Orientación muestra las cuatro direcciones; confirmación únicamente con riesgo aliado. El movimiento se selecciona directamente en el tablero. A/R/F y 1/2/3 son atajos.

Rectificar exclusivamente el último movimiento aceptado, antes de cualquier acción y antes del cierre del turno. Atacar antes de moverse también impide rectificar. Reconstruir y validar el diario; solo pueden variar x/y, facing, remaining, moved y su registro. PS/PT, estados, RNG y demás unidades se conservan. Persistir el diario revisado antes de presentar. No se introduce una orden Deshacer genérica.

La ficha activa lleva retrato de diálogo PMD 40×40 original ampliado con nearest, PS/PT, disponibilidad y barra de salud. La ficha objetivo aparece al inspeccionar una unidad; mantiene previsión extensa desplazable. El mensaje contextual ocupa el hueco inferior central. La cola sigue encima del escenario. Reservar zonas para el HUD: ninguna casilla jugable queda cubierta; comprobarlo a distintas resoluciones.

Conservar la vista cenital actual. Isometría y alturas son un sprint posterior por decisión expresa del usuario. La representación puede cambiar sin rehacer el dominio; las alturas requerirán datos de elevación, reglas de desnivel/rampas/vuelo, alcance/visibilidad, IA y guardados. No decidir bonificaciones de daño ahora.

No representa todavía la campaña de Rojo. Probar renderizado mínimo/medio/grande, teclado, ratón, submenús, guardado y cancelación; movimiento reducido y sonido independientes del PRNG.
