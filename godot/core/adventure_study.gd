extends "res://core/economy_study.gd"

func _init() -> void:
	super()
	data.version = 21

func recovery_award(member: Dictionary, amount: int) -> Dictionary:
	if member.hp>0: return award(member,amount)
	# A fallen participant can progress, but must still be revived in the shop.
	member.hp = 1
	var receipt: Dictionary = award(member,amount)
	member.hp = 0
	receipt.hpGain = 0
	receipt.reason = "Recuperación · debilitado"
	return receipt
