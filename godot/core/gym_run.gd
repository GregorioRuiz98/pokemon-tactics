extends "res://core/vitality_run.gd"

const GymStudy = preload("res://core/gym_study.gd")

func _init() -> void:
	super()
	progression = GymStudy.new()
	engine.progression = progression
	engine.catalog = progression.data
	for identity: int in engine.profiles: engine.profiles[identity].progression = progression

func gym_limit(run: Dictionary, after_victory: bool = false) -> Dictionary:
	var last: Dictionary = {"level":int(progression.data.levelCap),"leader":"","speciesId":0}
	for index: int in locations.size():
		var location: Dictionary = locations[index]
		if not location.get("leader",false): continue
		var insignia: Dictionary = ace({"stage":index})
		if insignia.is_empty(): continue
		last = {"level":mini(int(progression.data.levelCap),int(insignia.level)),"leader":location.name,"speciesId":int(insignia.speciesId)}
		if location.id not in run.cleared and not (after_victory and index==run.stage): return last
	# The demo ends at Brock: keep the last cap until another gym exists.
	return last

func level_cap(run: Dictionary) -> int:
	return int(gym_limit(run).level)

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if not run.is_empty():
		run.edition = 8
		progression.gym_cap = level_cap(run)
	return run

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("at",-1)!=input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	if not command.get("kind") is String: return fail("Orden de campaña no válida.")
	var limit: Dictionary = gym_limit(input)
	if command.kind=="level-up" and input.phase=="shop":
		var identity: Variant = command.get("member")
		if (identity is int or identity is float) and identity==int(identity):
			var selected: Dictionary = target(input,int(identity))
			if not selected.is_empty() and selected.hp>0 and selected.level>=limit.level:
				return fail("Límite de nivel %d: Pokémon insignia de %s. El Caramelo no se consume." % [limit.level,limit.leader])
	# EXP is awarded only on victory; a beaten leader unlocks the next gym then.
	progression.gym_cap = int(gym_limit(input,command.kind=="battle").level)
	var result: Dictionary = super.transact(input,command)
	progression.gym_cap = level_cap(result.state if result.ok else input)
	if result.ok and input.phase=="battle" and result.state.phase=="capture":
		var reward: Dictionary = result.state.reward
		if reward.level>progression.gym_cap:
			result.state.reward = progression.create_member(int(reward.id),int(reward.speciesId),reward.origin,int(progression.gym_cap))
	return result
