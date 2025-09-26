extends VBoxContainer
class_name CLobbyPlayerInfo

@onready var line_edit_name: LineEdit = $LineEditName
@onready var button_spectate: Button = $ButtonSpectate
@onready var button_join_team_a: Button = $ButtonJoinTeamA
@onready var button_join_team_b: Button = $ButtonJoinTeamB
@onready var button_ready_up: Button = $ButtonReadyUp


func _ready() -> void:
	GameState.players_changed.connect(update_buttons_active)
	try_initialize()
	
func try_initialize() -> void:
	if multiplayer.get_unique_id() in GameState.players:
		initialize()
	else:
		get_tree().create_timer(0.5).timeout.connect(try_initialize)

func initialize() -> void:
	var id := multiplayer.get_unique_id()
	line_edit_name.text = GameState.players[id].name
	line_edit_name.text_changed.connect(on_name_changed)
	button_spectate.pressed.connect(on_spectate_pressed)
	button_join_team_a.pressed.connect(on_join_team_a_pressed)
	button_join_team_b.pressed.connect(on_join_team_b_pressed)
	button_ready_up.pressed.connect(on_ready_up_pressed)
	
func on_name_changed(new_text : String) -> void:
	#var id := multiplayer.get_unique_id()
	server_change_name.rpc_id(1, new_text)
	
@rpc("any_peer", "reliable", "call_local")
func server_change_name(new_name : String) -> void:
	var id := multiplayer.get_remote_sender_id()
	GameState.players[id].name = new_name

func on_spectate_pressed() -> void:
	set_new_team.rpc_id(1, CGameState.PLAYER_TEAM.NONE)
	
func on_join_team_a_pressed() -> void:
	set_new_team.rpc_id(1, CGameState.PLAYER_TEAM.A)
	
func on_join_team_b_pressed() -> void:
	set_new_team.rpc_id(1, CGameState.PLAYER_TEAM.B)

func on_ready_up_pressed() -> void:
	ready_up.rpc_id(1)
	
@rpc("any_peer", "reliable", "call_local")
func ready_up() -> void:
	var id := multiplayer.get_remote_sender_id()
	#print_debug("Ready up pressed by ", id, " on ", multiplayer.get_unique_id())
	GameState.players[id].ready_for_game_start = true
	#for i in GameState.players:
		#print_debug(i, ": ", GameState.players[i].ready_for_game_start)
	
@rpc("any_peer", "reliable", "call_local")
func set_new_team(team : CGameState.PLAYER_TEAM) -> void:
	var id := multiplayer.get_remote_sender_id()
	GameState.players[id].team = team
	
func update_buttons_active() -> void:
	#Weird stuff with this node being freed during this transition
	#multiplayer property is null when this gets called
	#This seems to fix it - this node shouldn't exist during map load anyway
	if GameState.state == CGameState.GAME_STATE.MAP_LOAD:
		return
	var id := multiplayer.get_unique_id()
	button_spectate.disabled = GameState.players[id].team == CGameState.PLAYER_TEAM.NONE
	button_join_team_a.disabled = GameState.players[id].team == CGameState.PLAYER_TEAM.A
	button_join_team_b.disabled = GameState.players[id].team == CGameState.PLAYER_TEAM.B
	button_ready_up.disabled = GameState.players[id].ready_for_game_start
