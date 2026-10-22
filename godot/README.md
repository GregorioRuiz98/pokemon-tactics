# Pokémon Tactics — Kanto Windows0.22.15

Dirección visual 0.22.15: escenarios, suelos, iconos y efectos conectados a placeholders sustituibles. Ver [arte y estado](../docs/SPRINT_22_ART.md) y [prompts](../docs/PROMPTS_ARTE_FINAL.md). Los PNG finales requieren importar/exportar; no basta con copiarlos junto al EXE.

Hub 0.22.14: Comprar y Equipo y bolsa separados; elige Pokémon y después Ficha, Objetos, Movimientos o Rasgos. Seguir viaje queda fijo. Ver [simplificación](../docs/SPRINT_22_HUB.md).

Interfaz0.22.13: menú táctico sobre papel, cursor de selección y franja inferior con recursos y previsión; inicio, Oak, tienda y PC comparten el nuevo estilo. Ver [interfaz](../docs/SPRINT_22_GAME_UI.md).

Campaña Kanto completa hasta la Liga y dos desafíos legendarios alternativos. Los acontecimientos y puzzles se resumen entre tableros; sin exploración libre. Ver informe para límites de la entrega.

Cada aventura recibe una semilla nueva. Puedes editarla o generar otra con Oak y copiarla para repetirla. Durante la aventura, Menú → Copiar semilla de la campaña recupera la original. Misma semilla y decisiones conservan el mismo azar; los sorteos siguen las tablas locales y los gimnasios dan su insignia. Ver [semillas](../docs/SPRINT_22_SEEDS.md).

## Jugar y continuar

Abre PokemonTactics.exe; no necesitas editor, Node, cuenta ni servidor. Elige inicial de Oak en una campaña nueva. Si vienes de0.16/0.17, carga tu partida y pulsa **Continuar aventura · ampliar Kanto** desde mapa/tienda/final. Si ya terminaste un final legendario, **Actualizar versión · conservar final** mantiene ese desenlace. Conserva equipo, PS, movimientos, rasgos, bolsa, dinero, diario y una copia previa. Un combate pendiente conserva sus reglas hasta finalizar. Ediciones anteriores siguen siendo legibles y no se convierten automáticamente.

Guardado local: `%APPDATA%/PokemonTacticsLab/kanto-save.json`. Cada orden aceptada se guarda antes de presentarse. Diario con checksum, copia y detección de otra instancia. Esquema kanto-journey, edición18 y transición explícita entre motores; hasta50000 órdenes/16 MB. No borres un guardado para actualizar. Laboratorio y versión web conservan archivos y reglas independientes.

## Reglas

- Hasta seis plazas de equipo, incluidos debilitados. Capturas sobrantes al PC sin límite. Cambios gratuitos fuera del combate, sin curar; cada Pokémon conserva su equipable. Perder un combate termina la campaña aunque haya reservas vivas.
- Cuatro movimientos preparados más básico neutro sin tipo ni STAB. Preparación gratis, aprendizaje por nivel y MT consumibles. Cola por velocidad en rondas; movimiento y acción en ambos órdenes, orientación final y aliados atravesables.
- Tipos modernos, STAB, precisión propia del movimiento, daño por banda según frente/costado/espalda y crítico adicional por espalda. Estados y etapas temporales de tres activaciones. Parálisis reduce el movimiento; no la iniciativa ni la acción.
- Niveles y EXP; Caramelo25 ₽/+1 nivel. Evolución por nivel; piedras/Cable Vínculo80 ₽ según especie. Pikachu20 y Graveler36 siguen adaptados. Subir cura el aumento de PS máximos; piedras no curan ni reviven. Cap del insignia pendiente:14/21/24/29/43/43/47/50; después65 para la Liga y75 para el postgame.
- Curativos solo fuera del combate, en tienda. Revivir150 ₽/50% PS; Hiperpoción120 ₽/+200 PS; Poción Máxima200 ₽/todos los PS. Sin curación gratuita entre encuentros. Precios de prueba.
- Tres ofertas MT/equipables y rerolls25/50/75… por visita. Un equipable por miembro. Las ofertas consideran también las reservas.
- Gimnasios: medalla, dinero y captura del insignia de mayor nivel. Otras recompensas usan la zona salvaje indicada. Un premio por encuentro, sin repetir zonas para farmear.
- Grafo de destinos con requisitos: Bill/billete, rival del barco/Corte y medallas. Puedes elegir desvíos cuando están disponibles. Las MO no ocupan movimientos tácticos.

Catálogo151,79 familias y211 movimientos, con repertorios/compatibilidad de Let’s Go Pikachu/Eevee combinados. No se ofrecen formas regionales ni movimientos exclusivos de iniciales especiales. Tipos/estadísticas modernas y equipos de entrenadores de Rojo. Alcance, PT y varios efectos complejos son adaptaciones descritas en ficha.49 de78 habilidades normales producen efectos; las restantes se identifican como pendientes o sin condiciones aplicables (clima, huida, género u otras interacciones ausentes). No se presenta como réplica exacta de un cartucho.

Respiro, Recuperación, Amortiguador y Descanso tienen cinco usos por combate, además de sus PT. Los usos se muestran en el menú y no se restablecen cada ronda. Los finales excluyentes nunca conceden legendarios.

## Controles

Clic en casilla azul: movimiento directo; clic en rival: básico. Habilidades en menú dentro del tablero. R rectifica exclusivamente movimiento antes de actuar; F orienta y termina. Flechas/Enter y Escape disponibles. Rueda/+/- zoom, botón central cámara, C unidad, Combate/Mapa encuadre, G/H guías. Las casillas vacías alcanzables siguen seleccionables aunque un sprite grande las tape parcialmente.

Isometría16/24, alturas0–2, subida+1 y salto terrestre1; voladores ignoran desnivel. Altura limita alcance/visión, sin bono de daño. Grupos tardíos se incorporan por proximidad/daño o ronda3. Arte de terreno provisional; retratos/sprites originales locales. Ninguna descarga al jugar.

## Desarrollo

Godot4.7.2 estándar. Recursos existentes, sin plugins nuevos. Importadores explícitos import-expedition.py y build-expedition.py; no regenerar manifiestos congelados para ocultar discrepancias. Pillow existente se localiza con PYTHONPATH=../../work/balance-python solo al importar. Los builds/juego no lo necesitan.

Scripts de la raíz: godot:verify, godot:prepare, godot:test:expedition, godot:test:journey, godot:test:abilities, godot:qa:journey, godot:export y godot:qa:journey:export. QA usa archivos aislados, controles/eventos de tablero y comparación con el dominio; no sustituye valoración humana de diversión/balance. Evidencia en docs/SPRINT_22.md. Paquetes fuera de Git en outputs/releases/pokemon-tactics-0.22.10. Publicación pública aplazada.

Prueba manual: [guía Windows](../docs/PLAYTEST_WINDOWS.md). Balance y propuestas: [informe de29 simulaciones](../docs/reports/balance-native-0.22/INFORME.md). No se cambian parámetros para favorecer los ensayos.

Inicio, tienda por categorías y fichas revisadas en0.22.1: [informe y comprobaciones](../docs/SPRINT_22_UI.md).

Controles y navegación0.22.2: F2 abre reasignación, F6/Mayús+F6 cambia panel; foco conservado en selección/compras/PC y prevención de órdenes repetidas. Las asignaciones se guardan en controls.json fuera del diario de partida. Enter/Espacio, Escape, Tab y flechas permanecen como seguridad. Sin cambios a reglas, balance o formatos de campaña. [Informe](../docs/SPRINT_22_CONTROLS.md). Pruebas nuevas: godot:test:controls, godot:qa:input y godot:qa:input:export.

Turno contextual0.22.3: seleccionar una habilidad ya no la ejecuta; Q/E elige objetivo, Enter acepta y Escape vuelve. F abre orientación con flechas/Enter. Cámara por cruceta, Alt+flechas o modo P; central opcional. Modo Rápido/Seguro persistente en F2. [Informe](../docs/SPRINT_22_CONTEXT.md). Pruebas: godot:qa:context y godot:qa:context:export.


[Entrega0.22.10](../docs/SPRINT_22_ACCESSIBILITY_COMPLETE.md): I ficha, L resultado, F7 práctica, F4 glosario y F12 recuperar lectura. Opciones de texto/contraste y acceso textual experimental. Nuevos scripts godot:qa:updates, godot:qa:semantic y sus variantes :export; godot:test:shop-batch. Lector audible y sesiones humanas pendientes.
