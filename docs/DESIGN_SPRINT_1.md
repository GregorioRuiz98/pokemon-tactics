# Tablero de ensayo — contrato de interfaz

Superficie: tablero táctico 8×8. Acción principal: seleccionar una unidad, previsualizar un destino y confirmar o cancelar su movimiento. Se conserva el campamento del sprint 0 mediante un enlace.

Referencia local: paleta de bosque, selección ámbar, ficha marfil y sprites direccionales del campamento. El tablero ocupa el centro de la primera pantalla; ficha y confirmación permanecen a su derecha. El detalle distintivo es la trayectoria numerada con coste acumulado: el jugador puede comprobar el gasto antes de comprometerse.

Seis unidades fijas de ensayo, todas con perfil terrestre provisional. Suelo cuesta 1, maleza 2 y las rocas/agua bloquean. Presupuesto visible por unidad, acumulativo hasta reiniciar el ensayo. No representa rondas ni reglas de combate.

Objetivos: 1440×1000 y 390×844. Tablero cuadrado escalable; en pantalla estrecha, ficha y controles debajo. Selección y destinos accesibles mediante cuadrícula HTML superpuesta al canvas; flechas mueven foco, Enter/Espacio seleccionan y Escape cancela. El movimiento reducido omite los desplazamientos animados. Pausa disponible para las animaciones.

Estados verificables:
- Carga: tablero estable, progreso de recursos, interacción deshabilitada hasta estar listo.
- Catálogo vacío/error: mensaje y botón de recarga.
- Recurso gráfico parcial: aviso, marcador de sustitución y recarga; movimiento sigue disponible.
- Destino inválido: razón visible (obstáculo, sin camino, presupuesto); no cambia posiciones ni gasto.
- Trayectoria pendiente: pasos/coste visibles, botones confirmar/cancelar.
- Movimiento: bloqueo de órdenes hasta completar; posición, orientación y presupuesto coherentes al terminar.
- Éxito: confirmación y presupuesto restante; reinicio restablece el ensayo.
- Permisos: no aplicable; no se requieren cuentas ni permisos del dispositivo.
