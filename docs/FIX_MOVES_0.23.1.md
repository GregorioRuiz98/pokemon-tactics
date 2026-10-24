# Corrección de ranuras de movimientos — 0.23.1

En Equipo → Movimientos, los cuatro botones se quedaban en el ancho mínimo del marco al ajustar el texto. Los nombres desaparecían en columnas de unos 28 píxeles y las filas crecían hacia abajo. Las dos columnas ahora se expanden hasta ocupar el panel y mantienen los nombres alineados a la izquierda.

Se conserva la selección de ranura por ratón o teclado, el resaltado, las ranuras vacías y la restricción de llenarlas consecutivamente. No cambia el repertorio, el guardado, la economía ni las reglas: campaña 19/combate 18. También beneficia a partidas anteriores. Abre el ejecutable 0.23.1 y continúa la partida; no hace falta iniciar ni actualizar la aventura por este arreglo.

## Comprobaciones

- QA nativa específica: 304 comprobaciones en desarrollo y otras 304 en el ejecutable, con resultados idénticos. Incluye nombres largos, cuatro movimientos, 0/1/3 ranuras ocupadas, mapa/tienda, contraste alto y selección con teclado/ratón. Cancelar una sustitución conserva estado completo, diario y RNG.
- Resoluciones 1024×720, 1280×900 y 1920×1080, cada una al 100/125/150 % de texto. Verificación del ancho y altura reales del texto, ausencia de solapes y desplazamiento al enfocar la ranura.
- Regresión de interfaz espacial: 63 comprobaciones por versión de desarrollo/ejecutable. Motor espacial: 557 comprobaciones sin fallos.
- Validación Godot: cero errores; 65 advertencias existentes, ninguna nueva. Reglas/datos/pruebas del motor y versión web sin cambios respecto a 0.23.0. No se ha repetido toda la campaña para esta corrección visual; la evidencia anterior de los finales está en `docs/qa/sprint-23`.

Scripts reproducibles: `godot:qa:moves`, `godot:qa:moves:export`, `godot:qa:spatial`, `godot:qa:spatial:export`, `godot:test:spatial`. Todos los guardados de prueba están aislados. Evidencia y capturas: `docs/qa/moves-0.23.1`. Paquete Windows offline en `outputs/releases/pokemon-tactics-0.23.1`; sin publicación pública.
