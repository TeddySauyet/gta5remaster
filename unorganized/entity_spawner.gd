extends Node
class_name CEntitySpawner

var spawn_parent : Node3D : set = set_spawn_parent


func set_spawn_parent(value : Node3D) -> void:
	print_debug("New spawn parent: ", value, ", old parent was ", spawn_parent)
	spawn_parent = value
	
func spawn_item(item : Node3D) -> void:
	_server_spawn_item.rpc_id(1, item)
	
@rpc("call_local", "any_peer", "reliable")
func _server_spawn_item(item : Node3D) -> void:
	var id := multiplayer.get_remote_sender_id()
	_client_spawn_item.rpc(item)
	
@rpc("call_local", "authority", "reliable")
func _client_spawn_item(item : Node3D) -> void:
	spawn_parent.add_child(item)
