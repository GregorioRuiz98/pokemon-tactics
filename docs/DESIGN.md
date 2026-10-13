# Campamento: contrato de interfaz del sprint 0

Superficie: galería local de seis especies; acción principal: seleccionar una especie para consultar sus datos y animación. No es una selección definitiva de equipo ni un tablero de combate.

Referencia: Pokémon Mystery Dungeon para sprites direccionales y tipografía pixel; libreta de expedición para jerarquía. Fondo verde oscuro, suelo apagado, ficha marfil y selección ámbar. El campamento mantiene visibles las seis especies; la ficha coloca nombre y tipos antes del rol propuesto y estadísticas reales.

Objetivos de revisión: 1440x1000 y 390x844. En escritorio, escena y ficha contiguas; en móvil, escena, ficha y botones apilados sin desplazamiento horizontal. El alcance de juego sigue siendo PC.

Los controles son HTML semántico; la selección del canvas tiene equivalente en botones accesibles. Flechas izquierda/derecha recorren compañeros. Escape cierra créditos. Foco visible y contraste legible. Animaciones pausables; `prefers-reduced-motion` las pausa inicialmente.

Estados: carga de catálogo y hojas con progreso; fallo de catálogo con reintento; recurso gráfico parcial con aviso y reintento; éxito con campamento listo. Un catálogo vacío se trata como error de instalación, no como una colección vacía válida. No hay permisos, cuentas ni datos privados solicitados.

Comprobar alineación de cada especie en Idle/Walk y orientaciones cardinales. No animar el desplazamiento entre posiciones: ese comportamiento pertenece a otro sprint.
