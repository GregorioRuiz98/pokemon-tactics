# Fluidez 0.24.1

La planificación del rival deja de bloquear un fotograma completo. Conserva la campaña 20 / combate 18, las decisiones de la IA y el formato de guardado. Esta entrega no modifica el balance.

## Cambios

- El planificador de la interfaz recorre los mismos candidatos, puntuaciones y desempates del motor publicado. Reutiliza el peligro de cada destino: antes se calculaba otra vez por cada enemigo.
- La búsqueda avanza con un presupuesto orientativo de 3 ms por fotograma. Conserva la pausa de presentación habitual y guarda cada orden aceptada antes de mostrar sus efectos. Los menús pausan la búsqueda; actualizar el estado descarta el trabajo pendiente.
- Las previsiones de área se conservan mientras el estado no cambie. Alcance, cursor y confirmación pueden consultar el mismo resultado. Movimiento, acción, carga y refresco invalidan la caché; dirección del lanzamiento, orientación y movimiento tienen claves independientes.

El presupuesto es cooperativo: una consulta individual de geometría, peligro o rutas puede superar 3 ms. No es una garantía de tiempo máximo ni de FPS para todos los equipos.

## Mediciones

Godot 4.7.2, Compatibility/OpenGL, Windows, RTX 4070 Ti Super. Muestra sintética actual de 24×24 con seis aliados y seis rivales del gimnasio de Koga. Comparación del algoritmo original y el nuevo sobre los mismos estados, sin sorteos adicionales.

En el primer recorrido completo, la decisión de Tentacruel pasó de 58,5 ms a 12,6 ms de CPU, repartidos en cuatro tramos de hasta 3,5 ms. La previsión repetida de un área pasó de 0,148 ms a aproximadamente 0,04 ms. Son mediciones locales; el informe JSON conserva las muestras posteriores de desarrollo y del EXE, que pueden variar.

El dibujo del tablero rondaba 0,7 ms y el refresco de la interfaz 3–5 ms en esta muestra. Se conservan las cachés de terreno/minimapa y el guardado síncrono con copia, comprobación de conflictos y suma de verificación.

## Comprobación

`npm run godot:qa:fluency` y `npm run godot:qa:fluency:export` comparan 93 decisiones: doce unidades antes/después de moverse, tras actuar y con amedrentamiento; áreas, pantallas, zonas, desplazamientos y técnicas especiales; y 21 órdenes de un combate natural. Verifican que inspeccionar no cambie estado/azar, que la caché se invalide, que los menús pausen la IA y que la interfaz acepte exactamente una orden autoritativa. También guardan y reconstruyen el recorrido natural.

Se ejecutan además las regresiones de economía, movimientos espaciales, biblioteca y rendimiento anterior, tanto en desarrollo como en el ejecutable, y las pruebas de dominio publicadas. Evidencia y resultados finales: [verificación](qa/performance-0.24.1/verification.json), [mediciones originales](qa/performance-0.24.1/before.json), [desarrollo](qa/performance-0.24.1/fluency-source.json), [ejecutable](qa/performance-0.24.1/fluency-release.json).

No se repite una campaña completa de Kanto ni se afirma que el balance esté cerrado. La campaña 20 conserva los límites de prueba descritos en [progresión 0.24](SPRINT_24_ECONOMY.md). No hay dependencias, recursos ni servicios nuevos. Publicación pública pendiente.

Para probar: descomprimir `pokemon-tactics-0.24.1-windows.zip` y abrir `windows/PokemonTactics.exe`. Los guardados continúan con sus reglas actuales, sin conversión por esta optimización.
