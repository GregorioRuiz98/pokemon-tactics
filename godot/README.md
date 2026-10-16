# Pokémon Tactics — Kanto Windows 0.14.1

Muestra de Paleta hasta Brock con elección de inicial, cuatro encuentros, captura local, tienda y bajas definitivas. Esta revisión añade EXP/niveles, movimientos configurables, dos orientaciones de rol por línea y señales distintas para fallo/inmunidad.

## Jugar

Abrir PokemonTactics.exe desde la distribución. Funciona offline sin editor, Node ni servidor. Incluye LEEME, créditos/licencias y SHA256SUMS. Elige **Nueva campaña** para usar las reglas nuevas; un guardado0.14.0 continúa como Clásica0.14, conservando sus reglas y batalla. Al empezar otra se guarda copia de la anterior.

- Oak entrega un inicial de nivel5, dos pociones y120 ₽. PS/bajas persisten; estados/PT y etapas de atributos se restablecen por combate. Si no quedan vivos termina la campaña.
- Tras victoria, cada superviviente gana EXP y puede subir/aprender sin recuperar PS. Captura local ya sorteada y guardada, luego tienda. Brock da medalla/dinero/captura del Bosque Verde. Se admiten duplicados provisionalmente.
- Cuatro movimientos preparados **más** el básico fijo: cinco acciones. El básico no tiene tipo, STAB ni resistencias/inmunidades de tipo; 25potencia, alcance1, 0PT y consume la acción. Defensa, precisión y estados siguen aplicándose.
- Preparar movimientos aprendidos es gratis fuera de combate; desmarca uno para dejar hueco si tienes cuatro. Las dos orientaciones de rol se combinan, sin bonificaciones ocultas. Evolucionar conserva los movimientos aprendidos y actuales.
- Caramelo Raro100 ₽: evoluciona una etapa solo al alcanzar el nivel mínimo; no da niveles ni cura. Se ha retirado el entrenamiento de estadísticas por dinero en edición2. Poción40 ₽/+40PS y Superpoción90 ₽/+100PS siguen fuera de combate y sin revivir.
- Clic en casilla azul mueve; clic en rival al alcance usa el básico. Habilidades/A abre el menú; teclas1–5 eligen acciones. Rectificar/R devuelve solo el movimiento antes de actuar o terminar; nunca ataques, PS/PT, estados ni RNG. Orientar y terminar/F elige dirección final.
- Previsión al señalar muestra daño, precisión, STAB y multiplicador de tipos. Fallo e inmunidad muestran imagen, rótulo y sonido propios. Ajustes de sonido/animación en F1; efectos sin desplazamiento con movimiento reducido.
- Flechas/Enter para casillas, Escape/clic derecho para cancelar, F8 para cargar y F1 para opciones/ayuda/créditos. Laboratorio anterior accesible desde cabecera/menú, con reglas y guardado propios.

Guardado después de cada orden en `%APPDATA%/PokemonTacticsLab/kanto-save.json`, esquema kanto/edición2 para nuevas partidas. Reconstrucción de diario, checksum, copia/escritura temporal y detección de otra instancia. Archivos inválidos se preservan; un error de escritura avisa y permite seguir en memoria. Edición1 se reconstruye con el motor anterior. El laboratorio mantiene laboratory-save.json/esquema1/contrato0.13.0; no se leen guardados web.

## Alcance y valores provisionales

Cuatro mapas cenitales12×10 y catálogo de26 especies/diez líneas, con51 adaptaciones de movimientos reales. Los Pokémon capturables siguen siendo los de las tablas locales de Rojo, no todo el catálogo. Aprendizaje, PT, alcance y algunos efectos están adaptados: no es una réplica completa del cartucho. Pikachu20 y Graveler36 son umbrales provisionales para evolucionar con Caramelo en lugar de piedra/intercambio.

Bases reales, IV15/EV0/naturaleza neutra y PS×4 tácticos. EXP220/350/500/650 por encuentro, coste siguiente nivel40+10L, cap100. El equilibrio no está cerrado: la política automática probada completa con Squirtle/semilla kanto-14 y pierde antes con los otros iniciales. No son tasas humanas.

Sin isometría, alturas/cámara de mapas grandes, PC, equipables/MT de campaña, pasivas, críticos, clima ni todos los estados. Se mantienen los límites narrativos del14: textos de viaje y paquete/Pokédex resumidos, sin exploración libre, rival inicial, Ruta22 opcional o entrenadores secundarios. Liga/legendarios pertenecen a entregas posteriores.

## Desarrollo y comprobación

Godot4.7.2 estándar, importar project.godot y F5. Plantillas oficiales4.7.2 para exportar; sin plugins nuevos. Desde la raíz, Node24/npm ci:

```powershell
$env:GODOT_BIN='C:\ruta\Godot_v4.7.2-stable_win64_console.exe'
npm run godot:verify
npm run godot:prepare
npm run godot:test:progression
npm run godot:test:campaign:edges
npm run godot:test
npm run godot:qa
npm run godot:qa:campaign
npm run godot:export
npm run godot:qa:export
npm run godot:qa:campaign:export
```

Resultados temporales ../../work/qa-sprint-14-progression; paquete ../releases/pokemon-tactics-0.14.1/windows respecto a la raíz. Las pruebas del .exe no consultan el editor. QA usa archivos aislados, controles y eventos de viewport; no sustituye partidas humanas. Motor/plantillas/cachés/ZIP fuera de Git.

Importadores explícitos: import-progression.py (Python/Pillow ya disponibles mediante PYTHONPATH=../../work/balance-python) e import-feedback.mjs (jsfxr local). Referencias/hashes en progression-provenance y feedback-provenance. No ejecutar godot:import para ocultar discrepancias: regenera referencias del laboratorio desde la web, que deben conservarse.

[Reglas, roles y propuestas](../docs/DESIGN_LEVELS_ROLES.md) · [Informe y evidencia](../docs/SPRINT_14_PROGRESSION.md) · [Créditos](CREDITS.md)
