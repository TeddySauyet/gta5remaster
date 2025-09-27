extends Label
class_name CLobbyPlayerDisplay

var player : int = -1 : set = set_player

func update() -> void:
	if player in GameState.players:
		text = ""
		if GameState.players[player].ready_for_game_start:
			text += "✔ "
		text += GameState.players[player].name
		text += ": "
		text += str(player)
	else:
		text = ""

func _ready() -> void:
	GameState.players_changed.connect(update)
	
func set_player(value : int) -> void:
	player = value
	update()
