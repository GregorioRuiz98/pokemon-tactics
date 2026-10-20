# Informe de betatesting: accesibilidad, controles y jugabilidad

**Pokémon Tactics — Kanto · versión nativa 0.22.1 · 20 de octubre de 2026**

Base revisada: commit `9bbae5a653a189d5ce0c1b1565e62bdf0ddb7626`, Godot 4.7.2. Campaña edición 18; combate edición 17.

La mejora de mayor impacto es permitir que el jugador piense en **casillas, Pokémon y órdenes**, sin tener que buscar continuamente el botón adecuado. El juego ya tiene movimiento directo, atajos y previsiones útiles. Le falta una navegación que conserve la posición del jugador, una selección de órdenes segura y una gestión de equipo menos repetitiva.

Recomiendo resolver primero el foco del teclado, la escala de lectura y la interacción contextual. Después simplificaría tienda y PC. No tocaría daños, precios ni encuentros para corregir problemas de interfaz.

Este informe contiene propuestas; **no se han implementado cambios de jugabilidad**. Los [nueve prompts de actualización](PROMPTS_ACTUALIZACIONES.md) permiten abordar cada bloque por separado.

## 1. Qué se ha comprobado

| Método | Alcance y límites |
| --- | --- |
| Revisión del código actual | Inicio, Oak, mapa, combate, cámara, tienda, equipo, PC, indicadores, previsión, ayuda, opciones y guardado de órdenes. |
| Prueba nueva del ejecutor de Godot | **20 observaciones** con eventos sintéticos de teclado en el viewport nativo. Entrada desde Inicio, selección, foco, habilidades, cursor, compra, pestañas y reinicio de la escena. [Resultados](evidencia/observations.json). |
| Preparación del escenario de tienda | La IA pura resolvió el primer combate mediante 35 órdenes; después se aceptó la captura. Se usó únicamente como preparación de la prueba de menús. **No es una partida completa jugada con teclado.** |
| Inspección visual | Capturas existentes de la entrega 0.22.1 a 1024×720: [combate](../../qa/sprint-22-ui/battle-1024.png), [tienda](../../qa/sprint-22-ui/shop-1024.png) e [Inicio](../../qa/sprint-22-ui/title-1024.png). No se presentan como capturas nuevas. |
| Contraste calculado | Siete pares de colores opacos declarados en el tema; cálculo de luminancia sRGB. No equivale a medir todo el juego ni todas sus superposiciones. [Datos](evidencia/contrast.json). |
| API instalada | Existen `Control.accessibility_name`, `accessibility_description`, `accessibility_live` y consultas de soporte de accesibilidad. Su existencia **no prueba** compatibilidad funcional con un lector de pantalla. |
| Comprobación estática nueva | Lint del proyecto Godot: 0 errores y 0 advertencias. No es una prueba de accesibilidad ni sustituye la validación de ejecución. |
| Evidencia anterior consultada | QA de interfaz 58 comprobaciones, regresiones y [29 simulaciones de balance](../balance-native-0.22/INFORME.md). No se han vuelto a ejecutar ni se cuentan como pruebas nuevas. |

Las pruebas nuevas se realizaron en modo headless, sobre la fuente, con `APPDATA` y `LOCALAPPDATA` aislados. El sondeo asigna foco explícitamente a algunos controles para aislar su activación y comprobar qué ocurre después; los ajustes se cambian programáticamente. **No certifica un recorrido completo autónomo con teclado.** No se tocaron partidas humanas. No se ha repetido esta auditoría sobre el ejecutable exportado, ni con teclado físico, lectores de pantalla, conmutadores o jugadores con necesidades de acceso. Tampoco se midieron latencia, FPS, fatiga ni diversión humana.

La [evidencia reproducible](evidencia/README.md) incluye el sondeo empleado. Los nombres automáticos de nodos de sus registros sirven para identificar la observación, no para construir pruebas futuras dependientes de esos nombres.

## 2. Lo que conviene conservar

- Movimiento directamente sobre el tablero, sin una orden «Mover» intermedia. Los aliados son atravesables y las casillas ocupadas no son destinos válidos.
- Menú de órdenes dentro del juego, accesible al empezar el turno aliado. Mantenerlo como alternativa visible aunque se amplíen los controles directos.
- Un movimiento y una acción en cualquier orden; orientación final. Rectificar exclusivamente el movimiento antes de actuar, sin recuperar recursos ni azar.
- Previsión con rango de daño, precisión, crítico, STAB, efectividad, retroceso y desplazamientos. No hay que inventar un sistema paralelo para ofrecer información.
- Fuente Atkinson, PS numéricos, etiquetas de estado y etapas con signo. El color ya tiene varios apoyos textuales.
- Confirmación del fuego amigo, sonido y señal gráfica distintos para fallo/inmunidad, opciones de sonido/animación y guardado tras cada orden aceptada.
- Tienda por categorías y «Seguir viaje» fijo. Son avances útiles; el problema restante es la continuidad y la cantidad de operaciones.

## 3. Hallazgos priorizados

**P1:** afecta a un recorrido central o a un requisito de acceso. **P2:** fricción frecuente o información incompleta. **P3:** ampliación posterior. No se ha reproducido un defecto P0 de pérdida de datos o bloqueo irrecuperable.

**V:** verificado en el sondeo nuevo. **C:** observado en código/capturas, sin prueba humana. **H:** hipótesis de diseño que debe validarse.

| ID | Prioridad | Evidencia | Problema | Actualización |
| --- | --- | --- | --- | --- |
| A01 | P1 | V/C | Se pierde el foco al elegir miembro, comprar y abrir PC; también al pasar de Inicio a Oak. | Prompt 01 |
| A02 | P1 | V/C | La ventana mínima reduce toda la interfaz; no activa la composición compacta prevista. | Prompt 04 |
| A03 | P1 | C | Controles escritos como teclas fijas, sin reasignación ni perfil accesible de entrada. | Prompt 01 |
| A04 | P1 | C/H | Una habilidad propia se ejecuta al seleccionarla; ataques y final de turno requieren una política de confirmación coherente. | Prompt 02 |
| A05 | P1 | C | Detalles importantes dependen de pasar el puntero; los indicadores dibujados no tienen un recorrido propio de consulta con teclado. | Prompts 03/08 |
| A06 | P1 | C | Desplazar libremente la cámara requiere arrastrar con botón central; no hay equivalente explícito por pulsaciones. | Prompt 02 |
| A07 | P2 | V | Abrir habilidades desde su botón deja el foco vacío; el atajo A mantiene el tablero. | Prompt 01 |
| A08 | P2 | V/C/H | El cursor usa ejes lógicos isométricos e ignora la repetición de teclas. En mapas grandes puede sentirse lento o inesperado. | Prompt 02 |
| A09 | P2 | V/C | Sonido y movimiento reducido se reinician al recrear la escena. | Prompt 04 |
| A10 | P2 | C/H | Comprar y usar caramelos/curativos exige demasiadas operaciones individuales. | Prompt 05 |
| A11 | P2 | C/H | PC paginado y repertorios largos sin búsqueda/filtros; cambiar un movimiento exige quitar otro antes. | Prompt 06 |
| A12 | P2 | C/H | La previsión completa compite por atención con casillas, retratos y texto; falta una lectura rápida de intención y consecuencias. | Prompt 03 |
| A13 | P2 | C | Resultados flotantes duran 0,95 segundos; el registro existe, pero queda dentro de un diálogo del menú y muestra los últimos 12 textos. | Prompts 03/04 |
| A14 | P2 | C/H | El aprendizaje inicial es principalmente texto. No enseña de forma guiada las diferencias con Pokémon original. | Prompt 07 |
| A15 | P3 | C | No hay evidencia de accesibilidad completa del tablero para lectores de pantalla. Requiere una prueba específica. | Prompt 08 |

### A01/A07. El teclado pierde su punto de apoyo

**Reproducción nueva:** Inicio con foco en «Nueva partida» → Enter → Oak con foco `null`. Tras elegir inicial con Enter, el mapa también queda sin foco. En equipo, enfocar Bulbasaur → Enter: se selecciona correctamente, pero el control enfocado desaparece. En tienda, enfocar Poción → Enter: la bolsa pasa de 2 a 3 y el foco queda vacío. Al abrir PC ocurre lo mismo. «MT y equipo» sí restaura el foco de su pestaña.

`campaign.gd::_select_member`, `_roster_page` y `_event` desembocan en `_refresh`; `_render_travel` elimina y reconstruye controles con `_clear`. No se conserva una identidad de foco para todos esos recorridos. En combate, abrir habilidades mediante el botón lo oculta y deja el foco vacío; A conserva el tablero, y Tab llega al primer movimiento.

**Impacto:** el usuario necesita volver a orientarse y recorrer controles; no demuestra un bloqueo total, porque Tab puede recuperar navegación. Es especialmente costoso en compras y gestión repetidas.

**Mejora:** foco por identidad estable —miembro, artículo, movimiento, pestaña—, restauración después del refresco y alternativa vecina si desaparece. Conservar también desplazamiento del panel. Ningún cambio de foco, selección o página debe alterar el estado de campaña ni el RNG.

**Aceptación:** seleccionar, comprar tres veces mediante pulsaciones separadas y recorrer varias páginas del PC sin volver al principio, tocar el ratón ni ejecutar una segunda orden por arrastre de Enter. Los diálogos devuelven el foco a quien los abrió.

### A02. La reducción de ventana también reduce la lectura

**Dato nuevo:** con ventana 1024×720, el área lógica sigue siendo 1280×900; actor usa fuente 18 y objetivo 17. `window/stretch/mode="canvas_items"` reduce la composición al 80 %. `_layout_battle_hud` decide su variante compacta con `size.x < 1150`, condición que no se cumple en este caso. Una fuente 17 ocupa aproximadamente 13,6 píxeles físicos antes de considerar DPI del sistema. No se ha medido su legibilidad con personas.

La solución no es aumentar el zoom del tablero: eso agranda las casillas, no las fichas. Separar escala del texto/HUD y cámara, y probar una composición de lectura ampliada con paneles que se repliegan, no que se pisan. Propuesta inicial: texto/HUD 100/125/150 %, cursor mayor y alto contraste; estos valores son objetivos de diseño, no un estándar universal de escritorio.

**Aceptación:** en 1024×720 a 150 % de texto, consultar acción, PS/PT, objetivo y confirmación sin recorte ni desplazamiento horizontal. Puede existir una ficha desplegable: no es necesario mostrar todos los detalles simultáneamente. Probar además DPI 100/125/150/200 % en Windows y recuperación ante una combinación de ajustes incómoda.

### A03/A06/A08. El tablero tiene atajos, pero el control aún es parcial

Los manejadores de `laboratory.gd` e `isometric_board.gd` comparan directamente `KEY_*`. No hay acciones de juego configurables en `project.godot`. C, G, H y zoom funcionan cuando el tablero recibe entrada; esa disponibilidad depende del foco.

**Dato nuevo:** desde (5,10), flecha derecha lleva a (6,10), con desplazamiento proyectado de (+52,+31,2). Es un paso lógico hacia el sureste de la pantalla, **no un error de coordenadas**. Conviene explicarlo con brújula y ofrecer una alternativa configurable si las pruebas humanas la justifican. Una pulsación repetida marcada `echo=true` no mueve el cursor: mantener una tecla no recorre varias casillas en el sondeo.

Permitir reasignación, pan por pulsaciones y navegación entre unidades/objetivos. Dar repetición regulable únicamente a navegación y cámara; jamás a ataques, compras, consumibles o finalizar. Mantener la selección de casillas exacta con alturas y una señal grande del foco lógico. Clic derecho/Escape deben retroceder una capa, sin ordenar un básico inesperado ni deshacer un movimiento ya aceptado.

### A04. Elegir una orden no siempre significa querer ejecutarla

`_select_action` llama inmediatamente a `_select_tile(actor)` cuando el objetivo es propio. La ayuda lo explica, pero explorar el repertorio puede consumir acción/PT. Los ataques sin fuego amigo se aceptan directamente al seleccionar el objetivo; las flechas de orientación terminan el turno. Son decisiones actuales, no errores de cálculo.

Propongo dos preferencias: **Rápido**, que conserva ataque directo sobre un objetivo ya seleccionado y bien anunciado, y **Seguro**, que pide una aceptación final. En ambos, seleccionar una habilidad propia debe poder mostrar su efecto antes de gastar recursos. Confirmación adicional obligatoria para daño a aliados, autocoste letal y elección de final legendario excluyente. No añadir un diálogo a cada movimiento normal.

La interfaz debe distinguir «seleccionado», «previsualizado» y «orden aceptada». Mantener R como rectificación exclusiva del movimiento: atacar, usar apoyo o terminar lo bloquea. Cancelar una previsión no recupera una orden aceptada.

**Aceptación:** abrir habilidades, recorrerlas, seleccionar una mejora propia y cancelar no cambia revisión, PS, PT, estados, diario ni RNG. Confirmar produce exactamente una orden. Un clic para cerrar un menú no puede atravesarlo y activar la casilla del fondo.

### A05/A12/A13. Información rica, pero dispersa o breve

La previsión ya calcula lo importante. El siguiente paso es ordenarlo en dos capas:

1. **Lectura inmediata:** movimiento, objetivo, alcance válido, daño mínimo–máximo, precisión, riesgo a aliados y si el KO es garantizado o solo posible. Nunca presentar un crítico posible como daño garantizado.
2. **Detalle consultable:** STAB, tipos, frente/flanco/espalda, probabilidad crítica, habilidad, autocoste, empuje/acercamiento, atributos y duración en activaciones.

Los estados dibujados por `unit_indicators.gd` tienen abreviatura, signo y tooltip, pero no una navegación de detalle equivalente. Proponer una ficha con I/clic de inspección que permanezca abierta y permita consultar «Defensa +2; quedan 2 activaciones», así como explicar PT y las reglas adaptadas. En vista general, usar formas y contornos por equipo, dirección legible y señal del Pokémon activo, además del color.

El registro de combate ya existe. Recomiendo un historial accesible con actor/objetivo, acción, resultado real, fallos/inmunidad, estados y pasivas; pausable, con consulta al último evento y sin depender de los textos flotantes de 0,95 segundos. La duración de lectura y la velocidad visual deben configurarse independientemente de la IA.

Una vista de amenazas sería útil: muestra alcance legal y acciones que el enemigo podría ejecutar con información pública. No debe fingir que sabe qué decidirá la IA ni anticipar tiradas.

### A09. Las preferencias deben acompañar al jugador

**Dato nuevo:** tras desactivar sonido y animación, `muted=true` y `reduced_motion=true`; al crear una escena de campaña nueva, ambos vuelven a `false`. No hay persistencia de estas opciones en la implementación revisada.

Guardar ajustes locales independientes de la partida: controles, texto/HUD, contraste, cursor, confirmaciones y movimiento reducido. No meterlos en el diario determinista de campaña. Aplicarlos antes de mostrar la primera pantalla; restablecer valores por categoría con una salida recuperable. Ampliar volumen solo a buses/categorías que realmente existan; no inventar controles de voz si el juego carece de ella.

### A10/A11. La preparación del equipo no debería ser trabajo administrativo

La tienda actual divide ofertas a la izquierda y uso en el Pokémon a la derecha. Esa separación obliga a conservar mentalmente qué se compra y para quién. Seis Pokémon, niveles y muchos movimientos amplifican el coste.

**Propuesta:** elegir compañero una vez; comprar/usar con cantidad y un resumen de coste y resultado. Para Caramelo, nivel actual → solicitado → tope del gimnasio, bolsa disponible y unidades por comprar. No gastar dinero automáticamente al pulsar «Usar». Mostrar evoluciones/aprendizajes y recuperación de PS derivada del crecimiento. Revivir sigue siendo solo fuera de combate y al 50 %.

Las compras/uso por cantidad deben equivaler a una secuencia explícita de órdenes actuales, con resultado y diario verificables. No introducir una orden nueva en una edición publicada sin decidir compatibilidad. Si falla el guardado, parar y comunicar qué operaciones se aceptaron; no prometer atomicidad del conjunto si solo existe persistencia por orden.

En el PC: búsqueda por nombre, filtros de tipo/estado/rol y ordenación estable, conservando ID de instancia para duplicados. Un cambio gratuito no cura, no revive ni altera equipos. En movimientos: cuatro ranuras claras, básico fijo aparte y sustitución en un único recorrido revisable. Los filtros y la preselección son presentación; no reordenan la iniciativa ni el diario.

**Motivo cuantitativo previo:** las tres campañas automáticas victoriosas usaron 99, 129 y 95 caramelos. Esto motiva medir repetición, no prueba cuánto tarda un humano ni justifica abaratar nada.

## 4. Esquema de control propuesto

**Objetivo: ratón completo, teclado completo y uso mixto**, con los mismos resultados. Los botones siguen disponibles como apoyo visible; cada acción frecuente tiene una vía directa. Las siguientes asignaciones son una propuesta, no controles ya implementados.

| Intención | Ratón | Teclado propuesto | Regla de contexto |
| --- | --- | --- | --- |
| Recorrer casillas | Puntero | Flechas, reasignables | Solo con foco de tablero; brújula de ejes isométricos. |
| Mover | Clic izquierdo en destino válido | Enter en casilla válida | Movimiento directo. R solo rectifica antes de actuar. |
| Ver habilidades | Menú integrado | A | Abrir no gasta acción; foco inicial previsible. |
| Seleccionar movimiento | Clic en ranura | 1–5 | Básico en 1, cuatro movimientos en 2–5; sin ejecución propia al explorar. |
| Elegir objetivo | Puntero sobre unidad | Q/E anterior/siguiente válido | En targeting; orden estable, con nombre y previsión. No cambia de Pokémon activo. |
| Inspeccionar | Acción de inspección visible sobre selección | I | Ficha persistente; misma información que hover. |
| Confirmar | Clic en selección/confirmación | Enter | Solo el contexto superior recibe el evento. |
| Cancelar/volver | Derecho o control Volver | Escape | Una capa; no revierte ataques ni activa el fondo. |
| Orientar y terminar | F y selector integrado; clic de dirección | F, flechas, Enter | Flechas previsualizan dirección; Enter acepta. Evitar avanzar casillas para orientar. |
| Cámara libre | Botón central opcional y cruceta de pan por clic | Alt+flechas; modo cámara P como alternativa sin mantener modificador | En modo cámara, flechas desplazan vista y Escape vuelve al tablero. Sin movimiento de unidades ni conflicto con A/I. |
| Centrar/encuadrar | Controles Unidad/Combate/Mapa | C; atajos adicionales configurables | Sin consumir turno; seguimiento automático opcional. |
| Zoom | Rueda; +/− visibles | +/− | Zoom del mapa distinto de escala del texto. |
| Menús, pestañas y paneles | Clic | Tab/Mayús+Tab, flechas, Enter/Espacio | Tab recorre foco GUI; Q/E de objetivos no se activa aquí. |
| Cambiar de panel amplio | Clic en cabecera | F6/Mayús+F6 propuestos | Tablero, órdenes, inspección; tienda, equipo. Nunca saltar a controles ocultos. |
| Menú general | Menú visible | F1; Escape desde estado neutro, si se adopta | Al abrir, suspender avance rival; al cerrar, restaurar contexto. |

**Decisión recomendada para el primer perfil:** conservar A/R/F/C/G/H y 1–5; usar flechas para tablero y **Alt+flechas para pan**, con alternativa de «modo cámara» P activable sin mantener Alt. Un perfil WASD alternativo debe reasignar A de habilidades explícitamente. Alt+flechas deberá comprobarse en el ejecutable Windows y podrá sustituirse si el sistema lo intercepta.

No usar Tab a la vez para recorrer botones y objetivos. No hacer que el mero movimiento del ratón robe el foco a quien navega con teclado. Los campos de búsqueda/semilla consumen sus letras: escribir A/R/F o números nunca envía órdenes de batalla.

### Turno ideal, sin paneles obligatorios

Con ratón: previsualizar casilla → clic para moverse → 2/clic en habilidad → objetivo con previsión → aceptar según preferencia → orientar → terminar. Con teclado: flechas → Enter → 2 → Q/E → Enter → F → flecha → Enter. Las órdenes siguen disponibles en el menú integrado.

Tras gastar movimiento y acción, abrir automáticamente la orientación. Si queda movimiento después de actuar, ofrecerlo sin obligar a usarlo. Si el jugador termina con recursos disponibles, mostrar qué deja sin usar; no forzar un aviso repetitivo después de que haya elegido un modo rápido. Conservar la excepción de no rectificar tras actuar.

## 5. Accesibilidad visual, auditiva, motora y cognitiva

| Necesidad | Mejora concreta | Comprobación futura |
| --- | --- | --- |
| Baja visión | Texto escalable, ficha ampliada, cursor/casilla activa grandes, contraste configurable y mapa independiente. | Ventana mínima y DPI reales; todos los datos críticos sin recorte. |
| Distinción de colores | Forma/contorno para aliado, rival, activo, movimiento, ataque y amenaza; estados con texto y signo. | Capturas en gris y simulación cromática como apoyo, más revisión humana. |
| Precisión motora limitada | Selección tolerante y previsible, sin doble clic obligatorio; alternativas al arrastre; objetivos por lista. | Solo ratón sin botón central; teclado con una mano y teclas reasignadas. |
| Fatiga o pulsaciones involuntarias | Compras por cantidad, navegación con repetición opcional, órdenes irreversibles sin repetición automática. | Mantener Enter y soltar tras cambio de pantalla no compra/ataca dos veces. |
| Dificultades de memoria/atención | Intención visible, ayudas cortas, objetivos actuales, recapitulación del último evento y tutorial practicable. | Volver tras varios días y entender qué hacer sin consultar documentación externa. |
| Sensibilidad al movimiento | Persistir movimiento reducido, controlar seguimiento de cámara y duración visual. | Eventos igualmente comprensibles sin animación, desplazamientos o sonidos. |
| Audición | Conservar texto de fallo, inmunidad, crítico, pasiva y resultado; sonidos nunca como única señal. | Recorrido silenciado completo sin pérdida de información de decisión. |
| Ausencia de visión | Semántica de menús y representación textual/narrable del tablero, si el prototipo demuestra viabilidad. | Lector de pantalla real en el ejecutable; no basta con asignar nombres a botones. |

Los pares principales del tema son favorables: texto/panel **11,45:1**, secundario/panel **7,61:1**, texto/botón **9,47:1** y foco dorado/botón **7,44:1**. El borde normal/botón es **1,84:1**: revisar delimitación y estados en contexto, sin declarar un incumplimiento solo con ese par, porque el texto y otros indicios también identifican el control. Los colores calculados no resuelven el tamaño físico ni el solapamiento del texto sobre sprites.

Como referencias se han consultado [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/) para configuración y alternativas de entrada; [XAG 107](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107) para controles, y [XAG 112](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112) para navegación y foco. Las propuestas de esta sección son una adaptación al juego.

[WCAG 2.2](https://www.w3.org/TR/WCAG22/) aporta referencias útiles de contraste, teclado y señalización; su marco web no certifica este ejecutable nativo. No se trasladan tamaños CSS ni ARIA al tablero de Godot como si fueran requisitos equivalentes. La [documentación de foco de Godot](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html) y la API instalada son las referencias técnicas para implementarlo.

## 6. Jugabilidad: mejoras acordes con Pokémon y los RPG tácticos

Estas son hipótesis de diseño, no resultados de un estudio de diversión ni copias verificadas de las reglas de Fire Emblem, Final Fantasy Tactics o Triangle Strategy.

1. **Identidad antes de más botones.** Cada línea debería comunicar sus dos funciones mediante movimientos, alcance y movilidad: qué hace bien, qué necesita y cómo contrarrestarla. Mostrar los roles como orientación derivada del repertorio, sin un bonus oculto nuevo. Un atacante móvil debe expresar su identidad en acercamientos/flanqueos ya legales; un apoyo, en estados temporales y protección legible.
2. **Información de tablero antes de memoria de franquicia.** Mostrar resistencias, cobertura y daño esperado en el objetivo. Una persona puede conocer Pokémon y desconocer las adaptaciones de PT, parálisis, estados de tres activaciones, alturas o básico neutro.
3. **Preparación con una decisión por visita.** Resumir siguiente encuentro, límite de nivel y equipo disponible; conservar elección de MT, equipable y reparto de niveles. Facilitar la operación, sin seleccionar automáticamente lo óptimo ni comprar por el jugador.
4. **Mapas grandes con puntos de interés.** Primero medir rondas sin contacto, desplazamientos sin decisión y concentración de combates. Después probar corredores, alturas y posiciones que permitan dos aproximaciones. No agrandar mapas por defecto ni añadir amenazas invisibles para llenarlos. Activación/refuerzos deben ser previsibles mediante información pública.
5. **Variedad de objetivos en un experimento separado.** Probar un encuentro opcional de defender una zona, rescatar o alcanzar un punto, conservando al principio la alternativa de derrotar rivales. Requiere reglas, IA y versión propias; no introducirlo como una simple modificación de interfaz.
6. **Cierre de combate que prepare la siguiente decisión.** EXP, PS ganados, evolución, movimiento aprendido, captura y siguiente destino en una secuencia breve con detalle ampliable. No esconder una evolución entre texto de tienda ni obligar a recorrer celebraciones largas.
7. **Revisar el arranque después del acceso.** Los datos previos muestran diferencias fuertes entre iniciales para el bot: Bulbasaur supera Brock en 4/8 arranques; Charmander y Squirtle en 0/8. No equivale a que sean imposibles para una persona. Comparar primero comprensión del repertorio, curación y encuentro inicial, con semillas emparejadas; después decidir si hace falta balancear.

## 7. Secuencia de actualización recomendada

| Bloque propuesto | Resultado | Prompts | Dependencia |
| --- | --- | --- | --- |
| U1. Control fiable | Acciones reasignables, foco conservado, menú/diálogo sin filtraciones, pruebas de entrada real. | 01 | Primero. |
| U2. Turno integrado | Selección segura, objetivos, orientación directa, cámara por teclado y ratón sin arrastre obligatorio. | 02 | U1. |
| U3. Lectura accesible | Ajustes persistentes, escala, inspección y previsión con jerarquía clara. | 04 y después 03 | U1; integrar con U2. |
| U4. Preparación ágil | Cantidades de tienda, selección estable, PC filtrable y preparación clara de cuatro movimientos. | 05 y 06 | U1/U3. |
| U5. Aprender y comprobar | Tutorial, protocolo de prueba y evaluación humana de tres iniciales. | 07 y 09 | U2/U3; repetir sobre U4. |
| U6. Acceso sin visión | Prototipo acotado de menús/tablero con lector de pantalla y evaluación real. | 08 | Empezar la viabilidad técnica tras U1; no esperar al acabado final. |

Los bloques no son sprints autorizados ni estimaciones de días. Mantener una entrega revisable por bloque; no ejecutar todos los prompts al recibir solo uno.

## 8. Prueba humana propuesta y condiciones de salida

Primera ronda exploratoria: 6–8 participantes, combinando fans de Pokémon, jugadores de tácticos y personas nuevas en uno de ambos; incluir personas que utilicen teclado exclusivamente y, con su participación voluntaria, necesidades visuales o motoras relevantes. Es una muestra de detección cualitativa, no suficiente para estimar preferencias de toda la audiencia.

Realizar sesiones de 30–45 minutos con consentimiento para registrar errores/tiempos. No recoger diagnósticos ni datos personales innecesarios. Descansos y retirada libres. Si se prueba lector de pantalla, reclutar usuarios reales de esa tecnología y registrar la configuración empleada.

Tareas: empezar con Oak; mover/rectificar; comparar dos ataques y cancelar; atacar; orientar; consultar un estado temporal; jugar silenciado; comprar y usar curación/niveles; preparar cuatro movimientos; intercambiar un duplicado del PC; guardar, salir y continuar. Separar teclado, ratón y mixto. Usar guardados de prueba para un Pokémon con estado, tienda avanzada y PC grande, sin obligar a jugar horas para llegar a ellos.

| Métrica | Cómo registrarla | Objetivo propuesto, pendiente de medición |
| --- | --- | --- |
| Pérdidas de foco | Foco nulo/oculto tras cada interacción central. | 0 en escenarios automatizados. |
| Órdenes accidentales | Acción que el participante indica no haber querido aceptar. | 0 en pruebas de seguridad; investigar cada caso humano. |
| Recuperación de error | Pasos para cancelar selección o rectificar movimiento legal. | Cancelar una capa; rectificar mediante una orden, sin reiniciar. |
| Coste de preparación | Pulsaciones/clics y tiempo para comprar/usar 5 caramelos y curar dos miembros. | Reducir al menos 50 % de interacciones respecto al flujo actual medido; no es un resultado obtenido. |
| Autonomía | Ayudas del moderador para completar una tarea. | Recorrido central sin intervención; registrar dónde falla. |
| Comprensión | Explicar por qué cambió daño/precisión y cuándo caduca un estado. | Evaluación cualitativa por tarea, sin confundir acierto con diversión. |
| Ritmo | Duración por encuentro, rondas sin contacto y turnos sin elección significativa. | Comparar 16/24 con mismos iniciales/semillas y registrar divergencias. |
| Preferencia | Valoración breve y motivo: control, claridad, preparación, diversión. | Recoger razones y desacuerdos, sin forzar un único promedio. |

Para publicar una actualización de acceso: recorridos completos con teclado y ratón; guardados de ediciones anteriores preservados; inspección/cancelación sin RNG ni diario; preferencias persistentes; ventana mínima legible; prueba silenciada y sin movimiento; ejecutable offline comprobado. La salida técnica no permite afirmar «accesible para todo el mundo». Las pruebas humanas y de tecnologías de apoyo deben figurar como realizadas o pendientes, con sus límites.

## 9. Mapa del código para las siguientes actualizaciones

| Área | Archivos y puntos de entrada |
| --- | --- |
| Entrada y contexto de combate | `godot/ui/laboratory.gd`: `_unhandled_key_input`, `_select_action`, `_select_tile`, `_cancel`, `_select_finish`, `_commit`. |
| Tablero/cámara | `godot/ui/board.gd`; `godot/ui/isometric_board.gd`: `_gui_input`, `pick`, `track_turn`, `pan`, `change_zoom`. |
| Campaña y navegación | `godot/ui/campaign.gd`: `_event`, `_render_travel`, `_select_member`, `_roster_page`, `_shop_page`, `_layout_battle_hud`, `_title_options`. |
| Inicio, PC y señales | `godot/ui/title_screen.gd`, `roster_panel.gd`, `unit_indicators.gd`, `combat_feedback.gd`. |
| Reglas y persistencia | `godot/core/journey_run.gd`, `journey_store.gd`, `movement_revision.gd`; consultar sus motores heredados sin modificar contratos publicados. |
| Pruebas existentes | `godot/ui/qa_interface.gd`, `qa_journey.gd`, `qa_roster.gd`, `qa_scale.gd`; scripts reales `godot:qa:interface`, `godot:qa:interface:export`, `godot:qa:roster`, `godot:qa:scale`, `godot:qa:journey` y `godot:test:release`. |

Conservar recursos existentes y sus licencias; no hacen falta plugins nuevos para empezar. La viabilidad del acceso mediante lector de pantalla debe comprobarse sobre este motor y este ejecutable, antes de elegir una dependencia externa. Fuente web, motores/datos publicados y `CREDITS.md` raíz permanecen fuera de esta propuesta de auditoría.
