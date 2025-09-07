extends Node
class_name CEntitySpawner

var spawn_parent : Node3D : set = set_spawn_parent

enum Config
{
	PATH,
	SPAWNER_ID,
}

static var config_types : Dictionary = {
	Config.PATH: String(""),
	Config.SPAWNER_ID: int(0),
} 

func set_spawn_parent(value : Node3D) -> void:
	print_debug("New spawn parent: ", value, ", old parent was ", spawn_parent)
	spawn_parent = value
	
func spawn_item(config : Dictionary) -> void:
	for key in config:
		assert(typeof(config[key]) == typeof(config_types[key]))
	_server_spawn_item.rpc_id(1, config)
	
@rpc("call_local", "any_peer", "reliable")
func _server_spawn_item(config : Dictionary) -> void:
	var id := multiplayer.get_remote_sender_id()
	_client_spawn_item.rpc(config)
	
@rpc("call_local", "authority", "reliable")
func _client_spawn_item(config : Dictionary) -> void:
	print_debug("_client_spawn_item on ", multiplayer.get_unique_id() , ", config = ", config)
	#spawn_parent.add_child(item)
