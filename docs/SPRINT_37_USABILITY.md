# Sprint 37 — interfaz y respuesta

La ficha de Equipo construye solo la pestaña activa. Abrir Ficha ya no genera
una biblioteca de técnicas ni una tienda que permanecen ocultas; Movimientos
conserva las cuatro ranuras y los filtros. Las actualizaciones de tipografía y
preferencias se agrupan antes del siguiente fotograma.

## Medición

Ensayo nativo en el mismo ordenador, Godot 4.7.2, con biblioteca grande de MT,
24×24 casillas y hasta 12 unidades. Cada comparación usa 12 aperturas; estas cifras
son tiempos de reconstrucción de menús, no una promesa de FPS en otro equipo.

| Panel | Antes, mediana | Después, mediana | Antes/después p 95 |
| --- | --- | --- | --- |
| Equipo → Ficha |77,116 ms|10,725 ms|94,537 /14,090 ms|
| Equipo → Movimientos |78,291 ms|45,253 ms|86,514 /49,693 ms|

Los 95 casos del planificador conservan el mismo hash de decisiones, estado
natural y diario. No se cambian potencia, estadísticas, EXP ni precios. El
ensayo distingue fixtures de carga/visibilidad de la apertura natural.

## Carga y controles

La carga desde campaña usa el lector asíncrono existente: reconstruye el diario
por tramos, muestra progreso y bloquea órdenes hasta finalizar. La ruta
certificada sigue disponible; un guardado sin certificado se reconstruye
íntegramente. Un fallo conserva el archivo y muestra el diagnóstico.

La prueba específica de usabilidad recorre teclado y ratón, cancelación de
técnicas, rectificación, orientación, acceso a controles, Pokédex, una victoria
inicial, entrenamiento, ofertas estables y cuatro ranuras. Incluye 1024×720,
texto 150% y contraste alto. El mostrador sin existencias se comprueba mediante
un fixture visual explícito, sin sustituir el guardado natural.

## Evidencia

[Antes](qa/sprint-37/performance-before.json) ·
[Después](qa/sprint-37/performance-after.json).
Las [32 comprobaciones de controles](qa/sprint-37/usability-source.json) pasan
sin fallos; se conservan capturas de [Movimientos](qa/sprint-37/team-moves-1024-150.png)
y [Rasgos](qa/sprint-37/team-traits-1024-150.png) con texto ampliado y contraste alto.
La candidata de entrega añade los resultados fuente/EXE y capturas. Siguen
pendientes DPI físicos distintos, lector audible y sesiones humanas externas.

Las mediciones antes/después anteriores sustentan la comparación. Las pruebas
finales de equivalencia fuente/EXE se ejecutaron mientras otra instancia
recorría la campaña: sus tiempos son observaciones bajo esa carga, no una nueva
comparación aislada ni una estimación del rendimiento mínimo.
