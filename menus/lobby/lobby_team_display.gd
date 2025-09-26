extends VBoxContainer
class_name CLobbyTeamDisplay

@export var team : CGameState.PLAYER_TEAM : set = set_team

func _ready() -> void:
	GameState.players_changed.connect(update)

func set_team(value : CGameState.PLAYER_TEAM) -> void:
	team = value
	update()
	
func update() -> void:
	var children := get_children()
	var verified : Array[bool] = []
	var new_children : Array[CLobbyPlayerDisplay] = []
	verified.resize(children.size())
	verified.fill(false)
	for player in GameState.players:
		if GameState.players[player].team == team:
			var present := false
			var jdx := -1
			for child in children:
				jdx += 1
				if child is CLobbyPlayerDisplay:
					if child.player == player:
						verified[jdx] = true
						present = true
						break
			if not present:
				var new_child := preload("res://menus/lobby/LobbyPlayerDisplay.tscn").instantiate()
				new_child.player = player
				new_children.push_back(new_child)
	var idx := -1
	var kill_children = []
	for is_correct in verified:
		idx += 1
		if not is_correct:
			kill_children.push_back(get_child(idx))
	for child in kill_children:
		child.queue_free()
	for child in new_children:
		add_child(child)
