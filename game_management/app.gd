extends Node
class_name CApp

var main_menu : CMainMenu = null
var game_instance : CGameInstance = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu = preload("res://menus/main/MainMenu.tscn").instantiate()
	main_menu.debug_start.connect(debug_start)
	multiplayer.connected_to_server.connect(start_game)
	add_child(main_menu)
	
func debug_start() -> void:
	$DebugMultiplayer.debug_start_network()
	main_menu.queue_free()
	main_menu = null
	start_game()

func start_game() -> void:
	game_instance = preload("res://game_management/GameInstance.tscn").instantiate()
	add_child(game_instance)
