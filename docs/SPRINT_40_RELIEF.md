# Sprint 40 — mapas con relieve

Campaña 30, capítulo 34, combate 25; producto 1.0.0-rc.3. Los 58 lugares reciben
terrazas amplias, aproximaciones por tierra y un elemento propio. Se reutilizan
texturas y objetos locales, con sus hojas y manifiestos originales intactos.
[Catálogo completo](MAPAS_RELIEVE.md).

## Implementación

- `relief-maps.json`: catálogo explícito, reproducible mediante
  `tools/godot/author-relief.py`. Tres o cuatro cotas, senderos, obstáculos,
  despliegues y posiciones de ambos equipos. El formato 24 centra la arena
  diseñada de 16 y prolonga sus bordes, sin multiplicar enemigos.
- `relief_maps.gd` y `relief_battle.gd`: aplican la geometría y conservan
  equipos, movimientos, recompensas, clima y objetivos publicados. Los
  puntos de misión y los transportadores se protegen y verifican por tierra.
- `relief_run.gd`, `relief_store.gd`, `relief_challenge.gd`: nueva edición,
  códigos KT40 y actualización voluntaria fuera de combate. Los motores
  antiguos conservan sus archivos y resultados.
- `relief_board.gd`: relieve visual de 20 píxeles por cota, frente a los 12
  anteriores; colores de pared por entorno, senderos, escaleras y motivos.
  Escenografía y unidades comparten orden de dibujo; las copas se atenúan.
  La caché evita reconstruir el suelo cuando solo se redibuja una unidad.

La altura usa las reglas de movimiento, alcance y visión ya existentes. No hay
plantas superpuestas sobre una misma coordenada ni una nueva bonificación de
daño. Los pasos sobre agua son superficies continuas, no puentes transitables
también por debajo.

El lector actual también admite ediciones 13–18 con sus recursos disponibles y
rechaza tipos de orden inválidos antes del replay. La previsión tolera planes
antiguos sin `definition`. La incidencia modal de la Pokédex de la auditoría
RC2 sigue fuera de este cambio; no se declara resuelta.

## Comprobar

```sh
npm run godot:verify:relief
npm run godot:test:relief
npm run godot:simulate:relief
npm run godot:test:relief:replay
npm run godot:qa:relief
npm run godot:export
npm run godot:qa:relief:export
npm run godot:package
npm run godot:check:candidate
```

`verify:relief` elimina por turno cada casilla de paso para comprobar que ninguna
corta las dos aproximaciones al frente enemigo. `test:relief` comprueba 116
encuentros, consultas puras, órdenes de IA, accesos y guardados antiguos/nuevos.
La galería UI es un fixture explícito; la simulación de campaña usa exclusivamente
órdenes legales, compras, capturas y guardados, sin inyectar victorias.

Resultados:5.613 comprobaciones de reglas,15 de compatibilidad y1.809 de interfaz por build, con116 vistas por build. Validación:0 errores y65 avisos heredados, sin avisos nuevos.

Evidencia final en `docs/qa/sprint-40/`: geometría, reglas, campaña, fuente,
ejecutable, validación y paquete. Las métricas de campaña identifican su semilla;
no garantizan diversión ni éxito para cualquier equipo o jugador.

El recorrido natural final alcanza los58 lugares y las8 medallas en10.277 órdenes legales con la semilla `relief-40-kanto` y Bulbasaur. Las aves se resuelven antes que Mew/Mewtwo; la aventura termina tras reclamar la última captura. Guardados y recompensas se comprueban durante el recorrido.

La reproducción íntegra del diario en una ruta nueva, sin clave ni certificado, reconstruye las10.277 órdenes y el estado final idéntico; conserva el guardado original. Tardó73,344s en este PC. No es una medida de carga normal con certificado ni una segunda partida jugada.
