# Identidad Pokémon y escenarios de Kanto

Dirección solicitada el26 de octubre de2026, después de0.29.0. Documento de diseño: las propuestas siguientes todavía no están implementadas.

## Decisiones confirmadas

- El usuario considera correcto el balance actual. Se conserva como referencia; se retira el rebalanceo general de la siguiente fase. No retocar por defecto estadísticas, daño, precisión, EXP, dinero, caps, costes PT o duración de estados.
- Abandonar el sistema de dos roles predefinidos por línea evolutiva. La identidad debe surgir de los Pokémon, sus movimientos y sus interacciones reconocibles.
- Usar descripciones de Pokédex y usos competitivos como referencias para la identidad de los movimientos y de cada especie.
- Hacer las localizaciones de Kanto más reconocibles, con alturas intencionadas y obstáculos adecuados al lugar: árboles en Bosque Verde, por ejemplo.

El balance aceptado es una valoración del usuario; no convierte en realizadas las pruebas completas de campaña pendientes. Cambiar un mapa puede cambiar su dificultad aunque las cifras sean idénticas: se comprobarán recorridos, visibilidad, contacto entre equipos y alternativas tácticas.

## Movimientos e identidad

### Criterio de adaptación

1. Conservar el efecto reconocible del movimiento: qué hace, a quién afecta, cómo se representa y cuáles son sus límites.
2. Consultar la biología y comportamiento de la especie en la Pokédex para orientar animación, origen del ataque y presencia sobre el tablero. Una descripción narrativa no concede una pasiva nueva ni justifica efectos ilimitados.
3. Consultar estrategias competitivas con generación y formato identificados. Extraer decisiones reconocibles —preparar una mejora, dormir, desgastar, retirar trampas, proteger o presionar— sin copiar automáticamente estadísticas, EV, objetos o mecánicas de ese formato.
4. Traducir al tablero solamente lo necesario: área, trayectoria, alcance, zona o desplazamiento; comprobar inmunidades, fuego amigo, alturas y obstáculos con la misma previsión que usa la IA.
5. Registrar separadamente cambios visuales, aclaraciones de texto y cambios de comportamiento. Los primeros no necesitan una edición nueva; los últimos deben conservar el motor de las partidas publicadas.

Let’s Go Pikachu/Eevee combinado sigue siendo la base de aprendizaje vigente. La nueva dirección no autoriza importar todos los repertorios competitivos de otras generaciones. Cualquier excepción se propondrá por especie y movimiento, con su procedencia y una razón concreta. No recuperar automáticamente Demolición para Beedrill, Megaagotar para Butterfree ni Cola Férrea temprana para Pikachu: fueron sustituidos por la decisión posterior de usar LGPE.

### Ejemplos para revisión

Son orientaciones de diseño, no cambios aprobados de potencia, niveles o efectos.

| Pokémon o línea | Identidad reconocible | Traducción al tablero |
|---|---|---|
| Bulbasaur / Venusaur | Lianas, drenaje, polvos y resistencia | Mostrar el agarre de Látigo Cepa; distinguir claramente Drenadoras dirigidas de una zona de suelo; polvos con área visible. La familia puede combinar estas herramientas libremente. |
| Charmander / Charizard | Fuego, humo, garras y vuelo al evolucionar | Distinguir Ascuas de los chorros y abanicos de otras técnicas; humo visible y coherente con su penalización local. No dar vuelo a Charmander ni adelantar Lanzallamas por una etiqueta de rol. |
| Squirtle / Blastoise | Caparazón, burbujas y chorros de agua | Diferenciar abanico, disparo y protección. Anclar los disparos de Blastoise a sus cañones; la animación no duplica impactos ni daño. |
| Pikachu / Raichu | Electricidad, rapidez y parálisis | Dar lecturas distintas a un ataque eléctrico, un acercamiento y un estado dirigido. Conservar la adaptación vigente de parálisis y los niveles de aprendizaje. |
| Butterfree | Polvos, sueño, viento y preparación | Somnífero y otros polvos se reconocen por animación y área; Tornado muestra su corredor y disipación. El uso competitivo de Somnífero y Danza Aleteo sirve como referencia, sin añadir esta última automáticamente si no corresponde al repertorio vigente. |
| Beedrill | Aguijones, presión física y ataques punzantes | Distinguir Doble Ataque y los proyectiles de aguijones mediante impactos y trayectorias legibles. No otorgar críticos garantizados o movilidad gratuita por considerarlo un «asesino». |
| Onix | Cuerpo rocoso, constricción y relación con el subsuelo | Atadura y Lanzarrocas deben comunicar acciones diferentes. Su movimiento y animación pueden expresar peso y excavación; destruir el escenario o atravesar obstáculos sería una regla nueva, no un efecto visual implícito. |

### Cambios de interfaz propuestos

- Retirar los botones de rol y los contadores que clasifican al Pokémon como Artillero, Baluarte, etc.
- Mantener cuatro movimientos preparados y el básico neutro obligatorio; preparar fuera de combate sigue siendo gratuito.
- Conservar filtros por efectos reales: área, zona, empuje, atracción, movilidad, estados y apoyo. Son herramientas de consulta, no clases.
- Conservar potencia, precisión, PT, alcance, previsión, diagrama y próximos aprendizajes.
- Reorientar los consejos de MT a compatibilidad, efecto y herramientas que añade a la selección actual. No recomendar «completar un rol».
- Preservar metadatos históricos de roles cuando los necesite un motor antiguo para reproducir guardados, aunque dejen de exponerse en la interfaz actual.

Cada movimiento revisado tendrá una ficha breve con fuente, efecto actual, rasgo reconocible, representación propuesta y lista explícita de posibles cambios de reglas. La primera muestra cubrirá iniciales y capturas anteriores a Brock.

## Mapas reconocibles

### Qué limita la versión actual

El tablero ya admite isometría, altura0–2, terrenos y visión con desniveles. Los perfiles de movimiento distinguen suelo, vegetación, agua y vuelo. Hay ocho arenas de gimnasio y tres objetivos especiales definidos.

Las rutas posteriores reutilizan plantillas según bioma en `expedition_maps.gd`. El registro visual `visual_assets.gd` asigna el mismo arbusto genérico a pradera y bosque; el tablero utiliza una casilla sólida genérica para muchos obstáculos. Variar color o fondo no basta para expresar la localización.

### Dirección por localización

| Lugar | Rasgos visuales propuestos | Composición táctica |
|---|---|---|
| Ruta1 | Camino de tierra norte-sur, hierba lateral, vallas bajas y señales de Paleta/Ciudad Verde | Colinas suaves y una aproximación clara; poca obstrucción para presentar el combate. |
| Ruta2 | Transición de camino abierto a borde de bosque, árboles más próximos y desniveles reconocibles | Un paso central y un desvío lateral conectado; preparar la lectura del bosque. |
| Bosque Verde | Árboles grandes agrupados, senderos sinuosos, claros, maleza y pequeños taludes | Sendero principal, claro de enfrentamiento y dos accesos laterales conectados. Árboles interrumpen visión; maleza tiene el coste previsto; una terraza sirve de alternativa accesible. |
| Gimnasio de Brock | Interior de piedra, rocas, estatuas y plataforma del líder | Rutas claras entre grupos de rocas y una altura moderada; conservar referencias de contacto y despliegue. La presentación debe parecer un gimnasio de Plateada. |
| Monte Moon | Paredes de cueva, columnas, escalones de roca y referencias a fósiles | Pasos estrechos conectados con cámaras abiertas y terrazas; no bloquear la salida a equipos terrestres. |
| S.S. Anne | Cubierta de madera, barandillas, escaleras y elementos náuticos | Dos niveles y pasos identificables; las escaleras muestran los accesos reales. |
| Gimnasio de Misty | Piscinas, pasarelas, bordes de baldosa y plataforma del líder | El agua y los puentes organizan alternativas; ningún equipo terrestre queda sin acceso al objetivo. |
| Gimnasio de Surge | Contenedores, cableado y equipos eléctricos | Cobertura y pasillos con aspecto propio del gimnasio, sin introducir una fase de puzzle por defecto. |
| Gimnasio de Erika | Jardín interior, senderos y vegetación ornamental | Claros conectados y vegetación diferenciada; evitar que todo el suelo sea terreno lento. |
| Gimnasio de Koga | Biombos, pasillos y referencias de dojo | Obstáculos legibles y espacios para el humo existente. No ocultar paredes ni añadir penalizaciones por una niebla puramente decorativa. |
| Gimnasio de Sabrina | Salas de color y pares de transportadores reconocibles | Destinos de los portales señalizados; el tablero muestra su conexión antes de confirmar el movimiento. |
| Guarida Rocket | Suelo industrial, cajas, terminales y cambios de nivel | Integrar los objetivos existentes en la escenografía y mantener accesos alternativos. |
| Calle Victoria | Grandes terrazas de cueva, rampas y masas de roca | Elegir entre pasos conectados hacia las salidas del objetivo vigente. |

La forma, materiales y puntos de referencia deben permitir identificar una zona sin depender del nombre escrito. No se busca copiar casilla por casilla el mapa de exploración de Rojo: cada encuentro debe funcionar como un tablero táctico.

### Obstáculos con significado

| Elemento propuesto | Movimiento y visión previstos | Lectura visual |
|---|---|---|
| Árbol grande | Casilla sólida y obstáculo visual; no se atraviesa por ser volador sin una regla expresa | Tronco anclado a la casilla; copa separada visualmente. |
| Arbusto / maleza | Terreno transitable con el coste del perfil vigente; no equivale a una pared | Vegetación baja, suelo y casilla visibles. |
| Roca grande | Obstáculo sólido con volumen reconocible | Base clara y silueta distinta de una casilla de tierra elevada. |
| Tronco, caja o contenedor | Obstáculo sólido inicialmente; aspecto según localización | Huella del objeto visible. Destruir o empujar el objeto queda para una revisión posterior. |
| Agua | Usar los perfiles de desplazamiento vigentes | Orilla y puentes claramente separados. |
| Talud, rampa o escalera | Mostrar los cambios de altura y accesos legales | Cara vertical, peldaños y continuidad del suelo, sin escaleras decorativas que no se puedan usar. |
| Decoración menor | Sin bloqueo ni efecto táctico | Flores, hojas y detalles alejados de las señales de selección. |

Los datos deben separar apariencia, huella, bloqueo de movimiento, bloqueo/altura de visión, terreno y elevación. Un objeto puede ocupar varias casillas solo si su huella se identifica correctamente y las rutas se comprueban. No introducir clases nuevas por cada especie de árbol ni reemplazar todo el tablero por otro motor.

## Alturas y legibilidad

- Aprovechar primero los tres niveles existentes:0 suelo,1 terraza y2 posición superior. Diseñar mesetas continuas y accesos útiles, evitando desniveles arbitrarios en cada casilla.
- Conservar por defecto el coste y los límites de subida/bajada actuales. No añadir bonificaciones automáticas de daño, precisión o crítico por estar arriba.
- Mantener la diferencia vigente del vuelo respecto al desnivel, sin convertirlo en permiso universal para atravesar árboles, paredes o techos.
- Las posiciones elevadas deben tener una utilidad espacial y un acceso o respuesta; no crear refugios desde los que un enemigo sea inalcanzable.
- Ordenar los objetos por profundidad de su base. Atenuar copas o primer plano cuando oculten unidades, cursor, rutas o áreas, sin cambiar la colisión.
- Mantener visibles pies, base de equipo, PS, estados y casilla seleccionada. La transparencia debe ser de presentación; no modifica visión ni azar.
- Mantener escalas de texto, contraste, selección por teclado y lectura del terreno. El jugador debe poder consultar tipo de casilla, altura y transitabilidad.
- Conservar el dibujo en caché y el procesamiento cooperativo de amenazas/IA. Evitar reconstruir vegetación y terreno completo por cada movimiento del cursor.

## Secuencia de entregas propuesta

Esta secuencia sustituye la propuesta conversacional de comenzar con un rebalanceo o ampliar roles. Son sprints futuros; no están iniciados por este documento.

| Sprint | Alcance | Criterio de cierre |
|---|---|---|
|30 — Identidad Pokémon | Retirar la presentación de roles; revisar movimientos de la apertura, sus fuentes y animaciones; conservar herramientas de consulta | Selecciones de cuatro movimientos siguen funcionando; no hay cambios numéricos o de aprendizaje implícitos; guardados reproducibles. |
|31 — Bosque Verde como muestra | Recursos de árboles, maleza y taludes; mapa propio; profundidad, transparencia y selección | La zona se reconoce sin título; no se ocultan unidades ni quedan equipos terrestres bloqueados; rendimiento medido. |
|32 — Paleta–Brock | Extender la dirección a Ruta1, Ruta2 y gimnasio; alturas y obstáculos coherentes | Recorrido natural con los tres iniciales; contacto, duración y alternativas revisados respecto a la referencia aceptada. |
|33 — Kanto por tramos | Aplicar materiales, hitos y composiciones propios al resto de localizaciones | Cada tramo validado antes del siguiente; no sustituir de golpe toda la campaña por mapas sin probar. |
|34 — Recorrido y acabado final | Campaña completa, finales, guardados, logros, textos y paquete | Defectos registrados y corregidos; comprobaciones automatizadas y humanas distinguidas; publicación pública solo cuando se autorice. |

## Recursos y compatibilidad

Reutilizar sprites, efectos y arte local existente cuando encajen. Los nuevos recursos necesarios incluyen árboles con copa y tronco separables, maleza, troncos/rocas, caras de talud, rampas/escaleras y variantes propias de gimnasio. Seleccionar paquetes públicos compatibles con la perspectiva y paleta, con licencia, autores y commit/hash, antes de importarlos. El documento no afirma que se haya seleccionado o instalado un paquete nuevo. Godot y el tablero actual permiten abordar el trabajo sin exigir plugins o un port a3D.

Una mejora visual que conserva geometría y órdenes puede aplicarse a la presentación de guardados existentes. Nuevas geometrías, obstáculos físicos o efectos de movimientos necesitan edición de contenido/reglas reproducible: un combate guardado conserva su mapa y su motor; las actualizaciones se aceptan entre encuentros y con copia. Mapas, IA, previsión y amenazas deben consultar las mismas reglas.

## Referencias verificadas

- [Pokédex oficial de Onix](https://www.pokemon.com/us/pokedex/onix): relación con la excavación y cuerpo rocoso; referencia de identidad, no permiso para destruir el mapa.
- [Sitio oficial de Let’s Go](https://pokemonletsgo.pokemon.com/en-us/story/?cid=pin%3Asocial%3Aletsgo%3Ahairstyles): identifica los dos cañones de Blastoise normal al explicar su megaevolución. Se toma el rasgo visual, no se añaden megas.
- [Venusaur, análisis competitivo SV/ZU de Smogon](https://www.smogon.com/dex/sv/pokemon/venusaur/): ejemplo de uso de drenaje, Drenadoras y sostenimiento. No trasladar automáticamente su repertorio o formato.
- [Butterfree, análisis competitivo SS/AG de Smogon](https://www.smogon.com/dex/ss/pokemon/butterfree/): ejemplo de Somnífero, Danza Aleteo y preparación. Referencia identificada por generación y formato; no una propuesta de copiar sus reglas.

Verificado el26 de octubre de2026. Algunos accesos directos al sitio oficial devuelven únicamente un contenedor; las referencias anteriores cuentan con contenido recuperado. Ningún ejemplo de este documento se presenta como función añadida al ejecutable0.29.0.


## Desarrollo de cada localización

Las descripciones en prosa de los58 nodos actuales, las escenas de ciudad y la tienda se detallan en [DESIGN_MAPAS_KANTO.md](DESIGN_MAPAS_KANTO.md). Son propuestas de arte, geometría y legibilidad, todavía no implementadas.


## Implementación posterior autorizada0.30

El encargo posterior autoriza la implementación de esta dirección. Se retiran roles de la presentación, se conservan filtros/MT y cuatro técnicas libres, y se añaden anclajes visuales de familias iniciales y el doble origen de los cañones de Blastoise sin duplicar daño. Los211 movimientos conservan exactamente sus definiciones/aprendizajes y sus efectos espaciales publicados; no se han importado repertorios competitivos nuevos. Los58 lugares tienen diseños propios en ambos tamaños. La secuencia final es aves y después Mew/Mewtwo. Véase [entrega0.30](SPRINT_30_KANTO.md) para diferenciar implementación y pruebas de las propuestas futuras del documento.
