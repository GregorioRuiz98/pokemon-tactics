# Plan de desarrollo por sprints — Pokémon táctico roguelike

Fecha: 14 de octubre de 2026. Versión: 1.10. Estado: sprints 0–6 completados técnicamente; sprint 7 todavía no iniciado. POO, orientación final y paso por aliados implementados. Feedback inicial recibido: bajas demasiado rápidas en 3v3; el usuario aplaza el equilibrio hasta completar las mecánicas y pide conservar los parámetros actuales.

Este documento conserva las decisiones del proyecto y organiza entregas pequeñas para construirlo con asistencia de IA. Cada sprint produce algo revisable y termina antes de comenzar el siguiente. El objetivo es un juego de navegador divertido para el portfolio, con pruebas locales primero y una posible publicación posterior en web propia. La viralidad es una aspiración, no un criterio garantizado de éxito.

## 1. Forma de trabajar

- Mantener **un solo sprint activo**. No ejecutar toda esta hoja de ruta en una misma petición.
- Al recibir «empieza el sprint X», implementar únicamente ese alcance y las correcciones necesarias para que funcione. Las funciones futuras permanecen en el backlog.
- Revisar las instrucciones, el estado de Git y los scripts reales antes de editar. Preservar cambios ajenos. No inventar comandos ni dar por ejecutadas comprobaciones.
- Antes de construir una utilidad o un recurso desde cero, comprobar si los candidatos de la sección 4 resuelven la necesidad con una adaptación pequeña.
- Cerrar cada sprint con una demostración local, pruebas proporcionadas al cambio y un resumen de lo implementado, comprobaciones y limitaciones. Registrar observaciones del jugador.
- Si la prueba revela un problema de diversión o claridad, corregirlo en el sprint actual o abrir un sprint de ajuste antes de añadir contenido.
- No aumentar automáticamente la concurrencia ni delegar trabajo por seguir este documento.
- No fijar fechas hasta conocer el ritmo real de las primeras entregas. Un sprint es una unidad de resultado, no necesariamente una semana.
- La publicación se trata en su propio sprint; este plan no ejecuta ni autoriza por sí mismo un despliegue.

## 2. Decisiones confirmadas

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

Las fórmulas de daño, precisión por ángulo y costes de terreno son provisionales y se conservan por instrucción del usuario. Sprint 5 restablece PT, protección y estados por encuentro; conserva PS y bajas. La recuperación del objeto de una unidad derrotada queda por decidir en sprint 6. Deben quedar parametrizados y documentarse cuando se decidan. El coste de vida persistente debe probarse antes de aumentar la longitud de la partida.

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

Sprints 0–6 completados técnicamente; resto pendiente. Los criterios siguientes describen el cierre de cada entrega. Las comprobaciones ejecutadas figuran en los informes de cada sprint.

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
| 8–9 | Pendientes | — | Ninguna | Encargo conjunto autorizado |
| 10A–10D | Pendientes | — | Ninguna | Ejecutar un bloque por vez |
| 11–12 | Pendientes | — | Ninguna | Pruebas y publicación posteriores |

Entrega 8: completada técnicamente, versión 0.8.0, rama codex/sprint-8. 79 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_8.md).

Entrega 9: completada técnicamente, versión 0.9.0, rama codex/sprint-9. 81 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_9.md).

Entrega 10A: completada técnicamente, versión 0.10.0, rama codex/sprint-10A. 84 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_10A.md).

Entrega 10B: completada técnicamente, versión 0.10.1, rama codex/sprint-10B. 86 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_10B.md).

Entrega 10C: completada técnicamente, versión 0.10.2, rama codex/sprint-10C. 88 pruebas, build/tipos y recursos comprobados. Ver [informe](SPRINT_10C.md).

Plantilla de cierre: objetivo entregado; archivos o módulos modificados; recursos reutilizados y procedencia; comprobaciones ejecutadas y resultados; prueba manual disponible; feedback; pendientes; actualización de valores provisionales.

Petición sugerida para continuar, tras probar la gestión: **«Empieza únicamente el sprint 7 del PLAN_SPRINTS.md; añade experiencia, niveles simplificados y evoluciones mediante objetos».**

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
