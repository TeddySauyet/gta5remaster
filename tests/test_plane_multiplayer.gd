extends Node3D

var n_players = 0
var max_players = 2

var spawners : Array[PlayerSpawner]

func _ready() -> void:
	spawners = [$PlayerSpawner2, $PlayerSpawner3, $PlayerSpawner4, $PlayerSpawner5, $PlayerSpawner6]
	multiplayer.peer_connected.connect(on_peer_connected)
	$DebugMultiplayer.debug_start_network()
	
func on_peer_connected(id : int) -> void:
	n_players += 1
	if multiplayer.is_server() and n_players == max_players - 1:
		$PlayerSpawner.spawn_player.rpc(1)
		var peers = multiplayer.get_peers()
		for idx in  range(peers.size()):
			spawners[idx].spawn_player.rpc(peers[idx])
