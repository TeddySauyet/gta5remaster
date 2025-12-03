extends Node
class_name CGameInstance

var lobby_menu : CLobbyMenu = null
var map : CMap = null
var round_end_menu : CRoundEndMenu = null
var game_end_menu : CMenuGameEnd = null


func _ready() -> void:
	MPhaseController.new_local_phase.connect(_on_new_phase)
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(on_player_connected)
		on_player_connected(1)
		MPhaseController.set_phase("Lobby")
		_on_new_phase(MPhaseController.get_current_phase())

func _process(delta: float) -> void:
	if multiplayer.is_server():
		match MPhaseController.get_current_phase().name:
			RMPhase.RoundEnd:
				if MPhaseController.get_consensus():
					end_round_end_phase()

## lots more work to do here
func on_player_connected(id : int) -> void:
	assert(not id in GameState.players)
	GameState.players[id] = CGameState.CPlayerInfo.new()

func _on_new_phase(phase : RMPhase) -> void:
	match phase.name:
		RMPhase.LOBBY:
			close_map()
			open_lobby_menu()
		RMPhase.MapLoad:
			reset_menus()
			open_game_map()
			MPhaseController.set_ready(true)
		RMPhase.Playing:
			print_debug("Playing on ", multiplayer.get_unique_id())
		RMPhase.RoundEnd:
			print_debug("Round end on  ", multiplayer.get_unique_id())
			open_round_end_menu()
		RMPhase.GameEnd:
			print_debug("Game end on  ", multiplayer.get_unique_id())
			open_game_end_menu()
			

func open_lobby_menu() -> void:
	reset_menus()
	lobby_menu = preload("res://menus/lobby/LobbyMenu.tscn").instantiate()
	add_child(lobby_menu)

func reset_menus() -> void:
	if lobby_menu:
		remove_child(lobby_menu)
		lobby_menu.queue_free()
		lobby_menu = null
	if round_end_menu:
		remove_child(round_end_menu)
		round_end_menu.queue_free()
		round_end_menu = null
	if game_end_menu:
		remove_child(game_end_menu)
		game_end_menu.queue_free()
		game_end_menu = null


func open_game_map() -> void:
	map = preload("res://src/map/Map.tscn").instantiate()
	add_child(map)
	if multiplayer.is_server():
		map.round_won.connect(on_round_won)
	
func close_map() -> void:
	if map:
		remove_child(map)
		map.queue_free()
		map = null
		
func on_round_won(team : CGameState.PLAYER_TEAM) -> void:
	if multiplayer.is_server():
		GameState.round_wins[team] += 1
		if GameState.round_wins[team] >= GameState.N_ROUNDS_TO_WIN:
			MPhaseController.set_phase(RMPhase.GameEnd)
		else:
			MPhaseController.set_phase(RMPhase.RoundEnd)

func open_round_end_menu() -> void:
	reset_menus()
	round_end_menu = preload("res://menus/round_end/RoundEnd.tscn").instantiate()
	add_child(round_end_menu)

func open_game_end_menu() -> void:
	reset_menus()
	game_end_menu = preload("res://menus/game_end/GameEnd.tscn").instantiate()
	add_child(game_end_menu)

func end_round_end_phase() -> void:
	if multiplayer.is_server():
		remote_end_round_end_phase.rpc()
		if GameState.round_wins[CGameState.PLAYER_TEAM.A] >= GameState.N_ROUNDS_TO_WIN \
			or GameState.round_wins[CGameState.PLAYER_TEAM.A] >= GameState.N_ROUNDS_TO_WIN:
				MPhaseController.set_phase(RMPhase.LOBBY)
		else:
				MPhaseController.set_phase(RMPhase.Playing)
			
		
@rpc("call_local", "authority", "reliable")
func remote_end_round_end_phase() -> void:
	reset_menus()
