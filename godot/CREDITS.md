# Pokémon Tactics — laboratorio nativo 0.13.0

Proyecto de fans para portfolio, sin afiliación ni aprobación oficial. Pokémon y sus personajes pertenecen a sus respectivos titulares.

Esta entrega reutiliza únicamente las seis especies del ensayo: Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude. Hojas Idle/Walk originales y metadatos de SpriteCollab; miniaturas y datos locales del proyecto web. Autores registrados de estas seis especies: CHUNSOFT. Cada carpeta conserva credits.txt. El manifiesto data/provenance.json registra SHA-256 de cada archivo, su origen local y las fuentes de reglas usadas en las pruebas.

- SpriteCollab, PMDCollab: https://github.com/PMDCollab/SpriteCollab. Commit 6ad5f1c6229af6b055de2c64442e5e508664290c; condiciones publicadas CC BY-NC 4.0 y atribución individual, sin convertirlas en autorización sobre derechos subyacentes. Aviso en licenses/SpriteCollab-CC-BY-NC-4.0.md.
- Datos de PokéAPI y tabla moderna de tipos: instantáneas locales existentes. Licencia del código BSD-3-Clause en licenses/PokeAPI-BSD-3-Clause.txt. No hay consultas a la API al jugar.
- Pixelify Sans: fuente original, licencia SIL OFL en licenses/PixelifySans-OFL.txt.
- Sonidos select/hit/victory: WAV locales del proyecto generados con jsfxr; aviso en licenses/jsfxr-UNLICENSE.txt. La copia nativa de victory.wav añade el byte de relleno RIFF que faltaba y ajusta la longitud del contenedor para Godot; las muestras PCM y su longitud permanecen idénticas. Fuente original sin modificar, ambos hashes y adaptación registrados en provenance.json.
- La navegación GDScript adapta el orden A* de EasyStar.js 0.4.4 y las operaciones de heap.js 0.2.6 para conservar recorridos equivalentes. EasyStar: Bryce Neal, MIT; heap.js: Xueqiao Xu, licencia PSF y avisos de Python Software Foundation. Textos en licenses/EasyStar-MIT.txt y licenses/heap-PSF.md.
- Godot 4.7.2 estándar: motor de código abierto, licencia MIT. Su texto de licencia y los avisos de bibliotecas de terceros se muestran desde el menú Créditos mediante los datos incluidos en el propio motor.

El registro completo de las fuentes del proyecto web se conserva, sin modificar, en licenses/web-CREDITS.md; incluye especies y dependencias que no se distribuyen en este laboratorio nativo. No se incorpora música, un catálogo de 151 especies ni contenido de campaña nuevo.


## Retratos de diálogo — revisión 0.13.2

Retratos Normal de Bulbasaur, Charmander, Squirtle, Pikachu, Butterfree y Geodude, estilo Pokémon Mundo Misterioso / Exploradores. Autor registrado: CHUNSOFT. Proceden de portrait/NNNN/Normal.png de SpriteCollab, commit 6ad5f1c6229af6b055de2c64442e5e508664290c, el mismo origen fijado para los sprites. Se conservan los PNG originales de 40×40 y sus créditos individuales en assets/portraits/ID; solo se escalan con nearest al mostrar. data/portraits.json registra URLs, hashes y créditos. No se atribuyen al autor del juego ni se consulta el repositorio al jugar.

Herramienta explícita: npm run godot:import:portraits. Aviso de SpriteCollab ya incluido en licenses/SpriteCollab-CC-BY-NC-4.0.md. La atribución y condiciones de recursos comunitarios no sustituyen los derechos subyacentes de Pokémon.
