extends "res://core/vitality_study.gd"

var gym_cap: int = 14

func _init() -> void:
	super()
	data.version = 8

func award(member: Dictionary, amount: int) -> Dictionary:
	var remaining: int = 0
	if member.hp>0:
		for level: int in range(int(member.level),gym_cap): remaining += next_xp(level)
		remaining = maxi(0,remaining-int(member.xp))
		if member.level>=gym_cap: member.xp = 0
	var accepted: int = mini(maxi(0,amount),remaining)
	var receipt: Dictionary = super.award(member,accepted)
	if member.hp>0 and member.level>=gym_cap: member.xp = 0
	receipt.xpDiscarded = maxi(0,amount)-accepted
	return receipt

func candy(member: Dictionary) -> Dictionary:
	if member.level>=gym_cap:
		var receipt: Dictionary = _receipt(member,int(member.level),0,[],[])
		receipt.hpGain = 0
		return receipt
	var receipt: Dictionary = super.candy(member)
	if member.hp>0 and member.level>=gym_cap: member.xp = 0
	return receipt
