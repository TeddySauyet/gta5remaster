extends Node
class_name CEntitySpawner

var spawn_parent : Node3D : set = set_spawn_parent

enum Config
{
	PATH,
	SPAWNER_ID,
	GLOBAL_TRANSFORM,
	MULTIPLAYER_AUTHORITY,
	SET_CAMERA3D,
	CALLBACK,
}

static var config_types : Dictionary = {
	Config.PATH: String(""),
	Config.SPAWNER_ID: int(0),
	Config.GLOBAL_TRANSFORM: Transform3D(),
	Config.MULTIPLAYER_AUTHORITY: int(1),
	Config.SET_CAMERA3D: bool(false),
	Config.CALLBACK: Callable(self, "dummy_callback")
} 

static func dummy_callback(_node: Node, _config : Dictionary) -> void:
	print_debug("Uhhhhhhh you should look into this")

func set_spawn_parent(value : Node3D) -> void:
	print_debug("New spawn parent: ", value, ", old parent was ", spawn_parent)
	spawn_parent = value
	
func spawn_item(config : Dictionary) -> void:
	for key in config:
		assert(typeof(config[key]) == typeof(config_types[key]))
	_server_spawn_item.rpc_id(1, config)
	
@rpc("call_local", "any_peer", "reliable")
func _server_spawn_item(config : Dictionary) -> void:
	#var id := multiplayer.get_remote_sender_id()
	_client_spawn_item.rpc(config)
	
@rpc("call_local", "authority", "reliable")
func _client_spawn_item(config : Dictionary) -> void:
	#print_debug("_client_spawn_item on ", multiplayer.get_unique_id() , ", config = ", config)
	var item : Node3D
	if Config.PATH in config:
		item = load(config[Config.PATH]).instantiate()
	else:
		return
	if item.has_method("set_spawner_id") and Config.SPAWNER_ID in config:
		item.set_spawner_id(config[Config.SPAWNER_ID])
	if Config.GLOBAL_TRANSFORM in config:
		item.global_transform = config[Config.GLOBAL_TRANSFORM]
	spawn_parent.add_child(item)
	if Config.MULTIPLAYER_AUTHORITY in config:
		item.set_multiplayer_authority(config[Config.MULTIPLAYER_AUTHORITY])
	if Config.SET_CAMERA3D in config:
		if config[Config.SET_CAMERA3D]:
			if multiplayer.get_unique_id() == item.get_multiplayer_authority():
				item.find_child("Camera3D").current = true
			else:
				item.find_child("Camera3D").current = false
	if Config.CALLBACK in config:
		config[Config.CALLBACK].call(item, config)
				
	
