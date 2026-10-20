# Probar Pokémon Tactics en Windows ·0.22.2

Descomprime el ZIP completo y abre **windows/PokemonTactics.exe**. Funciona sin cuenta, servidor, conexión o instalación de Godot. Mantén en la carpeta los créditos y licencias incluidos. Esta entrega es para pruebas; su publicación pública está aplazada.

## Empezar o continuar

La pantalla de inicio ofrece **Continuar aventura**, **Nueva partida**, ayuda, opciones de sonido/animación, créditos y laboratorio. Continuar se desactiva cuando todavía no hay guardado. Desde el juego, **Inicio** o **Menú → Pantalla de inicio** vuelve a ella y pausa el combate. Escape permite volver a una aventura abierta. Cancelar la elección de otro inicial conserva tu campaña anterior.

Elige un inicial de Oak y una semilla; puedes comparar16×16 y24×24 antes del primer combate. La campaña guarda automáticamente cada orden aceptada. Cerrar y abrir permite continuar incluso durante una pelea, conservando iniciativa y azar.

El guardado está en `%APPDATA%/PokemonTacticsLab/kanto-save.json`. La copia anterior usa `.bak`; comenzar otra campaña o ampliar una antigua también conserva una copia. Guarda esa carpeta si quieres transportar la partida a otro ordenador. La web y el laboratorio tienen archivos independientes.

Al cargar una campaña anterior, **Continuar aventura · ampliar Kanto** aparece en mapa, tienda o final del tramo. Actualiza conservando equipo, PC, PS, dinero y diario. Termina primero los combates, capturas o preparativos pendientes. Un final legendario ya terminado ofrece **Actualizar versión · conservar final**: la actualización no permite cambiar destino ni repetir sus recompensas. Una derrota sigue siendo derrota.

Si el guardado es incompatible, incompleto o ha cambiado desde otra instancia, el juego informa y conserva el archivo. Cierra la otra instancia y vuelve a cargar antes de seguir guardando. Evita abrir dos partidas sobre el mismo archivo a la vez.

## Combate y preparación

- **F2** abre Controles; también están en Opciones o en el menú general. Permite reasignar teclas, intercambiar conflictos, restablecer categorías y elegir repetición de navegación. Las etiquetas y la ayuda muestran tus asignaciones. Enter/Espacio, Escape, Tab y flechas siguen disponibles como teclas de seguridad; Ctrl y combinaciones de sistema no se reasignan.
- **F6** o Mayús+F6 alterna tablero/órdenes o viaje/equipo. Tab/Mayús+Tab recorre controles. Al elegir un Pokémon, comprar o cambiar página del PC se conserva el foco; si una orden deja de estar disponible se elige una alternativa válida. Las compras y órdenes requieren pulsaciones nuevas, aunque mantengas la tecla.
- Los controles se conservan al reiniciar en el archivo independiente controls.json, junto a tu guardado local. Las opciones de sonido y animación todavía se aplican por sesión; escala de texto, cámara por pulsaciones y confirmación de habilidades propias pertenecen a los siguientes bloques.

- Clic en una casilla azul para moverte; clic en un enemigo para el básico. El menú derecho reúne las otras órdenes. **R** rectifica exclusivamente el movimiento, siempre antes de actuar; **F** permite orientar y terminar. Escape cancela la selección.
- Rueda o+/− para zoom; botón central para desplazar cámara. **C** centra la unidad; **Combate/Mapa** cambia el encuadre y **G/H** alterna guías. Flechas y Enter permiten seleccionar casillas.
- Prepara hasta cuatro movimientos y conserva el básico neutro gratuito. Consulta tipo, precisión, daño previsto, PT y estado antes de atacar. Respiro, Recuperación, Amortiguador y Descanso tienen cinco usos por combate, además de sus PT.
- Las bajas individuales pueden recuperarse en tienda con Revivir al50% de PS. Perder todo el equipo desplegado termina la campaña aunque queden reservas vivas. No hay curación gratuita tras una victoria.
- La tienda separa **Objetos**, **MT y equipo** y **Rasgos**. Las fichas del equipo muestran retrato y barra de PS; los curativos se usan desde la ficha seleccionada. **Seguir viaje** permanece visible al final del panel aunque desplaces las ofertas.
- Capturas sobrantes van al PC. Cambiar miembros fuera de combate es gratis y conserva sus PS. El dinero permite curar, subir niveles con Caramelos, comprar MT/equipables o renovar las tres ofertas.
- Los niveles tienen tope por insignia del siguiente gimnasio. La Liga permite65 y el postgame75. Una subida recupera los PS máximos ganados; las piedras evolutivas no curan.

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
