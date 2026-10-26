# Kanto nativo — sprint 14

- Godot 4.7.2 estándar/GDScript, Windows x86_64 offline. Versión nativa 0.14.0, web 0.12.0 conservada. Leer docs/SPRINT_14.md y PRODUCT.md. No iniciar sprint 15 sin encargo.
- Entrada: scenes/campaign.tscn, Paleta → Ruta 1 → Ruta 2 → Bosque Verde → Brock. Cuatro encuentros 12×10, un inicial de Oak, captura local y tienda. Brock concede medalla/dinero/captura del bosque. No confundir esta muestra con Kanto completo.
- Dominio KantoBattle hereda LabBattle; KantoPokemon extiende perfiles. Tipos y evolución como datos, acciones polimórficas. Estado solo JSON. Motor compartido para jugador/IA/previsión; no RNG al inspeccionar, dibujar, sonar o cancelar.
- Repertorios enemigos iniciales limitados por encuentro (1/1/2/3 acciones). Mantener fórmulas y referencias de laboratorio: 16 combates/506 órdenes/25 escenarios, sin regenerar fixtures para ocultar cambios. No se han modificado src/ ni public/.
- Campaña: user://kanto-save.json, esquema kanto/versión 1, diario y estado canónico; revisión por transacción impide callbacks obsoletos. Guardar antes de presentar, recompensa sorteada antes de reclamar, detectar conflictos y preservar archivos inválidos/copias al reiniciar. Cambios de economía/generación exigirán migración o nueva edición, no romper replay.
- Laboratorio independiente: user://laboratory-save.json, esquema 1/contrato 0.13.0. Mantener su carga, reglas, recursos y vistas. user:// equivale a %APPDATA%/PokemonTacticsLab; no tocar guardados web ni reales durante QA.
- Valores de prueba: Oak 120 y 2 pociones; victoria 150; poción40/super90/caramelo100; curan40/100. Un caramelo por etapa sin nivel; entrenamiento80, +5 a un atributo y dos compras totales por Pokémon. Evolución/PS máximos no curan. Muertos no reviven; límite de entrenamiento se conserva al evolucionar. Duplicados permitidos provisionalmente; máximo cinco miembros en esta muestra, PC pendiente.
- HUD derecho en turnos aliados, retratos PMD en esquinas, movimiento directo, no tapar casillas. Rectificar exclusivamente último movimiento antes de cualquier acción o fin de turno; nunca recursos/RNG. movement_revision.gd admite estado inicial de encuentro sin alterar el contrato de laboratorio.
- Retratos/hojas originales sin modificar. kanto-provenance.json añade 148 hashes; catálogo de 24 especies. Importador explícito tools/godot/import-kanto.py, commits fijados SpriteCollab/pret; ninguna descarga al jugar. Conservar WAV y atribución individual, incluidas contribuciones comunitarias de retratos.
- Scripts en package.json: godot:verify/prepare/test/qa/export/qa:export y test:campaign, test:campaign:edges, qa:campaign, qa:campaign:export. GODOT_BIN solo desarrollo. QA por controles y eventos del viewport, sin sustituir pruebas humanas. No añadir GUT/MCP/dependencias sin necesidad.
- Isometría, alturas y escala/cámara se evalúan en 15; equipo/progresión completa en 16. Aún sin EXP, PC, MT, equipables de campaña ni escenas completas del rival. Paquetes fuera de Git, créditos/licencias/hashes incluidos. Commit/push autorizado al cerrar, sin despliegue ni cambio de configuración GitHub.


## Revisión vigente — 0.14.1

- Sustituye para partidas nuevas las reglas provisionales de entrenamiento/evolución anteriores: niveles y EXP a supervivientes por victoria; estadísticas con bases reales/IV15/EV0/naturaleza neutra y PS×4; no curación al subir/evolucionar. EXP220/350/500/650, coste siguiente nivel40+10L, cap100; valores de prueba.
- Cuatro movimientos preparados además de básico fijo neutro25/0PT/alcance1, sin STAB ni modificadores de tipo; conserva precisión/defensa/estado. Biblioteca por nivel, roles combinables y preparación gratuita. Caramelo100 por evolución tras umbral; no da niveles. Pikachu20 y Graveler36 son adaptaciones explícitas.
- progression_run.gd hereda kanto_run.gd; progression_battle/pokemon/actions.gd extienden el dominio. No modificar v1 para cambiar sus resultados. kanto_store selecciona motor por versión1/2; guarda edición2 cuando state.edition==2. No convertir una pelea antigua ni generar EXP retroactiva. Anunciar Clásica0.14 en UI de archivos anteriores.
- core/kanto_run.gd solo añade recibos de presentación al retorno; no al estado persistido. combat_feedback.gd dibuja recibos reales: FALLO/INMUNE/daño/curación/atributos; ningún RNG ni estado táctico en presentación. Sonido correcto aunque falle un ataque, ajustes y movimiento reducido conservados.
- Datos nuevos progression.json (26 especies,10 familias,51 movimientos) y dos manifiestos extra; importadores explícitos import-progression.py e import-feedback.mjs. Fuentes/commits y bytes originales conservados. Ningún servicio nuevo.
- Comprobar godot:test:progression, casos límite clásicos, paridad, QA de campaña/laboratorio en fuente y ejecutable. QA de inmunidad usa fixture aislada sin guardarla; compatibilidad UI usa otro archivo. Paquetes0.14.1 fuera de Git. Isometría/escala, PC, equipables/MT y pasivas pendientes.


## Revisión vigente — 0.14.2

- Nuevas partidas edición3 mediante shop_run.gd/shop_battle.gd, heredando reglas2 congeladas. Guardados1/2 se reconstruyen y continúan sin conversión; usar Nueva campaña, que preserva copia.
- Brock concede Onix14 por ser el enemigo no legendario/mítico de mayor nivel. Rutas conservan tablas. Tres ofertas con una copia por casilla, seis MT compatibles y cuatro equipables. Primer stock de Charmander garantiza MT Demolición80. Garra Metal ya se aprendía al9. Precios de renovación25,50,75… ₽ y reset por tienda, provisionales.
- stock/rerolls/shopRandom separados del PRNG de rutas, persistidos y reconstruidos por diario. Comprar/equipar/aprender solo fuera de combate. Una MT por uso, máximo4 preparados+básico. Sustituir/quitar devuelve equipado; bajas lo devuelven al terminar combate. Vidaesfera afecta básico/tipados, nunca fallo/inmunidad/apoyo; retroceso una vez por acción, incluso área. Resolver KO propio/cola y derrota simultánea.
- shop.json/shop-provenance con datos PokéAPI e importador explícito, sin activos visuales ni dependencias nuevas. Pruebas godot:test:shop, regresión2/clásica/laboratorio y QA de fuente/ejecutable. Informe docs/SPRINT_14_SHOP.md. No ampliar mapas ni dar balance por resuelto.


## Revisión vigente — 0.14.3

- Crecimiento en edición4: growth_run hereda shop_run y comparte Growth con el motor/perfiles. Growth hereda Progression y aplica sobre su instancia las adiciones de growth.json; módulos/datos publicados1/2/3 congelados. KantoStore selecciona4 sin convertir partidas antiguas.
- Caramelo25 ₽/+1 nivel; compra/uso en tienda. Conserva EXP parcial, PS y equipable; cap100 y bajas bloqueadas. Evolución automática al cruzar umbral por EXP o Caramelo; no comando evolve ni botón manual en4. Mantener por confirmación del usuario Pikachu20/Graveler36 adaptados. Los encuentros mantienen sus especies configuradas; evolución se resuelve al subir de nivel.
- Beedrill/Demolición y Butterfree/Megaagotar al evolucionar al10; Pikachu/Cola Férrea al7, también accesible a Raichu. Prioridad al aprender con hueco, nunca más de4 preparados+básico ni reemplazar elecciones. Si está lleno, va a biblioteca. Roles cuentan las nuevas entradas. Compartir repertorios con IA.
- godot:test:growth prueba precio, uso, evolución, aprendizajes, cap, PS/EXP/objeto y replay1/2/3/4. QA usa controles/guardados aislados y prepara un Beedrill antes de Brock. Paquete0.14.3 offline fuera de Git. Ver docs/SPRINT_14_GROWTH.md. Sin nuevos recursos/dependencias ni balance global.

## Revisión vigente — 0.14.4

- Edición5: letsgo_study/actions/battle/run extienden dominio; datos letsgo.json/letsgo-shop.json/provenance propios. Motores1–4 y sus resultados congelados. Fuente Atkinson Hyperlegible OFL sustituye presentación Pixelify; unit_indicators.gd comparte badges de tablero/fichas, reales y sin PRNG.
- Usuario combina ediciones LGPE y retira excepciones de movimientos previas.32 especies/12 líneas/104 movimientos, aprendizajes/MT solo grupo19, sin13 exclusivos de iniciales especiales. Pikachu Doble Patada9, Cola Férrea MT19; Charmander Ascuas13/sin Garra Metal; insectos sin regalos de cobertura. Siete MT, equipables previos y primera Demolición de Charmander conservados.
- Salvajes terrestres de zonas actuales y niveles3–4/3–6; recompensas misma unión más Bulbasaur especial bosque. Probabilidades provisionales equiprobables/1%, no tasas originales. RNG generación salvaje por semilla/zona, separado de recompensa/tienda. Brock12/14 y premio Onix14. Oddish/Bellsprout21, Piedra Hoja80 para Gloom/Weepinbell; Pikachu20/Golem36 siguen adaptados.
- Cambios múltiples/precisión/evasión/estados, Niebla Clara, daño fijo y costes propios ejecutables. Efectos complejos traducidos explícitamente en descripción, ver docs/SPRINT_14_LETSGO.md; no críticos/pasivas/clima ni réplica exacta. Sueño/congelación sin daño, confusión/drenadoras independientes; no RNG al prever/dibujar. Fórmula/base/economía no retocadas para balancear.
- Scripts godot:test:letsgo y test:letsgo:journey, regresiones4/3/2/clásica/laboratorio, QA fuente/ejecutable. Recorridos automáticos no sustituyen balance humano: Squirtle pierde pronto al no aprender Burbuja hasta9. Nueva campaña para5; conservar archivos antiguos. Paquete0.14.4 offline fuera de Git; no iniciar15 ni publicar.

## Revisión vigente — 0.14.5

- Edición6 en tactics_study/actions/battle/run, tabla tactics.json; no alterar motores/datos1–5. Guardados seleccionan1–6. Precisión propia/etapas sin penalización frontal/lateral; Confusión mantiene adaptación−25. Daño85–100% por bandas inclusivas frente/mitad baja, costado/alta, espalda/máximo y+1 crítico. Rango antes de limitar a PS; daño fijo sin variación/crítico. Previsión muestra rangos y probabilidades, no resultados futuros.
- Críticos×1,5, etapas modernas0/1/2/3; ignoran ofensiva negativa/defensa positiva, conservan quemadura/protección/tipos/STAB/equipable. Garantía de crítico no implica acierto. Cuchillada/Hipercolmillo3PT garantizados; Foco Energía3PT/+2 crítico temporal, ya no precisión. Descripciones de adaptaciones explícitas; repertorios LGPE conservados.
- Usuario confirma estados y atributos3 activaciones del afectado (actual incluida al autoaplicar); temporizador por atributo, caduca a base, no refrescar al cap, Niebla Clara limpia temporizadores. Parálisis solo movimiento/2, mínimo1; new_round propio mantiene velocidad/iniciativa. Mejoras+1=2PT,+2=3PT,dos atributos+1=3PT,tres=4PT; no balance global.
- Acercamientos gastan movimiento restante/acción, respetan terreno, aliados atravesables/enemigos bloquean, destino libre, pagan también al fallar y bloquean Rectificar. Golpe Cabeza/Portazo empujan1; obstáculos sin daño de choque ni salida del mapa. IA valora flanqueo legal y coste/duración de apoyos con previsión pura; no lee resultados aleatorios.
- Marcadores añaden etapas firmadas y duraciones; crítico usa recibo real, drenaje usa daño tirado. Pruebas godot:test:tactics y test:tactics:journey, regresión5/4/3/2/clásica/laboratorio, QA de campaña fuente/ejecutable y guardados aislados. Ver docs/SPRINT_14_TACTICS.md. Ejecutable0.14.5 offline, sin activos/plugins/dependencias nuevos. No iniciar15 ni publicar.

## Revisión vigente — 0.14.6

- Edición7 en vitality_study/run: PS actuales += aumento positivo de PS máximos al subir por EXP o Caramelo, incluida evolución automática. Conserva déficit de PS, EXP parcial, equipable y repertorio; no cura sin subida ni revive bajas. Piedra sola sigue sin curar. Estudio compartido por campaña/motor/perfiles; sin cambios a fórmulas tácticas.
- KantoStore selecciona1–7 sin convertir guardados. UI usa7 para nuevas campañas, recibo +N PS y texto de tienda actualizado. godot:test:level-hp comprueba crecimiento, transacciones y compatibilidad; QA campaña fuente/ejecutable. Paquete0.14.6 fuera de Git. Ver docs/SPRINT_14_LEVEL_HP.md. No iniciar15 ni publicar.

## Revisión vigente — 0.14.7

- gym_study/run heredan7; edición8. Cap calculado con ace del primer líder no presente en cleared, límite global100 como techo técnico. Brock/Onix14 es el único gimnasio implementado; al finalizar se conserva14. EXP aceptada limitada al coste restante, sobrante descartado; al llegar, EXP0. Caramelo al cap rechazado sin tocar bolsa/revisión/RNG; UI bloqueada y etiqueta del líder/insignia.
- Al vencer un líder, su EXP usa el siguiente cap si existe. Crecimiento de PS, evolución/aprendizaje y equipo se conservan; captura no excede el cap. Catálogo y módulos1–7 congelados, KantoStore1–8. godot:test:gym-caps, test:level-hp/test:tactics y QA campaña fuente/ejecutable. Ver docs/SPRINT_14_GYM_CAPS.md; paquete0.14.7 fuera de Git. No iniciar15 ni publicar.

## Revisión vigente — 0.14.8

- revive_run extiende gym_run sin modificar su estudio/motor. Edición9 añade bag.revive0 y consumible fijo150 ₽. Comprar/usar solo en shop; revive únicamente HP0 a floor(maxHp/2), mínimo1, con estadísticas de progresión. Revision/objetivo/cantidad/fondos validados; sin RNG. No cambia nivel, EXP, repertorio, ID ni equipable; el que se devolvió al caer sigue en bolsa.
- Todo el equipo KO mantiene derrota definitiva y no permite Revivir. UI compra aparte de las tres ofertas, muestra bolsa, botón en miembro debilitado, mensaje de50% y texto sin permanencia para bajas individuales. Pociones posteriores permitidas. KantoStore1–9, módulos/datos1–8 congelados. godot:test:revive, regresión8 y QA de compra/uso/replay en fuente/ejecutable. Ver docs/SPRINT_14_REVIVE.md. Paquete0.14.8 fuera de Git; no iniciar15 ni publicar.

## Revisión vigente — 0.14.9

- traits_study hereda gym_study, conserva crecimiento de PS y cap14. member_stats aplica naturaleza/mint a cinco atributos; nunca PS. Asignación separada por seed/id, traitsAssigned, nature, mint, abilitySlot. Evoluciones preservan campos/slot y resuelven pasiva de la nueva especie. Reparar movement ausente de75/76 solo en instancia10 con valor de74, sin editar catálogos publicados.
- traits_actions/battle comparten jugador/IA/previsión:13 pasivas activas, eventos legibles antes de resolver KO/cola, Static30% contacto con inmunidad eléctrica (Tierra susceptible), Mudar1/3 al terminar activación antes de residuales. Cabeza Roca evita coste de movimientos, nunca Vidaesfera/Autodestrucción. Robustez conserva1 PS desde máximo; rango/heal/resultado coinciden. Multiimpactos siguen agregados. Clorofila/Fuga visibles y pendientes de clima/huida; sin ocultas.
- traits_run extiende revive_run: edición10,21 mentas100 y cápsula150, tienda/miembros vivos, vista previa, sin consumo inválido ni equipable ocupado. Clases/datos1–9 congelados; kanto_store1–10. Nueva campaña para10 con copia anterior. Datos propios traits.json/provenance e import-traits.py (7 CSV fijados), sin red al jugar. godot:test:traits y test:traits:journey; QA fuente/ejecutable y laboratorio. Ver docs/SPRINT_14_TRAITS.md. Paquete0.14.9 fuera de Git; no iniciar15 ni publicar.


## Sprint15 — 0.15.0

- scale_run/battle/maps y terrain_movement, edición11. Mapas16/24 con despliegue comparable; Dijkstra único por unidad. Alturas, visión, acercamientos y empujes comparten reglas con IA/previsión. new_round excluye vigía y lo activa como máximo en3; nunca intercala turno. No aumentar daño/precisión por altura ni añadir rescate/salida sin decisión.
- isometric_board extiende board; fábrica/consulta de rutas en UI mantiene laboratorio y clásicos cenitales. Cámara no consume órdenes/RNG. Rectificar conserva solo movimiento. Fuentes/sprites existentes sin cambios.
- QA nueva godot:test:scale/qa:scale/qa:scale:export. QA campaña anterior se fija explícitamente en10 al elegir inicial bajo --campaign-qa-dir, aislada de QA11. Todas las pruebas con guardados fuera de user real. Mantener versiones1–10, nuevo replay11; no regenerar fixtures. Informe docs/SPRINT_15.md. Arte/ritmo humanos pendientes; no iniciar16 ni publicar.


## Vista0.15.1

- Misma edición11, sin migrar ni exigir campaña nueva. isometric_board cachea bounds alfa por frame/especie para apoyar y seleccionar el sprite; conservar PNG/metadatos originales. Coordenadas lógicas intactas. Bases y marcadores son presentación.
- track_turn encuadra al iniciar y solo corrige margen con seguimiento automático; pan/zoom/Mapa son manuales hasta Unidad/Combate. Guías G/H no modifican estado. Camera_order devuelve foco al tablero.
- QA escala distingue encuadre de combate y vista general, prueba clic en sprite y pies/guías. Pruebas de motor/replay conservan resultados0.15.0. Informe docs/SPRINT_15_VIEW.md; no iniciar16.


- Sprint16 autorizado el19 de octubre:0.16.0/edición12, roster_run hereda11 sin alterar sus reglas. Usuario confirma PC ilimitado/seis plazas (incluidos debilitados), cambios gratuitos fuera del combate sin curación y derrota aunque haya reservas vivas. Captura sobrante al PC; deposit/withdraw/swap conservan miembro completo y equipable, siempre al menos un activo en pie. Reservas no se despliegan ni reciben EXP; objetos/movimientos respetan restricciones anteriores. Stock considera todos los poseídos. PC paginado en UI solo mapa/tienda/complete; consulta bloqueada para cambios en capture/defeat. Replay1–12, anteriores sin migrar; Nueva campaña preserva copia. Ver docs/SPRINT_16.md, test:roster y qa:roster fuente/.exe. No ampliar Kanto ni rebalancear ni iniciar17 automáticamente. Reutiliza recursos locales y hashes; sin dependencias/activos nuevos.


- Encargo19 de octubre «continua con todo»: autoriza17–22 con commits/push separados; publicación pública sigue aplazada. Sprint17 nativo0.17.0/edición13 añade18 encuentros hastaSurge, snapshot journey-17, catálogo151/211 movimientos y transición explícita desde12 con copia/diario. JourneyRun/Store y ExpandedStudy/Battle/Actions/Maps; no modificar sus resultados publicados sin edición/gating. Repertorios/encuentros LGPE unidos, entrenadores/historia Rojo; MO narrativas y desvíos con requisitos. Curativos nuevos200/todos PS120/200 ₽, piedras/Cable80; equipos y PS conservados.49/78 habilidades activas, pendientes señaladas; efectos complejos descritos como adaptaciones. Nuevos recursos originales, autores/hashes en expedition-provenance; rootCREDITS congelado. Ver DESIGN_KANTO_FULL y SPR17; continuar18–22 autorizado en este encargo. No delegación automática ni despliegue público.

- Sprint18 cerrado0.18.0/edición14:28 encuentros hastaErika/Fuji, hitos Scope/Flauta/Agua Fresca y cola desplazable. Snapshot18 conserva17; transición13→14 explícita con copia. Fuente/.exe6200 aserciones idénticas y recorrido5140, sin fallos. Ver docs/SPRINT_18.md. Continúan19–22 autorizados; sin despliegue público.

- Sprint19 cerrado0.19.0/edición15: Fucsia, Azafrán y sur de Kanto; snapshot19, transición y diario preservados. Recorrido11613 y UI fuente/.exe12544 sin fallos. Ver docs/SPRINT_19.md. Continuar hasta22 autorizado; sin despliegue público.

- Sprint20 cerrado0.20.0/edición16: Liga y rival; snapshot20, transición y diario preservados. Recorrido12273 y UI fuente/.exe4009 sin fallos. Ver docs/SPRINT_20.md. Continuar hasta22 autorizado; sin despliegue público.

- Sprint21 cerrado0.21.0/edición17: Finales legendarios; snapshot21, transición y diario preservados. Recorrido10729 y UI fuente/.exe895 sin fallos. Ver docs/SPRINT_21.md. Continuar hasta22 autorizado; sin despliegue público.

- Sprint 22: entrega técnica 0.22.0/edición 18, combate 17/snapshot 21 conservados. Actualización de finales, guardado 16 MB/futuras ediciones y paleta 24 comprobados. 29 simulaciones sin errores, derrotas incluidas; sin rebalanceo general. Fuente/.exe 898 aves 16 y 510 origen 24 iguales; paquete offline y guía. Pruebas humanas/publicación pendientes;49/78 habilidades activas, terreno provisional. Encargo 17–22 entregado técnicamente; ver docs/SPRINT_22.md. No iniciar nuevos cambios de balance ni publicar por haber documentado propuestas.

- Revisión UI0.22.1, rama codex/sprint-22-ui: Inicio nativo (sin autoload/escena adicional), pausa al volver, Continuar frío/caliente y cancelación de Oak preservada. Tienda por categorías/continuar fijo, retratos/barras de PS, fichas y tema revisados. Mismo motor18/combate17; estado completo de ambos finales idéntico0.22.0. UI fuente/.exe58, aves898 y origen510; regresión PC540/escala980,65 advertencias antiguas/0nuevas. QA aislada en work/qa-sprint-22-ui; paquete0.22.1. Sin plugins/activos nuevos ni publicación. Ver docs/SPRINT_22_UI.md.

- Controles0.22.2: input_profile crea acciones tactics_* y conserva alternativas GUI de seguridad; controles locales en controls.json, nunca campaña/RNG. controls_dialog captura desde hijo del Window (viewport propio); dialog_input protege entrada/cancelación; focus_memory restaura función/ID y scroll. F2/F6, etiquetas dinámicas y antirrepetición. Prompt01 de mejora, misma campaña18/combate17. QA input59 y preferencias13 en procesos separados; fuente/ejecutable aislados en work/qa-sprint-22-controls. Ver docs/SPRINT_22_CONTROLS.md. Prompts02–09 pendientes; sin soporte de lector de pantalla validado, plugins o activos nuevos.

- Turno contextual0.22.3: prompt02 aplicado sobre controles0.22.2. Elegir habilidad nunca ejecuta; Q/E selecciona objetivos legales, Enter/clic acepta; modos Rápido/Seguro persistentes con confirmación de aliados/autocoste letal. F/flechas/Enter orientan; R conserva límites. Cámara cruceta/Alt+flechas/P y umbral de arrastre; hover respeta teclado. Campaña18/combate17 y reglas/datos congelados. Ver docs/SPRINT_22_CONTEXT.md, QAcontext nativa aislada; siguiente prompt03, no encadenar03–09 ni publicar.

- Encargo20 de octubre «hazlo todo»: autoriza completar prompts03–09 de accesibilidad con entregas/commits separados. Sustituye el límite anterior de no encadenar. Publicación y pruebas humanas siguen pendientes; sin delegación automática. Inspección0.22.4 entregada; continuar04–09.


## Cierre de mejoras0.22.10

El encargo «hazlo todo» del20 de octubre completa técnicamente prompts03–09 con commits separados en codex/accessibility-complete. Ver docs/SPRINT_22_ACCESSIBILITY_COMPLETE.md (desde godot: ../docs/). Inspección, preferencias, cantidades, PC/biblioteca, práctica y acceso textual; motor18/17 y datos/snapshots intactos.09 prepara kit humano sin participantes; lector audible/usuario y DPI físicos pendientes. No delegación automática, publicación ni balance nuevos.


## Rendimiento0.22.11

Solicitud21 de octubre: corregir ralentizaciones. UI/representación solamente; campaña18/combate17, core/data/snapshots y guardados conservados. Tema con escrituras condicionales, previsión por contexto del cursor, semántica agrupada y terreno/minimapa con órdenes de dibujo conservadas. Invalidar geometría por mapa/cámara/HUD y marcas por cursor/alcance; preservar paredes y orden del pintor. QA específica de rendimiento y regresiones nativas, perfiles aislados; ver ../docs/SPRINT_22_PERFORMANCE.md. No delegación automática, publicación o balance nuevos.


## Semillas0.22.12

Solicitud21 de octubre: aventuras nuevas con semillas variables para variar capturas. El sorteo publicado ya usa semilla; se sustituye el valor inicial fijo de UI por generación local independiente, campo editable, Generar otra y Copiar en Oak, y copia desde Menú. Vacío genera semilla nueva; continuar/cancelar Oak preserva estado y azar. Misma semilla y decisiones reproducen; tablas/duplicados/insignias conservados. QA específica64 sondeos y dos combates naturales, perfiles aislados; ver ../docs/SPRINT_22_SEEDS.md. Core/data/snapshots congelados; sin delegación automática o publicación.


## Interfaz de juego0.22.13

Solicitud21 de octubre: integrar mejor la interfaz y mejorar los botones. Tema nativo compartido con variantes para órdenes, herramientas, pestañas y avance; cursor sin procesamiento continuo, menú claro y franja inferior compartida con PS/PT. Mantener controles reales, alto contraste y escalas100/125/150; reservar tablero sin solapamientos y conservar las cachés de rendimiento. Campaña18/combate17, core/data/snapshots y recursos originales congelados. Ver ../docs/SPRINT_22_GAME_UI.md. Sin delegación automática, publicación ni balance nuevos.


## Hub y tienda 0.22.14

Solicitud del 22 de octubre: reducir explicaciones y confusión. UI para edición 12+ con Comprar / Equipo y bolsa, cuatro categorías (Medicina, Evolución, MT y equipo, Rasgos), detalles por Ficha/Objetos/Movimientos/Rasgos y cantidades con contexto explícito. Bolsa con acciones para objetos poseídos; progreso y EXP en Resumen, avance fijo y ayuda conservada. F6, foco, escalas 100/125/150 y contraste; versiones anteriores conservan controles. Misma campaña 18/combate 17, core/data/snapshots y recursos congelados. Ver ../docs/SPRINT_22_HUB.md. Sin delegación automática, publicación o cambios de balance.


## Dirección visual 0.22.15

Solicitud del 22 de octubre: dirección profesional con arte nuevo provisional, sin generar imágenes. Cuaderno de Kanto, 45 slots/42 requeridos y 3 de promoción opcional, manifiesto en art/, registro con caché, escenas/terrenos/obstáculos/efectos/iconos conectados. Prompts completos y contratos; instalador verifica PNG/CRC/alfa/máscara 5:3 y conserva copia. Metadatos/icono Windows de versión 15. Publicación y arte final pendientes; no declarar ilustraciones terminadas. Campaña 18/combate 17, core/data/snapshots y recursos de terceros congelados; sin delegación automática o servicios nuevos. Ver ../docs/SPRINT_22_ART.md, ../docs/PROMPTS_ARTE_FINAL.md.


## Arte generado 0.22.16

Solicitud del 22 de octubre: producir e insertar las imágenes. 42 recursos del juego generados con image_gen e integrados; 3 promocionales opcionales pendientes. Procedencia/prompts/hashes en godot/art/generated-provenance.json (art/ desde Godot), dimensiones y alfa validados. Misma campaña18/combate17, reglas/datos/snapshots y sprites originales conservados. Ver docs/SPRINT_22_GENERATED_ART.md (../docs/ desde Godot). Publicación pública sigue aplazada.


## Animaciones y sonidos 0.22.17

Encargo del 23 de octubre: secuencias de ataque de hasta 0,64 s, variantes de los 18 tipos y 26 sonidos con jsfxr existente. Solo presentación; campañas 18/17, core/data/snapshots y balance congelados. Cancela al navegar, sin callbacks que modifiquen el juego; movimiento reducido, silencio y volumen conservados. Procedencia en godot/assets/combat/manifest.json (assets/ desde Godot); QA específica attack-effects en desarrollo/EXE y comparación de estados. Ver docs/SPRINT_22_ATTACK_EFFECTS.md (../docs/ desde Godot). Sin publicación pública ni delegación.


## Movimientos espaciales 0.23.0

Auditoría aprobada aplicada al catálogo actual: campaña19/combate18 en nuevos spatial_*.gd y data/spatial.json. No modificar reglas/datos/fixtures publicados para cambiar ediciones anteriores. La actualización es explícita entre encuentros, con copia y replay por edición; un combate pendiente conserva su motor. Fuente de decisiones y límites: ../docs/SPRINT_23_SPATIAL.md; tabla aplicada en ../docs/reports/moves-2026-10-24/aplicacion-0.23.csv.

Formas y zonas comparten geometría/visión/alturas con IA y previsión; aliados pueden recibir áreas. Aim de suelo canónico incluye x/y/axis/throwFacing; target se conserva para validación antigua. Cursor/VFX/audio sin PRNG. No rectificar consecuencias de zona ni tiradas. Pantallas2 rondas completas, controles nuevos1 activación, sueño de áreas1; daño/PT provisionales, sin afirmar balance cerrado.40 muestras WAV de PokeDot fijadas y acreditadas, incluida Hiperrayo; no atribuir licencia del código al audio. Sin red al jugar. Sin delegación automática ni publicación; commit/push privado autorizado.


## Corrección visual 0.23.1

Ranuras de Equipo → Movimientos: GridContainer y botones expanden ambas columnas; no alterar reglas por un fallo de presentación. Campaña19/combate18 y guardados conservados. QA específica qa_moves, texto 100/125/150 y tres resoluciones, desarrollo/EXE, ratón/teclado y cancelación sin órdenes. Ver ../docs/FIX_MOVES_0.23.1.md. Sin delegación ni publicación pública; commit/push privado autorizado.


## Progresión y gimnasios 0.24.0

Encargo del24 de octubre: nueva campaña20/combate18 en economy_study/battle/run/store, economy.json y journey-24.json. Preservar motores/datos/tests publicados anteriores; transición explícita19→20 fuera de combate, conserva niveles/PS, proporción de barra EXP y reembolsa25/80 ₽ por consumibles retirados. Curvas PokéAPI por especie; train-xp cobra1 ₽ por EXP restante, cotización validada y cap. Sin Caramelos/piedras/cables utilizables; evoluciones normales automáticas, antiguas de objeto/intercambio gratis y voluntarias por umbrales adaptados desde Ficha, ramas de Eevee elegibles. Reroll previo a captura común60/120/180…, distinta especie si hay alternativas, mismo nivel/ID; insignias fijas. Líderes4–6, encuentros/recompensas reajustados. Sin delegación ni publicación pública; commit/push privado autorizado. Ver ../docs/SPRINT_24_ECONOMY.md. No declarar balance cerrado ni campaña20 completa: muestras naturales alcanzan hasta3 medallas y contienen derrotas; los ocho sondeos de gimnasios son sintéticos.

## Fluidez 0.24.1

Planificador cooperativo de presentación turn_planner.gd para combate18: mismos candidatos/puntuaciones/desempates publicados, peligro una vez por destino, presupuesto orientativo3 ms. Modal pausa; refresco invalida. Previsiones espaciales por estado/acción/coordenadas/orientación; sin PRNG ni cambios de dominio. Core/data/tests y guardados conservados. QA fluency compara93 decisiones, recorrido natural y scheduler real de UI; desarrollo y EXE. Preservar cachés de terreno, navegación y guardado antes del feedback. Ver ../docs/PERFORMANCE_0.24.1.md. Sin delegación ni publicación pública; commit/push privado autorizado.


## Aventura táctica 0.25.0

Encargo25 de octubre: implementar todas las mejoras propuestas. Campaña21/combate19 mediante adventure_*.gd, adventure.json; tablas24 heredadas y módulos publicados congelados. Despliegue guardado sin RNG, B para iniciar, T amenazas geométricas cooperativas, F9 tarjeta/códigoKT25 local. Ocho arenas, objetivos Rocket/Fuji/Calle Victoria, IA sin bonificaciones, recuperación50% a debilitados desplegados sin revivir/25% por nivel rezagado hasta100%, descuento25% a partir de3 niveles bajo media, caps. Ruta1 introductoria con básico rival. Agua/fuego/seda con previsión y feedback. Portales solo si salida libre, no rectificables. Actualización voluntaria20→21 conserva EXP exacta;12–19 pasan conversión20 dentro de la transacción y con diario mixto. Pruebas/alcance en ../docs/SPRINT_25_TACTICAL.md. No afirmar balance ni campaña21 completa:2/6 muestras llegan a superar Brock, resto derrotas retenidas; gimnasios tardíos sintéticos. Mantener cachés, controles, guardado antes de feedback. Sin delegación ni publicación pública; commit/push privado autorizado.


## Presentación para jugadores 0.26.0

Sprint26: conservar campaña21/combate19, códigoKT25 y reglas. Opciones de partida plegadas en Oak, semilla automática, ayuda por edición y move_info/move_diagram compartidos. Las consultas no consumen azar; las semillas inválidas se rechazan antes de sustituir guardados. Ver ../docs/SPRINT_26_PLAYER.md. QA específica player y regresiones de interfaz en fuente/EXE; APPDATA/LOCALAPPDATA aislados en el ejecutor. Sin recursos externos ni delegación/publicación. No iniciar perfil27, tienda28 o repertorios29 automáticamente.
