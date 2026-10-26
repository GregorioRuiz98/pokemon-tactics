# Textos de juego — 0.30.1

Revisión de presentación para la campaña actual: se elimina la explicación repetida de mecánicas conocidas de Pokémon y se conserva la información necesaria para decidir.

## Cambios

- Viaje: nombre y vista del destino, con una frase solo si hay un objetivo, recompensa o desafío que señalar. Se retiran los párrafos de explicación del escenario.
- Despliegue: casillas válidas y condición de victoria. Los objetivos alternativos siguen indicando cómo completarlos.
- Equipo y movimientos: capacidad, básico neutro, potencia, precisión, PT, alcance, área y efectos concretos. Se eliminan las definiciones genéricas de daño físico/especial y las explicaciones repetidas de STAB. Se conservan probabilidades, etapas, duraciones y particularidades tácticas; la duración de las zonas permanece visible al quitar una línea duplicada de área.
- Tienda y PC: mensajes de resultado más cortos. Entrenamiento, evolución y sorteo mantienen precio, saldo, restricciones y consecuencias permanentes. Se conservan compatibilidad de MT y datos de los objetos.
- Combate: indicaciones breves en reposo y al señalar casillas. Las fichas muestran los estados y etapas presentes, sin repetir una explicación global en cada unidad.
- Ayuda: controles resumidos con las teclas configuradas por el jugador. Las reglas propias de este juego quedan disponibles en «Reglas tácticas»: posición, rectificación, áreas aliadas, duración temporal, terreno, PS persistentes y fin de aventura.

Ejemplos: «Nuevo compañero en el equipo», «Intercambio completado», «Siguiente: Mew y Mewtwo», «Drena el 50 % del daño». Los errores, avisos de guardado y confirmaciones importantes se conservan.

## Compatibilidad

Misma campaña22/capítulo26 y combate19. No cambia mapas, repertorios, balance, precios, EXP, RNG, perfil ni guardados. No requiere una campaña nueva ni otra actualización del diario. Los textos históricos almacenados en datos se conservan; la interfaz actual elige el resumen. No se añaden recursos, dependencias ni servicios.

## Comprobaciones

- 503 comprobaciones de textos/interfaz en fuente y ejecutable: 211 fichas con datos numéricos, 58 destinos, reglas opcionales, teclado, texto al150%, apertura natural, captura, tienda, confirmaciones canceladas sin gastar y reconstrucción del guardado.
- 428 comprobaciones de regresión Kanto en cada versión: galería de116 mapas, apertura/captura/tienda/carga, ranuras, escalas de texto y efectos visuales. Estado y catálogo coinciden entre fuente y EXE.
- Lint sin incidencias; validación con cero errores y las65 advertencias históricas, sin nuevas. El empaquetador verifica que motores, datos, pruebas publicadas y recursos permanecen intactos respecto a0.30.0.
- Evidencia y huellas en `docs/qa/sprint-30-ui-1`. EXE Windows offline y ZIP comprobado. Publicación pública aplazada.

No se ha hecho una prueba humana de toda la campaña. La revisión visual cubre las pantallas de este cambio; no certifica una auditoría de todos los mensajes de ediciones antiguas.
