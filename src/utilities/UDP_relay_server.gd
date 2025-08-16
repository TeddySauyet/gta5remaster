class_name UDP_relay_server
extends Node

## Simulates lag and packet drops when testing multiplayer locally
## Original source: https://forum.godotengine.org/t/how-i-can-simulate-a-network-latency-and-packet-loss-between-client-and-server-peers/25012/2
## 
## The basic idea is to use two PacketPeerUDPs to intercept packets between the
## client and the server, introduce lag/packet drops, then send them along.
##
## true server <-> [virtual client - - - virtual server] <-> true client
## where [...] denotes the contents of this script, "<->" is a lagless 
## connection, and "- - -" is the laggy connection

## Note: only works for two players, one server and one client

@export var virtual_server_port : int = 27016
@export var true_server_port : int = 27015
@export_category("Degradation")
@export_range(0, 5000) var fake_latency_ms : int = 0
@export_range(0,5000) var fake_latency_variance : int = 1
@export_range(0, 0.5) var fake_loss : float = 0

## the virtual server
var vserver_peer : PacketPeerUDP
## used to store if the virtual server has established a connection to a client
var vserver_has_dest_address : bool = false
var vserver_first_client_port : int = -1
## the virtual client
var vclient_peer : PacketPeerUDP

var rng = RandomNumberGenerator.new()

class QueEntry :
	var byte_array : PackedByteArray
	var qued_at : int
	var send_at : int
	
	func _init(packet:PackedByteArray, time_now:int, send_at_ : int) :
		self.byte_array = packet
		self.qued_at = time_now
		self.send_at = send_at_

var client_to_server_que : Array[QueEntry]
var server_to_client_que : Array[QueEntry]

func _enter_tree() -> void:
	print_debug("Setting up UDP relay server")

	#listen to this address/port
	vserver_peer = PacketPeerUDP.new()
	vserver_peer.bind(virtual_server_port, "127.0.0.1")
	
	#send commands to this port
	vclient_peer = PacketPeerUDP.new()
	vclient_peer.set_dest_address("127.0.0.1", true_server_port)

	if not OS.is_debug_build() :	
		push_warning("UDP relay is active, but it is not a debug build!!! This will consume some performance....")
		fake_latency_ms = 0
		fake_loss = 0
		
func _process(_delta : float) -> void :
	var now : int = Time.get_ticks_msec()
	var send_at : int
	
	# Handle packets Client -> Server
	while vserver_peer.get_available_packet_count() > 0 :
		var packet = vserver_peer.get_packet()
		var err = vserver_peer.get_packet_error()
		if err != OK :
			push_error("UDP relay server : Incoming packet error : ", err)
			continue
			
		var from_port = vserver_peer.get_packet_port()
		
		if not vserver_has_dest_address : 
			# Assume the first who send a packet to us is the True Client
			vserver_peer.set_dest_address("127.0.0.1", from_port)
			vserver_first_client_port = from_port
			vserver_has_dest_address = true
		elif vserver_first_client_port != from_port :
			push_warning("UDP relay server : VServer got packet from unknown port, ignored. first = " + str(vserver_first_client_port) + ", from = " + str(from_port))
			continue
		
		send_at = now + fake_latency_ms + randi_range(-fake_latency_variance,fake_latency_variance)
		client_to_server_que.push_back(QueEntry.new(packet, now, send_at))
	
	_process_que(client_to_server_que, vclient_peer)
	
	# Handle packets Server -> Client
	while vclient_peer.get_available_packet_count() > 0 :
		var packet = vclient_peer.get_packet()
		var err = vclient_peer.get_packet_error()
		if err != OK :
			push_error("DebugUDPLagger : Incoming packet error : ", err)
			continue
		
		var from_port = vclient_peer.get_packet_port()
		if from_port != true_server_port :
			push_warning("DebugUDPLagger : VClient got packet from unknown port, ignored.")
			continue
			
		send_at = now + fake_latency_ms + randi_range(-fake_latency_variance,fake_latency_variance)
		server_to_client_que.push_back(QueEntry.new(packet, now, send_at))

	_process_que(server_to_client_que, vserver_peer)
	
func _process_que(que : Array[QueEntry], to_peer : PacketPeerUDP) :
	var now : int = Time.get_ticks_msec()	
	while not que.is_empty() :
		var front = que.front()
		if now >= front.send_at :
			# Send it, or drop it?
			# Note : We check for dropping here, so that you can change fake_loss
			#  while packets are in the queue. Eg. the que is kept "intact"
			#  for as long as possible.
			if fake_loss <= 0  ||  rng.randf() >= fake_loss:
				to_peer.put_packet(front.byte_array)
			# Remove from que
			que.pop_front()
		else :
			break
	#print_debug('q processed')
