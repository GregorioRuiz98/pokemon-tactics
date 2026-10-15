# Sprint 13 — base Godot y ejecutable Windows

15 de octubre de 2026. Laboratorio nativo 0.13.0; campaña web 0.12.0 conservada. Rama de entrega: codex/sprint-13.

El usuario autorizó el inicio mediante «pues empieza», después de registrar la nueva dirección de Kanto. Esta entrega cierra la base técnica: un ensayo táctico manual 3v3 en Godot, guardado nativo y ejecutable Windows. No ejecuta los sprints 14–22 ni publica el juego.

Código subido a la rama codex/sprint-13 y SHA remoto verificado. La revisión automática rechazó el cambio adicional de rama predeterminada y el uso de una credencial para esa operación por falta de autorización explícita. Se conserva la configuración existente; esto no impide usar la rama ni el paquete local. No reintentar ese cambio por otra vía sin indicación del usuario.

## Qué se puede probar

- Tablero 8×8 y seis especies originales. Elegir entre iniciales contra Pikachu/Butterfree/Geodude o la composición inversa; semilla y variación de iniciativa ±5 %/±10 %.
- Reglas actuales de nivel uno/edición 14, con PS de campaña y Pirotecnia, o ensayo clásico con sus PS y Lanzallamas originales. No se han rebajado daños, alterado kits ni aplicado propuestas del informe de balance.
- Iniciativa por ronda, movimiento y acción en ambos órdenes, aliados atravesables, costes por perfil, ocupación, orientación final, precisión por ángulo y línea de visión.
- Básicos y habilidades con PT, daño físico/especial, tabla moderna de tipos, drenaje, protección, veneno/quemadura/parálisis, áreas con aliados, empuje y ascuas.
- HUD nativo: cola encima, equipo y objetivo en los laterales, órdenes/previsión y confirmación debajo del mapa. Ratón, flechas/Enter, Escape y atajos; avisos de daño/estado aliado, empuje, coste y precisión. Previsión extensa desplazable sin cubrir casillas.
- Guardado tras cada orden, continuar en combate, detección de cambios de otra instancia y aviso cuando solo puede seguirse en memoria. Ayuda, créditos, sonido local y animación Idle desactivable.

Abrir `PokemonTactics.exe` en `outputs/releases/pokemon-tactics-0.13.0/windows` respecto a la carpeta de trabajo que contiene el repositorio. El paquete se mantiene fuera de Git. No hacen falta editor Godot, Node, navegador ni servidor para jugar. Instrucciones de desarrollo y controles en [godot/README.md](../godot/README.md).

## Implementación y recursos

Godot 4.7.2 estándar: `4.7.2.stable.official.ed1daf0bf`. Motor portable y plantillas Windows fuera del repositorio, sin complementos nuevos. Archivo oficial de plantillas verificado contra SHA512-SUMS de godotengine/godot-builds: `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079`.

- POO en `godot/core`: LabPokemon comparte perfiles/creación; acciones Damage, Drain, Status y Guard implementan previsiones polimórficas. Tipos y repertorios son datos. LabBattle contiene las reglas y la IA; la UI no mantiene una segunda fórmula de daño.
- PRNG uint32 adaptado del motor web, incluyendo su tratamiento de semillas Unicode. El orden A* y las operaciones de heap se adaptan de EasyStar/heap.js para conservar también desempates, trayectorias, orientación y decisiones de IA. No se introducen dependencias nativas de esos paquetes; sus avisos se incluyen.
- Estado serializable y diario de órdenes independientes de nodos/clases. Carga mediante replay; conservar RNG/cola y reconstruir el estado canónico evita deriva de coma flotante al leer JSON. La comparación permite únicamente redondeo decimal mínimo en valores no enteros; IDs, PS y RNG enteros siguen exactos.
- Guardado nativo esquema 1/versión 0.13.0 en `%APPDATA%/PokemonTacticsLab/laboratory-save.json`. Archivo temporal, copia anterior y copias únicas antes de un nuevo ensayo. Un diario de más de 4.000 órdenes se rechaza antes de sustituir el guardado anterior. No es un sistema contra trampas.
- Importador explícito desde recursos locales: seis especies, 41 archivos con hashes de origen/destino y 13 fuentes del catálogo/reglas/generador. Hojas y WAV web originales sin modificar. `victory.wav` nativo añade un byte de relleno RIFF y actualiza la longitud del contenedor: muestras PCM y tamaño del bloque de audio idénticos. Esto elimina un error del importador de Godot con el WAV de longitud impar.
- Se conservan autores, licencias y el registro completo web como referencia. Créditos nativos limitan las especies realmente incluidas; el menú muestra además las licencias/atribuciones del motor. Sin consultas a PokéAPI/SpriteCollab durante el uso.

La versión web mantiene src/, public/, formato de guardado y parámetros. package.json añade herramientas de desarrollo Godot, con versión web 0.12.0 y lockfile conservados. La versión nativa se declara en project.godot. Ni motores/plantillas, caché .godot, exportados ni credenciales entran en Git.

## Comprobaciones ejecutadas

| Comprobación | Resultado y alcance |
| --- | --- |
| Referencia del motor web | 16 combates completos: dos modos, dos composiciones, ±5 %/±10 % y dos semillas, una Unicode |
| Paridad nativa | Las mismas 506 órdenes de IA, estados y resultados; entrada inmutable y RNG conservado en previsión/elección |
| Escenarios de reglas | 25: previsiones/rutas de las seis especies, resolución de sus 18 acciones y cierre con estado/ascuas |
| Guardado | Reconstrucción y siguiente tirada idénticas, archivo inválido preservado, conflicto de escritura y fallo de carpeta informados; diario excesivo no reemplaza el anterior |
| Interfaz desde proyecto | Cuatro batallas completas por señales de los controles: 73 órdenes aliadas y 706 aserciones, sin fallos |
| Ejecutable empaquetado | Las mismas cuatro batallas y 706 aserciones; se ejecuta desde su carpeta de distribución con GODOT_BIN apuntando a un editor inexistente |
| Guardado en user:// | Archivo aislado escrito/cargado en la carpeta real del juego, estado reconstruido y archivo de prueba eliminado; no se modifica la partida normal |
| Ventanas/renderizado | 1024×720, 1280×900 y 1440×1000; previsión extensa a tamaño mínimo, nuevo ensayo, rutas, ataques, orientación, resultado y créditos |
| Instalación limpia Godot | Copia sin caché .godot: importación completa sin errores tras corregir el contenedor RIFF |
| Integridad | Hashes de 41 recursos nativos y sus fuentes, 13 fuentes de referencia y PCM de los tres sonidos; fuentes originales intactas |
| Regresión web | 96 pruebas, typecheck y build aprobados; 146 hashes originales, cuatro CSV y audio/licencia de jsfxr verificados |
| Herramientas | `node --check tools/godot/run.mjs`; revisión de diff y enlaces locales |

Las 503.579 comparaciones internas del comprobador nativo **no se presentan como 503.579 pruebas independientes**: incluyen recorrido recursivo de snapshots. Los controles automatizados usan sus señales y un evento de teclado; no son sesiones humanas ni una auditoría de todos los dispositivos.

Las referencias generadas se conservan comprimidas en tests/parity.json.gz para mantener revisable el diff; Node y Godot usan sus codecs gzip integrados, sin dependencias nuevas. El generador documenta los escenarios y reproduce las referencias desde las reglas web. Los atributos Git preservan los bytes originales de recursos/licencias importados, incluido su espacio final.

Los primeros intentos de compilación/importación quedaron limitados por el aislamiento de archivos del entorno. Las comprobaciones finales se ejecutaron con acceso a los archivos del proyecto y la carpeta local del juego. El build web conserva su aviso conocido de tamaño de Phaser; no hay linter ni cobertura configurados.

Evidencia seleccionada: [paridad](qa/sprint-13/parity-result.json), [UI desde fuente](qa/sprint-13/ui-source-result.json), [UI del ejecutable](qa/sprint-13/ui-release-result.json), [paquete](qa/sprint-13/release-info.json), [ataque](qa/sprint-13/native-attack.png), [ventana mínima](qa/sprint-13/native-small.png), [créditos](qa/sprint-13/native-credits.png). Logs y capturas adicionales permanecen en work/qa-sprint-13 fuera del repositorio.

## Límites y siguiente entrega

Esta es una base técnica jugable. No contiene todavía la historia de Rojo, elección de Oak, capturas, tiendas, PC, evoluciones, mejoras de estadísticas, mapas grandes, peligros de zona ni jefes. No se ha implementado toda la campaña web dentro de Godot ni se han importado sus 28 especies. La animación de desplazamiento Walk queda pendiente; el cambio de casilla es inmediato. No hay migración automática desde localStorage ni pruebas humanas, de accesibilidad asistiva, de audio percibido o en otros equipos/GPUs.

La IA conserva su política para poder comprobar paridad; los ciclos defensivos y el balance del informe anterior no quedan resueltos por cambiar de motor. Las pruebas de este laboratorio no miden la diversión ni la duración de la nueva campaña.

Siguiente entrega propuesta: **sprint 14, Paleta hasta Brock**. Antes de implementar sus recompensas/progresión, cerrar solo las decisiones que la afectan: captura tras cada combate frente a una por ubicación, reservas y derrota, caramelos/evolución y límites de entrenamiento. Mantener los requisitos y propuestas de [PRODUCT.md](../PRODUCT.md) y no ampliar todos los sprints por esta autorización inicial.
