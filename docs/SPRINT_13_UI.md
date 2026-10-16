# Revisión del HUD nativo — 0.13.1

16 de octubre de 2026. Rama codex/sprint-13-ui. El usuario pidió integrar la interfaz en el juego y reducir clics. Esta revisión del laboratorio no inicia el sprint 14.

## Resultado

Tablero despejado, cola compacta encima y una única franja de combate debajo con retrato, PS/PT, habilidades, orientación y previsión. Equipo/registro extensos, nuevo ensayo, continuar, ayuda, ajustes y créditos se consultan desde Menú/F1. Ningún control cubre casillas.

Las casillas alcanzables aparecen sin pulsar Mover. Pasar el cursor dibuja trayectoria/coste o área, daño y precisión, incluida la pérdida prevista sobre las barras de PS. El básico está elegido por defecto. Un clic ejecuta movimiento o básico; una habilidad requiere elegirla y señalar objetivo. Las habilidades propias se ejecutan al pulsarlas.

Las flechas inferiores terminan el turno orientando con un clic; F permite elegir dirección en el tablero. Después de gastar movimiento y acción se ofrece esa elección automáticamente. Escape/clic derecho cancelan la selección. Solo los ataques que pueden dañar o aplicar estados a aliados necesitan confirmación: conservan la previsión, bloquean otras órdenes y muestran el aviso primero. El menú y los diálogos bloquean órdenes y pausan la IA.

| Orden | Flujo anterior | Flujo nuevo |
| --- | --- | --- |
| Mover | Mover → casilla → confirmar | Casilla |
| Básico | Elegir básico → enemigo → confirmar | Enemigo |
| Habilidad dirigida | Habilidad → objetivo → confirmar | Habilidad → objetivo |
| Habilidad propia | Habilidad → confirmar | Habilidad |
| Terminar orientando | Orientar → dirección → confirmar; dos pulsaciones si se acepta la dirección inicial | Flecha de dirección |

Un ataque con riesgo aliado añade una confirmación al flujo nuevo. La medición de las cuatro batallas reproduce 73 órdenes aliadas: **89 pulsaciones frente a 205 calculadas para el flujo anterior, 56,6 % menos**. El cálculo considera las habilidades propias y la orientación inicial que ya ahorraban una pulsación. Excluye hover, menús, cancelaciones y comprobaciones adicionales; no mide tiempo ni diversión de jugadores humanos.

## Comprobaciones ejecutadas

- Proyecto Godot 4.7.2 importado y ejecutado; aplicación nativa 0.13.1 exportada con plantillas locales, sin dependencias nuevas.
- Paridad: 16 combates completos, 506 órdenes idénticas y 25 escenarios sin fallos; integridad de 41 recursos y 13 fuentes de referencia verificada.
- UI desde fuente y ejecutable: cuatro batallas completas y 685 aserciones en cada ejecución. Mismos resultados: actuales/iniciales victoria ronda 6, actuales/mixto derrota ronda 3, clásico/iniciales victoria ronda 1, clásico/mixto derrota ronda 2.
- Previsiones sin consumo de estado/RNG; selección, cancelación, bloqueo y aceptación de fuego aliado; su resultado y guardado coinciden con la regla compartida.
- Ratón mediante eventos locales del tablero y señales de controles; además un clic real enviado al viewport verifica hit testing y movimiento directo. Flechas/F1 reales, foco, orientación desde tablero y bloqueo con diálogo comprobados.
- Guardado/carga y escritura aislada en user://; pruebas no usan la partida normal. El ejecutable se prueba desde su distribución con GODOT_BIN apuntando a un editor inexistente.
- Renderizado revisado en 1024×720, 1280×900 y 1440×1000. Recorrido de límites de controles y previsión extensa en ventana mínima; créditos comprobados.
- Diff, sintaxis de run.mjs, ZIP y hash del ejecutable comprobados. No se repite la suite web porque src/, public/, dependencias y sus herramientas no cambian.

Evidencia: [fuente](qa/sprint-13-ui/ui-source-result.json), [ejecutable](qa/sprint-13-ui/ui-release-result.json), [paridad](qa/sprint-13-ui/parity-result.json), [paquete](qa/sprint-13-ui/release-info.json), [ataque](qa/sprint-13-ui/native-attack.png), [riesgo aliado](qa/sprint-13-ui/native-friendly-fire.png), [ventana mínima](qa/sprint-13-ui/native-small.png).

## Compatibilidad y entrega

Aplicación 0.13.1; reglas/diario nativo conservan esquema 1 y versión contractual 0.13.0. No cambian core/, datos, PRNG, balance ni recursos importados; no se regeneran referencias. Partidas nativas anteriores siguen admitidas. Web 0.12.0 conservada.

Ejecutable en ../releases/pokemon-tactics-0.13.1/windows respecto al repositorio; ZIP junto a esa carpeta. Licencias, créditos, instrucciones y SHA256 acompañan al binario. Código destinado a la rama privada codex/sprint-13-ui; no se publica la web ni se cambia la rama predeterminada.

Se reutilizan los recursos y controles del proyecto. Se aplica la skill make-interfaces-feel-better a jerarquía, estados, foco y áreas de interacción; no introduce bibliotecas.

Sigue siendo un laboratorio 8×8 de seis especies. Campaña, mapas grandes, elección de Oak, capturas/tienda y progresión quedan para las entregas previstas. Walk, pruebas humanas, audio percibido y otros equipos/GPUs siguen pendientes.
