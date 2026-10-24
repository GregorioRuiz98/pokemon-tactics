extends Node

const MANIFEST: String = "res://assets/combat/manifest.json"
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var requests: int = 0
var original_streams: Dictionary = {}
var original_gains: Dictionary = {}

func _ready() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for entry: Dictionary in manifest.files: streams[entry.id] = load(entry.path)
	var originals: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/original-moves/manifest.json"))
	for entry: Dictionary in originals.files:
		original_streams[entry.id] = load(entry.path)
		original_gains[entry.id] = float(entry.gainDb)
	for index: int in 4:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func play_cue(identity: String, volume: float, silent: bool) -> void:
	var original: bool = identity.begins_with("original/")
	var key: String = identity.trim_prefix("original/") if original else identity
	var bank: Dictionary = original_streams if original else streams
	if silent or volume<=0 or not bank.has(key): return
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice+1)%voices.size()
	voice.stop()
	voice.stream = bank[key]
	voice.set_meta("gain",float(original_gains[key]) if original else 0.0)
	voice.volume_db = linear_to_db(clampf(volume/100.0,0.0001,1))+float(voice.get_meta("gain",0.0))
	voice.play()
	requests += 1

func stop() -> void:
	for voice: AudioStreamPlayer in voices: voice.stop()

func set_volume(volume: float, silent: bool) -> void:
	if silent or volume<=0: stop()
	for voice: AudioStreamPlayer in voices: voice.volume_db = linear_to_db(clampf(volume/100.0,0.0001,1))+float(voice.get_meta("gain",0.0))
