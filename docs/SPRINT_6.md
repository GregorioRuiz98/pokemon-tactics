# Sprint 6 — Tienda, reclutamiento y objetos

14 de octubre de 2026. Versión **0.6.0**, rama `codex/sprint-6`.

## Entrega

- Recompensas por victoria y saldo de partida. Cada resultado se cierra una vez; recargar no repite el pago.
- Tienda y reclutamiento como salas separadas y excluyentes antes de cada combate. Ofertas limitadas por visita, precios visibles y compras bloqueadas por falta de saldo o stock.
- Bolsa accesible desde la ruta y durante las visitas. Selector de miembro y previsión de PS; Poción y Superpoción solo sobre vivos heridos fuera de combate. Consumo único y recuperación limitada al máximo.
- Tres equipables con POO: Restos, Chaleco Asalto y Botas Gruesas. Un hueco por miembro; cambios devuelven el objeto anterior. La previsión y resolución comparten sus efectos. El HUD muestra el objeto y bloquea apoyo/estado con Chaleco Asalto.
- Reclutamiento con tres candidatos no legendarios. Equipo de hasta seis, todos desplegados en posiciones legales; identidades independientes de especie. Sustituciones opcionales con espacio u obligatorias al estar completo, con confirmación, cancelación/Escape y foco al control que abrió la selección.
- Bajas y liberados archivados. Los muertos no reviven ni vuelven a desplegarse. **El usuario ha confirmado recuperar el objeto al caer**; también se recupera al sustituir.
- Guardado esquema 2 con reproducción de operaciones para reconstruir saldo, bolsa, ofertas y roster. Migración del esquema 1 conserva PS, semilla y pelea en curso, con copia anterior local. Conflictos de pestañas y fallos de almacenamiento siguen siendo explícitos.

## Recursos y estructura

Se reutilizan Phaser, EasyStar, SpriteCollab, Pixelify Sans, los mapas y los seis perfiles de Pokémon. Nombres/IDs de objetos importados de los CSV públicos de PokéAPI del commit ya fijado; `tools/import-items.mjs` genera `src/data/item-metadata.ts`. CSV originales y hashes conservados, licencia existente BSD-3-Clause. Precios y adaptación táctica son propios. Sin dependencias, sprites nuevos ni llamadas a PokéAPI al jugar.

`src/domain/items.ts` separa consumibles y equipables polimórficos. En estados solo se guardan IDs. `run.ts` centraliza operaciones y sus validaciones, con copia para el juego y reproducción para el guardado. `run-management.ts` presenta vistas/controles. Los módulos `legacy-*` permiten migrar el esquema 1 sin sustituir una pelea por otra nueva. `Battle` conserva RNG y recursos exactos.

## Comprobaciones

| Comprobación | Resultado |
| --- | --- |
| Dominio/reglas/datos | 72 pruebas aprobadas |
| Valores base | Instantánea del sprint 4 conservada; PS máximos, costes, precisiones, potencias y previsiones sin equipables coinciden |
| Recursos | 33 hashes originales y 4 CSV de PokéAPI verificados; sprites intactos |
| Tipos y build | Correctos; permanece el aviso conocido del tamaño de Phaser |
| Gestión en navegador | 18 comprobaciones aprobadas en desarrollo |
| Producción local | Las mismas 18 comprobaciones aprobadas contra la compilación final en 4173 |
| Regresión de combate | 19 comprobaciones aprobadas |
| Ciclo de vida | 3 comprobaciones: nombres escapados, salida durante carga y recarga durante animación |
| Presentación | Escritorio/móvil revisados; detector manual de Impeccable sin hallazgos |

La QA recorre compra, equipar/retirar, victoria con recompensa, curación real, reclutar, desplegar seis aliados y bajas reales. Valida cada estado contra las reglas, recarga visitas, cancela sustituciones y comprueba migración, corrupción de saldo y conflicto entre pestañas. También completa seis combates reales con `route-79`, sin gasto en servicios, conservando el comportamiento anterior. El caso de sustitución con seis miembros usa un checkpoint sintético validado, explicitado en la evidencia; no se presenta como una partida ganada por un jugador.

Se comprobaron objetos, restricciones, cuota de migración, baja/recuperación de objeto, sustitución antes de seis, recibos duplicados, stock, saldo y migración con bajas previas mediante pruebas de reglas. Las nuevas pantallas alternan lista y bolsa, tras detectar que mostrarlas juntas alargaba la visita. Evidencia en `docs/qa/sprint-6`. Solo Edge/Chromium probado; sin linter/cobertura configurados ni auditoría completa de accesibilidad. No se ha repetido la suite de navegador de movimiento; sus reglas siguen en la suite y la regresión de combate comprueba acceso al ensayo/campamento.

## Probar y continuar

Abrir `http://127.0.0.1:5173`, empezar, elegir tienda, comprar y equipar desde Bolsa. Superar una pelea, curar a un herido y elegir reclutamiento. Recargar una visita debe conservar saldo, PS, objetos y ofertas. Con seis miembros, previsualizar una sustitución y cancelarla antes de confirmarla. Los parámetros económicos están en `run.ts`/`items.ts`; son propuestas, pendientes de valoración manual.

Daño, PS, precisión, costes y movimientos base se mantienen por instrucción del usuario. Los efectos de equipables son mecánicas nuevas, no un ajuste general de equilibrio. Se han observado pérdidas rápidas y daño aliado por áreas en pruebas automatizadas; no se han corregido alterando valores. Equilibrio aplazado hasta completar las mecánicas.

Sprint 6 completado técnicamente. Siguiente: sprint 7, experiencia individual, niveles simplificados y evoluciones con objetos. Sin iniciar otra entrega ni publicar la web automáticamente.
