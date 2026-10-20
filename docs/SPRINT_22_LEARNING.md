# Aprendizaje ·0.22.8

Prompt07: práctica repetible desde Inicio o F7, con dos aliados y rivales de prueba. Es un escenario sintético en memoria: no carga, sustituye ni escribe el archivo de la aventura. Al salir se recuperan estado, motor, diario y destino de guardado originales. El rival no avanza automáticamente durante la explicación. No hay esperas obligatorias de animación.

Secuencia: cursor, movimiento, rectificación, preparación/cancelación de habilidad, apoyo propio, orientación, ataque, bloqueo real de rectificar tras actuar, inspección de quemadura y fin de turno. Las órdenes aceptadas usan el motor publicado; la práctica únicamente restringe qué paso se puede ejecutar. Se puede abandonar en cualquier momento.

Glosario F4 consultable; ayudas de mapa/tienda/captura desactivables y persistentes. Inicio muestra fase, lugar, medallas, equipo en pie, límite y siguiente decisión si la aventura ya está reconstruida. En frío conserva el estado de carga sin inventar porcentajes; la reconstrucción registra su duración. El resumen real distingue aprendido de preparado. La elección legendaria abre comparación y cancelación antes de enviar la orden original.

QA ampliada:60 comprobaciones sin fallos, práctica completa por ambos recorridos, estado/diario/archivo originales intactos. Compilación sin errores;68 advertencias, tres introducidas en bloques anteriores que se revisarán en el cierre. Capturas en work/qa-sprint-22-updates-8. La prueba combina entradas reales del viewport y acceso programático al elemento Ficha del menú en el recorrido de ratón; no equivale a una sesión de principiante. Pruebas humanas pendientes.
