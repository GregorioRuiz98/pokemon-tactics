# Sprint 26 — inicio y textos para jugadores, 0.26.0

Entrega del 26 de octubre de 2026. Cambios de presentación en Godot 4.7.2, Windows offline. Campaña21 / combate19 conservados; no cambian repertorios, progresión, economía ni fórmulas. Los módulos de dominio, datos, pruebas publicadas y versión web permanecen intactos.

## Qué cambia

- **Nueva aventura → inicial → jugar.** Oak genera una semilla automáticamente. El campo manual, generar otra y copiar quedan en Opciones de partida. Escape cierra ese apartado y devuelve el foco. Refrescar no cambia la semilla.
- Las semillas manuales admiten hasta64 caracteres; los códigosKT25 conservan su formato y validación. El inicial y mapa del reto se explican antes de comenzar. Un código incompleto/incompatible o una semilla excesiva se rechazan antes de preservar o sustituir la campaña existente. Cancelar Oak recupera campaña, diario y azar anteriores.
- **Información compartida de movimientos** en Equipo, órdenes y MT: tipo, categoría, potencia base, precisión, coste, alcance, área y efectos secundarios. Los estados muestran potencia «—»; daño fijo, contraataques y técnicas variables tienen explicaciones propias. El básico indica que no tiene tipo ni STAB. La potencia agregada de técnicas múltiples sigue siendo la adaptación publicada.
- Las fichas explican la diferencia entre potencia base y daño previsto. La previsión sigue aplicando reglas reales. En combate, la lista muestra el resumen y la ficha de inspección permite consultar el detalle; en la tienda, Ver movimiento permite consultar sin comprar.
- Diagrama ilustrativo para movimientos espaciales, obtenido de la misma geometría del motor sobre suelo libre. U identifica al usuario y X las casillas afectadas. Es un ejemplo de forma: no sustituye la previsión del tablero con sus obstáculos, altura, ocupantes y orientación.
- Ayuda según la edición de la partida: EXP pendiente pagada y evolución gratuita adaptada para20+, caramelos y evolución histórica donde correspondan. Se explican los PT sin confundirlos con los PP originales.
- Se eliminan identificadores internos de las fichas principales, se traducen nombres de estadísticas en movimientos y se limpian textos de muestra/final/actualización. El laboratorio técnico queda accesible con el argumento de desarrollo `--developer`.
- Correcciones detectadas durante la revisión: foco diferido resuelto contra el panel vigente, filtro de coste con etiqueta legible y avisos de recompensa con altura acotada.

## Registro de textos principales

| Pantalla | Antes | Ahora |
|---|---|---|
| Título | Nueva partida | Nueva aventura |
| Oak | Semilla visible e instrucciones extensas | Elección del inicial y opciones de partida plegadas |
| Ayuda actual | Caramelo compra un nivel; evolución con piedra | Pago de EXP pendiente; evoluciones gratuitas adaptadas desde ficha |
| Movimientos | Nombre, PT y alcance | Tipo/categoría, potencia, precisión, coste, alcance, área y detalle |
| MT | Potencia solo en algunas descripciones | Misma ficha compartida y consulta sin comprar |
| PC e inspección | Identificadores técnicos | Nombre, origen, posición o número de lista según contexto |
| Finales/actualización | Referencias a sprints o ediciones técnicas | Resultado de la aventura y consecuencias comprensibles |

Las fichas reutilizan los efectos y descripciones de la edición abierta; no se ha reescrito manualmente todo el catálogo ni cambiado su comportamiento. Se conserva la distinción entre adaptaciones tácticas y efectos del cartucho.

## Comprobaciones

Resultados definitivos: [verificación](qa/sprint-26/verification.json) y [paquete](qa/sprint-26/release.json). Las pruebas usan campañas y preferencias aisladas; el ejecutor de desarrollo también aísla APPDATA/LOCALAPPDATA.

Comprobaciones ejecutadas en el proyecto y en el ejecutable final:

| Suite | Comprobaciones por destino | Resultado |
|---|---:|---|
| Inicio, textos y catálogo |719|Correcto;211 movimientos y Ruta1 natural hasta tienda |
| Ranuras y escalado de movimientos |304|Correcto;56 disposiciones |
| Movimientos espaciales |55|Correcto |
| Economía y tienda |57|Correcto |
| Aventura táctica |100|Correcto;incluye8 arenas preparadas |

Total: **1.235 comprobaciones de interfaz por destino**, además de105 comprobaciones de dominio de aventura. Los informes de fuente/EXE coinciden; en aventura se comparan estado y diario sin exigir tiempos idénticos. La partida y el diario naturales de la QA de aventura también conservan los hashes publicados en0.25.0. Validación:0 errores,65 advertencias históricas y0 nuevas. Linter:0 errores/advertencias. Comprobados también los hashes de recursos y el ZIP final.

La QA específica comprueba inicio normal,64 semillas distintas, refresco, cancelar, continuar, códigos válidos/inválidos, formato de los211 movimientos, geometría ilustrativa, efectos secundarios, consulta sin consumir recursos/azar, texto100/125/150 en1024×720 y1280×900 y una Ruta1 natural hasta captura y tienda con reconstrucción del guardado. Las regresiones comprueban ranuras, tienda, movimientos espaciales y aventura táctica.

Los casos preparados de gimnasios verifican interfaz y geometría; no representan victorias naturales. Este sprint no vuelve a equilibrar ni recorre completa la campaña21. El resultado anterior de2/6 muestras que superaban Brock sigue siendo una limitación de balance pendiente de juego humano.

## Pendiente

Sprint27: perfil local, historial y logros. Sprint28: tienda Kecleon y acabado visual. Sprint29: variedad táctica y repertorios. Este sprint no incorpora esos sistemas ni publica el juego en Internet. No se añaden recursos externos, dependencias o servicios.
