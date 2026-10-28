# Sprint 36 — campaña y estabilidad

Campaña nueva con las reglas actuales, desde Oak hasta Mew/Mewtwo. El jugador
automático reutiliza una estrategia de órdenes legales que había completado la
campaña anterior; cada orden se ejecuta de nuevo. No se importa el estado antiguo
ni se inyectan dinero, PS, unidades o victorias. No es una sesión humana.

## Resultado

Las ediciones28 y29 completan los 58 lugares, 57 combates y ocho medallas, con
7.865 órdenes en la edición actual. Incluye elección de Zapdos tras las aves y
Mewtwo tras el segundo desafío. Ningún encuentro supera las 15 rondas en esta
estrategia. Esto no demuestra la duración o dificultad de todas las semillas.

Se comprueban checkpoints, reconstrucción completa del diario sin certificado,
perfil cargado por separado, recuperación de la colección desde los eventos de
la campaña y un nuevo inicial legendario de nivel5. El reclutamiento de tienda se
verifica mediante una rama legal y guardada del primer mostrador, sin alterar el
presupuesto de la estrategia principal.

El primer intento añadió una compra antes del entrenamiento planificado y agotó
su presupuesto tras las aves. Se conserva ese resultado como limitación del
jugador automático, sin presentarlo como un fallo del motor o ajustar el balance.

## Corrección de Kecleon

En la edición28, cambiar el equipo o subir niveles recalculaba candidatos, nivel
y precio dentro de una misma visita. La edición29 conserva las ofertas generadas
al llegar al mostrador. Entrenar, gestionar el PC o abrir menús no las renueva.
Se mantiene la fórmula de precio y nivel, y una compra por lugar.

La corrección tiene nueva edición de campaña:29/capítulo33, combate24 sin cambios
numéricos. Las campañas anteriores conservan su comportamiento hasta actualizar
entre encuentros con copia. Los códigos KT36 identifican las nuevas reglas; los
anteriores siguen siendo legibles.

## Evidencia

[Resumen](qa/sprint-36/summary.json), [recorrido actual](qa/sprint-36/campaign-29.json),
[reglas](qa/sprint-36/rules.json), [intento con presupuesto agotado](qa/sprint-36/attempt-01-budget.json).
El diario íntegro es un fixture reproducible para las pruebas de interfaz.

Se conservan pendientes las sesiones humanas, otro PC físico y la decisión de
distribución pública. Los siguientes bloques verifican interfaz/rendimiento y
preparan la candidata de entrega.
