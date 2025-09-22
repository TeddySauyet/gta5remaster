extends Node3D
class_name CMap


func _ready() -> void:
	GameState.state_changed.connect(on_gamestate_changed)


func on_gamestate_changed() -> void:
	match GameState.state:
		CGameState.GAME_STATE.PLAYING:
			if multiplayer.is_server():
				spawn_players()


func spawn_players() -> void:
	pass
