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
