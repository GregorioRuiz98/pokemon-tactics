extends "res://core/tactics_run.gd"

const Vitality = preload("res://core/vitality_study.gd")

func _init() -> void:
	super()
	progression = Vitality.new()
	engine.progression = progression
	engine.catalog = progression.data
	for identity: int in engine.profiles: engine.profiles[identity].progression = progression

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if not run.is_empty(): run.edition = 7
	return run
