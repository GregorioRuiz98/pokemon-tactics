extends "res://core/spatial_study.gd"

var economy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))

func _init() -> void:
	super()
	data.version = 20

func member_next_xp(member: Dictionary) -> int:
	if member.level>=100: return 0
	var curve: Array = economy.curves[str(int(economy.growthGroups[str(int(member.speciesId))]))]
	return int(curve[int(member.level)+1])-int(curve[int(member.level)])

func next_xp(level: int) -> int:
	# Legacy consumers without a species use Medium Fast; new UI uses member_next_xp.
	return 0 if level>=100 else int(economy.curves["2"][level+1])-int(economy.curves["2"][level])

func evolution(member: Dictionary) -> Dictionary:
	return {} if economy.freeEvolutions.has(str(int(member.speciesId))) else super.evolution(member)

func free_evolutions(member: Dictionary) -> Array:
	return economy.freeEvolutions.get(str(int(member.speciesId)),[])

func award(member: Dictionary, amount: int) -> Dictionary:
	var before: int = member.level
	var previous_hp: int = member.hp
	var maximum: int = member_stats(member).maxHp
	var learned: Array = []
	var evolved: Array = []
	var accepted: int = 0
	var remaining: int = maxi(0,amount)
	if member.hp>0:
		while remaining>0 and member.level<mini(gym_cap,100):
			var needed: int = maxi(0,member_next_xp(member)-int(member.xp))
			var grant: int = mini(remaining,needed)
			member.xp += grant; accepted += grant; remaining -= grant
			if member.xp>=member_next_xp(member):
				member.xp -= member_next_xp(member)
				member.level += 1
				learned.append_array(learn(member))
				_evolve_ready(member,evolved,learned)
		if member.level>=gym_cap: member.xp = 0
	var receipt: Dictionary = _receipt(member,before,accepted,learned,evolved)
	receipt.xpDiscarded = maxi(0,amount)-accepted
	receipt.hpGain = 0
	if previous_hp>0 and member.level>before:
		member.hp = mini(member_stats(member).maxHp,previous_hp+maxi(0,int(member_stats(member).maxHp)-maximum))
		receipt.hpGain = member.hp-previous_hp
	return receipt
