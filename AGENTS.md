# Pokémon Tactics

- Leer `docs/PLAN_SPRINTS.md` y el informe del último sprint antes de continuar.
- Sprints 0–2 completados; próximo sprint: 3, todavía pendiente. No incorporar efectividad de tipos, habilidades, estados, progresión ni recorrido roguelike sin la petición del sprint correspondiente.
- Usar los scripts reales de `package.json`. Node 24 es la versión comprobada.
- Reglas independientes de Phaser en `src/rules`; catálogo validado en `src/data`; representación en `src/game`.
- Reutilizar recursos públicos y registrar fuente, commit, licencia, autores y cambios. No modificar las hojas originales de SpriteCollab.
- Los datos y sprites se sirven localmente. Las importaciones de red son tareas explícitas de desarrollo, nunca del arranque del juego.
- Mantener tres miembros iniciales y seis máximos como diseño futuro; el combate usa tres aliados y tres enemigos fijos, y no genera todavía un equipo aleatorio de run.
- `src/rules/movement.ts` contiene navegación con EasyStar, terreno, ocupación y presupuesto; nunca duplicar esas reglas en Phaser. El desplazamiento se confirma y se revalida antes de cobrar puntos.
- `src/rules/battle.ts` contiene PRNG, cola, activaciones, ataques y política táctica. No consumir tiradas al inspeccionar, previsualizar o animar. Una cola estable por ronda; una acción y un desplazamiento continuo por activación, en cualquier orden.
- Las bajas se conservan con PS 0 para el registro, pero se excluyen de ocupación, representación y turnos futuros. Una baja final resuelve el resultado inmediatamente.
- Fórmulas de PS/daño, alcance 1/2 y perfiles terrestres son provisionales. Precisión 100 %, sin multiplicadores de tipos ni ataque especial todavía. Ver `docs/SPRINT_2.md`.
- Ruta principal: combate. `?view=training` conserva el ensayo; `?view=camp`, la galería. Contratos en `docs/DESIGN_SPRINT_2.md`, `docs/DESIGN_SPRINT_1.md` y `docs/DESIGN.md`.
- Preferencia visual confirmada el 14 de octubre: HUD de RPG táctico integrado en el gameplay, retratos/fichas en esquinas y órdenes/previsión en el centro. Mantener los controles dentro del marco del juego, reservar espacio para ellos y no tapar casillas. La vista sigue siendo superior.
- Semilla, reinicio, lista de unidades y prototipos secundarios se abren en Opciones. Conservar Escape, cierre al pulsar fuera y el foco del menú. Versión del ajuste: 0.2.1; informe en `docs/SPRINT_2_HUD.md`.
- El bucle de IA debe invalidar turnos programados al reiniciar; conservar el bloqueo de órdenes durante transiciones y el acceso a pausa/reanudación.
- Conservar pruebas de integridad de recursos y comprobar la UI en navegador cuando cambie.
- Un sprint activo; sin delegación automática ni despliegue implícito.

## Cierre y subida de cada sprint

- El usuario ha autorizado crear el repositorio y subir los cambios al terminar cada sprint. Esta instrucción persiste entre sesiones; no pedir de nuevo permiso para el commit y push de ese trabajo.
- Repositorio: `https://github.com/GregorioRuiz98/pokemon-tactics`, privado inicialmente. Última rama de entrega: `codex/sprint-2`; las ramas anteriores conservan sus entregas.
- La rama predeterminada de GitHub apunta a la última entrega comprobada. Actualizarla tras una subida verificada para que el repositorio abra esa versión; conservar las ramas anteriores.
- Revisar `git status`, conservar cambios ajenos y comprobar el remoto y la rama antes de actuar. No incluir cachés, dependencias instaladas, compilados ni credenciales.
- Ejecutar las comprobaciones pertinentes de `package.json`; actualizar `docs/PLAN_SPRINTS.md` y `docs/SPRINT_N.md` con resultados reales y pendientes. Revisar el diff, crear un commit descriptivo y hacer push a la rama de entrega acordada (o a una rama `codex/sprint-N` para una nueva entrega).
- Verificar que el SHA remoto coincide con el commit local e informar del enlace y las comprobaciones. No usar force push ni sobrescribir trabajo remoto. Si la subida falla, conservar el commit y explicar el bloqueo; no afirmar que está subido.
- Subir código no inicia automáticamente otro sprint, publica una web ni cambia la visibilidad del repositorio.
