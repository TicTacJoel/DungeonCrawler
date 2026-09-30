extends MultiplayerSpawner

@export var spawn_points: Array[Node2D]

# Maps ClassType to the scene that should be spawned.
# apply_class_visuals() in player.gd swaps the texture at runtime, so
# sharing wizard.tscn as a base for classes without a dedicated scene is fine.
const CLASS_SCENES = {
	ClassData.ClassType.DRUID: Constants.PATH_SCENE_CLASS_DRUID,
	ClassData.ClassType.MAGE: Constants.PATH_SCENE_CLASS_MAGE,
	ClassData.ClassType.NECROMANCER: Constants.PATH_SCENE_CLASS_NECROMANCER,
	ClassData.ClassType.ROGUE: Constants.PATH_SCENE_CLASS_ROGUE,
}

var _loaded_scenes: Dictionary = {}
var next_spawn_point_index = 0


func _ready() -> void:
	for class_type in CLASS_SCENES:
		_loaded_scenes[class_type] = load(CLASS_SCENES[class_type])
	set_spawn_function(spawn_player)


func spawn_player(id: int) -> Node:
	var class_type = ClassData.ClassType.DRUID
	var player_info = PlayerManager.get_player_info(id)
	if player_info:
		class_type = player_info.class_type

	var scene: PackedScene = _loaded_scenes.get(class_type, _loaded_scenes[ClassData.ClassType.DRUID])
	var player_instance = scene.instantiate()
	player_instance.name = str(id)
	player_instance.global_position = get_spawn_point()
	return player_instance


func get_spawn_point() -> Vector2:
	# In the generated dungeon, spawn_points are filled in by DungeonGenerator
	# once the seed RPC arrives; a client can replicate a player spawn before
	# that. The player's synced position corrects it right after.
	if spawn_points.is_empty():
		return Vector2.ZERO
	var spawn_point = spawn_points[next_spawn_point_index].global_position
	next_spawn_point_index = wrapi(next_spawn_point_index + 1, 0, len(spawn_points))
	return spawn_point
