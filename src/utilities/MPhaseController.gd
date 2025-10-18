extends Node
class_name CMPhaseController

## Manages a set of RMPhases
## API:
##  set_phase(variant[String, RMPhase]) -> bool
##  set_ready(bool) -> void


@export var phases : Array[RMPhase] : set = set_phases

## Emitted when the local client changes phase
signal new_local_phase(phase : RMPhase)

## Emitted when a remote player changes phase
signal new_remote_phase(player: int, phase: RMPhase)

## Emitted when the local client changes ready status
signal new_local_ready(value: bool)

## Emitted when a remote player changes ready status
signal new_remote_ready(player: int, value: bool)

## int : RMPhase
var player_to_phase : Dictionary = {}

## int : bool
var player_to_ready : Dictionary = {}

## StringName: RMPhase
var name_to_phase : Dictionary = {}

var _initialized : bool = false
func get_current_phase() -> RMPhase:
	var id := multiplayer.get_unique_id()
	return player_to_phase[id]

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	set_phases(phases)

func server_initialize(phase : Variant, ready : bool = false) -> bool:
	if not multiplayer.is_server():
		return false
	var _phase : RMPhase = find_phase(phase)
	player_to_phase[1] = _phase
	player_to_ready[1] = ready
	_initialized = true
	return true

func _process(delta: float) -> void:
	if multiplayer.is_server() and _initialized:
		var current_phase : RMPhase = player_to_phase[1]
		if current_phase.transition_method == RMPhase.TRANSITION_METHOD.AUTO:
			match current_phase.transition_condition:
				RMPhase.TRANSITION_CONDITION.CONSENSUS:
					if get_consensus():
						if current_phase.transition_target == "NONE":
							print_debug("Current phase '", current_phase.name,"' does not have a vaid transition target")
						else:
							set_phase(current_phase)
				_:
					pass
					#no other condition gets triggered like that
				

func get_consensus() -> bool:
	for client in player_to_ready.values():
		if not client:
			return false
	return true

func set_phases(value : Array[RMPhase]) -> void:
	phases = value
	name_to_phase = {}
	for phase in phases:
		if phase is RMPhase:
			name_to_phase[phase.name] = phases
		else:
			print_debug("Wrong type in phases: ", phase)

func _on_connected_to_server() -> void:
	pass
	
func _on_peer_connected(id : int) -> void:
	if multiplayer.is_server():
		client_receive_data.rpc_id(id, player_to_phase, player_to_ready)
	else:
		pass

@rpc("authority", "reliable", "call_local")
func client_receive_data(pp : Dictionary, pr: Dictionary) -> void:
	player_to_phase = pp
	player_to_ready = pr
	_initialized = true
	
func set_phase(phase : Variant) -> bool:
	var _phase := find_phase(phase)
	if multiplayer.is_server():
		var current_phase : RMPhase = player_to_phase[1]
		if current_phase.transition_method == RMPhase.TRANSITION_METHOD.AUTO:
			return false
		match current_phase.transition_condition:
			RMPhase.TRANSITION_CONDITION.AUTHORITY:
				server_set_phase_impl(_phase)
				return true
			RMPhase.TRANSITION_CONDITION.CONSENSUS_OR_AUTHORITY:
				server_set_phase_impl(_phase)
				return true
			RMPhase.TRANSITION_CONDITION.CONSENSUS_AND_AUTHORITY:
				if get_consensus():
					server_set_phase_impl(_phase)
					return true
				else:
					return false
			RMPhase.TRANSITION_CONDITION.CONSENSUS:
				return false
			_:
				assert(false, "Unsupported transition condition")
				return false
	else:
		return false

func find_phase(input : Variant) -> RMPhase:
	if input is String or input is StringName:
		if StringName(input) in name_to_phase:
			return name_to_phase[StringName(input)]
		return null
	elif input is RMPhase:
		return input
	print_debug("Invalid input: ", input)
	return null

func server_set_phase_impl(phase : RMPhase) -> void:
	if multiplayer.is_server():
		for player in player_to_phase.keys():
			assert(server_set_player_phase(player, phase))

func server_set_player_phase(player: int, phase : RMPhase) -> bool:
	var index : int = phases.find(phase)
	assert(index >= 0)
	client_set_player_phase.rpc(player, index)
	return index >= 0

@rpc("authority", "call_local", "reliable")	
func client_set_player_phase(player: int, index : int) -> void:
	assert(index >= 0)
	assert(index < phases.size())
	if player_to_phase[player] == phases[index]:
		#rejoining same phase causes the ready to reset
		player_to_ready[player] = false
	else:
		player_to_phase[player] = phases[index]
		player_to_ready[player] = false
		if player == multiplayer.get_unique_id():
			new_local_phase.emit(phases[index])
		else:
			new_remote_phase.emit(player, phases[index])

func set_ready(value : bool) -> void:
	var id := multiplayer.get_unique_id()
	server_set_client_ready.rpc(value)
	
@rpc("any_peer", "reliable", "call_local")
func server_set_client_ready(value : bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if value != player_to_ready[id]:
		player_to_ready[id] = value
		multicast_set_player_ready.rpc(id, value)
		
@rpc("authority", "reliable", "call_local")
func multicast_set_player_ready(id : int, value: bool) -> void:
	if value != player_to_ready[id]:
		player_to_ready[id] = value
		if id == multiplayer.get_unique_id():
			new_local_ready.emit(value)
		else:
			new_remote_ready.emit(id, value)
