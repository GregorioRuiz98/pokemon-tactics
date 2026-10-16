extends "res://core/tactics_study.gd"

func _init() -> void:
	super()
	data.version = 7

func _apply_hp_growth(member: Dictionary, previous_hp: int, previous_max: int, receipt: Dictionary) -> Dictionary:
	receipt.hpGain = 0
	if previous_hp <= 0 or receipt.level <= receipt.before: return receipt
	# Include automatic evolution during leveling, preserving the missing HP.
	var maximum: int = stats(int(member.speciesId),int(member.level)).maxHp
	var gain: int = maxi(0,maximum-previous_max)
	member.hp = mini(maximum,previous_hp+gain)
	receipt.hpGain = member.hp-previous_hp
	return receipt

func award(member: Dictionary, amount: int) -> Dictionary:
	var previous_hp: int = member.hp
	var previous_max: int = stats(int(member.speciesId),int(member.level)).maxHp
	return _apply_hp_growth(member,previous_hp,previous_max,super.award(member,amount))

func candy(member: Dictionary) -> Dictionary:
	var previous_hp: int = member.hp
	var previous_max: int = stats(int(member.speciesId),int(member.level)).maxHp
	return _apply_hp_growth(member,previous_hp,previous_max,super.candy(member))
