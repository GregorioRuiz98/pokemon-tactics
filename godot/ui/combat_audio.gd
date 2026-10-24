extends Node

const MANIFEST: String = "res://assets/combat/manifest.json"
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var requests: int = 0

func _ready() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for entry: Dictionary in manifest.files: streams[entry.id] = load(entry.path)
	for index: int in 4:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func play_cue(identity: String, volume: float, silent: bool) -> void:
	if silent or volume<=0 or not streams.has(identity): return
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice+1)%voices.size()
	voice.stop()
	voice.stream = streams[identity]
	voice.volume_db = linear_to_db(clampf(volume/100.0,0.0001,1))
	voice.play()
	requests += 1

func stop() -> void:
	for voice: AudioStreamPlayer in voices: voice.stop()

func set_volume(volume: float, silent: bool) -> void:
	if silent or volume<=0: stop()
	for voice: AudioStreamPlayer in voices: voice.volume_db = linear_to_db(clampf(volume/100.0,0.0001,1))
