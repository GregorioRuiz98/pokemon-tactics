# Pokémon Tactics

Juego de rol táctico para Windows, gratuito y sin conexión, desarrollado para portfolio con asistencia de IA. Elige un inicial de Oak o una primera forma desbloqueada, forma un equipo de hasta seis Pokémon y recorre Kanto por combates en tableros isométricos con alturas.

**Versión Windows: 1.0.0-rc.4. Estado: candidata privada para beta.** No hay una descarga pública anunciada. El prototipo web 0.12.0 es una versión histórica independiente.

## Jugar

Extrae el paquete completo y abre `windows/PokemonTactics.exe`. No necesitas Godot, Node, servidor ni cuenta. La semilla se genera al empezar; partida, perfil y logros se guardan en el ordenador.

La campaña recorre 58 lugares, con ocho gimnasios, Liga y rival. Después se encadenan las tres aves y Mew/Mewtwo. Incluye PC, reclutamiento local, tienda Kecleon, evolución, naturalezas, habilidades y climas. Los PP limitan los movimientos equipados; no se gastan al atacar.

Antes de entrar puedes consultar contexto, objetivo y rivales reales. El menú de habilidades usa blanco con amarillo al pasar el ratón. Ratón y teclado disponibles; las amenazas se han retirado.

[Controles, guardados y recuperación](docs/PLAYTEST_WINDOWS.md) · [Reglas actuales](docs/REGLAS_ACTUALES.md)

## Desarrollo y comprobaciones

El juego actual está en `godot/`. Usa Git, Godot 4.7.2 estándar, Node 24 y Python 3; no requiere complementos. No hace falta instalar dependencias del prototipo web para ejecutar las herramientas nativas.

```sh
npm run check:repo
npm run test:repo-check
npm run godot:verify
```

Configura `GODOT_BIN` para abrir, probar o exportar desde otro ordenador. [Desarrollo nativo](godot/README.md) detalla los comandos y plantillas de exportación.

## Estado de la entrega

La RC4 corrige las fichas de la Pokédex y comprueba la campaña completa desde la interfaz del ejecutable. Conserva los 58 mapas y el balance de RC3. [Cambios de esta revisión](docs/RELEASE_1_0_RC4.md) · [Catálogo de mapas](docs/MAPAS_RELIEVE.md).

La candidata incluye Pokédex151,19 logros y primeras formas desbloqueables al nivel5. El cierre anterior verificó la edición29 con7.865 órdenes legales, recompensas y guardados; fija las ofertas de Kecleon durante cada visita y reduce el trabajo de los menús ocultos. [Entrega y comprobaciones](docs/SPRINT_38_RC.md) · [Cambios y límites](docs/RELEASE_1_0_RC4.md) · [Protocolo beta](docs/BETA_1_0.md).

Siguen pendientes jugadores externos y otro ordenador físico. El [estado de lanzamiento](docs/PLAN_SPRINTS.md) distingue lo comprobado de lo pendiente. La [guía de entrega](docs/DEPLOY.md) describe cómo preparar el ZIP sin publicar automáticamente.

## Documentación y recursos

[Índice](docs/README.md) · [Arquitectura](docs/ARCHITECTURE.md) · [Producto](PRODUCT.md) · [Portfolio](docs/PORTFOLIO.md) · [Historial](docs/history/README.md) · [Web histórica](docs/WEB_LEGACY.md)

Proyecto de fans independiente, sin afiliación ni aprobación oficial. Los personajes y recursos de terceros mantienen sus titulares y condiciones. [Procedencia y licencias](docs/LICENCIAS.md); los créditos no acreditan por sí solos autorización sobre la propiedad intelectual de Pokémon.
