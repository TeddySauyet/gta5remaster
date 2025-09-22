extends Node3D

var n_players = 0
var max_players = 2

var spawners : Array[PlayerSpawner]

func _ready() -> void:
	spawners = [$PlayerSpawner2, $PlayerSpawner3, $PlayerSpawner4, $PlayerSpawner5, $PlayerSpawner6]
	multiplayer.peer_connected.connect(on_peer_connected)
	$DebugMultiplayer.debug_start_network()
	if multiplayer.is_server():
		on_peer_connected(1)
	EntitySpawner.spawn_parent = self

func on_peer_connected(id : int) -> void:
	n_players += 1
	if multiplayer.is_server() and n_players == max_players:
		$PlayerSpawner.spawn_player.rpc(1)
		var peers = multiplayer.get_peers()
		for idx in  range(peers.size()):
			#spawners[idx].spawn_player.rpc(peers[idx])
			EntitySpawner.spawn_item({
				CEntitySpawner.Config.PATH: "res://src/plane/Plane.tscn",
				CEntitySpawner.Config.MULTIPLAYER_AUTHORITY: peers[idx],
				CEntitySpawner.Config.GLOBAL_TRANSFORM: spawners[idx].global_transform,
				CEntitySpawner.Config.SET_CAMERA3D: true
			})
