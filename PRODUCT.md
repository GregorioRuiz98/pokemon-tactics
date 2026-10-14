# Pokémon Tactics

<!-- impeccable:product-schema 1 -->

## Platform

web. Objetivo inicial: PC y navegador local; publicación posterior en web propia.

## Users

Fans de Pokémon y RPG tácticos. El creador prueba el loop en local y después lo comparte para recoger feedback. El proyecto forma parte de su portfolio.

## Product Purpose

Roguelike táctico por turnos contra la máquina, con control manual, equipos de hasta seis Pokémon de Kanto, evolución y objetos. Prioridades expresadas: diversión, calidad de portfolio y posibilidad de difusión.

## Operating Context

Una entrega por sprint; código subido a GitHub después de las comprobaciones. Los sprints 0 y 1 proporcionan catálogo, sprites, campamento y ensayo de movimiento. El sprint 2 permite un combate completo 3 contra 3. El sprint 3 incorpora POO, tipos, dos habilidades por especie, puntos tácticos, estados y dos composiciones fijas para comparar. El sprint 4 añade orientación final, precisión por ángulo, tránsito aliado, perfiles de terreno, áreas, empuje y ascuas. El sprint 5 incorpora tres compañeros aleatorios, seis encuentros conectados, PS y bajas persistentes, guardado local y resultado de partida. El sprint 6 incorpora tienda, reclutamiento, curación fuera de combate, equipables y hasta seis aliados. Experiencia y evoluciones permanecen en el plan.

## Capabilities and Constraints

Velocidad con variación de 5–10 % determina la cola de una ronda; una activación por unidad, desplazamiento y acción en ambos órdenes. Recursos locales. Reutilizar repositorios públicos con atribución y conservar las hojas originales. No hay cuentas, multijugador ni IA generativa durante el juego. Pokémon es un requisito del usuario; los legendarios quedan reservados para jefes en sprints posteriores.

POO solicitada por el usuario para facilitar la herencia de comportamiento. Base común de Pokémon y especializaciones con acciones compartidas; tipos dobles y evoluciones futuras como datos. Contrato en `docs/ARCHITECTURE.md`. El estado serializable sigue separado de las clases con comportamiento.

## Evidence on Hand

Decisiones confirmadas, backlog y valores provisionales en `docs/PLAN_SPRINTS.md`; código, recursos y comprobaciones en los informes de sprint. Los valores de daño, movilidad y salud de esta primera batalla son hipótesis de ensayo, no decisiones definitivas de balance.

El usuario pide aplazar el equilibrio hasta terminar las mecánicas y conservar parámetros y repertorios base del sprint 4. El sprint 6 incorpora economía, consumibles curativos fuera de combate, tres equipables y reclutamiento/sustitución hasta seis miembros. Objetos recuperados al caer o sustituir. La economía y efectos nuevos se prueban como mecánicas; no representan equilibrio definitivo. El sexto encuentro es provisional, sin los jefes legendarios previstos.

## Brand Commitments

El usuario ha pedido integrar las órdenes dentro del gameplay, con paneles de atacante/objetivo y previsión de ataque inspirados en la captura de RPG táctico aportada el 14 de octubre. Se adapta esa organización a Pokémon y al tablero en vista superior. La composición es una preferencia confirmada para las siguientes entregas.
