# Créditos y recursos de terceros

Registro del sprint 0, 13 de octubre de 2026. Commits exactos y archivos: `tools/sources.lock.json` y `public/data/provenance.json`. Los SHA-256 permiten comprobar la integridad de los archivos importados.

## Sprites de Pokémon

Fuente: [PMDCollab / SpriteCollab](https://github.com/PMDCollab/SpriteCollab), commit `6ad5f1c6229af6b055de2c64442e5e508664290c`.

| Especie | Número | Autor indicado en el registro de la fuente |
| --- | --- | --- |
| Bulbasaur | 001 | CHUNSOFT |
| Charmander | 004 | CHUNSOFT |
| Squirtle | 007 | CHUNSOFT |
| Pikachu | 025 | CHUNSOFT |
| Butterfree | 012 | CHUNSOFT |
| Geodude | 074 | CHUNSOFT |

Se incluyen Idle y Walk y sus metadatos. Hojas sin modificar; miniaturas recortadas del primer fotograma. Se conservan los `credits.txt` individuales. La licencia publicada por el repositorio es CC BY-NC 4.0, con atribución, uso no comercial e indicación de modificaciones. Estos seis registros atribuyen material a CHUNSOFT: no se presenta como arte original del proyecto ni como autorización sobre derechos de terceros. Pokémon y material subyacente conservan sus derechos originales.

## Código y herramientas

- [Phaser](https://github.com/phaserjs/phaser), versión 4.0.0: motor 2D, MIT. Aviso íntegro: `licenses/phaser-MIT.md` en la distribución.
- [Plantilla Phaser / Vite / TypeScript](https://github.com/phaserjs/template-vite-ts), commit `d1d7d58acfcf47f97642bcb8b4967071b85f8db9`: base de arranque/configuración adaptada, escenas reemplazadas, versiones fijadas y telemetría retirada. MIT; aviso en `licenses/phaser-template-MIT.txt`.
- [PokéSurvivor, JPTER78](https://github.com/JPTER78/pokesurvivor), commit `a9b21f091d7e2e0b10bc9ef94836447bf63cddeb`: archivo `tools/fetch_sprites.py` conservado como `tools/vendor/pokesurvivor_sprites.py`. Se reutilizan sus funciones de XML, resolución de animaciones y ancla de suelo. El adaptador de este proyecto limita especies, genera JSON y registra hashes. Código MIT; aviso íntegro en `licenses/pokesurvivor-LICENSE.txt`.
- [EasyStar.js](https://github.com/prettymuchbryce/easystarjs), Bryce Neal, versión 0.4.4: búsqueda A* integrada mediante npm, sin modificar el paquete. MIT; aviso íntegro en `licenses/EasyStar-MIT.txt` de la distribución. Usa [heap.js](https://github.com/qiao/heap.js), Xueqiao Xu, versión 0.2.6, port de heapq con licencia PSF y aviso de Python Software Foundation; texto conservado en `licenses/heap-PSF.md`. Versiones e integridad en `package-lock.json`.
- Playwright 1.64.0, Microsoft, Apache-2.0: pruebas de navegador de desarrollo; licencia conservada en el paquete instalado, no se incluye en la aplicación de producción.
- Vite 6.4.4 y TypeScript 5.7.3: herramientas de desarrollo, versiones en el lockfile. Sus licencias se conservan en los paquetes instalados; no se distribuyen como recursos del juego.

## Datos

[PokéAPI](https://pokeapi.co/): nombres, tipos, estadísticas base y clasificación de seis especies. Respuestas cacheadas por el importador y convertidas en una instantánea local. No se consulta la API al jugar. Código del servicio BSD-3-Clause; esto no constituye una licencia general para personajes o datos de terceros. Aviso conservado en `licenses/PokeAPI-BSD-3-Clause.txt`.

Sprint 3: tabla moderna de 18 tipos reutilizada de [`PokeAPI/pokeapi`](https://github.com/PokeAPI/pokeapi/tree/81d20919845b6a445969b9265aab5cec6b04cece/data/v2/csv), commit `81d20919845b6a445969b9265aab5cec6b04cece`. Copias originales de `types.csv` y `type_efficacy.csv` en `tools/vendor/pokeapi`, con fuente, licencia y SHA-256 en `sources.json`. `tools/import-types.mjs` genera la matriz local de 324 relaciones; excluye Stellar y tipos no estándar. Habilidades y reglas tácticas son adaptaciones propias documentadas en `docs/SPRINT_3.md`.

## Tipografía

Pixelify Sans, The Pixelify Sans Project Authors, obtenida del repositorio [Google Fonts](https://github.com/google/fonts/tree/main/ofl/pixelifysans). SIL Open Font License 1.1; archivo sin modificaciones y licencia en `licenses/PixelifySans-OFL.txt`.

## Proyecto y privacidad

Proyecto fan independiente, sin afiliación ni aprobación de Nintendo, Creatures, GAME FREAK o The Pokémon Company. Sus nombres y personajes pertenecen a sus respectivos titulares. Los avisos de terceros no sustituyen permisos sobre la IP.

El sprint 0 no utiliza cuentas, analítica, guardado de partidas ni servicios externos durante el uso. Los enlaces externos de estos créditos solo se abren por acción del usuario. No se incluye música ni sonido en esta entrega.

## Licencias incluidas

- [Phaser MIT](public/licenses/phaser-MIT.md)
- [Plantilla MIT](public/licenses/phaser-template-MIT.txt)
- [PokéSurvivor y separación de contenido](public/licenses/pokesurvivor-LICENSE.txt)
- [SpriteCollab CC BY-NC 4.0](public/licenses/SpriteCollab-CC-BY-NC-4.0.md)
- [Pixelify Sans OFL](public/licenses/PixelifySans-OFL.txt)
- [PokéAPI BSD-3-Clause](public/licenses/PokeAPI-BSD-3-Clause.txt)

En el código fuente las licencias están bajo `public/licenses`; en la web se sirven bajo `licenses`.

- [EasyStar MIT](public/licenses/EasyStar-MIT.txt)
- [heap PSF](public/licenses/heap-PSF.md)
