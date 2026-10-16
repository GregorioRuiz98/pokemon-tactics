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
