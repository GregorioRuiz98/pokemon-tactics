# Pokémon Tactics

- Leer `docs/PLAN_SPRINTS.md` y el informe del último sprint antes de continuar.
- Sprints 0 y 1 completados; próximo sprint: 2, todavía pendiente. No incorporar combate, rondas, IA ni recorrido roguelike sin la petición del sprint correspondiente.
- Usar los scripts reales de `package.json`. Node 24 es la versión comprobada.
- Reglas independientes de Phaser en `src/rules`; catálogo validado en `src/data`; representación en `src/game`.
- Reutilizar recursos públicos y registrar fuente, commit, licencia, autores y cambios. No modificar las hojas originales de SpriteCollab.
- Los datos y sprites se sirven localmente. Las importaciones de red son tareas explícitas de desarrollo, nunca del arranque del juego.
- Mantener tres miembros iniciales y seis máximos como diseño futuro; el ensayo usa seis unidades fijas y no genera todavía un equipo de run.
- `src/rules/movement.ts` contiene navegación con EasyStar, terreno, ocupación y presupuesto; nunca duplicar esas reglas en Phaser. El desplazamiento se confirma y se revalida antes de cobrar puntos.
- El perfil terrestre para todas las unidades, presupuestos 3/4/5 y reinicio de ensayo son valores de prueba. No confundirlos con rondas, vuelo, equilibrio final ni regeneración de una partida.
- Ruta principal: tablero. `?view=camp` conserva la galería. `docs/DESIGN_SPRINT_1.md` define el tablero; `docs/DESIGN.md` conserva el contrato del campamento.
- Conservar pruebas de integridad de recursos y comprobar la UI en navegador cuando cambie.
- Un sprint activo; sin delegación automática ni despliegue implícito.

## Cierre y subida de cada sprint

- El usuario ha autorizado crear el repositorio y subir los cambios al terminar cada sprint. Esta instrucción persiste entre sesiones; no pedir de nuevo permiso para el commit y push de ese trabajo.
- Repositorio: `https://github.com/GregorioRuiz98/pokemon-tactics`, privado inicialmente. Última rama de entrega: `codex/sprint-1`; `codex/sprint-0` conserva la primera entrega.
- Revisar `git status`, conservar cambios ajenos y comprobar el remoto y la rama antes de actuar. No incluir cachés, dependencias instaladas, compilados ni credenciales.
- Ejecutar las comprobaciones pertinentes de `package.json`; actualizar `docs/PLAN_SPRINTS.md` y `docs/SPRINT_N.md` con resultados reales y pendientes. Revisar el diff, crear un commit descriptivo y hacer push a la rama de entrega acordada (o a una rama `codex/sprint-N` para una nueva entrega).
- Verificar que el SHA remoto coincide con el commit local e informar del enlace y las comprobaciones. No usar force push ni sobrescribir trabajo remoto. Si la subida falla, conservar el commit y explicar el bloqueo; no afirmar que está subido.
- Subir código no inicia automáticamente otro sprint, publica una web ni cambia la visibilidad del repositorio.
