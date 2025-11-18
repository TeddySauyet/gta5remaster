extends Control
class_name CRoundEndMenu

@onready var button_ready_up: Button = $VBoxContainer/HBoxContainer2/ButtonReadyUp

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_ready_up.pressed.connect(on_ready_up)


func on_ready_up() -> void:
	MPhaseController.set_ready(true)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
