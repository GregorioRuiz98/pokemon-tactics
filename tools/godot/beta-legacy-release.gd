extends "res://tests/release_checks.gd"

# Historical control: isolates the version-number regression without editing the game.
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/version","0.22.0")
	super._initialize()
