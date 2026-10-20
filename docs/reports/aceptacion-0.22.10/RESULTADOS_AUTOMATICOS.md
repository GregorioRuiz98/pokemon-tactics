# Resultados automatizados ·0.22.10

Fecha: 2026-10-20T20:23:24.092068+00:00. Campaña18 / combate17. QA aislada; ninguna partida personal utilizada. Cada fila es una batería distinta, con cobertura solapada: no se suman como observaciones humanas ni como partidas independientes.

| Batería | Fuente | Ejecutable | Fallos | Informes iguales |
|---|---:|---:|---:|---|
|Interfaz y continuidad|58|58|0|Sí|
|Teclado y foco|59|59|0|Sí|
|Turno y cámara|96|96|0|Sí|
|Lectura, gestión, práctica y clásicos|137|137|0|Sí|
|PC y equipo|540|540|0|Sí|
|Laboratorio|1026|1026|0|Sí|
|Aves / mapa16|901|901|0|Sí|
|Mew-Mewtwo / mapa24|513|513|0|Sí|
|Prototipo semántico / ventanas nativas|8|8|0|Sí|

Preferencias:2 escritura +20 lectura en procesos separados. Cantidades:44 comprobaciones puras de equivalencia manual, límites y Revivir. Lint0 incidencias; compilación0 errores/65 advertencias previas. El fixture interactivo del fuente permite preparar compra/uso5 e intercambio y no escribe archivo de campaña. Requiere Godot4.7.2 y proyecto fuente; las plantillas release bloquean --script. La campaña normal y las nueve baterías del ejecutable funcionan sin editor.

## Métodos y alcance

Teclado/ratón son eventos sintéticos del viewport; algunos recorridos antiguos usan señales de controles para preparar o aceptar menús. La prueba de gestión sí acepta operaciones por los controles nativos; el tutorial de ratón utiliza acceso programático al elemento Ficha del menú en un paso. No son sesiones humanas. Los recorridos legendarios parten de checkpoints QA naturales: origen continuado de campeón16 y campeón24; no se reatribuyen todos los encuentros anteriores como jugados de nuevo.

Las dos campañas finales coinciden íntegramente con0.22.3 en estado y diario:8924 órdenes para aves,7396 para origen. Fuente y ejecutable comparan además sus informes y guardados completos; el empaquetador impide reutilizar evidencia de un ejecutable anterior. src/,public/,core/,datos publicados y CREDITS raíz conservados.

Ventanas1024×720/1280×900/1920×1080 con texto100/125/150%, alto contraste, silencio y movimiento reducido; modo seguro y controles reasignados. Los clásicos se comprueban como vistas de cinco familias de reglas, con fase de tienda sintética explícita; sus diarios no se transforman. Se prueban Inicio/Oak/mapa/combate/resultado/captura/tienda/PC/derrota/final/guardado inválido con la cobertura de cada batería, sin afirmar todos los cruces de la matriz.

## Entorno y límites

Windows 10.0.26300, backend Windows, renderizador gl_compatibility, DPI informado 96, motor 4.7.2-stable (official) / ed1daf0bf001b61586d9930840f2f1394092c079. AccessKit forzado: soportado=True, activo=True. La existencia de propiedades/nombres/foco no acredita árbol UIA externo, voz ni comprensión. Lectura real con Narrador/NVDA y usuario habitual: pendiente. DPI físicos125/150/200% y otras máquinas: pendientes.

El ejecutable se prueba con GODOT_BIN apuntando a una ruta inexistente; carga su PCK incluido, sin editor ni servidor. No se midieron FPS ni se afirma mejora de diversión o reducción50% de operaciones. Kit humano listo, cero participantes. El balance anterior de29 simulaciones y la auditoría anterior de20 observaciones son antecedentes separados.

## Incidencias corregidas durante la revisión

Etiquetas auxiliares de Inicio recortadas; callback de presentación tras salir de escena; compatibilidad de límites/caramelos en ediciones clásicas. El harness recibió perfiles únicos por ejecución y espera a que los controles estén visibles/recolocados antes de clicar. La prueba inicial con accesibilidad forzada y subventanas incrustadas produjo un error interno de foco; el corte se validó con ventanas nativas, como la aplicación normal. Ver DEFECTOS.csv e informe del lector. El primer laboratorio exportado agotó300s; repetido con límite900s completó1026 comprobaciones iguales a fuente, sin errores. No se interpreta ese tiempo de QA como FPS. Los fallos preliminares no se presentan como aprobados.
