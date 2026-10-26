# PP de equipamiento — Windows 0.31.0

Los PP limitan los movimientos preparados. Lanzar un movimiento consume la acción, sin gastar puntos ni esperar a regenerarlos. Se mantienen cuatro ranuras y el básico neutro gratuito.

## Capacidad y costes provisionales

La propuesta inicial de4–8 PP se descarta por indicación del usuario. Nueva capacidad por Pokémon:10 hasta nivel9,11 al10,12 al15,13 al20; aumenta uno cada cinco niveles hasta20 al55. Depende del nivel, sin ventaja adicional por forma evolutiva. Misma regla para aliados y rivales.

Los211 movimientos cuestan1–5 PP al equipar. La valoración tiene en cuenta potencia, área, alcance, críticos garantizados, drenaje, estados de control y mejoras permanentes; conserva las desventajas de autodestrucción y preparación. No se fija el catálogo a partir de los ejemplos del usuario. Ascuas queda en1, Lanzallamas en4 por su línea, Danza Espada en3, Somnífero en4 y movimientos de gran impacto como Hiperrayo en5.

Tabla completa revisable: [PP por movimiento](qa/sprint-31/power-prices.csv). Los valores son una primera prueba, no un balance validado con jugadores. En niveles altos cabe una combinación más fuerte. El presupuesto controla la combinación, pero permite repetir una técnica equipada cada turno si sus reglas particulares lo permiten.

Aprender por nivel o MT conserva siempre el conocimiento. Solo se preparan automáticamente las técnicas que caben; las restantes siguen disponibles en la biblioteca. Sustituir o vaciar ranuras libera PP. Las técnicas copiadas por Espejo, Metrónomo, Mimético o Transformación usan la regla de su movimiento de origen, sin cobrar por el resultado sorteado o copiado. La revisión de equipamiento impide superar el presupuesto sin gastar objetos ni cambiar el guardado.

## Atributos y estados

Subidas y bajadas de atributos, incluidas precisión/evasión y Foco Energía, duran hasta finalizar el combate o hasta que una técnica las elimine. Se conserva el límite táctico±2 y el restablecimiento entre combates. Los estados mantienen sus duraciones temporales actuales, incluida la inmunidad existente tras despertar o descongelarse; parálisis sigue reduciendo movimiento. El texto incompleto del usuario se interpreta como conservar estos estados temporales.

Se retira también el contador especial de cinco usos de recuperación: la limitación pasa al equipamiento, como el resto. Se conservan acción por turno, requisitos de objetivo, preparación/recarga, retroceso, sacrificios de PS y reglas particulares de cada movimiento.

Presión deja de aumentar costes porque ya no existe ese recurso durante el combate. Se etiqueta «sin efecto» en esta edición; no se inventa otra pasiva ni se cambian las otras habilidades.

## Manantiales de recuperación

Primera implementación de las casillas solicitadas: dos por escenario, accesibles a ambos bandos, señalizadas con borde cian y cruz. La colocación es determinista y no consume RNG; evita apariciones, despliegues, objetivos, portales, peligros iniciales y obstáculos. Se seleccionan suelos alcanzables por terrestres de ambos equipos. No cambian los mapas históricos almacenados.

Terminar el turno sobre ellas cura estados principales y confusión antes del daño periódico de estado. No recupera PS, no revive, no quita atributos, Drenadoras ni otras técnicas temporales. Se pueden usar varias veces y no exigen otro botón. La IA considera estos destinos cuando tiene un estado; no se afirma que encuentre siempre la mejor decisión. Ayuda al señalar la casilla y en inspección textual. Se usan las figuras y colores del tablero, sin recursos gráficos o servicios nuevos.

## Compatibilidad

Nueva campaña23/capítulo27 y combate20. Reglas, datos, pruebas y recursos publicados anteriores intactos. Sin cambios de estadísticas base, EXP, precios, equipos rivales ni recompensas. La disponibilidad de acciones sí cambia: el equilibrio anterior no acredita el de esta edición.

Nueva partida usa este sistema. Una partida12–22 conserva sus reglas hasta pulsar «Actualizar a PP de equipamiento» entre encuentros; hay copia previa y replay mixto. Se conservan niveles, PS, objetos y todas las técnicas aprendidas. Se mantienen las ranuras que caben en su orden anterior; las que excedan el presupuesto se desequipan y pueden reorganizarse gratis. El combate en curso no se convierte. KT31 identifica las reglas nuevas; KT30/KT25 conservan las anteriores. Perfil/logros se mantienen.

## Comprobaciones y entrega

- 1.602 comprobaciones de reglas:211 movimientos,200 resueltos con escenarios genéricos y11 condicionales, consultas sin mutar estado/RNG, equipamiento rechazado/aceptado, MT, repetición sin puntos, recuperación, Presión, atributos duraderos, estados temporales y curación sin PS para ambos bandos.116 escenarios con dos manantiales y presupuestos válidos. Aperturas naturales con los tres iniciales, guardado23 y transición22→23 reconstruidos.
- 233 comprobaciones de interfaz en fuente y EXE:211 fichas, ratón/teclado, lectura100/150%, PP, ausencia de barra/costes de ejecución, manantiales, apertura/captura/tienda, reglas, código y carga.
- 503 comprobaciones de presentación de la edición anterior en fuente y EXE. Prueba histórica fijada a22; no se altera para aceptar reglas nuevas.
- Lint y validación: cero errores,65 advertencias históricas, ninguna nueva. Paquete con comparación de estado fuente/EXE, archivos protegidos intactos, ZIP e inventario SHA256. Evidencia en `docs/qa/sprint-31`.

No hay prueba humana ni recorrido completo de la campaña nueva. Publicación pública aplazada; ejecutable local y commit/push privado autorizados. No hay dependencias, plugins ni recursos descargados nuevos.
