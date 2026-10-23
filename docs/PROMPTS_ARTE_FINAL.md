# Prompts de arte final · Pokémon Tactics 0.22.15

Actualización 0.22.16: **las 42 imágenes del juego están generadas e integradas** mediante image_gen. Las tres imágenes promocionales opcionales siguen pendientes. Este archivo conserva los encargos; los prompts realmente usados, ajustes de encuadre y hashes se registran en `godot/art/generated-provenance.json`. Sprites, retratos PMD, fuente y sonidos originales conservados.

## Cómo producir y sustituir el arte

1. Genera primero ART-01 (portada) y ART-12 (primer suelo), elige una dirección consistente y úsala como referencia de estilo para el resto. Adjunta las capturas del juego como referencia de distribución, no como imagen a modificar. Adjunta una imagen aprobada de la serie como referencia de estilo. No cambies identidades ni mezcles estilos entre encargos.
2. Copia **todo** el bloque del recurso. Las dimensiones son el tamaño de entrega, no una garantía de la herramienta: si el generador entrega otra medida, ajusta/exporta el recurso antes de instalarlo. No aceptes texto inventado ni transparencias simuladas.
3. Exporta PNG sRGB, 8 bits. Los recursos transparentes requieren RGBA y píxeles realmente transparentes; sin halos. Los tamaños, pivotes y máscaras de las casillas son contratos, no aproximaciones. Comprueba también el resultado al tamaño real del juego.
4. Valida: `python tools/godot/art-assets.py check`. Instala un recurso: `python tools/godot/art-assets.py install --id title_keyart --source RUTA/imagen.png`. El instalador valida dimensiones, estructura PNG y alfa; conserva una copia del archivo anterior. No cambia reglas, estado, mapas ni recursos originales.
5. Importa/exporta de nuevo con los scripts de Godot del proyecto. El juego usa automáticamente `godot/art/final/ID.png` cuando existe y cumple su contrato; en otro caso mantiene el placeholder. Reinicia para vaciar la caché. Instalar brand_emblem actualiza además el icono nativo de aplicación.
6. Revisa los fondos detrás de texto al 100/125/150 %, el contraste de casillas, los contornos de aliados/rivales y la cámara a distintos aumentos. Comprueba créditos y procedencia de cada entrega final antes de distribuir. Los recursos de promoción son opcionales y no aparecen en el juego.

## Contrato de conjunto

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

- El tablero real usa un rombo **5:3 (80×48)**, no el habitual 2:1; altura lógica 12 px. No redibujar la geometría, esconder casillas ni simular alturas en los fondos.
- El terreno se entrega a 4× (320×192); el motor lo representa a 80×48 antes del zoom. Las paredes, contornos tácticos, flechas, PS, textos y selección siguen siendo nativos.
- La interfaz final usa controles reales, no menús dibujados en una imagen. No generar botones con texto.
- Los iconos de estado y etapas existentes siguen siendo vectoriales para conservar +1/−1 y duración legibles. Los efectos nuevos son estáticos: el motor controla su presentación y el movimiento reducido.
- No generar sprites animados de las 151 especies para esta entrega: se reutilizan los originales acreditados. Tampoco sustituir los retratos por rediseños incoherentes.

## Inventario

| Prompt | ID / destino PNG | Medida | Alfa | Uso |
|---|---|---:|---|---|
| ART-01 | `title_keyart.png` | 1920×1080 | No obligatorio | Portada de Kanto |
| ART-02 | `brand_emblem.png` | 512×512 | Sí | Emblema y aplicación |
| ART-03 | `scene_travel.png` | 1600×400 | No obligatorio | Viaje |
| ART-04 | `scene_oak.png` | 1600×400 | No obligatorio | Laboratorio de Oak |
| ART-05 | `scene_shop.png` | 1600×400 | No obligatorio | Tienda |
| ART-06 | `scene_pc.png` | 1600×400 | No obligatorio | Centro y PC |
| ART-07 | `scene_capture.png` | 1600×400 | No obligatorio | Nuevo compañero |
| ART-08 | `scene_ending_birds.png` | 1600×400 | No obligatorio | Final de las aves |
| ART-09 | `scene_ending_origin.png` | 1600×400 | No obligatorio | Final del origen |
| ART-10 | `scene_defeat.png` | 1600×400 | No obligatorio | Fin del viaje |
| ART-11 | `battle_surround.png` | 1920×1080 | No obligatorio | Entorno del tablero |
| ART-12 | `floor_meadow.png` | 320×192 | Sí | Suelo · Prado |
| ART-13 | `floor_forest.png` | 320×192 | Sí | Suelo · Bosque |
| ART-14 | `floor_rock.png` | 320×192 | Sí | Suelo · Roca |
| ART-15 | `floor_water.png` | 320×192 | Sí | Suelo · Costa |
| ART-16 | `floor_ice.png` | 320×192 | Sí | Suelo · Hielo |
| ART-17 | `floor_wood.png` | 320×192 | Sí | Suelo · Barco |
| ART-18 | `floor_industrial.png` | 320×192 | Sí | Suelo · Rocket |
| ART-19 | `floor_haunted.png` | 320×192 | Sí | Suelo · Torre |
| ART-20 | `floor_psychic.png` | 320×192 | Sí | Suelo · Psíquico |
| ART-21 | `floor_volcanic.png` | 320×192 | Sí | Suelo · Volcánico |
| ART-22 | `floor_league.png` | 320×192 | Sí | Suelo · Liga |
| ART-23 | `floor_birds.png` | 320×192 | Sí | Suelo · Santuario de las aves |
| ART-24 | `floor_origin.png` | 320×192 | Sí | Suelo · Cueva del origen |
| ART-25 | `prop_shrub.png` | 256×256 | Sí | Matorral |
| ART-26 | `prop_rock.png` | 256×256 | Sí | Roca |
| ART-27 | `prop_crate.png` | 256×256 | Sí | Caja |
| ART-28 | `prop_crystal.png` | 256×256 | Sí | Cristal |
| ART-29 | `fx_hit.png` | 256×256 | Sí | Impacto |
| ART-30 | `fx_critical.png` | 256×256 | Sí | Crítico |
| ART-31 | `fx_heal.png` | 256×256 | Sí | Curación |
| ART-32 | `fx_miss.png` | 256×256 | Sí | Fallo |
| ART-33 | `fx_immune.png` | 256×256 | Sí | Inmunidad |
| ART-34 | `icon_medicine.png` | 128×128 | Sí | Medicina |
| ART-35 | `icon_evolution.png` | 128×128 | Sí | Evolución |
| ART-36 | `icon_tm.png` | 128×128 | Sí | MT |
| ART-37 | `icon_held.png` | 128×128 | Sí | Equipable |
| ART-38 | `icon_mint.png` | 128×128 | Sí | Menta |
| ART-39 | `icon_capsule.png` | 128×128 | Sí | Cápsula |
| ART-40 | `icon_pc.png` | 128×128 | Sí | PC |
| ART-41 | `icon_badge.png` | 128×128 | Sí | Medallas |
| ART-42 | `icon_money.png` | 128×128 | Sí | Dinero |
| ART-43 | `promo_capsule.png` | 600×900 | No obligatorio | Portada vertical · promoción opcional |
| ART-44 | `promo_banner.png` | 1920×480 | No obligatorio | Banner horizontal · promoción opcional |
| ART-45 | `promo_social.png` | 1200×630 | No obligatorio | Imagen social · promoción opcional |

## ART-01 · Portada de Kanto

ID: `title_keyart`. Destino: `godot/art/final/title_keyart.png`. Entrega: **1920×1080 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Portada de Kanto. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #294c56; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una panorámica de Kanto al amanecer: sendero entre prados, bosque al fondo, costa y una silueta lejana de la meseta de la Liga. Sin personajes ni Pokémon: los retratos y criaturas del juego son recursos separados. Sensación de aventura, descubrimiento y estrategia.

COMPOSICIÓN Y GEOMETRÍA: Dejar el 48 % izquierdo oscuro y tranquilo para un menú vivo. Foco visual en el tercio derecho; horizonte al 36 % de la altura; reservar el 9 % inferior para versión y controles. No incluir botones, interfaz ni letras.

ENTREGA: una sola imagen de 1920×1080 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-02 · Emblema y aplicación

ID: `brand_emblem`. Destino: `godot/art/final/brand_emblem.png`. Entrega: **512×512 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Emblema y aplicación. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #bd9452; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Un emblema sencillo que combine una brújula de cuatro direcciones, un tablero de cuatro rombos y un círculo de captura. Una silueta principal reconocible, apropiada para un RPG táctico de criaturas.

COMPOSICIÓN Y GEOMETRÍA: Objeto centrado dentro de un cuadrado de 512×512, margen vacío del 12 %. Debe seguir legible a 32×32. Sin tipografía; no copiar el logotipo oficial de Pokémon. Fondo realmente transparente.

ENTREGA: una sola imagen de 512×512 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-03 · Viaje

ID: `scene_travel`. Destino: `godot/art/final/scene_travel.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Viaje. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #4c7663; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Un mapa ilustrado de Kanto extendido sobre una mesa de viaje, libreta y brújula a los lados. Geografía inspirada en Kanto: costa sur y este, bosque al oeste, montañas al norte. No dibujar rutas de progresión ni nodos: el juego los gestiona.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-04 · Laboratorio de Oak

ID: `scene_oak`. Destino: `godot/art/final/scene_oak.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Laboratorio de Oak. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #a2916f; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Interior cálido y ordenado del laboratorio de Oak: mesa de madera, tres cápsulas de captura cerradas, libros de investigación, plantas junto a una ventana. Sin personajes.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-05 · Tienda

ID: `scene_shop`. Destino: `godot/art/final/scene_shop.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Tienda. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #726e58; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Interior de una pequeña tienda de suministros para entrenadores: mostrador de madera, estantes ordenados con frascos, cajas, bolsa de viaje y luz del exterior. No simular ofertas, precios ni inventario.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-06 · Centro y PC

ID: `scene_pc`. Destino: `godot/art/final/scene_pc.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Centro y PC. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #4e7f85; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Rincón limpio de un centro de descanso para entrenadores, terminal de almacenamiento con monitor apagado, casilleros y una planta. Sin Pokémon, texto ni estadísticas en pantalla.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-07 · Nuevo compañero

ID: `scene_capture`. Destino: `godot/art/final/scene_capture.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Nuevo compañero. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #638157; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Claro de hierba con una cápsula de captura cerrada en un círculo de luz suave; flores pequeñas y hojas que enmarquen el espacio. Sin criatura dentro: el retrato real se superpone mediante el juego.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-08 · Final de las aves

ID: `scene_ending_birds`. Destino: `godot/art/final/scene_ending_birds.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Final de las aves. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #687b87; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Santuario remoto de Kanto con tres formas de paisaje: cristal de hielo a la izquierda, conductores de tormenta en el centro y roca volcánica a la derecha; equilibrio después del desafío. No dibujar a las aves legendarias.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-09 · Final del origen

ID: `scene_ending_origin`. Destino: `godot/art/final/scene_ending_origin.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Final del origen. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #796a8c; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Cámara silenciosa de una cueva profunda, lago subterráneo y restos discretos de instrumental de investigación, luz violeta tenue. Evocar misterio y origen sin dibujar a Mew ni Mewtwo.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-10 · Fin del viaje

ID: `scene_defeat`. Destino: `godot/art/final/scene_defeat.png`. Entrega: **1600×400 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Fin del viaje. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #886650; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Mochila y brújula junto a un sendero al atardecer, luz cálida tras el horizonte. Melancolía contenida y posibilidad de empezar otra aventura. Sin personajes heridos ni dramatismo explícito.

COMPOSICIÓN Y GEOMETRÍA: Franja panorámica 4:1, cámara elevada suave. Motivo principal en el tercio derecho. Mantener el tercio central despejado, contornos tranquilos y el 10 % exterior libre de objetos cortados. La imagen no contiene interfaz ni texto.

ENTREGA: una sola imagen de 1600×400 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-11 · Entorno del tablero

ID: `battle_surround`. Destino: `godot/art/final/battle_surround.png`. Entrega: **1920×1080 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Entorno del tablero. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #263f49; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Superficie oscura de un cuaderno de expedición con relieve de papel y contornos cartográficos muy discretos en los bordes, acorde a un tablero táctico isométrico.

COMPOSICIÓN Y GEOMETRÍA: Centro y banda izquierda casi vacíos, bajo contraste. Detalles solo en el 12 % exterior. Sin mapas jugables, criaturas, fichas, casillas ni textos; los terrenos se dibujan por separado.

ENTREGA: una sola imagen de 1920×1080 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-12 · Suelo · Prado

ID: `floor_meadow`. Destino: `godot/art/final/floor_meadow.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Prado. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #769264; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: hierba corta con tierra clara y dos pequeñas variaciones de vegetación. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-13 · Suelo · Bosque

ID: `floor_forest`. Destino: `godot/art/final/floor_forest.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Bosque. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #628355; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: musgo y suelo de bosque, hojas pequeñas y raíces muy bajas. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-14 · Suelo · Roca

ID: `floor_rock`. Destino: `godot/art/final/floor_rock.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Roca. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #afa78c; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: piedra caliza cálida con juntas suaves, sin agujeros ni precipicios. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-15 · Suelo · Costa

ID: `floor_water`. Destino: `godot/art/final/floor_water.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Costa. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #b4ae83; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: suelo arenoso costero compacto con guijarros pequeños, sin olas sobre la superficie. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-16 · Suelo · Hielo

ID: `floor_ice`. Destino: `godot/art/final/floor_ice.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Hielo. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #a6c8c8; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: hielo azul lechoso compacto con dos fracturas finas de baja intensidad. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-17 · Suelo · Barco

ID: `floor_wood`. Destino: `godot/art/final/floor_wood.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Barco. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #957b5b; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: tablones cortos de madera naval cálida con juntas paralelas y desgaste moderado. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-18 · Suelo · Rocket

ID: `floor_industrial`. Destino: `godot/art/final/floor_industrial.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Rocket. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #7f9195; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: baldosa de metal pintado gris verdoso con una única junta técnica discreta. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-19 · Suelo · Torre

ID: `floor_haunted`. Destino: `godot/art/final/floor_haunted.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Torre. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #85768e; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: baldosa antigua de piedra violeta grisácea con bordes gastados y polvo fino. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-20 · Suelo · Psíquico

ID: `floor_psychic`. Destino: `godot/art/final/floor_psychic.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Psíquico. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #a58dba; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: baldosa pulida malva con un motivo geométrico muy tenue, sin glifos ni texto. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-21 · Suelo · Volcánico

ID: `floor_volcanic`. Destino: `godot/art/final/floor_volcanic.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Volcánico. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #9d7562; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: roca basáltica cálida con grietas oscuras; sin lava luminosa ni fuego que confunda con peligro real. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-22 · Suelo · Liga

ID: `floor_league`. Destino: `godot/art/final/floor_league.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Liga. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #8d9daf; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: piedra noble azul grisácea con losas ordenadas y un detalle sobrio de pizarra. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-23 · Suelo · Santuario de las aves

ID: `floor_birds`. Destino: `godot/art/final/floor_birds.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Santuario de las aves. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #99a7a0; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: piedra ritual desaturada gris verdosa que combine con hielo, tormenta y fuego sin incorporar símbolos elementales activos. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-24 · Suelo · Cueva del origen

ID: `floor_origin`. Destino: `godot/art/final/floor_origin.png`. Entrega: **320×192 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Suelo · Cueva del origen. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #9182a8; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una única cara superior de terreno: piedra de cueva violeta grisácea con un pequeño veteado mineral tenue. Sin elementos altos, sombras proyectadas externas ni paredes.

COMPOSICIÓN Y GEOMETRÍA: Rombo isométrico 5:3 exacto: vértices (160,0), (320,96), (160,192), (0,96). Cara plana, sin perspectiva convergente. Transparencia total fuera del rombo. Luz fija desde arriba a la izquierda. Diseño repetible sin bordes gruesos. El juego lo reduce a 80×48 y genera las paredes de altura; no dibujarlas.

ENTREGA: una sola imagen de 320×192 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-25 · Matorral

ID: `prop_shrub`. Destino: `godot/art/final/prop_shrub.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Matorral. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #5a774b; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Un matorral bajo y compacto de hojas verdes, sin tronco alto ni frutos. Es decoración para una casilla bloqueada.

COMPOSICIÓN Y GEOMETRÍA: Vista isométrica 5:3, objeto completo dentro del lienzo. Pivote de apoyo exacto (128,192); huella máxima de 224×112. Nada por debajo de y=224 ni por encima de y=32. Borde vacío mínimo 16 px. Sombra corta incorporada y fondo realmente transparente. Lectura clara al reducir a 64×64.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-26 · Roca

ID: `prop_rock`. Destino: `godot/art/final/prop_rock.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Roca. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #898e7b; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una roca baja y ancha, caliza gris cálida, con dos planos de luz. Es decoración para una casilla bloqueada.

COMPOSICIÓN Y GEOMETRÍA: Vista isométrica 5:3, objeto completo dentro del lienzo. Pivote de apoyo exacto (128,192); huella máxima de 224×112. Nada por debajo de y=224 ni por encima de y=32. Borde vacío mínimo 16 px. Sombra corta incorporada y fondo realmente transparente. Lectura clara al reducir a 64×64.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-27 · Caja

ID: `prop_crate`. Destino: `godot/art/final/prop_crate.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Caja. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #967957; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una caja baja de madera y metal, cerrada, sin etiqueta. Es decoración para una casilla bloqueada.

COMPOSICIÓN Y GEOMETRÍA: Vista isométrica 5:3, objeto completo dentro del lienzo. Pivote de apoyo exacto (128,192); huella máxima de 224×112. Nada por debajo de y=224 ni por encima de y=32. Borde vacío mínimo 16 px. Sombra corta incorporada y fondo realmente transparente. Lectura clara al reducir a 64×64.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-28 · Cristal

ID: `prop_crystal`. Destino: `godot/art/final/prop_crystal.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Cristal. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #8f82a0; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Una agrupación baja de tres cristales desaturados gris violeta, sin aura ni partículas. Es decoración para una casilla bloqueada.

COMPOSICIÓN Y GEOMETRÍA: Vista isométrica 5:3, objeto completo dentro del lienzo. Pivote de apoyo exacto (128,192); huella máxima de 224×112. Nada por debajo de y=224 ni por encima de y=32. Borde vacío mínimo 16 px. Sombra corta incorporada y fondo realmente transparente. Lectura clara al reducir a 64×64.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-29 · Impacto

ID: `fx_hit`. Destino: `godot/art/final/fx_hit.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Impacto. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #e7c784; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Un destello radial pequeño de impacto físico, seis puntas cortas y dos fragmentos, sensación de golpe preciso

COMPOSICIÓN Y GEOMETRÍA: Un solo fotograma estático y aislado. Motivo centrado, margen transparente 20 %. Sin texto, cifras ni marco. Fondo realmente transparente; no fondo negro ni falso damero. El juego añade el resultado real y controla duración y movimiento reducido. Debe leerse a 32–48 px.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-30 · Crítico

ID: `fx_critical`. Destino: `godot/art/final/fx_critical.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Crítico. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #f1b653; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Un destello de impacto dorado de ocho puntas, centro claro y silueta compacta más intensa que el impacto normal

COMPOSICIÓN Y GEOMETRÍA: Un solo fotograma estático y aislado. Motivo centrado, margen transparente 20 %. Sin texto, cifras ni marco. Fondo realmente transparente; no fondo negro ni falso damero. El juego añade el resultado real y controla duración y movimiento reducido. Debe leerse a 32–48 px.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-31 · Curación

ID: `fx_heal`. Destino: `godot/art/final/fx_heal.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Curación. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #81bf91; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Un pequeño brote luminoso verde con tres destellos redondos alrededor, sensación de recuperación

COMPOSICIÓN Y GEOMETRÍA: Un solo fotograma estático y aislado. Motivo centrado, margen transparente 20 %. Sin texto, cifras ni marco. Fondo realmente transparente; no fondo negro ni falso damero. El juego añade el resultado real y controla duración y movimiento reducido. Debe leerse a 32–48 px.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-32 · Fallo

ID: `fx_miss`. Destino: `godot/art/final/fx_miss.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Fallo. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #87bcc5; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Tres estelas curvas cortas azul claro que expresen esquiva, sin diana ni cruz de prohibición

COMPOSICIÓN Y GEOMETRÍA: Un solo fotograma estático y aislado. Motivo centrado, margen transparente 20 %. Sin texto, cifras ni marco. Fondo realmente transparente; no fondo negro ni falso damero. El juego añade el resultado real y controla duración y movimiento reducido. Debe leerse a 32–48 px.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-33 · Inmunidad

ID: `fx_immune`. Destino: `godot/art/final/fx_immune.png`. Entrega: **256×256 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Inmunidad. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #b8a3cf; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Un pequeño escudo de energía violeta cerrado, silueta hexagonal con una línea de rebote

COMPOSICIÓN Y GEOMETRÍA: Un solo fotograma estático y aislado. Motivo centrado, margen transparente 20 %. Sin texto, cifras ni marco. Fondo realmente transparente; no fondo negro ni falso damero. El juego añade el resultado real y controla duración y movimiento reducido. Debe leerse a 32–48 px.

ENTREGA: una sola imagen de 256×256 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-34 · Medicina

ID: `icon_medicine`. Destino: `godot/art/final/icon_medicine.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Medicina. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #9fb6a1; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Frasco pequeño de medicina para criaturas con tapón sólido y etiqueta vacía

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-35 · Evolución

ID: `icon_evolution`. Destino: `godot/art/final/icon_evolution.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Evolución. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #d3af76; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Pequeña piedra evolutiva facetada junto a un caramelo envuelto, sin letras

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-36 · MT

ID: `icon_tm`. Destino: `godot/art/final/icon_tm.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: MT. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #a3bfd0; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Disco de entrenamiento circular con una marca geométrica sencilla y sin números

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-37 · Equipable

ID: `icon_held`. Destino: `godot/art/final/icon_held.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Equipable. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #c98570; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Amuleto compacto con una esfera roja oscura y un enganche simple

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-38 · Menta

ID: `icon_mint`. Destino: `godot/art/final/icon_mint.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Menta. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #8dbb8d; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Ramita de menta con tres hojas diferenciadas

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-39 · Cápsula

ID: `icon_capsule`. Destino: `godot/art/final/icon_capsule.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Cápsula. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #bca3c9; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Cápsula horizontal de dos mitades que sugiera cambio de habilidad, sin letras

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-40 · PC

ID: `icon_pc`. Destino: `godot/art/final/icon_pc.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: PC. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #87b9c0; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Terminal compacto de almacenamiento con pantalla de color liso, sin datos

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-41 · Medallas

ID: `icon_badge`. Destino: `godot/art/final/icon_badge.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Medallas. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #dab969; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Medalla octogonal simple dorada con una hendidura central, sin texto

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-42 · Dinero

ID: `icon_money`. Destino: `godot/art/final/icon_money.png`. Entrega: **128×128 px**, PNG RGBA con transparencia real.

```text
ENCARGO: Dinero. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #dbc074; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Moneda dorada con un círculo interior vacío, sin símbolo monetario ni números

COMPOSICIÓN Y GEOMETRÍA: Icono individual sobre transparencia real, centrado con margen 16 %. Vista tres cuartos coherente, luz superior izquierda, contorno de 8 px en el tamaño maestro, agrupaciones de píxeles sobre rejilla de 4 px. Máximo tres formas principales y cuatro tonos. Legible a 24×24; no dibujar el nombre, precio, botón, marco ni interfaz.

ENTREGA: una sola imagen de 128×128 píxeles. PNG RGBA con fondo realmente transparente; ningún píxel de damero pintado ni recuadro de color.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar alfa en editor y en el juego sobre fondo claro y oscuro.

## ART-43 · Portada vertical

ID: `promo_capsule`. Destino: `godot/art/final/promo_capsule.png`. Entrega: **600×900 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Portada vertical. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #46716b; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Ilustración de una aventura táctica en Kanto: sendero, prados, bosque y costa, con pequeños rombos de terreno en primer plano. Sin criaturas ni entrenadores; los retratos oficiales de juego se componen por separado.

COMPOSICIÓN Y GEOMETRÍA: Composición vertical con senda ascendente, Kanto al fondo y foco central. Reservar el 28 % superior vacío para la marca añadida después. No añadir promesas de características, precios, logotipos de plataformas, marcas de agua ni texto.

ENTREGA: una sola imagen de 600×900 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-44 · Banner horizontal

ID: `promo_banner`. Destino: `godot/art/final/promo_banner.png`. Entrega: **1920×480 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Banner horizontal. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #46716b; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Ilustración de una aventura táctica en Kanto: sendero, prados, bosque y costa, con pequeños rombos de terreno en primer plano. Sin criaturas ni entrenadores; los retratos oficiales de juego se componen por separado.

COMPOSICIÓN Y GEOMETRÍA: Composición panorámica 4:1 con aventura en el tercio derecho y el 50 % izquierdo tranquilo para marca y fecha añadidas después. No añadir promesas de características, precios, logotipos de plataformas, marcas de agua ni texto.

ENTREGA: una sola imagen de 1920×480 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## ART-45 · Imagen social

ID: `promo_social`. Destino: `godot/art/final/promo_social.png`. Entrega: **1200×630 px**, PNG sRGB; puede ser opaco.

```text
ENCARGO: Imagen social. Recurso individual listo para integrar en un juego de escritorio; no crear un mockup de una interfaz ni una lámina con variantes.

Dirección común «Cuaderno de Kanto»: pixel art táctico de aventura, color contenido, formas cuidadas y textura limpia. Construcción sobre una rejilla lógica, bordes de píxel nítidos y grupos de píxeles deliberados; sin ruido fino, desenfoque, bloom, render 3D ni pinceladas borrosas. Escala visual compatible con sprites pequeños de Pokémon Mundo Misterioso; las criaturas existentes se conservan por separado. Materiales naturales, tinta azul petróleo #142A36, marfil #F1E9D2 y ámbar #F0C568 como acentos; verdes y azules desaturados para el mundo. Luz suave fija desde arriba a la izquierda. Evocar aventura de Kanto y claridad de un RPG táctico, con composición propia, sin copiar una pantalla concreta de otro juego. Toda tipografía, estadística, botón, ruta seleccionable y resultado se añade mediante código; la imagen no debe incluirlos.

PALETA LOCAL: base #46716b; sombras frías de la misma familia y luces marfil moderadas. El contraste del objeto debe mantenerse al reducirlo al tamaño de uso.

SUJETO Y MATERIALES: Ilustración de una aventura táctica en Kanto: sendero, prados, bosque y costa, con pequeños rombos de terreno en primer plano. Sin criaturas ni entrenadores; los retratos oficiales de juego se componen por separado.

COMPOSICIÓN Y GEOMETRÍA: Composición 1.905:1 con tablero táctico sugerido a la derecha y 45 % izquierdo limpio para título añadido después. No añadir promesas de características, precios, logotipos de plataformas, marcas de agua ni texto.

ENTREGA: una sola imagen de 1200×630 píxeles. PNG sRGB. No añadir borde ni paspartú.

EVITAR: letras, cifras, marcas de agua, firma, logotipos de plataformas, marcos de interfaz, botones, retículas tácticas ajenas, personajes adicionales, elementos cortados, sombras inconsistentes, perspectiva 3D convergente, fotorealismo, exceso de detalle, brillo intenso y suavizado borroso. No añadir características de juego ni resultados que la imagen no controla.
```

Criterio de aceptación: medida y formato exactos; composición compatible con el hueco real; ninguna letra accidental; paleta y luz de la serie; legibilidad al tamaño de uso. Verificar que el arte no compita con las etiquetas nativas.

## Correcciones dirigidas para una segunda pasada

- Estilo inconsistente: «Cambia únicamente la agrupación de píxeles y la paleta para coincidir con la imagen de estilo adjunta; conserva composición, perspectiva, dimensiones, sujeto y espacios vacíos. No añadas elementos».
- Texto intruso: «Elimina solo todas las letras, cifras, marcas y firmas; reconstruye el material local. Conserva el resto exactamente y no inventes otra interfaz».
- Ruido excesivo: «Reduce solo el detalle interior de las superficies y los colores secundarios; conserva silueta, luz, encuadre y geometría. El resultado debe leerse a su tamaño real».
- Suelo incorrecto: «Recompón solo la cara superior dentro del rombo 5:3 de los vértices indicados. Elimina paredes y sombras exteriores. Mantén alfa total fuera de esa máscara. No cambies el material ni la luz».
- Transparencia falsa: «Extrae únicamente el objeto sobre alfa real; elimina el damero o fondo pintado sin cambiar los bordes, la escala, el color ni el pivote. Sin halo».

## Qué falta para publicación visual

Esta entrega es un candidato visual funcional con arte nuevo provisional. Sustituir todos los slots requeridos, revisar cada imagen dentro del juego, añadir su procedencia/créditos y volver a exportar y probar. `check --require-final` falla mientras quede algún placeholder requerido; no afirma calidad artística ni aprobación humana. Los tres recursos de promoción pueden producirse después. La publicación pública sigue pendiente de decisión del creador.
