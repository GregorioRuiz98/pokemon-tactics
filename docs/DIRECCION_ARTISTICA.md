# Dirección artística · Cuaderno de Kanto

Base visual de Pokémon Tactics 0.22.15, producida en 0.22.16. Las 42 imágenes del juego están generadas e integradas; los placeholders se conservan como respaldo y para las tres piezas promocionales opcionales pendientes. La distribución, tipografía, marcos, estados y jerarquía mantienen esta dirección.

## Intención

Aventura táctica de Kanto presentada como un cuaderno de expedición: tinta azul petróleo, papel marfil, selección ámbar y mundos naturales de color contenido. Los Pokémon y sus expresiones deben ser los protagonistas. La ilustración aporta lugar y atmósfera; los controles y los resultados permanecen legibles y separados de ella.

Se conserva el pixel art pequeño de los sprites y retratos de Mundo Misterioso, sin recolorear los originales. La escena nueva debe tener grupos de píxeles claros, detalle controlado y luz superior izquierda. No mezclar con renders 3D, fotografía, personajes rediseñados o fondos borrosos. Usar Final Fantasy Tactics, Fire Emblem y Triangle Strategy como referencias de claridad táctica, composición y jerarquía, sin copiar sus pantallas ni sus activos.

## Sistema de interfaz

| Función | Decisión |
|---|---|
| Fondo / tinta | #142A36; paneles oscuros casi opacos |
| Papel | #F1E9D2; órdenes y compras claras |
| Selección | #F0C568, cursor y borde de foco |
| Aliados | #64D4D1, acompañado por forma y etiqueta |
| Rivales | #ED8F74, acompañado por forma y etiqueta |
| Avance | Rojo terroso, un único compromiso principal por pantalla |
| Tipografía | Atkinson Hyperlegible existente; texto vivo, nunca en las imágenes |
| Ritmo | Base de 4 px; contenedores, alineación y desplazamiento interno |
| Acceso | Botones reales, nombres accesibles, foco visible, remapeo y Escape |

La tienda mantiene Comprar / Equipo y bolsa. Cuatro categorías; objetos poseídos en la ficha del Pokémon; Resumen bajo demanda. Seguir viaje queda fuera del desplazamiento. No introducir tutoriales largos ni etiquetas técnicas en los flujos normales. El pequeño identificador ART-XX solo aparece en las ilustraciones provisionales y desaparece automáticamente al instalar arte final válido.

Los fondos de portada reservan el 48 % izquierdo para el menú y el 9 % inferior para utilidades. Un velo nativo de tinta protege el texto; el fondo no contiene menús. Las escenas de viaje se muestran como franjas 4:1 dentro de su panel. Las ilustraciones son decorativas y no capturan entrada del ratón. No se añaden bucles de animación de fondo ni partículas continuas.

## Tablero y unidades

- Proyección real 5:3: rombo de 80×48, vértices relativos (40,0), (80,24), (40,48), (0,24). Cada altura lógica levanta 12 px. No convertir a un tileset 2:1.
- Suelos maestros 320×192, con alfa cero fuera del rombo. El motor dibuja paredes y desniveles reales. Los contornos de movimiento, ataque, área, cursor, altura y orientación se aplican después del arte.
- Trece familias visuales cubren los dieciocho biomas actuales; el manifiesto relaciona cada bioma con su suelo. No se altera ninguna casilla, ruta, cobertura, altura, coste, generación ni decisión de la IA.
- Obstáculos 256×256 con apoyo en (128,192), representados a 64×64 y detrás de las unidades. Mantenerlos bajos para conservar lectura de casillas. No dibujar edificios o árboles gigantes como sustituto de una sola casilla.
- Unidades, retratos, animaciones, contornos de facción y medidores siguen usando los recursos y los datos originales. Ninguna imagen nueva inventa criaturas, rivales, daño, estados o alcances.

## Recursos y sustitución

45 huecos: portada y emblema, ocho escenas, entorno de tablero, trece suelos, cuatro obstáculos, cinco efectos, nueve iconos y tres recursos de promoción opcionales. Los 42 recursos del juego son requeridos para cerrar el arte; los tres de promoción no aparecen en las pantallas de juego.

`godot/art/manifest.json` es la lista de contratos. Cada entrada incluye nombre, función, tamaño, alfa, placeholder, destino final, prompt y SHA256 del placeholder. `docs/PROMPTS_ARTE_FINAL.md` contiene todos los encargos completos, el orden recomendado, sus invariantes y las correcciones para una segunda pasada.

Los PNG finales se instalan en `godot/art/final/ID.png` con `python tools/godot/art-assets.py install --id ID --source RUTA.png`. La herramienta verifica estructura/CRC, dimensiones, PNG de 8 bits, alfa real y máscara de suelo; crea una copia al reemplazar. El emblema actualiza también el icono nativo. El historial queda excluido de Git y de la exportación.

Hay que importar y exportar de nuevo el proyecto después de instalar imágenes. Un EXE lleva sus recursos dentro; copiar PNG junto al ejecutable no los sustituye. Al iniciar, el registro comprueba medidas y alfa, usa los PNG válidos y mantiene el placeholder si falta un archivo o no cumple las comprobaciones de presentación. La caché evita lecturas repetidas por fotograma; una sustitución requiere reiniciar.

## Criterios de acabado

1. Paleta, perspectiva, grupos de píxeles y luz coherentes en todos los recursos. Ninguna letra accidental, marca de agua o damero pintado.
2. Revisar a tamaño real: iconos a 24 px; efectos a 24–40 px; suelos a 80×48 y con zoom; escenas tras los controles al 100/125/150 %.
3. Texto, selección y unidades conservan contraste con alto contraste y movimiento reducido. No desplazar controles ni tapar casillas para acomodar una imagen.
4. Verificar procedencia y créditos de los PNG finales; conservar las atribuciones de los recursos reutilizados. No sustituir los créditos de SpriteCollab por atribución al generador.
5. `python tools/godot/art-assets.py check --require-final` debe pasar antes de presentar el arte como terminado. Esta comprobación técnica no determina calidad artística ni sustituye la revisión dentro del juego.
6. Exportar, probar el paquete offline y comparar guardados. Las pruebas humanas y la publicación pública siguen pendientes; no se publica como parte de este encargo.
