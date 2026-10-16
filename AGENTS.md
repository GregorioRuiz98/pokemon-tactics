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
