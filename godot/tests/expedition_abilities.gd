extends SceneTree

const Run = preload("res://core/journey_run.gd")
const Save = preload("res://core/journey_store.gd")
var game: RefCounted
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void:
	call_deferred("run_tests")

func arena(move: String, source: String = "overgrow", protection: String = "water-absorb") -> Dictionary:
	var state: Dictionary = game.engine.encounter(game.create("abilities",1),game.locations[0])
	var actor: Dictionary = game.engine.member_unit(game.progression.create_member(1,1,"Fixture",30),{"x":5,"y":8})
	var target: Dictionary = game.engine.member_unit(game.progression.create_member(10000,134,"Fixture",30),{"x":6,"y":8})
	actor.moves = [move]
	actor.tp = 5
	actor.ability = source
	actor.abilityName = source
	target.ability = protection
	target.abilityName = protection
	target.team = "enemy"
	target.facing = 2
	state.units = [actor,target]
	state.queue = [1,10000]
	state.completed = []
	state.moved = false
	state.acted = false
	for row: Array in state.board: row.fill(0)
	for row: Array in state.heights: row.fill(0)
	return state

func run_tests() -> void:
	game = Run.new(17)
	var state: Dictionary = arena("water-gun")
	state.units[1].hp -= 20
	var before: Dictionary = state.duplicate(true)
	var preview: Dictionary = game.engine.attack_plan(state,10000,{},"water-gun")
	check(preview.ok and preview.hits[0].damageMax==0,"Water Absorb forecast")
	check(Save.equivalent(state,before),"Ability preview does not mutate or roll")
	var result: Dictionary = game.engine.attack(state,10000,"water-gun")
	check(result.ok and result.state.units[1].hp==result.state.units[1].maxHp and state.units[1].hp<state.units[1].maxHp,"Absorb heals target without mutating source")
	state = arena("earthquake","overgrow","levitate")
	preview = game.engine.attack_plan(state,10000,{},"earthquake")
	check(preview.ok and preview.hits[0].damageMax==0,"Levitate blocks Ground")
	state.units[0].ability = "mold-breaker"
	preview = game.engine.attack_plan(state,10000,{},"earthquake")
	check(preview.ok and preview.hits[0].damageMax>0,"Mold Breaker bypasses Levitate in forecast")
	state = arena("slash","overgrow","shell-armor")
	preview = game.engine.attack_plan(state,10000,{},"slash")
	check(preview.ok and preview.hits[0].criticalChance==0,"Armor blocks guaranteed critical")
	result = game.engine.attack(state,10000,"slash")
	check(result.ok and not result.hits[0].critical,"Armor blocks critical in resolution")
	state = arena("thunder-wave","overgrow","limber")
	check(not game.engine.attack_plan(state,10000,{},"thunder-wave").ok,"Limber rejects paralyzing support")
	state = arena("growl","overgrow","clear-body")
	check(not game.engine.attack_plan(state,10000,{},"growl").ok,"Clear Body rejects lowering support")
	state = arena("fissure","no-guard","torrent")
	preview = game.engine.attack_plan(state,10000,{},"fissure")
	check(preview.ok and preview.hits[0].accuracy==100,"No Guard removes original miss chance")
	state = arena("rest","overgrow","torrent")
	state.units[0].hp -= 25
	result = game.engine.attack(state,1,"rest")
	check(result.ok and result.state.units[0].hp==result.state.units[0].maxHp and result.state.units[0].status.kind=="sleep","Rest heals and sleeps")
	state.units[0].ability = "insomnia"
	check(not game.engine.attack_plan(state,1,{},"rest").ok,"Insomnia prevents Rest")
	state = arena("transform","overgrow","torrent")
	var original_hp: int = state.units[0].hp
	result = game.engine.attack(state,10000,"transform")
	check(result.ok and result.state.units[0].speciesId==134 and result.state.units[0].hp==original_hp and result.state.units[0].id==1,"Transformation copies form while preserving HP and identity: "+str(result.get("reason",result.get("state",{}).get("units",[]))))
	state = arena("self-destruct","overgrow","damp")
	check(not game.engine.attack_plan(state,10000,{},"self-destruct").ok,"Damp stops self-KO before spending resources")
	state = arena("water-gun","overgrow","pressure")
	preview = game.engine.attack_plan(state,10000,{},"water-gun")
	check(preview.ok and preview.cost==2,"Pressure increases PT cost once")
	state.units[0].tp = 1
	check(not game.engine.attack_plan(state,10000,{},"water-gun").ok,"Pressure can prevent unaffordable move")
	var report: Dictionary = {"checks":checks,"failures":failures}
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
