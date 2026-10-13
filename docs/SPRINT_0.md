# Sprint 0 — Preparación y recursos mínimos

Estado: **completado técnicamente**, 13 de octubre de 2026. Pendiente de feedback visual del usuario. El sprint 1 no se ha iniciado.

## Entrega

- Proyecto local Phaser 4 + TypeScript + Vite adaptado de la plantilla oficial, con dependencias y fuentes fijadas.
- Campamento con Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude.
- Selección por canvas, botones o teclado; estadísticas base modernas, tipos y roles propuestos.
- Idle/Walk en las cuatro orientaciones cardinales, pausa y movimiento reducido.
- Catálogo y recursos locales; 12 hojas de animación, 6 miniaturas, fuente local, créditos y manifiesto con 33 hashes.
- Reutilización efectiva de tres funciones del importador de PokéSurvivor; atribución a JPTER78 y autores de los sprites.
- Carga con progreso, error recuperable de catálogo y aviso parcial si falta una hoja.

Arranque: `npm.cmd ci` y `npm.cmd run dev` en la carpeta del proyecto; abrir `http://127.0.0.1:5173`. Detener con Ctrl+C. Instrucciones completas en README.

## Verificación ejecutada

| Comprobación | Resultado |
| --- | --- |
| Instalación limpia `npm.cmd ci --ignore-scripts --no-fund` | Correcta, 17 paquetes; auditoría de npm: 0 vulnerabilidades en ese momento |
| `npm.cmd run build` | Correcta; incluye TypeScript sin errores |
| `npm.cmd test` | 6 pruebas aprobadas de contrato, geometría, tipos, exclusión de legendarios/míticos y rutas locales |
| `npm.cmd run verify:assets` | 6 especies, 12 hojas y 33 hashes verificados |
| Navegador Edge headless con Playwright | 12 comprobaciones aprobadas; informe en `qa/browser-results.json` |
| Red durante la visita correcta | Ninguna petición HTTP a servicios externos; imágenes blob generadas en memoria por Phaser |
| Consola durante la visita correcta | Sin errores JavaScript ni errores de consola |
| Escenarios de fallo | Catálogo vacío y hoja ausente simulados; reintentos recuperan la escena |
| Vista previa de producción | Seis especies renderizadas desde `http://127.0.0.1:4173` |
| Revisión visual | Capturas en 1440x1000 y 390x844, créditos y estados de fallo inspeccionados |

No hay linter ni cobertura configurados: no se presentan como ejecutados. Las pruebas de este sprint validan importación y presentación; todavía no existe lógica de combate que cubrir. El registro visual se valida con el checker de la skill frontend-design-direction; su resultado se conserva junto a la evidencia.

## Observaciones y límites

- La compilación avisa del tamaño del bloque de Phaser: aproximadamente 1,66 MB sin comprimir y 374 kB gzip. Es el motor separado; optimización de entrega pendiente para la publicación.
- Solo Edge/Chromium se ha probado. Firefox, Safari, dispositivos móviles reales y uso con lector de pantalla quedan pendientes.
- La comprobación visual estrecha valida presentación de la galería, no controles tácticos móviles futuros.
- La versión no contiene movimiento en tablero, combate, equipos aleatorios, progresión ni guardado.
- Entrega Git en `codex/sprint-0`, preparada para el repositorio privado `GregorioRuiz98/pokemon-tactics`. El plan canónico está incluido en `docs/PLAN_SPRINTS.md`; AGENTS.md registra la subida al terminar cada sprint. La subida del código es independiente de la publicación web del juego.
- Algunas operaciones de Node/Git necesitaron permisos normales fuera del sandbox por resolución de rutas. No es un requisito de permisos especiales del juego al ejecutarlo normalmente en el equipo.
- La primera prueba del detector de red confundió URL blob locales con solicitudes externas; se corrigió la prueba y la ejecución final completa pasó.

## Siguiente sprint

Sprint 1: tablero y desplazamiento. Antes de iniciarlo, recoger impresión sobre legibilidad, tamaño y presentación de especies. Mantener una sola entrega activa.
