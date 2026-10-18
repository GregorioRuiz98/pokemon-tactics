extends "res://core/traits_run.gd"

const ScaleBattle = preload("res://core/scale_battle.gd")

func _init() -> void:
	super()
	engine = ScaleBattle.new()
	progression = engine.progression

func create(campaign_seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(campaign_seed,starter)
	if not run.is_empty():
		run.edition = 11
		run.mapSize = 16
	return run

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("kind")=="map-size":
		if command.get("at",-1)!=input.revision or input.phase!="map" or not input.cleared.is_empty() or not input.battle.is_empty(): return fail("El tamaño se elige antes del primer encuentro.")
		if command.get("size")!=16 and command.get("size")!=24: return fail("Elige 16×16 o 24×24.")
		if command.get("size")==input.mapSize: return fail("Ese tamaño ya está seleccionado.")
		var run: Dictionary = input.duplicate(true)
		run.mapSize = int(command.get("size"))
		run.revision += 1
		return {"ok":true,"state":run}
	return super.transact(input,command)
