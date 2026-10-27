# Pokémon Tactics — Kanto Windows 0.33.0

**Referencia actual:** [reglas vigentes](../docs/REGLAS_ACTUALES.md), [pruebas y recuperación Windows](../docs/PLAYTEST_WINDOWS.md), [revisión0.33](../docs/SPRINT_33_REVIEW.md). Las notas por versión siguientes son historial.

**0.32.0:** climas de sol/lluvia/arena, treinta habilidades pendientes aplicadas, sexo persistente y mentas con atributos ↑/↓ antes de comprar. Tres técnicas climáticas y MT; auras y previsión integradas. Actualización voluntaria entre combates con copia. [Cambios y comprobaciones](../docs/SPRINT_32_CLIMATE.md).

**0.31.2:** subida de nivel en Equipo → Ficha; tienda sin pestaña Entrenar. Iconos locales de los 18 tipos y las categorías Físico/Especial/Estado en movimientos, combate y MT, con etiquetas y alto contraste. Mismos guardados, precios y reglas. [Entrega y procedencia](../docs/UI_SYMBOLS_0.31.2.md).

**0.31.1:** dormir bloquea movimiento y acción; al despertar vuelven las rutas. [Corrección y pruebas](../docs/FIX_SLEEP_0.31.1.md). Cargar0.31.0 aplica el arreglo con copia, incluso en combate.

**0.31.0:** PP al equipar, capacidad10–20 por nivel y técnicas de1–5 PP. Usarlas no gasta puntos. Atributos durante el combate y estados temporales; manantiales para curarlos. [Cambios, costes y comprobaciones](../docs/SPRINT_31_POWER.md). Partidas anteriores conservan reglas hasta actualizar entre encuentros, con copia.

**0.30.1:** textos resumidos en viaje, combate, equipo y tienda. Conserva cifras, objetivos, costes y consecuencias; controles y reglas tácticas disponibles en la ayuda. [Cambios y comprobaciones](../docs/FIX_TEXT_0.30.1.md). Mismos guardados y balance.

**0.30.0:**58 escenarios con geometría propia, recursos temáticos y alturas; sin roles predefinidos. Liga y rival → tres aves → tienda → Mew/Mewtwo. Campaña22/combate19; se conservan las cifras y las partidas anteriores. [Entrega y comprobaciones](../docs/SPRINT_30_KANTO.md).

**0.29.0:** perfil persistente y logros cosméticos, tienda Kecleon animada, combinaciones de movimientos por rol y recomendaciones de MT. Inicio con semilla automática; las opciones manuales son opcionales. [Cambios y comprobaciones](../docs/SPRINT_29_VARIETY.md). Campaña21/combate19 y guardados conservados.

[Entrega 0.25](../docs/SPRINT_25_TACTICAL.md): coloca aliados antes de actuar; B comienza, T alterna amenazas y F9 guarda tarjeta/código de reto desde el hub. Ocho arenas propias, tres misiones, recuperación de EXP y nuevos efectos de terreno. Actualiza una campaña anterior entre encuentros, con copia. Balance humano pendiente.

**0.24.1:** [mejoras de fluidez](../docs/PERFORMANCE_0.24.1.md): IA repartida entre fotogramas y caché de previsiones espaciales. Conserva decisiones, balance y guardados.

**Windows 0.24.0:** [progresión, capturas y gimnasios](../docs/SPRINT_24_ECONOMY.md). EXP por especie y entrenamiento por los puntos restantes; evoluciones sin objetos, reroll local pagado y líderes de4–6 Pokémon. Actualización explícita con copia, reembolso y conservación de niveles/PS. Balance provisional.

**0.23.1:** corregidas las ranuras de Equipo → Movimientos: nombres completos, columnas que ocupan el panel y selección con teclado/ratón. Conserva guardados y reglas. [Comprobaciones](../docs/FIX_MOVES_0.23.1.md).

**0.23.0:** [movimientos espaciales](../docs/SPRINT_23_SPATIAL.md): líneas, conos y otras áreas; zonas temporales, empujes/atracciones, pantallas y técnicas especiales. Habilidades apuntables al suelo, Q/E para girar pantallas/lanzamientos, VFX y 40 muestras originales de sonido. Actualiza la aventura entre encuentros para activar las reglas nuevas. Costes/daño de área provisionales.
Presentación anterior 0.22.17: [animaciones y sonidos](../docs/SPRINT_22_ATTACK_EFFECTS.md). Arte integrado desde 0.22.16: 42 imágenes generadas para escenarios, suelos, iconos y efectos. Ver [arte y estado](../docs/SPRINT_22_GENERATED_ART.md) y [prompts](../docs/PROMPTS_ARTE_FINAL.md). Los PNG finales requieren importar/exportar; no basta con copiarlos junto al EXE.

Hub 0.22.14: Comprar y Equipo y bolsa separados; elige Pokémon y después Ficha, Objetos, Movimientos o Rasgos. Seguir viaje queda fijo. Ver [simplificación](../docs/SPRINT_22_HUB.md).

Interfaz0.22.13: menú táctico sobre papel, cursor de selección y franja inferior con recursos y previsión; inicio, Oak, tienda y PC comparten el nuevo estilo. Ver [interfaz](../docs/SPRINT_22_GAME_UI.md).

La campaña actual recorre Liga y rival, las tres aves juntas y después Mew/Mewtwo. Los acontecimientos y puzzles se resumen entre tableros; sin exploración libre. Consulta las reglas vigentes para las diferencias respecto a las versiones históricas anteriores.

Cada aventura recibe una semilla nueva. Puedes editarla o generar otra con Oak y copiarla para repetirla. Durante la aventura, Menú → Copiar semilla de la campaña recupera la original. Misma semilla y decisiones conservan el mismo azar; los sorteos siguen las tablas locales y los gimnasios dan su insignia. Ver [semillas](../docs/SPRINT_22_SEEDS.md).

## Jugar y continuar

Abre PokemonTactics.exe; no necesitas editor, Node, cuenta ni servidor. Elige un inicial de Oak en una campaña nueva. Las partidas anteriores ofrecen **Actualizar revisión táctica** entre encuentros, con copia previa. Conserva equipo, PS, movimientos, rasgos, bolsa, dinero y diario. Un combate pendiente conserva sus reglas hasta finalizar. Ediciones anteriores siguen siendo legibles y no se convierten automáticamente. Consulta la guía Windows para recuperar una copia de la partida.

Guardado local: `%APPDATA%/PokemonTacticsLab/kanto-save.json`. Cada orden aceptada se guarda antes de presentarse. Diario con checksum, copia y detección de otra instancia. Esquema kanto-journey, edición19 y transición explícita entre motores; hasta50000 órdenes/16 MB. No borres un guardado para actualizar. Laboratorio y versión web conservan archivos y reglas independientes.

## Reglas vigentes

Consulta [REGLAS_ACTUALES.md](../docs/REGLAS_ACTUALES.md): PP al equipar sin gasto ni cinco usos de curación; atributos durante todo el combate; estados temporales; EXP restante desde Equipo → Ficha; sin caramelos, piedras ni cables utilizables. Liga/rival → aves → Mew/Mewtwo.214 técnicas,151 especies y78 habilidades normales aplicables. Las adaptaciones se detallan en ficha.

## Controles

Clic en casilla azul: movimiento directo; clic en rival: básico. Habilidades en menú dentro del tablero. R rectifica exclusivamente movimiento antes de actuar; F orienta y termina. Flechas/Enter y Escape disponibles. Rueda/+/- zoom, botón central cámara, C unidad, Combate/Mapa encuadre, G/H guías. Las casillas vacías alcanzables siguen seleccionables aunque un sprite grande las tape parcialmente.

Isometría16/24, alturas0–2, subida+1 y salto terrestre1; voladores ignoran desnivel. Altura limita alcance/visión, sin bono de daño. Grupos tardíos se incorporan por proximidad/daño o ronda3. Arte de terreno generado e integrado; retratos/sprites originales locales. Ninguna descarga al jugar.

## Desarrollo

Godot4.7.2 estándar. Recursos existentes, sin plugins nuevos. Importadores explícitos import-expedition.py y build-expedition.py; no regenerar manifiestos congelados para ocultar discrepancias. Pillow existente se localiza con PYTHONPATH=../../work/balance-python solo al importar. Los builds/juego no lo necesitan.

Scripts de la raíz para esta entrega: `godot:verify`, `godot:test:review`, `godot:qa:review`, `godot:qa:playthrough` y sus variantes `:export`, además de `godot:export` y `godot:package`. QA usa archivos aislados, controles/eventos de tablero y comparación con el dominio; no sustituye valoración humana de diversión/balance. El diario reproducible y los resultados están en docs/qa/sprint-33; el informe explica los intentos fallidos y los límites de las pruebas. Paquetes fuera de Git en outputs/releases/pokemon-tactics-0.33.0. Publicación pública aplazada.

Prueba manual: [guía Windows](../docs/PLAYTEST_WINDOWS.md). Balance y propuestas: [informe de29 simulaciones](../docs/reports/balance-native-0.22/INFORME.md). No se cambian parámetros para favorecer los ensayos.

Inicio, tienda por categorías y fichas revisadas en0.22.1: [informe y comprobaciones](../docs/SPRINT_22_UI.md).

Controles y navegación0.22.2: F2 abre reasignación, F6/Mayús+F6 cambia panel; foco conservado en selección/compras/PC y prevención de órdenes repetidas. Las asignaciones se guardan en controls.json fuera del diario de partida. Enter/Espacio, Escape, Tab y flechas permanecen como seguridad. Sin cambios a reglas, balance o formatos de campaña. [Informe](../docs/SPRINT_22_CONTROLS.md). Pruebas nuevas: godot:test:controls, godot:qa:input y godot:qa:input:export.

Turno contextual0.22.3: seleccionar una habilidad ya no la ejecuta; Q/E elige objetivo, Enter acepta y Escape vuelve. F abre orientación con flechas/Enter. Cámara por cruceta, Alt+flechas o modo P; central opcional. Modo Rápido/Seguro persistente en F2. [Informe](../docs/SPRINT_22_CONTEXT.md). Pruebas: godot:qa:context y godot:qa:context:export.


[Entrega0.22.10](../docs/SPRINT_22_ACCESSIBILITY_COMPLETE.md): I ficha, L resultado, F7 práctica, F4 glosario y F12 recuperar lectura. Opciones de texto/contraste y acceso textual experimental. Nuevos scripts godot:qa:updates, godot:qa:semantic y sus variantes :export; godot:test:shop-batch. Lector audible y sesiones humanas pendientes.
