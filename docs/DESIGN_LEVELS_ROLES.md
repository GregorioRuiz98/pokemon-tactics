# Niveles, roles y siguientes decisiones tácticas

Revisión nativa 0.14.1, 16 de octubre de 2026. Implementa el encargo de niveles/estadísticas, roles por movimientos y señales de fallo. Adelanta parte del sprint 16; no inicia automáticamente los mapas/isometría del 15 ni el resto de Kanto.

## Reglas confirmadas y aplicadas

El usuario confirma cuatro movimientos configurables más un básico obligatorio sin tipo ni STAB: cinco acciones en total. El Caramelo Raro hace evolucionar cuando se alcanza el nivel mínimo; no concede niveles. Se retira la compra directa de estadísticas en partidas nuevas. Los roles son orientaciones de repertorio, combinables sin pago ni clase fija.

- Inicial nivel5; capturas con el nivel del slot de hierba de Rojo ya sorteado, sin otra tirada. Hasta seis vivos; este tramo llega a cinco miembros.
- EXP individual a cada superviviente tras victoria: Ruta1 220, Ruta2 350, bosque500, Brock650. No se gana por esperar, fallar, defender repetidamente o dar el último golpe; no se concede a bajas. Son valores provisionales para esta muestra.
- Siguiente nivel cuesta 40 + 10 × nivel actual; EXP sobrante se conserva. Tope100. La fórmula simplificada permite recuperar distancia a los capturados de menor nivel. La recompensa y los niveles se guardan en la misma transacción de victoria.
- Estadísticas a partir de las bases reales: IV fijo15, EV0, naturaleza neutra; fórmula habitual de nivel, con PS multiplicados por4 como adaptación táctica. No se añaden naturalezas/IV aleatorios ni estadísticas pagadas. Subir de nivel o evolucionar conserva los PS actuales; nunca cura ni revive.
- Los movimientos aprendidos se conservan al evolucionar y pueden prepararse gratis fuera de combate. Se rellenan huecos libres al aprender; si ya hay cuatro, el nuevo queda en la biblioteca. Básico fijo de potencia25, físico, alcance1 y 0PT: ignora STAB, debilidades, resistencias e inmunidades de tipo. Sigue sujeto a precisión, defensa, terreno, quemadura y protección.
- El básico consume la acción. Los cuatro movimientos gastan PT, con el sistema táctico anterior. Atajos1–5, submenú integrado y selección directa. No se añaden PP en esta revisión.

Los nombres de roles no dan bonificaciones ocultas. Los contadores muestran cuántos movimientos preparados pertenecen a cada orientación. No es necesario escoger una especialización ni pagar por cambiarla.

## Diez líneas del catálogo, dos orientaciones por línea

| Línea disponible | Orientación 1 y repertorio | Orientación 2 y repertorio |
| --- | --- | --- |
| Bulbasaur → Ivysaur → Venusaur | Drenador: Látigo Cepa, Megaagotar, Hoja Afilada, Gigadrenado | Controlador: Gruñido, Polvo Veneno |
| Charmander → Charmeleon → Charizard | Artillero: Ascuas, Pirotecnia, Lanzallamas | Escaramuzador: Gruñido, Garra Metal, Cuchillada, Ataque Ala |
| Squirtle → Wartortle → Blastoise | Baluarte: Refugio, Mordisco, Protección | Tirador: Pistola Agua, Hidropulso, Surf |
| Caterpie → Metapod → Butterfree | Controlador: Disparo Demora, Fortaleza, Polvo Veneno, Paralizador | Artillero: Picadura, Confusión, Tornado, Psicorrayo |
| Weedle → Kakuna → Beedrill | Asaltante: Doble Ataque, Agilidad, Puya Nociva | Hostigador: Picotazo Veneno, Disparo Demora, Fortaleza, Pin Misil |
| Pidgey → Pidgeotto → Pidgeot | Escaramuzador: Tornado, Ataque Rápido, Ataque Ala | Apoyo: Respiro, Danza Pluma |
| Rattata → Raticate | Duelista: Mordisco, Ataque Rápido, Hipercolmillo, Triturar | Debilitador: Agitacola, Cara Susto |
| Pikachu → Raichu | Artillero: Impactrueno, Rayo | Paralizador: Gruñido, Onda Trueno, Chispa, Agilidad, Moflete Estático |
| Geodude → Graveler → Golem | Baluarte: Rizo Defensa, Protección | Rompelineas: Lanzarrocas, Tumba Rocas, Terratemblor, Terremoto |
| Onix | Muro: Fortaleza, Chirrido, Cola Férrea | Controlador: Atadura, Lanzarrocas, Tumba Rocas, Dragoaliento |

26 especies y 51 adaptaciones de movimientos reales. Incluye perfiles aliados y enemigos; las capturas siguen sus tablas locales, sin reclutar a los Pokémon de Brock. El catálogo añade Graveler/Golem con recursos que ya existían en la web, y sus retratos locales. Onix sigue sin Steelix porque el catálogo actual se limita a Kanto.

Los movimientos elegidos constan en las listas de compatibilidad de PokéAPI para esas especies; **los niveles de aprendizaje, alcance, PT y geometría están adaptados al juego** y no se presentan como una réplica de una edición concreta. Las formas pueden exigir evolución para aprender una técnica, y el menú lo indica. No todas las propiedades de cada movimiento están modeladas: Ataque Rápido no altera la cola fija, Pin Misil/Dobleataque agregan dos impactos en una tirada, Respiro recupera un cuarto y conserva los tipos. Confusión como estado, retroceso, atrapamiento y otras propiedades siguen pendientes. Datos y hashes de referencia en progression-provenance.json; [documentación PokéAPI](https://pokeapi.co/docs/v2).

## Evoluciones y dinero

| Línea | Nivel mínimo + un Caramelo por etapa |
| --- | --- |
| Bulbasaur | 16 → Ivysaur; 32 → Venusaur |
| Charmander | 16 → Charmeleon; 36 → Charizard |
| Squirtle | 16 → Wartortle; 36 → Blastoise |
| Caterpie / Weedle | 7 → capullo; 10 → forma final |
| Pidgey | 18 → Pidgeotto; 36 → Pidgeot |
| Rattata | 20 → Raticate |
| Pikachu | 20 → Raichu, umbral adaptado al uso de Caramelo |
| Geodude | 25 → Graveler; 36 → Golem, segundo umbral adaptado al intercambio |
| Onix | Sin otra evolución de Kanto |

Pikachu/Golem no usan sus métodos de piedra/intercambio originales: son excepciones explícitas para cumplir el Caramelo con restricción de nivel que pidió el usuario. Sus umbrales20/36 son provisionales. El Caramelo cuesta100; poción40/+40PS, superpoción90/+100PS y victoria150 continúan como valores provisionales. Comprar el caramelo antes del umbral no permite saltárselo. El dinero queda para consumibles/evolución y futuras MT/equipables, sin compras de estadísticas en edición2.

## Fidelidad ya presente y límites

STAB ×1,5 en movimientos con tipo coincidente, multiplicación de tipos dobles, resistencias/inmunidades, físico/especial, precisión por orientación, estados de quemadura/veneno/parálisis, inmunidades a esos estados y al polvo, áreas con riesgo aliado, empuje y terreno. La fórmula de daño es táctica, no la fórmula completa del cartucho. Se conservan cola fija por ronda, movimiento/acción y orientación final.

Esta revisión añade etapas de Ataque/Defensa/Velocidad con límite táctico -2…+2 y reinicio por combate, curación mediante Respiro y señales diferentes para fallo e inmunidad. No incorpora críticos, habilidades pasivas, clima, naturalezas, IV variables, EV ni todos los estados. Las partidas clásicas conservan el sistema anterior.

## Propuestas propias para siguientes entregas

Estas propuestas quedan documentadas; no se implementan como reglas nuevas sin una entrega correspondiente.

| Prioridad | Propuesta | Decisión que aporta y prueba necesaria |
| --- | --- | --- |
| 1, lectura del tablero | Alternar amenazas enemigas por casilla y previsión tras moverse | Poder valorar una exposición antes de arriesgar una baja definitiva. Calcular con las reglas reales de movilidad/alcance, obstáculos y movimientos preparados; sin estimaciones de Manhattan que ignoren el terreno. Encaja con el énfasis de [Fire Emblem en terreno, posición y talentos](https://www.nintendo.com/en-gb/Games/Nintendo-Switch-games/Fire-Emblem-Engage-2267157.html). |
| 2, identidad Pokémon | Una habilidad pasiva visible por especie, empezando por las familias de iniciales | Espesura/Mar Llamas/Torrente son candidatos; mostrar cuándo se activa y su efecto en la previsión. Medir su combinación con STAB/tipos antes de aumentar el daño. |
| 3, trabajo en equipo | Ataque de apoyo al flanquear con un aliado al otro lado | Limitarlo por activación y aplicarlo también a enemigos; comprobar que no borre unidades mediante cadenas gratuitas. Inspiración explícita: [flanqueo y ataques de seguimiento de Triangle Strategy](https://www.nintendo.com/us/whatsnew/tips-for-getting-started-with-triangle-strategy/). |
| 4, mapa vivo | Alturas, accesos y pequeñas interacciones elementales legibles | Dar utilidad a vuelo, empujes y control del espacio: agua, ascuas y zonas seguras. Se concreta en 15 junto a cámara/isometría. La misma [guía oficial de Triangle Strategy](https://www.nintendo.com/us/whatsnew/tips-for-getting-started-with-triangle-strategy/) describe altura e interacción entre elementos. |
| 5, economía de equipo | MT compatibles y un equipable por Pokémon, con previsualización del repertorio | Que el dinero amplíe opciones y especialice el equipo. Conservar técnicas aprendidas al evolucionar y limitar los cuatro huecos evita homogeneizar especies. La inspiración de [Final Fantasy Tactics](https://final-fantasy-tactics-the-ivalice-chronicles.square-enix-games.com/en-us) es combinar habilidades aprendidas; aquí la compatibilidad sigue dependiendo de Pokémon. |
| 6, ritmo de rutas | Objetivos de entrenador, defensa o salida en encuentros concretos | En mapas grandes, ofrecer decisiones antes que turnos vacíos para perseguir al último enemigo. Mantener eliminar enemigos como base mientras se evalúa la escala; premios y capturas explícitos por objetivo. |

Primero probaría amenazas y habilidades pasivas; después el apoyo por flanqueo y el terreno. El equipo de dos roles y cuatro movimientos proporciona la base para medir si estas ampliaciones añaden decisiones. La IA debe utilizar las mismas reglas y los efectos deben quedar claros antes de confirmar una orden.

## Guardados y continuidad

Las nuevas partidas usan edición2 del esquema kanto. Las partidas0.14.0 se reconstruyen y continúan con edición1, sin convertir una batalla ni inventar EXP retroactiva. Se identifican como Clásica0.14; para probar niveles hay que iniciar una nueva campaña, que conserva copia del archivo anterior. No se sobrescriben guardados web ni del laboratorio. Se conserva el alcance Paleta–Brock; no se amplía Kanto ni se aplica isometría en esta revisión.
