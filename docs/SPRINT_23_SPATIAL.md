# 0.23.0 — Movimientos espaciales

Se aplica la auditoría aprobada del 24 de octubre al catálogo actual: 211 movimientos y básico. La [tabla aplicada](reports/moves-2026-10-24/aplicacion-0.23.csv) permite revisar cada forma, zona, desplazamiento, coste mínimo y adaptación. La tabla original se conserva; sus 15 movimientos exclusivamente históricos no se incorporan a los repertorios de Let’s Go.

## Jugar

Usa el ejecutable 0.23.0. Las aventuras nuevas utilizan edición 19 / combate 18. Una aventura anterior ofrece actualización desde el mapa, tienda o final, con copia y diario conservados. Un combate en curso termina con sus reglas anteriores antes de permitir actualizar. No hace falta borrar la partida.

Elige la habilidad y apunta con flechas o ratón, también a casillas vacías. El tablero anticipa toda el área; la ficha indica daño, precisión, desplazamientos y riesgo a aliados. Enter/clic acepta; el fuego amigo y los costes letales requieren confirmación. Q/E gira las pantallas y el destino de un lanzamiento. Escape cancela. El básico y el desplazamiento directo se conservan.

## Cambios aplicados

| Sistema | Comportamiento |
|---|---|
| Formas | Líneas perforantes, cruces, conos, anillos, rombos, franjas, aspas, olas y estrella de siete casillas. Incluyen aliados y respetan bordes, obstáculos y visión. Las ondas terrestres no saltan acantilados. |
| Humo | Cruz de cinco casillas. Una sola penalización local de precisión ×0,75 al salir de humo o atravesarlo con una trayectoria visual. No se suma por casilla. Vista Lince, Indefenso, técnicas infalibles, sonidos y ondas terrestres conservan sus excepciones. |
| Zonas | Gas venenoso, fuego, lodo, seda y rocas. Veneno al entrar/comenzar; fuego y rocas causan daño con límite por activación. Rocas se consumen al activarse. Voladores, Levitación y Botas Gruesas conservan las excepciones implementadas. Lodo/seda/fuego cuestan +1 al atravesarlos por tierra. |
| Duración | Una zona persiste el resto de la ronda de creación y dos rondas completas más. El número visible indica las rondas completas restantes, con mínimo 1 durante su última ronda. |
| Pantallas | Reflejo/Pantalla Luz reducen ×0,75 una vez el daño físico/especial que cruza sus casillas; no bloquean movimiento. Neblina impide bajadas hostiles dentro. Barrera bloquea paso y visión y no concede además Defensa. No permite ocupar unidades ni cerrar todas sus salidas inmediatas. Demolición destruye también una casilla de barrera vacía adyacente. |
| Movimiento forzado | Empujes, atracciones, cargas, saltos, retirada y lanzamientos. No atraviesan destinos ocupados ni paredes; respetan alturas. Ventosas impide desplazamiento. Entrar por empuje en una trampa la activa. No hay daño extra de colisión. |
| Interacciones | Agua apaga fuego; viento dispersa humo/gas; un agarre encarece alejarse. Tornado empuja solo al primer rival del corredor. |
| Control | Anulación, Mofa, Otra Vez, Bostezo y Sorpresa tienen reglas reales y visibles. Los controles nuevos duran una activación afectada. Sueño por canto/polvos/esporas dura una activación; tras sueño/congelación hay una ventana breve de resistencia. Estados y etapas restantes conservan tres activaciones. |
| Técnicas especiales | Mimético copia una ranura durante el combate; Espejo repite una técnica recibida válida; Metrónomo sortea al confirmar entre tres técnicas seguras y muestra un intervalo sin revelar el azar. Sustituto tiene PS propios, Conversión cambia tipo, Venganza acumula y devuelve daño acotado, Furia prepara una subida al recibir daño. Refuerzo mejora un ataque; Amortiguador puede curar aliados. Triataque sortea como máximo un estado por impacto (20 % total; quemadura, hielo o parálisis), respetando inmunidades. |
| Integridad | IA, previsión y jugador usan las mismas reglas. El cursor y las animaciones no consumen azar. Las consecuencias de zonas y las tiradas no se pueden rectificar. Recursos, daño, estados y bajas se guardan antes de animar. |

Las áreas parten de daño ×0,8 y suelo de 3/4 PT según extensión; fuego residual y bombas de humo tienen ajustes concretos en la tabla. Explosiones cuestan 5 PT; las salvas reparten un presupuesto total de daño. Vidaesfera, retroceso y autodebilitamiento se pagan una vez por acción. Son valores provisionales, **no un balance cerrado**. Día de Pago concede 25 ₽ extra por victoria, como máximo una vez por encuentro.

Las alternativas se han resuelto así: Psíquico en cruz, Barrera como muro, Drenadoras dirigida, Salpicadura como salto corto, Sustituto como escudo del usuario. No se añaden simultáneamente las variantes alternativas de la auditoría. Daños por peso/nivel de Patada Baja, Tinieblas, Psicoonda y Bomba Sónica conservan su adaptación previa; la auditoría proponía revisarlos aparte.

## Imagen y sonido

Las secuencias distinguen rayos, hielo, electricidad, hojas, burbujas, látigos, ondas de sonido, portales, explosiones, vínculos y lanzamientos. Hiperrayo tiene carga, haz con núcleo y anillos propios. Las zonas dejan símbolos distintos sobre sus casillas y muestran duración. Los controles nuevos y Sustituto aparecen sobre el Pokémon y en su ficha. Se conservan movimiento reducido, volumen, silencio y cancelación al navegar. Son dibujos nativos y variaciones por movimiento; no 211 animaciones dibujadas a mano.

Se importan **40 WAV originales del banco público PokeDot-Engine**, incluido `PRSFX- Hyper Beam.wav` completo. Se mantienen sus bytes y hashes; el volumen se ajusta al reproducir. Algunas otras muestras corresponden a una fase nombrada `1` en ese banco. No se afirma una edición concreta de cartucho ni una secuencia completa de varias fases para todos los ataques. Los demás utilizan el banco propio de 26 sonidos. Procedencia y derechos: [manifiesto](../godot/assets/original-moves/manifest.json), [créditos](../godot/CREDITS.md). Ninguna descarga al jugar.

## Comprobación y límites

- Pruebas del catálogo completo y casos condicionados, geometría, zonas, movimiento, pantallas, control, habilidades conservadas y replay de edición 19. Script `godot:test:spatial`.
- QA nativa de teclado/ratón, suelo vacío, rotación, confirmaciones, movimiento reducido, cancelación, audio y guardado de un combate natural: `godot:qa:spatial`, también en EXE.
- Dos desafíos finales desde campañas ganadas con anterioridad y actualizadas de forma explícita, en 16/24 casillas. Son pruebas de continuidad y encuentros nuevos; no una campaña entera empezada desde cero con edición 19.
- Comparación de estados e historiales entre desarrollo y ejecutable, integridad de activos, validación de scripts y regresión del laboratorio/motor anterior. Resultados exactos en [evidencia](qa/sprint-23/release.json).

Resultado de esta entrega: **557 comprobaciones de reglas**, **63 de interfaz** por destino y **1121/575** en los desafíos de aves/origen. Estados y diarios completos idénticos en desarrollo y EXE; 406 archivos publicados conservados, cero errores y cero advertencias nuevas (65 anteriores).

La escucha humana, la diversión y el balance de composiciones/áreas siguen pendientes. No se presenta el informe de balance de 0.22 como validación de estas reglas. Publicación pública aplazada; entrega Windows offline y código en el repositorio privado.
