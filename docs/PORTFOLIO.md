# Caso de proyecto — Pokémon Tactics

Juego táctico Windows desarrollado por Gregorio Ruiz con asistencia de IA. Para fans de Pokémon y estrategia por turnos. Aportación propia: adaptar reglas, progresión, decisiones de IA, guardado reproducible e interfaz; no se atribuyen personajes, sprites, datos ni audio original de terceros.

Pasó de prototipo web a campaña offline de 58 lugares,151 especies, ocho gimnasios, Liga y dos desafíos legendarios consecutivos. Godot 4.7.2, estado serializable, reglas compartidas por IA/previsión y ediciones de motor que conservan partidas antiguas. [Arquitectura](ARCHITECTURE.md) · [Reglas](REGLAS_ACTUALES.md).

## Evidencia y límites

Candidata1.0: campaña actual completada mediante7.865 órdenes legales automatizadas, con intentos fallidos conservados. Equipo → Ficha pasa de77,116 a10,725ms de mediana en el ensayo local; Movimientos de78,291 a45,253ms. [Medición y límites](SPRINT_37_USABILITY.md). Interfaz 0.34.1:4.548 comprobaciones fuente/EXE, con previas de los 58 lugares. [Estado/resultados](PLAN_SPRINTS.md).

Sin métricas públicas de usuarios, retención o viralidad. Jugadores externos y otro PC físico pendientes. El balance aceptado por el creador no equivale a validación pública.

Material actual: [menú](qa/sprint-34-ui-1/briefing-white-command-menu.png), [previa Brock](qa/sprint-34-ui-1/briefing-map-brock.png), [ficha rival](qa/sprint-34-ui-1/briefing-before-combat-details.png). Brock es un fixture de presentación; menú/ficha inicial proceden de la prueba de apertura. El [vídeo antiguo](portfolio/demo.webm) es del prototipo web, no de Windows.

[Procedencia/licencias](LICENCIAS.md). Publicación pendiente; repo privado del creador. [Caso web anterior](history/PORTFOLIO_WEB_2026-10-27.md).
