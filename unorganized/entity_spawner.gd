extends Node
class_name CEntitySpawner

var spawn_parent : Node3D : set = set_spawn_parent

var _name_idx := 0

enum Config
{
	PATH,
	SPAWNER_ID,
	GLOBAL_TRANSFORM,
	MULTIPLAYER_AUTHORITY,
	SET_CAMERA3D,
	CALLBACK_NAME,
	CALLBACK_PATH,
	NAME,
}

static var config_types : Dictionary = {
	Config.PATH: String(""),
	Config.SPAWNER_ID: int(0),
	Config.GLOBAL_TRANSFORM: Transform3D(),
	Config.MULTIPLAYER_AUTHORITY: int(1),
	Config.SET_CAMERA3D: bool(false),
	Config.CALLBACK_NAME: String(""),
	Config.CALLBACK_PATH: NodePath(),
	Config.NAME: String(""),
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
	if not Config.NAME in config:
		config[Config.NAME] = str(_name_idx)
		_name_idx += 1
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
	spawn_parent.add_child(item, true)
	if Config.MULTIPLAYER_AUTHORITY in config:
		item.set_multiplayer_authority(config[Config.MULTIPLAYER_AUTHORITY])
	if Config.SET_CAMERA3D in config:
		if config[Config.SET_CAMERA3D]:
			if multiplayer.get_unique_id() == item.get_multiplayer_authority():
				item.find_child("Camera3D").current = true
			else:
				item.find_child("Camera3D").current = false
	if Config.CALLBACK_NAME in config and Config.CALLBACK_PATH in config:
		var node : Node = get_node(config[Config.CALLBACK_PATH])
		if node:
			if node.has_method(config[Config.CALLBACK_NAME]):
				var callable : Callable = Callable(node, config[Config.CALLBACK_NAME])
				callable.call(item, config)
			else:
				print_debug("Node exists but does not have callback method, config = ", config)
		else:
			print_debug("Callback node not found, config: ", config)
				
	
