# Calidad táctica en todo Kanto — 0.34.0

El encargo se amplió expresamente a la campaña completa: Oak, ocho gimnasios, Liga y rival, tres aves y Mew/Mewtwo. Esta revisión aplica la pasada de escenarios y preparación a las 58 localizaciones; no se detiene en Brock.

## Escenarios, objetivos y presentación

- Ruta1, Ruta2, Bosque Verde y Brock tienen una nueva distribución central de senderos, claros, terrazas y accesos, conservando su ambientación.
- Los otros54 lugares conservan su geometría reconocible y reciben plataformas con alturas de1/2 y obstáculos de su entorno: árboles, rocas, servidores, tumbas, columnas o cristales. Una comprobación de conectividad descarta cambios que corten un acceso previamente disponible a unidades, despliegue, portales u objetivos.
- Monte Moon, Guarida Rocket, Silph/Giovanni, Mansión Pokémon y Central permiten controlar dos mecanismos accesibles como alternativa a derrotar al rival. Se conservan los objetivos especiales anteriores, incluido Fuji. Cada objetivo se anuncia durante la preparación y sus casillas se señalan en el tablero.
- Los ocho líderes, Alto Mando, campeón y legendarios tienen planes de equipo asociados a su identidad: formación, movilidad, concentración de ataques, control, flanqueo o distancia. Esto orienta la IA; no impone roles a los Pokémon del jugador.
- Los58 encuentros muestran contexto breve de un personaje/lugar y el objetivo junto al equipo rival. El detalle de terreno se conserva en la ayuda de la cabecera. Los retratos y recursos proceden de los catálogos locales ya acreditados.

El inventario de escenarios y objetivos está en [MAPAS_0.34.csv](MAPAS_0.34.csv). Las propuestas anteriores de nuevos ataques ambientales o ataques de jefe con compromiso de turno no se presentan como implementadas: esta entrega utiliza las técnicas, áreas, habilidades y geometría existentes.

## Decisiones rivales y lectura táctica

Los entrenadores valoran mejor un objetivo debilitado o ya afectado por un compañero, consideran los flancos y conservan cercanía con su formación. Los apoyos buscan compañeros heridos al reposicionarse. Las preferencias de movilidad/distancia y exposición tienen en cuenta la posición candidata. Los Pokémon salvajes conservan un comportamiento más directo.

La memoria por ronda conserva el mínimo de PS alcanzado por cada unidad y mide el progreso de cada bando. Después de tres rondas sin un nuevo mínimo de PS en su propio bando, la IA deja de puntuar la recuperación que mantiene el estancamiento e intenta otra decisión. Cambiar de casilla o hacer daño al otro bando no oculta ese ciclo. Una pérdida nueva de PS propios permite volver a valorar la curación. No prohíbe curar al jugador ni añade un contador de usos, costes por ataque, límite de turnos o derrota oculta.

Durante un turno aliado, al consultar una casilla de movimiento se indican los rivales con alcance potencial, incluyendo su desplazamiento. La consulta se reparte entre fotogramas, se invalida con cada revisión y no consume azar. Es cobertura geométrica: puede cambiar con el estado, la ocupación y la visión; no es una orden enemiga comprometida ni garantiza daño.

## Ritmo y partidas largas

Opciones ofrece velocidad1×,1,5× y2× para animaciones de ataque y pausa entre órdenes enemigas. La duración de lectura de resultados conserva su ajuste independiente. Se mantienen movimiento reducido, alto contraste, teclado y los sonidos originales existentes.

La carga de campañas26/27 puede aprovechar un certificado local de una validación real. La primera lectura sin certificado reconstruye el diario por bloques y cede fotogramas para mostrar progreso. El certificado liga los bytes exactos del guardado al estado canónico binario, con una firma local; conserva los números y el RNG. Si faltan certificado/clave o cambian los bytes, se reconstruye todo el historial.

Cada guardado nuevo certifica solo una continuación comprobada del estado anterior. Se conserva el diario entero, la escritura temporal, la copia previa y la detección de otra instancia. Copiar únicamente el archivo de partida a otro equipo funciona mediante validación completa; los archivos auxiliares son opcionales. No son una cuenta, un servicio ni una garantía contra modificaciones deliberadas del propio equipo.

Los resultados medidos de la partida histórica de7.838 órdenes —tiempo inicial, carga certificada y fotogramas de respuesta— se guardan en `docs/qa/sprint-34/quality-source.json` y `quality-release.json`. La inicialización de reglas antiguas puede añadir tiempo al primer acceso de esa revisión.

## Compatibilidad y verificación

Campaña27/capítulo31/combate24 en módulos nuevos. Actualización voluntaria entre encuentros con copia; un combate anterior conserva sus reglas. Nuevos retos KT34, con decodificación de los anteriores. Se conservan datos publicados, estadísticas, potencias, EXP, precios, capturas y premios numéricos. Los mapas y las decisiones de IA sí pueden cambiar la dificultad.

- Pruebas de lógica: 116 escenarios (58×2 tamaños), accesos, objetivos/manantiales, cifras y repertorios frente a0.33, consultas puras, actualización, retos, guardados certificados y alteraciones.
- Pruebas nativas de las58 preparaciones y los ocho gimnasios, menús/PC grandes, consulta rival, teclado, texto150%, opciones y carga histórica. Se ejecutan sobre fuente y EXE; cantidades finales en `verification.json`.
- Recorridos automáticos mediante órdenes legales, con sus capturas, compras y bajas reales. El primer jugador automático pierde en Koga; se conserva la evidencia. Las mejoras de su preparación pertenecen al banco de pruebas y no añaden recursos a la aventura.

La entrega incluye una guía de pruebas humanas. Ningún ensayo automático equivale a que una persona haya completado el juego, ni acredita otro ordenador. La publicación pública sigue aplazada.

## Recorrido completado

La reproducción final termina en `ending` con58 lugares, ocho medallas y7.861 órdenes legales. Las aves requieren15 rondas y Mew/Mewtwo8. Se reconstruye también el guardado final. Se reutiliza el prefijo legal de los intentos anteriores y se cambia la preparación/decisiones del jugador automático; no se inyectan recursos, unidades, niveles ni victorias. El primer intento cae en Koga y otro detecta el ciclo de Respiro de las aves, que motivó corregir la memoria de IA.

Los tiempos de carga certificados miden la lectura con reglas ya preparadas en el proceso. No son el tiempo de arranque completo del programa; inicializar una revisión histórica puede añadir demora. La primera comprobación completa sigue siendo considerablemente más lenta y muestra progreso. Las cifras de fuente y EXE se conservan por separado en la evidencia.

La semilla verificada es `release-33-kanto`, con Bulbasaur. Safari conserva su parada narrativa; el recorrido tiene57 combates y58 lugares. No se acredita una victoria con todos los iniciales o semillas.
