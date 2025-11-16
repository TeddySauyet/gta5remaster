extends Node
class_name CGameInstance

var lobby_menu : CLobbyMenu = null
var map : CMap = null


func _ready() -> void:
	MPhaseController.new_local_phase.connect(_on_new_phase)
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(on_player_connected)
		on_player_connected(1)
		MPhaseController.set_phase("Lobby")
		_on_new_phase(MPhaseController.get_current_phase())


## lots more work to do here
func on_player_connected(id : int) -> void:
	assert(not id in GameState.players)
	GameState.players[id] = CGameState.CPlayerInfo.new()

func _on_new_phase(phase : RMPhase) -> void:
	match phase.name:
		RMPhase.LOBBY:
			open_lobby_menu()
		RMPhase.MapLoad:
			reset()
			open_game_map()
			MPhaseController.set_ready(true)
		RMPhase.Playing:
			print_debug("Playing on ", multiplayer.get_unique_id())
		RMPhase.RoundEnd:
			print_debug("Round end on  ", multiplayer.get_unique_id())
			

func open_lobby_menu() -> void:
	reset()
	lobby_menu = preload("res://menus/lobby/LobbyMenu.tscn").instantiate()
	add_child(lobby_menu)

func reset() -> void:
	if lobby_menu:
		remove_child(lobby_menu)
		lobby_menu.queue_free()
		lobby_menu = null


func open_game_map() -> void:
	map = preload("res://src/map/Map.tscn").instantiate()
	add_child(map)
	if multiplayer.is_server():
		map.round_won.connect(on_round_won)
	
func on_round_won(team : CGameState.PLAYER_TEAM) -> void:
	if multiplayer.is_server():
		GameState.round_wins[team] += 1
		if GameState.round_wins[team] >= GameState.N_ROUNDS_TO_WIN:
			MPhaseController.set_phase(RMPhase.GameEnd)
		else:
			MPhaseController.set_phase(RMPhase.RoundEnd)

@rpc("any_peer", "reliable", "call_local")
func set_map_ready() -> void:
	var id := multiplayer.get_remote_sender_id()
	GameState.players[id].ready_for_map_start = true
