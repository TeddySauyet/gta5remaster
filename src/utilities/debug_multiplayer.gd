extends Node

var server_port : int = 27015
var client_port : int = 27015
var ip : String = "127.0.0.1"


func _ready():
	pass # Replace with function body.

func debug_start_network() -> void:
	if not _attempt_host_server():
		_join_server()

func _attempt_host_server() -> bool:
	var peer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(server_port,32)
	if error:
		return false
	multiplayer.multiplayer_peer = peer
	print_debug('Hosted server')
	return true

func _join_server() -> bool:
	var peer := ENetMultiplayerPeer.new()
	var error : Error = peer.create_client(ip,client_port)
	if error:
		return false
	multiplayer.multiplayer_peer = peer
	print_debug('Joined server, id is ', str(multiplayer.get_unique_id()))
	return true
