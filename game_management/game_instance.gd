extends Node
class_name CGameInstance

var lobby_menu : CLobbyMenu = null

func _ready() -> void:
	GameState.state_changed.connect(on_game_state_changed)
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(on_player_connected)
		on_player_connected(1)
		GameState.state = CGameState.GAME_STATE.LOBBY
	else:
		if GameState.state == CGameState.GAME_STATE.LOBBY:
			open_lobby_menu()

## lots more work to do here
func on_player_connected(id : int) -> void:
	assert(not id in GameState.players)
	GameState.players[id] = CGameState.CPlayerInfo.new()

func on_game_state_changed() -> void:
	match GameState.state:
		CGameState.GAME_STATE.LOBBY:
			open_lobby_menu()
		CGameState.GAME_STATE.MAP_LOAD:
			reset()

func open_lobby_menu() -> void:
	#print_debug(multiplayer.get_unique_id(), " opened lobby menu")
	reset()
	lobby_menu = preload("res://menus/lobby/LobbyMenu.tscn").instantiate()
	add_child(lobby_menu)

func reset() -> void:
	if lobby_menu:
		remove_child(lobby_menu)
		lobby_menu.queue_free()
		lobby_menu = null

func _process(delta: float) -> void:
	match GameState.state:
		CGameState.GAME_STATE.LOBBY:
			if multiplayer.is_server():
				var ready_game_start := true
				for player in GameState.players:
					if not GameState.players[player].ready_for_game_start:
						ready_game_start = false
						break
				if ready_game_start:
					GameState.state = CGameState.GAME_STATE.MAP_LOAD
