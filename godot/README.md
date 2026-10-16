# Pokémon Tactics — Kanto Windows 0.14.0

Muestra jugable de Pueblo Paleta hasta Brock: elige un inicial de Oak, supera Ruta 1, Ruta 2 y Bosque Verde y desafía a Geodude/Onix. Cada victoria concede dinero, captura local garantizada y tienda. Tras Brock: Medalla Roca, dinero y captura del Bosque Verde, como decidió el creador.

## Jugar

Abrir PokemonTactics.exe en la distribución. Funciona offline, sin editor, Node ni servidor. LEEME.txt, CREDITS.md, licenses y SHA256SUMS.txt acompañan al ejecutable.

- Oak entrega un único inicial, dos pociones y 120 ₽. Los PS y las bajas persisten; estados/PT se reinician por combate. Caer termina la campaña si no quedan vivos.
- El sorteo usa las tablas de hierba de Pokémon Rojo original. El premio ya está guardado al mostrarse; cargar no lo vuelve a sortear. Esta muestra admite duplicados y llega a cinco miembros como máximo; todavía no necesita PC.
- Tienda tras cada captura: Poción 40 ₽ (+40 PS), Superpoción 90 ₽ (+100 PS), Caramelo Raro 100 ₽. Curación solo fuera de combate, sin revivir. Un Caramelo evoluciona una etapa sin requisito de nivel y sin curar. Entrenamiento 80 ₽: +5 a una estadística, dos compras totales por Pokémon, conservadas al evolucionar. Valores provisionales.
- Movimiento directo por casillas azules y básico al pulsar un rival al alcance. Menú flotante derecho visible en turnos aliados; Habilidades/A o 1/2/3 para los movimientos.
- Rectificar/R solo devuelve el último movimiento antes de actuar o terminar; atacar primero también lo bloquea. Nunca devuelve PS, PT, estados, ataques ni RNG.
- Orientar y terminar/F elige la dirección final. Previsión al señalar; confirmar solo ataques con riesgo aliado. Flechas/Enter para casillas, Escape/clic derecho para cancelar, F8 para cargar y F1 para opciones, ayuda, créditos y ajustes.
- Laboratorio táctico conserva el ensayo anterior 3v3/8×8, composiciones y guardado propio. Se accede desde la cabecera o el menú.

La campaña se guarda tras cada orden en `%APPDATA%/PokemonTacticsLab/kanto-save.json`. Nuevo inicio conserva copia del archivo anterior. Carga por reconstrucción, checksum, escritura temporal/copia y detección de otra instancia; los archivos inválidos se preservan. Si falla escribir se avisa y se continúa solo en memoria. Contrato de campaña `kanto`, versión 1; laboratorio `laboratory-save.json`, esquema 1/contrato 0.13.0 conservado. No se leen partidas web.

## Alcance de esta muestra

Cuatro encuentros y mapas de prueba 12×10 en vista cenital. No incluye aún isometría, alturas, cámara de mapas grandes, PC, equipables en campaña, EXP/niveles, MT, Liga ni legendarios. La entrega del paquete/Pokédex se resume en texto; no hay mundo de exploración libre, combate inicial del rival, Ruta 22 opcional ni entrenadores secundarios. Evoluciones y mejoras mínimas sirven para probar el ciclo; no representan todos los requisitos de la campaña futura.

Balance provisional: nueve simulaciones, tres por inicial; completaron Brock 1/3 con Bulbasaur, 0/3 con Charmander y 3/3 con Squirtle bajo la política automática usada. No son tasas humanas. Para recorrer todo el tramo con una configuración comprobada: Squirtle y semilla `kanto-14`.

## Desarrollo y comprobación

Godot 4.7.2 estándar, importar project.godot y F5. Recursos incluidos, sin plugins nuevos. Exportar requiere las plantillas oficiales 4.7.2. Desde la raíz, Node 24 y npm ci:

```powershell
$env:GODOT_BIN='C:\ruta\Godot_v4.7.2-stable_win64_console.exe'
npm run godot:verify
npm run godot:prepare
npm run godot:test
npm run godot:test:campaign
npm run godot:test:campaign:edges
npm run godot:qa
npm run godot:qa:campaign
npm run godot:export
npm run godot:qa:export
npm run godot:qa:campaign:export
```

El motor portable del entorno está en ../../work/godot-4.7.2; GODOT_BIN admite otra instalación. El binario exportado se prueba sin consultar el editor. Resultados temporales en ../../work/qa-sprint-14; distribución en ../releases/pokemon-tactics-0.14.0/windows respecto a la raíz del repositorio. No subir motores, cachés ni paquetes a Git.

`godot:import` regenera las referencias de laboratorio desde la web: no ejecutarlo para ocultar discrepancias. `python tools/godot/import-kanto.py` importa solo esta ampliación; requiere Pillow instalado y acceso de red en desarrollo o caché local. En este entorno Pillow ya está en ../../work/balance-python, seleccionable mediante PYTHONPATH; no se ha instalado una dependencia nueva. Commits fijados, fuentes y hashes en los manifiestos. La reproducción de futuras reglas de campaña exige conservar esta edición o migrarla expresamente.

[Informe del sprint 14](../docs/SPRINT_14.md) · [Diseño del HUD](DESIGN.md) · [Créditos](CREDITS.md) · [Base Godot](../docs/SPRINT_13.md)
