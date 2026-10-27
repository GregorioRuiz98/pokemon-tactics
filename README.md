# Pokémon Tactics

Juego de rol táctico para Windows, gratuito y sin conexión, desarrollado para portfolio con asistencia de IA. Elige un inicial de Oak, forma un equipo de hasta seis Pokémon y recorre Kanto por combates en tableros isométricos con alturas.

**Versión Windows: 0.34.1. Estado: validación privada antes del lanzamiento.** No hay una descarga pública anunciada. El prototipo web 0.12.0 es una versión histórica independiente.

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

La 0.34.1 conserva las reglas y guardados de 0.34.0. Sus pruebas de interfaz suman 4.548 comprobaciones entre fuente y EXE, con previas de los 58 lugares. La campaña completa 0.34.0 se recorrió mediante órdenes legales automatizadas; esto no equivale a una sesión humana.

Siguen pendientes jugadores externos y otro ordenador físico. El [estado de lanzamiento](docs/PLAN_SPRINTS.md) distingue lo comprobado de lo pendiente. La [guía de entrega](docs/DEPLOY.md) describe cómo preparar el ZIP sin publicar automáticamente.

## Documentación y recursos

[Índice](docs/README.md) · [Arquitectura](docs/ARCHITECTURE.md) · [Producto](PRODUCT.md) · [Portfolio](docs/PORTFOLIO.md) · [Historial](docs/history/README.md) · [Web histórica](docs/WEB_LEGACY.md)

Proyecto de fans independiente, sin afiliación ni aprobación oficial. Los personajes y recursos de terceros mantienen sus titulares y condiciones. [Procedencia y licencias](docs/LICENCIAS.md); los créditos no acreditan por sí solos autorización sobre la propiedad intelectual de Pokémon.
