# Posición y terreno dentro del gameplay

Público y dirección visual se conservan: fans de Pokémon y RPG tácticos, tablero superior, HUD de RPG con fichas en esquinas y órdenes en el centro. Objetivo de esta entrega: hacer legibles la orientación, el tránsito entre aliados y los riesgos del terreno.

- Cada unidad muestra una flecha cardinal; su ficha indica dirección y perfil de movimiento.
- Terminar turno abre Norte/Este/Sur/Oeste dentro del HUD. La flecha del actor previsualiza la elección. Confirmar cede el turno; Escape o Cancelar conserva el estado. El foco entra en la dirección actual y vuelve al tablero al cancelar o avanzar a un aliado.
- La previsión ofensiva indica Frente/Flanco/Espalda y precisión final. La precisión base aparece en la descripción del botón, sin sustituir el cálculo del objetivo.
- La cruz de un área se resalta en el tablero. La ficha del objetivo lista cada unidad afectada, daño, acierto y estados posibles; los aliados se señalan explícitamente. El listado tiene scroll nativo cuando crece.
- Un empuje resalta su destino y muestra el impedimento cuando hay borde, terreno incompatible, ocupación o una baja previa al empuje.
- Las ascuas tienen marca cálida en canvas y casilla HTML. La ficha y el cierre de turno avisan del daño; Fuego y voladores son inmunes a este terreno.
- El mapa Charca de Kanto conserva 8×8 y añade un paso de agua central, rutas terrestres y maleza. La leyenda distingue agua de obstáculos sólidos y recuerda que se atraviesan aliados.

Las órdenes permanecen fuera de las casillas. Se revisan orientación y previsiones activas con texto largo en escritorio, ventana de poca altura y móvil. Campamento y ensayo permanecen como prototipos secundarios; el ensayo conserva sus perfiles y ocupación originales.
