# Pokémon Tactics

<!-- impeccable:product-schema 1 -->

## Platform

Entregas actuales: campaña web local 0.12.0 y laboratorio táctico Windows offline 0.13.0 en godot/. Godot 4.7.2 estándar y plantillas oficiales verificados. El ejecutable contiene un ensayo 3v3, recursos y guardado propios; la campaña larga de Kanto aún es el objetivo futuro.

**15 de octubre de 2026:** primero se documentaron los inputs sin iniciar Godot. Después el usuario indicó «pues empieza», autorizando el sprint 13 de base técnica. Esta indicación no inicia automáticamente los sprints 14–22 ni resuelve las propuestas pendientes. La publicación continúa aplazada.

## Users

Fans de Pokémon y RPG tácticos. El creador prueba el loop en local y después lo comparte para recoger feedback. El proyecto forma parte de su portfolio.

## Product Purpose

RPG táctico contra la máquina que recorre la historia de Pokémon Rojo original, con capturas locales aleatorias y bajas definitivas. Campaña larga con guardado entre sesiones, un inicial elegido de Oak y equipos de hasta seis Pokémon desplegados. Prioridades expresadas: diversión, identidad Pokémon, calidad de portfolio y posibilidad de difusión; no se promete viralidad.

## Operating Context

Una entrega por sprint; código subido a GitHub después de las comprobaciones. Los sprints 0 y 1 proporcionan catálogo, sprites, campamento y ensayo de movimiento. El sprint 2 permite un combate completo 3 contra 3. El sprint 3 incorpora POO, tipos, dos habilidades por especie, puntos tácticos, estados y dos composiciones fijas para comparar. El sprint 4 añade orientación final, precisión por ángulo, tránsito aliado, perfiles de terreno, áreas, empuje y ascuas. El sprint 5 incorpora tres compañeros aleatorios, seis encuentros conectados, PS y bajas persistentes, guardado local y resultado de partida. El sprint 6 incorpora tienda, reclutamiento, curación fuera de combate, equipables y hasta seis aliados. Sprints 7–10 incorporan experiencia, evoluciones, dos finales y ocho zonas. Sprint 11 añade tutorial, sonido local, pruebas completas y un ajuste inicial de campaña.

## Capabilities and Constraints

Velocidad con variación de 5–10 % determina la cola de una ronda; una activación por unidad, desplazamiento y acción en ambos órdenes. Recursos locales. Reutilizar repositorios públicos con atribución y conservar las hojas originales. No hay cuentas, multijugador ni IA generativa durante el juego. Pokémon es un requisito del usuario; los legendarios solo aparecen como jefes.

POO solicitada por el usuario para facilitar la herencia de comportamiento. Base común de Pokémon y especializaciones con acciones compartidas; tipos dobles y evoluciones futuras como datos. Contrato en `docs/ARCHITECTURE.md`. El estado serializable sigue separado de las clases con comportamiento.

## Evidence on Hand

Decisiones confirmadas, backlog y valores provisionales en `docs/PLAN_SPRINTS.md`; código, recursos y comprobaciones en los informes de sprint. Los valores de daño, movilidad y salud de esta primera batalla son hipótesis de ensayo, no decisiones definitivas de balance.

La versión 0.12.0 contiene ocho zonas, dos finales, progresión y economía; no implementa todavía esta nueva campaña. El [informe de balance](docs/reports/balance-2026-10-15/INFORME.md) registra 2.000 recorridos y 14.587 combates de IA: reunir seis pronto domina esas simulaciones, la oferta inicial homogeneiza equipos y hay ciclos defensivos de IA. Son resultados de las reglas actuales, no tasas de victoria humanas ni evidencia del balance de la futura campaña. Las recomendaciones del informe no se aplican automáticamente.

## Brand Commitments

El usuario ha pedido integrar las órdenes dentro del gameplay, con paneles de atacante/objetivo y previsión de ataque inspirados en la captura de RPG táctico aportada el 14 de octubre. Se adapta esa organización a Pokémon y al tablero en vista superior. La composición es una preferencia confirmada para las siguientes entregas.

## Estado de entrega

Sprints 0–12 cerrados técnicamente para la versión web, con publicación y pruebas externas pendientes. Sprint 13 aporta la base Godot y su ensayo/guardado/exportación; ver [informe](docs/SPRINT_13.md). El código, parámetros y recursos web permanecen intactos. La muestra nativa 0.14.0 implementa Paleta hasta Brock y el ciclo mínimo de captura/tienda; el resto de la campaña sigue pendiente. Ver docs/SPRINT_14.md.

## Campaña de Kanto — requisitos confirmados

Esta sección sustituye, como objetivo futuro, el inicio con tres aleatorios, las ocho zonas abstractas y el cierre directo en legendarios. El código y las partidas de la versión web conservan su funcionamiento. Las propuestas de la sección siguiente quedan registradas sin convertir sus detalles en decisiones del usuario.

| ID | Requisito confirmado | Resultado esperado cuando se implemente |
| --- | --- | --- |
| K01 | Ejecutable de Windows offline | Jugar y guardar sin navegador, servidor de juego, cuentas ni servicios remotos; el jugador no necesita Godot instalado |
| K02 | Campaña larga con guardado | Continuar entre sesiones; conservar progreso, PS, compras, capturas y bajas; reinicio si cae todo el equipo |
| K03 | Un inicial de Oak | Elegir Bulbasaur, Charmander o Squirtle al comenzar; completar el equipo mediante capturas |
| K04 | Historia de Pokémon Rojo original | Recorrer sus rutas, ciudades y acontecimientos; distinguirlo de Azul, Amarillo y Rojo Fuego |
| K05 | Un combate por ruta | Encuentro temático con las especies de la ruta original; añadir gimnasios y acontecimientos como encuentros diferenciados |
| K06 | Mapas más grandes | Más espacio y decisiones de terreno que los tableros actuales; tamaño y número de enemigos pendientes de prueba |
| K07 | Gachapón tras cada combate ganado | Obtener un Pokémon aleatorio de la ruta o zona, con presentación de captura; no comprar reclutas de una oferta genérica como mecanismo principal |
| K08 | Tienda después de la captura | Flujo de victoria → captura → tienda → preparación → siguiente encuentro |
| K09 | Caramelos Raros para evolucionar | Revisión 0.14.1: nivel mínimo + un caramelo por etapa; no concede niveles, última decisión del usuario |
| K10 | Crecimiento de estadísticas por nivel | Sustituye entrenamiento por dinero en partidas nuevas; moneda reservada para caramelos/consumibles y futuras compras |
| K11 | Liga Pokémon y rival | Cierre principal de la campaña; no sustituirlo por un combate legendario |
| K12 | Legendarios después de la Liga | Dos desafíos alternativos: Articuno/Zapdos/Moltres y Mew/Mewtwo; siguen excluidos de capturas, inicio y reclutamiento |
| K13 | Inicio por indicación expresa | El usuario autorizó sprint 13 con «pues empieza»; no extenderlo automáticamente al resto de la campaña ni a publicación |

Se mantienen las decisiones tácticas anteriores: control manual, cuadrícula cuadrada superior, máximo seis desplegados, tipos modernos y dobles, cola por velocidad recalculada por ronda, movimiento y acción en ambos órdenes, orientación final, aliados atravesables y previsión sin consumir RNG. Los PS y las bajas persisten; consumibles curativos fuera de combate, un equipable por miembro y recuperación del objeto al morir o ser sustituido. La POO comparte comportamiento; tipos y evoluciones siguen siendo datos, no jerarquías de herencia.

## Ideas registradas para acercarlo a Pokémon

Son propuestas para evaluar dentro de las funcionalidades pedidas. Incorporarlas al backlog no fija cantidades, precios, excepciones ni todas las reglas nuevas.

| ID | Propuesta | Decisión o prueba necesaria |
| --- | --- | --- |
| P01 | Mapa regional con ciudades, rutas y lugares reconocibles; trayecto del entrenador entre encuentros | Conservar ritmo de aventura sin construir todavía un mundo completo de exploración libre |
| P02 | Desvíos como Ruta 22 temprana, Camino de Bicis o costa hacia Fucsia | Decidir qué rutas son obligatorias, alternativas y opcionales; volver a una ubicación no implica automáticamente otro combate ni otra recompensa |
| P03 | Probar primero 16×16 y 24×24; cámara y zoom sin ocultar casillas bajo el HUD | Son tamaños de ensayo, no límites aprobados ni prueba de que más superficie resulte más divertida |
| P04 | Grupos enemigos que se incorporen al acercarse, con señales claras | Definir activación, iniciativa y persistencia; evitar rondas de enemigos lejanos y desplazamiento vacío |
| P05 | Objetivos puntuales de salida, rescate o derrota del entrenador principal | Empezar por eliminar enemigos; decidir recompensas y qué ocurre con los grupos que quedan vivos |
| P06 | Captura con animación de encuentro/Poké Ball, mote, origen y rarezas locales | Separar la tabla de captura de la plantilla de enemigos; un Pokémon de entrenador no pasa automáticamente a la tabla salvaje |
| P07 | Una captura por ubicación, al estilo Nuzlocke; cláusula de duplicados por familia | **Alternativa pendiente a K07**, que pide una captura tras cada combate; no imponerla ni retirar premios de gimnasio sin decisión del usuario |
| P08 | Recompensas propias de gimnasios y eventos: medallas, MT u objetos | Si reemplazan el gachapón, constituyen una excepción pendiente a K07; si lo acompañan, definir la tabla local aplicable |
| P09 | PC de reserva con seis desplegados; registro de bajas con mote y procedencia | Capacidad, momentos de intercambio, equipables en reserva y tratamiento de derrota con reservas pendientes |
| P10 | Capturas con nivel adecuado a la zona | Medir si pueden incorporarse al equipo; evitar reposiciones inutilizables por llegar siempre a nivel uno |
| P11 | Vitaminas: Proteína, Hierro, Calcio, Zinc, Carburante y Más PS | Forma propuesta de K10; topes por miembro, disponibilidad por medalla y costes crecientes aún sin aprobar; revisar velocidad por su efecto en iniciativa |
| P12 | Experiencia por combate, Caramelo Raro que acelera niveles y evolución por requisitos de especie | Comparar con el uso directo evolutivo solicitado en K09; conservar piedras y resolver intercambios mediante un objeto local si se adopta |
| P13 | Cuatro movimientos configurables, aprendizaje gradual y MT | Decidir si el básico ocupa una plaza, compatibilidad con PT/PP y conservación del rol al evolucionar |
| P14 | Rival recurrente con equipo que evoluciona; gimnasios reconocibles con mecánicas propias | Equipos, apariciones y adaptación táctica pendientes de documentar por tramo |
| P15 | Medallas que amplían entrenamiento/catálogos; Pokédex con vistos, capturados y origen | Evitar desbloqueos arbitrarios o mejoras sin límite; definir los datos que persisten al reiniciar |
| P16 | Escenas breves con Oak, Bill, Team Rocket y personajes clave | Apoyar el recorrido sin rehacer todos los diálogos o puzzles originales |
| P17 | Presentar PC y servicios como parte de ciudades y Centros Pokémon; tiendas de ruta con catálogo menor | Mantener tienda tras cada combate; curación gratuita de Centro no está aprobada y no sustituye la regla de objetos fuera de combate |

## Recorrido y recursos de referencia

Orden narrativo de referencia: Paleta → Ruta 1 / Ciudad Verde / Ruta 2 / Bosque Verde → Plateada y Brock → Ruta 3 / Monte Moon / Ruta 4 → Celeste, Misty y Bill en rutas 24–25 → rutas 5–6 / Carmín / S. S. Anne / Lt. Surge → rutas 9–10 / Túnel Roca / Lavanda → rutas 8–7 / Azulona / Erika / guarida Rocket → Torre Pokémon, Silph S. A., Azafrán y Fucsia con sus gimnasios → rutas marítimas / Islas Espuma / Canela / Mansión Pokémon / Blaine → Ciudad Verde y Giovanni → rutas 22–23 / Calle Victoria → Alto Mando y rival → desafíos legendarios.

Es una referencia de hitos, no la especificación de todas las rutas ni un orden único obligatorio: el original permite alternativas. Las rutas 11–18 y 21, Cueva Diglett, Safari y Central de Energía deben clasificarse al cerrar el grafo. No se omiten por no aparecer en la línea abreviada. Las rutas 24–25 no van después de la 23 por su número. El número de combates en mazmorras y gimnasios sigue pendiente.

- [Recorrido de Rojo/Azul original](https://bulbapedia.bulbagarden.net/wiki/Walkthrough:Pok%C3%A9mon_Red_and_Blue): referencia de localizaciones y acontecimientos, no de nuestras reglas de combate.
- [Tablas de encuentros de pret/pokered](https://github.com/pret/pokered/tree/master/data/wild/maps): consultar la variante `_RED`, separar hierba/agua/pesca y definir acceso a métodos especiales. Ejemplos verificados: Ruta 1, Pidgey/Rattata; Ruta 2, Pidgey/Rattata/Weedle en Rojo; Bosque Verde, predominio de Weedle/Kakuna y apariciones de Caterpie/Metapod/Pikachu. No copiar una tabla conjunta de todas las versiones.
- Reutilizar sprites, retratos, metadatos de duración/anclaje, audio y fuente locales existentes. Importar solo las especies necesarias por tramo; registrar commit, hash, autores y licencia antes de incorporar material nuevo. Ninguna descarga durante una partida.
- [Tiny Town de Kenney](https://kenney.nl/assets/tiny-town): candidato para terreno si encaja con los sprites; no importado ni adoptado por este documento.
- Godot estándar 4.7.2 y sus plantillas: herramientas previstas. GDScript tipado es una preferencia técnica propuesta; [GUT](https://github.com/bitwes/Gut) para pruebas y [Godot MCP](https://github.com/Coding-Solo/godot-mcp) para asistencia son opcionales y requieren verificar compatibilidad. No se han instalado ni configurado. No hay complementos de pago imprescindibles identificados.

Las fuentes se registran como referencias de diseño. Este encargo no descarga recursos, integra código de esos repositorios ni modifica los créditos de la entrega actual.

## Contrato previsto y casos límite

Superficies futuras: elección de inicial, mapa de viaje, combate táctico, recompensa de captura, tienda/entrenamiento, gestión de equipo, guardado y resumen de campaña/postgame. Un único jugador controla su equipo; no se añaden servicios remotos.

Transición propuesta: elegir inicial → viajar al encuentro disponible → combatir → registrar victoria y bajas → resolver captura → tienda → preparar siguiente encuentro. El cierre de la Liga habilita el postgame. La derrota conduce a fin de campaña conforme a la política de reservas que se acuerde. Guardar también dentro de los combates, conservando RNG, cola y orientación, es el punto de partida del sistema actual.

Implicaciones de datos que habrá que especificar antes de programar:

- IDs estables de ubicación, encuentro y tabla de captura/versionado; separar especies salvajes de equipos de entrenador, gimnasio y jefe.
- Inicial, medallas, hitos narrativos, rutas visitadas, capturas reclamadas, resultado del sorteo y estado de la tienda. Semilla y reglas de generación persistidas; inspeccionar una recompensa no la vuelve a sortear.
- IDs individuales, especie, PS, EXP, origen/mote, equipable, estadísticas entrenadas y movimientos si se adoptan; separar activos, reservas y bajas sin duplicar miembros.
- Transacciones únicas de captura, compra, entrenamiento y evolución: cerrar o recargar no concede otra recompensa ni cobra dos veces. Definir recuperación ante cierre a mitad de guardado y conservar copia de datos inválidos antes de descartarlos.
- Guardado nativo con esquema/edición propios o un importador explícito. No prometer lectura automática del localStorage web desde el ejecutable, ni sobrescribir partidas anteriores. La compatibilidad exacta está por decidir.
- Conservar PRNG, reglas de redondeo y desempates cuando se exija paridad. Usar pruebas y simulador actuales como referencia; añadir escenarios para un único inicial, encuentros de mayor tamaño y la economía nueva.

Antes de aceptar cada entrega: comprobar que las capturas pertenecen a su tabla y respetan exclusiones; que solo hay seis desplegados; que no se revive al evolucionar, cambiar de equipo o recargar; que el inventario y las mejoras no se duplican; y que la campaña puede continuar tras guardar en cada superficie. Las pruebas de diversión requieren partidas humanas; las simulaciones no fijan su duración en minutos.

## Decisiones pendientes y siguiente entrega

1. Para Brock se confirma medalla, dinero y captura del Bosque Verde. Otros gimnasios/eventos, revisitas, cláusula de duplicados y tablas agotadas siguen pendientes; la muestra permite duplicados y solo cuatro victorias sin revisita.
2. PC de reserva, cambios permitidos y si perder los seis desplegados termina la campaña aun teniendo reservas. El usuario confirmó bajas definitivas y reinicio al perder el equipo; no inventar rescates desde el PC.
3. Escala de niveles, requisitos evolutivos/caramelos/piedras, aprendizaje de movimientos y límites/coste del entrenamiento. El sistema actual de cinco niveles no queda ampliado por este documento.
4. Rutas obligatorias/desvíos, número de combates especiales, escala de mapas, condiciones de activación y objetivos; decidir cómo se elige uno de los dos desafíos de postgame y qué ocurre al completarlo.
5. Formato y compatibilidad de guardados; localización de Godot, plantillas y distribución del ejecutable cuando se autorice el port. Un único archivo `.exe` o `.exe` acompañado de recursos es una decisión de empaquetado, no un requisito ya confirmado.

Estado del traspaso: base técnica 13 y muestra 14 autorizadas y entregadas. Paleta hasta Brock disponible en Windows 0.14.0; los sprints posteriores siguen pendientes. La secuencia y criterios de cierre están en [PLAN_SPRINTS.md](docs/PLAN_SPRINTS.md#11-siguiente-etapa-kanto-y-ejecutable).


### Interfaz confirmada — 16 de octubre de 2026

Menú de órdenes vertical a la derecha dentro de la escena, visible automáticamente al empezar el turno aliado. Movimiento directo por casillas, sin botón Mover. Añadir Rectificar movimiento, disponible solo antes de cualquier acción o fin de turno; atacar primero y moverse después también lo bloquea. Nunca deshacer ataques, PS/PT, estados o RNG.

Retratos de diálogo de Pokémon Mundo Misterioso, referencia Exploradores del Cielo: activo abajo a la izquierda y objetivo/previsión abajo a la derecha. Mantener básico directo y habilidades en submenú como elección de implementación mientras se valida la composición. El usuario prefiere isometría y alturas, pero ha elegido resolver primero la interfaz y tratarlas en otro sprint.


### Muestra confirmada — sprint 14, 16 de octubre

El usuario confirma tras Brock medalla/dinero/captura de la última zona salvaje y acepta para probar un Caramelo Raro por evolución sin nivel y entrenamiento +5 con dos compras totales por Pokémon. Se conservan PS y topes al evolucionar. Oak entrega 120 y dos pociones; victoria 150; precios de poción40/super90/caramelo100 y entrenamiento80 son provisionales de implementación.

La muestra incluye cuatro encuentros (Ruta 1, Ruta 2, Bosque Verde y Brock), tablas de hierba de Rojo y cinco miembros como máximo contando el premio final. Duplicados permitidos provisionalmente, sin cláusula por familia. PC, intercambio, equipables, EXP, MT y niveles completos se concretarán en 16. Tras morir todo el equipo termina la campaña.

Mapas cenitales de prueba 12×10; no cumplen aún el objetivo de escala/isometría/alturas, reservado a 15. Paleta/Ciudad Verde/Plateada aparecen mediante pantallas de viaje y textos; no hay exploración libre ni recreación completa de acontecimientos. Paquete/Pokédex resumidos narrativamente; combate inicial del rival, Ruta 22 opcional y entrenadores secundarios pendientes. El final de la muestra es Brock; no la Liga.

Guardado de campaña independiente kanto/versión 1, con sorteo y órdenes persistidos, sin importar ni sobrescribir web/laboratorio. Regenerar futuras reglas exige edición nueva o migración. Las simulaciones de 14 son diagnóstico provisional, sin autorización automática para cambiar fórmulas de daño del laboratorio.


### Revisión de progresión — decisión posterior del 16 de octubre

El usuario sustituye el entrenamiento por dinero por niveles que aumentan estadísticas y pide dos roles por línea, definidos mediante movimientos. Confirma cuatro movimientos configurables **más** un básico fijo sin tipo ni STAB (cinco acciones) y evolución mediante Caramelo Raro con restricción de nivel. El Caramelo no sube niveles. La regla anterior de evolución sin nivel y entrenamiento +5 pagado queda vigente solo en edición1.

Edición2 implementada en 0.14.1: inicial5, EXP por victoria a cada superviviente, curvas deterministas sin curación, aprendizaje/biblioteca y preparación gratuita, diez líneas y 26 especies con 51 adaptaciones tácticas. Pikachu20 y Graveler36 son umbrales provisionales de métodos antes por piedra/intercambio. Lectura de STAB en previsión, fallos/inmunidades con imágenes y audio diferentes. Datos exactos, roles, límites y propuestas propias en docs/DESIGN_LEVELS_ROLES.md.

Las propuestas de amenazas por casilla, habilidades pasivas, apoyos por flanqueo, MT, alturas e interacciones elementales quedan como futuras entregas. Se adelanta parte de 16, sin iniciar mapas/isometría de 15, extender Kanto ni publicar. Guardados1 siguen sus reglas y los nuevos usan2; se conserva copia al reiniciar para probar la progresión nueva.


### Revisión de tienda y gimnasio — 16 de octubre, 0.14.2

El usuario sustituye expresamente el premio salvaje del gimnasio por su Pokémon insignia: el de mayor nivel, Onix14 en Brock; mantiene medalla/dinero. Las rutas conservan sus capturas locales. Nunca se reclutan legendarios/míticos. Añade tres ofertas MT/equipables y renovaciones pagadas de coste creciente.

Edición3: tres ofertas distintas con una copia, al menos una MT útil y un equipable mientras haya MT por aprender; restantes aleatorios. Renovación25×(n+1) ₽ por visita; reponer las tres puede volver a ofrecer objetos anteriores. Primer stock de Charmander incluye Demolición80 antes de Brock. Garra Metal ya se aprende al9. Seis MT y cuatro equipables; un uso por MT y un equipable por miembro. Compatibilidad por máquina verificada en PokéAPI, unión de versiones. Pociones/Caramelos permanecen aparte. Precios provisionales; no se cambian estadísticas ni fórmulas base de daño.

Guardado conserva oferta, compras, coste y PRNG de tienda separado del de capturas. Equipables retornan a bolsa al sustituir/quitar o al cerrar combate con bajas. Vidaesfera ×1,3 con retroceso10% de PS máximos una vez por acción dañina, incluido básico neutro; no por fallo/inmunidad/apoyo. Puede causar baja. Ediciones1/2 siguen sus motores; Nueva campaña para estas reglas con copia del archivo anterior. Isometría y ampliación de Kanto continúan pendientes.
