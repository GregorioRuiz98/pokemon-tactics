# Pokémon Tactics

- Responder en español. Leer docs/PLAN_SPRINTS.md y el último informe antes de continuar.
- Encargo del 15 de octubre: completar todos los sprints pendientes con entregas separadas. No delegación automática. El usuario ha decidido **preparar versión y publicar después**; no desplegar, cambiar visibilidad ni comprar dominio.
- Versión 0.11.0, rama codex/sprint-11. Sprints 0–10D completos; 11 completado técnicamente con pruebas humanas pendientes. Preparación de publicación en 12.
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
- Actualizar informe, plan, versión y créditos con hechos. Verificar SHA remoto después del push; actualizar rama predeterminada a la última entrega comprobada. Subir código no publica la web ni cambia visibilidad.
- Usar GIT_CONFIG_GLOBAL=NUL y GIT_CONFIG_NOSYSTEM=1 por el entorno local. Preferir credential.helper=manager por comando. Nunca imprimir ni persistir tokens.
