extends Node3D
class_name PlayerSpawner

enum PLAYER_SCENES
{
	PLANE,
	MOTORCYCLE,
}

var scene_path_map := {
	PLAYER_SCENES.PLANE: "res://src/plane/Plane.tscn",
	PLAYER_SCENES.MOTORCYCLE: "res://src/motorcycle/motorcycle2.tscn",
}

@export var player_scene : PLAYER_SCENES = PLAYER_SCENES.PLANE

@rpc("authority", "reliable", "call_local")
func spawn_player(player_id : int) -> void:
	var player = load(scene_path_map[player_scene]).instantiate()
	add_child(player)
	player.set_multiplayer_authority(player_id)
	player.get_node("Camera3D").current = player.is_authority()
