# Colección e iniciales — 0.35.0

La Pokédex y los logros pasan a formar parte de la progresión entre aventuras.
Campaña 28/capítulo 32; conserva el combate 24 y los datos publicados.

## Reglas confirmadas

| Sistema | Comportamiento |
| --- | --- |
| Pokédex | 151 especies, búsqueda por nombre/número, páginas y filtros de obtenidos, vistos sin obtener y sin ver. |
| Obtener | Capturar, reclutar o evolucionar registra esa especie; el equipo y el PC cuentan. Ver un enemigo o una recompensa pendiente no basta. |
| Iniciales | Obtener cualquier forma desbloquea la primera de su línea, al nivel 5, sin equipo ni progresión heredada. Oak permanece disponible. Colección completa: 79 primeras formas. |
| Kecleon | Reclutamiento separado de las tres ofertas de MT/equipables. Tres candidatos sin repetir y una incorporación por lugar. Incluye las 146 especies no legendarias entre distintas semillas/visitas. |
| Precio/nivel | 200 + 10 × nivel. Nivel medio del equipo, mínimo 5 y hasta el límite de gimnasio. Formas evolucionadas desde su umbral; ofertas deterministas por semilla y lugar. |
| Aves | Tras vencer al trío, elige Articuno, Zapdos o Moltres. Solo uno, sin renovación de la recompensa. |
| Mew/Mewtwo | Después de su combate conjunto, elige uno; se conserva el cierre de campaña. |
| Equipo completo | El recluta va al PC. No sustituye miembros ni equipa objetos automáticamente. |
| Persistencia | Colección y logros pertenecen al perfil local y sobreviven al inicio de una aventura nueva. Los desbloqueos no se transfieren por pegar un código de reto. |

El reclutamiento de tienda amplía las vías de obtención; las tablas locales y las
recompensas de gimnasio se mantienen. Completar las elecciones legendarias exige
varias aventuras. No se ha reajustado daño, EXP de combate, costes de movimientos,
objetos existentes ni equipos rivales. La nueva oferta puede cambiar las
composiciones disponibles y requiere observación con jugadores.

## Logros

Se conservan los diez anteriores y se añaden nueve: nuevo compañero, empezar con
un inicial desbloqueado, reclutar un legendario, obtener 10/25/50/100/151 especies
y obtener los tres iniciales de Oak. Los avisos respetan la preferencia del perfil.
No conceden estadísticas ni recursos de combate.

## Compatibilidad

El perfil v1 se convierte a v2 conservando identidad, nombre, personalización,
historial, colección y logros anteriores. Sus especies registradas se consideran
obtenidas. Antes de sustituirlo se conserva `trainer-profile.json.before-v2`;
continúan la copia rotativa y la protección frente a conflicto, corrupción o
versión futura. Los números JSON se normalizan antes de comparar identificadores.

Los guardados anteriores conservan sus motores y pueden actualizarse entre
encuentros con copia. No se generan capturas retroactivas de jefes ya vencidos.
Los códigos KT35 admiten primeras formas; los anteriores siguen siendo legibles.
La inspección y las ofertas no consumen RNG. Las órdenes se guardan antes del
feedback; los eventos del diario permiten recuperar el perfil tras una interrupción.

## Implementación

Módulos nuevos `collection_*` en el núcleo y controles nativos en la interfaz.
Los archivos publicados de motores, datos, recursos y pruebas permanecen intactos.
Reutiliza los 151 retratos locales y las tablas de familias/evoluciones existentes;
sin dependencias, plugins, servicios ni descargas adicionales al jugar.

La Pokédex y el selector disponen de teclado, búsqueda, páginas y retorno de foco.
El perfil reduce su cabecera en Pokédex/Logros para aprovechar la ventana pequeña.
La selección legendaria muestra su recompensa y deja fija la confirmación inferior.

## Comprobaciones de esta entrega

Los registros definitivos se conservan en `docs/qa/sprint-35/`:

- Motor: 4.196 comprobaciones, incluidas las 151 familias/especies, 79 iniciales,
  oferta no legendaria completa entre semillas, coste, límite de compra, PC,
  victorias/elecciones de los cinco legendarios, migración y replay de guardados.
- Interfaz: apertura natural, captura, compra, reconstrucción del diario JSON,
  perfil, nuevo inicial y recarga; la pantalla legendaria usa un fixture explícito.
- Fuente y EXE: 34 comprobaciones de colección, 1.958 de previa, 46 de regresión
  y 69 de perfil por build; con el motor suman 8.410 comprobaciones.
- Regresión: previas de los 58 lugares y pruebas de equipo/biblioteca/PC grandes.
- Fuente y ejecutable Windows se comprueban por separado; el empaquetador compara
  sus resultados y los estados deterministas registrados.
- Lint y validación: sin errores ni avisos nuevos; se conservan 65 avisos previos.
- ZIP extraído en una carpeta limpia del mismo ordenador, perfil aislado y Godot
  fuera del PATH: arranque correcto y pantalla inicial visible. No es otro PC.

No se atribuye a esta entrega una nueva campaña completa humana, prueba en otro
ordenador ni lector de pantalla verificado. El recorrido automático completo de
0.34 sigue siendo evidencia histórica. [Reglas](REGLAS_ACTUALES.md) y
[prueba Windows](PLAYTEST_WINDOWS.md) describen la versión del jugador.

Publicación pública pendiente; entrega privada Windows, sin servidor.
