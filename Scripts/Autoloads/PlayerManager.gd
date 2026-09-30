extends Node

# Signals
signal player_added(player_id)
signal player_removed(player_id)
signal player_health_changed(player_id, current_health, max_health)

# Dictionary to track player data: { player_id: PlayerInfo }
var players_data: Dictionary = {}

# Local player's selected class
var local_player_class: ClassData.ClassType = ClassData.ClassType.WARRIOR

#------------------------------------------------------------------------------|
class PlayerInfo:
	var player_id: int
	var player_name: String
	var class_type: ClassData.ClassType
	var current_health: float
	var max_health: float
	var position: Vector2
	
	func _init(id: int, p_class: ClassData.ClassType):
		player_id = id
		player_name = "Player " + str(id)
		class_type = p_class
		var class_data = ClassData.get_class_by_type(p_class)
		max_health = class_data.max_health
		current_health = max_health

#------------------------------------------------------------------------------|
func register_player(player_id: int, class_type: ClassData.ClassType):
	if not players_data.has(player_id):
		players_data[player_id] = PlayerInfo.new(player_id, class_type)
		player_added.emit(player_id)
		print("PlayerManager: Registered player ", player_id, " as ", ClassData.get_class_by_type(class_type).className)

#------------------------------------------------------------------------------|
func unregister_player(player_id: int):
	if players_data.has(player_id):
		players_data.erase(player_id)
		player_removed.emit(player_id)
		print("PlayerManager: Unregistered player ", player_id)

#------------------------------------------------------------------------------|
func update_player_health(player_id: int, new_health: float):
	if players_data.has(player_id):
		players_data[player_id].current_health = clamp(new_health, 0, players_data[player_id].max_health)
		player_health_changed.emit(player_id, players_data[player_id].current_health, players_data[player_id].max_health)

#------------------------------------------------------------------------------|
func update_player_position(player_id: int, new_position: Vector2):
	if players_data.has(player_id):
		players_data[player_id].position = new_position

#------------------------------------------------------------------------------|
func get_player_info(player_id: int) -> PlayerInfo:
	if players_data.has(player_id):
		return players_data[player_id]
	return null

#------------------------------------------------------------------------------|
func get_all_players() -> Array:
	return players_data.values()

#------------------------------------------------------------------------------|
func clear_all_players():
	players_data.clear()
