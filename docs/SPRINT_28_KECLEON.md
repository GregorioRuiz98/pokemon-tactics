# Sprint 28 — Tienda Kecleon, 0.28.0

El mostrador reúne tres ofertas, compra directa, ficha comparativa y renovación con precio creciente. Entrenar y Equipo son accesos principales; Medicina y Mentas y habilidades se abren desde el vendedor. Se conservan la bolsa, compras múltiples, cotizaciones de EXP, evolución gratuita y controles existentes.

Kecleon utiliza su animación original de SpriteCollab, fijada a un commit y acreditada en `godot/CREDITS.md`. Es exclusivamente el vendedor: no se añade a encuentros ni capturas de Kanto. Los recursos son locales; no hay consultas de red al jugar. El importador verifica procedencia, geometría y hashes sin modificar las imágenes originales.

Las ofertas entran con un fundido breve; el vendedor se anima y responde a compras, entrenamiento y renovación. Movimiento reducido mantiene su primer fotograma y elimina las transiciones. Las animaciones no consumen RNG ni modifican la campaña. Cada orden se guarda antes de presentar su respuesta.

## Comprobaciones

- QA del mostrador: 70 comprobaciones en fuente y ejecutable, recorrido natural Ruta 1 → captura → tienda; precios, dos renovaciones, bolsa, ficha, medicina, entrenamiento, teclado, escalas100/125/150, contraste y movimiento reducido.
- Regresiones en ambas compilaciones: perfil69 y presentación719. Núcleo: perfil120 y aventura105.
- Comparación de estado/diario entre fuente y EXE; importar/verificar recursos, análisis de scripts y ZIP con CRC.
- Validación: cero errores;65 advertencias históricas, ninguna nueva. Evidencia en `docs/qa/sprint-28/`.

## Límites

Mantiene campaña21/combate19, economía y repertorios. La prueba recorre la apertura y los menús; no equivale a una campaña completa ni cierra el balance humano. Se prepara un ejecutable Windows offline y se sube el código al repositorio privado; la publicación pública sigue aplazada.
