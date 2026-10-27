extends "res://ui/kanto_board.gd"

const Climate = preload("res://core/climate_context.gd")
const AURA_COLORS: Dictionary = {"neutralizing-gas":"ce99ec","cloud-nine":"edf2e8","illuminate":"ffe292","magnet-pull":"8ed3ed","arena-trap":"ebc283","pressure":"fa9e9e"}

func _draw() -> void:
	super._draw()
	if state.get("combatEdition",0)<22: return
	var selected: Dictionary = {}
	for unit: Dictionary in state.units:
		if unit.hp>0 and int(unit.x)==cursor.x and int(unit.y)==cursor.y: selected = unit; break
	if selected.is_empty(): return
	var identity: String = Climate.ability(state,selected)
	if not Climate.AURAS.has(identity): return
	var radius: int = Climate.AURAS[identity]
	var color: Color = Color(AURA_COLORS[identity])
	for y: int in range(maxi(0,selected.y-radius),mini(state.board.size(),selected.y+radius+1)):
		for x: int in range(maxi(0,selected.x-radius),mini(state.board[0].size(),selected.x+radius+1)):
			var point: Dictionary = {"x":x,"y":y}
			if Climate.near(state,selected,point,radius) and play_area().has_point(center(point)): _outline(diamond(point),Color(color,.8),2)
	_tag(center(selected)+Vector2(0,-80*zoom),selected.abilityName+" · %d"%radius,color,12)
