extends Control
class_name LobbyMenu

@onready var player_display_parent : Container = $VBoxContainer

func _ready() -> void:
	GameState.players_changed.connect(update_players)
	for player in GameState.players:
		var scene := preload("res://menus/LobbyPlayerDisplay.tscn").instantiate()
		player_display_parent.add_child(scene)
		scene.player = player
	$HBoxContainer/Button.pressed.connect(debug_player_enter)

func update_players() -> void:
	var current_ids := []
	for child in player_display_parent.get_children():
		if child is CLobbyPlayerDisplay:
			current_ids.push_back(child.player)
	for player in GameState.players:
		if not player in current_ids:
			var scene := preload("res://menus/LobbyPlayerDisplay.tscn").instantiate()
			player_display_parent.add_child(scene)
			scene.player = player

func debug_player_enter() -> void:
	var id := 1
	for player in GameState.players:
		if player >= id:
			id = player + 1
	var player_info = CGameState.CPlayerInfo.new()
	player_info.id = id
	player_info.name = $HBoxContainer/LineEdit.text
	GameState.players[id] = player_info
