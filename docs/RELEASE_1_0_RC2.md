# Pokémon Tactics — 1.0.0-rc.2

Revisión del perfil de entrenador y del texto para jugadores, en el repositorio
original. La candidata independiente 1.0.0-rc.1 conserva su entrega anterior.

- Nombre, retrato y título visibles en todas las pestañas del perfil.
- Retratos cargados aunque ese Pokémon no esté en el equipo actual.
- Personalizar, Logros, Pokédex e Historial con selección visible y teclado.
- Vista previa de nombre, retrato y marco; guardar confirma los cambios.
  Un nombre inválido conserva el campo para corregirlo.
- Logros agrupados por estado e historial con tarjetas y fechas.
- Inicio, ayuda táctica y mensajes del viaje más breves.

Conserva las reglas y el balance de campaña 29/combate 24, el perfil local
existente y los guardados. No añade cuentas ni varios perfiles simultáneos.

## Comprobación

Pruebas nuevas de perfil y regresiones de colección, interacción y revisión,
tanto en fuente como en el EXE recompilado. El perfil se prueba con teclado y
ratón en 1024×720 y 1280×900, texto al 100/150% y ambos modos de contraste.
Las personalizaciones de prueba son fixtures aislados, sin victorias ficticias.
Inspeccionar y previsualizar no modifican el perfil guardado ni la campaña.

| Prueba | Fuente | EXE |
| --- | ---: | ---: |
| Perfil, personalización e historial | 158 | 158 |
| Pokédex, reclutamiento y guardados | 34 | 34 |
| Teclado, ratón y menús | 32 | 32 |
| Revisión de combate | 46 | 46 |

540 comprobaciones sin fallos. Lint y validación sin errores ni avisos nuevos;
se conservan los 65 avisos heredados de módulos publicados.

La campaña completa verificada en la [RC1](RELEASE_1_0_RC1.md) es evidencia previa;
esta revisión de presentación no repite todo el recorrido de Kanto.
Los resultados de esta revisión quedan en `docs/qa/sprint-39/`.

Continúan los [límites de la beta](BETA_1_0.md): prueba en otro ordenador,
sesiones humanas externas y decisiones de distribución pendientes. No se
publica ni se cambia la visibilidad de los repositorios.
