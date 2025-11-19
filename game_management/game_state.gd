extends Node
class_name CGameState

## This class is literally just data.
## @Me: Do not put methods in here, please
## To think about: should I use a synchronizer to auto synchronize this stuff?
## Man to detect changes in dictionaries we gotta monitor it in process, which kinda sucks but whadda ya gonna do.

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

static var  N_ROUNDS_TO_WIN := 2

class CPlayerInfo:
	var state := PLAYER_STATE.NONE
	var team := PLAYER_TEAM.NONE
	var name : String = "CPlayerInfo"
	func equals(other : CPlayerInfo) -> bool:
		return state == other.state and \
			team == other.team and \
			name == other.name
	func copy() -> CPlayerInfo:
		var result := CPlayerInfo.new()
		result.state = state
		result.team = team
		result.name = name
		return result
	func serialize() -> Dictionary:
		return {'state': state,
			'team': team,
			'name': name,
			}
	static func deserialize(data : Dictionary) -> CPlayerInfo:
		var result := CPlayerInfo.new()
		result.state = data['state']
		result.team = data['team']
		result.name = data['name']
		return result

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

var round_wins := {PLAYER_TEAM.A : 0, PLAYER_TEAM.B: 0} : set = set_round_wins
signal round_wins_changed()
func set_round_wins(value : Dictionary) -> void:
	var emit := false
	if (value[PLAYER_TEAM.A] != round_wins[PLAYER_TEAM.A]) or (value[PLAYER_TEAM.B] != round_wins[PLAYER_TEAM.B]):
		emit = true
	round_wins = value
	if emit:
		round_wins_changed.emit()

func _process(_delta: float) -> void:
	check_players_changed()
	copy_players_to_last_frame_players()
	if multiplayer.is_server():
		sync_game_state()

func sync_game_state() -> void:
	var data := {
		"team_motorcycle": team_motorcycle,
		"team_plane": team_plane,
		"round_wins": round_wins,
		"players": {}
		}
	for player in players:
		data["players"][player] = players[player].serialize()
	rpc_game_state.rpc(data)

@rpc("authority", "call_remote", "unreliable_ordered")
func rpc_game_state(data : Dictionary) -> void:
	team_motorcycle = data["team_motorcycle"]
	team_plane = data['team_plane']
	round_wins = data['round_wins']
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
