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
	func serialize() -> Dictionary:
		return {'state': state,
			'team': team,
			'name': name,
			'id': id}
	static func deserialize(data : Dictionary) -> CPlayerInfo:
		var result := CPlayerInfo.new()
		result.state = data['state']
		result.team = data['team']
		result.name = data['name']
		result.id = data['id']
		return result

var state := GAME_STATE.NONE : set = set_state
signal state_changed()
func set_state(value : GAME_STATE) -> void:
	state = value
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
	
func _process(_delta: float) -> void:
	check_players_changed()
	copy_players_to_last_frame_players()
	if multiplayer.is_server():
		sync_game_state()

func sync_game_state() -> void:
	var data := {"state": state, "players": {}}
	for player in players:
		data["players"][player] = players[player].serialize()
	rpc_game_state.rpc(data)

@rpc("authority", "call_remote", "unreliable_ordered")
func rpc_game_state(data : Dictionary) -> void:
	state = data["state"]
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
