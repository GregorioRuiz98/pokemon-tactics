# Pokémon Tactics — Kanto y laboratorio nativo 0.17.0

Proyecto de fans para portfolio, sin afiliación ni aprobación oficial. Pokémon y sus personajes pertenecen a sus respectivos titulares.

El laboratorio original reutiliza las seis especies del ensayo: Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude. Hojas Idle/Walk originales y metadatos de SpriteCollab; miniaturas y datos locales del proyecto web. Autores registrados de estas seis especies: CHUNSOFT. Cada carpeta conserva credits.txt. El manifiesto data/provenance.json registra SHA-256 de cada archivo, su origen local y las fuentes de reglas usadas en las pruebas.

- SpriteCollab, PMDCollab: https://github.com/PMDCollab/SpriteCollab. Commit 6ad5f1c6229af6b055de2c64442e5e508664290c; condiciones publicadas CC BY-NC 4.0 y atribución individual, sin convertirlas en autorización sobre derechos subyacentes. Aviso en licenses/SpriteCollab-CC-BY-NC-4.0.md.
- Datos de PokéAPI y tabla moderna de tipos: instantáneas locales existentes. Licencia del código BSD-3-Clause en licenses/PokeAPI-BSD-3-Clause.txt. No hay consultas a la API al jugar.
- Pixelify Sans: fuente original, licencia SIL OFL en licenses/PixelifySans-OFL.txt.
- Sonidos select/hit/victory: WAV locales del proyecto generados con jsfxr; aviso en licenses/jsfxr-UNLICENSE.txt. La copia nativa de victory.wav añade el byte de relleno RIFF que faltaba y ajusta la longitud del contenedor para Godot; las muestras PCM y su longitud permanecen idénticas. Fuente original sin modificar, ambos hashes y adaptación registrados en provenance.json.
- La navegación GDScript adapta el orden A* de EasyStar.js 0.4.4 y las operaciones de heap.js 0.2.6 para conservar recorridos equivalentes. EasyStar: Bryce Neal, MIT; heap.js: Xueqiao Xu, licencia PSF y avisos de Python Software Foundation. Textos en licenses/EasyStar-MIT.txt y licenses/heap-PSF.md.
- Godot 4.7.2 estándar: motor de código abierto, licencia MIT. Su texto de licencia y los avisos de bibliotecas de terceros se muestran desde el menú Créditos mediante los datos incluidos en el propio motor.

El registro completo de las fuentes del proyecto web se conserva, sin modificar, en licenses/web-CREDITS.md; incluye especies y dependencias que no se distribuyen en este laboratorio nativo. No se incorpora música nueva; el catálogo completo de Kanto se añade en la expansión0.17.0. La ampliación de campaña se detalla a continuación.


## Retratos de diálogo — revisión 0.13.2

Retratos Normal de Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude, estilo Pokémon Mundo Misterioso / Exploradores. Autor registrado: CHUNSOFT. Proceden de portrait/NNNN/Normal.png de SpriteCollab, commit 6ad5f1c6229af6b055de2c64442e5e508664290c, el mismo origen fijado para los sprites. Se conservan los PNG originales de 40×40 y sus créditos individuales en assets/portraits/ID; solo se escalan con nearest al mostrar. data/portraits.json registra URLs, hashes y créditos. No se atribuyen al autor del juego ni se consulta el repositorio al jugar.

Herramienta explícita: npm run godot:import:portraits. Aviso de SpriteCollab ya incluido en licenses/SpriteCollab-CC-BY-NC-4.0.md. La atribución y condiciones de recursos comunitarios no sustituyen los derechos subyacentes de Pokémon.

## Campaña hasta Brock — 0.14.0

24 especies: números 1–20, 25, 26, 74 y 95. Se reutilizan las seis anteriores y siete ampliaciones de la web; once especies adicionales usan datos locales de PokéAPI y sprites de SpriteCollab del mismo commit fijado. Hojas Idle/Walk, AnimData y retratos Normal originales sin editar; miniaturas nuevas recortadas del primer fotograma. Los retratos conservan sus créditos propios, incluidos colaboradores comunitarios además de CHUNSOFT. La tabla enumera autores presentes en los historiales distribuidos; el detalle de contribuciones está junto a cada recurso.

| Especie | Autores registrados de sprites y retratos |
| --- | --- |
| 1 · Bulbasaur | CHUNSOFT |
| 2 · Ivysaur | CHUNSOFT, Emmuffin |
| 3 · Venusaur | <@!276175146304405514>, CHUNSOFT, G〜 |
| 4 · Charmander | CHUNSOFT, Emboarger, baronessfaron |
| 5 · Charmeleon | 0palite, <@!199989579682414592>, CHUNSOFT, Grimlin, bwappi |
| 6 · Charizard | 0palite, CHUNSOFT, Emboarger |
| 7 · Squirtle | CHUNSOFT |
| 8 · Wartortle | CHUNSOFT, Emmuffin |
| 9 · Blastoise | CHUNSOFT, Emmuffin, Top_Kec |
| 10 · Caterpie | CHUNSOFT, Frostdrop1, baronessfaron |
| 11 · Metapod | Blanky, CHUNSOFT, Emboarger, baronessfaron |
| 12 · Butterfree | CHUNSOFT, Emmuffin |
| 13 · Weedle | CHUNSOFT, Novie |
| 14 · Kakuna | CHUNSOFT, Caitemis |
| 15 · Beedrill | CHUNSOFT, Fable |
| 16 · Pidgey | CHUNSOFT, JFain |
| 17 · Pidgeotto | CHUNSOFT, Tainted#3886 |
| 18 · Pidgeot | CHUNSOFT, FalafelPorpoise |
| 19 · Rattata | CHUNSOFT, Frostdrop1 |
| 20 · Raticate | CHUNSOFT, G〜, baronessfaron |
| 25 · Pikachu | CHUNSOFT |
| 26 · Raichu | 3Monika4, CHUNSOFT, C_Pariah, Grimlin, G〜, Top_Kec |
| 74 · Geodude | CHUNSOFT, JustAGunk |
| 95 · Onix | CHUNSOFT, baronessfaron |

Archivos individuales en assets/kanto/ID/credits.txt y portrait-credits.txt para las ampliaciones; las seis originales conservan assets/pokemon y assets/portraits. data/kanto-provenance.json registra 148 archivos con SHA-256, procedencia y modificaciones. Las instantáneas PokéAPI en data/kanto-sources se conservan en el repositorio para desarrollo; el ejecutable usa el catálogo procesado.

Tablas locales de encuentros de Rojo: [pret/pokered](https://github.com/pret/pokered/tree/af519899719f0754965776faac0e836a3b906e6d/data/wild/maps), commit af519899719f0754965776faac0e836a3b906e6d. Se han transcrito datos factuales de Ruta 1, Ruta 2 y Bosque Verde, con pesos de aparición originales sobre 256; no se distribuyen su código ensamblador ni ROMs. El catálogo conserva URL y hash de las tablas consultadas. Equipos enemigos, mapas tácticos, precios y repertorios son adaptaciones de este proyecto.

El importador explícito tools/godot/import-kanto.py reutiliza el ayudante MIT procedente de PokéSurvivor ya registrado en licenses/web-CREDITS.md y tools/vendor. Requiere Python/Pillow y Node durante la importación, sin añadir dependencias al juego. No hay consultas de red durante las partidas.


## Progresión y efectos — 0.14.1

26 especies: se añaden Graveler75 y Golem76 a las 24 anteriores, reutilizando sus hojas originales y metadatos de la web. Retratos Normal del mismo commit SpriteCollab fijado. Atribución original en assets/progression/pokemon/75 y 76, archivos credits.txt y portrait-credits.txt, sin editar. Los datos de 51 movimientos y sus listas de compatibilidad proceden de PokéAPI: nombres, tipos, categoría y potencia, con adaptación explícita de aprendizaje/alcance/PT/efectos. progression-provenance.json registra 18 archivos y 77 respuestas de referencia con SHA-256; no hay llamadas al jugar.

Imágenes de fallo e inmunidad: star_01.png y circle_01.png originales del Particle Pack1.1 de Kenney Vleugels, CC0, mostrados con tamaño/color del juego sin editar los archivos. Fuente: https://kenney.nl/assets/particle-pack. Archivo descargado y SHA-256 en progression-provenance.json; aviso original en licenses/Kenney-Particle-Pack-CC0.txt, que también conserva los créditos adicionales de plantillas de filtro. Se distribuyen solo dos PNG, no todo el paquete.

Sonidos miss/immune/level-up: generados de forma determinista con la copia jsfxr ya incluida, commit b7b6aa27d62f8f356db267276bf54b451555c49d; autores/Unlicense indicados arriba. Herramienta tools/godot/import-feedback.mjs; presets, semilla y hashes en data/feedback-provenance.json. No son grabaciones ni sonidos extraídos de Pokémon. WAV select/hit/victory anteriores sin modificar.


## Tienda y cobertura — 0.14.2

shop.json añade Demolición y compatibilidad de seis MT por entradas de aprendizaje mediante máquina de las26 especies en PokéAPI, unión de versiones; no es una lista exclusiva de Rojo ni de una generación. Potencia75, Lucha/físico/precisión100 de Demolición son datos factuales; 2PT/alcance1 y precios son adaptaciones. Numeración de MT combina generaciones. shop-provenance.json registra28 respuestas con URL/SHA-256 y el catálogo derivado. Fuente: https://pokeapi.co/api/v2/move/brick-break y https://pokeapi.co/api/v2/pokemon/4, entre las demás entradas enumeradas. Metadatos de Vidaesfera contrastados en https://pokeapi.co/api/v2/item/life-orb. Importador explícito tools/godot/import-shop.py; ninguna llamada durante el juego. Se reutilizan catálogos, traducciones de objetos, retratos, sprites, fuente, tema y sonidos existentes; no se incorporan imágenes/audio externos nuevos.


## Crecimiento — 0.14.3

No se importan activos ni datos externos nuevos. growth.json y growth.gd son configuración/lógica de este proyecto: Caramelo25, evolución automática, Pikachu Cola Férrea7 y aprendizajes de Beedrill/Butterfree. Se reutilizan los52 movimientos y26 especies con su procedencia ya registrada, los retratos/sprites y el jingle de nivel existentes. Pikachu20/Graveler36 son adaptaciones expresamente confirmadas; los aprendizajes nuevos no se presentan como una copia del cartucho.


## Legibilidad y Let’s Go — 0.14.4

Atkinson Hyperlegible Regular, Braille Institute of America, SIL Open Font License1.1. Archivo original sin modificar del repositorio google/fonts, commit66928797f271fed5ee428544e7229685e2d90127; licencia completa en licenses/Atkinson-Hyperlegible-OFL.txt. Fuente/hash en letsgo-provenance.json. Pixelify se conserva con sus créditos para procedencia anterior.

Seis especies adicionales con Idle/Walk y retrato Normal de SpriteCollab, commit6ad5f1c6229af6b055de2c64442e5e508664290c. Hojas/retratos originales intactos; miniaturas recortadas declaradas. Créditos completos sin modificar junto a cada recurso en assets/letsgo/ID. Autores de sprites/retratos combinados:

| Especie | Autores registrados |
| --- | --- |
|43|CHUNSOFT, Felis-Licht, ShyStarryRain|
|44|CHUNSOFT, chikorene|
|45|CHUNSOFT|
|69|<@!436940337865293834>, CHUNSOFT, baronessfaron|
|70|CHUNSOFT, G〜|
|71|CHUNSOFT|

Aprendizajes/compatibilidad por grupo Let’s Go en PokéAPI y encuentros/máquinas del CSV fijado81d20919845b6a445969b9265aab5cec6b04cece. Nombres, tipos, potencia y categorías factuales; alcance/PT/efectos tácticos y pesos de aparición propios explicados en docs/SPRINT_14_LETSGO.md. letsgo-provenance.json registra46 archivos derivados/originales con hashes y respuestas de origen. Importador explícito import-letsgo.py, sin consultas al jugar. Indicadores vectoriales dibujados por este proyecto; no se importan packs adicionales ni se alteran sonidos existentes.


## Reglas tácticas — 0.14.5

Sin nuevos activos externos. Se reutilizan tipografía, sprites/retratos, sonidos y datos LGPE ya atribuidos. Tablas factuales de probabilidad/daño crítico moderno contrastadas en https://github.com/smogon/pokemon-showdown/blob/master/sim/battle-actions.ts; no se incorpora código de ese proyecto. Reglas de orientación, temporalidad, costes y prototipos de movilidad son implementación de este proyecto en tactics_*.gd/data/tactics.json.

## Naturalezas y habilidades0.14.9

Metadatos factuales y nombres españoles de25 naturalezas y15 habilidades normales, slots de32 especies y contacto de39 acciones (incluido básico propio), reutilizados desde7 CSV de PokéAPI, commit81d20919845b6a445969b9265aab5cec6b04cece. URL/SHA256 de fuentes y catálogo derivado en data/traits-provenance.json; importador tools/godot/import-traits.py. Se mantiene el aviso BSD-3-Clause de PokéAPI ya incluido. Descripciones españolas de efectos/adaptaciones, precios, cálculo y representación propios. Clorofila/Fuga no activas hasta añadir clima/huida; multiimpactos conservan agregación táctica. Sin imágenes, sonidos ni fuentes nuevos; ninguna consulta al jugar.


## Kanto completo — recursos0.17.0

Se reutilizan los32 registros nativos anteriores y se incorporan119 especies para completar151. Hojas Idle/Walk, AnimData, retratos Normal y créditos son originales de SpriteCollab, commit6ad5f1c6229af6b055de2c64442e5e508664290c. Sin recolorear ni redibujar. Autores individuales completos en data/expedition-provenance.json y credits.txt/portrait-credits.txt de cada carpeta assets/expedition/ID; no se atribuyen al autor de este juego.

Repertorios y compatibilidad de MT de Let’s Go, encuentros combinados, especies, tipos, estadísticas y habilidades normales desde PokéAPI, CSV fijados al commit81d20919845b6a445969b9265aab5cec6b04cece y respuestas API identificadas por URL/SHA256. Se conserva su aviso BSD-3-Clause. Datos compilados nuevos en expedition.json, expedition-shop.json y expedition-traits.json; manifiesto de717 archivos con fuentes/hashes. No se consulta ninguna API al jugar.

Equipos/niveles de entrenadores de Rojo desde los datos factuales de pret/pokered, commitaf519899719f0754965776faac0e836a3b906e6d, data/trainers/parties.asm. No se incorpora código del juego original. Grafo, textos españoles, mapas, reglas de PT/alcance/roles, adaptaciones de efectos complejos y habilidades, economía y guardado son implementación de este proyecto. Cada snapshot journey-N-provenance registra los hashes de su capítulo.


## Placeholders y presentación 0.22.15

Guías vectoriales de composición, rombos de suelo, obstáculos esquemáticos, iconos/efectos provisionales e icono de aplicación creados mediante código para este proyecto con asistencia de IA. Son placeholders, no ilustraciones finales generadas. Manifiesto y SHA256 en art/manifest.json; encargos completos en docs/PROMPTS_ARTE_FINAL.md del repositorio. No se han modificado ni atribuido al proyecto los sprites, retratos, fuentes o sonidos de terceros. Las imágenes futuras deberán conservar su procedencia al incorporarse.
