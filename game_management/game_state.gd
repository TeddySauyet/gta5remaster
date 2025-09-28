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
	ROUND_END,
	END_SCREEN,
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
	var ready_for_game_start : bool = false
	var ready_for_map_start : bool = false
	func equals(other : CPlayerInfo) -> bool:
		return state == other.state and \
			team == other.team and \
			name == other.name and \
			ready_for_game_start == other.ready_for_game_start and \
			ready_for_map_start == other.ready_for_map_start
	func copy() -> CPlayerInfo:
		var result := CPlayerInfo.new()
		result.state = state
		result.team = team
		result.name = name
		result.ready_for_game_start = ready_for_game_start
		result.ready_for_map_start = ready_for_map_start
		return result
	func serialize() -> Dictionary:
		return {'state': state,
			'team': team,
			'name': name,
			'ready_for_game_start': ready_for_game_start,
			'ready_for_map_start': ready_for_map_start,
			}
	static func deserialize(data : Dictionary) -> CPlayerInfo:
		var result := CPlayerInfo.new()
		result.state = data['state']
		result.team = data['team']
		result.name = data['name']
		result.ready_for_game_start = data['ready_for_game_start']
		result.ready_for_map_start = data['ready_for_map_start']
		return result

var state := GAME_STATE.NONE : set = set_state
signal state_changed()
func set_state(value : GAME_STATE) -> void:
	var flag : bool = value != state
	state = value
	if flag:
		state_changed.emit()

## int : CPlayerInfo
var players : Dictionary = {} : set = set_players
var last_frame_players : Dictionary
signal players_changed()
func set_players(value : Dictionary) -> void:
	for key in value:
		assert(typeof(key) == TYPE_INT)
		assert(value[key] is CPlayerInfo)
	players = value
	#note: do this manually cause of dictionary operations
	#players_changed.emit()
	
var team_motorcycle := PLAYER_TEAM.A : set = set_team_motorcycle
signal team_motorcycle_changed()
func set_team_motorcycle(value : PLAYER_TEAM) -> void:
	var emit_signal = value != team_motorcycle
	team_motorcycle = value
	if emit_signal:
		team_motorcycle_changed.emit()

var team_plane := PLAYER_TEAM.B : set = set_team_plane
signal team_plane_changed()
func set_team_plane(value : PLAYER_TEAM) -> void:
	var emit_signal = value != team_plane
	team_plane = value
	if emit_signal:
		team_plane_changed.emit()
		
func _process(_delta: float) -> void:
	check_players_changed()
	copy_players_to_last_frame_players()
	if multiplayer.is_server():
		sync_game_state()

func sync_game_state() -> void:
	var data := {
		"state": state,
		"team_motorcycle": team_motorcycle,
		"team_plane": team_plane,
		"players": {}
		}
	for player in players:
		data["players"][player] = players[player].serialize()
	rpc_game_state.rpc(data)

@rpc("authority", "call_remote", "unreliable_ordered")
func rpc_game_state(data : Dictionary) -> void:
	state = data["state"]
	team_motorcycle = data["team_motorcycle"]
	team_plane = data['team_plane']
	var new_players := {}
	for player in data['players']:
		new_players[player] = CPlayerInfo.deserialize(data['players'][player])
	players = new_players

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
