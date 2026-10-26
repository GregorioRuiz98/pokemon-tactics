# Sprint 27 — perfil de entrenador, 0.27.0

26 de octubre de2026. Windows offline; campaña21/combate19 intactos. El usuario autoriza completar27–29 en entregas separadas, sin publicación pública ni delegación automática.

## Funciones

- Perfil local único con nombre opcional, retrato, Pokédex registrada, estadísticas acumuladas e historial de aventuras. Acceso desde Inicio y Menú → Perfil. Se puede jugar con el perfil predeterminado sin rellenar formularios.
- Diez logros: primera medalla; Brock con inicial Charmander; gimnasio sin bajas; empujar un rival sobre rocas que se activen; dispersar humo con el equipo; Fuji con sus4 puntos de protección; ambas terminales Rocket; Liga y rival; desafío de las aves; desafío psíquico. Los dos últimos requieren aventuras distintas por las rutas excluyentes del juego.
- Títulos Explorador/Campeón y marcos Hoja/Campeón desbloqueables por medallas/Liga. Retratos iniciales y especies obtenidas. Solo apariencia: no hay dinero ni ventajas estadísticas permanentes.
- Avisos opcionales, breves y no bloqueantes; no reproducen audio ni requieren animación. Se consultan todos los logros desde el perfil. Ratón y teclado, texto100/125/150 y ventanas1024×720/1280×900 comprobados.

## Persistencia y recuperación

`user://trainer-profile.json` es independiente de campaña y controles. Formato trainer/1, checksum, escritura temporal y copia `.bak`. Un perfil inválido no se sustituye al jugar: se avisa y se ofrece recuperación explícita, conservando el archivo dañado. Se detectan cambios concurrentes.

La campaña incorpora identificadores y una bandeja de eventos fuera del estado de dominio, dentro del mismo sobre con checksum que guarda cada orden. El perfil procesa los eventos después del guardado, mediante un cursor por aventura. Si el juego se cierra entre ambas escrituras, cargar permite reconciliar sin duplicar victorias/logros. El perfil no escribe dinero, PS, estadísticas, movimientos ni azar de la campaña.

Cerrar el juego, abrir Inicio o cancelar Oak no abandona una aventura. Confirmar otra aventura marca como abandonada la anterior en el historial; una derrota se distingue de una aventura completada. Dos aventuras con la misma semilla tienen identidades distintas.

Las campañas anteriores se vinculan sin reinicio ni cambio de órdenes. Retroactividad limitada a hechos demostrables: inicial, medallas, Liga/final completado y especies conservadas. No se inventan capturas descartadas, evoluciones históricas o victorias sin bajas que no quedaron registradas. Las métricas tácticas existentes se conservan; el historial parcial se indica en la ficha.

## Verificación y límites

Pruebas de dominio:120 comprobaciones, con Ruta1 natural, metadatos/replay, interrupción entre escrituras, idempotencia, identidad, legado, concurrencia y recuperación. Interacciones humo/rocas se resuelven mediante movimientos reales en escenarios preparados. Las condiciones de misiones/finales también tienen casos preparados; no representan una campaña natural completada.

QA de perfil:69 comprobaciones por destino. Regresión de inicio/textos:719 por destino. Dominio aventura anterior:105. Evidencia definitiva en [verificación](qa/sprint-27/verification.json) y [paquete](qa/sprint-27/release.json). Los perfiles, partidas y preferencias de QA están aislados.

No hay cuentas, red ni sincronización. El perfil es local y único en esta versión. La tienda Kecleon y los repertorios del sprint29 se entregan después. No se han tocado módulos publicados de reglas, datos, tests ni recursos anteriores.
