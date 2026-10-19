# Pokémon Tactics — Kanto Windows0.17.0

Campaña offline de Paleta a Carmín:18 encuentros, tres gimnasios, Bill, rival, S. S. Anne y desvíos de Ruta11/Cueva Diglett/Ruta22. Sin exploración libre ni puzzles completos: los hitos se resumen entre tableros. El resto de Kanto sigue en las entregas18–22.

## Jugar y continuar

Abre PokemonTactics.exe; no necesitas editor, Node, cuenta ni servidor. Elige inicial de Oak en una campaña nueva. Si vienes de0.16, carga tu partida y pulsa **Continuar aventura · ampliar Kanto** desde mapa/tienda/final. Conserva equipo, PS, movimientos, rasgos, bolsa, dinero, diario y una copia previa. Un combate pendiente conserva sus reglas hasta finalizar. Ediciones anteriores siguen siendo legibles y no se convierten automáticamente.

Guardado local: `%APPDATA%/PokemonTacticsLab/kanto-save.json`. Cada orden aceptada se guarda antes de presentarse. Diario con checksum, copia y detección de otra instancia. Esquema kanto-journey, edición13 y transición explícita entre motores; hasta50000 órdenes. No borres un guardado para actualizar. Laboratorio y versión web conservan archivos y reglas independientes.

## Reglas

- Hasta seis plazas de equipo, incluidos debilitados. Capturas sobrantes al PC sin límite. Cambios gratuitos fuera del combate, sin curar; cada Pokémon conserva su equipable. Perder un combate termina la campaña aunque haya reservas vivas.
- Cuatro movimientos preparados más básico neutro sin tipo ni STAB. Preparación gratis, aprendizaje por nivel y MT consumibles. Cola por velocidad en rondas; movimiento y acción en ambos órdenes, orientación final y aliados atravesables.
- Tipos modernos, STAB, precisión propia del movimiento, daño por banda según frente/costado/espalda y crítico adicional por espalda. Estados y etapas temporales de tres activaciones. Parálisis reduce el movimiento; no la iniciativa ni la acción.
- Niveles y EXP; Caramelo25 ₽/+1 nivel. Evolución por nivel; piedras/Cable Vínculo80 ₽ según especie. Pikachu20 y Graveler36 siguen adaptados. Subir cura el aumento de PS máximos; piedras no curan ni reviven. Cap del insignia pendiente:14/21/24 en este tramo.
- Curativos solo fuera del combate, en tienda. Revivir150 ₽/50% PS; Hiperpoción120 ₽/+200 PS; Poción Máxima200 ₽/todos los PS. Sin curación gratuita entre encuentros. Precios de prueba.
- Tres ofertas MT/equipables y rerolls25/50/75… por visita. Un equipable por miembro. Las ofertas consideran también las reservas.
- Gimnasios: medalla, dinero y captura del insignia de mayor nivel. Otras recompensas usan la zona salvaje indicada. Un premio por encuentro, sin repetir zonas para farmear.
- Grafo de destinos con requisitos: Bill/billete, rival del barco/Corte y medallas. Puedes elegir desvíos cuando están disponibles. Las MO no ocupan movimientos tácticos.

Catálogo151,79 familias y211 movimientos, con repertorios/compatibilidad de Let’s Go Pikachu/Eevee combinados. No se ofrecen formas regionales ni movimientos exclusivos de iniciales especiales. Tipos/estadísticas modernas y equipos de entrenadores de Rojo. Alcance, PT y varios efectos complejos son adaptaciones descritas en ficha.49 de78 habilidades normales producen efectos; las restantes se identifican como pendientes o sin condiciones aplicables (clima, huida, género u otras interacciones ausentes). No se presenta como réplica exacta de un cartucho.

## Controles

Clic en casilla azul: movimiento directo; clic en rival: básico. Habilidades en menú dentro del tablero. R rectifica exclusivamente movimiento antes de actuar; F orienta y termina. Flechas/Enter y Escape disponibles. Rueda/+/- zoom, botón central cámara, C unidad, Combate/Mapa encuadre, G/H guías. Las casillas vacías alcanzables siguen seleccionables aunque un sprite grande las tape parcialmente.

Isometría16/24, alturas0–2, subida+1 y salto terrestre1; voladores ignoran desnivel. Altura limita alcance/visión, sin bono de daño. Grupos tardíos se incorporan por proximidad/daño o ronda3. Arte de terreno provisional; retratos/sprites originales locales. Ninguna descarga al jugar.

## Desarrollo

Godot4.7.2 estándar. Recursos existentes, sin plugins nuevos. Importadores explícitos import-expedition.py y build-expedition.py; no regenerar manifiestos congelados para ocultar discrepancias. Pillow existente se localiza con PYTHONPATH=../../work/balance-python solo al importar. Los builds/juego no lo necesitan.

Scripts de la raíz: godot:verify, godot:prepare, godot:test:expedition, godot:test:journey, godot:test:abilities, godot:qa:journey, godot:export y godot:qa:journey:export. QA usa archivos aislados, controles/eventos de tablero y comparación con el dominio; no sustituye valoración humana de diversión/balance. Evidencia en docs/SPRINT_17.md. Paquetes fuera de Git en outputs/releases/pokemon-tactics-0.17.0. Publicación pública aplazada.
