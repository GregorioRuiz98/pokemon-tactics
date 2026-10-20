# Prueba exploratoria ·30–45 minutos

Estado: preparada, sin participantes reclutados ni sesiones realizadas. Objetivo: 6–8 voluntarios con experiencia variada de Pokémon y tácticos; incluir uso habitual de teclado y necesidades de acceso si desean participar. No registrar diagnósticos. No es una muestra para estimar tasas poblacionales ni cerrar el balance.

## Consentimiento y preparación ·5 minutos

Explicar: se prueba el juego, no a la persona. Puede pausar, omitir cualquier pregunta y retirarse sin justificarlo. Pedir consentimiento separado para notas y para grabación; por defecto solo notas anónimas. Identificador P01…P08, nunca nombre real/correo. Acordar borrar las notas si lo solicita; fijar conservación máxima de30 días para el análisis y conservar después únicamente resultados agregados. No enviar datos a servicios remotos.

Entregar una copia de la versión y perfil QA aislado. Registrar versión/commit, fecha, semilla, inicial, tamaño16/24, teclado/ratón/mixto, ajustes y lector/versión si lo usa. Dejar configurar texto, contraste, sonido y teclas. Windows/DPI reales se anotan; no asumirlos por tamaño de ventana.

## Abrir perfiles de prueba

En el ZIP: ejecutar `./ABRIR_BETA.ps1` desde PRUEBAS_HUMANAS abre una aventura con un perfil nuevo aislado. `./ABRIR_BETA.ps1 -Fixture -GodotPath RUTA_AL_GODOT_4_7_2 -ProjectPath CARPETA_GODOT_DEL_FUENTE` abre tienda/PC/biblioteca sintéticos, solo en memoria, para tareas6–8: seis miembros, dos heridos, duplicados en PC y2000 ₽. Este escenario avanzado requiere el motor de desarrollo y el proyecto fuente: las plantillas release oficiales bloquean `--script` (opciones de sobrescritura de ruta). El juego normal del ZIP funciona sin editor. El creador prepara esta sesión para los participantes; no hace falta instalar nada para jugar la campaña. Se identifica en pantalla; cerrar descarta los cambios y no permite comprobar replay. Para tarea9 usar la aventura normal: cerrar y reabrir con `./ABRIR_BETA.ps1 -Session session-…`, copiando el nombre completo del perfil que muestra la consola. No ejecutar la tarea9 en el fixture. El script no cambia la política de ejecución de Windows; si está bloqueado, puede revisarse y abrir el ejecutable desde una consola con esas variables.

## Tareas ·20–25 minutos

Leer solo el objetivo, sin señalar el botón. Permitir60–90 segundos antes de ofrecer una pista si la persona la solicita; registrar tipo de ayuda y punto de atasco. Parar si hay fatiga.

1. Empieza una aventura y encuentra qué hacer a continuación.
2. Desplaza a tu Pokémon y devuelve ese desplazamiento sin perder una acción.
3. Compara una habilidad con otra y abandona la selección sin ejecutarla.
4. Ataca y termina orientado hacia una amenaza.
5. Encuentra cuánto durará un estado o un cambio de atributo.
6. En un equipo preparado, deja cuatro movimientos elegidos y comprueba qué hace el básico.
7. En tienda, compra y usa cinco Caramelos (objetivo bajo el cap), y cura a dos miembros heridos. Anota compras/uso separados y desperdicio.
8. En PC, cambia un miembro por otro de la misma especie verificando su identidad y PS.
9. Sal, continúa y explica dónde estás, cuánto dinero tienes y cuál es la próxima decisión.

Las tareas6–8 pueden usar copias sintéticas etiquetadas de QA. No presentarlas como progresión natural ni exigir horas de juego. Nunca usar ni sobreescribir una partida personal. Para lector: primero validar el corte Inicio→Oak→práctica, consultar casilla/ocupante/estado/previsión, cancelar, actuar, orientar, volver y leer una oferta de tienda. Si el lector no transmite un campo, registrar bloqueo; no guiar visualmente y marcar aprobado.

## Comprensión y cierre ·5–10 minutos

Pedir con palabras propias: diferencia entre PS y PT; básico y STAB; frente/costado/espalda; aprendido/preparado; qué rectifica R; cuándo caducan estados; qué ocurre al alcanzar el cap; qué conserva el PC. Preguntar qué decisión táctica resultó interesante y cuál confusa, sin sugerir que debería gustarle.

Medir por tarea: éxito sin/con ayuda, tiempo, interacciones, órdenes no deseadas, foco perdido, cancelaciones, errores, ayuda y explicación correcta/parcial/incorrecta. Registrar comentarios literales solo con permiso. La meta de reducir50% operaciones exige repetir la misma tarea en0.22.3 y0.22.10, con orden contrabalanceado; no es un resultado logrado por implementar cantidad.

## Experimentos separados

- Iniciales: mismas semillas, repartir Bulbasaur/Charmander/Squirtle y contrabalancear orden. Registrar elecciones de alcance/movimientos/curación, derrotas y explicaciones. Los anteriores resultados del bot4/8 frente0/8 motivan investigar, no miden probabilidad humana.
- Escala16/24: misma semilla e inicial, documentar divergencias reales de mapa/recorrido. Medir duración, rondas sin contacto, movimientos sin decisión, alturas usadas, rutas alternativas y claridad. No atribuir toda diferencia al tamaño.
- Hipótesis futura: dos aproximaciones legibles aumentan decisiones útiles sin aumentar travesías. Proponer después un mapa aislado con límites públicos y contrastar las métricas anteriores. No añadir ahora defender/rescatar/huir ni modificar daño.
- Identidad: pedir por qué eligió cada línea y cómo contrarrestaría su movilidad/alcance/apoyo. Separar falta de información de potencia excesiva. No inventar roles o atributos ocultos.

## Criterio de salida

Bloqueantes: pérdida de guardado, orden involuntaria reproducible, salida inaccesible, campo imprescindible no disponible para el método probado. Una tarea fallida genera defecto con pasos/version/evidencia/aceptación. Priorizar por impacto y riesgo, no por media de satisfacción. Diversión y balance siguen abiertos hasta observar personas.
