# Pokémon Tactics

- Responder en español. Leer docs/PLAN_SPRINTS.md y el último informe antes de continuar.
- Nueva dirección del 15 de octubre en PRODUCT.md: campaña larga de Rojo original, un inicial de Oak, mapas grandes, captura local tras combate y tienda con evolución/entrenamiento; Liga y rival antes de los desafíos legendarios. Objetivo futuro: ejecutable Windows offline. Diferenciar requisitos confirmados de propuestas pendientes.
- El usuario indicó «pues empieza» el 15 de octubre: **autoriza el sprint 13 de base Godot**, no ejecutar automáticamente toda la campaña 14–22. Laboratorio nativo 0.13.2 en godot/, Godot 4.7.2 estándar y plantillas Windows oficiales verificadas; sin complementos nuevos. Consultar godot/AGENTS.md y docs/SPRINT_13.md antes de continuar.
- Encargo del 15 de octubre: completar todos los sprints pendientes con entregas separadas. No delegación automática. El usuario ha decidido **preparar versión y publicar después**; no desplegar, cambiar visibilidad ni comprar dominio.
- Versión 0.12.0, rama codex/sprint-12. Sprints 0–10D y 11 completos técnicamente; 12 preparado para publicar. Pruebas humanas y despliegue público pendientes por decisión del usuario. Guía en docs/DEPLOY.md; paquetes en outputs/releases fuera del repositorio.
- Las reglas siguientes describen la versión web 0.12.0; no sustituyen el objetivo futuro de PRODUCT.md. El sprint 13 conserva src/, public/, parámetros y guardados web; package.json añade scripts Godot, manteniendo la versión web. El informe de balance está en docs/reports/balance-2026-10-15/INFORME.md; sus propuestas no se aplican automáticamente.
- Scripts reales en package.json, Node 24. Dominio POO en src/domain, reglas puras en src/rules, catálogo en src/data, representación en src/game. No convertir tipos o evoluciones en jerarquías de herencia.
- Battle/Combatant/Run serializables; solo datos. RNG no se consume al inspeccionar/previsualizar/animar. Cola fija por ronda, una activación por vivo; movimiento y acción en ambos órdenes.
- Aliados atravesables, destinos ocupados inválidos; enemigos bloquean. Orientación cardinal final con confirmación/cancelación. Precisión frontal/lateral/trasera; áreas incluyen aliados. Reutilizar reglas compartidas con IA.
- Estados/PT se restablecen por combate; PS, XP, equipo y bajas persisten. Hasta seis vivos, tres iniciales dentro de INITIAL_SPECIES. IDs monotónicos distintos de speciesId. Muertos no reviven; equipo vuelve a la bolsa al morir o ser sustituido.
- Un equipable por miembro; consumibles/evolución fuera de combate. Evolucionar/subir nivel conserva PS actuales. XP por victoria/contribución, cinco niveles. EVOLUTIONS es una tabla de datos; familias seleccionadas, no toda Kanto.
- Legendarios/míticos solo enemigos. Tres aves juntas o Mew/Mewtwo; destinos excluyentes. Ocho zonas temáticas, dos mapas por zona y dos arenas. ZONES declara orden y composiciones; peligros etiquetados, daño desde ronda 2.
- Guardado esquema 3 y edición de reglas persistida. replayRun reconstruye transacciones. No cambiar generación/economía o contratos de una edición ya publicada sin migración o nueva edición. Módulos legacy y *-v2 congelados para migrar esquemas 1/2 con copia. Conservar RNG/cola de peleas en curso, detectar conflictos de pestañas y preservar guardados inválidos hasta descarte.
- Ediciones 6–13 mantienen recorridos/reglas anteriores. Edición 14 ajusta campaña tras completar mecánicas: PS efectivos ×2, curación 40/100, victoria 150, objetos evolutivos por avance y Pirotecnia en Charmander. La instantánea combat-v0.4.json protege el ensayo clásico; no regenerarla para ocultar cambios. Ver docs/BALANCE.md.
- UI: HUD táctico dentro del juego, órdenes/previsión centrales, fichas laterales; tablero superior cuadrado. No tapar casillas. Mantener teclado/Escape/foco y movimiento reducido. Reutilizar docs/DESIGN_CAMPAIGN.md y PRODUCT.md.
- Recursos locales de repositorios públicos con commit/hash/licencia/autores. No modificar hojas originales SpriteCollab. Importadores explícitos; ninguna consulta a PokéAPI/SpriteCollab al jugar. Preservar WAV al reimportar sprites. Prototipos training/camp limitados a sus seis unidades originales.
- Guardar cada orden aceptada antes de animar; invalidar callbacks/turnos IA al salir. Cargar en combate solo especies desplegadas. Sonido y volumen no afectan al PRNG.
- Verificar con scripts pertinentes, revisar diff y registrar evidencia real. No declarar probados navegadores/personas no comprobados. No hay linter ni cobertura; Phaser avisa de tamaño. Prueba de release completa ambos destinos desde nueva partida mediante UI.

## Cierre y GitHub

- Autorización persistente para commit/push al terminar cada sprint; no pedirla de nuevo. Repositorio privado: https://github.com/GregorioRuiz98/pokemon-tactics.
- Revisar status y conservar cambios ajenos. Ramas codex/sprint-N, sin force push. No incluir cachés, node_modules, dist, credenciales o ZIP de publicación en Git.
- Actualizar informe, plan, versión y créditos con hechos. Verificar SHA remoto después del push; conservar la rama predeterminada salvo indicación expresa del usuario para cambiarla. La revisión automática del sprint 13 rechazó cambiar esa configuración sin dicha autorización; no reintentar por otra vía. Subir código no publica la web ni cambia visibilidad.
- Usar GIT_CONFIG_GLOBAL=NUL y GIT_CONFIG_NOSYSTEM=1 por el entorno local. Preferir credential.helper=manager por comando. Nunca imprimir ni persistir tokens.

- Revisión de interfaz nativa del 16 de octubre, 0.13.1: HUD inferior compacto y órdenes directas; confirmación solo por riesgo a aliados. Ver docs/SPRINT_13_UI.md. La web y el contrato de guardado/reglas nativo 0.13.0 siguen conservados.


- Revisión 0.13.2 confirmada por el usuario: menú flotante a la derecha al empezar turnos aliados; movimiento directo sin botón Mover; retratos de diálogo PMD de CHUNSOFT. Rectificar solo el movimiento mientras no se haya realizado ninguna acción ni terminado el turno; atacar antes de moverse también lo bloquea. No deshacer ataques, recursos o RNG. Isometría y alturas quedan para otro sprint. Ver docs/SPRINT_13_CONTEXT_MENU.md; sustituye la composición inferior de 0.13.1.


- Sprint 14 autorizado el 16 de octubre con «ponte con el siguiente sprint»: muestra nativa 0.14.0 Paleta–Brock, no ejecución de 15–22. Entrada campaña, laboratorio separado. Ver godot/AGENTS.md e informe docs/SPRINT_14.md.
- Decisiones confirmadas para esta prueba: Brock da medalla, dinero y captura de la última zona salvaje; Caramelo Raro evoluciona una etapa sin nivel; entrenamiento +5 a una estadística con dos compras totales por Pokémon. Precios provisionales. No curar al evolucionar/entrenar PS.
- Campaña Kanto tiene archivo/contrato propios (kanto-save.json, kanto/1); conservar edición o migrar si cambian generación/economía. Duplicados permitidos en la muestra; PC y progresión completa pendientes. Isometría/alturas y cámara se evalúan en 15. Paridad web/laboratorio intacta; no presentar las simulaciones de campaña como balance humano.


- Revisión posterior 0.14.1 en codex/sprint-14-progression: usuario autoriza niveles/estadísticas, dos roles por línea, señales de fallo y nuevas propuestas tácticas. Confirma cuatro movimientos preparados + básico neutro obligatorio sin tipo/STAB, y nivel mínimo + Caramelo por evolución (no da niveles). Sustituye entrenamiento pagado en nuevas partidas. Ver docs/SPRINT_14_PROGRESSION.md y docs/DESIGN_LEVELS_ROLES.md.
- Edición2 implementada mediante progression_run/battle/pokemon/actions.gd, heredando los módulos existentes. No alterar sus reglas futuras sin nueva edición/migración. kanto/1 se reconstruye con KantoRun original y se etiqueta Clásica0.14; iniciar nueva para niveles, preservando copia. Web y laboratorio intactos; presentación compartida puede mostrar recibos de fallo sin consumir RNG.
- Catálogo26/51 movimientos, graveler/golem reutilizados, dos PNG Kenney CC0 y tres WAV nuevos con jsfxr existente; verificar los manifiestos nuevos. Aprendizaje/alcance/PT y algunos efectos son adaptados, no afirmar copia exacta del cartucho. Pasivas/críticos/clima y propuestas tácticas no se han implementado por documentarlas.


- Revisión vigente0.14.2, codex/sprint-14-shop: usuario pide insignia de líder por mayor nivel y tres ofertas MT/equipables con rerolls crecientes. Brock ahora da Onix14 en edición3; rutas sin cambios. Garra Metal ya está al9; MT Demolición80 garantizada primer stock de Charmander. No se retocan fórmulas/estadísticas.
- shop_run/battle.gd heredan edición2; no modificar progression_* para cambiar sus resultados. kanto_store selecciona1/2/3. Nueva campaña para reglas3, con copia; UI etiqueta partidas clásicas. stock/rerolls/shopRandom persistidos; nunca RNG al inspeccionar. Un equipable; devolución a bolsa al cambiar/quitar o cerrar combate con bajas. Ver docs/SPRINT_14_SHOP.md.
- Seis MT de un uso con compatibilidad por máquina (unión de juegos), cuatro equipables y retroceso real de Vidaesfera. Pruebas godot:test:shop y QA de fuente/.exe; importador import-shop.py/manifiesto shop-provenance. Balance humano sigue pendiente; no presentar cobertura como garantía de victoria. No iniciar sprint15 automáticamente.


- Revisión vigente0.14.3, codex/sprint-14-growth: usuario cambia Caramelo a +1 nivel barato y evolución automática por umbral, tanto por EXP como por Caramelo. Confirma Pikachu20/Graveler36 adaptados. Beedrill aprende Demolición y Butterfree Megaagotar al evolucionar al10; Pikachu Cola Férrea al7. Precio provisional25 ₽.
- Nuevos growth.gd/growth_run.gd y data/growth.json, edición4; no alterar motores/datos1/2/3. Uso solo en tienda, conserva EXP parcial/PS/equipo, no revive, cap100. Sin botón/orden evolve en4. Biblioteca respeta4+básico, movimientos aprendidos sin reemplazo forzado. kanto_store elige1/2/3/4; Nueva campaña con copia para reglas nuevas. Ver docs/SPRINT_14_GROWTH.md y godot:test:growth. No afirmar balance cerrado ni iniciar15.

- Revisión0.14.4, codex/sprint-14-letsgo: fuente Atkinson Hyperlegible e indicadores reales de estado/etapas sobre sprites y en ambas fichas. Usuario confirma unir ambas ediciones de Let’s Go y usar sus repertorios sin las tres excepciones anteriores; no añadir movimientos exclusivos de iniciales especiales. Edición5 en letsgo_study/actions/battle/run, datos/provenance nuevos; no alterar motores/datos1–4. kanto_store selecciona1–5.
- Catálogo32/12 líneas/104 movimientos, siete MT LGPE y compatibilidad exclusiva del grupo19. Enemigos/capturas terrestres de zonas actuales con niveles LGPE; normales equiprobables y Bulbasaur especial1% son probabilidades tácticas provisionales, no porcentajes originales. Oddish/Bellsprout21; Gloom/Weepinbell con Piedra Hoja80; Pikachu20/Golem36 confirmados conservados. Efectos/PT/alcance adaptados descritos en habilidades e informe; no afirmar réplica del cartucho ni balance resuelto.
- Ver docs/SPRINT_14_LETSGO.md y godot:test:letsgo. Nueva campaña para tablas nuevas; presentación mejora también guardados clásicos. Fuente OFL y seis sprites/retratos originales con créditos/hashes. Sin plugins/dependencias nuevos ni red al jugar. No iniciar15 ni publicar; commit/push privado al cerrar autorizado.

- Revisión0.14.5 en codex/sprint-14-tactics, edición6: usuario pide precisión sin penalización direccional, daño85–100% dividido frente/mitad baja, costado/alta, espalda/máximo y+1 etapa crítica. Críticos×1,5 y tabla moderna; daño fijo excluido. Confirma estadísticas temporales3 activaciones igual que estados. Parálisis solo mitad de movimiento, sin reducir iniciativa ni perder acción. Mostrar+1/+2/−1/−2 sobre sprites y fichas.
- tactics_study/actions/battle/run y data/tactics.json; motores/datos1–5 congelados. Nuevos prototipos: Cuchillada/Hipercolmillo críticos garantizados3PT; Ataque Rápido/Acua Jet/Golpe Bajo/Ataque Ala se acercan gastando movimiento; Golpe Cabeza/Portazo empujan1; Foco Energía+2 crítico3PT. Mejoras2/3/4PT según etapas/atributos, límite±2 y5PT conservados. No cambia potencia general/niveles/EXP/economía/pool.
- Nueva campaña para6, copia/continuación clásica1–5 y RNG preservados. Ver docs/SPRINT_14_TACTICS.md, godot:test:tactics y test:tactics:journey, QA fuente/ejecutable. Previsión/IA sin RNG, acercamiento no rectificable tras actuar, empujes bloqueados sin daño de choque. No iniciar15 ni publicar. Balance de prototipos requiere prueba humana.

- Revisión0.14.6: vitality_study/run heredan reglas6; edición7 recupera exactamente el aumento positivo de PS máximos al subir por EXP o Caramelo, incluida evolución automática. Mantener PS que faltaban, sin curar por EXP sin nivel ni revivir bajas; piedra sola no cura. Reglas1–6 congeladas, replay selecciona1–7. UI muestra +N PS en recibo. godot:test:level-hp y QA campaña fuente/ejecutable; ver docs/SPRINT_14_LEVEL_HP.md. No inicia15 ni publica.

- Revisión0.14.7: gym_study/run, edición8. Tope por insignia del próximo líder pendiente (Brock/Onix14). EXP sobrante no se acumula; Caramelo al cap bloqueado sin gasto. Victoria de líder usa el cap del siguiente si existe; muestra acaba en Brock y conserva14. PS crecen como7. Reglas/datos1–7 congelados, replay1–8. godot:test:gym-caps, regresión7/6 y QA fuente/ejecutable. Ver docs/SPRINT_14_GYM_CAPS.md. No iniciar15 ni publicar.

- Revisión0.14.8: revive_run hereda8, edición9. Usuario autoriza Revivir, sustituyendo bajas definitivas de campañas nuevas:150 ₽, compra/uso solo tienda, objetivo HP0, recupera50% máximo (floor/mínimo1), consume1. No modifica nivel/EXP/movimientos/ID ni recupera equipable de la bolsa. Pociones normales después. Derrota de todo el equipo sigue terminando campaña, aunque queden Revivir. Reglas/datos1–8 congelados; replay1–9. Ver docs/SPRINT_14_REVIVE.md y godot:test:revive. No iniciar15 ni publicar.

- Revisión0.14.9, edición10, traits_study/actions/battle/run.25 naturalezas,21 mentas100 ₽, Cápsula150 ₽ entre habilidades normales,13 pasivas activas de15 normales en32 especies. Clorofila/Fuga señaladas pendientes de clima/huida; sin ocultas/Parche. IV15/EV0 conservados. Rasgos con PRNG por semilla/ID separado de combate/tienda/rutas, persistidos y sin reroll al evolucionar. Menta conserva naturaleza original; slot normal se conserva al evolucionar. Traits.json/provenance e importador explícito7 CSV PokéAPI fijados. Reglas/datos1–9 congelados; replay1–10. Ver docs/SPRINT_14_TRAITS.md. No iniciar15 ni publicar.

- Sprint15 autorizado:0.15.0, edición11 en scale_run/battle/maps y terrain_movement. Comparar16/24 desde primera pantalla de mapa, elección persistida por diario. Isometría/cámara/zoom/minimapa solo11; anteriores conservan vista/reglas. Alturas0–2: salto terrestre1, subida+1, voladores sin coste vertical; alcance/visión/empuje/acercamiento compartidos con IA. Vigía último del bosque fuera de cola hasta proximidad6/daño/ronda3; incorporación al construir próxima ronda. Objetivo sigue eliminar, sin historia/PC adicionales ni reajuste general. Reglas/datos1–10 congelados, replay1–11. Ver docs/SPRINT_15.md; contraste humano pendiente. No iniciar16 ni publicar.

- Revisión0.15.1 de vista, codex/sprint-15-view: presentación solamente, misma edición11/guardados. Proyección80×48/LIFT12, paredes solo expuestas, apoyo y hit-test alfa de sprites originales; cámara inicial del combate, seguimiento solo al salir del margen, manual respetado. Botones Combate/Unidad/Mapa, G/H, minimapa isométrico. No modificar motores/datos ni pedir Nueva campaña al usuario0.15.0. Ver docs/SPRINT_15_VIEW.md; no iniciar16 ni publicar.


- Sprint16 autorizado el19 de octubre:0.16.0/edición12, roster_run hereda11 sin alterar sus reglas. Usuario confirma PC ilimitado/seis plazas (incluidos debilitados), cambios gratuitos fuera del combate sin curación y derrota aunque haya reservas vivas. Captura sobrante al PC; deposit/withdraw/swap conservan miembro completo y equipable, siempre al menos un activo en pie. Reservas no se despliegan ni reciben EXP; objetos/movimientos respetan restricciones anteriores. Stock considera todos los poseídos. PC paginado en UI solo mapa/tienda/complete; consulta bloqueada para cambios en capture/defeat. Replay1–12, anteriores sin migrar; Nueva campaña preserva copia. Ver docs/SPRINT_16.md, test:roster y qa:roster fuente/.exe. No ampliar Kanto ni rebalancear ni iniciar17 automáticamente. Reutiliza recursos locales y hashes; sin dependencias/activos nuevos.


- Encargo19 de octubre «continua con todo»: autoriza17–22 con commits/push separados; publicación pública sigue aplazada. Sprint17 nativo0.17.0/edición13 añade18 encuentros hastaSurge, snapshot journey-17, catálogo151/211 movimientos y transición explícita desde12 con copia/diario. JourneyRun/Store y ExpandedStudy/Battle/Actions/Maps; no modificar sus resultados publicados sin edición/gating. Repertorios/encuentros LGPE unidos, entrenadores/historia Rojo; MO narrativas y desvíos con requisitos. Curativos nuevos200/todos PS120/200 ₽, piedras/Cable80; equipos y PS conservados.49/78 habilidades activas, pendientes señaladas; efectos complejos descritos como adaptaciones. Nuevos recursos originales, autores/hashes en expedition-provenance; rootCREDITS congelado. Ver DESIGN_KANTO_FULL y SPR17; continuar18–22 autorizado en este encargo. No delegación automática ni despliegue público.

- Sprint18 cerrado0.18.0/edición14:28 encuentros hastaErika/Fuji, hitos Scope/Flauta/Agua Fresca y cola desplazable. Snapshot18 conserva17; transición13→14 explícita con copia. Fuente/.exe6200 aserciones idénticas y recorrido5140, sin fallos. Ver docs/SPRINT_18.md. Continúan19–22 autorizados; sin despliegue público.

- Sprint19 cerrado0.19.0/edición15: Fucsia, Azafrán y sur de Kanto; snapshot19, transición y diario preservados. Recorrido11613 y UI fuente/.exe12544 sin fallos. Ver docs/SPRINT_19.md. Continuar hasta22 autorizado; sin despliegue público.

- Sprint20 cerrado0.20.0/edición16: Liga y rival; snapshot20, transición y diario preservados. Recorrido12273 y UI fuente/.exe4009 sin fallos. Ver docs/SPRINT_20.md. Continuar hasta22 autorizado; sin despliegue público.

- Sprint21 cerrado0.21.0/edición17: Finales legendarios; snapshot21, transición y diario preservados. Recorrido10729 y UI fuente/.exe895 sin fallos. Ver docs/SPRINT_21.md. Continuar hasta22 autorizado; sin despliegue público.

- Sprint 22: entrega técnica 0.22.0/edición 18, combate 17/snapshot 21 conservados. Actualización de finales, guardado 16 MB/futuras ediciones y paleta 24 comprobados. 29 simulaciones sin errores, derrotas incluidas; sin rebalanceo general. Fuente/.exe 898 aves 16 y 510 origen 24 iguales; paquete offline y guía. Pruebas humanas/publicación pendientes;49/78 habilidades activas, terreno provisional. Encargo 17–22 entregado técnicamente; ver docs/SPRINT_22.md. No iniciar nuevos cambios de balance ni publicar por haber documentado propuestas.

- Revisión UI0.22.1, rama codex/sprint-22-ui: Inicio nativo (sin autoload/escena adicional), pausa al volver, Continuar frío/caliente y cancelación de Oak preservada. Tienda por categorías/continuar fijo, retratos/barras de PS, fichas y tema revisados. Mismo motor18/combate17; estado completo de ambos finales idéntico0.22.0. UI fuente/.exe58, aves898 y origen510; regresión PC540/escala980,65 advertencias antiguas/0nuevas. QA aislada en work/qa-sprint-22-ui; paquete0.22.1. Sin plugins/activos nuevos ni publicación. Ver docs/SPRINT_22_UI.md.

- Controles0.22.2: prompt01 de la auditoría aplicado; input_profile/controls_dialog/focus_memory/dialog_input y QA nueva. F2 configura, F6/Mayús+F6 alterna paneles; teclas de seguridad conservadas, preferencias controls.json independientes y nunca en diario. Foco/scroll por ID, captura/cancelación/conflictos y antirrepetición. Campaña18/combate17 y módulos publicados intactos. QA aislada work/qa-sprint-22-controls, scripts test:controls/qa:input/qa:input:export; ver docs/SPRINT_22_CONTROLS.md. No presentar como completados los prompts02–09 ni el soporte de lectores de pantalla. Sin activos/plugins nuevos o publicación.

- Turno contextual0.22.3: prompt02 aplicado sobre controles0.22.2. Elegir habilidad nunca ejecuta; Q/E selecciona objetivos legales, Enter/clic acepta; modos Rápido/Seguro persistentes con confirmación de aliados/autocoste letal. F/flechas/Enter orientan; R conserva límites. Cámara cruceta/Alt+flechas/P y umbral de arrastre; hover respeta teclado. Campaña18/combate17 y reglas/datos congelados. Ver docs/SPRINT_22_CONTEXT.md, QAcontext nativa aislada; siguiente prompt03, no encadenar03–09 ni publicar.

- Encargo20 de octubre «hazlo todo»: autoriza completar prompts03–09 de accesibilidad con entregas/commits separados. Sustituye el límite anterior de no encadenar. Publicación y pruebas humanas siguen pendientes; sin delegación automática. Inspección0.22.4 entregada; continuar04–09.


## Cierre de mejoras0.22.10

El encargo «hazlo todo» del20 de octubre completa técnicamente prompts03–09 con commits separados en codex/accessibility-complete. Ver docs/SPRINT_22_ACCESSIBILITY_COMPLETE.md (desde godot: ../docs/). Inspección, preferencias, cantidades, PC/biblioteca, práctica y acceso textual; motor18/17 y datos/snapshots intactos.09 prepara kit humano sin participantes; lector audible/usuario y DPI físicos pendientes. No delegación automática, publicación ni balance nuevos.


## Rendimiento0.22.11

Solicitud21 de octubre: corregir ralentizaciones. UI/representación solamente; campaña18/combate17, core/data/snapshots y guardados conservados. Tema con escrituras condicionales, previsión por contexto del cursor, semántica agrupada y terreno/minimapa con órdenes de dibujo conservadas. Invalidar geometría por mapa/cámara/HUD y marcas por cursor/alcance; preservar paredes y orden del pintor. QA específica de rendimiento y regresiones nativas, perfiles aislados; ver docs/SPRINT_22_PERFORMANCE.md. No delegación automática, publicación o balance nuevos.


## Semillas0.22.12

Solicitud21 de octubre: aventuras nuevas con semillas variables para variar capturas. El sorteo publicado ya usa semilla; se sustituye el valor inicial fijo de UI por generación local independiente, campo editable, Generar otra y Copiar en Oak, y copia desde Menú. Vacío genera semilla nueva; continuar/cancelar Oak preserva estado y azar. Misma semilla y decisiones reproducen; tablas/duplicados/insignias conservados. QA específica64 sondeos y dos combates naturales, perfiles aislados; ver docs/SPRINT_22_SEEDS.md. Core/data/snapshots congelados; sin delegación automática o publicación.


## Interfaz de juego0.22.13

Solicitud21 de octubre: integrar mejor la interfaz y mejorar los botones. Tema nativo compartido con variantes para órdenes, herramientas, pestañas y avance; cursor sin procesamiento continuo, menú claro y franja inferior compartida con PS/PT. Mantener controles reales, alto contraste y escalas100/125/150; reservar tablero sin solapamientos y conservar las cachés de rendimiento. Campaña18/combate17, core/data/snapshots y recursos originales congelados. Ver docs/SPRINT_22_GAME_UI.md. Sin delegación automática, publicación ni balance nuevos.


## Hub y tienda 0.22.14

Solicitud del 22 de octubre: reducir explicaciones y confusión. UI para edición 12+ con Comprar / Equipo y bolsa, cuatro categorías (Medicina, Evolución, MT y equipo, Rasgos), detalles por Ficha/Objetos/Movimientos/Rasgos y cantidades con contexto explícito. Bolsa con acciones para objetos poseídos; progreso y EXP en Resumen, avance fijo y ayuda conservada. F6, foco, escalas 100/125/150 y contraste; versiones anteriores conservan controles. Misma campaña 18/combate 17, core/data/snapshots y recursos congelados. Ver docs/SPRINT_22_HUB.md. Sin delegación automática, publicación o cambios de balance.


## Dirección visual 0.22.15

Solicitud del 22 de octubre: dirección profesional con arte nuevo provisional, sin generar imágenes. Cuaderno de Kanto, 45 slots/42 requeridos y 3 de promoción opcional, manifiesto en art/, registro con caché, escenas/terrenos/obstáculos/efectos/iconos conectados. Prompts completos y contratos; instalador verifica PNG/CRC/alfa/máscara 5:3 y conserva copia. Metadatos/icono Windows de versión 15. Publicación y arte final pendientes; no declarar ilustraciones terminadas. Campaña 18/combate 17, core/data/snapshots y recursos de terceros congelados; sin delegación automática o servicios nuevos. Ver docs/SPRINT_22_ART.md, docs/PROMPTS_ARTE_FINAL.md.


## Arte generado 0.22.16

Solicitud del 22 de octubre: producir e insertar las imágenes. 42 recursos del juego generados con image_gen e integrados; 3 promocionales opcionales pendientes. Procedencia/prompts/hashes en godot/art/generated-provenance.json (art/ desde Godot), dimensiones y alfa validados. Misma campaña18/combate17, reglas/datos/snapshots y sprites originales conservados. Ver docs/SPRINT_22_GENERATED_ART.md (../docs/ desde Godot). Publicación pública sigue aplazada.


## Animaciones y sonidos 0.22.17

Encargo del 23 de octubre: secuencias de ataque de hasta 0,64 s, variantes de los 18 tipos y 26 sonidos con jsfxr existente. Solo presentación; campañas 18/17, core/data/snapshots y balance congelados. Cancela al navegar, sin callbacks que modifiquen el juego; movimiento reducido, silencio y volumen conservados. Procedencia en godot/assets/combat/manifest.json (assets/ desde Godot); QA específica attack-effects en desarrollo/EXE y comparación de estados. Ver docs/SPRINT_22_ATTACK_EFFECTS.md (../docs/ desde Godot). Sin publicación pública ni delegación.


## Movimientos espaciales 0.23.0

Auditoría aprobada aplicada al catálogo actual: campaña19/combate18 en nuevos spatial_*.gd y data/spatial.json. No modificar reglas/datos/fixtures publicados para cambiar ediciones anteriores. La actualización es explícita entre encuentros, con copia y replay por edición; un combate pendiente conserva su motor. Fuente de decisiones y límites: docs/SPRINT_23_SPATIAL.md; tabla aplicada en docs/reports/moves-2026-10-24/aplicacion-0.23.csv.

Formas y zonas comparten geometría/visión/alturas con IA y previsión; aliados pueden recibir áreas. Aim de suelo canónico incluye x/y/axis/throwFacing; target se conserva para validación antigua. Cursor/VFX/audio sin PRNG. No rectificar consecuencias de zona ni tiradas. Pantallas2 rondas completas, controles nuevos1 activación, sueño de áreas1; daño/PT provisionales, sin afirmar balance cerrado.40 muestras WAV de PokeDot fijadas y acreditadas, incluida Hiperrayo; no atribuir licencia del código al audio. Sin red al jugar. Sin delegación automática ni publicación; commit/push privado autorizado.
