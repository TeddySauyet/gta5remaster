extends HBoxContainer

@onready var label_team_a : Label = $VBoxContainer2/Label
@onready var label_team_b : Label = $VBoxContainer3/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.team_motorcycle_changed.connect(update_labels)
	GameState.team_plane_changed.connect(update_labels)
	update_labels()


func update_labels() -> void:
	label_team_a.text = "Team A: "
	label_team_b.text = "Team B: "
	if GameState.team_motorcycle == GameState.PLAYER_TEAM.A:
		label_team_a.text += "Motorcycles"
		label_team_b.text += "Planes"
	elif GameState.team_motorcycle == GameState.PLAYER_TEAM.B:
		label_team_a.text += "Planes"
		label_team_b.text += "Motorcycles"
	else:
		print_debug("Uh oh!")
