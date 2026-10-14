# Gestión entre encuentros — sprint 6

Ampliación del juego existente, modo Operate. Se conserva verde bosque, ventanas azul oscuro, acento dorado, Pixelify Sans y sprites locales. El jugador debe ver saldo, existencias, PS, efecto de cada objeto y coste de reclutar antes de actuar.

Una sala de tienda y otra de reclutamiento forman cada bifurcación de servicios, también antes del primer combate. Elegir una excluye la otra en ese tramo. La columna de equipo conserva PS y objeto equipado; la zona central muestra mercancía o candidatos y permite abrir la bolsa. La ruta completa usa un panel con scroll nativo y centra el próximo paso disponible. En móvil los controles y el equipo se apilan sin ocultar compras ni opciones de sustitución.

Tienda con filas de mercancía, precio, existencias y botón de compra. Bolsa con selector nativo de miembro, previsión de recuperación y equipables; un único hueco, cambio reversible que devuelve el anterior. Reclutamiento con tres fichas de Pokémon y coste. Sustituir abre confirmación inline, también antes de llenar el equipo, con selección del miembro saliente; cancelar/Escape conserva dinero, oferta y equipo, y devuelve el foco.

Decisión del usuario: recuperar el objeto cuando cae un Pokémon, igual que al sustituirlo. Los miembros perdidos y liberados quedan en un registro separado y no vuelven a desplegarse. Guardado versión 2 con copia de la versión 1 al actualizar; conservar PS y RNG de una pelea en curso. Estado, saldo y existencias se anuncian tras cada acción. Parámetros de combate y repertorios conservados; precios y recompensas son propuestas nuevas para probar la economía. No se incorporan niveles, evoluciones ni jefes.
