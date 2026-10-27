# Preparar y entregar Windows

La plataforma actual es un ejecutable offline, sin servidor web. Esta guía prepara una entrega; **no autoriza publicarla**, crear release pública ni cambiar visibilidad. Pendientes y evidencia en [Estado](PLAN_SPRINTS.md).

## Preparar el artefacto

1. Revisar cambios y versión de `godot/project.godot`. Conservar motores, guardados, recursos y avisos. Configurar Godot 4.7.2 y plantillas según [Desarrollo](../godot/README.md).
2. Ejecutar `npm run check:repo`, `npm run test:repo-check` y `npm run godot:verify`. Pruebas según lo cambiado; solo documentación no obliga a reconstruir el juego.
3. Para cambios jugables: `npm run godot:export` y pruebas sobre el EXE nuevo. Las de una compilación anterior no validan otra nueva.
4. Conservar lint/validación en el directorio QA de la entrega. El empaquetador comprueba errores, avisos de referencia, edición, evidencia fuente/EXE, coincidencia de estado y fecha posterior al EXE.
5. Ejecutar `npm run godot:package`: comprueba también los enlaces de la documentación distribuida y produce `windows/`, ZIP y `SHA256SUMS.txt` en `../releases/pokemon-tactics-VERSION/`, fuera de Git. Los contratos/mínimos están en `tools/godot/package-finishing.py`; una versión nueva debe definir el suyo.
6. Extraer en carpeta limpia y comprobar arranque, recursos, Créditos y guardado/recuperación. Probar también otro PC físico con el [protocolo](PLAYTEST_WINDOWS.md). La integridad del ZIP no acredita jugabilidad.

Para 0.34.1 se exigen briefing/review/symbols fuente/EXE, lint y validación. El SDK de la skill usado para estos informes no se incluye en el repositorio ni lo necesita el jugador. Para repetirlo se necesita ese SDK, o adaptar explícitamente el registro a una comprobación equivalente del motor; no presentar como reproducido lo que no se ha ejecutado.

## Qué compartir

El ZIP completo conserva EXE, documentación, créditos, licencias y procedencia. No eliminar avisos ni incluir `node_modules`, cachés, carpeta de trabajo, perfiles QA, certificados locales o guardados personales.

Conservar SHA-256 del EXE/ZIP, commit y cambios. Una revisión documental puede actualizar el ZIP y su checksum manteniendo el EXE idéntico; identificarla como tal, no como otra build jugable probada.

## Publicación y reversión

Resolver [Estado](PLAN_SPRINTS.md) y [Licencias](LICENCIAS.md), definir contacto/canal y recibir autorización del creador. No se ha anunciado URL de descarga.

Publicar el binario y abrir el código son decisiones distintas; el repo puede seguir privado. No aplicar automáticamente una licencia global al contenido Pokémon ni incorporar monetización, analítica o servicios.

Conservar el paquete anterior y copia de la carpeta de partidas. Actualización de reglas explícita y con copia. No sobrescribir un guardado reciente con un EXE antiguo; conservar original y usar versión compatible. [Recuperación](PLAYTEST_WINDOWS.md).

El [despliegue web 0.12.0](history/DEPLOY_WEB_2026-10-27.md) es histórico.
