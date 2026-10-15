# Ajuste inicial tras completar las mecánicas

Edición 14, sprint 11. Los guardados conservan su edición. El ensayo clásico y las partidas anteriores mantienen los valores protegidos por `tests/fixtures/combat-v0.4.json`; no se ha regenerado esa instantánea.

Cambios solo para nuevas partidas de campaña: PS efectivos ×2 para ambos bandos, curación de Poción/Superpoción de 40/100 PS, recompensa de 150 monedas. Charmander usa Pirotecnia (50 de potencia, 2 PT, área sin ascuas) en su segunda orden; las evoluciones conservan sus opciones avanzadas. Se obtiene Caramelo Raro tras las zonas 2/4/6/8 y Piedra Trueno tras la tercera. La tabla de tipos mantiene sus multiplicadores, incluidas debilidades dobles. Evolucionar y subir nivel conservan PS actuales.

En 16 simulaciones emparejadas, ocho semillas y dos destinos, se comparó la edición 13 con la candidata. Se registran golpes que derrotan a un objetivo que estaba a PS completos, no todos los KOs. Los JSON están en `qa/sprint-11/simulations-13.json` y `simulations-14.json`; este último amplía a 24 simulaciones. La política de gestión compra curación/reclutas y usa las evoluciones disponibles, y la política de combate es la misma que controla al enemigo.

Esta comparación observa el conjunto de cambios; no aísla causalmente cada parámetro. No mide diversión, tiempo humano, comprensión ni una tasa de victoria deseada. Persisten bajas definitivas y rutas difíciles. Antes de otro ajuste, recoger el feedback de `PLAYTEST.md` y comparar estrategias manuales, no únicamente la política de IA.

Resultado emparejado: edición 13, 137/787 golpes contra PS completos terminan en KO (17,4 %), 2/16 victorias; edición 14, 75/1994 (3,8 %), 7/16 victorias. El número de rondas acumuladas sube de 265 a 558: el combate dura más y necesita valoración humana. La muestra ampliada de edición 14 obtiene 8/24 victorias.
