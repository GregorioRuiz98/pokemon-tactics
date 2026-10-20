# Evidencia de la auditoría 0.22.1

Capturada el 20 de octubre de 2026 sobre el commit 9bbae5a653a189d5ce0c1b1565e62bdf0ddb7626, con Godot 4.7.2 estable oficial, hash ed1daf0bf001b61586d9930840f2f1394092c079.

- [observations.json](observations.json): 20 observaciones; estados y propietarios de foco después de eventos sintéticos de teclado.
- [probe.gd](probe.gd): sondeo reproducible, fuera del proyecto de juego. No es código cargado por la aplicación ni un test humano.
- [contrast.json](contrast.json): siete pares de colores opacos del tema y relación de contraste calculada.

## Método y límites

El sondeo instancia la escena de campaña y envía pulsaciones mediante el viewport del motor. Asigna foco explícitamente a determinados controles para aislar la activación y medir la pérdida posterior; no demuestra que el jugador pueda llegar a todos ellos sin ayuda. La repetición se ejercita con un evento marcado echo, no manteniendo una tecla física.

Para preparar la tienda se ejecutan 35 órdenes elegidas por la IA pura en el primer combate y se acepta una captura. No se presentan como partida humana ni como prueba de teclado de ese combate. La compra de Poción pasa de 2 a 3 mediante Enter. Las preferencias se cambian a través de los controles programáticamente y se comprueban después de crear una nueva escena; no se probó su reinicio de proceso con este sondeo.

Se utilizó modo headless: válido para observar foco, lógica de entrada y tamaños lógicos; no para certificar lectura visual, sonido, DPI real o accesibilidad de Windows. Las capturas revisadas pertenecen a la entrega anterior y están enlazadas como tales en el informe.

Los IDs de nodo automáticos pueden cambiar entre ejecuciones. El resultado esperado relevante es su función/texto y presencia de foco, no el nombre generado.

## Reproducir

Desde la raíz del repositorio, elegir un directorio nuevo fuera del repositorio y aislado de los datos personales. En el entorno local auditado:

~~~~powershell
$auditRoot = Join-Path (Resolve-Path ../../work).Path ("beta-replay-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $auditRoot | Out-Null
$env:APPDATA = $auditRoot
$env:LOCALAPPDATA = $auditRoot
$probePath = (Resolve-Path docs/reports/beta-accesibilidad-0.22.1/evidencia/probe.gd).Path
& ../../work/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path godot --script $probePath -- "--audit-dir=$auditRoot"
~~~~

El motor debe recibir una ruta absoluta al script externo. Genera observations.json y un guardado sintético de preparación dentro del directorio elegido. No ejecutar con APPDATA real ni usar el script para modificar una partida existente. Una versión futura puede cambiar los puntos de entrada; antes de reutilizar, comprobar la escena y sus funciones.

## Contraste

Cálculo sobre colores sRGB opacos declarados, usando luminancia relativa lineal y relación (Lmayor + 0,05) / (Lmenor + 0,05). Valores redondeados a dos decimales. No incluye mezclas alfa, antialiasing, sprites, todo el mapa ni todos los estados del tema.

Estos datos no son una certificación WCAG ni una evaluación de usuarios. Un contraste favorable no corrige una fuente demasiado pequeña.
