# Sprint 25 — aventura táctica 0.25.0

Se implementa el conjunto de mejoras aprobado el 25 de octubre. Nueva campaña 21 / combate 19; Windows offline. Se reutilizan los terrenos, retratos PMD, imágenes y sonidos ya incorporados: no hay dependencias, descargas al jugar ni servicios nuevos.

## Qué cambia

| Bloque | Implementación |
|---|---|
| Preparación | Cada encuentro empieza pausado. Formación inicial automática; clic en aliado y casilla verde, o arrastrar. Arrastrar sobre un aliado intercambia sus posiciones. Formación inicial restaura la distribución; B confirma. Teclas reasignables. |
| Amenazas | T alterna No / rival bajo el cursor / todos. Geometría de movimientos de daño y estados dirigidos al rival, con desplazamiento, PT disponibles y transportadores. Consulta incremental, caché por estado; se pausa con los menús. |
| Ritmo | Despliegues próximos al contacto en 16×16 y24×24, sin eliminar el espacio para flanquear. Se registra cuántos movimientos acaban lejos de cualquier rival. Ruta1 es introductoria: el rival usa básico; Ruta2 en adelante conserva repertorios. |
| Gimnasios | Ocho arenas propias: cantera y terrazas, canales y pasarelas, cobertura de maquinaria, jardín con seda, dojo con humo, transportadores, laboratorio con fuego y falla con trampas. No se cambia el equipo insignia ni las tablas LGPE. |
| IA | Salvajes mantienen decisiones sencillas. Entrenadores penalizan daño/estado a aliados, favorecen remates y curaciones útiles y evitan repetir mejoras ya altas. Apoyos buscan compañeros heridos; vanguardias intentan mantenerse cerca de apoyos. Líderes distribuyen mejor sus posiciones y evitan renovar campos ya presentes. No reciben estadísticas extra. |
| Recuperación | Por victoria, los debilitados que estuvieron desplegados reciben50% de la EXP base. Siguen a0 PS, sin curación ni Revivir gratuito. Los supervivientes rezagados reciben25% extra por nivel entero por debajo de la media del equipo, hasta100% adicional. PC sin EXP de victoria; caps conservados. |
| Entrenamiento | Estar al menos tres niveles por debajo de la media del equipo concede25% de descuento al completar la EXP pendiente. Se revisa la cotización y la revisión del estado antes de pagar. |
| Objetivos | Guarida Rocket: terminar sobre dos terminales. Rescate de Fuji: proteger4 puntos hasta ronda4; un rival que termine adyacente resta uno. Calle Victoria: llevar a todos los aliados en pie a las seis salidas. Derrotar a todos los enemigos también permite ganar. Perder a Fuji termina la campaña y se explica en el resumen. |
| Terreno | Viento dispersa humo/gas, como en0.23. Agua que apaga fuego deja lodo; fuego que quema seda deja llamas. Los efectos nuevos duran hasta el comienzo de la segunda ronda siguiente, incluyendo una ronda completa. Se anticipan en la previsión y tienen texto visual propio. Empujes y trampas anteriores se conservan. |
| Recompensas | Avisos breves con retrato para capturas, evoluciones y medallas; no bloquean órdenes. Respetan la duración de resultados y se omiten con Escape. |
| Compartir | Reto/F9 en el hub exporta PNG960×640 del equipo, medallas, bajas, combates, rondas y semilla, y copia un códigoKT25. Pegarlo en Oak fija inicial, semilla, mapa y edición. Las decisiones posteriores pueden producir resultados distintos. No sube nada a Internet. |

Las amenazas son **cobertura geométrica potencial**, no la orden que elegirá la IA ni una garantía de acierto/daño. Inmunidades, condiciones de técnicas, ocupación, campos, visión y cambios posteriores pueden alterarla; las técnicas copiadas o aleatorias requieren la previsión al apuntar. La previsión al apuntar sigue usando las reglas completas. Mientras se calcula se indica cobertura pendiente.

La consulta de todas las amenazas puede tardar varios segundos con doce unidades: se reparte entre fotogramas, muestra el cálculo pendiente y conserva el resultado hasta que cambia el estado. Su presupuesto es cooperativo, no una garantía de FPS. Las muestras de CPU/dibujo están en los informes de QA de desarrollo y ejecutable.

Los transportadores se activan al acabar un desplazamiento sobre ellos, para ambos equipos, únicamente si el destino está libre. Ese movimiento no se puede rectificar. Los campos ambientales fijos se identifican con∞; los creados por movimientos muestran rondas restantes. La iniciativa se sortea una sola vez; colocar aliados y consultar amenazas no consume azar.

## Guardados y compatibilidad

Las ediciones anteriores siguen con sus motores. La actualización a21 es voluntaria entre encuentros, conserva una copia, equipo, PC, PS, niveles, dinero y diario. Desde20 conserva exactamente la EXP parcial. Desde12–19 aplica primero la conversión económica publicada de20, con sus reembolsos. Nunca convierte un combate pendiente.

Se reconstruye una partida natural20, se actualiza en tienda y se verifica el diario mixto20/21. Preparación, posiciones y comienzo del combate también se guardan como órdenes. La tarjeta de una aventura actualizada ofrece un reto nuevo con las reglas actuales; no reproduce su tramo histórico. Las métricas de combate empiezan al actualizar, las medallas son las totales.

## Comprobaciones

- Pruebas de dominio nuevas: despliegue, RNG, guardado/recarga, código de reto, ocho arenas, objetivos con recompensas reales, fallo de protección, transportadores y bloqueo de rectificación, EXP sin revivir, descuento, terreno y actualización real20→21.
- Regresiones publicadas: economía964 y movimientos espaciales557 comprobaciones. Sus módulos/datos/tests anteriores permanecen intactos.
- QA nativa: partida natural con código de reto, ratón, teclado y arrastre; amenazas; tarjeta PNG; previsión y VFX de terreno; contraste, movimiento reducido, semántica y texto100/125/150 en1024×720 y1280×900; capturas de las ocho arenas.
- Regresiones de biblioteca, economía, geometría y rendimiento en sus ediciones históricas. El planificador compartido conserva las93 decisiones de referencia de0.24.1.
- Validación completa: cero errores y cero advertencias nuevas sobre las65 existentes. Resultados definitivos y artefactos: [verificación](qa/sprint-25/verification.json), [entrega](qa/sprint-25/release.json).

## Revisión de economía y ritmo

Se repiten seis semillas/iniciales fijados en0.24, con despliegue predeterminado, política automática de movimientos aprendidos, curación y entrenamiento pagados. Sin reroll de captura ni compra de MT. Se conservan las derrotas. Las seis partidas se guardan y reconstruyen correctamente.

| Inicial | Semilla | Último encuentro | Resultado | Medallas |
|---|---|---|---|---:|
| Bulbasaur | economy-0 | Bosque Verde | Derrota |0|
| Bulbasaur | economy-1 | Brock | Victoria |1|
| Charmander | economy-0 | Ruta2 | Derrota |0|
| Charmander | economy-1 | Brock | Derrota |0|
| Squirtle | economy-0 | Ruta2 | Derrota |0|
| Squirtle | economy-1 | Brock | Victoria |1|

Todos superan Ruta1. Solo2/6 superan Brock con esta política; no demuestra imposibilidad para un jugador humano. La política no aprovecha manualmente el despliegue ni prepara cobertura mediante MT/rerolls. Hay0 movimientos terminados a más de seis casillas de cualquier rival en estas muestras: sugiere contacto temprano, sin demostrar que todos los turnos sean interesantes. Costes/recuperación, duración de gimnasios y protección de Fuji requieren prueba humana. No se ha jugado automáticamente una campaña21 completa ni sus finales. Las arenas posteriores se verifican con escenarios sintéticos, sin presentarlos como victorias naturales.

Fuente de reglas nuevas: adventure_*.gd, tactical_planner.gd, threat_query.gd, journey_challenge.gd y adventure.json. Tablas de encuentros/EXP heredadas de0.24. Informe de muestras: [simulación](qa/sprint-25/balance.json). Publicación pública pendiente.
