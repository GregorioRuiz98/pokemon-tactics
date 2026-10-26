# Kanto reconocible y desafíos consecutivos — 0.30.0

Petición del 26 de octubre: implementar la dirección de mapas e identidad y jugar primero las aves, después Mew/Mewtwo. Esta autorización sustituye la limitación anterior de documentar propuestas. La publicación pública sigue aplazada.

## Cambios

- Liga y rival → Articuno/Zapdos/Moltres juntos → tienda → Mew/Mewtwo. No hay selección excluyente ni capturas legendarias. El perfil conserva ambos logros; la aventura solo aparece completada después de ambos desafíos.
- 58 localizaciones con 116 diseños de terreno/altura para 16×16 y24×24: caminos, claros, terrazas, agua, piscinas, pasarelas, galerías y mobiliario temático. Bosque Verde tiene árboles y troncos; Surge papeleras; Silph oficinas; la Torre lápidas; Blaine un laboratorio. La revancha de Ruta22 conserva exactamente su terreno. Safari sigue siendo narrativo; la galería de QA lo representa para comprobar su diseño, sin añadirle un combate a la campaña.
- Atlas nuevo de 16 objetos con transparencia real, sumado a los suelos, ilustraciones y sprites existentes. Árboles/rocas/muebles sólidos bloquean movimiento y visión; arbustos de maleza se atraviesan con el perfil vigente. Cada casilla sólida tiene huella visible. Orden de profundidad y atenuación de objetos ante unidades/cursor; fondo acorde al material, sin marco de cueva en exteriores.
- Alturas 0–2 con caras de talud y peldaños legibles. Se mantienen las reglas de movimiento y visión compartidas por jugador, previsión e IA. Pares de transportadores A/B y conexión visible al apuntar.
- Miniatura del lugar al viajar, sin otro menú ni paseo obligatorio. Oak, ciudades y servicios conservan sus escenas y funciones integradas: esta entrega no crea doce ciudades explorables.
- Se retiran las propuestas de roles y su mensaje de bonificaciones. Se conservan cuatro técnicas libres, básico neutro, potencia, diagramas, próximos aprendizajes, filtros por efecto, herramientas del equipo y aportación de MT.
- Anclajes de lanzamiento por familia inicial. Los chorros de Blastoise parten de dos posiciones en su sprite, con el mismo recibo de impacto y daño. Se conservan efectos espaciales y audio original, incluida Hiperrayo. No se importan movimientos competitivos nuevos ni las excepciones descartadas al adoptar LGPE.

## Compatibilidad y balance

Nueva campaña 22/capítulo 26; las fórmulas y reglas numéricas de combate 19 se conservan. Los 211 movimientos, repertorios LGPE, estadísticas, equipos rivales, niveles, EXP, precios y recompensas siguen iguales. Cambiar geometría puede cambiar la dificultad: conservar cifras no equivale a demostrar el mismo balance en todos los escenarios.

Motores/datos/tests publicados anteriores intactos. Nuevos módulos `kanto_journey`, `landscape_battle`, `kanto_landscape` y `kanto_campaign_store`, con datos aditivos. Una partida en combate mantiene su mapa; actualizar es voluntario entre encuentros con copia previa y diario mixto. Los finales históricos conservan sus victorias y pueden completar el desafío que les falte; no se inventa una victoria para imponer retroactivamente el orden nuevo. KT30 identifica22; KT25 sigue iniciando21.

## Comprobaciones

- 7.626 comprobaciones nuevas:116 diseños, accesos terrestres a despliegues/unidades/objetivos/portales, apariciones distintas, huellas, alturas, geometrías propias, comparación de cifras, finales sintéticos, logros, guardado22 y replay mixto12/19/20/21→22.
- Tres aperturas naturales con la misma semilla y cada inicial, sin alterar estadísticas ni enemigos: Bulbasaur10 órdenes/75PS, Charmander14/64PS y Squirtle14/68PS; las tres llegan a captura y se reconstruyen exactamente.
- Regresiones de motores/perfil anteriores:105 y120 comprobaciones. No se modifican sus fixtures para aceptar el contenido nuevo.
- QA actual en fuente y EXE: galería116, apertura natural Charmander/captura/tienda/carga, teclado, ranuras al 100/125/150%, lectura del equipo, origen doble sin daño duplicado y movimiento reducido. Regresión de presentación anterior separada con su edición21. Resultados y métricas reales en `docs/qa/sprint-30`; el paquete exige igualdad de estado natural entre fuente y ejecutable.
- Recursos: CRC/alpha/SHA256 del atlas y hashes de recursos anteriores. Lint y validación del proyecto; el empaquetador exige cero errores y ninguna advertencia nueva sobre las 65 históricas.
- EXE Windows offline y ZIP con integridad y SHA256. No se ha desplegado públicamente.

Los remates legendarios son fixtures explícitos, no dos victorias naturales. No se ha jugado toda la campaña nueva ni hecho una prueba humana; quedan para valorar la dificultad de los mapas y el acabado de los anclajes en todas las orientaciones. Las mediciones de dibujo son tiempos de CPU del tablero en este equipo, no FPS garantizados ni una prueba en ordenadores modestos.

## Recursos y revisión

Inventario revisable: [mapas.csv](reports/kanto-0.30/mapas.csv). El autor offline genera los datos con coordenadas explícitas; no crea mapas al azar durante la partida ni consume la semilla. Se mantiene el contacto inicial de las rutas; las aves ocupan sus sectores de hielo/tormenta/fuego.

Atlas original sin editar, prompt completo y hash en `godot/assets/kanto`. Renderizado por regiones UV y texturas cacheadas, sin nuevas dependencias, plugins ni red en ejecución. Se reutilizan los recursos acreditados de SpriteCollab/PMD y el arte local anterior.
