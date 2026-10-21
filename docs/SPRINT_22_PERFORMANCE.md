# Rendimiento nativo · 0.22.11

Solicitud del 21 de octubre: corregir las ralentizaciones del juego. Misma campaña18 y combate17, sin cambios de balance, datos, IA, contratos o guardados. Puedes continuar la aventura existente.

## Causas y corrección

La aplicación reaplicaba todos los tamaños de letra y los estilos globales aunque conservaran su valor. Cada escritura de un tema propagaba invalidaciones a los controles descendientes. Se calcula el factor tipográfico una vez por recorrido y se escriben únicamente los valores diferentes. Los controles nuevos siguen recibiendo las preferencias existentes.

Cada animación reconstruía mediante GDScript los polígonos de terreno y las576 casillas del minimapa de24×24. Ahora Godot conserva las órdenes de dibujo de las casillas y el fondo del minimapa. El terreno mantiene el orden del pintor, paredes y alturas; se invalida al cambiar mapa, cámara, cuadrícula, alturas, ventana o espacio reservado para el HUD. Las marcas de movimiento, alcance, área y cursor se redibujan cuando cambian. Unidades, PS, orientación y previsiones siguen actualizándose.

El cursor reutiliza su previsión mientras permanezcan iguales la casilla y la selección. Un refresco de estado invalida esa consulta. Los eventos de ratón actualizan también el cursor lógico. Los avisos accesibles se agrupan y solo vuelven a recorrer los controles cuando cambia la interfaz; mantienen nombres nativos y la región de avisos. El tablero oculto o con movimiento reducido deja de ejecutar la animación ociosa.

## Mediciones

Godot4.7.2 oficial, Windows, Compatibility/OpenGL, NVIDIA RTX4070TiSUPER. Escenario sintético24×24 con cuatro unidades, perfiles y archivos de prueba aislados. Son medianas de operaciones concretas en este equipo; no representan toda la campaña ni garantizan FPS en otros ordenadores.

| Medición | Antes | Después | Muestra y alcance |
|---|---:|---:|---|
| Reaplicar preferencias |228,917ms|1,018ms|30 llamadas sin render;0.22.10 frente a la primera corrección de UI|
| Previsión repetida de la misma casilla |0,524ms|0,005ms|100 llamadas en ese mismo ensayo sin render|
| Dibujo habitual del tablero |22,244ms|0,695ms|43/37 redibujados con ventana; antes/después de conservar el terreno|
| Intervalo de fotograma, percentil95 |37,977ms|16,722ms|120 intervalos en cada ensayo con ventana; incluye sincronización y planificación del sistema|

El ensayo de dibujo anterior ya incluía la primera corrección de UI: permite distinguir la mejora del terreno de la del tema. La reconstrucción completa al abrir un mapa o cambiar la cámara sigue teniendo coste. La mediana de una consulta de IA en este fixture no caracteriza las decisiones de todos los enemigos de Kanto.

Los JSON originales se conservan en `docs/qa/sprint-22-updates-11/`. La comparación de preferencias usa los ensayos sin render; no se mezcla con los tiempos del ejecutable optimizado con ventana. Las cifras posteriores del ejecutable pueden variar.

## Comprobaciones

El ensayo específico comprueba estado completo y PRNG intactos, ausencia de invalidaciones del tema por preferencias iguales, una previsión para100 eventos de la misma casilla, invalidación al cambiar casilla/estado, semántica sin avisos repetidos, pausa de animación oculta/reducida y reanudación. También verifica que la animación reutiliza el terreno, el cursor solo cambia sus marcas y cámara/HUD invalidan la geometría.

Once baterías repetidas en fuente y ejecutable, sin fallos. Los informes deterministas coinciden; los tiempos del ensayo de rendimiento varían por ejecución. Se compararon además los estados y diarios completos de ambos finales, PC y laboratorio. Ambos finales conservan también exactamente los estados y8924/7396 órdenes de la referencia0.22.3.

| Batería | Fuente | EXE | Resultado |
|---|---:|---:|---|
|Preferencias, inspección, gestión, aprendizaje y texto|105|105|Sin fallos|
|Turno contextual|96|96|Sin fallos|
|Entrada y foco|59|59|Sin fallos|
|Inicio y ventanas|58|58|Sin fallos|
|PC y seis unidades|540|540|Sin fallos|
|Escala, alturas y selección|980|980|Sin fallos|
|Laboratorio y clásicos|1026|1026|Sin fallos|
|Final aves16|901|901|Sin fallos|
|Final psíquico24|513|513|Sin fallos|
|Semántica nativa|8|8|Sin fallos|
|Rendimiento y cachés|18|18|Sin fallos|

Preferencias persistentes:22 comprobaciones adicionales; operaciones por cantidad:44. Lint estático sin incidencias. Validación del motor:0 errores y65 advertencias preexistentes; ninguna nueva. Recursos, hashes y fuentes de reglas verificados. No se cambiaron archivos de `src/`, `public/`, `godot/core/`, `godot/data/` ni snapshots.

Las pruebas del EXE se ejecutaron con una ruta de editor deliberadamente inexistente. Los ensayos usan perfiles aislados y no leen ni escriben el guardado real del jugador. La lectura audible, las pruebas con usuarios y otros equipos siguen pendientes; no se declaran aprobadas por estos resultados automatizados.

## Repetir la prueba

`npm run godot:qa:performance` ejecuta el escenario con el motor local; `npm run godot:qa:performance:export` lo ejecuta en el EXE generado sin editor. El informe incluye tiempos y comprobaciones deterministas; no impone umbrales de velocidad dependientes del hardware. Las preferencias y los guardados de estas pruebas usan directorios separados de la aventura del jugador.

La versión sigue funcionando offline, sin plugins, recursos externos o dependencias nuevos. Los sprites y manifiestos originales se conservan.
