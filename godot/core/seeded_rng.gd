class_name LabRng
extends RefCounted

const MASK = 0xffffffff

static func hash_seed(seed: String) -> int:
	var value = 2166136261
	for index in seed.length():
		var code = seed.unicode_at(index)
		# JS for..of + charCodeAt(0) uses the high surrogate for astral characters.
		if code > 0xffff:
			code = 0xd800 + ((code - 0x10000) >> 10)
		value = ((value ^ code) * 16777619) & MASK
	return value

static func next(state: Dictionary) -> float:
	state.rng = (int(state.rng) + 0x6d2b79f5) & MASK
	var value = int(state.rng)
	value = ((value ^ (value >> 15)) * (value | 1)) & MASK
	value = (value ^ ((value + (((value ^ (value >> 7)) * (value | 61)) & MASK)) & MASK)) & MASK
	return float((value ^ (value >> 14)) & MASK) / 4294967296.0
