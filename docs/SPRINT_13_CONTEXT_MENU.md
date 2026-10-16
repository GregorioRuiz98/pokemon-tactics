# Menú dentro de la escena — 0.13.2

16 de octubre de 2026. Rama codex/sprint-13-context-menu. Referencia del usuario: menú vertical a la derecha y fichas de retrato en las esquinas, similar a la captura de RPG táctico aportada. Sustituye la barra inferior de 0.13.1. No inicia la campaña 14.

## Composición y controles

- Menú flotante azul petróleo/cian a la derecha, visible automáticamente en turnos aliados y oculto durante la IA.
- Habilidades abre los tres movimientos de la unidad. Básico directo al señalar rival; 1/2/3 siguen siendo atajos. Orientar y terminar/F abre las direcciones; la elección aparece automáticamente al gastar movimiento y acción.
- Sin botón Mover: casillas alcanzables y trayectoria al señalar, clic para moverse.
- Rectificar movimiento/R recupera casilla, orientación y presupuesto anteriores. Solo antes de usar cualquier acción o cerrar el turno. Atacar primero y moverse después también lo bloquea, como confirmó el usuario.
- Retrato de diálogo del activo, PS/PT y barra de salud abajo a la izquierda; retrato del objetivo y previsión abajo a la derecha. Mensaje contextual en el hueco central inferior. El menú de habilidades es una elección de implementación revisable.
- Ningún panel cubre casillas jugables; los límites se comprueban automáticamente a las tres resoluciones. Previsiones, confirmación por riesgo aliado, teclado, cancelación y ajustes conservados.

La escena sigue cenital. El usuario eligió explícitamente interfaz primero e isometría/alturas en otro sprint. La separación entre representación y reglas permite cambiar el dibujo conservando el dominio, aunque exige adaptar selección, cámara, profundidad y recursos. Las alturas añaden reglas y datos de desnivel, rampas/vuelo, alcance/visibilidad, IA y guardado. Godot admite tiles isométricos; referencia técnica: https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html. No se han implementado alturas decorativas ni bonificaciones nuevas.

## Rectificación exclusiva del movimiento

Módulo adicional core/movement_revision.gd. Solo acepta la última orden move de una activación aliada con moved y sin acted. Reconstruye el estado anterior desde el diario y exige que aplicar ese movimiento reproduzca exactamente el estado actual. Además compara que las únicas diferencias sean x/y, facing, remaining, moved y el registro de ese movimiento.

Así no existe una orden Deshacer genérica: no devuelve PS, PT, estados, ataques ni tiradas. Trunca únicamente la última orden de movimiento, guarda y luego actualiza la presentación. La carga reconstruye la misma disponibilidad. battle.gd, movement.gd y save_store.gd permanecen intactos; se mantiene el contrato de guardado nativo 0.13.0/esquema 1 y la web 0.12.0.

## Recursos

Seis retratos Normal originales de 40×40 de Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude. Créditos individuales: CHUNSOFT; estilo de diálogo Pokémon Mundo Misterioso, referencia Exploradores del Cielo. Se conservan PNG y créditos sin editar; el juego los amplía con nearest.

Origen SpriteCollab, commit 6ad5f1c6229af6b055de2c64442e5e508664290c, ya fijado por el proyecto. data/portraits.json conserva URL/hash/créditos de los 12 archivos. Importador explícito npm run godot:import:portraits; el verificador habitual comprueba hashes. No hay descargas al jugar, nuevas dependencias ni plugins. CREDITS nativo y licencia existente actualizados; hojas originales y fuentes web sin modificar.

Se consulta la skill Godot para composición, tipos y API real del motor; no se incorporan sus autoloads de ejemplo porque el laboratorio ya tiene su controlador.

## Comprobaciones ejecutadas

- Importación/ejecución en Godot 4.7.2 real y exportación Windows 0.13.2 con metadatos de versión alineados.
- Paridad: 16 batallas completas, 506 órdenes y 25 escenarios, sin discrepancias. Hashes de 41 recursos, 13 fuentes de referencia y 12 archivos de retrato verificados.
- Fuente y ejecutable: cuatro batallas completas, 73 órdenes aliadas y 1.017 aserciones por ejecución; 17 rectificaciones aceptadas con estado anterior íntegro y 56 intentos bloqueados tras actuar/terminar. Continúan los mismos resultados y número de órdenes que en 0.13.1.
- Guardar/cargar después de moverse, después de rectificar y tras confirmar fuego aliado; RNG/recursos exactos. Guardado user:// aislado y limpio, sin usar la partida normal.
- Menú según equipo activo, submenú real visible, cancelación, orientación, teclado F1/flechas y clic real enviado al viewport; confirmación de áreas con aliados.
- Renderizado revisado en 1024×720, 1280×900 y 1440×1000; menú, habilidades, botón para rectificar habilitado, fichas y previsiones. Capturas desde viewport, sin automatización del escritorio.
- Ejecutable probado desde su distribución con GODOT_BIN apuntando a un editor inexistente. ZIP verificado contra el hash del binario.
- Linter de la skill antes/después: dos falsos positivos existentes por rutas formateadas thumbnail/%d y audio/%s; no informa problemas nuevos. Motor real e integridad verifican esos recursos. Sintaxis Node y diff sin errores. No se repite la suite web al no cambiar sus fuentes.

Evidencia: [fuente](qa/sprint-13-context-menu/ui-source-result.json), [ejecutable](qa/sprint-13-context-menu/ui-release-result.json), [paridad](qa/sprint-13-context-menu/parity-result.json), [paquete](qa/sprint-13-context-menu/release-info.json), [menú](qa/sprint-13-context-menu/native-menu.png), [habilidades](qa/sprint-13-context-menu/native-skills.png), [previsión](qa/sprint-13-context-menu/native-attack.png).

Las pruebas son automatizadas y no miden diversión ni equivalen a sesiones humanas. No se anuncia el recuento de clics de 0.13.1 como métrica de este nuevo menú: sus pasos son diferentes.

## Entrega y límites

Ejecutable y ZIP fuera de Git, en ../releases/pokemon-tactics-0.13.2/windows y ../releases/pokemon-tactics-0.13.2-windows.zip respecto al repositorio. Conservan licencias, créditos e instrucciones. Rama privada codex/sprint-13-context-menu; sin publicación ni cambio de rama predeterminada.

Continúa el laboratorio 8×8 de seis especies. Campaña de Rojo, mapas grandes, isometría/alturas, Walk y pruebas con otras personas quedan pendientes. No se modifica el balance. La composición queda disponible para que el creador la contraste con sus siguientes referencias.
