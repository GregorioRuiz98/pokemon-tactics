# 0.24.0 — Experiencia, evolución, capturas y gimnasios

Se sustituye la compra de niveles por Caramelos por entrenamiento de la EXP pendiente. La campaña nueva usa edición20 y conserva el combate espacial18. Los precios y los mínimos de evolución sin objetos son valores provisionales elegidos para esta prueba.

## Qué cambia al jugar

- Cada especie utiliza su grupo y curva de crecimiento de [PokéAPI](https://pokeapi.co/docs/v2#growth-rates). Las 151 especies y seis tablas están incluidas localmente, con fuentes y hashes; no hay consultas de red al jugar.
- Tienda → **Entrenar** permite elegir un miembro del equipo o PC y completar únicamente su siguiente nivel. Precio: **1 ₽ por EXP pendiente**. Ejemplo real: Bulbasaur al6 necesita57 EXP; con46 ya ganados solo paga11 ₽. La revisión muestra gasto y saldo antes de aceptar. No compra niveles de golpe, no revive y respeta el cap del próximo líder. Subir sigue recuperando solo el aumento de PS máximos.
- Desaparecen Caramelos, piedras y Cable Vínculo de las compras y acciones. Las evoluciones normales siguen automáticas. Las antiguas evoluciones por objeto/intercambio pasan a **Ficha → Evolucionar**, gratis y con nivel mínimo. Son voluntarias; Eevee conserva sus tres ramas para elegir. La evolución manual mantiene PS actuales, EXP y equipable; no cura.
- Antes de aceptar una captura local se puede pagar **60/120/180… ₽** por cambiar la oferta. Sale otra especie común de esa zona, conserva nivel e ID de oferta y se guarda inmediatamente. Consultar o cancelar no altera azar/dinero. El precio se reinicia en cada nueva recompensa; después de aceptar no se puede cambiar ese Pokémon. Los gimnasios mantienen su insignia fija; los legendarios siguen sin reclutarse. Los especiales del1 % conservan su sorteo inicial y no entran en el reroll común.

## Experiencia y encuentros

Las primeras recompensas pasan a90/160/240 EXP. Un inicial que sobreviva a los tres encuentros llega al10, frente al cap14 de Brock. Las pruebas verifican para los tres iniciales que, aun conservando todo el dinero y sin gastar en curación, no se puede comprar el cap en ninguna de esas tres primeras tiendas. Después la EXP aumenta con el tramo de campaña, evitando aplicar la vieja escala lineal a curvas cúbicas.

Se retocan niveles de encuentros/capturas según el tramo y se reducen Ruta3/Ruta4 a3 enemigos y Monte Moon a4 para dejar recuperación después del primer líder. El dinero contempla número de rivales, tramo y un extra por gimnasio, destinado también a curas, MT, equipo y rerolls. Se conservan precios de medicina, MT, mentas y equipables. No cambia la fórmula de daño, STAB, tipos, precisión ni las reglas espaciales.

Los líderes tienen más integrantes, conservan su insignia como nivel más alto y utilizan hasta cuatro movimientos que conocen a ese nivel. Los mapas16/24 admiten sus nuevas posiciones sin duplicarlas ni bloquear el despliegue. Referencia de especies: [revanchas de Let’s Go](https://www.serebii.net/letsgopikachueevee/gymrematch.shtml); formas tempranas, niveles y composición final son adaptaciones propias. Giovanni conserva su identidad de Tierra; no se sustituye por Azul.

| Gimnasio | Equipo nuevo | Cap / insignia |
|---|---|---|
| Ciudad Plateada · Brock | Geodude 9, Kabuto 9, Omanyte 10, Onix 14 | 14 / Onix |
| Ciudad Celeste · Misty | Psyduck 16, Seel 17, Staryu 18, Starmie 21 | 21 / Starmie |
| Ciudad Carmín · Lt. Surge | Voltorb 19, Electabuzz 20, Jolteon 20, Magnemite 21, Raichu 24 | 24 / Raichu |
| Ciudad Azulona · Erika | Tangela 25, Parasect 25, Victreebel 26, Exeggutor 27, Vileplume 29 | 29 / Vileplume |
| Ciudad Fucsia · Koga | Tentacruel 36, Golbat 37, Venomoth 37, Muk 38, Koffing 38, Weezing 43 | 43 / Weezing |
| Ciudad Azafrán · Sabrina | Mr. Mime 37, Jynx 37, Hypno 38, Slowbro 38, Kadabra 39, Alakazam 43 | 43 / Alakazam |
| Isla Canela · Blaine | Magmar 41, Rapidash 42, Ninetales 42, Flareon 43, Growlithe 43, Arcanine 47 | 47 / Arcanine |
| Ciudad Verde · Giovanni | Sandslash 44, Marowak 45, Dugtrio 45, Nidoqueen 46, Nidoking 47, Rhydon 50 | 50 / Rhydon |

## Mínimos de evolución gratuita

Estos umbrales son adaptaciones, no niveles originales de evolución por piedra/intercambio. Se pueden ajustar sin rehacer la interfaz.

| Origen | Evolución | Nivel mínimo |
|---|---|---|
| Pikachu | Raichu | 20 |
| Nidorina | Nidoqueen | 26 |
| Nidorino | Nidoking | 26 |
| Clefairy | Clefable | 20 |
| Vulpix | Ninetales | 30 |
| Jigglypuff | Wigglytuff | 20 |
| Gloom | Vileplume | 32 |
| Growlithe | Arcanine | 32 |
| Poliwhirl | Poliwrath | 36 |
| Kadabra | Alakazam | 36 |
| Machoke | Machamp | 36 |
| Weepinbell | Victreebel | 32 |
| Graveler | Golem | 36 |
| Shellder | Cloyster | 30 |
| Haunter | Gengar | 36 |
| Exeggcute | Exeggutor | 32 |
| Staryu | Starmie | 32 |
| Eevee | Vaporeon | 25 |
| Eevee | Jolteon | 25 |
| Eevee | Flareon | 25 |

## Guardados

Carga una campaña anterior y usa **Actualizar progresión y gimnasios** desde mapa/tienda/final. Se conserva copia y diario; un combate pendiente conserva sus reglas hasta terminar. Mantiene niveles, PS, movimientos, PC y rasgos. La EXP parcial conserva su proporción dentro de la barra nueva. Reembolsa25 ₽ por Caramelo y80 ₽ por piedra/cable que queden, retirándolos del uso. No rebaja niveles ya comprados: para evaluar el ritmo desde el inicio conviene una campaña nueva.

## Comprobaciones y balance pendiente

- Dominio nuevo: 964 comprobaciones, incluidas curvas de todas las especies, caps, precios manipulados/sin fondos, ranuras de evolución, elección de ramas, reroll determinista distinto, posiciones16/24 y replay frío de un diario natural que cruza19→20 con reembolso. Regresión espacial anterior:557 comprobaciones.
- QA nativa con teclado/ratón en desarrollo y ejecutable: entrenamiento/cancelación, reroll/cancelación, selección de evolución, guardado/replay natural y escalas100/125/150 a1024/1280. La fixture de Eevee se etiqueta sintética y está separada del guardado natural. Regresiones de movimiento espacial y ranuras equipadas se ejecutan aparte.
- Validador:0 errores;65 advertencias anteriores,0 nuevas. Recursos existentes verificados. No se modifican motores, datos ni tests publicados de ediciones anteriores.

### Simulaciones naturales de campaña

Son bots que usan la IA táctica del juego. Preparan movimientos, compran curación/Revivir, eligen evoluciones gratuitas y pagan entrenamiento hasta un nivel de referencia conservando120 ₽. No compran MT/equipables ni repiten capturas: **no representan todas las herramientas de un jugador humano**. Se conservan las derrotas y todos los guardados se reconstruyen desde semilla y diario.

| Muestra | Inicial | Semilla | Resultado | Última zona | Medallas |
|---|---|---|---|---|---|
| opening | Bulbasaur | economy-0 | defeat | forest | 0 |
| opening | Bulbasaur | economy-1 | capture | brock | 1 |
| opening | Charmander | economy-0 | defeat | forest | 0 |
| opening | Charmander | economy-1 | capture | brock | 1 |
| opening | Squirtle | economy-0 | defeat | forest | 0 |
| opening | Squirtle | economy-1 | capture | brock | 1 |
| full | Bulbasaur | economy-1 | defeat | route-6 | 2 |
| full | Charmander | economy-1 | defeat | route-10 | 3 |
| full | Squirtle | economy-1 | defeat | surge | 2 |

Los seis inicios se fijaron antes de ajustar. Hay3 victorias contra Brock y3 derrotas en Bosque Verde; ningún equipo ganador entra a Brock al cap. Los tres recorridos largos utilizan la semilla que había superado el inicio, y tampoco se presentan como una muestra aleatoria independiente: alcanzan2/3/2 medallas y terminan derrotados en Ruta6/Ruta10/Surge. No se ha acreditado una campaña20 completa ni sus finales con esta política. Se mantiene como límite real para una prueba humana de desgaste, composición y economía antes de afirmar balance cerrado.

### Pruebas aisladas de gimnasios

Equipo sintético sano de seis líneas (tres iniciales, Pidgey, Pikachu y Oddish), evolucionado solo cuando corresponde, dos niveles por debajo de la insignia, sin curas durante la batalla. No son victorias de campaña ni demuestran que esa composición sea obtenible en una partida.

| Gimnasio | Nivel del equipo | Rivales | Resultado | Rondas |
|---|---|---|---|---|
| brock | 12 | 4 | victory | 5 |
| misty | 19 | 4 | victory | 7 |
| surge | 22 | 5 | victory | 10 |
| erika | 27 | 5 | defeat | 19 |
| koga | 41 | 6 | victory | 20 |
| sabrina | 41 | 6 | victory | 17 |
| blaine | 45 | 6 | defeat | 23 |
| giovanni-gym | 48 | 6 | victory | 19 |

Resultado6/8 con ese equipo; pierde contra Erika y Blaine. Sirve para detectar combates que se atasquen o fallen técnicamente, no para declarar justo cada enfrentamiento. Recomendación de prueba humana: comparar gasto en curación/entrenamiento, usar el reroll para evitar duplicados o cubrir debilidades y comprobar qué Pokémon quedan rezagados tras caer. Posible siguiente ajuste: EXP de recuperación para los debilitados; no se ha añadido sin evaluarlo.

Fuentes/datos: `godot/data/economy.json`, `journey-24.json` y `tools/godot/reference/economy`. Scripts: `godot:test:economy`, `godot:simulate:economy`, `godot:qa:economy`, `godot:qa:economy:export`; `verify-economy.py` compara el importado con los dos CSV públicos fijados. Evidencia: `docs/qa/sprint-24`. Ejecutable y ZIP fuera de Git, en `outputs/releases/pokemon-tactics-0.24.0`. Sin despliegue público.
