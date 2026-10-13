# Habilidades dentro del HUD

Público: fans de Pokémon y RPG tácticos. Objetivo: que tipos, roles y recursos cambien las decisiones del combate. Acción principal: seleccionar una habilidad, elegir su objetivo en el tablero y confirmar la previsión.

Se conserva el HUD solicitado para el sprint 2: tablero superior, ficha azul de actor, ficha del objetivo en la otra esquina y órdenes centrales. Bajo Mover/Acciones/Terminar aparecen tres botones: básico y dos habilidades, con nombre y coste. La descripción indica tipo, alcance y efecto; el actor muestra PT y estado.

Una habilidad de apoyo resalta aliados o al propio actor; una ofensiva resalta enemigos. Elegir una casilla genera una previsión con daño si acierta, precisión, categoría, efectividad, afinidad de tipo, PT y estado posible. Confirmar gasta acción y coste incluso si falla; cancelar conserva todo. Los estados tienen duración expresada en activaciones propias.

Opciones permite comparar dos equipos fijos: Iniciales y Control. El cambio se aplica al reiniciar. No se presenta como reclutamiento ni como inicio aleatorio de una run.

Los botones permanecen nativos, con foco visible y selección anunciada mediante `aria-pressed`. La cuadrícula conserva navegación por flechas y cancelación por Escape. En móvil las fichas y órdenes se apilan bajo el tablero; las previsiones largas deben caber sin desbordar ni tapar casillas. El espacio de la zona central reserva también el bloque de habilidades y la confirmación.

No se cambia la dirección visual, la perspectiva ni los sprites. Orientación final manual y paso a través de aliados permanecen pendientes para el sprint 4.
