extends Node
class_name CGameState

## This class is literally just data.
## @Me: Do not put methods in here, please
## To think about: should I use a synchronizer to auto synchronize this stuff?
## Man to detect changes in dictionaries we gotta monitor it in process, which kinda sucks but whadda ya gonna do.

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
	func equals(other : CPlayerInfo) -> bool:
		return state == other.state and \
			team == other.team and \
			name == other.name and \
			id == other.id 
	func copy() -> CPlayerInfo:
		var result := CPlayerInfo.new()
		result.state = state
		result.team = team
		result.name = name
		result.id = id
		return result

var state := GAME_STATE.NONE : set = set_state
signal state_changed(new_value : GAME_STATE)
func set_state(value : GAME_STATE) -> void:
	state = value
	state_changed.emit(state)

## int : CPlayerInfo
var players : Dictionary = {} : set = set_players
var last_frame_players : Dictionary
signal players_changed()
func set_players(value : Dictionary) -> void:
	for key in value:
		assert(typeof(key) == TYPE_INT)
		assert(value[key] is CPlayerInfo)
	players = value
	players_changed.emit()
	
func _process(_delta: float) -> void:
	check_players_changed()
	copy_players_to_last_frame_players()
	
func check_players_changed() -> void:
	if players.size() != last_frame_players.size():
		players_changed.emit()
		return
	for id in players:
		if not id in last_frame_players:
			players_changed.emit()
			return
		if not players[id].equals(last_frame_players[id]):
			players_changed.emit()
			return

func copy_players_to_last_frame_players() -> void:
	last_frame_players = {}
	for id in players:
		last_frame_players[id] = players[id].copy()
