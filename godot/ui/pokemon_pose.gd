extends RefCounted

# Presentation anchors within the visible SpriteCollab frame. They never affect
# range, collision, number of hits, damage or animation/game RNG.
static func anchors(species_id: int, element: String) -> Array[Vector2]:
	if species_id==9 and element=="water": return [Vector2(.30,.28),Vector2(.70,.28)]
	if species_id in [1,2,3] and element=="grass": return [Vector2(.30,.52)]
	if species_id in [4,5,6] and element=="fire": return [Vector2(.60,.38)]
	if species_id in [7,8] and element=="water": return [Vector2(.60,.42)]
	if species_id in [25,26] and element=="electric": return [Vector2(.48,.40)]
	if species_id in [13,14,15] and element in ["bug","poison"]: return [Vector2(.68,.60)]
	return [Vector2(.50,.50)]
