# Plan de desarrollo por sprints — Pokémon táctico roguelike

Fecha: 15 de octubre de 2026. Versión documental: 1.13. Sprints 0–12 completados para la web 0.12.0; sprint 13 aporta el laboratorio nativo Windows 0.13.0. Publicación aplazada por el usuario; pruebas con personas pendientes. La web conserva las reglas de la edición 14 y sus partidas anteriores.

Este documento conserva las decisiones del proyecto y organiza entregas pequeñas para construirlo con asistencia de IA. Cada sprint produce algo revisable y termina antes de comenzar el siguiente. Los sprints 0–12 corresponden al objetivo inicial de navegador. La siguiente etapa apunta a un ejecutable Windows offline y una campaña larga basada en Rojo; el detalle está en [PRODUCT.md](../PRODUCT.md#campaña-de-kanto--requisitos-confirmados) y la secuencia futura en la [sección 11](#11-siguiente-etapa-kanto-y-ejecutable). La viralidad es una aspiración, no un criterio garantizado de éxito.

**Autorización vigente:** después de documentar los inputs, el usuario indicó «pues empieza» para iniciar el sprint 13 de base Godot. No se interpreta como autorización para ejecutar toda la campaña 14–22 ni para publicar. La versión web permanece disponible.

## 1. Forma de trabajar

- Mantener **un solo sprint activo a la vez**, cerrando y subiendo cada bloque. En el encargo del 15 de octubre el usuario ha autorizado expresamente completar los sprints 7–12 en una misma petición.
- Al recibir «empieza el sprint X», implementar únicamente ese alcance y las correcciones necesarias para que funcione. Las funciones futuras permanecen en el backlog.
- Revisar las instrucciones, el estado de Git y los scripts reales antes de editar. Preservar cambios ajenos. No inventar comandos ni dar por ejecutadas comprobaciones.
- Antes de construir una utilidad o un recurso desde cero, comprobar si los candidatos de la sección 4 resuelven la necesidad con una adaptación pequeña.
- Cerrar cada sprint con una demostración local, pruebas proporcionadas al cambio y un resumen de lo implementado, comprobaciones y limitaciones. Registrar observaciones del jugador.
- Si la prueba revela un problema de diversión o claridad, corregirlo en el sprint actual o abrir un sprint de ajuste antes de añadir contenido.
- No aumentar automáticamente la concurrencia ni delegar trabajo por seguir este documento.
- No fijar fechas hasta conocer el ritmo real de las primeras entregas. Un sprint es una unidad de resultado, no necesariamente una semana.
- La publicación se trata en su propio sprint; este plan no ejecuta ni autoriza por sí mismo un despliegue.

## 2. Decisiones de la etapa web 0–12

Registro histórico y reglas de la implementación 0.12.0. Para trabajo futuro prevalecen las decisiones nuevas de PRODUCT.md: ejecutable offline, un inicial de Oak, campaña larga de Rojo, captura/tienda y Liga antes de legendarios. Documentar ese objetivo no cambia las partidas existentes.

| Área | Regla |
| --- | --- |
| Público | Fans de Pokémon y RPG tácticos; portfolio y diversión como prioridades |
| Referencias | Fire Emblem para terreno y composición; Triangle Strategy para acciones y habilidades; Slay the Spire para rutas y salas |
| Plataforma | Navegador, primero en local; vista superior y cuadrícula cuadrada |
| Control | Manual contra IA convencional del juego |
| Equipo | Tres Pokémon aleatorios al empezar; máximo seis, con sustitución |
| Iniciativa | Velocidad determina el orden; todos tienen una activación por ronda y después se recalcula la cola |
| Variación | Tirada de velocidad con variación porcentual del 5–10 % |
| Activación | Desplazamiento y una acción, en cualquier orden; atacar y después moverse es posible |
| Paso entre unidades | Se puede atravesar a los aliados al moverse, pero el destino debe estar libre; los enemigos bloquean el paso |
| Recursos de combate | Sistema de puntos tácticos inspirado en Triangle Strategy; PP individuales pendientes de evaluación |
| Posición | Frente, flancos y espalda afectan a probabilidades; previsión antes de confirmar |
| Orientación final | Al incorporar bonificaciones por flancos y espalda, un botón al cerrar el turno permite elegir hacia dónde mira el Pokémon |
| Información enemiga | Las intenciones se deducen; no se muestran como órdenes futuras |
| Unidades | Especies de Kanto con tipos dobles, estadísticas y tabla de tipos modernos |
| Identidad | Rol inicial fijo; ataque básico cuerpo a cuerpo o a distancia y habilidades inspiradas en Pokédex y movimientos |
| Terreno | Peso importante; desplazamiento diferenciado, áreas, empujes y efectos sobre casillas |
| Mapas | Colección de mapas según tramo; no generación procedural libre inicialmente |
| Victoria | Eliminar enemigos; una sola dificultad inicial |
| Progresión | Experiencia individual, niveles simplificados y evolución mediante objetos |
| Salud | PS conservados entre combates; curación mediante objetos fuera de combate |
| Derrota | Pokémon perdido para el resto de la partida; sin resurrección inicial |
| Objetos | Un equipado por Pokémon y consumibles fuera de combate |
| Reclutamiento | Salas específicas; unirlas con la tienda sigue siendo una opción para probar |
| Recorrido | Rutas con bifurcaciones y temáticas de gimnasios de Kanto |
| Finales | Dos alternativos: Articuno + Zapdos + Moltres juntos, o Mew + Mewtwo juntos |
| Legendarios | Exclusivos de jefes; excluidos del inicio y de todo reclutamiento |
| Presentación | Sprites tipo Mystery Dungeon; alcance visual inicial sencillo |
| Lanzamiento deseado | Web propia y Pokémon como requisito del proyecto |

Las habilidades tácticas son adaptaciones propias: conservar la identidad de Pokémon no exige copiar el sistema de combate de los juegos principales.

## 3. Valores provisionales y decisiones pendientes

Estos puntos son propuestas de arranque; no deben presentarse como decisiones expresas del usuario.

| Punto | Propuesta para probar | Momento de revisión |
| --- | --- | --- |
| Tamaño | Tablero inicial de 8×8 | Sprint 1 |
| Iniciativa | ±5 %, sorteado una vez por ronda; cola estable; empates aleatorios | Sprint 2 |
| Movimiento | Cuatro direcciones, un tramo continuo antes o después de actuar | Sprint 1–2 |
| Puntos tácticos | Dos iniciales, +1 por activación, máximo cinco; básico gratis | Sprint 3 |
| Contraataques | Sin contraataque universal inicial | Sprint 3 |
| Estados | Veneno, quemadura y parálisis; inicialmente se eliminan al acabar el combate | Sprint 3 y 5 |
| Equipo aleatorio | Tres especies distintas dentro de las seis disponibles, con defensa y ofensiva/control; implementado provisionalmente | Sprint 5 |
| Experiencia | Individual por participación y contribución, sin depender solo del último golpe | Sprint 7 |
| Evoluciones | Todas requieren objetos; sin evolución automática por nivel ni intercambios externos | Sprint 7 |
| Duración | Ruta de cinco combates y un final provisional en sprint 5; jefe posterior. Hipótesis de 20–30 minutos sin medir | Sprint 5–9 |
| Metaprogresión | No añadir aumentos permanentes de poder al principio; decidir tras probar la ruta | Después del sprint 9 |
| Idioma y dispositivos | Español y PC con ratón como objetivo inicial | Sprint 0 y 11 |

Las fórmulas de daño, precisión por ángulo y costes de terreno son provisionales. El historial de la edición 14 y el informe de balance describen su estado actual; la actualización documental no modifica parámetros. Sprint 5 restablece PT, protección y estados por encuentro; conserva PS y bajas. La recuperación del equipable al morir o sustituir fue confirmada e implementada en sprint 6. El coste de vida persistente debe probarse de nuevo al aumentar la longitud de la campaña.

## 4. Reutilización de repositorios públicos

Fuentes consultadas el 13 de octubre de 2026. En el sprint 0 se integraron plantilla Phaser, SpriteCollab, PokéAPI, Pixelify Sans y funciones de importación de PokéSurvivor; EasyStar se integra en el sprint 1, versión npm 0.4.4 fija. Versiones, archivos, autores y modificaciones están registrados en el proyecto. La licencia del código no cubre automáticamente los datos, imágenes o marcas de un repositorio.

| Recurso | Uso previsto y ahorro | Condiciones / fuente |
| --- | --- | --- |
| [Plantilla oficial Phaser + Vite + TypeScript](https://github.com/phaserjs/template-vite-ts) | Arranque, escenas, carga de recursos y compilación; evita preparar el proyecto desde cero | [MIT](https://github.com/phaserjs/template-vite-ts/blob/main/LICENSE); conservar avisos. Verificar versiones y scripts al adoptar; usar variantes sin telemetría |
| [Phaser](https://github.com/phaserjs/phaser) | Motor 2D, entrada, cámara, animaciones y sonido | [MIT](https://github.com/phaserjs/phaser/blob/master/LICENSE.md); elegir versión compatible con la plantilla y fijarla |
| [SpriteCollab](https://github.com/PMDCollab/SpriteCollab) | Sprites y retratos Pokémon; descargar únicamente las especies de cada entrega | [CC BY-NC 4.0](https://github.com/PMDCollab/SpriteCollab/blob/master/LICENSE.md); atribución por recurso, modificaciones indicadas y uso no comercial. Revisar procedencia y excepciones de cada archivo |
| [PokéAPI](https://github.com/PokeAPI/pokeapi) | Tipos, estadísticas, especies y textos; importar una selección a datos locales | Código del servicio [BSD-3-Clause](https://github.com/PokeAPI/pokeapi/blob/master/LICENSE.md). No extender esa licencia a toda la IP Pokémon. La [política de uso](https://pokeapi.co/docs/v2) pide caché local |
| [PokéSurvivor](https://github.com/JPTER78/pokesurvivor) | Evaluar importadores de datos, sprites y créditos; utilidades de animación, terreno y audio solo si encajan | Su [licencia](https://github.com/JPTER78/pokesurvivor/blob/main/LICENSE) distingue código MIT de contenido de terceros. Adaptar módulos pequeños; no trasladar el juego completo |
| [EasyStar.js](https://github.com/prettymuchbryce/easystarjs) | Búsqueda de caminos A* con costes de casillas; candidato para navegación táctica | [MIT](https://github.com/prettymuchbryce/easystarjs/blob/master/LICENSE). Comprobar ocupación, perfiles de movimiento y compatibilidad; no resuelve por sí solo todas las casillas alcanzables |
| [Pixelify Sans en Google Fonts](https://github.com/google/fonts/tree/main/ofl/pixelifysans) | Fuente local para títulos y UI de estilo pixel art | [SIL OFL 1.1](https://github.com/google/fonts/blob/main/ofl/pixelifysans/OFL.txt). Conservar licencia y comprobar legibilidad y caracteres españoles |

Prioridad: reutilizar plantilla, sprites y datos; evaluar las utilidades ya existentes antes de escribir importadores. Para terreno y audio, evaluar módulos MIT de PokéSurvivor; si no encajan, buscar un paquete público pequeño con licencia explícita y documentar la elección. No inventar un conjunto visual completo durante los sprints de combate.

Crear durante el sprint 0 un registro de terceros y, al integrar recursos, `CREDITS.md`, avisos de licencia y un manifiesto de procedencia. No clonar catálogos enteros ni descargar todos los Pokémon para una prueba de seis especies. Guardar recursos en el proyecto para que las partidas no dependan de consultar servicios externos.

El uso de recursos comunitarios y un aviso de proyecto fan no otorgan autorización sobre la IP Pokémon. Este riesgo de publicación ya fue comentado; el usuario mantiene Pokémon como requisito. La [posición de Pokémon Support](https://support.pokemon.com/hc/en-us/articles/360000634094-Can-I-use-Pok%C3%A9mon-images-or-materials) queda como referencia, sin tratar las licencias comunitarias como permiso del titular.

## 5. Base técnica propuesta

Phaser + TypeScript + Vite, partiendo de la plantilla oficial. Mantener las reglas de combate separadas de la representación para poder probar iniciativa, movimiento, tipos y persistencia sin animaciones. Especies, habilidades, objetos y mapas se definen mediante datos. Guardado local con versión de formato y semilla para reproducir errores.

No se necesita servidor de juego para la primera versión. Cuentas, nube, multijugador, clasificaciones, monetización, IA generativa durante la partida y una Pokédex completa quedan fuera del alcance inicial. Las futuras generaciones se añadirían después de validar Kanto.

## 6. Sprints y criterios de cierre

Sprints 0–12 completados técnicamente; publicación y pruebas humanas pendientes. Los criterios siguientes conservan el alcance histórico de cada entrega. Las comprobaciones ejecutadas figuran en los informes de cada sprint. Los sprints futuros se registran en la sección 11.

### Sprint 0 — Preparación y recursos mínimos

**Objetivo:** abrir una base reproducible en el navegador local.

- Inspeccionar entorno, instrucciones y scripts; adoptar la plantilla compatible y fijar dependencias.
- Preparar estructura de datos y reglas; registrar decisiones provisionales y procedencia de terceros.
- Importar datos y sprites mínimos de Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude. Reutilizar herramientas existentes si son compatibles.
- Mostrar una escena con las seis especies y acceso a créditos; documentar arranque y compilación reales.

**Cierre:** arranque desde instalación limpia y compilación correctos; recursos cargan localmente, sin consultas a PokéAPI durante el juego. Verificar licencias y alineación de sprites. Sin combate ni recorrido.

### Sprint 1 — Tablero y desplazamiento

**Depende de:** 0. **Objetivo:** mover unidades de forma comprensible.

- Tablero 8×8 con suelo y obstáculos, selección de unidad y casillas alcanzables.
- Trayectoria previa, costes de movimiento y ocupación; evaluar EasyStar antes de implementar navegación propia.
- Desplazamiento limitado y cancelación antes de confirmar; perfiles terrestres iniciales.

**Cierre:** no atravesar obstáculos, ocupar una unidad ni exceder el presupuesto; resolver destinos sin camino. Demostración manual y pruebas de reglas de movimiento. Sin daño ni IA.

### Sprint 2 — Rondas, iniciativa y combate básico

**Depende de:** 1. **Objetivo:** terminar un combate sencillo.

- Cola visible por velocidad con variación configurable; una activación por unidad y ronda.
- Desplazamiento + acción en ambos órdenes; ataque básico, PS y eliminación.
- Enemigos capaces de acercarse, atacar o esperar; victoria, derrota y reinicio.

**Cierre:** completar un 3 contra 3; no duplicar activaciones ni bloquear una ronda al morir una unidad. Misma semilla reproduce orden y resultados. Sin tipos, progresión ni economía.

### Sprint 3 — Identidades, tipos y habilidades

**Depende de:** 2. **Objetivo:** que la composición cambie las decisiones. Entrega técnica completada en 0.3.0; informe en [SPRINT_3.md](SPRINT_3.md). Prueba manual del usuario pendiente.

- POO confirmada por el usuario: clase común de Pokémon, especializaciones de especies y acciones polimórficas; tipos dobles como datos. Contrato en [ARCHITECTURE.md](ARCHITECTURE.md).
- Tabla moderna completa, tipos dobles, daño físico/especial y estadísticas importadas.
- Ataque básico y dos habilidades iniciales por especie; propuestas de control, ofensiva, defensa, movilidad y apoyo.
- Puntos tácticos y estados iniciales; costes y duraciones en datos.
- Previsión de daño, precisión y posibles estados sin consumir tiradas ni recursos por mirar la UI.

**Cierre:** probar las seis especies, resistencias, inmunidades y doble debilidad; impedir gasto insuficiente y ataques inválidos. El usuario compara al menos dos composiciones. Ajustar antes de ampliar especies.

### Sprint 4 — Posición y terreno táctico

**Depende de:** 3. **Objetivo:** que el tablero importe. Entrega técnica completada en 0.4.0; informe en [SPRINT_4.md](SPRINT_4.md). Valoración manual de estrategias y equilibrio pendiente.

- Precisión según frente, flanco y espalda; resolver diagonales con una regla explícita.
- Botón de orientación al finalizar cada turno: elegir una dirección cardinal antes de ceder la activación. La dirección elegida se conserva y determina el frente, los flancos y la espalda para ataques posteriores. Se incorpora junto a las bonificaciones por posición.
- Permitir que las rutas atraviesen aliados, manteniendo el destino libre y a los enemigos como obstáculos. Compartir la regla entre previsualización, confirmación e IA; conservar los costes del terreno.
- Agua, hierba y obstáculos; perfiles de movimiento con excepciones por especie cuando proceda.
- Ataques de área, empuje y un efecto de terreno; reglas de alcance y línea de visión.
- Mejorar decisiones enemigas con costes, alcance, afinidades y seguridad, sin mostrar intenciones.

**Cierre:** probar elección y persistencia de orientación al terminar el turno, flanqueo según esa orientación y paso a través de aliados sin terminar sobre otra unidad. Comprobar bloqueo por enemigos, ocupación tras empuje, bordes, casillas inaccesibles y aplicación de áreas sin duplicar daño. Un mapa permite varias estrategias viables. Sin alturas, clima global ni complejidad adicional necesaria para zonas futuras.

### Sprint 5 — Primera ruta y consecuencias persistentes

**Depende de:** 4. **Objetivo:** enlazar combates en una partida. Entrega técnica completada en 0.5.0; informe en [SPRINT_5.md](SPRINT_5.md). Ruta con seis encuentros; equilibrio aplazado y curación pendiente del sprint 6.

- Inicio con tres Pokémon aleatorios, todos no legendarios; semilla y variedad provisional de roles.
- Ruta corta con bifurcaciones, colección de mapas por tramo y temática de roca inicial.
- Conservar PS; retirar derrotados durante toda la partida y resolver pérdida de todo el equipo.
- Guardado local entre salas, continuación y pantalla de final; escenario final de prueba sin afirmar que representa los jefes definitivos.

**Cierre:** recorrer varios encuentros; recargar entre salas no restaura PS ni unidades perdidas. Tratar guardado corrupto o incompatible. La ruta se valida antes de añadir ocho zonas.

### Sprint 6 — Tienda, reclutamiento y objetos

**Depende de:** 5. **Objetivo:** decidir cómo invertir recursos y mantener el equipo. Entrega técnica completada en 0.6.0; informe en [SPRINT_6.md](SPRINT_6.md). Tienda/reclutamiento separados, seis aliados, objetos y guardado actualizado.

- Dinero, recompensas y tienda con consumibles curativos y unos pocos objetos equipables.
- Usar consumibles exclusivamente fuera de combate, sin revivir ni curar automáticamente.
- Sala de reclutamiento con tres candidatos no legendarios; incorporar hasta seis o sustituir con confirmación.
- Un objeto equipado por miembro; recuperación en la bolsa al sustituir o morir, confirmada por el usuario.

**Cierre:** recorrido compra → curación → reclutamiento → combate. Sin duplicaciones de dinero, objetos ni recompensas tras recargar; compras sin saldo bloqueadas. Evaluar si separar tienda y reclutamiento ofrece decisiones útiles.

### Sprint 7 — Experiencia y evoluciones

**Depende de:** 6. **Objetivo:** construir unidades dentro de la partida.

- Experiencia individual y niveles simplificados; mostrar contribución y progreso.
- Objetos evolutivos aplicables solo a miembros vivos y compatibles, sin dependencias de intercambios externos.
- Incorporar evoluciones seleccionadas de las familias iniciales, con recursos y créditos, sin ampliar toda Kanto.
- Evolución conserva identidad individual, experiencia y equipo; documentar ajuste de PS máximos y actuales, sin curación gratuita accidental.

**Cierre:** evolucionar mediante un objeto obtenido en la ruta; comprobar consumo único, compatibilidad y persistencia. La evolución cambia al menos una opción táctica. Probar que unidades derrotadas no reaparecen por este sistema.

### Sprint 8 — Final alternativo de las aves

**Depende de:** 7. **Objetivo:** encuentro contra Articuno, Zapdos y Moltres juntos.

- Escenario con sectores de hielo, electricidad y fuego; peligro y afinidades legibles.
- Kit pequeño y diferenciado para cada ave; todos respetan la iniciativa y reglas del tablero.
- Condición de victoria sobre los tres y resumen de partida; entrada mediante ruta de prueba.

**Cierre:** probar victoria y derrota con varias composiciones; ninguna posición de inicio causa daño inevitable sin oportunidad de actuar. Los tres siguen fuera de selección inicial, recompensas y reclutamiento.

### Sprint 9 — Final psíquico y elección de destino

**Depende de:** 8. **Objetivo:** segundo final contra Mew y Mewtwo juntos.

- Laboratorio con sector natural y obstáculos; movilidad de Mew y presión ofensiva de Mewtwo como hipótesis de diseño.
- Kit y comportamiento propios, sin añadir sistemas innecesarios para dos unidades.
- Bifurcación final identifica ambos destinos; escoger uno excluye el otro en esa partida.
- Guardar y restaurar destino; registrar victoria, derrota y equipo final.

**Cierre:** completar ambos finales en partidas distintas; guardado mantiene la elección y no concede doble recompensa. Mew y Mewtwo nunca son reclutables. Revisar ritmo y economía antes de ampliar el recorrido.

### Sprint 10 — Gimnasios de Kanto, en cuatro entregas independientes

**Depende de:** 9. **Objetivo:** ampliar contenido sin introducir las ocho zonas de golpe.

Cada bloque se ejecuta y cierra por separado. Incorporar inicialmente dos mapas por temática y un grupo reducido de enemigos; reutilizar sistemas ya existentes.

| Entrega | Temáticas | Foco táctico propuesto |
| --- | --- | --- |
| 10A | Roca y agua | Obstáculos, pasos estrechos y rutas acuáticas |
| 10B | Eléctrico y planta | Sectores peligrosos y control del movimiento |
| 10C | Veneno y psíquico | Desgaste y líneas de ataque |
| 10D | Fuego y tierra | Áreas peligrosas y reorganización del equipo |

Orden temático del recorrido completo: roca → agua → eléctrico → planta → veneno → psíquico → fuego → tierra → uno de los dos finales. Los jefes no dependen de elegir una temática concreta hasta que se diseñe esa relación. No implica incluir entrenadores, diálogos o combates de líder de gimnasio.

**Cierre de cada bloque:** jugar sus dos temáticas con la economía persistente; validar mapas, composición enemiga y nuevos créditos. Registrar duración y recursos; los ajustes de equilibrio esperan a completar las mecánicas. Si ocho zonas alargan demasiado la partida, probar un recorrido reducido antes de aumentar encuentros.

### Sprint 11 — Pruebas externas, equilibrio y portfolio

**Depende de:** 10D; se permite una prueba pequeña tras 9 sin adelantar toda esta entrega.

- Tutorial breve, claridad de controles, precisión de previsiones, mensajes de daño y registro de combate.
- Sonido y mejoras visuales mediante recursos reutilizables registrados; controles de volumen.
- Pruebas con otras personas cuando el usuario decida compartir la versión; recoger confusión, decisiones, duración y ganas de repetir.
- Corregir bloqueos y dominancias; preparar README, capturas, vídeo y explicación de la contribución propia frente a terceros e IA.

**Cierre:** recorridos completos en el navegador objetivo, guardado y reinicio verificados, sin bloqueos conocidos que impidan terminar. Créditos corresponden a recursos reales. Registrar feedback; no convertir una métrica de viralidad en promesa.

### Sprint 12 — Preparación y publicación en web propia

**Depende de:** 11 y decisión del usuario de publicar.

- Seleccionar alojamiento y dominio según requisitos y presupuesto reales; preparar compilación estática y procedimiento de despliegue.
- Aviso legal, créditos y privacidad acordes con el producto real. Sin textos de Firebase, cuentas o red copiados de otro juego si no existen aquí.
- Verificar HTTPS, rutas de recursos, actualización de guardados y carga desde una instalación nueva.
- Presentar la versión preparada y su destino antes de la publicación; desplegar cuando esté autorizado y verificar el sitio después.

**Cierre:** juego accesible en su URL, ambos finales funcionales, créditos visibles y posibilidad de volver a la compilación anterior. Documentar comprobaciones y límites. Las licencias de recursos no eliminan el riesgo ya identificado de usar Pokémon.

## 7. Hitos de revisión

| Al cerrar | Resultado | Decisión |
| --- | --- | --- |
| Sprint 2 | Combate sencillo completo | ¿Se entiende y se controla bien? |
| Sprint 4 | Combate táctico con identidad | ¿Posición, tipos y roles ofrecen decisiones? |
| Sprint 7 | Partida corta con construcción de equipo | ¿Curación, reclutamiento y progresión generan elecciones? |
| Sprint 9 | Dos finales alternativos | ¿Apetece repetir con otro equipo o destino? |
| Sprint 10D | Recorrido temático de Kanto | ¿La duración y el contenido sostienen el interés? |
| Sprint 11 | Versión candidata | ¿Está lista para que otros la jueguen? |

La secuencia es deliberadamente lineal. Si un hito no funciona, revisar el bloque correspondiente antes de pasar al siguiente. Solo ampliar especies cuando aporten un rol, una interacción o una necesidad concreta del contenido.

## 8. Registro para continuar entre sesiones

Actualizar esta tabla al cerrar una entrega. Las columnas se completan con hechos, no con expectativas.

| Sprint | Estado | Versión / commit | Comprobaciones ejecutadas | Feedback y próximo paso |
| --- | --- | --- | --- | --- |
| 0 | Completado técnicamente | 0.0.1; rama `codex/sprint-0` | Instalación limpia, tipos y build; 6 pruebas de catálogo; 33 hashes; 12 comprobaciones de navegador | Pendiente de feedback del usuario; siguiente: 1 |
| 1 | Completado técnicamente | 0.1.0; rama `codex/sprint-1` | 12 pruebas de datos/movimiento; tipos y build; 33 hashes; 18 comprobaciones de navegador | Probar el ensayo en local; siguiente: 2 |
| 2 | Completado técnicamente | 0.2.0; rama `codex/sprint-2` | 21 pruebas de reglas/datos; tipos y build; 33 hashes; 20 comprobaciones de combate y 18 de regresión | Probar combate 3 contra 3; siguiente: 3 |
| Ajuste UI de 2 | Completado | 0.2.1; misma rama | 21 pruebas de reglas/datos; tipos y build; 33 hashes; 22 comprobaciones de combate y HUD en desarrollo y producción | Referencia del usuario integrada; siguiente: 3 |
| 3 | Completado técnicamente | 0.3.0; rama `codex/sprint-3` | 35 pruebas; 324 relaciones de tipos y 35 hashes de recursos; tipos/build; 19 comprobaciones de navegador en desarrollo y producción | Probar dos composiciones y ajustar costes; siguiente: 4 |
| 4 | Completado técnicamente | 0.4.0; rama `codex/sprint-4` | 49 pruebas; 20 escenarios repetidos; tipos/build y 35 hashes; 19 comprobaciones de navegador en desarrollo y producción, 18 de ensayo | Bajas rápidas en 3v3; equilibrio aplazado por el usuario. Conservar parámetros y repertorio; revisar Lanzallamas como opción futura. Siguiente: 5 |
| 5 | Completado técnicamente | 0.5.0; rama `codex/sprint-5` | 57 pruebas; 100 rutas simuladas; tipos/build y 35 hashes; 18 comprobaciones de ruta en desarrollo y producción local, 19 de combate y 18 de ensayo | Probar continuidad y desgaste. Parámetros intactos; curación y economía en 6 |
| 6 | Completado técnicamente | 0.6.0; rama `codex/sprint-6` | 72 pruebas; tipos/build y 37 hashes; 18 comprobaciones de gestión en desarrollo y producción local, 19 de combate y 3 de ciclo de vida | Probar economía y composición. Equilibrio aplazado; siguiente: 7 |
| 7 | Completado técnicamente | 0.7.0; codex/sprint-7 | 76 pruebas; build/tipos; 78 hashes; 4 comprobaciones de navegador | EXP y evolución disponibles |
| 8–9 | Completados técnicamente | 0.8.0–0.9.0; ramas de entrega | 81 pruebas al cerrar 9; ambos finales y exclusión, build/tipos, recursos y navegador | Finales disponibles |
| 10A–10D | Completados técnicamente | 0.10.0–0.10.3; cuatro ramas | 90 pruebas al cerrar 10D; 16 mapas y continuidad; build/tipos y navegador por bloque | Ocho zonas de Kanto |
| 11 | Completado técnicamente; pruebas humanas pendientes | 0.11.0; codex/sprint-11 | 93 pruebas; dos campañas completas por UI, regresiones, capturas y vídeo | Feedback externo por organizar cuando el creador comparta |
| 12 | Preparación completada; publicación aplazada | 0.12.0; codex/sprint-12 | Build, integridad, raíz/subcarpeta, instalación limpia, guardado y ambos finales en producción local | Sin alojamiento/dominio ni URL pública por decisión del usuario |

Entrega 8: completada técnicamente, versión 0.8.0, rama codex/sprint-8. 79 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_8.md).

Entrega 9: completada técnicamente, versión 0.9.0, rama codex/sprint-9. 81 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_9.md).

Entrega 10A: completada técnicamente, versión 0.10.0, rama codex/sprint-10A. 84 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_10A.md).

Entrega 10B: completada técnicamente, versión 0.10.1, rama codex/sprint-10B. 86 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_10B.md).

Entrega 10C: completada técnicamente, versión 0.10.2, rama codex/sprint-10C. 88 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_10C.md).

Entrega 10D: completada técnicamente, versión 0.10.3, rama codex/sprint-10D. 90 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_10D.md).

Entrega 11: completada técnicamente, versión 0.11.0, rama codex/sprint-11. 93 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_11.md).

Entrega 12: completada técnicamente, versión 0.12.0, rama codex/sprint-12. 93 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_12.md).

Plantilla de cierre: objetivo entregado; archivos o módulos modificados; recursos reutilizados y procedencia; comprobaciones ejecutadas y resultados; prueba manual disponible; feedback; pendientes; actualización de valores provisionales.

Sprints 13–15 entregados técnicamente. La muestra Paleta–Brock y la comparación de escala esperan valoración del creador; siguiente bloque: 16, equipo/progresión y PC si se aprueba.

## 9. Historial de entregas

Entrega documental inicial: plan y fuentes, sin implementación. La primera consulta de Git falló; durante el sprint 0 se identificó un repositorio en la carpeta personal y se creó uno independiente para el proyecto sin modificar el anterior.

Sprint 0: proyecto en `outputs/pokemon-tactics`, campamento de seis especies, recursos locales con atribución y verificaciones completas. Consultar [README](../README.md), [cierre](SPRINT_0.md) y [créditos](../CREDITS.md). La publicación web del juego sigue pendiente; el código se entrega mediante GitHub.


## 10. Entregas en GitHub

Repositorio: https://github.com/GregorioRuiz98/pokemon-tactics (privado inicialmente). Al terminar cada sprint: actualizar este plan y su informe, ejecutar las comprobaciones pertinentes, revisar el diff, crear un commit, subirlo y verificar el SHA remoto. El usuario ha autorizado este flujo para los siguientes sprints. Consultar AGENTS.md para los detalles. Este archivo es el plan canónico del proyecto.

Sprint 1: tablero 8×8 con obstáculos, maleza, seis unidades fijas, alcance y trayectoria, confirmación/cancelación, presupuestos y orientación. Navegación reutilizada de EasyStar. El campamento continúa en `?view=camp`. Informe: [SPRINT_1.md](SPRINT_1.md). Rama de entrega: `codex/sprint-1`.

Sprint 2: combate 3 contra 3 con cola por velocidad, semilla reproducible, desplazamiento y ataque en ambos órdenes, IA, PS, bajas y resultados. El ensayo sigue en `?view=training`. Informe: [SPRINT_2.md](SPRINT_2.md). Rama de entrega: `codex/sprint-2`.

14 de octubre: ajuste de interfaz del sprint 2, versión 0.2.1. HUD integrado en el escenario, fichas/retratos en esquinas, previsión y órdenes centrales y menú de opciones secundario. Referencia proporcionada por el usuario; reglas de combate conservadas. Informe: [SPRINT_2_HUD.md](SPRINT_2_HUD.md).

Sprint 3: POO de Pokémon y acciones, tabla moderna reutilizada de PokéAPI, daño físico/especial, básicos y dos habilidades por especie, PT, estados y dos composiciones fijas para comparar. Informe: [SPRINT_3.md](SPRINT_3.md). Rama de entrega: `codex/sprint-3`.

Sprint 4: orientación final con confirmación, precisión por ángulo, rutas entre aliados, perfiles terrestres/de hierba/acuáticos/voladores, mapa Charca, áreas con daño a aliados, empuje y ascuas. Informe: [SPRINT_4.md](SPRINT_4.md). Rama de entrega: `codex/sprint-4`.

## Alcance final del encargo conjunto

El usuario autorizó el 15 de octubre completar los sprints restantes en una sesión, conservando hitos separados. La restricción original de una entrega por petición queda sustituida en este encargo. No se ha delegado ni enviado mensajes externos. Posteriormente eligió preparar la versión y publicar después: el cierre 12 cubre compilación, paquete, textos, guía y reversión; no despliegue real, HTTPS público ni dominio. Las pruebas externas del sprint 11 esperan que el creador comparta la demo.

## 11. Siguiente etapa: Kanto y ejecutable

Registro del 15 de octubre de 2026. El usuario pidió primero documentar sin iniciar Godot y posteriormente indicó «pues empieza»: sprint 13 de base técnica autorizado y entregado. [PRODUCT.md](../PRODUCT.md) es la fuente única de requisitos K01–K13, ideas P01–P17, conflictos y decisiones pendientes. Los sprints restantes se conservan como propuesta.

Cambios de objetivo confirmados: campaña larga con guardado y bajas definitivas; un inicial de Oak; historia y encuentros de Rojo original; mapas grandes; captura aleatoria local tras victoria y tienda con Caramelos Raros/entrenamiento; Liga y rival como cierre, dos desafíos legendarios alternativos después; ejecutable Windows offline. La reserva del PC, cuatro movimientos, vitaminas, objetivos nuevos y tamaños concretos se registran como propuestas cuyo detalle debe cerrarse antes de implementarlo.

| Sprint futuro | Alcance propuesto | Criterio de cierre previsto | Estado |
| --- | --- | --- | --- |
| 13 — Base técnica y paridad | Godot/plantillas verificados, laboratorio 3v3 con recursos existentes, POO, guardado y exportación Windows; contraste con el motor web | 16 combates/506 órdenes y 25 escenarios coinciden; cuatro batallas por controles en fuente y ejecutable; guardados web intactos | Completado 0.13.0; [informe](SPRINT_13.md) |
| 14 — Paleta hasta Brock | Inicial de Oak, Ruta 1, Ruta 2, Bosque Verde y Brock; captura, tienda, evolución/entrenamiento mínimos | Ciclo completo con guardado y premios únicos; ver informe | Completado 0.14.0; pruebas humanas/balance pendientes; [informe](SPRINT_14.md) |
| 15 — Escala y ritmo táctico | Evaluar isometría/alturas y comparar mapas amplios, cámara, grupos enemigos y objetivos puntuales propuestos | Comparación16/24 y reglas compartidas probadas; contraste jugando pendiente del creador | Entrega técnica0.15.0; isometría/alturas/cámara/vigía, métricas y QA. [Informe](SPRINT_15.md); valoración humana pendiente |
| 16 — Equipo y progresión | Gestionar capturas, PC/reserva aprobada, movimientos/MT y evolución acordada | Comprobar máximo desplegado, bajas, intercambio, límites y guardado | Completado0.16.0: seis plazas y PC sin límite, envío automático, cambios sin curación, derrota pese a reservas y diario12; progresión adelantada0.14.1–0.14.9. Nuevas zonas/tablas en17. [Informe](SPRINT_16.md) |
| 17 — Celeste y Carmín | Monte Moon, rutas del tramo, Bill, Misty, S. S. Anne, Lt. Surge y rival | Encuentros y premios trazables a Rojo; tramo completo desde una partida continuada | Completado0.17.0;18 encuentros hastaSurge, continuación desde12 y recursos Kanto. [Informe](SPRINT_17.md) |
| 18 — Lavanda, Azulona y Team Rocket | Túnel Roca, conexiones, Erika, guarida y Torre Pokémon; hitos y desvíos según grafo acordado | Hitos habilitan sus destinos sin saltos accidentales; gacha local separado del equipo de entrenadores | Completado0.18.0;28 encuentros, Scope/Fuji, transición13→14 y UI desplazable. [Informe](SPRINT_18.md) |
| 19 — Fucsia, Azafrán y sur de Kanto | Ramas hacia Fucsia, Safari/Silph, Koga/Sabrina, mar, Canela/Blaine y regreso a Giovanni; dividir por tramo si excede una entrega revisable | Cada tramo con prueba de continuidad, equipos temáticos y guardado; no prometer un orden único donde hay alternativas | Completado0.19.0; 48 lugares en recorrido probado, continuidad y ejecutable offline. [Informe](SPRINT_19.md) |
| 20 — Liga y rival | Acceso por rutas 22–23/Calle Victoria, Alto Mando, rival y cierre principal | Campaña completa desde el inicio; reglas de curación y continuidad entre miembros de la Liga explícitas | Completado0.20.0; 56 lugares en recorrido probado, continuidad y ejecutable offline. [Informe](SPRINT_20.md) |
| 21 — Postgame legendario | Tras la Liga, desafíos alternativos de tres aves o Mew/Mewtwo; elección y cierre según regla acordada | Legendarios nunca capturables; desbloqueo y exclusión de destinos comprobados, con escenarios temáticos | Completado0.21.0; 55 lugares en recorrido probado, continuidad y ejecutable offline. [Informe](SPRINT_21.md) |
| 22 — Balance y distribución | Nuevas simulaciones con un inicial/economía de captura, pruebas humanas y paquete Windows | Guardado, recursos, créditos e integridad comprobados; jugar sin conexión y sin Godot instalado; publicar solo cuando el usuario lo autorice | Entrega técnica0.22.0:29 simulaciones, guardados y paquete Windows comprobados. Pruebas humanas/publicación pendientes. [Informe](SPRINT_22.md) |

Dependencias: 13 precede a la muestra 14; la muestra se prueba antes de ampliar contenido. Los sistemas mínimos de captura/tienda necesarios para 14 no esperan a sus ampliaciones de 16. La división anterior es propuesta, no una orden para ejecutar toda la tabla. No se fijan fechas ni duración de campaña sin mediciones humanas.

Antes de empezar cada bloque, cerrar únicamente las decisiones que lo afectan: premio por combate frente a captura única por ubicación; reservas y derrota; caramelos, evolución y entrenamiento; movimientos; acceso a rutas/mazmorras; compatibilidad de guardados. No resolver silenciosamente esos conflictos usando las antiguas reglas web.

El informe de balance de la web se conserva como evidencia previa. Sus cifras no representan el nuevo recorrido ni autorizan rebajar daño, cambiar kits o alterar precios durante esta entrega. Tras portar las reglas y añadir la campaña, repetir pruebas con semillas comparables y partidas humanas.

Entrega documental anterior: inputs registrados en PRODUCT.md, este plan, README.md y AGENTS.md, sin iniciar el port. Entrega actual 13: laboratorio Godot independiente y herramientas de comprobación/exportación. No se ha implementado la campaña larga ni aplicado propuestas de balance.

## Revisión del HUD nativo — 16 de octubre de 2026

Solicitud adicional del usuario: integrar la interfaz en el juego y reducir clics. Entrega 0.13.1 en codex/sprint-13-ui: tablero con órdenes directas, previsión al pasar el cursor y franja inferior compacta; orientación con un clic y confirmación solo por riesgo aliado. No inicia el sprint 14 ni cambia balance, datos, reglas o guardados. [Informe y comprobaciones](SPRINT_13_UI.md).


## Menú dentro de la escena — 0.13.2

16 de octubre: el usuario concreta su referencia. Menú vertical flotante a la derecha en turnos aliados, movimiento directo sin botón, rectificación exclusiva del movimiento antes de actuar y retratos PMD en esquinas. La acción realizada antes del movimiento también impide rectificar. Implementación y prueba en [SPRINT_13_CONTEXT_MENU.md](SPRINT_13_CONTEXT_MENU.md).

Isometría y alturas se posponen expresamente a otro sprint. Añadir su evaluación al bloque de escala/mapas (15), antes de ampliar escenarios definitivos; no forman parte de 0.13.2. En aquella revisión la campaña 14 seguía pendiente. No hubo cambio de balance ni de contratos de guardado.


## Sprint 14 — Paleta hasta Brock, 0.14.0

Muestra nativa entregada en codex/sprint-14. Cuatro encuentros, tres iniciales, 24 especies locales, capturas con pesos de Rojo, tienda y evolución/entrenamiento mínimos. Brock concede medalla/dinero/captura del bosque. Caramelo por etapa sin nivel y +5/dos entrenamientos confirmados por el usuario. Duplicados permitidos provisionalmente; no se necesita PC para un máximo de cinco miembros.

Guardado propio kanto/1 y laboratorio conservado. Tableros 12×10; mapas grandes, cámara, isometría y alturas quedan para evaluar en 15. EXP/progresión completa en 16. Rival inicial, Ruta 22 y entrenadores secundarios no implementados; acontecimientos de paquete/Pokédex comprimidos en texto. Informe, pruebas y límites en [SPRINT_14.md](SPRINT_14.md). No iniciar automáticamente el siguiente bloque ni publicar.


## Revisión 0.14.1 — niveles, roles y fallos

Encargo posterior del usuario: crecimiento por nivel, dos roles de movimientos por línea, dinero para caramelos/otros aspectos y señales visuales/sonoras de fallo. Confirma cuatro movimientos + básico neutro y Caramelo sujeto a nivel. Entrega en codex/sprint-14-progression, con edición2 y continuación clásica1 sin conversión de batallas. [Reglas y propuestas](DESIGN_LEVELS_ROLES.md) · [Comprobaciones](SPRINT_14_PROGRESSION.md).

Adelanta sistemas mínimos de 16; 15 sigue pendiente. No equivale a completar PC, MT, equipables, pasivas, mapas amplios, alturas/isometría ni toda Kanto. Los roles se combinan libremente, no son profesiones bloqueadas. Las recomendaciones nuevas están separadas de las reglas aplicadas.


## Revisión0.14.2 — tienda y Pokémon insignia

Petición del16 de octubre completada como ampliación del14, adelantando MT/equipables mínimos de16. Brock entrega Onix14 en vez de captura del bosque; tres ofertas distintas con compras individuales y rerolls25,50,75… ₽ por visita. Seis MT, cuatro equipables y cobertura accesible para Charmander. Edición3 conserva1/2 y laboratorio. [Informe y límites](SPRINT_14_SHOP.md).

El15 sigue pendiente: escala/cámara, evaluación de isometría/alturas. Quedan PC y equipo completo, más especies/contenido de Kanto, pasivas, Liga/legendarios y balance con pruebas humanas. La tienda nueva no equivale a completar16 ni arreglar todo el balance. No publicar hasta indicación del usuario.


## Revisión0.14.3 — niveles comprables y evolución automática

Petición del16 de octubre: Caramelo25 ₽ por un nivel, evolución automática en sus umbrales con EXP o Caramelo; Beedrill/Demolición, Butterfree/Megaagotar al10 y Pikachu/Cola Férrea al7. El usuario confirma las adaptaciones Pikachu20/Graveler36. Edición4 conserva reglas1/2/3 y laboratorio. [Informe y comprobaciones](SPRINT_14_GROWTH.md).

Amplía progresión mínima de16; no completa PC ni mapas/cámara/isometría de15, contenido de Kanto o balance. Publicación sigue pendiente por decisión del usuario.

## Revisión0.14.4 — legibilidad, indicadores y Let’s Go

Petición del16 de octubre: Atkinson Hyperlegible, indicadores de estados/etapas sobre unidades y en ambas fichas, encuentros y movimientos de Let’s Go. El usuario combina las dos ediciones y retira las excepciones anteriores.32 especies/12 líneas/104 movimientos, siete MT compatibles, Piedra Hoja para nuevas líneas; pesos de aparición y efectos tácticos explícitamente adaptados. Edición5 preserva1–4 y laboratorio. [Informe y comprobaciones](SPRINT_14_LETSGO.md).

No inicia15 ni completa Kanto. Restan mapas/cámara/isometría/alturas, PC, pasivas, historia/Liga/legendarios y balance humano. La nueva pool y aprendizaje requieren revisar el arranque, especialmente Squirtle. Preparación local; publicación pendiente.

## Revisión0.14.5 — orientación y estados temporales

Precisión sin penalización direccional; frente usa mitad baja del daño, costado alta, espalda máximo y+1 crítico. Críticos, acercamientos y empujes mediante movimientos del catálogo LGPE. Usuario confirma atributos/estados3 activaciones; parálisis afecta solo movimiento, mejoras más caras y marcadores+1/+2. Edición6 conserva1–5 y laboratorio. [Reglas, prototipos y comprobaciones](SPRINT_14_TACTICS.md).

Amplía mecánicas del14, sin iniciar15 ni modificar el balance general por otro motivo. Siguen pendientes escala/cámara/isometría/alturas, PC, resto de Kanto y balance humano de los nuevos prototipos. Publicación pendiente por decisión del usuario.

## Revisión0.14.6 — PS al subir de nivel

Ajuste puntual del14: edición7 suma a los PS actuales el aumento de PS máximos por EXP o Caramelo, incluida la evolución automática. No revive bajas. Tienda/recibo muestran la regla. Reglas y guardados1–6 conservados; no inicia15. [Comprobaciones y entrega](SPRINT_14_LEVEL_HP.md).

## Revisión0.14.7 — límite por gimnasio

Edición8 limita EXP y Caramelos al nivel del insignia del próximo líder pendiente: Brock/Onix14. No acumular EXP al tope ni gastar Caramelo bloqueado; PS por subida conservados. Al vencer, cap del siguiente gimnasio cuando exista; muestra sigue acabando en Brock con14. Reglas/guardados1–7 conservados. [Informe y comprobaciones](SPRINT_14_GYM_CAPS.md). No inicia15 ni publica.

## Revisión0.14.8 — Revivir en tienda

Edición9 añade Revivir150 ₽ fuera de combate, recuperando un debilitado con50% de PS máximos, sin cambiar progreso ni duplicar equipable. Todo el equipo KO sigue siendo derrota. Topes por gimnasio/PS por nivel y partidas1–8 conservados. [Informe y comprobaciones](SPRINT_14_REVIVE.md). No inicia15 ni publica.

## Revisión0.14.9 — naturalezas y habilidades antes del15

Bloque14.9A/B solicitado y reunido en edición10:25 naturalezas,21 mentas100 ₽ con vista previa,13 pasivas activas y Cápsula Habilidad150 ₽ entre opciones normales. Clorofila/Fuga esperan clima/huida; ocultas/Parche quedan para ampliación posterior. IV15/EV0 y la muestra hasta Brock conservados; rasgos persistentes, topes y Revivir vigentes. [Informe y comprobaciones](SPRINT_14_TRAITS.md). El siguiente bloque sigue siendo15, mapas/cámara/evaluación de isometría y alturas; no se inicia automáticamente.


## Sprint15 — escala e isometría, 0.15.0

Edición11: mapas16×16 o24×24 seleccionables antes del primer combate, cámara/zoom/minimapa, alturas0–2 y movimiento/alcance/visión compartidos con IA. Vigía visible en bosque con activación a próxima cola y límite ronda3. Se mantienen cuatro encuentros y objetivo eliminar. Dos tamaños con despliegue comparable, sin obligar a caminar más. Reglas1–10 y laboratorio conservados; nueva campaña para11. [Entrega, métricas y comprobaciones](SPRINT_15.md). Arte de terreno provisional; ritmo/diversión/tamaño final esperan prueba del creador. El siguiente bloque es16, no iniciado.


## Revisión de vista del15 — 0.15.1

El usuario considera rara/confusa la primera presentación. Se revisan proyección, cámara estable/encuadre de combate, alturas, bases de unidades, sprites/hit-test, minimapa y guías opcionales. Misma edición11, mapas/reglas/guardados conservados; partidas0.15.0 continúan directamente. [Informe y capturas](SPRINT_15_VIEW.md). No inicia16 ni resuelve el arte final o balance.


Encargo19 de octubre: «continua con todo» autoriza cerrar17–22 en secuencia, con entregas/push separados y sin publicación pública.

- Revisión UI0.22.1, rama codex/sprint-22-ui: Inicio nativo (sin autoload/escena adicional), pausa al volver, Continuar frío/caliente y cancelación de Oak preservada. Tienda por categorías/continuar fijo, retratos/barras de PS, fichas y tema revisados. Mismo motor18/combate17; estado completo de ambos finales idéntico0.22.0. UI fuente/.exe58, aves898 y origen510; regresión PC540/escala980,65 advertencias antiguas/0nuevas. QA aislada en work/qa-sprint-22-ui; paquete0.22.1. Sin plugins/activos nuevos ni publicación. Ver docs/SPRINT_22_UI.md.

## Mejoras posteriores a la auditoría · controles 0.22.2

Prompt 01 aplicado: acciones reasignables y persistentes, conflictos revisables, foco por identidad y desplazamiento conservados en equipo/tienda/PC, navegación de paneles y protección contra órdenes repetidas. Misma campaña18/combate17 y guardados; sin rebalanceo. [Entrega y comprobaciones](SPRINT_22_CONTROLS.md). El siguiente bloque es prompt 02, turno contextual; prompts 02–09 pendientes. Publicación pública aplazada.

## Turno contextual0.22.3

Prompt02 aplicado: selección de habilidades sin ejecución, objetivos Q/E, modos Rápido/Seguro, orientación flechas/Enter y cámara por cruceta/Alt+flechas/P. Reglas18/17 y guardados conservados. [Entrega y evidencia](SPRINT_22_CONTEXT.md). Siguiente: prompt03, inspección persistente;03–09 pendientes. Sin publicación pública.


## Cierre de mejoras0.22.10

El encargo «hazlo todo» del20 de octubre completa técnicamente prompts03–09 con commits separados en codex/accessibility-complete. Ver docs/SPRINT_22_ACCESSIBILITY_COMPLETE.md (desde godot: ../docs/). Inspección, preferencias, cantidades, PC/biblioteca, práctica y acceso textual; motor18/17 y datos/snapshots intactos.09 prepara kit humano sin participantes; lector audible/usuario y DPI físicos pendientes. No delegación automática, publicación ni balance nuevos.


## Rendimiento0.22.11

Solicitud21 de octubre: corregir ralentizaciones. UI/representación solamente; campaña18/combate17, core/data/snapshots y guardados conservados. Tema con escrituras condicionales, previsión por contexto del cursor, semántica agrupada y terreno/minimapa con órdenes de dibujo conservadas. Invalidar geometría por mapa/cámara/HUD y marcas por cursor/alcance; preservar paredes y orden del pintor. QA específica de rendimiento y regresiones nativas, perfiles aislados; ver docs/SPRINT_22_PERFORMANCE.md. No delegación automática, publicación o balance nuevos.


## Semillas0.22.12

Solicitud21 de octubre: aventuras nuevas con semillas variables para variar capturas. El sorteo publicado ya usa semilla; se sustituye el valor inicial fijo de UI por generación local independiente, campo editable, Generar otra y Copiar en Oak, y copia desde Menú. Vacío genera semilla nueva; continuar/cancelar Oak preserva estado y azar. Misma semilla y decisiones reproducen; tablas/duplicados/insignias conservados. QA específica64 sondeos y dos combates naturales, perfiles aislados; ver docs/SPRINT_22_SEEDS.md. Core/data/snapshots congelados; sin delegación automática o publicación.


## Interfaz de juego0.22.13

Solicitud21 de octubre: integrar mejor la interfaz y mejorar los botones. Tema nativo compartido con variantes para órdenes, herramientas, pestañas y avance; cursor sin procesamiento continuo, menú claro y franja inferior compartida con PS/PT. Mantener controles reales, alto contraste y escalas100/125/150; reservar tablero sin solapamientos y conservar las cachés de rendimiento. Campaña18/combate17, core/data/snapshots y recursos originales congelados. Ver docs/SPRINT_22_GAME_UI.md. Sin delegación automática, publicación ni balance nuevos.


## Hub y tienda 0.22.14

Solicitud del 22 de octubre: reducir explicaciones y confusión. UI para edición 12+ con Comprar / Equipo y bolsa, cuatro categorías (Medicina, Evolución, MT y equipo, Rasgos), detalles por Ficha/Objetos/Movimientos/Rasgos y cantidades con contexto explícito. Bolsa con acciones para objetos poseídos; progreso y EXP en Resumen, avance fijo y ayuda conservada. F6, foco, escalas 100/125/150 y contraste; versiones anteriores conservan controles. Misma campaña 18/combate 17, core/data/snapshots y recursos congelados. Ver SPRINT_22_HUB.md. Sin delegación automática, publicación o cambios de balance.


## Dirección visual 0.22.15

Solicitud del 22 de octubre: dirección profesional con arte nuevo provisional, sin generar imágenes. Cuaderno de Kanto, 45 slots/42 requeridos y 3 de promoción opcional, manifiesto en art/, registro con caché, escenas/terrenos/obstáculos/efectos/iconos conectados. Prompts completos y contratos; instalador verifica PNG/CRC/alfa/máscara 5:3 y conserva copia. Metadatos/icono Windows de versión 15. Publicación y arte final pendientes; no declarar ilustraciones terminadas. Campaña 18/combate 17, core/data/snapshots y recursos de terceros congelados; sin delegación automática o servicios nuevos. Ver SPRINT_22_ART.md, PROMPTS_ARTE_FINAL.md.


## Arte generado 0.22.16

Solicitud del 22 de octubre: producir e insertar las imágenes. 42 recursos del juego generados con image_gen e integrados; 3 promocionales opcionales pendientes. Procedencia/prompts/hashes en godot/art/generated-provenance.json (art/ desde Godot), dimensiones y alfa validados. Misma campaña18/combate17, reglas/datos/snapshots y sprites originales conservados. Ver docs/SPRINT_22_GENERATED_ART.md (../docs/ desde Godot). Publicación pública sigue aplazada.


## Animaciones y sonidos 0.22.17

Encargo del 23 de octubre: secuencias de ataque de hasta 0,64 s, variantes de los 18 tipos y 26 sonidos con jsfxr existente. Solo presentación; campañas 18/17, core/data/snapshots y balance congelados. Cancela al navegar, sin callbacks que modifiquen el juego; movimiento reducido, silencio y volumen conservados. Procedencia en godot/assets/combat/manifest.json (assets/ desde Godot); QA específica attack-effects en desarrollo/EXE y comparación de estados. Ver docs/SPRINT_22_ATTACK_EFFECTS.md (../docs/ desde Godot). Sin publicación pública ni delegación.


## Movimientos espaciales 0.23.0

Auditoría aprobada aplicada al catálogo actual: campaña19/combate18 en nuevos spatial_*.gd y data/spatial.json. No modificar reglas/datos/fixtures publicados para cambiar ediciones anteriores. La actualización es explícita entre encuentros, con copia y replay por edición; un combate pendiente conserva su motor. Fuente de decisiones y límites: docs/SPRINT_23_SPATIAL.md; tabla aplicada en docs/reports/moves-2026-10-24/aplicacion-0.23.csv.

Formas y zonas comparten geometría/visión/alturas con IA y previsión; aliados pueden recibir áreas. Aim de suelo canónico incluye x/y/axis/throwFacing; target se conserva para validación antigua. Cursor/VFX/audio sin PRNG. No rectificar consecuencias de zona ni tiradas. Pantallas2 rondas completas, controles nuevos1 activación, sueño de áreas1; daño/PT provisionales, sin afirmar balance cerrado.40 muestras WAV de PokeDot fijadas y acreditadas, incluida Hiperrayo; no atribuir licencia del código al audio. Sin red al jugar. Sin delegación automática ni publicación; commit/push privado autorizado.


## Sprint 25 — mejoras tácticas, 0.25.0

El encargo del25 de octubre autoriza todas las propuestas: despliegue, amenazas, arenas, ritmo, recuperación, IA, objetivos, terreno y presentación/retos compartibles. Nueva campaña21/combate19, módulos históricos congelados y actualización entre encuentros con copia. Ver [entrega y límites](SPRINT_25_TACTICAL.md). Simulaciones naturales2/6 superan Brock; balance humano y recorrido completo21 pendientes. Sin delegación, publicación pública ni servicios nuevos.


## Acabado para jugadores — sprints26–29

- **26: inicio, textos y movimientos (0.26.0), completado.** Implementación y comprobaciones en [informe](SPRINT_26_PLAYER.md). Mantiene campaña21/combate19.
- **27: perfil local e historial de logros (0.27.0), completado.** Progreso entre campañas, sin ventajas estadísticas permanentes.
- **28: tienda Kecleon y acabado visual (0.28.0), completado.** Interacción integrada, teclado/ratón y movimiento reducido.
- **29: variedad táctica (0.29.0), completado.** Auditoría de211 movimientos, propuestas por rol, herramientas del equipo y recomendaciones de MT. Usa órdenes existentes; no cambia repertorios ni reglas.

El encargo «empieza a implementar» inicia26. Completar cada sprint por separado; no se publica el juego en Internet.


## Entrega27 y continuación autorizada

27: perfil local implementado en0.27.0; [informe](SPRINT_27_TRAINER.md). El usuario pide «implementa todo», autorizando completar también28 (tienda) y29 (variedad táctica) con entrega independiente por sprint. Se conserva la publicación pública aplazada.

## Entrega28

Tienda Kecleon completada en0.28.0; [informe y comprobaciones](SPRINT_28_KECLEON.md). Siguiente29: disponibilidad y variedad táctica con edición nueva cuando cambien resultados. Perfil27 y presentación26 conservados.


## Entrega29 y cierre del encargo

[Informe](SPRINT_29_VARIETY.md): catálogo actual hecho visible y configurable, dos propuestas de rol por línea, filtros por función y plan de aprendizaje. Misma campaña21/combate19; no requiere migración al usar transacciones existentes. Sprints26–29 implementados y empaquetados por separado. Balance humano, pruebas completas de Kanto y publicación pública siguen pendientes; no se presentan como ejecutados.

## Dirección confirmada — identidad Pokémon y mapas reconocibles

El usuario considera correcto el balance actual: se conserva como referencia y se retira el rebalanceo general de la siguiente fase. Abandona los dos roles predefinidos por línea y pide identidad basada en Pokédex, movimientos reconocibles y usos competitivos. Quiere localizaciones propias de Kanto, alturas intencionadas y obstáculos específicos, como árboles en Bosque Verde.

Diseño y propuesta de sprints30–34 en [DESIGN_POKEMON_KANTO_IDENTITY.md](DESIGN_POKEMON_KANTO_IDENTITY.md):30 identidad y retirada de presentación de roles;31 Bosque Verde como muestra;32 Paleta–Brock;33 Kanto por tramos;34 recorrido y acabado final. La base de aprendizaje LGPE y los parámetros vigentes se conservan salvo excepción explícita. Los cambios de geometría se validarán por sus efectos en la dificultad. Se trata de planificación; estos sprints no están implementados ni iniciados automáticamente por documentarlos.


Desarrollo por localización: [mapas de Kanto](DESIGN_MAPAS_KANTO.md),58 nodos cubiertos, ciudades y tienda; conserva Safari narrativo y finales alternativos. Documento de diseño sin cambios en el ejecutable.


## Implementación de identidad y Kanto0.30

La petición posterior «implementa los cambios a los mapas y el resto de cambios» autoriza esta entrega conjunta.30: roles retirados, consultas y repertorios conservados, orígenes visuales por especie.31–33:58 localizaciones, dos tamaños, atlas de16 objetos, alturas/huellas/ocultación y transportadores señalizados.34: finales consecutivos, compatibilidad, logros, QA y paquete Windows; prueba humana completa de Kanto sigue pendiente. No considerar una galería de escenarios o un remate sintético como campaña jugada. [Informe y alcance exacto](SPRINT_30_KANTO.md).

## Revisión de textos0.30.1

[Textos simplificados](FIX_TEXT_0.30.1.md): viaje, despliegue, equipo, movimientos y tienda; controles y reglas tácticas en ayuda opcional. Mantiene datos de decisión, objetivos y consecuencias. Presentación solamente, misma campaña22/combate19 y guardados. Sin publicación pública.

## Entrega0.31 — PP de equipamiento

Cambio autorizado: sustituir gasto durante el combate por presupuesto al preparar, creciente con nivel. Se descarta el presupuesto inicial4–8; primera tabla1–5 por técnica con capacidad10–20. Atributos durante el combate, estados temporales y manantiales compartidos. Actualización voluntaria con copia, nueva edición23. [Informe y tabla](SPRINT_31_POWER.md). Pruebas humanas de equilibrio y publicación pública siguen pendientes.

## Corrección0.31.1

[Movimiento durante el sueño](FIX_SLEEP_0.31.1.md): rutas y comandos bloqueados, despertar restituye movimiento, IA termina. Actualización con copia al cargar0.31.0, incluso en combate; no reiniciar campaña. Reglas y recursos anteriores conservados.

## Interfaz0.31.2

[Equipo, tienda e iconos](UI_SYMBOLS_0.31.2.md): se retira Entrenar de Kecleon; compra de EXP en Equipo → Ficha junto a la experiencia. Iconos locales de los18 tipos y categorías de ataque en ranuras, biblioteca, combate y MT. Misma campaña24, precios y guardados; recursos originales con commit, hashes y créditos.
