# Pokémon Tactics

- Leer `docs/PLAN_SPRINTS.md` y el informe del último sprint antes de continuar.
- Sprint 0 completado; próximo sprint: 1, todavía pendiente. No incorporar tablero, desplazamiento, combate ni rutas sin la petición del sprint correspondiente.
- Usar los scripts reales de `package.json`. Node 24 es la versión comprobada.
- Reglas independientes de Phaser en `src/rules`; catálogo validado en `src/data`; representación en `src/game`.
- Reutilizar recursos públicos y registrar fuente, commit, licencia, autores y cambios. No modificar las hojas originales de SpriteCollab.
- Los datos y sprites se sirven localmente. Las importaciones de red son tareas explícitas de desarrollo, nunca del arranque del juego.
- Mantener tres candidatos iniciales y seis miembros máximos como diseño futuro; esta pantalla presenta seis especies y no genera todavía un equipo.
- Conservar pruebas de integridad de recursos y comprobar la UI en navegador cuando cambie.
- Un sprint activo; sin delegación automática ni despliegue implícito.

## Cierre y subida de cada sprint

- El usuario ha autorizado crear el repositorio y subir los cambios al terminar cada sprint. Esta instrucción persiste entre sesiones; no pedir de nuevo permiso para el commit y push de ese trabajo.
- Repositorio: `https://github.com/GregorioRuiz98/pokemon-tactics`, privado inicialmente. Rama de entrega inicial: `codex/sprint-0`.
- Revisar `git status`, conservar cambios ajenos y comprobar el remoto y la rama antes de actuar. No incluir cachés, dependencias instaladas, compilados ni credenciales.
- Ejecutar las comprobaciones pertinentes de `package.json`; actualizar `docs/PLAN_SPRINTS.md` y `docs/SPRINT_N.md` con resultados reales y pendientes. Revisar el diff, crear un commit descriptivo y hacer push a la rama de entrega acordada (o a una rama `codex/sprint-N` para una nueva entrega).
- Verificar que el SHA remoto coincide con el commit local e informar del enlace y las comprobaciones. No usar force push ni sobrescribir trabajo remoto. Si la subida falla, conservar el commit y explicar el bloqueo; no afirmar que está subido.
- Subir código no inicia automáticamente otro sprint, publica una web ni cambia la visibilidad del repositorio.
