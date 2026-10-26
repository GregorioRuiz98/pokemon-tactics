extends RefCounted

static func glossary(edition: int) -> String:
	if edition>=21: return preload("res://ui/concise_copy.gd").tactical_rules(edition)
	var text: String = "TU TURNO\nUn movimiento y una acción, en cualquier orden. Puedes atravesar aliados, pero no terminar sobre ellos.\n\nRectificar devuelve solo el movimiento, mientras no hayas actuado ni terminado el turno. No recupera PS ni recursos.\n\nPT son puntos tácticos: el recurso de tus movimientos. No son dinero ni los PP de los juegos originales. El básico cuesta 0 PT, no tiene tipo ni STAB. Puedes preparar otros cuatro movimientos fuera de combate.\n\nPOTENCIA Y DAÑO\nLa potencia es la fuerza base del movimiento. La previsión muestra el daño en PS contra el objetivo, aplicando estadísticas, tipos, STAB y efectos."
	if edition>=6:
		text += "\n\nDe frente se usa la mitad baja del daño normal; de costado, la alta; por la espalda, el máximo y una etapa crítica adicional. El lado no modifica la precisión.\n\nEstados y cambios de estadísticas caducan por activaciones del afectado. La parálisis reduce a la mitad el desplazamiento."
	else:
		text += "\n\nEsta aventura conserva sus reglas clásicas de orientación, estados y precisión. Consulta la previsión de cada acción."
	text += "\n\nENTRE COMBATES\nLos PS se conservan. Los objetos curativos se usan fuera de combate."
	if edition>=9: text += " Revivir se usa en la tienda y recupera la mitad de los PS máximos."
	if edition>=20:
		text += "\nGanas EXP al vencer. En la tienda puedes pagar por la EXP que falta para completar un nivel. Las evoluciones por nivel son automáticas; las adaptadas de piedra o intercambio se eligen gratis en la ficha al alcanzar su nivel mínimo. No se usan caramelos, piedras ni cables."
	elif edition>=4:
		text += "\nUn Caramelo Raro compra un nivel. Las evoluciones por nivel son automáticas; las otras requieren el objeto indicado en la ficha."
	elif edition>=2:
		text += "\nLa EXP aumenta el nivel. Evolucionar requiere el nivel indicado y un Caramelo Raro; el caramelo no sube niveles."
	else:
		text += "\nUn Caramelo Raro evoluciona una etapa sin requisito de nivel. El entrenamiento mejora una estadística hasta dos veces por Pokémon."
	if edition>=8: text += "\nEl próximo gimnasio fija el nivel máximo. Al alcanzarlo no se acumula EXP adicional."
	if edition>=12: text += "\nEl PC no cura. Perder un combate termina la aventura aunque queden Pokémon en la reserva."
	text += "\nAprender un movimiento no lo prepara automáticamente: revísalo en Equipo → Movimientos.\n\nLa previsión al apuntar muestra el resultado posible y los riesgos para aliados."
	if edition>=22: text += "\n\nKANTO\nÁrboles, rocas, muebles y lápidas sólidos bloquean movimiento y visión. La maleza se atraviesa con el coste de tu perfil. Una diferencia de altura de un nivel se puede recorrer; más de uno requiere rodear o volar. Las copas se atenúan para mostrar unidades y cursor.\n\nDespués de la Liga y el rival llegan dos combates seguidos: las tres aves legendarias, tienda de preparación y Mew con Mewtwo. Ningún legendario es reclutable."
	return text
