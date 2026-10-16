extends "res://core/letsgo_run.gd"

const TacticalBattle = preload("res://core/tactics_battle.gd")

func _init() -> void:
	super()
	engine = TacticalBattle.new()
	progression = engine.progression

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if not run.is_empty(): run.edition = 6
	return run
