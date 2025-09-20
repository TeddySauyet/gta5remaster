extends Control
class_name CMainMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Button.pressed.connect(debug_starter)

signal debug_start()

func debug_starter() -> void:
	debug_start.emit()
