extends Node
class_name CGameInstance

var lobby_menu : CLobbyMenu = null
var map : CMap = null


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
			open_game_map()
			set_map_ready.rpc_id(1)
		CGameState.GAME_STATE.PLAYING:
			print_debug("Playing on ", multiplayer.get_unique_id())
		CGameState.GAME_STATE.ROUND_END:
			pass

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

func _process(_delta: float) -> void:
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
		CGameState.GAME_STATE.MAP_LOAD:
			if multiplayer.is_server():
				var ready_map_start := true
				for player in GameState.players:
					if not GameState.players[player].ready_for_map_start:
						ready_map_start = false
						break
				if ready_map_start:
					GameState.state = CGameState.GAME_STATE.PLAYING
		CGameState.GAME_STATE.PLAYING:
			if multiplayer.is_server():
				var alive_motorcycle := false
				var alive_plane := false
				for player in GameState.players:
					var state : CGameState.CPlayerInfo = GameState.players[player]
					if (state.team == GameState.team_motorcycle) and (state.state == CGameState.PLAYER_STATE.MOTORCYCLE):
						alive_motorcycle = true
					elif (state.team == GameState.team_plane) and (state.state == CGameState.PLAYER_STATE.PLANE):
						alive_plane = true
				if alive_motorcycle and alive_plane:
					pass
				elif (not alive_motorcycle) and (not alive_plane):
					GameState.state = CGameState.GAME_STATE.ROUND_END
				elif alive_motorcycle:
					GameState.round_wins[GameState.team_motorcycle] += 1
					GameState.state = CGameState.GAME_STATE.ROUND_END
				elif alive_plane:
					GameState.round_wins[GameState.team_plane] += 1
					GameState.state = CGameState.GAME_STATE.ROUND_END
				else:
					assert(false, "2^2 = 4, and this is the 5th")
			
			

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
