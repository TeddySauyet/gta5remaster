extends Label
class_name CLobbyPlayerDisplay

var player : int = -1 : set = set_player

func update() -> void:
	if player in GameState.players:
		text = ""
		if MPhaseController.player_to_ready[player]:
			text += "✔ "
		text += GameState.players[player].name
		text += ": "
		text += str(player)
	else:
		text = ""

func _ready() -> void:
	GameState.players_changed.connect(update)
	MPhaseController.new_local_ready.connect(_on_new_local_ready)
	MPhaseController.new_remote_ready.connect(_on_new_remote_ready)
	
	
func _on_new_local_ready(value : bool) -> void:
	update()

func _on_new_remote_ready(id: int, value: bool) -> void:
	update()

func set_player(value : int) -> void:
	player = value
	update()
