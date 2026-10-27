# Probar Pokémon Tactics en Windows — 0.33.0

[Reglas actuales](REGLAS_ACTUALES.md) · [Informe de la entrega](SPRINT_33_REVIEW.md).
Este documento describe la campaña Windows actual. Los informes por versión son historial.

## Arranque y controles

Extrae el ZIP completo y abre windows/PokemonTactics.exe. El juego lleva sus recursos y motor integrados: no requiere instalar Godot, Node, servidor ni iniciar sesión. La entrega no consulta la red al jugar. La prueba en un segundo ordenador físico sigue pendiente hasta recibir un resultado externo.

Oak permite elegir inicial; la semilla se genera sola. Clic o flechas/Enter seleccionan casillas. A abre técnicas; R rectifica solo movimiento antes de actuar; F orienta y termina. Escape cancela, Tab recorre controles y F6 cambia de panel. F2 abre controles configurables. Rueda o +/− cambia zoom; C centra la unidad; P y flechas/arrastre desplazan la cámara. Las etiquetas reflejan las teclas reasignadas.

Las opciones permiten ampliar texto, alto contraste, movimiento reducido y ajustar sonido. Comprueba primero 1280×720; el juego también tiene recorridos comprobados a 1024×768 y con texto 150 %. Esto no sustituye comprobar DPI físico 125/150/200 % en otro equipo o lectores de pantalla.

## Partida y recuperación

Guarda automáticamente las órdenes y las compras. Continuar restaura equipo, PS, EXP, objetos, cola, orientación, azar y diario. Perfil, logros y opciones son independientes. En Windows se ubican en %APPDATA%/PokemonTacticsLab; el juego conserva el archivo previo si detecta formato alterado o versión futura. No abras dos instancias sobre la misma partida.

Antes de actualizar reglas se crea una copia con sufijo before-new. La actualización se ofrece entre encuentros; un combate pendiente conserva su motor. Para recuperación manual, cierra el juego, copia toda la carpeta de guardados a otra ubicación, conserva el archivo problemático con otro nombre y restaura una copia válida como kanto-save.json. Si no hay copia válida, no borres el original: adjúntalo con el informe para diagnóstico. Nunca edites PS, dinero ni el diario a mano.

Equipo → Ficha permite completar la EXP del nivel durante la tienda. No hay pestaña Entrenar, caramelos ni piedras utilizables. Los PP limitan equipamiento; las técnicas no gastan puntos al usarse ni tienen cinco usos de curación. Liga/rival, aves y Mew/Mewtwo se recorren consecutivamente.

## Prueba en otro ordenador

Entrega el ZIP completo, sin el directorio fuente ni el editor. Desconecta la red y prueba arranque, sonido, ventana y pantalla completa. El paquete incluye Comprobar-equipo.cmd: inicia una sesión de diagnóstico aislada y guarda un informe de arranque; no toca tu partida habitual. Adjunta también especificaciones del equipo y cualquier mensaje de Windows. El diagnóstico no acredita por sí solo una campaña jugada.

| Prueba | Evidencia que debe anotar quien juega |
|---|---|
| Arrancar sin Godot instalado y sin conexión | Windows, CPU/GPU/RAM, si abre y si hay errores/recursos ausentes. |
| 1024×768/1280×720/1920×1080 y DPI 125/150/200 % | Resolución y DPI reales, escala del texto, capturas de recortes o foco perdido. |
| Ratón y teclado, cerrar/reabrir a mitad de combate | Mismos PS, cola, posición, movimientos preparados, dinero y compras. |
| Equipo de 6 y PC/biblioteca grandes | Buscar, paginar, cambiar ranura, salir y volver sin perder selección. |
| Ruta y gimnasio con muchas unidades | Tiempo de respuesta, claridad de estados/objetivos, pausas y sonidos. |
| Recorrer campaña completa | Semilla, inicial, desvíos, bajas, rondas excesivas, gastos, recompensas y encuentros legendarios. |
| NVDA u otro lector habitual | Lector/versión y controles que no se anuncian; no declarar compatibilidad sin prueba. |

Pide a cada participante que anote qué intentaba hacer, qué esperaba y qué ocurrió. Evita explicarle de antemano cada menú: interesa detectar dudas reales. No se ha contactado automáticamente con personas ni enviado el juego a terceros.

## Plantilla de incidencia

- Versión, semilla, inicial, mapa y ronda:
- Equipo / último movimiento u objeto:
- Pasos exactos y resultado esperado:
- Resultado observado y si se repite al cargar:
- Resolución, DPI, escala de texto y entrada utilizada:
- Captura, informe de arranque y copia del guardado (si procede):

Una reproducción automática, una escena sintética y una sesión humana externa son evidencias distintas. El informe de esta entrega identifica cuál se ha ejecutado y cuál queda pendiente.
