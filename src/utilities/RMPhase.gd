extends Resource
class_name RMPhase

@export var name : StringName = "Default"
@export var transition_method : TRANSITION_METHOD = TRANSITION_METHOD.MANUAL
@export var transition_condition : TRANSITION_CONDITION = TRANSITION_CONDITION.CONSENSUS
@export var transition_target : StringName = "NONE"

enum TRANSITION_METHOD
{
	MANUAL,
	AUTO,
}

enum TRANSITION_CONDITION
{
	CONSENSUS,
	AUTHORITY,
	CONSENSUS_OR_AUTHORITY,
	CONSENSUS_AND_AUTHORITY,
}

const LOBBY : StringName = "Lobby"
const MapLoad : StringName = "MapLoad"
const Playing : StringName = "Playing"
const RoundEnd : StringName = "RoundEnd"
const GameEnd : StringName = "GameEnd"
