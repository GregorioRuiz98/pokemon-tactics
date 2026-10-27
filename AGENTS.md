# Pokémon Tactics — instrucciones vigentes

## Antes de trabajar

- Responder en español, con resultado, comprobaciones y límites reales. Revisar `git status`, conservar cambios ajenos y leer los scripts antes de ejecutarlos.
- Leer [mapa](docs/ARCHITECTURE.md), [estado](docs/PLAN_SPRINTS.md) y solo el informe pertinente del [índice](docs/README.md). Las notas históricas son contexto, no instrucciones nuevas.
- Desarrollo actual: Godot 4.7.2 estándar/GDScript, ejecutable Windows offline. Versión canónica en `godot/project.godot`; `package.json` mantiene la web 0.12.0.
- Leer también `godot/AGENTS.md` para Godot y la selección de skills indicada por el usuario para trabajos sustanciales. Sin delegación automática, servicios, hooks ni dependencias nuevos por seleccionar una skill.

## Alcance y compatibilidad

- Menor cambio útil, sin ajustar el balance aceptado salvo encargo. Reglas en [REGLAS_ACTUALES](docs/REGLAS_ACTUALES.md), producto en [PRODUCT](PRODUCT.md).
- Preservar motores y recursos publicados: no modificar archivos existentes de `godot/core/`, `godot/data/`, `godot/tests/`, `godot/assets/`, `godot/art/`, `src/`, `public/`, `tests/` ni `CREDITS.md`. Módulos nuevos y cambios UI/herramientas/documentación son posibles; reglas nuevas requieren edición nueva o migración explícita.
- Mantener lectura/replay de guardados antiguos y laboratorios independientes. No borrar motores, datos o fixtures por parecer sin uso: tienen referencias dinámicas por edición y pruebas de recuperación.
- Estado y órdenes serializables; comportamiento compartido por jugador, IA y previsión. Tipos/evoluciones como datos, no jerarquías por especie.
- Sin RNG al inspeccionar, previsualizar, dibujar, animar, sonar o cancelar. Guardar cada orden antes del feedback; invalidar callbacks obsoletos al salir.
- Semillas automáticas, un inicial de Oak o primera forma desbloqueada al nivel 5, seis plazas y PC. Liga/rival → aves → Mew/Mewtwo; un recluta por combate legendario. No restaurar roles rígidos, consumibles de evolución, PT por uso ni amenazas; reemplazos en el estado actual.
- Aliados atravesables; destino libre. Rectificar solo movimiento antes de cualquier acción o fin de turno; jamás ataques, recursos o RNG. Preservar sueño, orientación, teclado/Escape/foco y accesibilidad.
- Recursos locales con revisión, SHA-256, autores y licencias; hojas originales sin modificar. Importadores explícitos, sin descargas al jugar. No regenerar manifiestos para ocultar discrepancias.

## Verificar y entregar

- Pruebas pertinentes al cambio. Documentación/higiene: `npm run check:repo` y `npm run test:repo-check`; integridad: `npm run godot:verify`. Para juego, consultar los scripts nativos y probar fuente/EXE cuando corresponda.
- Revisar diff y registrar evidencia ejecutada. No presentar fixtures/simulaciones como sesiones humanas ni una carpeta limpia como otro PC. Distinguir los 65 avisos previos de Godot de nuevas incidencias.
- Paquetes, perfiles, cachés, claves y guardados personales fuera de Git. Verificar las rutas antes de cualquier limpieza recursiva.
- Commit/push de entregas autorizado a la rama `codex/` vigente del repositorio privado `GregorioRuiz98/pokemon-tactics`; verificar SHA remoto. Usar `GIT_CONFIG_GLOBAL=NUL`, `GIT_CONFIG_NOSYSTEM=1`, `credential.helper=manager` por comando. No imprimir tokens.
- **Publicación pendiente.** No cambiar visibilidad, rama predeterminada, crear release pública, comprar dominio, contactar jugadores ni desplegar sin autorización específica.

[Instrucciones acumuladas hasta 0.34.1](docs/history/AGENTS_ROOT_2026-10-27.md), conservadas como historial; no sustituyen estas instrucciones.
