# Interfaz y previa al combate — 0.34.1

## Resultado

La caja de habilidades y sus botones usan blanco como fondo principal y texto oscuro. El amarillo aparece al pasar el ratón, también cuando la opción ya estaba seleccionada. Selección, pulsación y opciones desactivadas conservan el blanco; el foco de teclado tiene un contorno oscuro. Alto contraste conserva su presentación alternativa. Se corrigen los estilos que heredaban los márgenes de los iconos y mantenían el fondo oscuro anterior.

Viaje muestra los enemigos **antes de pulsar Entrar**, en un panel propio a la derecha; contexto, objetivo y descripción del terreno quedan a la izquierda. Equipo/PC abre la preparación aliada y Viaje devuelve la lista rival. Las tarjetas incluyen retrato, nombre, nivel, tipos, PS, habilidad y movimientos preparados, incluido el básico. Ratón o teclado abren la ficha completa con estadísticas y efectos de movimientos; Escape devuelve el foco. El botón Entrar sigue accesible. El despliegue conserva su consulta rival.

La previa usa el generador real sobre una copia, con caché por el estado completo de la aventura. No acepta órdenes, guarda partidas ni consume su azar. Cambiar destino, equipo, tamaño o semilla invalida la caché. La prueba compara la previa con el encuentro que realmente se inicia. Safari muestra su visita narrativa, sin inventar enemigos. El prototipo original sin niveles conserva su pantalla clásica.

Se retiran del juego el botón Amenazas, el atajo T, las marcas sobre casillas y la consulta automática de cobertura al mover el cursor. La IA mantiene sus reglas publicadas.

## Comprobaciones

- Suite briefing ampliada: entrada natural desde Oak; consulta previa con ratón/teclado y retorno de foco; igualdad del encuentro antes/después de Entrar; conservación de estado, RNG y diario; fichas de los 58 lugares; movimientos preparados visibles; ausencia de combate ficticio en Safari; menú blanco, selección y hover; ventana de 1024×768 con texto150% y alto contraste.
- Regresiones review y symbols: apertura natural, guardado/recarga, equipo/biblioteca e iconos.
- Ejecución sobre fuente y ejecutable Windows; cifras finales y comparación de estados en `qa/sprint-34-ui-1/verification.json`.
- Lint sin incidencias; validación sin errores y con los65 avisos previos, sin avisos nuevos. Dos escenas instanciadas sin avisos de configuración.
- Sin cambios en reglas, datos, recursos, pruebas publicadas ni balance. Campaña27/capítulo31/combate24 y guardados existentes conservados.

Son pruebas de interfaz y fixtures de presentación de todo Kanto. No se ha vuelto a jugar una campaña completa ni se ha realizado una prueba humana externa o en otro equipo físico. Se prepara la entrega local y el código privado; publicación pública pendiente.
