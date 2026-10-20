# Controles y navegación · 0.22.2

Primer bloque de los [prompts de mejora](reports/beta-accesibilidad-0.22.1/PROMPTS_ACTUALIZACIONES.md), solicitado el 20 de octubre con «empieza a aplicar los prompts de mejora». Conserva campaña edición 18, combate 17, los motores/datos publicados y los guardados existentes.

## Cambios

- Acciones configurables para navegación, habilidades, cinco ranuras, rectificar, orientación, cámara/zoom, menú, controles y recuperación de guardado. F2 abre la configuración desde Inicio o durante la aventura; también se accede desde Opciones y el menú.
- Reasignación con captura de teclado, conflicto revisable e intercambio explícito. Restablecer una categoría también restablece las asignaciones que entran en conflicto, avisándolo antes. No se roba silenciosamente otra orden.
- Enter/Espacio, Escape, Tab y flechas conservan sus funciones de seguridad. Inicio centra la unidad; el signo + conserva acercar. Combinaciones Ctrl, tecla de sistema y Alt+F4 no se asignan. Una asignación principal por acción; controles de ratón existentes conservados.
- Preferencias independientes de la campaña en controls.json: asignaciones y repetición de navegación. Escritura temporal, sustitución y reversión del cambio en memoria si no se puede guardar. Un archivo inválido usa valores seguros y se copia antes de reemplazarlo por una configuración nueva.
- Etiquetas de órdenes, cámara y ayuda derivadas de las teclas reales. La captura se puede cancelar sin cambiar nada.
- Foco por función/ID, con restauración del desplazamiento y visibilidad del control. Oak y mapa tienen un control inicial; seleccionar miembro, comprar, cambiar categoría o paginar PC conserva un foco utilizable. Si desaparece o se deshabilita el destino, se elige una alternativa válida. Selector de mentas registrado también.
- Habilidades abre el repertorio con foco en el primer movimiento disponible; cancelar devuelve al tablero. F6/Mayús+F6 alterna los dos paneles principales del contexto. Los diálogos devuelven el foco al origen si todavía existe.
- Entrada con propietario: los campos de texto consumen letras/números, los diálogos contienen sus órdenes y las teclas repetidas se limitan a navegación. Se limpian teclas retenidas al cerrar un diálogo o perder la ventana; mantener aceptar no produce compras o ataques repetidos.

La implementación adapta captura y preferencias de las plantillas de la skill Godot instalada. No añade autoloads, complementos, servicios, activos o dependencias. Los oyentes de entrada de los diálogos pertenecen a su viewport: el nodo Window pertenece al viewport padre, por lo que capturar solamente en ese nodo no cubría la ventana propia.

## Verificación

Evidencia de fuente y ejecutable en [qa/sprint-22-controls](qa/sprint-22-controls). QA con APPDATA/LOCALAPPDATA y archivos aislados; partidas humanas conservadas.

- 59 comprobaciones nuevas con pulsaciones y eventos de puntero del viewport: Inicio/Oak, Tab/Mayús+Tab, escritura de A/R/F y números, selección de miembro, cambio de panel, habilidades, contención/cancelación de diálogo, reasignación, conflicto/cancelación/intercambio, restauración, compras separadas/tecla mantenida y PC con 0/1/6/7/30 miembros.
- 13 comprobaciones de preferencias en dos procesos separados: escritura y lectura tras reiniciar, asignación efectiva del motor, teclas reservadas y fallo de persistencia sin aplicar el cambio.
- La tienda de la prueba se prepara mediante órdenes de IA del primer encuentro. Las reservas grandes son fixtures explícitos de presentación: no se guardan ni se presentan como campañas naturales.
- Regresión de interfaz: 58 comprobaciones en fuente y ejecutable. Los dos finales repiten 898 y 510, respectivamente, con informes fuente/ejecutable iguales y estados completos idénticos a 0.22.1. PC: 540; escala: 980, estas dos sobre fuente en esta entrega.
- Validación y lint sin errores ni advertencias nuevas; se mantienen 65 advertencias anteriores del proyecto. Recursos y fuentes originales verificados con sus manifiestos.

Los eventos sintéticos ejercitan manejo nativo, pero no equivalen a una prueba humana con teclado físico o tecnologías de apoyo. El ejecutable se comprueba con ruta de editor inexistente. La entrega es local y su publicación pública sigue aplazada.

## Límites y siguiente bloque

Esta entrega aplica el prompt 01. Los prompts 02–09 siguen pendientes. Las habilidades propias aún se ejecutan al seleccionarlas y los ataques conservan su política anterior de confirmación; cambiarlo es parte del turno contextual del prompt 02. Tampoco se añade todavía cámara por pulsaciones, inspección persistente, texto ampliable, preferencias de sonido/movimiento entre sesiones, cantidades de tienda, filtros de PC o soporte validado de lector de pantalla.

No se retocan daño, precisión, economía, encuentros o reglas de rectificación. El próximo bloque de implementación es el turno contextual: selección segura, objetivos, orientación con teclado y cámara alternativa al arrastre.
