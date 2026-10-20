# Acceso textual y lector de pantalla ·0.22.9

Prototipo acotado, no declaración de accesibilidad completa. La API instalada Godot4.7.2 ofrece nombres, descripciones y regiones de anuncios en Control y consultas de soporte/activación en SceneTree. La [documentación oficial de integración](https://docs.godotengine.org/en/stable/tutorials/ui/creating_applications.html#screen-reader-integration) indica que usa AccessKit y recomienda probar lectores reales. Las propiedades comprobadas pertenecen al motor local; no se han trasladado propiedades de documentación futura que no existen en esta instalación.

El corte cubre Inicio, Oak, práctica/combate inicial, casilla y lista de unidades, previsión/estados, aceptación/cancelación, orientación, menú y una muestra de tienda. Se conserva la entrada nativa y se ofrecen nombres/descripciones para controles y una representación textual del Canvas. La configuración no modifica campañas ni tiradas. No se añade síntesis de voz ni proveedor remoto, evitando una segunda narración.

## Capas de evidencia

1. Existencia de API: consulta del motor instalado y documentación oficial.
2. Semántica instrumentada: nombres, descripciones, estados nativos, foco y mensaje de casilla/resultado.
3. Navegación automática: eventos nativos y comprobaciones de datos sin consumir RNG al inspeccionar.
4. Árbol del sistema y lectura audible con Narrador/NVDA: pendientes. Narrador.exe está presente en Windows; su presencia no prueba su funcionamiento con el juego. No se inició una sesión de lector ni se instaló software.
5. Usuario habitual de lector: pendiente, con consentimiento y guion del kit de aceptación.

Los datos del entorno gráfico y las propiedades instrumentadas se registran por separado de los resultados deterministas. Activar siempre el backend para una prueba se puede hacer con `PokemonTactics.exe --accessibility always`; en uso normal el motor conserva detección automática. Sonido silenciado no debe silenciar el lector externo.

## Prueba manual concreta

Con el lector elegido ya iniciado, anotar versión/configuración y ejecutar la copia de prueba. Activar «Texto de casilla y avisos accesibles» en Opciones. Recorrer Inicio y Oak con Tab/Mayús+Tab y Enter, sin ratón; volver y abrir Aprender. Explicar coordenada, terreno, altura, ocupante/equipo, PS/PT/orientación y legalidad desde las flechas. Abrir Ficha, cambiar unidad y comprobar que el cursor coincide; leer estado y activaciones. Consultar una previsión, cancelarla, aceptar una acción una vez, orientar y salir. En tienda leer artículo, precio, saldo y destinatario; cancelar sin gasto. Probar interrupción/repetición del último resultado, cierre de diálogos y atajos reasignados.

Si solo se lee el nombre estático o no llegan los cambios, registrar el bloqueo y conservar los resultados automáticos como contratos de texto, sin aprobar compatibilidad. Probar interacción con atajos del lector y navegación de foco antes de ampliar a toda Kanto.

## Límites y orden posterior

Primero validar árbol y lectura en Windows real; después priorizar PC/biblioteca y tiendas completas, anuncios de áreas/peligros/cola, campañas clásicas y controles de lector alternativos. El tablero no se convierte en cientos de casillas enfocables. No se ha medido conformidad WCAG ni comprensión humana, ni se promete navegación sin visión en todas las pantallas.

## Comprobación del corte

Ocho aserciones sin fallos con ventanas nativas y backend AccessKit forzado activo: Windows10.0.26300,96DPI, OpenGL/gl_compatibility, Godot4.7.2 ed1daf0bf001b61586d9930840f2f1394092c079; soporte y activación devuelven verdadero.100 actualizaciones iguales no repiten anuncios ni cambian RNG. La lista sincroniza cursor/estado y la muestra de tienda expone destinatario/saldo. No se inspeccionó un árbol UIA externo ni hubo lectura audible.

La primera prueba con subventanas incrustadas artificialmente y accesibilidad forzada produjo un error interno de foco del motor al cerrar diálogos. Se repitió el corte con ventanas nativas, como en el ejecutable normal, sin ese error. La regresión de interacción incrustada conserva detección automática; no se ocultan errores en los registros.
