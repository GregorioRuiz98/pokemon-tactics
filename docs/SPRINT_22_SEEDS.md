# Semillas de aventuras nuevas · 0.22.12

Solicitud: variar los Pokémon que salen mediante semillas. El sorteo existente ya dependía de la semilla persistida, pero la interfaz rellenaba todas las aventuras nuevas con `kanto-14`. Se corrige la entrada a la campaña; se conservan campaña18/combate17, tablas LGPE, probabilidades, fórmulas y diarios publicados.

## Comportamiento

- Cada visita a Oak para comenzar otra aventura genera una semilla nueva de hasta64 caracteres. Se usa aleatoriedad local del sistema, separada del PRNG de combate, capturas y tienda. No requiere conexión.
- El jugador puede escribir o pegar una semilla, generar otra y copiarla junto a los iniciales. Un refresco de presentación mantiene el texto elegido. Al elegir inicial se recortan espacios exteriores; el campo vacío genera una nueva semilla en vez de usar la antigua constante.
- Menú → Copiar semilla de la campaña copia la que está guardada. No cambia el equipo, la recompensa pendiente, el diario ni el azar. Cancelar Oak restaura íntegramente la aventura previa.
- Misma semilla y decisiones reproducen el azar. Semillas diferentes pueden coincidir en alguna captura, especialmente en tablas pequeñas. No se impone una prohibición nueva de duplicados. Los gimnasios siguen dando su Pokémon insignia y los legendarios siguen siendo enemigos.
- Una partida existente conserva su semilla. No se cambian capturas ya sorteadas ni se vuelve a sortear al cargar. Tampoco se cambia la semilla a mitad de campaña.

## Comprobaciones de semillas

La batería específica comprueba64 semillas generadas distintas, estabilidad de la entrada al refrescar, generación manual, normalización, copia nativa y recuperación del texto guardado. Prueba también campo vacío, cancelación de Oak, controles dentro de ventanas1024×720/1280×900 y ausencia de cambios del estado/PRNG al copiar.

Se prueban64 semillas fijas mediante consultas aisladas a las tres primeras tablas locales:64 secuencias distintas de especie/nivel, cuatro especies distintas en Ruta1 y el mismo resultado al repetir cada consulta. Estos son sondeos de tablas, no64 campañas jugadas. Brock conserva Onix en todos ellos. Además se juegan dos primeros combates con `tactics-1`: ambos producen la misma captura y cargar conserva íntegramente la recompensa pendiente y el PRNG.

La copia se comprobó en una ventana nativa de Windows con acceso al portapapeles, restaurándolo después y sin guardar o mostrar su contenido previo. El primer intento dentro del entorno aislado no podía abrir el portapapeles y falló esas dos comprobaciones; el ensayo nativo pasó las920 comprobaciones.

Doce baterías completadas tanto en fuente como en ejecutable, sin fallos finales. Los informes deterministas coinciden; los tiempos de rendimiento varían por ejecución. Los estados y diarios completos de ambos finales, PC y laboratorio coinciden entre fuente/EXE. Los finales conservan además los8924/7396 comandos y estados de referencia0.22.3.

| Batería | Fuente | EXE | Resultado |
|---|---:|---:|---|
|Semillas|920|920|Sin fallos|
|Inicio y ventanas|58|58|Sin fallos|
|Entrada y foco|63|63|Sin fallos|
|Preferencias y gestión|105|105|Sin fallos|
|Turno contextual|96|96|Sin fallos|
|Rendimiento|18|18|Sin fallos|
|PC|540|540|Sin fallos|
|Mapas y alturas|980|980|Sin fallos|
|Laboratorio|1026|1026|Sin fallos|
|Final aves16|901|901|Sin fallos|
|Final psíquico24|513|513|Sin fallos|
|Semántica nativa|8|8|Sin fallos|

La navegación de teclado añade cuatro comprobaciones para los botones Generar otra y Copiar:63 en total. La primera regresión esperaba el recorrido anterior sin esos botones; se actualizó para comprobar todos los controles nuevos, manteniendo escritura sin atajos de juego y elección del inicial.

Preferencias persistentes22 y cantidades44 comprobaciones adicionales. Lint sin incidencias; validación del motor0 errores y65 advertencias preexistentes, ninguna nueva. Los recursos y hashes de reglas se verificaron. El EXE se probó con la ruta del editor deliberadamente inexistente; la prueba del portapapeles usó acceso nativo a Windows. No se usaron partidas reales.

Evidencia en `docs/qa/sprint-22-updates-12/`. Las pruebas humanas y la lectura audible con lector habitual siguen pendientes; estas comprobaciones no las sustituyen.

## Reproducir

`npm run godot:qa:seeds` ejecuta la prueba específica en fuente y `npm run godot:qa:seeds:export` en el ejecutable generado. Los informes y las capturas se guardan en perfiles de prueba aislados. La semilla generada para un usuario y el contenido del portapapeles no se escriben en los informes.

No se añaden plugins, dependencias o recursos nuevos. Los módulos y datos publicados, la web y las mejoras de rendimiento0.22.11 se conservan. El código se entrega en el repositorio privado y el ejecutable se prepara para uso local; no hay publicación pública.
