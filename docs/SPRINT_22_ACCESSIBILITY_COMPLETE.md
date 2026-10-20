# Entrega de controles y accesibilidad ·0.22.10

Solicitud «hazlo todo»: completados técnicamente los prompts03–09 sobre01–02 ya entregados. Campaña18 y combate17; sin cambios en fórmulas, economía, encuentros, IA, activos ni contratos publicados. Ejecutable Windows offline; repositorio privado, sin despliegue público.

## Cambios disponibles

- Ficha persistente I, lista de unidades, previsión compacta y detalle completo; resultados reales L. Estados y etapas con signo/duración, marcadores además del color.
- Texto100/125/150%, contraste, volumen/silencio, movimiento reducido, seguimiento de cámara y duración de resultados. Preferencias locales independientes del diario. F12 recupera lectura incluso en diálogos.
- Compra/uso por cantidad: revisión de coste, saldo, destino, límite y consecuencias; cada orden original se guarda antes del siguiente paso. Cancelación pura y parada ante fallo, sin repetir al recargar. Las ediciones clásicas con caramelo evolutivo conservan sus operaciones originales; las vistas no inventan un límite por gimnasio.
- PC con búsqueda/filtros/ordenación visual, identidad/origen de duplicados y comparación de intercambio. Biblioteca de cuatro ranuras con filtros y revisión de sustitución; básico fijo separado.
- Aprender a jugar/F7: práctica aislada en memoria, repetible, abandonable y sin escritura en la aventura; glosario F4 y ayudas desactivables. Continuar informa fase y próxima decisión. Confirmación de final legendario excluyente.
- Acceso textual experimental al tablero, semántica nativa y mensajes moderados. Se conserva el funcionamiento normal cuando el backend no está activo. No se añade voz remota ni una segunda narración.

## Comprobaciones

La tabla final de resultados, denominadores, entorno, fechas y evidencia se genera en [RESULTADOS_AUTOMATICOS](reports/aceptacion-0.22.10/RESULTADOS_AUTOMATICOS.md). Se comparan los informes y estados/diarios completos de fuente y ejecutable, con perfiles aislados. La matriz de ventanas no equivale a cambiar el DPI físico de Windows. Los recorridos históricos y simulaciones anteriores se citan como antecedentes, sin sumarlos como pruebas nuevas.

Lint estático sin incidencias; validación del motor sin errores y65 advertencias preexistentes. Se han corregido tres advertencias introducidas en los nuevos módulos. No se regeneran snapshots para obtener un aprobado. Se reutilizan recursos locales y manifiestos de repositorios públicos, sin dependencias o descargas durante el juego.

## Límites reales

[Prototipo de lector](SPRINT_22_SCREEN_READER.md): API y contratos de texto comprobados; árbol externo UIA, lectura audible y usuario habitual pendientes. No se declara accesibilidad completa ni porcentaje WCAG.

[Kit humano](reports/aceptacion-0.22.10/KIT_HUMANO.md), CSV de sesiones/defectos y [backlog](reports/aceptacion-0.22.10/BACKLOG.md) preparados. No se reclutó, contactó ni inventó ningún participante. Diversión, comprensión, reducción50% de interacciones, DPI125/150/200% reales y balance humano siguen pendientes.49/78 habilidades activas y terreno provisional conservan sus límites previos.

## Trazabilidad de bloques

| Prompt | Versión | Informe |
|---|---|---|
|01|0.22.2|[Controles](SPRINT_22_CONTROLS.md)|
|02|0.22.3|[Turno contextual](SPRINT_22_CONTEXT.md)|
|03|0.22.4|[Inspección](SPRINT_22_INSPECTION.md)|
|04|0.22.5|[Preferencias](SPRINT_22_PREFERENCES.md)|
|05|0.22.6|[Cantidades](SPRINT_22_QUANTITIES.md)|
|06|0.22.7|[PC y biblioteca](SPRINT_22_ROSTER_TOOLS.md)|
|07|0.22.8|[Aprendizaje](SPRINT_22_LEARNING.md)|
|08|0.22.9|[Lector: prototipo](SPRINT_22_SCREEN_READER.md)|
|09|0.22.10|Regresión automatizada y kit humano preparado; fase humana pendiente|

El primer ensayo del laboratorio exportado agotó el límite de300s sin errores del motor. Se repitió con límite900s y completó1026 comprobaciones y los cuatro resultados idénticos a fuente. Es un resultado de QA en segundo plano, no una medición de FPS ni una sesión de usuario.

El escenario artificial interactivo del kit se abre desde el proyecto fuente con Godot4.7.2. Las plantillas release oficiales bloquean `--script`; el lanzador lo indica y solicita las rutas del motor/fuente solo para ese fixture opcional. La campaña normal del ZIP y las nueve baterías del ejecutable funcionan sin editor. No se declara aprobado el arranque de un script externo en el release.
