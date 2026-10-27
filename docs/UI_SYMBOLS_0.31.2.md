# Interfaz y subida de nivel — 0.31.2

27 de octubre de 2026. Presentación para Windows offline; campaña24 y combate21
conservados. No hay nuevos precios, balance, reglas ni migración del guardado.

## Cambios

- Se retira la pestaña **Entrenar** de la tienda Kecleon. Sus accesos son Ofertas
  y Equipo; Medicina y Mentas y habilidades siguen junto al mostrador.
- **Equipo → Ficha** muestra la EXP y **Completar nivel** durante la visita a la
  tienda. Abre la misma confirmación, compra los mismos EXP pendientes y respeta
  dinero, descuento de recuperación, límite del gimnasio y aumento de PS actuales.
  Se elimina la compra duplicada en Objetos. Fuera de la tienda conserva las
  restricciones existentes. Las evoluciones gratuitas siguen en la ficha.
- Iconos originales de los **18 tipos** y las categorías **Físico, Especial y
  Estado** en las cuatro ranuras, biblioteca de movimientos, órdenes de combate
  y ofertas de MT. El básico neutro se representa sin icono de tipo Normal.
- Insignias con nombre y símbolo de los tipos del Pokémon en su ficha; filtros
  de tipos con iconos; cabecera visual de tipo/categoría en la ficha de un ataque.
- Se mantienen potencia, precisión, alcance, PP, áreas, efectos, descripciones y
  precios. Los iconos no reemplazan las etiquetas ni los detalles accesibles.
  El fondo claro de la categoría permite leer su silueta también en botones
  oscuros; los estilos decorados respetan el alto contraste.
- Texturas y estilos compartidos en caché, sin consultas a la red al jugar ni
  nuevas dependencias. Los símbolos no capturan clics ni foco.

## Procedencia

21 PNG sin modificar de [PokéSprite](https://github.com/msikma/pokesprite), commit
`c5aaa610ff2acdf7fd8e2dccd181bca8be9fcb3e`: `misc/types/gen8` y
`misc/seals/gen8/move-{physical,special,status}.png`.

La licencia MIT del código del repositorio no concede esa licencia a los sprites
de Pokémon. Se conserva el aviso de derechos de Nintendo / Creatures Inc. /
GAME FREAK inc., la licencia y la lista de colaboradores originales. Recursos en
`godot/assets/ui-symbols`; manifiesto con ruta, URL fijada, dimensiones y SHA256.
Créditos visibles en el juego y copiados al paquete. No se afirma autorización de
los titulares para publicar el juego.

Importación explícita: `python tools/godot/import-ui-symbols.py --download`.
Comprobación sin red: el mismo script sin argumentos. Preparar/exportar verifica
los bytes locales; nunca descarga de forma automática.

## Comprobaciones

- Interfaz nueva: 270 comprobaciones por versión; carga de los 21 iconos, mapeo
  de los 211 movimientos, ranuras por ratón/teclado, básico neutro, apertura natural
  hasta captura/tienda, ausencia de Entrenar, compra/cancelación de EXP y carga.
- Capturas de movimientos, combate, tienda, subida de nivel y ficha del ataque;
  texto al100/150 %, ventana1024×720, alto contraste y movimiento reducido.
- Regresiones: sueño15 y PP233 por versión; las pruebas históricas de PP usan
  explícitamente su edición23 y no se cambian sus resultados esperados.
- Lint sin incidencias. Validación: cero errores y65 advertencias históricas,
  sin advertencias nuevas. Motores, datos, pruebas y recursos anteriores intactos.
- La entrega incluye EXE offline, ZIP con CRC verificado y SHA256. Se cotejan los
  estados finales del proyecto y el EXE. Evidencia en `docs/qa/sprint-31-ui-2`.

No se ha realizado una campaña humana completa. No se publica en Internet.
