extends Node3D
class_name CMap

@onready var motorcycle_start: Node3D = $MotorcycleStart
@onready var plane_start: Node3D = $PlaneStart
@onready var spectator_start: Node3D = $SpectatorStart

signal round_won(team : CGameState.PLAYER_TEAM)

func _ready() -> void:
	EntitySpawner.spawn_parent = self
	MPhaseController.new_local_phase.connect(on_phase_changed)

func _process(delta: float) -> void:
	if multiplayer.is_server():
		match MPhaseController.get_current_phase().name:
			RMPhase.Playing:
				var motorcycle_alive := false
				var plane_alive := false
				for player in GameState.players:
					match GameState.players[player].state:
						GameState.PLAYER_STATE.MOTORCYCLE:
							motorcycle_alive = true
						GameState.PLAYER_STATE.PLANE:
							plane_alive = true
				if motorcycle_alive and plane_alive:
					pass
				elif not motorcycle_alive and not plane_alive:
					round_won.emit(CGameState.PLAYER_TEAM.NONE)
				elif motorcycle_alive:
					round_won.emit(GameState.team_motorcycle)
				elif plane_alive:
					round_won.emit(GameState.team_plane)
				else:
					print_debug("Unreachable")
					
					

func on_phase_changed(phase : RMPhase) -> void:
	match phase.name:
		"Playing":
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
				CEntitySpawner.Config.SET_CAMERA3D: true,
				CEntitySpawner.Config.CALLBACK_NAME: "spawn_callback",
				CEntitySpawner.Config.CALLBACK_PATH: get_path(),
			})
			n_motorcycles += 1
		if GameState.players[player].team == GameState.team_plane:
			EntitySpawner.spawn_item({
				CEntitySpawner.Config.PATH: "res://src/plane/plane.tscn",
				CEntitySpawner.Config.MULTIPLAYER_AUTHORITY: player,
				CEntitySpawner.Config.GLOBAL_TRANSFORM: plane_start.global_transform.translated(plane_start.global_transform.basis.x*plane_delta*n_planes),
				CEntitySpawner.Config.SET_CAMERA3D: true,
				CEntitySpawner.Config.CALLBACK_NAME: "spawn_callback",
				CEntitySpawner.Config.CALLBACK_PATH: get_path(),
			})
			n_planes+= 1
		if GameState.players[player].team == CGameState.PLAYER_TEAM.NONE:
			EntitySpawner.spawn_item({
				CEntitySpawner.Config.PATH: "res://src/spectator/Spectator.tscn",
				CEntitySpawner.Config.MULTIPLAYER_AUTHORITY: player,
				CEntitySpawner.Config.GLOBAL_TRANSFORM: spectator_start.global_transform,
				CEntitySpawner.Config.SET_CAMERA3D: true,
				CEntitySpawner.Config.CALLBACK_NAME: "spawn_callback",
				CEntitySpawner.Config.CALLBACK_PATH: get_path(),
			})
			n_planes+= 1

func spawn_callback(node : Node, config : Dictionary) -> void:
	#print_debug("Call back with id ", config[CEntitySpawner.Config.MULTIPLAYER_AUTHORITY], " on player ", multiplayer.get_unique_id(), " scene is ", config[CEntitySpawner.Config.PATH])
	pass
