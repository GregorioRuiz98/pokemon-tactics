# Pokémon Tactics — laboratorio Windows 0.13.0

Primera entrega del port. Combate manual 3 contra 3 con Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude. Incluye tipos modernos, tres acciones por especie, PT, precisión por orientación, estados, áreas, empuje, terreno e IA. Dos composiciones; reglas actuales con PS de campaña/Pirotecnia o ensayo clásico con sus PS/Lanzallamas originales. Las reglas y estadísticas proceden del motor web sin balance adicional.

No es todavía la campaña de Kanto: no contiene elección de inicial de Oak, rutas narrativas, capturas, tienda, evoluciones, reserva del PC ni legendarios. La siguiente muestra prevista es Paleta hasta Brock, sprint 14.

## Jugar

Desde la carpeta de distribución, abrir PokemonTactics.exe. No instalar Godot, Node ni un servidor. El juego utiliza únicamente sus recursos locales y puede jugarse sin conexión. LEEME.txt, CREDITS.md, licenses y SHA256SUMS.txt acompañan al ejecutable.

- Elegir «Nuevo ensayo», semilla, composición, reglas y variación de iniciativa.
- M para mover; 1/2/3 para elegir movimiento; seleccionar casilla/objetivo y confirmar. Escape cancela.
- F para orientar y terminar; elegir dirección y confirmar. Movimiento y acción admiten ambos órdenes.
- Flechas y Enter recorren/seleccionan casillas cuando el tablero tiene foco. F8 continúa el guardado.
- Ayuda, créditos, sonido y animación tienen controles propios. La animación disponible es Idle; las unidades cambian de casilla inmediatamente.

La partida se guarda tras cada orden aceptada en `%APPDATA%/PokemonTacticsLab/laboratory-save.json`. Al abrir continúa automáticamente si es válida. «Nuevo ensayo» conserva una copia anterior; una carga inválida informa y preserva el archivo. Un error de escritura permite seguir en memoria, con aviso. No se importan automáticamente partidas web.

## Abrir y comprobar el proyecto

En Godot 4.7.2 estándar, importar este project.godot y pulsar F5. Los recursos necesarios están en el repositorio; no se consulta PokéAPI ni SpriteCollab al jugar. Para exportar hacen falta las plantillas oficiales 4.7.2; no se requieren complementos de pago ni GUT/MCP.

Desde la raíz del repositorio, Node 24 y dependencias instaladas con npm ci:

```powershell
$env:GODOT_BIN='C:\ruta\Godot_v4.7.2-stable_win64_console.exe'
npm run godot:verify
npm run godot:prepare
npm run godot:test
npm run godot:qa
npm run godot:export
npm run godot:qa:export
```

El entorno de esta entrega tiene un motor portable en ../../work/godot-4.7.2; GODOT_BIN permite usar otra instalación. No se suben binarios, plantillas ni cachés a Git. El código de Godot es independiente de Node; Node se usa para herramientas de desarrollo y la referencia de pruebas.

`godot:import` regenera datos, copias y referencias **desde el motor web actual**. No ejecutarlo para aceptar diferencias sin revisarlas: el verificador detecta cambios de las fuentes. Son 16 combates completos y 25 escenarios, incluyendo la resolución de las 18 acciones del ensayo. La UI automatizada usa señales de sus controles y un evento de teclado; no sustituye probarlo con personas.

La exportación aparece en ../releases/pokemon-tactics-0.13.0/windows respecto a la raíz del repositorio. Para probar el binario empaquetado, godot:qa:export no consulta el editor. Los informes temporales van a ../../work/qa-sprint-13; evidencia seleccionada en docs/qa/sprint-13 de la raíz.

[Diseño](DESIGN.md) · [Créditos](CREDITS.md) · [Informe de entrega](../docs/SPRINT_13.md)
