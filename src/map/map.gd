extends Node3D
class_name CMap

@onready var motorcycle_start: Node3D = $MotorcycleStart
@onready var plane_start: Node3D = $PlaneStart


func _ready() -> void:
	EntitySpawner.spawn_parent = self
	GameState.state_changed.connect(on_gamestate_changed)


func on_gamestate_changed() -> void:
	match GameState.state:
		CGameState.GAME_STATE.PLAYING:
			if multiplayer.is_server():
				spawn_players()


func spawn_players() -> void:
	var n_motorcycles := 0
	var n_planes := 0
	var motorcycle_delta := 3.0
	var plane_delta := 3.0
	for player in GameState.players:
		if GameState.players[player].team == GameState.team_motorcycle:
			EntitySpawner.spawn_item({
				CEntitySpawner.Config.PATH: "res://src/motorcycle/motorcycle2.tscn",
				CEntitySpawner.Config.MULTIPLAYER_AUTHORITY: player,
				CEntitySpawner.Config.GLOBAL_TRANSFORM: motorcycle_start.global_transform.translated(motorcycle_start.global_transform.basis.x*motorcycle_delta*n_motorcycles),
				CEntitySpawner.Config.SET_CAMERA3D: true
			})
			n_motorcycles += 1
		if GameState.players[player].team == GameState.team_plane:
			EntitySpawner.spawn_item({
				CEntitySpawner.Config.PATH: "res://src/plane/plane.tscn",
				CEntitySpawner.Config.MULTIPLAYER_AUTHORITY: player,
				CEntitySpawner.Config.GLOBAL_TRANSFORM: plane_start.global_transform.translated(plane_start.global_transform.basis.x*plane_delta*n_planes),
				CEntitySpawner.Config.SET_CAMERA3D: true
			})
			n_planes+= 1
