extends Node
class_name CGameState

## This class is literally just data.
## @Me: Do not put methods in here, please
## To think about: should I use a synchronizer to auto synchronize this stuff?

enum GAME_STATE
{
	NONE,
	LOBBY,
	MAP_LOAD,
	PLAYING,
	END_SCREEN
}

enum PLAYER_STATE
{
	NONE,
	SPECTATING,
	PLANE,
	MOTORCYCLE,
}

enum PLAYER_TEAM
{
	NONE,
	A,
	B,
}

class CPlayerInfo:
	var state := PLAYER_STATE.NONE
	var team := PLAYER_TEAM.NONE
	var name : String = "CPlayerInfo default name"
	var id : int

var state := GAME_STATE.NONE : set = set_state
signal state_changed(new_value : GAME_STATE)
func set_state(value : GAME_STATE) -> void:
	state = value
	state_changed.emit(state)

## int : CPlayerInfo
var players : Dictionary = {} : set = set_players
signal players_changed(new_value : Dictionary)
func set_players(value : Dictionary) -> void:
	for key in value:
		assert(typeof(key) == TYPE_INT)
		assert(value[key] is CPlayerInfo)
	players = value
	players_changed.emit(players)
	
