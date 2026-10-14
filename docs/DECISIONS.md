# Decisiones de preparación

13 de octubre de 2026.

- Base adaptada de `phaserjs/template-vite-ts`, commit registrado en `tools/sources.lock.json`. Se conservan enfoque de arranque, configuración de TypeScript y separación del motor en la compilación. Se retiran escenas de ejemplo y llamadas de telemetría. Vite queda fijado al parche 6.4.4 compatible; Phaser 4.0.0 y TypeScript 5.7.3.
- Datos reales de Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude. El catálogo se valida al cargar. No se generan aún los tres miembros aleatorios de una partida.
- Reutilización directa de `parse_animdata`, `resolve` y `ground_anchor` del importador MIT de PokéSurvivor. El archivo original permanece en `tools/vendor` con versión fija. El adaptador limita la descarga a seis especies normales y dos animaciones.
- Recursos SpriteCollab originales sin recolorear; miniaturas derivadas del primer fotograma. Suelo de la escena dibujado mediante primitivas; no requiere un tileset para esta galería.
- Las coordenadas de sprite representan el punto de apoyo obtenido de las hojas de sombra. Duraciones de animación convertidas desde ticks de 60 Hz. El marco incluye ocho direcciones; la UI ofrece cuatro cardinales.
- Solo carga local durante la ejecución. Font local. Sin cuentas, analítica, claves, nube ni persistencia de partidas.
- Guardado, tabla de efectividad, daño, iniciativa y tablero se incorporarán en sus sprints. Los tipos y estadísticas mostrados ya son los datos modernos.
- El primer objetivo es PC. La galería se revisa también en 390 px para evitar desbordamientos, sin comprometer soporte completo de juego móvil.
- La carpeta del proyecto tiene un repositorio Git propio en `codex/sprint-0`. La inspección inicial detectó un repositorio ajeno en la carpeta personal; no se cambió su configuración ni contenido.

Valores de iniciativa, puntos tácticos, estados y duración siguen siendo propuestas del plan. No se han convertido en mecánicas por aparecer en esta documentación.

## Sprint 1

- EasyStar 0.4.4 se integra como dependencia fija: A* con costes de terreno, cuatro direcciones y ocupantes excluidos. En 64 casillas la búsqueda síncrona de rutas es suficiente; no se implementa un algoritmo propio paralelo. Versión e integridad en package-lock.json, licencia local.
- Todas las unidades usan perfil terrestre provisional. Suelo 1, maleza 2, rocas y agua infranqueables. Geodude dispone de 3 puntos, Pikachu 5, el resto 4; son parámetros para probar legibilidad y control, pendientes de equilibrio.
- El coste se cobra al confirmar, con una nueva validación del camino y la ocupación. La trayectoria previa y su cancelación no alteran estado. Durante el desplazamiento se bloquean órdenes; pausa/reanudación permanece accesible.
- El ensayo permite repartir el presupuesto entre varios desplazamientos hasta reiniciar. El sprint 2 sustituirá este contexto libre por activaciones y rondas.
- Los sprites y estadísticas del sprint 0 se reutilizan sin nuevas descargas de especies. El terreno se dibuja con primitivas de Phaser. La cuadrícula HTML aporta nombres de casilla, selección y teclado equivalentes al canvas.
- Playwright 1.64.0 queda como dependencia de desarrollo, con prueba de navegador reproducible. No se incluye en el juego de producción.

## Sprint 2

- Tres aliados fijos (Bulbasaur, Charmander, Squirtle) y tres enemigos (Pikachu, Butterfree, Geodude). Se reutilizan tablero, sprites, estadísticas y EasyStar; no hay nuevos paquetes ni descargas de especies.
- PRNG local con semilla de texto, sin dependencia adicional. Se sortean velocidad y desempate una vez por unidad al empezar la ronda; ±5 % por defecto, opción ±10 %. La cola no vuelve a sortearse por inspeccionar, mover o atacar.
- Una acción y un único desplazamiento continuo por activación, en ambos órdenes. El botón terminar renuncia a recursos pendientes. Presupuestos terrestres heredados del ensayo.
- PS máximos: `round(35 + PS_base / 3)`. Daño básico físico: `max(5, round(12 + ataque_base × 0.18 − defensa_base × 0.10))`, limitado a los PS del objetivo. Precisión fija 100 %. Fórmulas provisionales, sin tabla de tipos ni ataque especial.
- Alcance 1 para Bulbasaur, Pikachu y Geodude; 2 para Charmander, Squirtle y Butterfree. Distancia Manhattan; las casillas intermedias bloquean disparos y las diagonales cortas requieren ambos lados libres. Estos perfiles básicos se revisarán junto a las identidades del sprint 3.
- La IA usa las mismas reglas: ataca un objetivo legal, busca un camino a una posición de ataque o espera. Elige por coste, PS e ID, sin consumir tiradas ni mostrar intenciones futuras. La política también permite simulaciones reproducibles en pruebas.
- Las bajas conservan registro con PS 0, pero dejan ocupación, sprites y turnos pendientes. Victoria/derrota inmediata al caer la última unidad de un bando. Reiniciar invalida el bucle de IA anterior.
- Se conserva el ensayo en `?view=training` y la galería en `?view=camp`. No se incorpora aún progreso de run, curación, reclutamiento ni guardado.

## Requisitos de jugabilidad pendientes — 14 de octubre de 2026

- Registrar para el sprint 4 un botón de orientación al finalizar cada turno, junto con las bonificaciones por atacar flancos y espalda. El jugador elige una dirección cardinal antes de ceder la activación; esa dirección determina la posición relativa de los ataques posteriores.
- Registrar para el mismo sprint que el desplazamiento pueda atravesar aliados. El destino debe estar libre y los enemigos siguen bloqueando el paso; previsualización, confirmación e IA deben compartir esta regla.
- Son decisiones para implementar más adelante. El combate de la versión 0.2.1 todavía usa precisión fija del 100 %, orientación automática por movimiento/ataque y ocupación que impide atravesar cualquier unidad.

## Sprint 3 — POO, 14 de octubre de 2026

- El usuario solicita POO para facilitar la introducción de herencia entre Pokémon. Se incorpora base `Pokemon`, seis especializaciones y jerarquía de acciones; los tipos y las relaciones futuras de evolución permanecen como datos. Las clases contienen comportamiento; el estado sigue siendo serializable y se copia al resolver órdenes. Ver `ARCHITECTURE.md`.
- Se reutilizan `types.csv` y `type_efficacy.csv` de PokéAPI en el mismo commit ya fijado. Se importan 18 tipos estándar y 324 relaciones; Stellar no forma parte de este combate. Fuentes y dos hashes en `tools/vendor/pokeapi/sources.json`.
- Se añaden dos habilidades y un básico gratuito por especie, PT, veneno/quemadura/parálisis, absorción y protección. Son adaptaciones tácticas; precisiones, potencias, alcances, costes y duración se definen con las acciones. Reglas y excepciones en `SPRINT_3.md`.
- Iniciales y Control son dos equipos fijos de prueba con los mismos seis recursos, intercambiando bandos. No representan todavía selección aleatoria, reclutamiento ni sustitución durante una run.
- El PRNG resuelve precisión y estados secundarios al confirmar. El gasto se valida de nuevo y se aplica incluso si la orden falla. IA y previsión usan el mismo contrato de acción.
- Orientación final manual y paso por aliados siguen pendientes del sprint 4. No se implementan progresión, mapa de ruta, guardado ni evolución en esta entrega.

## Sprint 4 — Posición y terreno, 14 de octubre de 2026

- Se implementan las peticiones de orientación final y paso por aliados. La orientación se elige antes de ceder la activación y se confirma; la ruta permite tránsito aliado, exige destino libre y bloquea enemigos. El ensayo conserva sus reglas históricas.
- Precisión provisional 85/95/100 % para un básico según frente/flanco/espalda; otras precisiones usan −15/−5/0 puntos porcentuales. Diagonales por proyección sobre el eje de orientación, con empate en ese eje. No se añade bonus de daño por ángulo.
- Perfiles derivados de tipos: Planta mejora maleza, Agua permite cruzar agua y Volador cruza agua/maleza. Roca bloquea movimiento y visión; agua permite visión. Se conserva la regla de ambas esquinas libres para disparos diagonales cortos.
- Lanzallamas y Polvo Veneno reciben área en cruz con aliados afectados y lanzador excluido. Lanzallamas se prueba con potencia 70 y ascuas de 4 PS al cerrar turno; Lanzarrocas añade empuje de una casilla. Límites, probabilidades, inmunidades y caducidad en `SPRINT_4.md`.
- La IA usa las mismas previsiones espaciales y rutas. Se corrige la selección parcial de ruta para que agotar presupuesto sobre un aliado no produzca una orden inválida. La orientación defensiva y la decisión táctica no consumen PRNG.
- No se añaden especies, dependencias, recursos de red en ejecución, progresión, guardado ni encuentros de run. Equilibrio y variedad de estrategias quedan para prueba del usuario antes de avanzar.

## Feedback posterior — equilibrio aplazado

- El usuario ha probado el sprint 4 y considera que se elimina demasiado fácilmente a los rivales en 3v3.
- Su instrucción posterior es conservar los parámetros actuales y esperar a definir mejor el juego antes de equilibrarlo. La revisión iniciada fue solo de lectura; no cambió código ni valores.
- Revisar el repertorio temprano de Charmander, especialmente Lanzallamas, es una posible vía para más adelante. No se ha decidido sustituirlo, reducirlo ni reservarlo para una evolución.
