# Sprint 38 — candidata 1.0.0-rc.1

Entrega privada del 28 de octubre de 2026. Se conserva el balance aceptado y
se prepara el ejecutable portátil para una beta. No se ha publicado ni enviado
el juego a terceros.

## Comprobaciones ejecutadas

| Prueba | Resultado |
| --- | --- |
| Campaña actual, motor | 16.036 comprobaciones; 58 lugares, 57 combates, 8 medallas y 7.865 órdenes legales. |
| Reglas nuevas / regresión de colección | 36 / 4.196 comprobaciones, sin fallos. |
| Campaña completa, interfaz fuente y EXE | 15.750 comprobaciones por versión; mismo estado final y mismo inicial desbloqueado en la siguiente aventura. |
| Previa / colección / menús y recuperación | 1.958 / 34 / 46 comprobaciones por versión; estados equivalentes. |
| Controles / rendimiento | 32 / 231 comprobaciones por versión; teclado, ratón, texto ampliado y 95 casos de IA equivalentes. |
| Lint y validación | 0 errores, 0 avisos nuevos; los 65 avisos heredados coinciden por archivo y mensaje con 0.35.0. |
| Herramientas y documentación | 7 pruebas del verificador y 3 del contrato del empaquetador; enlaces locales del paquete válidos. |
| ZIP extraído | Arranque y diagnóstico con perfil aislado; mismo EXE y ZIP comprobados por SHA-256. |

Son 18.051 comprobaciones UI por versión, 36.102 entre fuente y EXE. La campaña
es un recorrido automático con una estrategia legal, guardado de cada orden y
reconstrucción completa del diario. No se importa el estado anterior ni se
inyectan victorias o recursos. No acredita todas las semillas o estilos de juego.

La prueba fuente comenzó durante el cierre 0.36, antes de cambiar los metadatos
de versión y retirar una línea vacía; el código jugable es el mismo. El EXE de
la candidata se reprodujo íntegramente después de exportarlo. El campo
`coldLoadMs` del informe es el tiempo de la última carga del nuevo inicial:
no se usa para afirmar la latencia de la reconstrucción larga.

## Paquete

`pokemon-tactics-1.0.0-rc.1-windows.zip`, 55.935.359 bytes. Incluye EXE con
recursos integrados, reglas actuales, recuperación, protocolo beta, plantilla,
licencias, créditos, manifiestos y sumas SHA-256. No incluye perfiles, claves,
guardados de QA, Node ni editor.

- EXE: `8ed40a83368a0ef5e3c3be6879c8a3c6378b6e0d54c617054b1e8e91ac7a0bac`
- ZIP: `f3f28dfb15c6673059c1c8566fa7b4e587a3b814db68ebaf8ef5c4c499025d41`

Se extrajo este ZIP exacto en otra carpeta del mismo ordenador, con APPDATA y
LOCALAPPDATA aislados y sin Godot en PATH. Abrió Inicio y pasó el diagnóstico.
La prueba de arranque usa audio Dummy; no acredita una sesión audible o hardware
distinto. El EXE no tiene firma de editor. No se alteró la seguridad de Windows.

## Evidencia

[Verificación](qa/sprint-38/verification.json) · [Paquete](qa/sprint-38/release.json) ·
[Arranque](qa/sprint-38/clean-startup.json) · [Avisos](qa/sprint-38/warning-parity.json) ·
[Entorno y límites de la medición](qa/sprint-38/test-environment.json).

Campaña [fuente](qa/sprint-38/closing-playthrough-source.json) y
[EXE](qa/sprint-38/closing-playthrough-release.json). Capturas del EXE:
[rival campeón](qa/sprint-38/release-champion.png),
[aves](qa/sprint-38/release-legendary-birds.png),
[Mew/Mewtwo](qa/sprint-38/release-legendary-origin.png) y
[aventura completada](qa/sprint-38/release-complete-current-kanto.png).

## Pendientes reales

Sesiones humanas externas, segundo PC físico, DPI y lector audible reales,
revisión del alcance de distribución y decisión de canal/contacto/publicación.
El [protocolo beta](BETA_1_0.md) y la [plantilla](PLANTILLA_BETA.md) están listos.
No se declara 1.0 pública ni se presenta una carpeta limpia como otro ordenador.
