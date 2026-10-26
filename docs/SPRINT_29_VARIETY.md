# Sprint 29 — combinaciones y herramientas tácticas, 0.29.0

El catálogo actual ya contiene211 movimientos. La mejora facilita identificar sus funciones y preparar equipos diferentes: dos propuestas de rol con movimientos aprendidos, comparación antes de aceptar, filtros tácticos, herramientas del equipo y recomendaciones de MT en el mostrador de Kecleon.

## Implementación

- Dos propuestas por línea: prioridades específicas para15 familias, incluidas las de la apertura; para las restantes se combinan ofensiva y apoyo/control a partir de sus técnicas reales. No son clases con estadísticas extra ni una elección permanente.
- Cada propuesta usa hasta cuatro movimientos conocidos, sin duplicados; el básico neutro se conserva. Se penalizan alternativas con la misma función y se excluyen autodestrucciones de las propuestas automáticas. El jugador puede seguir preparando manualmente cualquier movimiento legal.
- Se muestran selección actual y propuesta antes de aceptar. Una única orden `loadout`, ya soportada por los guardados, aplica la combinación gratis. Cancelar, inspeccionar o filtrar no cambia recursos ni azar; la revisión queda vinculada a su revisión de campaña.
- Filtros: áreas, zonas, empujar/atraer/acercarse, estados/atributos y curar/proteger/disipar. Las etiquetas proceden de las definiciones del motor abierto; las fichas y previsiones siguen siendo la autoridad sobre alcance, aliados e inmunidades.
- Herramientas del equipo: informe opcional de funciones preparadas por compañero en pie y funciones no cubiertas. No obliga a cubrirlas todas.
- Próximas técnicas: tres aprendizajes ordenados de la forma actual, con nivel y aviso cuando superan el límite del gimnasio. Las evoluciones pueden cambiar esa secuencia.
- MT en tienda: compatibilidad y aportación respecto a los movimientos preparados de cada compañero; no compra ni enseña automáticamente.

No se añaden ataques, estadísticas, bonificaciones de rol ni cambios de aprendizaje. Se conserva LGPE combinado sin técnicas especiales de los iniciales. La mejora utiliza órdenes ya existentes: campaña21/combate19, códigosKT25 y guardados anteriores conservados; no necesita una edición nueva.

## Auditoría para revisión

[Catálogo completo,211 filas](qa/sprint-29/variety-moves.csv) · [Opciones de la apertura al nivel14](qa/sprint-29/variety-opening.csv). Son consultas reproducibles del contenido local instalado; no requieren Internet ni un importador nuevo.

| Función | Movimientos con esa propiedad |
|---|---:|
| Área |78|
| Zona temporal |11|
| Empuje |21|
| Atracción |1|
| Acercamiento |17|
| Disipar |2|
| Curación o drenaje |9|
| Estados o atributos |84|
| Crítico mejorado |5|

Las categorías se solapan. Los CSV también incluyen tipo, categoría, potencia, precisión, PT, alcance, forma y familias que aprenden cada movimiento por nivel; no representan toda la compatibilidad por MT.

La apertura muestra limitaciones reales: Charmander y Squirtle solo disponen de cuatro técnicas por nivel antes del límite de Brock, por lo que sus dos propuestas comparten movimientos. La interfaz lo explica. Bulbasaur, Pidgey, Rattata, Oddish, Butterfree y algunas otras trayectorias ya permiten selecciones distintas. Capturar directamente una forma evolucionada puede dar opciones diferentes de entrenarla desde su preevolución, porque conserva técnicas ya aprendidas. No se regalan movimientos para ocultar esa diferencia.

## Comprobaciones

- Núcleo/consultas:7428 comprobaciones, clasificación de211 movimientos y1208 propuestas sobre151 especies en niveles5/14/30/60. Validación de aprendidos, cuatro ranuras, determinismo, no autodestrucción automática, aprendizaje futuro concreto, cap y transacción/diario/replay sin cambiar reglas.
- Interfaz específica:72 comprobaciones en fuente y ejecutable. Comparar/cancelar/confirmar, callback con revisión caducada, teclado, filtros y recuentos, informe del equipo, escalas100/125/150 en1024×720/1280×900; Ruta1 natural, captura, recomendación de MT y recarga.
- Regresiones en ambas compilaciones:719 de inicio/textos,304 de ranuras,70 del mostrador,69 de perfil. Dominio anterior:120 de perfil y105 de aventura.
- Análisis de scripts:0 errores,65 advertencias históricas y ninguna nueva; linter sin incidencias. Recursos y ZIP verificados, estado/diario de fuente y EXE comparados. Evidencia en `docs/qa/sprint-29/`.

## Alcance y entrega

Se aprovecha y hace configurable la variedad existente; no se ha realizado un rebalanceo ni una campaña completa nueva. La limitación publicada de2/6 muestras automatizadas superando Brock no se sustituye por estas pruebas de interfaz. Diversión, dificultad y experiencia con un lector de pantalla requieren pruebas humanas.

Ejecutable y ZIP Windows offline0.29.0, código subido al repositorio privado en la rama de trabajo. El perfil es local y no concede ventajas entre campañas. Publicación pública aplazada por decisión del usuario. Con esta entrega quedan implementados los sprints26–29 del encargo.
