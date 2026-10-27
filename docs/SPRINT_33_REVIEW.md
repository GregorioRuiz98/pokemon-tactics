# Revisión de campaña y entrega — 0.33.0

27 de octubre de 2026. Windows local, edición 26/capítulo 30/combate 23.
Balance numérico conservado. Publicación pública aplazada.

## Qué se ha hecho

- Recorrido de las 58 localizaciones desde Oak hasta Mew/Mewtwo, con órdenes
  legales, capturas, tiendas, ocho medallas y ambos desafíos legendarios.
- Reproducción del diario completo en la interfaz nativa, con guardado por orden
  y recarga final. Se compara el estado con el recorrido de reglas.
- Revisión de PP, curaciones repetidas, etapas permanentes, estados, IA,
  habilidades, menús grandes y presentación.
- Guía vigente centralizada y paquete de pruebas para otro equipo.

Es **una campaña natural controlada por un jugador automático** y una
reproducción nativa, no una sesión humana externa. No se han regalado Pokémon,
dinero, PS, niveles, victorias ni medallas. Los escenarios sintéticos de UI y
las pruebas unitarias se identifican aparte.

## Recorrido y límites

Semilla `release-33-kanto`, inicial Bulbasaur, mapa 16. El diario completo contiene
7.838 órdenes. Se recorren también los desvíos, no solo los nodos obligatorios.
Los gimnasios conceden su insignia, los dos encuentros legendarios no permiten
captura y su orden es Liga/rival → aves → tienda → Mew/Mewtwo. El guardado final
se reconstruye desde el diario y conserva el mismo estado y azar.

**Límite de rendimiento detectado:** la recarga final del EXE tarda 37.447 ms
(unos 37 segundos) en este equipo, al reconstruir las 7.838 órdenes. La carga
es síncrona y durante ese intervalo la interfaz no responde. El estado se
recupera correctamente, pero esto necesita una mejora específica antes de
considerar pulida la experiencia de continuar una campaña larga. No se ha
saltado la validación del diario para ocultar ese tiempo. El dato se conserva
como `reloadMsec` en la evidencia del ejecutable.

Se conservan resultados desfavorables: un primer intento de la edición 25 cae en
Ruta24; otro de la 26 llega a un estancamiento en Erika. Para probar una mejor
composición se inicia una nueva reproducción desde Oak de su prefijo legal,
cambiando la preparación antes de Erika. El diario ganador contiene todo el
recorrido, sin saltos de estado ni resurrecciones inyectadas. No se afirma que
todos los iniciales o semillas estén validados hasta el final.

Las rondas son útiles para revisar ritmo; los segundos de ejecución automática
no representan tiempo de decisión humano. Erika alcanza 34 rondas y las aves 21;
la mediana global es de seis rondas. Se realizan 55 capturas y 30 compras de EXP. El CSV por encuentro conserva las
rondas, órdenes, niveles, límite, dinero y recompensa observados. No se cambian
potencia, estadísticas, EXP, precios, premios ni niveles para reducir esos picos.

## PP e IA

Las técnicas siguen sin coste por uso: no se añaden enfriamientos, un sexto
contador de curación ni límites de turnos ocultos. La campaña observa hasta 16 recuperaciones de una misma técnica/objetivo en
un encuentro; las pruebas unitarias realizan más de cinco recuperaciones y verifican PS máximos y contadores antiguos intactos.
Las etapas siguen permanentes y limitadas a ±2; sueño y demás estados conservan
sus duraciones, bloqueos y protecciones anteriores.

El límite total de mejoras **ya impedía** una técnica sin efecto en 0.32. La
corrección real de esta entrega ajusta la valoración de la IA cuando solo una
parte de la mejora tiene espacio, y distingue correctamente efectos sobre el
usuario de los aplicados al objetivo. No puntúa de nuevo una cobertura de zona
que ya está activa y le queda duración suficiente. La elección de curación usa
los PS realmente recuperables. Son cambios de decisión, sin alterar los efectos
de las técnicas; por eso tienen edición nueva y replay anterior conservado.

El estancamiento observado en Erika combina un único superviviente defensivo,
Descanso y un manantial. No es un error de gasto de PP: la curación y la limpieza
del estado funcionan como indican sus reglas. La reproducción ganadora cambia
la composición para tener cobertura y consigue avanzar. Se registra como
combinación que requiere prueba humana y respuestas tácticas, sin imponer una
penalización nueva al jugador. No se presenta como balance cerrado.

## Habilidades

Se comprueban las 78 habilidades normales activas, incluidas las 30 completadas
en 0.32. Presión ya reduce 1 movimiento al comenzar dentro de aura 2, mínimo 1 y sin
acumulación. No se ha vuelto a implementar ni cambiado a un coste por uso.
Viscosidad impide desplazamiento forzado; el catálogo no tiene retirada de
equipables, así que no se añade un movimiento nuevo solo para crear esa interacción.
Las adaptaciones y excepciones siguen en [la tabla de climas](SPRINT_32_CLIMATE.md).

## Presentación y menús

Doce motivos visuales nuevos distinguen embestidas, mandíbulas, puños, agujas,
chorros, pulsos, ascuas, rocas, estrellas, polvos, plumas y huevos. Se reutilizan
recursos locales; no se sustituyen las muestras características originales,
incluida Hiperrayo. Se respetan volumen, silencio y movimiento reducido. Los
efectos no consumen RNG ni modifican la partida. La prueba visual renderiza once
motivos representativos; la tabla de estilos declara doce familias.

Las etiquetas del tablero distribuyen sus posiciones para reducir choques.
Unidad activa y unidad inspeccionada expanden la información; las otras muestran
su estado principal y contador de detalles. PS, previsión, equipo y aviso de
vigía se conservan. Navegar al equipo, a otra ficha o a un combate retira avisos
transitorios anteriores que tapaban la pantalla.

Se prueban seis miembros, 140 reservas de especies no legendarias y una biblioteca
de movimientos por nivel/MT compatible grande, incluyendo 1024×768 y texto 150 %.
Son escenas de estrés separadas, no capturas añadidas a la campaña natural.

## Documentación y entrega

[REGLAS_ACTUALES.md](REGLAS_ACTUALES.md) es la referencia: PP al equipar, sin
caramelos/piedras/cables utilizables; EXP desde Equipo → Ficha; finales
consecutivos, estados temporales y atributos durante el combate. README, guía
Godot, producto, plan y guía Windows apuntan a ella. Los informes de versiones
anteriores se conservan como historial, sin reescribir sus evidencias.

El paquete incluye `Comprobar-equipo.cmd`, que abre un diagnóstico con perfil
aislado y escribe un informe de arranque/renderizado. Se verifica además el EXE
copiado a una carpeta limpia y sin Godot en PATH, en **este mismo ordenador**.
Eso no acredita otra GPU, otro Windows, DPI real distinto ni usuarios externos.

Pendiente de personas/equipos externos: arranque en otro ordenador físico,
rendimiento y DPI reales, lector de pantalla y comprensión de menús sin ayuda.
La [guía de pruebas](PLAYTEST_WINDOWS.md) incluye matriz y plantilla de incidencias.
No se han enviado mensajes ni distribuido el juego a terceros automáticamente.

## Evidencias

505 comprobaciones de reglas en fuente. Por cada versión de desarrollo/EXE:
46 de presentación, 112 de clima/mentas, 270 de iconos y 15 de sueño; la campaña
nativa completa aporta 15.693
comprobaciones adicionales por versión. Validación: 0 errores, 65 advertencias
históricas, ninguna nueva; revisión estática sin incidencias.

Resultados de reglas, UI en desarrollo/EXE, campaña completa, arranque aislado,
capturas, equivalencia de estados y hashes del paquete en `docs/qa/sprint-33/`.
Se distinguen pruebas automáticas, inspección de capturas y validación humana
externa pendiente. La actualización 25→26 es voluntaria entre encuentros, con
copia, conservando equipo, niveles, PS, dinero y diario. KT33 nuevo; códigos y
guardados anteriores conservados. Módulos/datos/tests/recursos publicados intactos.
