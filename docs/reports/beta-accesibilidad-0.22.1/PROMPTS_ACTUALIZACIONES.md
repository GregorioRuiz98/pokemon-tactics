# Prompts detallados para próximas actualizaciones

Base: Pokémon Tactics — Kanto, Godot 4.7.2, nativo 0.22.1, commit 9bbae5a653a189d5ce0c1b1565e62bdf0ddb7626. Consultar el [informe](INFORME.md) y [sus evidencias](evidencia/README.md). **Estos encargos futuros no se han ejecutado por redactarlos.**

Estado posterior:01 entregado en0.22.2 y02 en0.22.3;03–09 pendientes. Ver [turno contextual](../../SPRINT_22_CONTEXT.md).

Copiar cada bloque por separado. Implementar solamente el elegido y sus dependencias estrictamente necesarias; no encadenar toda la lista. Revisar la versión real al empezar: los archivos describen la base auditada y pueden haber evolucionado.

| Prompt | Resultado | Dependencias |
| --- | --- | --- |
| 01 | Entrada configurable y continuidad de foco. | Primero. |
| 02 | Turno contextual, orientación y cámara. | 01. |
| 03 | Inspección y lectura táctica. | 01; coordinar con 02/04. |
| 04 | Preferencias persistentes y legibilidad. | 01. |
| 05 | Tienda por cantidad y preparación del equipo. | 01/04. |
| 06 | PC, duplicados y repertorios grandes. | 01; coordinar con 03/05. |
| 07 | Tutorial y continuidad de campaña. | 02/03/04. |
| 08 | Viabilidad de lector de pantalla. | 01; investigación temprana. |
| 09 | Beta de aceptación y experimentos. | Preparar ya; evaluar sobre cada entrega. |

## Prompt 01 — Entrada configurable y foco estable

~~~~text
Actúa como desarrollador experto en interfaz y accesibilidad de juegos Godot. Implementa únicamente una actualización de entrada y navegación para Pokémon Tactics — Kanto. El objetivo es completar los recorridos centrales con teclado, con ratón o alternando ambos, sin perder selección ni ejecutar órdenes accidentales.

Contexto y límites:
- Lee AGENTS.md, godot/AGENTS.md, los scripts reales de package.json y docs/reports/beta-accesibilidad-0.22.1/INFORME.md. Revisa git status y conserva cambios ajenos. Consulta las skills compatibles y anuncia las elegidas. No delegues automáticamente.
- Base auditada: nativo0.22.1, campaña18/combate17. Comprueba si existe una implementación posterior antes de añadir otra.
- Conserva reglas, recursos, ediciones y guardados publicados; src/, public/ y CREDITS.md raíz están congelados. No cambies balance, economía, encuentros ni rectificación. No publiques ni añadas servicios/plugins por este encargo.

Problema reproducido:
Inicio→Enter en Nueva partida deja Oak sin foco. Elegir inicial deja el mapa sin foco. Enfocar un miembro→Enter, comprar Poción→Enter y abrir PC eliminan el control enfocado. Abrir habilidades con su botón deja foco vacío, mientras A conserva el tablero. Las pestañas de tienda sí restauran su foco. No declares un bloqueo total: Tab puede recuperar navegación, pero se pierde el punto de apoyo.

Archivos a examinar:
godot/ui/laboratory.gd (_clear, _refresh, _open_actions, _unhandled_key_input), campaign.gd (_render_travel, _event, _select_member, _roster_page, _shop_page), title_screen.gd, roster_panel.gd, board.gd, isometric_board.gd y project.godot. Reutiliza qa_interface.gd. No refactorices el motor para resolver foco.

Implementación:
1. Acciones con nombres de intención, usando mecanismos del Godot instalado y una sola fuente de asignaciones: aceptar, cancelar, menú, cursor, habilidades, ranuras1–5, rectificar, orientación, inspección, objetivo anterior/siguiente, cámara y zoom. Si alguna función aún no existe, no expongas un control muerto ni implementes otro bloque entero.
2. Reasignación local: detectar conflictos dentro del mismo contexto, ofrecer sustituir/cancelar, restaurar categoría y salida segura. No dejar aceptar/cancelar inaccesibles ni interceptar combinaciones del sistema. Etiquetas y ayuda se generan desde asignaciones reales. Reutiliza preferencias existentes; si faltan, crea la solución mínima versionada y recuperable.
3. Prioridad: modal > campo de texto/menú activo > tablero. Un evento tiene un propietario y no atraviesa menús. A/R/F/números en semilla o búsqueda nunca envían órdenes. Hover no roba foco al teclado; clic sí puede cambiar el método activo.
4. Foco por identidad estable de función/datos, nunca NodePath autogenerado: miembro.id, artículo.id, movimiento.id, pestaña. Tras refrescar, restaurar control, desplazamiento y selección. Si desaparece o se deshabilita, elegir vecino lógico; no volver a controles ocultos o liberados.
5. Oak e Inicio tienen foco inicial explícito. Popups y diálogos contienen navegación y devuelven foco al origen. PC y selectores mantienen contexto. Foco visual, miembro seleccionado y Pokémon activo son conceptos distintos.
6. Tab/Mayús+Tab recorren controles; flechas siguen su estructura; Enter/Espacio activan. El tablero usa flechas para casillas cuando posee el foco. Acceso explícito a órdenes/paneles sin recorrer toda la pantalla. Tab no sirve a la vez para objetivos.
7. Repetición configurable solo para navegación/cámara. Ataques, compras, objetos, captura y terminar requieren una pulsación nueva. Una tecla sostenida no se hereda al nuevo contexto ni activa dos veces por key-down/key-up.
8. Configuración independiente del diario de campaña: foco, remapeo y páginas no cambian RNG, revisión ni órdenes.

Aceptación:
- Inicio→Oak→inicial→miembro→habilidades sin ratón, con foco visible y válido en cada transición.
- Tres pulsaciones separadas de Enter compran exactamente tres pociones y conservan foco; mantener Enter no compra de más.
- PC con0/1/6/7/30 miembros, duplicados diferenciados por ID, páginas con selección coherente y sin saltos al inicio.
- Ayuda, confirmación y opciones se abren/cancelan y restauran el origen sin filtrar entrada al tablero.
- Remapear/reiniciar: etiquetas y comportamiento coinciden; configuración inválida recuperable; salida segura siempre accesible.
- Ratón→teclado→ratón sin órdenes por cambiar foco. Seleccionar/filtrar/abrir menús conserva estado completo de campaña.

Verificación y entrega:
Eventos nativos de teclado/puntero en viewport para probar entrada; emitir pressed solo prueba enlaces, no manejo de entrada. Aísla APPDATA/LOCALAPPDATA y QA, sin tocar guardados humanos o sobrescribir evidencias previas. Ejecuta lint/validación y scripts pertinentes de interfaz, PC y escala. Regresión de reglas si se tocaron. Comprueba la exportación cuando prepares paquete. Entrega código, pruebas y un informe con controles, capturas, verificación real y límites. Resolver foco no demuestra compatibilidad con lectores de pantalla.
~~~~

## Prompt 02 — Turno contextual y cámara sin dependencia de botones

~~~~text
Implementa una actualización de control contextual del combate nativo de Pokémon Tactics — Kanto. Lee AGENTS.md, godot/AGENTS.md, scripts y docs/reports/beta-accesibilidad-0.22.1/INFORME.md; revisa git status y conserva cambios ajenos. Verifica primero la base de acciones/foco del prompt01; reutilízala, sin otro router. Trabaja solo este bloque, sin encadenar los demás ni delegar automáticamente.

Objetivo:
Dar órdenes mirando al tablero y a los Pokémon, con teclado completo o ratón completo. Mantener el menú integrado como alternativa. Reducir pasos sin decisión, sin consumir acciones al explorar ni añadir confirmaciones a todo.

Reglas intocables:
Base0.22.1/campaña18/combate17. Movimiento+acción en ambos órdenes, cola por ronda, cuatro movimientos+básico neutro, aliados atravesables/destinos libres. R solo rectifica antes de cualquier acción o fin de turno: jamás devuelve PS/PT, ataques, estados o RNG. Inspección/render/cámara no consumen azar. Persistir cada orden aceptada antes de animar. Sin cambios de balance, IA, precios, mapas o guardados publicados. No editar src/, public/, activos originales o CREDITS.md raíz ni publicar.

Archivos:
ui/laboratory.gd (selección/confirmación/commit), campaign.gd (persistencia/contexto), board.gd e isometric_board.gd (cursor/pan/zoom/selección), todos dentro de godot/. Consulta core/movement_revision.gd y reglas compartidas. Menor cambio útil, sin jerarquías nuevas de Pokémon.

Comportamiento:
1. Contextos explícitos: tablero neutro, movimiento previsto, habilidad seleccionada, objetivo previsto, orientación, confirmación y modal. Una sola fuente verificable, sin una máquina de estados sobredimensionada.
2. Clic o Enter en casilla válida mueve directamente. Elegir habilidad muestra y permite cancelar; apoyos propios no se ejecutan al abrir su ranura. Atajos1–5 y menú comparten ruta y coste.
3. Q/E propuestos recorren objetivos válidos de la habilidad con orden estable, nombre y previsión. No consumen acción ni cambian unidad activa; inactivos en menús/campos. Inspección puede mostrar unidades fuera de alcance, diferenciándolas de objetivos legales.
4. Preferencias Rápido/Seguro: ataque directo sobre objetivo identificado frente a aceptación final. Aviso explícito de fuego amigo/autocoste letal en ambos; no dos confirmaciones para la misma intención. La selección siempre debe ser distinguible de una orden aceptada.
5. Tras mover y actuar, abrir orientación. F permite terminar antes, indicando recursos sin usar. En orientación, flechas previsualizan dirección y Enter termina; ratón ofrece brújula equivalente. Escape cancela orientación, no termina ni rectifica. Clic fuera no ordena.
6. Cámara: rueda y+/-; pan central opcional, cruceta por clic y acciones de teclado. Perfil principal conserva A/R/F/C/G/H y1–5; pan Alt+flechas y modo cámara P activable sin mantener modificador, previa comprobación Windows. Un perfil WASD alternativo debe reasignar A de habilidades explícitamente. No conflictos activos. C centra; Combate/Mapa mantienen encuadres. Zoom mapa separado de texto.
7. Brújula para ejes isométricos. Derecha actual suma x y se proyecta en diagonal: no cambies coordenadas ni prometas un paso horizontal imposible entre vecinos. Cualquier esquema alternativo debe describir su mapeo y ser configurable.
8. Hover no roba selección de teclado. Umbral clic/arrastre para no mover/atacar al soltar pan. Repetición solo de cursor/cámara; nunca ataque/compras/fin de turno. Entrada sostenida no cruza turnos.
9. Menú e inspección modal suspenden avance rival; al cerrar conservan selección/cámara e invalidan callbacks obsoletos. Sin tiempos de reacción ni dobles clics obligatorios.

Aceptación:
- Mover→R restaura solo desplazamiento; mover→atacar→R bloqueado; actuar→mover tampoco rectificable.
- Seleccionar/cancelar apoyo propio mantiene estado completo/diario/RNG; confirmar aplica una sola orden.
- Turno sin tocar botones: flechas,Enter,ranura,Q/E,Enter,F,flecha,Enter. Recorrido equivalente solo ratón, incluida cámara sin botón central.
- Objetivo inválido, aliado en área, autocoste letal,0PT, restricción de estado y destino ocupado: razón legible, sin gasto inválido.
- Arrastre no mueve unidades; modal no deja avanzar rival debajo ni hereda una tecla retenida.
- Mapas16/24 y alturas0–2; acercamiento/empuje respetan las mismas reglas del motor y la IA.

Entrega:
Pruebas de eventos nativos, guardados aislados, regresión movimiento/rectificación/replay, lint y validación. Comparar estados completos para órdenes equivalentes, no solo capturas. Documentar controles definitivos y comprobación de fuente/ejecutable cuando se prepare paquete. El encargo es fluidez y seguridad de entrada, no rebalanceo.
~~~~

## Prompt 03 — Inspección, previsión y lectura táctica

~~~~text
Mejora la lectura táctica de Pokémon Tactics — Kanto en Godot. Implementa solo inspección e información de combate. Lee instrucciones, scripts y docs/reports/beta-accesibilidad-0.22.1/INFORME.md; revisa git status y conserva cambios ajenos. Reutiliza entrada/foco y ajustes existentes. Si faltan dependencias, identifica el mínimo necesario sin ejecutar otros bloques completos ni delegar automáticamente.

Guardas:
Base auditada0.22.1, campaña18/combate17. La previsión ya calcula daño mínimo/máximo, crítico, precisión, STAB, tipos, autocoste, estados, etapas, empuje y acercamiento. Usa sus resultados: no recalcules fórmulas en UI ni cambies probabilidades, IA, catálogo o efectos. Inspeccionar/cancelar/dibujar no consume RNG/transacciones. Conserva web, motores/datos publicados, activos originales y CREDITS.md raíz. Sin publicación o plugins nuevos por defecto.

Archivos:
godot/ui/laboratory.gd (_hover_tile, _show_plan, _preview_self), campaign.gd, unit_indicators.gd, board.gd, isometric_board.gd y combat_feedback.gd. Consulta planes/recibos reales. El registro ya existe en Equipo y registro: no digas que carece de él.

Resultado:
1. Ficha de inspección persistente con I reasignable y una acción visible de ratón. Misma información esencial desde cursor, lista y puntero, sin hover obligatorio. Cerrar devuelve contexto exacto sin atacar, gastar ni cambiar unidad activa.
2. Resumen: nombre/nivel, equipo, PS/PT, movimiento/acción restante, tipos, habilidad efectiva y si está implementada, orientación/altura. Estados con nombre completo, etapa firmada y activaciones restantes. Explicar parálisis y caducidades usando la edición real de la partida; clásicos no heredan una descripción falsa.
3. Previsión en dos capas. Principal: acción/objetivo, coste, legalidad, rango de daño normal, precisión y riesgo a aliados. Detalle: crítico/probabilidad/rango, STAB, tipos, lado, altura/visión, habilidad, autocoste, empuje/acercamiento y duraciones. No presentar máximo crítico como KO garantizado ni multiplicar daño otra vez.
4. KO garantizado/posible solo con datos suficientes, considerando precisión/pasivas. Si hay incertidumbre por efectos complejos, conservar datos y lenguaje prudente. Razón concreta de ilegalidad: alcance, visión, recurso, destino o restricción.
5. Activo/aliado/enemigo/movimiento/ataque/amenaza con formas y contornos además de color. Signos+1/+2/−1/−2 legibles; agrupar iconos sobre sprites cuando haya muchos, manteniendo detalle completo. Sin modificar hojas originales.
6. Vista de amenazas opcional solo si puede consultarse de forma pura con información pública: «puede alcanzar», no «hará este ataque». No futuras tiradas ni decisiones ocultas de IA. Poder apagarla.
7. Historial: actor/objetivo, movimiento, daño real, fallo/inmunidad, crítico, pasiva, estados y expiraciones cuando los eventos lo suministren. Separar previsión y resultado, sin inventar recibos ni cambiar diarios legacy. Consulta del último evento mediante ambos métodos de entrada; no depender de marcas flotantes0,95s.
8. Ayudas de PT, básico neutro sin STAB, duración por activaciones y orientación accesibles en foco y detalle, además de tooltip. Resumen compacto; detalle opcional no tapa casillas decisivas. Español y nombres del catálogo real.

Pruebas:
- Frente/flanco/espalda coincide con plan; presentación no cambia precisión. Crítico garantizado no significa acierto garantizado.
- Varios estados/etapas, dos activaciones y habilidad pendiente: nombres completos, signos y advertencia verdadera.
- Fuego amigo, inmunidad, Robustez, autocoste, curación, acercamiento y empuje bloqueado: consecuencias correctas sin duplicar cálculos.
- Inspeccionar100 veces conserva estado/PRNG/diario. Teclado/ratón/mixto consultan mismo contenido y cancelan con foco restaurado.
- Ventana mínima y texto ampliado: cifras/confirmación accesibles. Captura en gris ayuda a revisar señales, pero no valida daltonismo humano.
- Silencio+movimiento reducido no eliminan información; historial recupera un fallo cuando ya desapareció su marca.

Entrega:
Implementación mínima, pruebas de coherencia UI/plan/recibo y capturas reales. QA aislada; lint/validación y regresiones pertinentes de interfaz/escala. Informa pruebas ejecutadas y pendientes humanas. No declares soporte de lector de pantalla sin su prototipo y evaluación específica.
~~~~

## Prompt 04 — Preferencias persistentes y legibilidad

~~~~text
Implementa preferencias accesibles y legibilidad adaptable para el ejecutable Godot de Pokémon Tactics — Kanto. Lee instrucciones, scripts y docs/reports/beta-accesibilidad-0.22.1/INFORME.md; revisa git status. Reutiliza entrada/configuración existente. Solo este bloque, sin delegación automática, rebalanceo o publicación.

Evidencia:
En0.22.1, ventana1024×720 conserva lógica1280×900 y fuentes18/17. Stretch reduce todo al80%; size.x<1150 de _layout_battle_hud no selecciona su composición compacta. Zoom de tablero no amplía HUD. Sonidos/Animaciones vuelven a activos al recrear escena. Verifica si la rama actual ya lo corrigió.

Objetivos:
1. Configuración local independiente del guardado de campaña, versionada/recuperable. Cargar antes de Inicio; persistir al cambiar y conservar al iniciar campaña, entrar al laboratorio y reiniciar proceso. Archivo inválido conservado para diagnóstico; solo campos inválidos vuelven a valores seguros. Sin telemetría ni datos de cuenta.
2. Texto/HUD100/125/150% iniciales, separados del zoom del mapa. No escalar ciegamente todo el viewport: adaptar contenedores, saltos, fichas desplegables y navegación. Medir ventana y DPI reales. No exigir todo el detalle abierto simultáneamente.
3. Conservar Atkinson/recursos existentes. Escalar cifras, indicadores y cursor; ofrecer alto contraste y tamaño de casilla activa. Señales por forma/texto además de color y tipos reconocibles. No descargar fuentes/activos innecesarios.
4. Movimiento reducido persistente: quitar desplazamientos decorativos y controlar seguimiento de cámara, sin ocultar resultados. Velocidad visual/duración de lectura separadas de lógica de turnos. Ampliar duración de resultados e historial sin adelantar IA al acelerar presentación.
5. Sonido persistente y volumen general; categorías solo para buses realmente presentes. No controles vacíos de voz/música. Fallo/inmunidad/crítico también en texto. Sliders operables por teclas/pasos y valor numérico; sin arrastres obligatorios.
6. Integrar Rápido/Seguro y remapeo ya existentes, con descripción de lo que protegen. No crear configuraciones duplicadas. Ajustes sin órdenes de campaña/RNG.
7. Restablecer por categoría y volver con foco conservado. Antes de una escala/modo que pueda dejar al usuario sin acceso, proporcionar recuperación accesible verificada, sin depender del mismo diseño roto.

Archivos:
godot/project.godot, ui/campaign.gd (_layout_battle_hud/_title_options), laboratory.gd (tema/sonido/movimiento), title_screen.gd, unit_indicators.gd, combat_feedback.gd. Consulta API del motor antes de usar propiedades de escala/DPI/accesibilidad. No editar src/, public/, motores/datos publicados, activos originales o CREDITS.md raíz. Sin plugins nuevos.

Matriz de aceptación:
- Ventanas1024×720,1280×900,1920×1080; texto100/125/150%; DPI Windows100/125/150/200% en combinaciones realmente ejecutables. Marcar las demás pendientes.
- Inicio/Oak/órdenes/previsión larga/orientación/tienda/PC/diálogos: datos esenciales y aceptar/cancelar alcanzables. Scroll vertical de detalle permitido; no horizontal para cifras críticas.
- Texto150% conserva alcance, hit-test, posiciones lógicas y resultados. Zoom mapa independiente de ficha.
- Guardar, cerrar proceso y abrir: ajustes antes de primera pantalla/sonido. Archivo truncado/fuera de rango/campos desconocidos no dañan campaña.
- Teclado completo, foco visible/restaurado; cambio mixto no produce órdenes debajo. Silencio+movimiento reducido conserva comprensión.
- Medir contraste de pares reales y revisar foco, deshabilitado, selección, unidades y superposiciones. No declarar conformidad WCAG de un ejecutable con esos cálculos.

Entrega:
Preferencias/guardados QA aislados, pruebas de entrada y reinicio de proceso, lint/validación, interfaz/escala y ejecutable cuando se prepare paquete. Documentar valores, recuperación, capturas, DPI realmente probado y límites de lectura humana. No cambiar economía/daño para solucionar presentación.
~~~~

## Prompt 05 — Tienda por cantidad y preparación del equipo

~~~~text
Reduce la fricción de tienda en Pokémon Tactics — Kanto, manteniendo exactamente su economía y progresión. Lee AGENTS.md, godot/AGENTS.md, scripts y docs/reports/beta-accesibilidad-0.22.1/INFORME.md. Revisa git status, conserva cambios ajenos y reutiliza entrada/foco/ajustes disponibles. Solo este bloque, sin delegación automática, rebalanceo ni publicación.

Problema:
Comprar y usar cada Caramelo/curativo obliga a muchas operaciones y reconstruye menús. Los ensayos previos usaron99/129/95 caramelos en tres campañas victoriosas; no prueban tiempo humano, pero justifican medir repetición. En0.22.1 comprar una poción con Enter incrementa bolsa correctamente y pierde foco. Corregirlo/reutilizar prompt01 antes de ampliar operaciones.

Contrato:
Campaña18/combate17 en la base auditada. Caramelo25 ₽ por+1 nivel; cap del siguiente gimnasio y evolución automática según especie; crecimiento de PS actuales igual al aumento positivo de máximos. No revivir por subir nivel. Revivir150 ₽, solo tienda,50%PS; curativos y requisitos reales del catálogo. Un equipable. Tres ofertas MT/equipables y rerolls crecientes conservados. Revalida cifras contra la versión actual antes de codificarlas. Motores/datos y replay publicados no se editan silenciosamente. src/, public/, activos originales y CREDITS.md raíz congelados.

Diseño solicitado:
1. Elegir compañero una vez y mantenerlo al cambiar pestaña/artículo. Identificarlo con nombre,ID/nivel/PS; no usar índice de lista como identidad. Precio, bolsa, saldo y destinatario siempre claros. Mantener Seguir viaje fijo.
2. Selector de cantidad por teclas/botones y entrada numérica validada. Compra y uso son operaciones distintas. Nunca gastar dinero automáticamente al pulsar Usar sin una decisión explícita de comprar.
3. Caramelo: mostrar nivel actual→nivel solicitado→cap, unidades en bolsa, por comprar, coste total y saldo previsto. Anunciar evoluciones/aprendizajes/gananciaPS que se produzcan a lo largo de la secuencia. No saltarse umbrales intermedios ni sustituir movimientos automáticamente.
4. Curación: objetivo/PS actuales y restauración prevista, número de unidades y desperdicio si existe. Permitir varias unidades sin clic repetido, pero no añadir curación grupal gratuita. Revivir solo sobre debilitado válido y sin reequipar lo devuelto a bolsa. Bloquear sobrecuración/uso inválido según motor.
5. Comprar/usar cantidad confirma un resumen una vez; tras aceptar, ejecutar una secuencia definida de órdenes actuales validadas con su revisión. Resultado final y diario equivalentes a esa secuencia manual. No introducir una orden nueva en una edición publicada ni cambiar formato persistido sin estrategia de versión explícita.
6. Revalidar destinatario, bolsa, dinero, cap, disponibilidad y revisión al aceptar. No aceptar dos veces por doble clic/Enter sostenido. Bloquear entrada de otra operación durante el procesamiento, conservar una salida segura y mostrar progreso si la secuencia tarda.
7. Persistencia: respetar guardado tras cada orden aceptada. Si solo hay atomicidad por orden, no prometer atomicidad del lote. Si falla, detener y distinguir órdenes aceptadas en memoria, persistidas y pendientes; preservar archivos/copia. No continuar consumiendo recursos ni reejecutar al reiniciar. Cualquier necesidad de cambiar garantías se resuelve con diseño/versionado específico, no ocultándola.
8. Filtros, cantidad, vistas previas y cancelación son presentación pura. Reroll sigue costando lo indicado, no se dispara al cambiar pestaña ni al actualizar la vista.

Archivos:
godot/ui/campaign.gd (_event, _render_travel, _shop_panels, uso/compra/rasgos/equipo), roster_panel.gd, core/journey_run.gd y journey_store.gd para comprender contratos. No cambies core legacy para acortar clics.

Pruebas:
- Comprar/usar1 y5 caramelos: comparación completa con secuencia manual, incluidos bolsa/saldo/niveles/evoluciones/PS/movimientos/RNG/diario.
- Cap14/otros gimnasios, cantidad0/negativa/enorme/texto inválido, fondos insuficientes, bolsa parcial, miembro debilitado/PC y estado fuera de tienda. Todo inválido sin gasto.
- Revivir deja50%, no activa equipable devuelto, curar después funciona; no permitir continuar una campaña derrotada.
- Cancelar resumen, cambiar destinatario y abrir pestañas conserva estado; doble clic/tecla sostenida no duplica.
- Fallo simulado de persistencia y revisión obsoleta: sin consumo posterior ni repetición al recargar; informe honesto de aceptación parcial.
- Mismo recorrido teclado/ratón, foco/scroll conservados, texto ampliado; medir interacciones contra base con el mismo objetivo.

Entrega:
UI y pruebas necesarias, sin nuevas dependencias. QA aislada; scripts pertinentes de progresión/caps/revivir/release/interfaz, según archivos tocados; lint/validación. Adjunta comparación manual/lote y medición de interacciones antes/después. Reducir50% es un objetivo a evaluar, no una cifra que se pueda declarar sin medición.
~~~~

## Prompt 06 — PC y repertorios grandes

~~~~text
Mejora la gestión de equipo, PC y movimientos en Pokémon Tactics — Kanto. Lee AGENTS.md/godot/AGENTS.md/scripts y docs/reports/beta-accesibilidad-0.22.1/INFORME.md; revisa git status y conserva cambios ajenos. Reutiliza navegación/foco/ajustes ya implementados. Limita el encargo a este bloque, sin delegación automática ni publicación.

Contrato a preservar:
Base0.22.1 campaña18/combate17. Equipo máximo6 plazas, incluidos debilitados; PC ilimitado; cambiar solo en fases permitidas, gratis y sin curar. Siempre al menos un activo en pie; derrota del combate termina campaña aunque haya reservas vivas. Duplicados permitidos con ID de instancia distinto de speciesId. Conservar miembro completo: PS, nivel/EXP, movimientos, rasgos, origen y equipable. Reservas no ganan EXP de combate. Cuatro movimientos preparados+básico neutro fijo aparte. Cambiar repertorio solo donde se permite. No alterar reglas/economía ni fuentes LGPE, motores/datos publicados, src/,public/, activos originales o CREDITS.md raíz.

Archivos:
godot/ui/roster_panel.gd, campaign.gd (_select_member, _roster_page, _render_moves, _toggle_move y equipo/rasgos), title_screen.gd si necesita restauración. Consulta core/roster_run.gd y journey_run.gd, sin modificarlos para ordenar visualmente.

Implementación:
1. PC con búsqueda por nombre y filtros de tipo, estado en pie/debilitado y función derivada del repertorio existente. Ordenación por nombre/nivel/PS/origen con desempate estable por ID. Añadir filtros solo si hay datos fiables; no inventar roles o estadísticas.
2. Separar orden visual del orden real de equipo/iniciativa. Filtrar no cambia miembro ni diario. Conservar selección por ID, página y scroll; si deja de estar visible, mostrarlo claramente y ofrecer volver, o elegir vecino siguiendo una regla explícita sin efectuar una operación.
3. Duplicados distinguibles por nivel, origen e identificador de instancia legible. No añadir motes persistidos sin analizar su contrato. No perder estados al depositar/intercambiar.
4. Equipo y PC con navegación completa por teclado/ratón, resultados de búsqueda anunciados y salida recuperable si lista vacía. Búsqueda consume letras y números sin activar combate. Cambiar panel no obliga a recorrer todos los controles.
5. Intercambio directo con ficha antes/después de entrante y saliente: PS/nivel/tipos/objeto/movimientos. Aceptar usa los IDs y revisión actuales; cancelar no toca nada. Restricciones con razón textual, no solo botón gris. No hace falta arrastrar para intercambiar.
6. Preparación de movimientos: cuatro ranuras visibles y básico fijo aparte, biblioteca filtrable por tipo/categoría/rol/coste y detalle consultable. Mostrar alcance/área,PT,efecto,condiciones y adaptación cuando exista. Misma información por foco o puntero.
7. Reemplazar una ranura en un recorrido: elegir ranura→movimiento→comparación→aceptar; no exigir quitar y buscar de nuevo. Producir un loadout válido mediante el contrato actual. No preparar un quinto, eliminar básico, enseñar algo desconocido ni usar una MT por inspección.
8. Aprendizajes pendientes/futuros separados de disponibles; fecha/nivel y forma reales del catálogo. Al evolucionar, conservar y mostrar lo que permita el motor, sin una decisión automática de «mejor ataque». El indicador de rol describe movimientos y no concede un bonus nuevo.
9. Selección y filtros sin RNG/órdenes; depositar/retirar/intercambiar o aceptar repertorio genera exactamente la transacción legal. Doble clic/tecla sostenida no duplica.

Pruebas:
- PC0/1/6/7/30/100 como fixtures sintéticos de UI claramente etiquetados, no resultados de campaña. Duplicados y miembros debilitados con rasgos/equipo.
- Equipo lleno, último activo en pie, reserva viva tras derrota y fasecapture: mismas restricciones de motor con mensajes correctos.
- Ordenar/filtrar/cancelar mantiene estado completo; swaps mantienen objetos yPS y no confunden duplicados.
- Repertorio0–4 preparados, muchos conocidos, movimientos sin recursos/en evolución, MT incompatible. Reemplazo válido mantiene básico y conoce exactamente cuatro como máximo.
- Secuencias equivalentes de interfaz/motor conservan replay, revisión y RNG. Foco no desaparece al preparar, buscar, paginar o cambiar selección.
- Texto ampliado/ventana mínima y solo teclado/solo ratón, sin hover o arrastre obligatorio.

Entrega:
Pruebas nativas de entrada nuevas y regresiones PC/catálogo/interfaz pertinentes, QA aislada, lint/validación y capturas reales. Mantener guardados humanos intactos. Documentar restricciones y límites de listas grandes, diferenciando fixtures de campañas jugadas. Evitar refactorización del catálogo o nuevas dependencias para una mejora de navegación.
~~~~

## Prompt 07 — Tutorial y continuidad de la campaña

~~~~text
Implementa aprendizaje contextual y continuidad de aventura para Pokémon Tactics — Kanto. Antes, lee instrucciones, scripts y docs/reports/beta-accesibilidad-0.22.1/INFORME.md; revisa git status. Verifica controles y fichas actuales para no enseñar atajos obsoletos. Trabaja solo este bloque, sin delegación automática, rebalanceo o publicación.

Objetivo:
Una persona que conoce Pokémon, pero no nuestras adaptaciones tácticas, debe aprender a mover, prever, cancelar, rectificar y orientar sin leer un manual largo. Un jugador que vuelve tras varios días debe saber dónde está, qué objetivo tiene y qué recursos lleva.

Guardas:
Base auditada0.22.1/campaña18/combate17. No cambiar encuentros, capturas, daño, economía, IA o riesgo de campaña para demostrar el tutorial. Práctica separada de la aventura real, sin recompensas transferibles ni alteración de sus guardados/diarios. Conservar versiones anteriores, src/, public/, activos originales y CREDITS.md raíz. Sin servicios o plugins nuevos.

Archivos:
godot/ui/title_screen.gd, campaign.gd, laboratory.gd (ayuda), roster_panel.gd y presentación de resultados. Consulta el laboratorio existente: reutiliza su función de práctica cuando encaje, sin cambiar ensayos clásicos o presentar datos ficticios como originales.

Diseño:
1. En Inicio, acceso a «Aprender a jugar» y «Controles/accesibilidad» mediante ambos métodos. Tutorial opcional, saltable y repetible, sin bloquear Continuar ni exigirlo en cada campaña. Aplicar preferencias antes de empezar.
2. Práctica guiada con objetivos breves: seleccionar/cursor, mover, rectificar antes de actuar, comparar ataques, cancelar, usar un apoyo propio con confirmación, atacar, intentar rectificar y explicar bloqueo, orientar, consultar estado/activaciones, terminar. Esperar la acción correcta; no simular que el usuario la realizó.
3. Mostrar ayudas junto a la intención relevante, sin tapar casillas. Instrucciones actualizadas desde asignaciones reales; no «pulsaA» si está reasignada. Botón/atajo y alternativa de ratón siempre visibles.
4. Explicar diferencias adaptadas: básico neutro sin STAB, cuatro movimientos,PT, dirección afecta rango de daño/crítico y no precisión en edición actual, parálisis limita desplazamiento, estados/etapas temporales, altura/visión, aliados atravesables/destinos libres. No decir que reproduce exactamente un cartucho.
5. Enseñar gestión fuera de combate: PS persistentes, curación con objetos, Revivir50%, cap del siguiente gimnasio/EXP no acumulada, evolución/niveles, PC sin curación y derrota aunque existan reservas. No abrumar: introducir al necesitarlo y conservar glosario consultable.
6. Resumen de victoria: resultado,EXP/niveles/PS ganados,evolución,movimientos aprendidos,captura y siguiente paso; vista corta con detalle ampliable. Mostrar «aprendido» frente a «preparado». Saltar presentación no cambia transacciones ni pierde captura; no autoaceptar una elección de final.
7. Continuar: mostrar lugar/fase, medallas, siguiente objetivo/cap, equipo en pie y próxima decisión. Si leer un guardado frío requiere replay costoso, medirlo y usar un estado de carga honesto; no duplicar reconstrucción ni prometer progreso porcentual no disponible.
8. Lista/mapa de destinos con objetivo principal/desvío/requisito/recompensa pública. No descubrir capturas ni tiradas futuras. Finales legendarios excluyentes con confirmación clara de elección y sin permitir reclutarlos.
9. Ayudas desactivables/persistentes y repetibles. Pasar del tutorial a campaña restaura foco y no arrastra entradas. No bloquear temporariamente al usuario para obligarle a mirar animaciones; texto a su ritmo.

Aceptación:
- Tutorial completo con teclado y con ratón, silencio y movimiento reducido; saltar/salir/repetir no toca partida real.
- Una ayuda no produce órdenes al cerrarse. Controles reasignados aparecen correctos. Foco vuelve al tablero o control de origen.
- Subida/evolución/aprendizaje/cap muestran recibos reales, incluidos varios eventos en una victoria, sin duplicar recursos al recargar.
- Continuar en mapa/combate/tienda/captura/final mantiene fase exacta y mensajes veraces para una partida clásica.
- Elección legendaria no se acepta por Enter retenido; cancelar preserva todas las posibilidades originales.

Entrega:
Pruebas del tutorial y transiciones por eventos de entrada, guardados aislados, lint/validación y regresiones pertinentes. Capturas/guion de sesiones cortas con principiantes; si no hubo participantes, declararlo. No afirmar que una ayuda mejora diversión solo por superar aserciones. El éxito humano se evalúa con tareas y preguntas de comprensión, no por haber mostrado todos los textos.
~~~~

## Prompt 08 — Viabilidad de lector de pantalla

~~~~text
Realiza e implementa un prototipo acotado de acceso sin visión para Pokémon Tactics — Kanto en Godot, sin prometer accesibilidad completa. Lee AGENTS.md, godot/AGENTS.md, scripts y docs/reports/beta-accesibilidad-0.22.1/INFORME.md; revisa git status. No delegues automáticamente, instales herramientas externas, publiques ni amplíes a todo el juego sin validar primero el corte.

Contexto:
La auditoría0.22.1 comprobó en la API instalada Godot4.7.2 Control.accessibility_name, accessibility_description, accessibility_live y SceneTree.is_accessibility_supported/is_accessibility_enabled. Eso prueba existencia, no funcionamiento con tecnologías de apoyo. El tablero/estados se dibujan en Canvas y no tienen una representación semántica dedicada en el código auditado. Los botones nativos pueden aportar semántica básica; inspecciónala antes de reemplazarla.

Alcance verificable:
Inicio→Oak→primer combate de prueba→seleccionar casilla/unidad→consultar previsión/estado→aceptar o cancelar→orientar→volver al menú. Añadir una muestra de tienda con artículo/saldo/destinatario para probar reutilización. No afirmar soporte de toda Kanto a partir de este corte.

Guardas:
Campaña18/combate17 y guardados publicados intactos; sin cambios de balance, RNG, IA o economía. Accesibilidad no consulta futuros resultados. src/, public/, motores/datos publicados, activos originales y CREDITS.md raíz congelados. Guardados QA aislados. Sin servicios de voz/red ni dependencias por defecto.

Fase1: comprobar compatibilidad:
1. Consulta las API exactas del motor instalado y documentación oficial pertinente; registra versión/hash, backend/Windows y si accesibilidad figura soportada/activa en entorno gráfico real.
2. Inspecciona nombres,roles,estados,foco/orden y cambios de los controles actuales, con el lector ya disponible si existe. No inventes herramientas probadas. Headless no demuestra salida audible ni árbol accesible funcional.
3. Si no hay tecnología de apoyo disponible, implementa/prueba la representación textual y contratos, entrega instrucciones concretas de prueba y marca NVDA/Narrador u otra tecnología como pendientes. No declares compatibilidad ni detengas trabajo independiente útil. Cualquier instalación requiere la autorización correspondiente.

Fase2: corte implementado:
4. Menús con nombres descriptivos, seleccionado/deshabilitado y razón; leer precio,bolsa,saldo y destinatario sin concatenaciones ambiguas. Decoración/retratos redundantes no generan ruido. No apliques ARIA web a Control.
5. Tablero con cursor lógico y representación textual de casilla: coordenada,terreno,altura,ocupante,equipo,nivel,PS,PT,orientación y acción legal actual. Navegación por casillas y lista de unidades/objetivos; ambos sincronizan el mismo cursor y modelo.
6. Previsión estructurada: movimiento,coste,objetivo,daño normal,precisión,crítico,efectividad y riesgo; detalles a petición. Estado/etapas con nombre,signo y activaciones restantes. No anunciar todo el tablero por cada paso.
7. Anuncios moderados de turno,resultado,error y cambio de selección; agrupar eventos, evitar repetir texto íntegro en cada refresh y permitir interrumpir/consultar último mensaje. Foco y lectura coherentes tras reconstrucción. Los controles no generan doble narración por dos sistemas distintos.
8. Modo accesible no necesita hover, arrastre, visión de color ni reacción temporal. Las teclas de juego no roban atajos del lector sin contexto; ofrecer asignaciones alternativas. El menú mantiene salida recuperable.
9. Si se usa síntesis nativa además del árbol accesible, justificarlo, evitar duplicación y probar ambos modos. No añadir un proveedor remoto de voz. Mantener funcionamiento normal aunque el backend no admita accesibilidad.

Pruebas y aceptación:
- Navegación lógica automatizada del corte, sin transacciones/RNG al inspeccionar. Aceptar exactamente una orden y cancelar ninguna.
- Árbol/nombres/estados/orden comprobados con herramientas realmente disponibles; idioma y anuncios correctos.
- Recorrido con lector de pantalla en el ejecutable Windows, registrando lector/versión/configuración. Si falta, «pendiente», no «aprobado».
- Prueba de participante usuario del lector, cuando sea posible y con consentimiento; ningún registro de diagnósticos innecesario. Que pueda explicar casilla,objeto/objetivo y resultado sin ayuda visual.
- Menú/combate normales conservan entrada, rendimiento y guardados. Medir cualquier coste observado sin inventar FPS.

Entrega:
Prototipo mínimo, representación textual/pruebas, informe de viabilidad, límites por pantalla y una lista ordenada para ampliar después. Lint/validación y regresión pertinente. Diferencia claramente API existente, semántica instrumentada, prueba automática, lectura real y validación humana. No uses un porcentaje de conformidad WCAG para calificar este juego.
~~~~

## Prompt 09 — Beta de aceptación y experimentos de jugabilidad

~~~~text
Actúa como responsable de QA y diseño de pruebas de Pokémon Tactics — Kanto. Prepara y ejecuta las comprobaciones automatizadas disponibles, y deja un kit de prueba humana para accesibilidad/jugabilidad. Lee instrucciones, scripts, versión vigente y docs/reports/beta-accesibilidad-0.22.1/INFORME.md. Revisa git status y conserva cambios ajenos. Sin delegación automática, publicación, balance automático ni modificación de partidas humanas.

Objetivo:
Comprobar resultados de las actualizaciones de control/lectura/gestión y obtener evidencia para decidir qué mejorar después. No confundir «el bot gana», «no hay errores» o «el texto se ve en una captura» con diversión, accesibilidad humana o balance resuelto.

Base y separación:
La auditoría0.22.1 aportó20 observaciones nativas sintéticas. La QA58 y las29 simulaciones de balance pertenecen a entregas anteriores. Mantén fecha/commit/método y no sumes todas como pruebas nuevas. Base campaña18/combate17; conserva replay/versiones y src/,public/,CREDITS.md raíz. No cambies catálogos o parámetros para conseguir un aprobado.

ParteA: regresión ejecutable:
1. Matriz de métodos: solo teclado, solo ratón sin botón central, mixto; preferencias normal/seguro, silencio y movimiento reducido; ventanas mínima/normal/texto ampliado.
2. Estados: Inicio nuevo/continuar, Oak, mapa, turno aliado/rival, apuntado, orientación,confirmación, victoria,captura,tienda,PC,derrota,final exclusivo y guardado inválido. Campo de texto/modal no filtran órdenes.
3. Seguridad: foco nulo/oculto tras mutación, pulsación mantenida, doble clic, cancelación, hover al navegar con teclado, clicar donde desapareció un menú y callbacks IA al volver a Inicio.
4. Reglas: R solo movimiento antes de acción, aliados atravesables/destinos ocupados no, básicos/movimientos/PT, estados y duraciones, cap/crecimientoPS/Revivir/PC. Previsión/cámara/configuración sin RNG. Compras por cantidad equivalentes a órdenes manuales si existen.
5. Probar entrada real del viewport; una señal pressed no prueba teclado. QA aislada en directorios nuevos, sin sobrescribir evidencia histórica. Ejecutar scripts pertinentes de package.json según cambios; no toda la batería indiscriminadamente. Comparar fuente/ejecutable cuando se prepare entrega y conservar logs/estado final.
6. Matriz honesta de DPI/tecnologías de apoyo/ventanas no disponibles como pendientes. Sin afirmar rendimiento o lectura humana sin medición.

ParteB: kit humano:
7. Guion30–45min para6–8 participantes exploratorios con experiencia variada de Pokémon/tácticos; incluir usuarios de teclado y necesidades de acceso pertinentes cuando participen voluntariamente. No reclutar/mensajear a nadie sin autorización explícita. No fabricar testimonios ni identidades.
8. Consentimiento, pausas y retirada libre; recoger solo lo necesario. Plantilla con versión/semilla/inicial/mapa/método/ajustes/tarea/tiempo/interacciones/errores/ayuda/comprensión/comentario. No diagnósticos personales.
9. Tareas sin explicar solución: empezar, mover/rectificar, comparar/cancelar, atacar/orientar, consultar un estado, preparar cuatro movimientos, comprar/usar5 caramelos y curar2 miembros, intercambiar un duplicado, guardar/salir/continuar. Fixtures sintéticos identificados para PC/tienda avanzada, sin obligar a horas de campaña.
10. Medir foco perdido, órdenes no deseadas, tiempo/interacciones de preparación, necesidad de ayuda y comprensión de PT/STAB/lados/temporales. Reducir50% de operaciones es objetivo a contrastar con la misma tarea en base, no resultado supuesto.

ParteC: experimentos separados de diseño:
11. Arranque: mismas semillas con tres iniciales, registrar decisiones humanas de movimientos/curación y derrotas. Datos previos del bot4/8 Bulbasaur frente0/8 de los otros motivan investigar; no estiman probabilidad humana ni imposibilidad.
12. Escala16/24: comparar duración,rondas sin contacto,desplazamientos sin decisión,utilidad de alturas/rutas y claridad. Registrar divergencias de trayectoria; no atribuir todo al tamaño por una campaña diferente.
13. Antes de diseñar objetivos nuevos, definir una hipótesis concreta: por ejemplo, dos aproximaciones legibles aumentan decisiones útiles sin alargar travesías. Proponer prototipo aislado y métricas. No implementar defender/rescatar/huir o cambiar daño dentro de este encargo.
14. Evaluar identidad de líneas por sus movimientos/alcance/movilidad y claridad de contrajuego; no añadir estadísticas/roles ocultos. Pedir explicaciones de elecciones, no solo notas numéricas.

Entrega:
Informe con defectos reproducibles,prioridad,evidencia y aceptación; resultados automáticos con denominadores/fechas; kit humano listo y resultados humanos solo si ocurrieron; backlog por impacto y riesgo. Si no hay participantes, la fase humana queda preparada/pendiente, sin fingir cierre. Cada propuesta de balance o mecánica nueva debe estar diferenciada de los fallos de acceso y quedar para autorización futura. No instalar plugins, añadir telemetría remota ni publicar para completar la prueba.
~~~~


## Estado20 de octubre

01–08 implementados con entregas0.22.2–0.22.9;09 ejecuta regresión0.22.10 y deja preparada la fase humana, todavía pendiente. Ver ../../SPRINT_22_ACCESSIBILITY_COMPLETE.md. No se declara compatibilidad audible ni balance humano cerrado.
