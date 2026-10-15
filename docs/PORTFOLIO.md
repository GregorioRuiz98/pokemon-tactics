# Pokémon Tactics — caso de proyecto

Prototipo de roguelike táctico desarrollado por Gregorio Ruiz con asistencia de IA. Público: fans de Pokémon y estrategia por turnos. Objetivo: combinar lectura del tablero y construcción de equipo con progresión de una partida; la difusión es una aspiración, no un resultado medido.

La aportación propia está en el diseño y adaptación de reglas, arquitectura de dominio, política táctica, generación de ruta, progreso/economía, guardado versionado, interfaz integrada y pruebas reproducibles. El creador aportó las referencias, decisiones de producto y feedback; la implementación y parte de las verificaciones se realizaron con Codex. No se atribuyen como propios los personajes, datos, tipografía ni sprites.

Decisiones: estado serializable separado de POO; acciones compuestas y compartidas; evoluciones como datos; semilla/RNG sin consumo durante previsiones; una edición de reglas por partida para conservar rutas antiguas; recursos locales con hashes y créditos. Se priorizó un recorrido completo y dos finales sobre cubrir toda la Pokédex.

Resultados verificables: 28 especies importadas, nueve evoluciones seleccionadas, dieciséis mapas temáticos y dos finales. Dos campañas completas recorridas mediante UI en Edge, guardado comparado después de cada transacción/orden, recarga en combate y regresiones de prototipos. Detalles y límites en `SPRINT_11.md`. No hay métricas de usuarios, retención o viralidad, ni feedback externo todavía.

Material real: [captura de las aves](portfolio/final-aves.png), [tablero](portfolio/tablero.png), [vídeo breve de interfaz](portfolio/demo.webm). El vídeo muestra un ensayo con equipo predefinido; no se presenta como una partida humana completa. Código: repositorio privado del creador; publicación de la web aplazada.

Recursos: Phaser/template-vite-ts (MIT), EasyStar (MIT), SpriteCollab (CC BY-NC 4.0, con derechos subyacentes de Pokémon), PokéAPI, Pixelify Sans (OFL) y jsfxr/RIFFWAVE (dominio público). Autores, revisiones y licencias concretas en `CREDITS.md`, `public/licenses` y los manifiestos. No se afirma autorización de los titulares de Pokémon.
