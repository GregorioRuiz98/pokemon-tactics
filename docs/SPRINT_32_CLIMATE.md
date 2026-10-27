# Climas, habilidades y mentas — 0.32.0

27 de octubre de 2026. Windows local, campaña25/capítulo29/combate22.
Implementa las treinta habilidades que quedaban sin efecto y completa Piel Seca.
Las 78 habilidades normales del catálogo tienen ahora una aplicación táctica.

## Climas y acceso

Un único clima global: despejado, sol, lluvia o tormenta de arena. Día Soleado,
Danza Lluvia y Tormenta Arena consumen la acción y 2 PP al **equiparlos**; no
gastan puntos al usarse. Duran la ronda parcial actual y tres rondas completas.
Reemplazan el clima anterior; no permiten repetir el que ya está activo.

| Clima | Efectos |
|---|---|
| Sol | Fuego ×1,5; Agua ×0,5; precisión de Trueno50. |
| Lluvia | Agua ×1,5; Fuego ×0,5; Trueno supera la comprobación de precisión. |
| Arena | Daño de1/16 PS máximos al terminar cada activación, salvo Roca/Tierra/Acero; Defensa especial de Roca ×1,5. |

Las técnicas están disponibles como tres nuevas MT de80 ₽ en la oferta aleatoria
normal. Compatibilidad importada de instantáneas existentes de PokéAPI: unión
de aprendizaje por máquina de las generaciones7–9,112/107/38 especies,
respectivamente. Es una excepción explícita a la base LGPE, que no contiene
estas técnicas. No se han alterado las otras211 ni sus precios.

Las familias con Clorofila/Defensa Hoja, Nado Rápido/Hidratación/Piel Seca y Velo
Arena aprenden su clima al15, únicamente en formas compatibles. Al evolucionar
se aplica el aprendizaje normal. Se conserva el orden original de aprendizaje.
Los rivales compatibles de nivel15 o superior preparan su clima respetando las
cuatro ranuras y el mismo presupuesto de PP. La IA compara ventajas de ambos
bandos y espera tres rondas antes de volver a cambiarlo.

Bosque Verde empieza con lluvia; rutas3/17 con sol; ruta4 con arena; rutas9 y
19–21 con lluvia excepto21, que tiene sol. Estos climas iniciales duran tres
rondas completas. Los demás escenarios comienzan despejados. No hay tiradas
meteorológicas adicionales.

## Habilidades aplicadas

Todas las auras requieren distancia Manhattan y visión del terreno. No atraviesan
obstáculos sólidos. Varias fuentes iguales no acumulan su penalización.

| Habilidad | Efecto en esta edición |
|---|---|
| Clorofila | Velocidad ×2 bajo sol al formar la siguiente cola; ninguna activación adicional. |
| Nado Rápido | Velocidad ×2 bajo lluvia al formar la siguiente cola. |
| Hidratación | Cura el estado principal al terminar la activación bajo lluvia. |
| Defensa Hoja | Impide nuevos estados principales bajo sol; no elimina los ya presentes. |
| Velo Arena | Inmune al daño de arena; daño recibido a distancia −20 % bajo arena, sin más fallos por precisión. |
| Aclimatación | Aura3: neutraliza el clima para aliados y enemigos dentro. |
| Muro Mágico | Evita daño de estados, clima, Drenadoras, zonas dañinas y Vidasfera. No evita ataques, retroceso propio ni costes de PS. |
| Tenacidad | Una bajada de atributos causada por una acción rival otorga +2 At. especial, una vez por acción y respetando el límite. |
| Foco Interno | Impide amedrentamiento, Intimidación y el empuje de Hedor. |
| Lodo Líquido | Drenaje y Drenadoras dañan al beneficiario por los PS que habría recuperado. |
| Despiste | Impide Mofa, Intimidación y Encanto. |
| Madrugar | Reduce el contador de sueño dos pasos por activación. |
| Intrépido | Normal y Lucha alcanzan a Fantasma; conserva las otras resistencias. |
| Francotirador | Multiplicador de crítico ×2,25 en lugar de ×1,5. |
| Descarga | Al desplegar: +1 Ataque si el enemigo más cercano tiene Defensa menor que Def. especial; en otro caso +1 At. especial. |
| Calco | Copia al comenzar una habilidad válida del rival más cercano; muestra previsión antes de desplegar. Sin cadenas de Calco ni copia de Gas Reactivo. |
| Gas Reactivo | Aura2: anula otras habilidades de ambos bandos; salir no repite efectos de entrada. |
| Cuerpo Maldito | Al recibir daño:30 % de anular esa técnica durante la próxima activación del atacante; básico disponible y protección temporal contra anulaciones repetidas. |
| Fuga | Atraviesa rivales sin ocupar su casilla final; ignora Trampa Arena e Imán, manteniendo terreno y alturas. |
| Trampa Arena | Salir de una casilla adyacente cuesta +1 movimiento a rivales terrestres; excluye voladores, Levitación y Fuga. |
| Imán | Aura2: pasos de enemigos Acero dentro cuestan +1 movimiento, salvo Fuga. |
| Viscosidad | Impide empujes y atracciones hostiles; conserva desplazamiento voluntario. El catálogo actual no tiene retirada de equipables, por lo que esa inmunidad no añade aún otra interacción. |
| Cura Natural | Terminar sin usar una acción cura el estado principal; puede haberse movido. |
| Recogida |25 % de recibir una Poción al ganar si sobrevive un poseedor; una tirada por equipo/encuentro, sin repetir al cargar. |
| Hedor | Contacto:10 % de empujar una casilla libre, una comprobación por acción y sin daño de choque. |
| Alerta | Al desplegar marca la técnica rival de mayor potencia; daño recibido de esa técnica −25 %. |
| Iluminación | Aura2 aliada: elimina la penalización del humo, conservando paredes y demás reglas de precisión. |
| Presión | Enemigos que comienzan dentro de aura2: −1 movimiento, mínimo1; no acumula fuentes. |
| Rivalidad | Potencia +25 % frente al mismo sexo, −25 % frente al opuesto; sin sexo, neutral. |
| Gran Encanto |30 % al recibir contacto de sexo opuesto: durante dos activaciones futuras el atacante causa20 % menos daño al poseedor; no pierde turnos. |

Piel Seca conserva absorción de Agua y vulnerabilidad al Fuego; ahora lluvia cura
1/8 PS y sol causa1/8 al terminar. Las cifras anteriores de ataques, estadísticas,
EXP, caps y economía se conservan salvo los efectos explícitos anteriores y las
tres MT nuevas. Los cambios de atributos siguen durante todo el combate y los
estados siguen temporales. Saltos/aproximaciones especiales de movimientos
conservan sus reglas propias; las auras de control alteran las rutas normales.

## Presentación y guardado

- Clima y duración en cabecera; efectos visuales de sol, lluvia y arena al usar
  las técnicas, con sonido existente, silencio y movimiento reducido.
- Auras al inspeccionar una unidad; información de Gas Reactivo, Calco y Alerta.
- Sexo persistente según proporciones originales de las151 especies, asignado
  por semilla/identidad en un flujo separado, sin consumir azar de combate.
- Mentas: nombre de atributos ↑/↓ y +10 %/−10 % antes de comprar y al elegir una
  de la bolsa; naturaleza neutra explícita y comparación numérica conservada.
- Partida nueva usa edición25 y código KT32. Ediciones12–24 se actualizan
  voluntariamente **entre encuentros**, con copia y diario mixto. Se conservan
  PS, dinero, niveles, movimientos preparados y conocimientos; se añaden los
  nuevos aprendizajes climáticos correspondientes. Un combate en curso conserva
  su motor. Los códigos y guardados anteriores siguen legibles.
- Las consultas y efectos visuales no consumen RNG ni generan órdenes. Se guarda
  la orden antes de mostrar su animación. No hay servidor ni consultas de red al jugar.

## Procedencia y comprobación

`tools/godot/build-climate.py` reutiliza datos PokéAPI ya cacheados; no descarga
recursos. `godot/data/climate-provenance.json` fija fuentes y SHA256. Adaptaciones
tácticas propias, sin nuevos sprites/audio externos. Los motores, datos, pruebas,
imágenes y recursos publicados permanecen intactos; la edición nueva añade módulos.

Comprobaciones:487 de reglas y112 de UI climática,270 de iconos y15 de sueño
por versión de desarrollo/EXE. Validación:0 errores,65 advertencias históricas,
0 nuevas; revisión estática sin incidencias.

Evidencias finales de reglas, UI en desarrollo/EXE, estado equivalente, validación,
capturas y hashes del paquete en `docs/qa/sprint-32/verification.json` y
`release.json`. Las pruebas incluyen un inicio natural hasta captura/tienda/menta,
fixtures de habilidades y clima, actualización de guardado y regresiones de sueño
e iconos. No equivalen a una campaña completa jugada ni a balance humano del clima.
Publicación pública aplazada; ejecutable local y subida al repositorio privado.
