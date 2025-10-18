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
			

func on_game_state_changed() -> void:
	pass # does this even ever get called?
	#match GameState.state:
		#CGameState.GAME_STATE.LOBBY:
			#open_lobby_menu()
		#CGameState.GAME_STATE.MAP_LOAD:
			#reset()
			#open_game_map()
			#set_map_ready.rpc_id(1)
		#CGameState.GAME_STATE.PLAYING:
			#print_debug("Playing on ", multiplayer.get_unique_id())
		#CGameState.GAME_STATE.ROUND_END:
			#pass

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


func open_game_map() -> void:
	map = preload("res://src/map/Map.tscn").instantiate()
	map.package_delivered.connect(on_package_delivered)
	add_child(map)
	

@rpc("any_peer", "reliable", "call_local")
func set_map_ready() -> void:
	var id := multiplayer.get_remote_sender_id()
	GameState.players[id].ready_for_map_start = true


func on_package_delivered(player_id : int) -> void:
	pass
