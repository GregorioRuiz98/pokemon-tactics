# Combate del claro — extensión del tablero

Modo: Experience, con controles de operación explícitos. Público y producto definidos en PRODUCT.md. Se conserva el bosque, la selección ámbar, Pixelify Sans y los sprites reales. El propio tablero protagoniza la pantalla.

Acción principal: completar una batalla 3 contra 3. Jerarquía: tablero, cola compacta en el borde superior, panel de unidad activa y órdenes en el borde inferior, ficha de objetivo en la esquina opuesta. Inspeccionar una unidad no transfiere su turno. Aliados azules/enemigos terracota, además de texto A/E y etiquetas accesibles; el color no es el único indicador.

La ficha muestra movimiento y acción disponibles. Elegir un destino muestra ruta/coste; elegir un enemigo muestra daño previsto. Ambos se confirman o cancelan. Terminar turno renuncia a lo que quede. La cola solo muestra el orden, no órdenes futuras de la IA. Las bajas desaparecen del tablero y de los turnos pendientes.

Semilla y variación (5 % o 10 %) se configuran antes de reiniciar la batalla. El reinicio reproduce posiciones y tiradas. Victoria/derrota se muestran en el tablero con resumen y botón para volver a jugar. Ensayo de movimiento y campamento se mantienen como rutas secundarias.

Objetivos de revisión: 1440×1000 y 390×844. Cola adaptable sin desbordamiento; tablero cuadrado; ficha debajo en estrecho. Flechas/Enter/Espacio en la cuadrícula, Escape para cancelar, foco visible y pausa de animaciones. Movimiento reducido omite transiciones de desplazamiento; la IA continúa resolviendo sus turnos.

## Ajuste de interfaz del sprint 2 — 14 de octubre de 2026

Referencia aportada por el usuario: captura de RPG táctico con escenario protagonista, paneles de atacante/objetivo en esquinas y previsión de ataque central. Se adapta la organización al tablero superior existente; no se convierte la perspectiva a isométrica ni se incorpora ninguna nueva mecánica.

La pantalla es una superficie de juego. Órdenes, confirmación, cancelación y terminar turno quedan dentro del marco del escenario. Los retratos reutilizan miniaturas de Pokémon. Los PS y recursos de la unidad activa se distinguen de la ficha consultada. La previsión central muestra precisión y daño reales del prototipo. Semilla, reinicio, lista de unidades, registro y accesos a prototipos anteriores se encuentran en Opciones.

En escritorio, HUD de esquinas y órdenes centrales ocupa la franja inferior reservada fuera de las casillas. Nunca se tapa una casilla interactiva. En estrecho, el mismo HUD se apila inmediatamente bajo el tablero dentro del marco de juego; conserva scroll nativo, teclado y controles táctiles. La nueva composición no requiere ilustraciones externas ni modificar sprites.

Estados: carga con interacción deshabilitada; catálogo vacío/error con recarga; hojas ausentes con marcador y aviso; orden inválida sin gasto; orden pendiente confirmable; desplazamiento/turno enemigo con bloqueo de órdenes del jugador; batalla activa; victoria/derrota con reinicio. Sin permisos ni cuentas.
