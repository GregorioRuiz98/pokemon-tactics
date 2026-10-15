# Laboratorio táctico — sprint 13

Fans de Pokémon y RPG tácticos; ensayo manual 3v3 que comprueba el port antes de Kanto. Acción principal: elegir movimiento/casilla, revisar previsión y confirmar. La orientación final forma parte de las órdenes. Nueva partida y opciones quedan fuera del tablero.

Conservar la identidad del prototipo: verde oscuro, suelo apagado, texto marfil, selección ámbar y Pixelify Sans; sprites direccionales Mystery Dungeon originales. Cola encima del mapa, equipo a la izquierda, objetivo/previsión a la derecha y órdenes debajo. Ningún panel cubre casillas. No presentar este laboratorio como la campaña larga ni incluir una selección de inicial ficticia.

Controles Godot nativos con foco; tablero por ratón y flechas/Enter, Escape para cancelar, atajos M/1/2/3/F/F8. Mostrar coste, precisión, eficacia, recuperación y aviso de fuego aliado antes de confirmar. Pausar IA al abrir diálogos; animación y sonido no afectan al RNG. Permitir desactivar ambos. Rutas se confirman; en esta entrega el cambio de casilla es inmediato y los sprites tienen animación Idle. Animación Walk y cámara para mapas mayores quedan para el acabado posterior.

Comprobar 1024×720, 1280×900 y 1440×1000; vistas de nuevo ensayo, movimiento, ataque, orientación y resultado. Carga fallida conserva el archivo; error de escritura permite seguir en memoria y lo indica. El guardado nativo usa un diario independiente y nunca lee ni sobrescribe localStorage.
