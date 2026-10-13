# Combate del claro — extensión del tablero

Modo: Experience, con controles de operación explícitos. Público y producto definidos en PRODUCT.md. Se conserva el bosque, la ficha marfil, la selección ámbar, Pixelify Sans y los sprites reales. El propio tablero protagoniza la pantalla.

Acción principal: completar una batalla 3 contra 3. Jerarquía: ronda y cola de iniciativa, tablero con bandos/PS, ficha de la unidad inspeccionada y órdenes de la unidad activa. Inspeccionar una unidad no transfiere su turno. Aliados verdes/enemigos terracota, además de texto A/E y etiquetas accesibles; el color no es el único indicador.

La ficha muestra movimiento y acción disponibles. Elegir un destino muestra ruta/coste; elegir un enemigo muestra daño previsto. Ambos se confirman o cancelan. Terminar turno renuncia a lo que quede. La cola solo muestra el orden, no órdenes futuras de la IA. Las bajas desaparecen del tablero y de los turnos pendientes.

Semilla y variación (5 % o 10 %) se configuran antes de reiniciar la batalla. El reinicio reproduce posiciones y tiradas. Victoria/derrota se muestran en el tablero con resumen y botón para volver a jugar. Ensayo de movimiento y campamento se mantienen como rutas secundarias.

Objetivos de revisión: 1440×1000 y 390×844. Cola adaptable sin desbordamiento; tablero cuadrado; ficha debajo en estrecho. Flechas/Enter/Espacio en la cuadrícula, Escape para cancelar, foco visible y pausa de animaciones. Movimiento reducido omite transiciones de desplazamiento; la IA continúa resolviendo sus turnos.

Estados: carga con interacción deshabilitada; catálogo vacío/error con recarga; hojas ausentes con marcador y aviso; orden inválida sin gasto; orden pendiente confirmable; desplazamiento/turno enemigo con bloqueo de órdenes del jugador; batalla activa; victoria/derrota con reinicio. Sin permisos ni cuentas.
