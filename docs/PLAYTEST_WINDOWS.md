# Probar Pokémon Tactics en Windows ·0.25.0

La interfaz reúne las órdenes en un menú táctico y los recursos/previsión en la franja inferior. La fila ámbar y su cursor indican la selección; las acciones rojas avanzan en la aventura. Teclado, ratón y atajos conservan las mismas funciones.

Descomprime el ZIP completo y abre **windows/PokemonTactics.exe**. Funciona sin cuenta, servidor, conexión o instalación de Godot. Mantén en la carpeta los créditos y licencias incluidos. Esta entrega es para pruebas; su publicación pública está aplazada.

Progresión0.24: curvas originales de EXP por especie; 1 ₽ por EXP pendiente, con revisión antes de pagar. Sin Caramelos/piedras/cables en la tienda. Capturas locales: otro sorteo cuesta60/120/180… ₽ antes de aceptar, con especie distinta si hay alternativas; insignias fijas. Gimnasios de4–6 Pokémon. Detalles y límites de balance en CAMBIOS_0.24.md dentro del paquete.

Fluidez0.24.1: el rival planifica en varios fotogramas y las previsiones de área reutilizan consultas. Conserva las decisiones y los guardados. Detalles en FLUIDEZ_0.24.1.md dentro del paquete.

Novedades0.25: preparación por clic o arrastre; B comienza y T alterna amenazas. Reto/F9 guarda una tarjeta y copia un código que se puede pegar como semilla en Oak. Gimnasios con arenas propias, misiones y recuperación para rezagados. Consulta CAMBIOS_0.25.md y sus límites de balance.

## Empezar o continuar

La pantalla de inicio ofrece **Continuar aventura**, **Nueva partida**, ayuda, opciones de sonido/animación, créditos y laboratorio. Continuar se desactiva cuando todavía no hay guardado. Desde el juego, **Inicio** o **Menú → Pantalla de inicio** vuelve a ella y pausa el combate. Escape permite volver a una aventura abierta. Cancelar la elección de otro inicial conserva tu campaña anterior.

Elige un inicial de Oak y una semilla; puedes comparar16×16 y24×24 antes del primer combate. La campaña guarda automáticamente cada orden aceptada. Cerrar y abrir permite continuar incluso durante una pelea, conservando iniciativa y azar.

La semilla se genera automáticamente al comenzar otra aventura. Junto a los iniciales puedes escribir o pegar una, pulsar Generar otra o Copiar. Si dejas el campo vacío también se genera una nueva. Durante la campaña, Menú → Copiar semilla de la campaña copia la original. Misma semilla y decisiones repiten los sorteos; cambiarla permite otras capturas dentro de la tabla local. Las tablas con pocas especies pueden repetir Pokémon entre semillas y los gimnasios conservan su recompensa insignia. Continuar una partida mantiene su semilla y su captura pendiente.

El guardado está en `%APPDATA%/PokemonTacticsLab/kanto-save.json`. La copia anterior usa `.bak`; comenzar otra campaña o ampliar una antigua también conserva una copia. Guarda esa carpeta si quieres transportar la partida a otro ordenador. La web y el laboratorio tienen archivos independientes.

Al cargar una campaña anterior, **Continuar aventura · ampliar Kanto** aparece en mapa, tienda o final del tramo. Actualiza conservando equipo, PC, PS, dinero y diario. Termina primero los combates, capturas o preparativos pendientes. Un final legendario ya terminado ofrece **Actualizar versión · conservar final**: la actualización no permite cambiar destino ni repetir sus recompensas. Una derrota sigue siendo derrota.

Si el guardado es incompatible, incompleto o ha cambiado desde otra instancia, el juego informa y conserva el archivo. Cierra la otra instancia y vuelve a cargar antes de seguir guardando. Evita abrir dos partidas sobre el mismo archivo a la vez.

## Combate y preparación

- **F2** abre Controles; también están en Opciones o en el menú general. Permite reasignar teclas, intercambiar conflictos, restablecer categorías y elegir repetición de navegación. Las etiquetas y la ayuda muestran tus asignaciones. Enter/Espacio, Escape, Tab y flechas siguen disponibles como teclas de seguridad; Ctrl y combinaciones de sistema no se reasignan.
- **F6** o Mayús+F6 alterna tablero/órdenes o viaje/equipo. Tab/Mayús+Tab recorre controles. Al elegir un Pokémon, comprar o cambiar página del PC se conserva el foco; si una orden deja de estar disponible se elige una alternativa válida. Las compras y órdenes requieren pulsaciones nuevas, aunque mantengas la tecla.
- Los controles se conservan al reiniciar en el archivo independiente controls.json, junto a tu guardado local. Sonido, animación, tamaño del texto y otras preferencias de presentación también se conservan.

- Clic en una casilla azul para moverte; clic en un enemigo para el básico. El menú derecho reúne las otras órdenes. **R** rectifica exclusivamente el movimiento, siempre antes de actuar; **F** permite orientar y terminar. Escape cancela la selección.
- Rueda o+/− para zoom; cruceta, Alt+flechas o modo P para desplazar cámara. Central opcional. **C** centra la unidad; **Combate/Mapa** cambia el encuadre y **G/H** alterna guías. Flechas y Enter permiten seleccionar casillas.
- Prepara hasta cuatro movimientos y conserva el básico neutro gratuito. Consulta tipo, precisión, daño previsto, PT y estado antes de atacar. Respiro, Recuperación, Amortiguador y Descanso tienen cinco usos por combate, además de sus PT.
- Las bajas individuales pueden recuperarse en tienda con Revivir al50% de PS. Perder todo el equipo desplegado termina la campaña aunque queden reservas vivas. No hay curación gratuita tras una victoria.
- **Comprar** ofrece Medicina, Evolución, MT y equipo y Rasgos. **Equipo y bolsa** permite elegir Pokémon y usar lo que ya posees en Objetos; Ficha, Movimientos y Rasgos muestran el resto por separado. Comprar añade a la bolsa. Comprar varias y Usar varias abren su propia revisión. **Seguir viaje** queda siempre visible; Resumen abre las ganancias del último combate.
- Capturas sobrantes van al PC. Cambiar miembros fuera de combate es gratis y conserva sus PS. El dinero permite curar, completar el siguiente nivel pagando la EXP pendiente desde Entrenar, comprar MT/equipables o renovar las tres ofertas.
- Los niveles tienen tope por insignia del siguiente gimnasio. La Liga permite65 y el postgame75. Una subida recupera los PS máximos ganados; las antiguas evoluciones por piedra/intercambio son gratuitas desde Ficha, con un nivel mínimo adaptado y sin curación.

## Sesiones de prueba propuestas

| Sesión | Qué observar |
| --- | --- |
| Inicio→Brock con cada inicial | Tiempo hasta reclutar, alternativas de cobertura, recursos y derrotas. Anotar semilla, tamaño y último encuentro. |
| Una ruta y un gimnasio intermedios | Si se entiende el siguiente destino, la tienda, el PC y los bloqueos narrativos. |
| Un mismo encuentro en16 y24 | Claridad de selección, alturas y cámara; desplazamientos sin decisiones interesantes. |
| Liga y uno de los finales | Preparación necesaria, bajas, uso del básico, duración y recuperación de los jefes. |
| Cerrar/reabrir en combate y tienda | Mismo equipo, PS, turno, objetos y dinero; sin repetir capturas o recompensas. |

Para una incidencia, conserva una copia del guardado y anota versión, semilla, tamaño, encuentro, orden realizada y resultado esperado/observado. Un vídeo o captura ayuda si afecta a selección o cámara. Para valorar diversión, anota también dónde tomaste una decisión interesante y dónde esperaste sin decidir.

Las pruebas automáticas acreditan reglas, integridad y recorridos concretos. No sustituyen estas sesiones humanas. Hay terreno provisional, efectos adaptados y29 habilidades normales sin condiciones implementadas, identificadas en ficha; no se presenta como réplica exacta de Pokémon Rojo o Let’s Go.

## Turno contextual0.22.3

- Habilidades por A o1–5: seleccionar nunca ejecuta, incluso los apoyos propios. Q/E recorre solo objetivos válidos con orden estable; Enter acepta. Escape cancela sin gastar. El hover no cambia la selección hecha con teclado.
- F2 ofrece Modo Seguro: una confirmación por acción. Desactivado usa Modo Rápido: aceptar un objetivo ejecuta. Ambos avisan y piden confirmar daño a aliados o coste propio potencialmente letal. Se conserva entre sesiones.
- Al mover y actuar se abre orientación; F la abre antes mostrando recursos sin usar. Flechas previsualizan, Enter termina; botones diagonales o clic en tablero ofrecen la alternativa de ratón. Escape vuelve sin terminar. Derecha del cursor suma X y se proyecta ↘; abajo suma Y y se proyecta ↙. La brújula lo recuerda.
- Cámara por cruceta visible, Alt+flechas o P seguido de flechas. P vuelve al cursor sin mantener teclas. Rueda/+− acerca; C centra. El botón central es opcional. Arrastrar con el izquierdo en modo P también desplaza; soltar un arrastre no da órdenes.
- R rectifica exclusivamente el movimiento anterior si todavía no hubo acción. Actuar antes de moverse también bloquea R.

Las pruebas inyectan eventos del viewport nativo en Windows. Falta la valoración con teclado/ratón físicos y tecnologías de apoyo por personas. No se añade todavía inspección persistente (prompt03), ampliación de texto (04) ni los demás bloques.


## Mejoras0.22.10

Aprender a jugar o F7 abre práctica separada de tu aventura; F7/Inicio sale y la restaura. F4 abre el glosario. I mantiene la ficha y lista de unidades; L repite resultados reales. Opciones ofrece texto100/125/150%, contraste, silencio y movimiento reducido; F12 recupera texto100% y contraste normal. Tienda permite cantidades con revisión previa; PC y biblioteca admiten búsqueda/filtros sin alterar el equipo real. El final legendario pide confirmación. El modo textual es un prototipo: soporte de lector real pendiente.

Guion de aceptación, consentimiento y plantillas en reports/aceptacion-0.22.10/KIT_HUMANO.md; en el ZIP, PRUEBAS_HUMANAS/KIT_HUMANO.md. No sustituir una partida personal para probar fixtures.


## Arte integrado 0.22.16

Las 42 imágenes del juego están generadas e integradas: portada, escenas, suelos, obstáculos, iconos y efectos. Los Pokémon conservan sus recursos originales. ARTE incluye los PNG, prompts, contratos y procedencia. Las tres imágenes promocionales opcionales siguen pendientes. Revisar la lectura del tablero, los efectos y el contraste con el tamaño de texto preferido.


## Ataques y sonido

Los ataques muestran preparación, recorrido e impacto según su familia y tipo. Puedes seguir dando órdenes sin esperar; esto corta el efecto anterior. En Opciones, el volumen y silencio afectan también a los sonidos nuevos. Movimiento reducido elimina desplazamientos y partículas animadas y conserva un resultado estático. El último golpe pasa directamente a recompensa con su sonido de impacto.
