extends SceneTree

const Game = preload("res://core/journey_run.gd")
const Batch = preload("res://ui/shop_batch.gd")
const Store = preload("res://core/save_store.gd")
var assertions: int = 0
var failures: Array[String] = []

func check(value: bool, text: String) -> void:
	assertions += 1
	if not value: failures.append(text)

func _initialize() -> void:
	var game: RefCounted = Game.new(22)
	var initial: Dictionary = game.create("batch-fixture",1)
	initial.phase = "shop"
	initial.money = 10000
	initial.bag["rare-candy"] = 10
	var snapshot: Dictionary = initial.duplicate(true)
	for count: int in [1,5]:
		for mode: String in ["buy","use"]:
			var plan: Dictionary = Batch.prepare(game,initial,mode,"rare-candy",1,count)
			check(plan.ok,"Valid candy batch "+mode+str(count))
			if not plan.ok: continue
			var manual: Dictionary = initial.duplicate(true)
			for index: int in count:
				var command: Dictionary = {"kind":"buy" if mode=="buy" else "level-up","at":manual.revision}
				if mode=="buy": command.item = "rare-candy"
				else: command.member = 1
				check(command==plan.commands[index],"Batch contains exactly the independent manual command")
				var result: Dictionary = game.transact(manual,command)
				check(result.ok,"Every batch command is a legal original transaction")
				manual = result.state
			check(Store.equivalent(plan.state,manual),"Full manual/batch state equivalence")
			check(Store.equivalent(initial,snapshot),"Preview does not mutate full fixture")
	for count: int in [-1,0,100,1000000]: check(not Batch.prepare(game,initial,"buy","rare-candy",1,count).ok,"Invalid quantity rejected")
	var cap: Dictionary = initial.duplicate(true)
	cap.party[0].level = 14
	check(not Batch.prepare(game,cap,"use","rare-candy",1,1).ok,"Gym cap cannot be bypassed")
	var poor: Dictionary = initial.duplicate(true)
	poor.money = 0
	check(not Batch.prepare(game,poor,"buy","rare-candy",1,5).ok,"Insufficient money cannot partially purchase preview")
	var dead: Dictionary = initial.duplicate(true)
	dead.party[0].hp = 0
	dead.bag.revive = 1
	var revive: Dictionary = Batch.prepare(game,dead,"use","revive",1,1)
	check(revive.ok and revive.state.party[0].hp==maxi(1,int(game.progression.stats(1,5).maxHp/2.0)),"Revive retains original half HP rule")
	check(not Batch.prepare(game,dead,"use","rare-candy",1,1).ok,"Candy cannot revive")
	print(JSON.stringify({"assertions":assertions,"failures":failures,"syntheticFixture":true}))
	quit(0 if failures.is_empty() else 1)
