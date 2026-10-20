# Turno contextual · 0.22.3

Prompt02 aplicado sobre0.22.2. Misma campaña18, combate17 y contratos de guardado. Cambia la entrada y su presentación; no cambia daño, precisión, economía, mapas, IA ni repertorios.

## Cambios

- Seleccionar una habilidad por ranura o menú solo la prepara. Los apoyos propios muestran previsión y esperan Enter/clic. Cancelar no modifica partida, diario, PS/PT ni azar.
- Q/E recorre objetivos legales por ID estable. No cambia la unidad activa ni funciona mientras otro control tiene el foco. Los objetivos fuera de alcance siguen mostrando el motivo al intentar seleccionarlos.
- Modo Rápido por defecto; Modo Seguro configurable y persistente en F2/controls.json. El primero ejecuta al aceptar objetivo y el segundo pide una aceptación final. En ambos se confirma daño a aliados o autocoste potencialmente letal, contemplando el máximo crítico y Vidaesfera. Una intención requiere una sola confirmación; Escape conserva el movimiento ya realizado.
- Orientación automática tras mover y actuar. F permite terminar antes y muestra recursos sin usar. Flechas eligen dirección lógica, Enter termina, Escape vuelve. Botones diagonales y clic en tablero ofrecen la alternativa de ratón. La brújula recuerda cómo se proyectan X/Y; no cambia las coordenadas del motor.
- Cámara por cruceta junto al minimapa, Alt+flechas y modo P sin mantener modificador. En modo P las flechas y el arrastre izquierdo desplazan la cámara; aceptar no ordena. Central opcional, rueda/+−, C y encuadres anteriores conservados. Los controles ocupan el margen del HUD.
- Hover no cambia la selección ni previsión iniciada con teclado. El clic se acepta al soltar y exige menos de8 píxeles de arrastre. Entradas retenidas solo repiten cursor/cámara. Diálogos contienen la entrada, limpian arrastres pendientes y devuelven foco.

Se reutilizan input_profile, foco y captura del prompt01. interaction_context deriva los contextos del estado de selección existente; no introduce otro router ni un segundo estado de combate. Preferencias antiguas conservan sus asignaciones; si una tecla nueva coincide, solo esa orden nueva recibe una tecla libre. Sin plugins, servicios, dependencias o recursos externos nuevos; créditos anteriores conservados.

## Comprobaciones

Evidencia en [qa/sprint-22-context](qa/sprint-22-context). APPDATA/LOCALAPPDATA y archivos aislados. Los fixtures sintéticos de interacción se identifican como tales y se separan del guardado natural con replay.

- 96 comprobaciones nuevas de eventos de teclado/puntero del viewport: apoyos propios, cancelación, objetivos/remapeo, ambos modos de aceptación, fuego amigo/autocoste letal, destinos inválidos, PT/estado, orientación, movimiento en ambos órdenes y R, pulsación mantenida entre activaciones, cámara16/24, umbral de arrastre y reconstrucción de una campaña natural.
- 20 comprobaciones de preferencias en dos procesos independientes. Lint sin hallazgos; validación sin errores ni advertencias nuevas, con65 advertencias anteriores.
- Regresiones: controles59, interfaz58, laboratorio1029 y finales898/510. Fuente y ejecutable offline comparan informes y estados completos de los guardados. Los diarios y estados de ambos finales siguen idénticos a0.22.2. El paquete rechaza informes de ejecutable anteriores a su compilación.

No se han hecho pruebas humanas con teclado físico o lector de pantalla. Los eventos nativos se inyectan en Windows; no acreditan por sí solos compatibilidad con todas las tecnologías de apoyo. El arte y terreno siguen provisionales y no se reajusta el balance.

## Siguiente bloque

Prompt03: inspección persistente, información táctica y previsiones más claras. Prompts03–09 pendientes. Escala de texto y preferencias persistentes de sonido/movimiento corresponden a sus bloques posteriores. Publicación pública aplazada.
