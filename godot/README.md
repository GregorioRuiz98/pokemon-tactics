# Pokémon Tactics — Kanto Windows 0.15.0

Muestra de Paleta hasta Brock con elección de inicial, cuatro encuentros, captura local, tienda y debilitados recuperables con Revivir. Esta revisión añade mapas isométricos 16×16/24×24, alturas, cámara/zoom y un vigía en el bosque. Conserva naturalezas y habilidades normales. Mantiene Revivir150 ₽/50% de PS y el límite por gimnasio. Mantiene encuentros y repertorios de Let’s Go combinados.

## Jugar

Abrir PokemonTactics.exe desde la distribución. Funciona offline sin editor, Node ni servidor. Incluye LEEME, créditos/licencias y SHA256SUMS. Elige **Nueva campaña** para usar las reglas nuevas; los guardados0.14.0–0.14.9 continúan como Clásica con su versión original, conservando sus reglas y batalla. Al empezar otra se guarda copia de la anterior.

- Oak entrega un inicial de nivel5, dos pociones y120 ₽. PS/bajas persisten; estados/PT y etapas de atributos se restablecen por combate. Si no quedan vivos termina la campaña.
- Tras victoria, cada superviviente gana EXP y puede subir/aprender. Cada subida recupera tantos PS como aumenten sus PS máximos, incluida la evolución automática. Un Pokémon a 20/30 pasa a 23/33; los debilitados no reviven por subir de nivel. Captura local ya sorteada y guardada, luego tienda. Brock da medalla, dinero y su Onix de nivel14, como insignia de mayor nivel. Se admiten duplicados provisionalmente.
- Cuatro movimientos preparados **más** el básico fijo: cinco acciones. El básico no tiene tipo, STAB ni resistencias/inmunidades de tipo; 25potencia, alcance1, 0PT y consume la acción. Defensa, precisión y estados siguen aplicándose.
- Preparar movimientos aprendidos es gratis fuera de combate; desmarca uno para dejar hueco si tienes cuatro. Las dos orientaciones de rol se combinan, sin bonificaciones ocultas. Evolucionar conserva los movimientos aprendidos y actuales.
- Caramelo Raro25 ₽: sube exactamente un nivel. Comprar en la tienda y usar con el miembro seleccionado. Conserva EXP parcial y recupera el aumento de PS máximos; no revive. Tope actual14, por el Onix de Brock. Al llegar no acumulas EXP y el Caramelo se bloquea sin consumirse. La evolución ocurre automáticamente al alcanzar su nivel, mediante EXP o Caramelo, sin coste adicional ni botón Evolucionar. Poción40 ₽/+40PS y Superpoción90 ₽/+100PS siguen fuera de combate y sin revivir.
- Tienda: tres ofertas únicas, una copia por casilla. Renovar las tres cuesta25,50,75… ₽; se reinicia en cada tienda. Cargar no cambia ofertas ni coste. Pociones, Caramelos y Revivir siguen siempre disponibles aparte.
- Revivir150 ₽: compra una unidad, selecciona un debilitado y úsala para recuperar el50% de sus PS máximos (redondeo hacia abajo, mínimo1). Conserva nivel/EXP/movimientos. El equipable devuelto al caer permanece en la bolsa; no se duplica ni equipa solo. Se puede curar después con pociones. Si cae todo el equipo termina la campaña, aunque quede Revivir.
- MT80 ₽ de un uso: comprar, seleccionar miembro y Aprender. Se indica compatibilidad; si ya tiene cuatro movimientos, el nuevo queda en la biblioteca. Siete MT de Let’s Go: Demolición, Escaldar, Megaagotar, Protección, Rayo, Avalancha y Cola Férrea. Numeración/compatibilidad exclusivamente LGPE.
- Un equipable por Pokémon: Vidaesfera100, Restos100, Chaleco Asalto90 o Botas Gruesas60 ₽. Cambiar/quitar devuelve el anterior a la bolsa; las bajas lo devuelven al cerrar el combate. Vidaesfera aumenta daño ×1,3 y pierde10% PS máximos por acción que cause daño; puede debilitar al portador. La previsión muestra el retroceso.
- Aprendizaje por nivel de Let’s Go, sin los movimientos de los iniciales especiales ni las excepciones anteriores. Pikachu aprende Doble Patada al9; Cola Férrea por MT19. Butterfree aprende Tornado/Confusión y Beedrill Doble Ataque/Picotazo; Megaagotar/Demolición por MT compatible.
- Charmander aprende Ascuas al13, sin Garra Metal temprana; tiene Demolición garantizada en la primera oferta de la tienda de Ruta1. Cobertura disponible no equivale a balance resuelto; conservarlo vivo sigue siendo importante.
- Clic en casilla azul mueve; clic en rival al alcance usa el básico. Habilidades/A abre el menú; teclas1–5 eligen acciones. Rectificar/R devuelve solo el movimiento antes de actuar o terminar; nunca ataques, PS/PT, estados ni RNG. Orientar y terminar/F elige dirección final.
- Previsión al señalar muestra daño, precisión, STAB y multiplicador de tipos. Fallo e inmunidad muestran imagen, rótulo y sonido propios. Ajustes de sonido/animación en F1; efectos sin desplazamiento con movimiento reducido.
- Flechas/Enter para casillas, Escape/clic derecho para cancelar, F8 para cargar y F1 para opciones/ayuda/créditos. Laboratorio anterior accesible desde cabecera/menú, con reglas y guardado propios.

Guardado después de cada orden en `%APPDATA%/PokemonTacticsLab/kanto-save.json`, esquema kanto/edición11 para nuevas partidas. Reconstrucción de diario, checksum, copia/escritura temporal y detección de otra instancia. Archivos inválidos se preservan; un error de escritura avisa y permite seguir en memoria. Ediciones1–10 se reconstruyen con sus motores originales. El laboratorio mantiene laboratory-save.json/esquema1/contrato0.13.0; no se leen guardados web.

## Alcance y valores provisionales

Cuatro mapas isométricos16×16 o24×24 y catálogo de32 especies/doce líneas, con104 adaptaciones de movimientos reales. Los Pokémon capturables siguen siendo los de las tablas terrestres de Let’s Go combinadas, no todo el catálogo. Aprendizaje, PT, alcance y algunos efectos están adaptados: no es una réplica completa del cartucho. Pikachu20 y Graveler36 siguen como umbrales adaptados de evolución automática, confirmados por el usuario en lugar de piedra/intercambio. Los aprendizajes proceden de Let’s Go; los efectos que se traducen al sistema táctico se explican en cada habilidad. Oddish/Bellsprout evolucionan al21; Gloom/Weepinbell con Piedra Hoja80 ₽, sin curar.

Bases reales, IV15/EV0 y modificadores de naturaleza y PS×4 tácticos. EXP220/350/500/650 por encuentro, coste siguiente nivel40+10L, techo técnico100 y límite activo14 por Brock. El equilibrio no está cerrado. En 0.15.0 se completan recorridos automáticos con Bulbasaur/tactics-1 en ambos tamaños; son comprobaciones de mecánicas, no tasas humanas ni prueba de balance entre iniciales. Ver docs/SPRINT_15.md.

Pendientes PC, clima, habilidades ocultas y ampliación de estados. Clorofila/Fuga esperan clima/huida. El terreno y los tamaños son de prueba; no es el arte final de Kanto. Se mantienen los límites narrativos del14: textos de viaje y paquete/Pokédex resumidos, sin exploración libre, rival inicial, Ruta22 opcional o entrenadores secundarios. Liga/legendarios pertenecen a entregas posteriores.

## Cámara y alturas

Elige 16×16 (inicial) o 24×24 antes del primer combate. Rueda/+/-: zoom; botón central: arrastrar; botones de cámara disponibles dentro de la escena. C/Inicio o Unidad centran al activo, Mapa encuadra todo. El minimapa muestra aliados, enemigos y vigías.

Subir un nivel cuesta +1 de movimiento; saltos de más de uno bloquean el paso terrestre. Voladores ignoran alturas. Alcance y visión tienen en cuenta el desnivel, sin subir daño/precisión. Empujes y acercamientos respetan las mismas restricciones. Rectificar sigue afectando solo al movimiento antes de actuar. El vigía del bosque se incorpora en la siguiente ronda al acercarte/dañarlo, y como máximo al comenzar la tercera.

## Desarrollo y comprobación

Godot4.7.2 estándar, importar project.godot y F5. Plantillas oficiales4.7.2 para exportar; sin plugins nuevos. Desde la raíz, Node24/npm ci:

```powershell
$env:GODOT_BIN='C:\ruta\Godot_v4.7.2-stable_win64_console.exe'
npm run godot:verify
npm run godot:prepare
npm run godot:test:scale
npm run godot:qa:scale
npm run godot:test:tactics
npm run godot:test:level-hp
npm run godot:test:gym-caps
npm run godot:test:revive
npm run godot:test:traits
npm run godot:test:traits:journey
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

Resultados temporales ../../work/qa-sprint-14-traits; paquete ../releases/pokemon-tactics-0.14.9/windows respecto a la raíz. Las pruebas del .exe no consultan el editor. QA usa archivos aislados, controles y eventos de viewport; no sustituye partidas humanas. Motor/plantillas/cachés/ZIP fuera de Git.

Importadores explícitos: import-progression.py (Python/Pillow ya disponibles mediante PYTHONPATH=../../work/balance-python) e import-feedback.mjs (jsfxr local). import-shop.py añade datos/compatibilidad de MT reutilizando PokéAPI y los recursos existentes. Referencias/hashes en progression-provenance, feedback-provenance y shop-provenance. No ejecutar godot:import para ocultar discrepancias: regenera referencias del laboratorio desde la web, que deben conservarse.

[Niveles y evolución automática](../docs/SPRINT_14_GROWTH.md) · [Tienda, premio y comprobaciones](../docs/SPRINT_14_SHOP.md) · [Reglas, roles y propuestas](../docs/DESIGN_LEVELS_ROLES.md) · [Informe y evidencia](../docs/SPRINT_14_PROGRESSION.md) · [Créditos](CREDITS.md)


Nueva fuente Atkinson Hyperlegible OFL. Iconos sobre sprites y en ambas fichas: condiciones y atributos ATQ/DEF/AE/DE/VEL/PRE/EVA con flechas, etapas y tooltip; no consumen RNG. Probabilidades LGPE provisionales: normales equiprobables y Bulbasaur especial1%, porque PokéAPI no incluye porcentajes por especie de esas ediciones. Sin spawns aéreos posjuego. [Informe, fuentes y adaptaciones0.14.4](../docs/SPRINT_14_LETSGO.md). Importador explícito tools/godot/import-letsgo.py;46 archivos nuevos con hashes/créditos en letsgo-provenance.json.


## Reglas tácticas0.14.5

Nueva campaña: precisión propia del movimiento/etapas sin penalización por orientación. Daño85–100% dividido por frente (mitad baja), costado (mitad alta), espalda (máximo y+1 etapa de crítico). Crítico×1,5; la previsión muestra rangos/probabilidad, no resultados futuros. Daño fijo sin variación ni críticos. Cuchillada/Hipercolmillo son críticos garantizados por3PT; conservan su precisión.

Ataque Rápido/Acua Jet/Golpe Bajo/Ataque Ala se acercan descontando movimiento restante y consumiendo desplazamiento; no atraviesan enemigos ni ocupan casillas con unidades. Golpe Cabeza/Portazo empujan una casilla libre, sin daño de choque. Rectificar nunca después de actuar, incluso al fallar un acercamiento.

Parálisis solo reduce movimiento a la mitad, sin alterar iniciativa ni perder acción. Estados y subidas/bajadas de atributos duran3 activaciones del afectado, incluida la actual si se aplica a sí mismo. Etapas con+1/+2/−1/−2 sobre sprites y en fichas; duración en tooltip. Fortaleza2PT, Agilidad3, Desarrollo3, Danza Aleteo4; Foco Energía3 aumenta crítico+2. La revisión0.14.6 añade recuperación del aumento de PS máximos al subir de nivel por EXP o Caramelo; conserva EXP, precios y bases. [Detalles, límites y comprobaciones](../docs/SPRINT_14_TACTICS.md).

[PS al subir de nivel: reglas y comprobaciones0.14.6](../docs/SPRINT_14_LEVEL_HP.md). Esa regla de PS continúa en edición8; los archivos anteriores conservan sus reglas originales. Una evolución por piedra sin subir de nivel sigue conservando los PS actuales.

[Límites por gimnasio0.14.7](../docs/SPRINT_14_GYM_CAPS.md): Nueva campaña usa edición8. Tope del siguiente líder pendiente, calculado desde el insignia de mayor nivel. Actualmente solo Brock,14; al terminar la muestra se conserva14. No se implementan los gimnasios siguientes en esta revisión.

[Revivir0.14.8](../docs/SPRINT_14_REVIVE.md): Esa regla de Revivir continúa en edición10. Los archivos anteriores conservan sus reglas; la copia al reiniciar se mantiene.

## Naturalezas y habilidades0.14.9

Nueva campaña usa edición10. Un Pokémon recibe naturaleza y habilidad normal al obtenerlo, con sorteo separado y persistido; inspeccionar/cargar/evolucionar no lo vuelve a sortear. Las25 naturalezas aplican+10%/−10% a los atributos correspondientes (cinco son neutras), sin modificar PS.

Mentas100 ₽: el selector de tienda permite elegir uno de21 efectos y la ficha muestra los valores antes/después. Se conserva el nombre de la naturaleza original. Cápsula Habilidad150 ₽: alterna dos habilidades normales cuando la especie dispone de ambas; vista previa y sin ocupar el equipable. Solo en tienda y en miembros vivos; no consumir si no puede cambiar nada. No hay habilidades ocultas ni Parche Habilidad en esta entrega.

Trece pasivas activas: Espesura, Mar Llamas, Torrente, Enjambre, Polvo Escudo, Mudar, Ojo Compuesto, Vista Lince, Tumbos, Agallas, Elec. Estática, Cabeza Roca y Robustez. Clorofila y Fuga conservan su descripción pero esperan clima/huida: no tienen efecto en los escenarios actuales. Robustez respeta el golpe agregado de los multiimpactos del prototipo; no se implementan impactos individuales aquí. [Reglas, adaptaciones y evidencia](../docs/SPRINT_14_TRAITS.md).
