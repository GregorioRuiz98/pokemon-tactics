# Sprint 3 — POO, identidades, tipos y habilidades

14 de octubre de 2026. Versión **0.3.0**, rama `codex/sprint-3`.

## Entrega

- Clase base `Pokemon`, seis especializaciones y registro central; contrato de acción con daño, absorción, estados y protección. La herencia comparte comportamiento y la composición permite reutilizar acciones. Arquitectura en [ARCHITECTURE.md](ARCHITECTURE.md).
- Tabla moderna de 18 tipos y 324 relaciones, tipos dobles, inmunidades y afinidad del mismo tipo (×1,5). Datos originales de PokéAPI, commit ya fijado, conservados como CSV locales y transformados mediante `tools/import-types.mjs`.
- Ataque básico gratuito y dos habilidades por especie. Daño físico/especial usa estadísticas reales importadas; precisión y efectos secundarios usan el PRNG del combate solo al confirmar.
- PT: 2 iniciales, +1 al comenzar cada activación, máximo 5. Una acción por activación; los fallos gastan acción y PT. La previsión y cancelación conservan recursos y aleatoriedad.
- Veneno, quemadura y parálisis; protección y absorción. Estado, duración y PT visibles en fichas. Habilidades y previsiones integradas en el HUD existente.
- Dos composiciones fijas comparables en Opciones: Iniciales (Bulbasaur/Charmander/Squirtle) y Control (Pikachu/Butterfree/Geodude); el otro trío ocupa el bando enemigo.
- Misma resolución de acciones para jugador e IA. Campamento, ensayo, reinicio, teclado, pausado y degradación a marcadores se conservan.

## Perfiles para probar

| Pokémon | Básico gratuito | Habilidad 1 | Habilidad 2 | Identidad |
| --- | --- | --- | --- | --- |
| Bulbasaur | Placaje, Normal físico, alcance 1 | Látigo Cepa, Planta físico, 1 PT, alcance 2 | Megaagotar, Planta especial, 2 PT, alcance 2; recupera mitad del daño | Desgaste y recuperación |
| Charmander | Ascuas, Fuego especial, alcance 2 | Lanzallamas, Fuego especial, 3 PT, alcance 2; 10 % quemadura | Fuego Fatuo, 2 PT, alcance 2, 85 % acierto | Ofensiva especial y quemadura |
| Squirtle | Pistola Agua, Agua especial, alcance 2 | Hidropulso, Agua especial, 2 PT, alcance 2 | Cobertura, 1 PT, alcance 1; aliado o propio | Defensa y apoyo |
| Pikachu | Ataque Rápido, Normal físico, alcance 1 | Impactrueno, Eléctrico especial, 1 PT, alcance 2; 10 % parálisis | Onda Trueno, 2 PT, alcance 2, 90 % acierto | Movilidad y control |
| Butterfree | Tornado, Volador especial, alcance 2 | Polvo Veneno, 1 PT, alcance 2, 75 % acierto | Confusión, Psíquico especial, 2 PT, alcance 2 | Control y cobertura de tipos |
| Geodude | Placaje, Normal físico, alcance 1 | Lanzarrocas, Roca físico, 1 PT, alcance 2, 90 % acierto | Fortaleza, 1 PT; propio | Resistencia y ataque físico |

Las habilidades son adaptaciones tácticas propias inspiradas en movimientos de Pokémon. Alcances, PT y duraciones no son los del juego original. Cobertura es una acción propia inspirada en el caparazón de Squirtle; Hidropulso/Confusión no aplican confusión en esta entrega y Ataque Rápido no cambia la cola.

## Reglas provisionales

- PS máximos conservados: `round(35 + PS_base / 3)`. Base de daño: `max(5, 12 + ataque × 0.18 − defensa × 0.10) × potencia / 40`, con estadísticas físicas o especiales según categoría. Después se aplican tipos, afinidad y protección; se redondea y se limita a los PS actuales. La inmunidad causa 0; otros daños tienen mínimo 1.
- Quemadura reduce a la mitad el ataque físico y resta `floor(PS máximos / 16)` al terminar la activación afectada. Veneno resta `floor(PS máximos / 8)`; ambos tienen mínimo 1. No se reduce el daño de estado mediante protección.
- Parálisis reduce a la mitad la velocidad al formar la siguiente cola, conservando la cola actual; reduce movimiento a `max(1, floor(presupuesto / 2))` al comenzar la activación. No introduce fallo aleatorio de acción en esta adaptación.
- Solo un estado principal a la vez. Dura tres activaciones del afectado, con pérdida de duración al terminar cada una. Veneno/Acero son inmunes al veneno, Fuego a quemadura, Eléctrico a parálisis; Tierra bloquea Onda Trueno y Planta bloquea Polvo Veneno. Las resistencias al daño no reducen la posibilidad del polvo.
- Cobertura/Fortaleza reducen a la mitad daño físico y especial hasta el comienzo de la siguiente activación del protegido. No se acumulan. Megaagotar cura `floor(daño real / 2)`, limitado por los PS faltantes; no cura a partir de exceso de daño.
- Los estados solo existen en este combate: reiniciar crea unidades nuevas. Persistencia entre encuentros, PP, evoluciones y equipamiento siguen pendientes.

## Comprobaciones ejecutadas

| Comprobación | Resultado |
| --- | --- |
| Pruebas de dominio/reglas/datos | 35 aprobadas; incluyen las 21 anteriores |
| Tabla de tipos | Las 324 relaciones coinciden con el CSV original; dos hashes de fuentes verificados |
| Recursos previos | 6 especies, 12 hojas y 33 hashes originales conservados |
| TypeScript y build | Correctos; aviso conocido del tamaño de Phaser |
| Navegador de desarrollo | 19 comprobaciones aprobadas; comparación del modelo con PS, posición, PT, estado, duración y protección tras cada orden |
| Producción local, puerto 4173 | Las mismas 19 comprobaciones aprobadas contra la compilación final |
| Geometría y capturas | Escritorio y móvil revisados; previsión activa sin tapar casillas en 1440×1000, 1280×768, 900×1000 y 390×844 |

Evidencia en [qa/sprint-3](qa/sprint-3). Playwright y escenarios de carga/fallo reutilizados de la prueba del sprint 2. No se añadieron dependencias, sprites ni servicios de ejecución externos. No hay linter ni cobertura configurados y no se ejecutó una auditoría WCAG completa. Navegador probado: Edge/Chromium; otros navegadores y dispositivos reales pendientes.

Con la política determinista de pruebas, Iniciales obtiene victoria en 3 rondas y Control en 2; esperar con Iniciales produce derrota en 2. Ambos recorridos completos se verifican en navegador. Esto demuestra que se pueden terminar y repetir; la diversión, la duración y el equilibrio requieren la prueba del jugador.

La primera compilación encontró un EPERM al resolver archivos bajo el sandbox; la compilación local autorizada completó correctamente. Un caso de prueba de recuperación de PT consultaba una cola ya vacía al cerrar ronda: se corrigió el caso para comparar el actor efectivo de la ronda siguiente y volvió a pasar la suite.

## Prueba del jugador y pendientes

En local, elegir Iniciales, probar los básicos y las habilidades, observar los costes y alternar Mover/Acciones. Después cambiar a Control en Opciones y reiniciar. Comparar qué decisiones permiten ambos equipos y si los costes justifican guardar PT.

Entrega completada técnicamente; comparación y feedback manual del usuario pendientes. Los valores de daño, PT, precisión y estados siguen abiertos a equilibrio. Sprint 4 aún no iniciado: flancos/espalda, orientación final manual, paso por aliados y terreno avanzado.
