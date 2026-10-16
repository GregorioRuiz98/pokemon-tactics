# Pokémon Tactics — Kanto Windows 0.14.6

Muestra de Paleta hasta Brock con elección de inicial, cuatro encuentros, captura local, tienda y bajas definitivas. Esta revisión mejora la tipografía, muestra estados/etapas sobre las unidades y en sus fichas, y adopta encuentros y repertorios de Let’s Go combinados.

## Jugar

Abrir PokemonTactics.exe desde la distribución. Funciona offline sin editor, Node ni servidor. Incluye LEEME, créditos/licencias y SHA256SUMS. Elige **Nueva campaña** para usar las reglas nuevas; los guardados0.14.0–0.14.5 continúan como Clásica con su versión original, conservando sus reglas y batalla. Al empezar otra se guarda copia de la anterior.

- Oak entrega un inicial de nivel5, dos pociones y120 ₽. PS/bajas persisten; estados/PT y etapas de atributos se restablecen por combate. Si no quedan vivos termina la campaña.
- Tras victoria, cada superviviente gana EXP y puede subir/aprender. Cada subida recupera tantos PS como aumenten sus PS máximos, incluida la evolución automática. Un Pokémon a 20/30 pasa a 23/33; las bajas no reviven. Captura local ya sorteada y guardada, luego tienda. Brock da medalla, dinero y su Onix de nivel14, como insignia de mayor nivel. Se admiten duplicados provisionalmente.
- Cuatro movimientos preparados **más** el básico fijo: cinco acciones. El básico no tiene tipo, STAB ni resistencias/inmunidades de tipo; 25potencia, alcance1, 0PT y consume la acción. Defensa, precisión y estados siguen aplicándose.
- Preparar movimientos aprendidos es gratis fuera de combate; desmarca uno para dejar hueco si tienes cuatro. Las dos orientaciones de rol se combinan, sin bonificaciones ocultas. Evolucionar conserva los movimientos aprendidos y actuales.
- Caramelo Raro25 ₽: sube exactamente un nivel. Comprar en la tienda y usar con el miembro seleccionado. Conserva EXP parcial y recupera el aumento de PS máximos; no revive. Tope100. La evolución ocurre automáticamente al alcanzar su nivel, mediante EXP o Caramelo, sin coste adicional ni botón Evolucionar. Poción40 ₽/+40PS y Superpoción90 ₽/+100PS siguen fuera de combate y sin revivir.
- Tienda: tres ofertas únicas, una copia por casilla. Renovar las tres cuesta25,50,75… ₽; se reinicia en cada tienda. Cargar no cambia ofertas ni coste. Pociones y Caramelos siguen siempre disponibles aparte.
- MT80 ₽ de un uso: comprar, seleccionar miembro y Aprender. Se indica compatibilidad; si ya tiene cuatro movimientos, el nuevo queda en la biblioteca. Siete MT de Let’s Go: Demolición, Escaldar, Megaagotar, Protección, Rayo, Avalancha y Cola Férrea. Numeración/compatibilidad exclusivamente LGPE.
- Un equipable por Pokémon: Vidaesfera100, Restos100, Chaleco Asalto90 o Botas Gruesas60 ₽. Cambiar/quitar devuelve el anterior a la bolsa; las bajas lo devuelven al cerrar el combate. Vidaesfera aumenta daño ×1,3 y pierde10% PS máximos por acción que cause daño; puede provocar baja definitiva. La previsión muestra el retroceso.
- Aprendizaje por nivel de Let’s Go, sin los movimientos de los iniciales especiales ni las excepciones anteriores. Pikachu aprende Doble Patada al9; Cola Férrea por MT19. Butterfree aprende Tornado/Confusión y Beedrill Doble Ataque/Picotazo; Megaagotar/Demolición por MT compatible.
- Charmander aprende Ascuas al13, sin Garra Metal temprana; tiene Demolición garantizada en la primera oferta de la tienda de Ruta1. Cobertura disponible no equivale a balance resuelto; conservarlo vivo sigue siendo importante.
- Clic en casilla azul mueve; clic en rival al alcance usa el básico. Habilidades/A abre el menú; teclas1–5 eligen acciones. Rectificar/R devuelve solo el movimiento antes de actuar o terminar; nunca ataques, PS/PT, estados ni RNG. Orientar y terminar/F elige dirección final.
- Previsión al señalar muestra daño, precisión, STAB y multiplicador de tipos. Fallo e inmunidad muestran imagen, rótulo y sonido propios. Ajustes de sonido/animación en F1; efectos sin desplazamiento con movimiento reducido.
- Flechas/Enter para casillas, Escape/clic derecho para cancelar, F8 para cargar y F1 para opciones/ayuda/créditos. Laboratorio anterior accesible desde cabecera/menú, con reglas y guardado propios.

Guardado después de cada orden en `%APPDATA%/PokemonTacticsLab/kanto-save.json`, esquema kanto/edición6 para nuevas partidas. Reconstrucción de diario, checksum, copia/escritura temporal y detección de otra instancia. Archivos inválidos se preservan; un error de escritura avisa y permite seguir en memoria. Ediciones1/2/3/4/5 se reconstruyen con sus motores originales. El laboratorio mantiene laboratory-save.json/esquema1/contrato0.13.0; no se leen guardados web.

## Alcance y valores provisionales

Cuatro mapas cenitales12×10 y catálogo de32 especies/doce líneas, con104 adaptaciones de movimientos reales. Los Pokémon capturables siguen siendo los de las tablas terrestres de Let’s Go combinadas, no todo el catálogo. Aprendizaje, PT, alcance y algunos efectos están adaptados: no es una réplica completa del cartucho. Pikachu20 y Graveler36 siguen como umbrales adaptados de evolución automática, confirmados por el usuario en lugar de piedra/intercambio. Los aprendizajes proceden de Let’s Go; los efectos que se traducen al sistema táctico se explican en cada habilidad. Oddish/Bellsprout evolucionan al21; Gloom/Weepinbell con Piedra Hoja80 ₽, sin curar.

Bases reales, IV15/EV0/naturaleza neutra y PS×4 tácticos. EXP220/350/500/650 por encuentro, coste siguiente nivel40+10L, cap100. El equilibrio no está cerrado: la política automática de prueba completa con Bulbasaur/lgpe-9 y Charmander/lgpe-1, mientras Squirtle pierde pronto en las semillas ensayadas (Burbuja al9). No son tasas humanas.

Sin isometría, alturas/cámara de mapas grandes, PC, pasivas, clima ni todos los estados. Se mantienen los límites narrativos del14: textos de viaje y paquete/Pokédex resumidos, sin exploración libre, rival inicial, Ruta22 opcional o entrenadores secundarios. Liga/legendarios pertenecen a entregas posteriores.

## Desarrollo y comprobación

Godot4.7.2 estándar, importar project.godot y F5. Plantillas oficiales4.7.2 para exportar; sin plugins nuevos. Desde la raíz, Node24/npm ci:

```powershell
$env:GODOT_BIN='C:\ruta\Godot_v4.7.2-stable_win64_console.exe'
npm run godot:verify
npm run godot:prepare
npm run godot:test:tactics
npm run godot:test:level-hp
npm run godot:test:tactics:journey
npm run godot:test:letsgo
npm run godot:test:letsgo:journey
npm run godot:test:growth
npm run godot:test:shop
npm run godot:test:progression
npm run godot:test:campaign:edges
npm run godot:test
npm run godot:qa
npm run godot:qa:campaign
npm run godot:export
npm run godot:qa:export
npm run godot:qa:campaign:export
```

Resultados temporales ../../work/qa-sprint-14-level-hp; paquete ../releases/pokemon-tactics-0.14.6/windows respecto a la raíz. Las pruebas del .exe no consultan el editor. QA usa archivos aislados, controles y eventos de viewport; no sustituye partidas humanas. Motor/plantillas/cachés/ZIP fuera de Git.

Importadores explícitos: import-progression.py (Python/Pillow ya disponibles mediante PYTHONPATH=../../work/balance-python) e import-feedback.mjs (jsfxr local). import-shop.py añade datos/compatibilidad de MT reutilizando PokéAPI y los recursos existentes. Referencias/hashes en progression-provenance, feedback-provenance y shop-provenance. No ejecutar godot:import para ocultar discrepancias: regenera referencias del laboratorio desde la web, que deben conservarse.

[Niveles y evolución automática](../docs/SPRINT_14_GROWTH.md) · [Tienda, premio y comprobaciones](../docs/SPRINT_14_SHOP.md) · [Reglas, roles y propuestas](../docs/DESIGN_LEVELS_ROLES.md) · [Informe y evidencia](../docs/SPRINT_14_PROGRESSION.md) · [Créditos](CREDITS.md)


Nueva fuente Atkinson Hyperlegible OFL. Iconos sobre sprites y en ambas fichas: condiciones y atributos ATQ/DEF/AE/DE/VEL/PRE/EVA con flechas, etapas y tooltip; no consumen RNG. Probabilidades LGPE provisionales: normales equiprobables y Bulbasaur especial1%, porque PokéAPI no incluye porcentajes por especie de esas ediciones. Sin spawns aéreos posjuego. [Informe, fuentes y adaptaciones0.14.4](../docs/SPRINT_14_LETSGO.md). Importador explícito tools/godot/import-letsgo.py;46 archivos nuevos con hashes/créditos en letsgo-provenance.json.


## Reglas tácticas0.14.5

Nueva campaña: precisión propia del movimiento/etapas sin penalización por orientación. Daño85–100% dividido por frente (mitad baja), costado (mitad alta), espalda (máximo y+1 etapa de crítico). Crítico×1,5; la previsión muestra rangos/probabilidad, no resultados futuros. Daño fijo sin variación ni críticos. Cuchillada/Hipercolmillo son críticos garantizados por3PT; conservan su precisión.

Ataque Rápido/Acua Jet/Golpe Bajo/Ataque Ala se acercan descontando movimiento restante y consumiendo desplazamiento; no atraviesan enemigos ni ocupan casillas con unidades. Golpe Cabeza/Portazo empujan una casilla libre, sin daño de choque. Rectificar nunca después de actuar, incluso al fallar un acercamiento.

Parálisis solo reduce movimiento a la mitad, sin alterar iniciativa ni perder acción. Estados y subidas/bajadas de atributos duran3 activaciones del afectado, incluida la actual si se aplica a sí mismo. Etapas con+1/+2/−1/−2 sobre sprites y en fichas; duración en tooltip. Fortaleza2PT, Agilidad3, Desarrollo3, Danza Aleteo4; Foco Energía3 aumenta crítico+2. La revisión0.14.6 añade recuperación del aumento de PS máximos al subir de nivel por EXP o Caramelo; conserva EXP, precios y bases. [Detalles, límites y comprobaciones](../docs/SPRINT_14_TACTICS.md).

[PS al subir de nivel: reglas y comprobaciones0.14.6](../docs/SPRINT_14_LEVEL_HP.md). Nueva campaña para edición7; archivos1–6 conservan sus reglas originales. Una evolución por piedra sin subir de nivel sigue conservando los PS actuales.
