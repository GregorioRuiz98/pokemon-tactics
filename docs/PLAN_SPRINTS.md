# Estado hacia 1.0

Actualizado el 29 de octubre de 2026. **1.0.0-rc.5**, candidata privada Windows offline. No hay descarga pública anunciada. Los planes acumulados son [historial](history/PLAN_SPRINTS_2026-10-27.md), no funciones pendientes por reintroducir.

## Cierre del desarrollo

| Sprint | Trabajo y evidencia | Alcance real |
| --- | --- | --- |
|36 — campaña y estabilidad|[Informe](SPRINT_36_CLOSURE.md), [motor](qa/sprint-36/summary.json), [interfaz](qa/sprint-36/native-source.json)|58 lugares,57 combates,8 medallas y 7.865 órdenes legales. Guardados, replay completo, recompensas, colección e inicial siguiente. Ofertas de Kecleon fijas por visita, edición 29.|
|37 — respuesta y controles|[Informe](SPRINT_37_USABILITY.md), [medición](qa/sprint-37/performance-after.json), [usabilidad](qa/sprint-37/usability-source.json)|Ficha 77,116 → 10,725 ms y Movimientos 78,291 → 45,253 ms de mediana local;95 casos de IA equivalentes. Teclado, ratón, rectificación, orientación, texto 150% y carga asíncrona.|
|38 — candidata y beta|[Verificación final](SPRINT_38_RC.md), [Cambios y límites](RELEASE_1_0_RC1.md), [protocolo](BETA_1_0.md), [plantilla](PLANTILLA_BETA.md)|EXE portátil, documentación, créditos/procedencia, contrato de empaquetado y comprobación del ZIP exacto. La evidencia final identifica fuente y EXE.|
|39 — perfil y texto|[Cambios RC2](RELEASE_1_0_RC2.md)|Identidad visible, personalización con vista previa y mensajes más breves. Sin cambios de reglas.|
|40 — relieve e identidad de Kanto|[Informe](SPRINT_40_RELIEF.md), [58 mapas](MAPAS_RELIEVE.md), [RC3](RELEASE_1_0_RC3.md)|Terrazas conectadas, dos aproximaciones por tierra, senderos, escaleras y obstáculos temáticos. Edición30, sin cambios numéricos del balance.|
|41 — correcciones y entrega|[Informe](SPRINT_41_STABILITY.md), [RC4](RELEASE_1_0_RC4.md)|Ficha de Pokédex anidada;72 comprobaciones de diálogo y20.574 de campaña por build, fuente/EXE.10.277 órdenes,58 lugares,8 medallas, replay completo y próximo inicial.|
|42 — informes de jugadores|[RC5](RELEASE_1_0_RC5.md), [uso](FEEDBACK.md)|Formulario integrado; vista previa, contexto opcional, copia/.txt y borrador de correo. Sin servidor ni envío automático.|


El cierre RC1 reutilizó una estrategia legal que funcionó en la edición previa; cada orden se ejecuta de nuevo. No importa el estado antiguo ni inyecta victorias, PS, dinero o Pokémon. El intento con una compra que agotó el presupuesto queda conservado. No se cambia el balance aceptado.

Validación:0 errores y 0 avisos nuevos;65 avisos heredados. Las suites históricas mantienen su edición. [Colección 0.35](SPRINT_35_COLLECTION.md) sigue documentando 151 especies,19 logros y 79 primeras formas; la candidata conserva sus reglas salvo las ofertas estables.

La [auditoría beta del 28 de octubre](BETA_RC2_2026-10-28.md) repite la campaña completa en fuente y EXE y añade casos límite. La auditoría reprodujo cuatro incidencias sin modificar RC2. RC3 corrige la disponibilidad de ediciones13–18; prueba lectura de las muestras13,16y18, previsión antigua, rechazo de tipos inválidos y actualización/replay mixto13/18→30. Incluye15 pruebas específicas de regresión. RC4 corrige la jerarquía modal de BETA-03 y verifica72 casos de ficha/foco por build. El recorrido completo por la interfaz se documenta en el [sprint41](SPRINT_41_STABILITY.md).

## Pendiente que requiere evidencia externa o decisión del creador

| Pendiente | Criterio de cierre |
| --- | --- |
|Otro ordenador físico|Arranque sin Godot/sin conexión, audio, guardado/recuperación, resoluciones y DPI reales. Fecha y especificaciones.|
|Jugadores externos|Comprender preparación y menús sin acompañamiento; registrar principio, mitad y final, bloqueos y ritmo. [Beta](BETA_1_0.md).|
|Procedencia/permisos|Resolver alcance de distribución de recursos Pokémon y terceros. [Inventario](LICENCIAS.md). Los hashes no acreditan autorización.|
|Canal de distribución|Elegir dónde ofrecer el ZIP. La recepción de incidencias está integrada mediante correo y exportación de informes; no se ha contactado automáticamente con nadie.|
|Autorización de publicación|El creador decide cuándo y dónde publicar. Repo privado, sin cambios de visibilidad ni release pública.|

La carpeta limpia se prueba en el mismo ordenador: no es otro PC. No hay evidencia de lector audible, duración universal, éxito de todos los iniciales, retención ni viralidad. La candidata no se declara 1.0 pública solo por superar scripts.

## Reglas que sustituyen diseños antiguos

|Antes|Ahora|
|---|---|
|Amenazas/T|Fichas de rivales y terreno.|
|Roles rígidos|Repertorios por especie y cuatro técnicas preparadas.|
|PT al atacar|PP al equipar y básico gratuito.|
|Caramelos/piedras/cables y Entrenar|EXP restante desde Equipo → Ficha; evolución por nivel o elección gratuita al umbral.|
|Tres iniciales aleatorios y finales excluyentes|Un inicial de Oak o primera forma obtenida Nv.5; Liga/rival → aves → Mew/Mewtwo.|
|Servidor obligatorio|Ejecutable offline y perfil local.|

[Reglas](REGLAS_ACTUALES.md) · [Arquitectura](ARCHITECTURE.md) · [Entrega](DEPLOY.md).
