# Corrección del movimiento durante el sueño — 0.31.1

El sueño impedía usar movimientos, pero el cálculo de rutas no consultaba ese estado. Por eso el tablero y la IA todavía ofrecían desplazamientos.

La corrección devuelve cero rutas voluntarias para una unidad dormida y rechaza el comando directo de desplazamiento, con un motivo visible. Afecta a ambos equipos y a los acercamientos; la IA termina la activación. Al despertar vuelven las rutas normales. La ficha muestra «Dormido» y la inspección identifica el movimiento bloqueado.

Se conserva la duración por activaciones, la posibilidad de orientar/terminar, los manantiales, las acciones de otros Pokémon contra el dormido y los desplazamientos forzados. No cambia otros estados, PP, daño, precios, EXP ni mapas.

## Partidas existentes

Las reglas publicadas se conservan para reconstruir los diarios. Nuevos módulos `sleep_battle/run/store/challenge`, campaña24/capítulo28 y combate21, sin contenido nuevo de campaña.

Al cargar una partida de0.31.0 se añade una transición reproducible y se guarda una copia previa automáticamente. También funciona con un combate empezado: conserva unidades, posiciones, estados, PS, mapa, manantiales, cola y RNG. No se deshacen movimientos ya aceptados. La rectificación de movimientos empieza desde el punto de corrección, para no reconstruir antiguas órdenes de sueño con reglas distintas. El diario completo de campaña permanece intacto.

Las campañas anteriores a0.31 mantienen su actualización voluntaria entre encuentros. Los retos nuevos usan KT31S; los formatos históricos siguen siendo legibles. Las pruebas históricas se fijan a su edición y no se modifican para aceptar el arreglo.

## Comprobaciones

- 35 comprobaciones de reglas: bloqueo de rutas/comando/ataque/acercamiento para ambos bandos, IA, consultas puras sin gasto ni RNG, duración y movimiento al despertar, parálisis y manantial conservados, objetivos dormidos atacables, transición en pleno combate y replay23→24.
- 15 comprobaciones de interfaz en fuente y EXE: carga y copia automática de23, ficha y casillas, clic, teclado, rechazo sin mutación, vuelta de las casillas al despertar, apertura natural/captura/carga y ayuda. El estado dormido de UI es un escenario explícito que se restaura antes de continuar el diario real.
- 233 comprobaciones de regresión de PP en fuente y EXE, con edición23 explícita. Coincidencia de estados entre ambas versiones.
- Lint sin incidencias y validación: cero errores,65 advertencias históricas, ninguna nueva. Motores/datos/tests/recursos publicados intactos. EXE offline, ZIP comprobado e inventario SHA256; evidencia en `docs/qa/sprint-31-ui-1`.

No se ha realizado una partida humana completa. No se publica el juego en Internet.
