extends Node2D
class_name DungeonGenerator

## Builds a small procedural dungeon: an entrance, `general_room_count`
## general rooms connected in a random walk (with backtracking so it can
## branch instead of dead-ending), an exit room, and a boss dropped into the
## room right before the exit.
##
## All peers must end up with the IDENTICAL layout since players share one
## world (enemies/rooms aren't networked the way players are — see
## enemy.gd). Rather than replicating room data, the server rolls a random
## seed and RPCs just that seed; every peer then runs the exact same
## deterministic generation locally from it.

signal generation_complete
signal exit_reached

@export var entrance_scene: PackedScene
@export var general_room_scene: PackedScene
@export var exit_room_scene: PackedScene

@export var general_room_count: int = 4
@export var room_spacing: Vector2 = Vector2(384, 224)

@export var enemy_scenes: Array[PackedScene] = []
@export var boss_scene: PackedScene
@export var dungeon_level: int = 1
@export var enemies_per_room: int = 3

var rooms: Dictionary = {} # Vector2i -> Room
var rng := RandomNumberGenerator.new()

#------------------------------------------------------------------------------|
func _ready() -> void:
	if multiplayer.multiplayer_peer == null:
		rng.randomize()
		generate()
		return

	if multiplayer.is_server():
		rpc("rpc_generate", randi())

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "reliable")
func rpc_generate(seed_value: int) -> void:
	rng.seed = seed_value
	generate()

#------------------------------------------------------------------------------|
func generate() -> void:
	var path: Array[Vector2i] = _build_path()
	_instance_rooms(path)
	_connect_rooms(path)
	_populate_rooms(path)
	generation_complete.emit()

#------------------------------------------------------------------------------|
func _build_path() -> Array[Vector2i]:
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var path: Array[Vector2i] = [Vector2i.ZERO]
	var occupied := {Vector2i.ZERO: true}
	var current := Vector2i.ZERO

	while path.size() < general_room_count + 1:
		var shuffled := _shuffled(directions)
		var moved := false
		for dir in shuffled:
			var next: Vector2i = current + dir
			if not occupied.has(next):
				occupied[next] = true
				path.append(next)
				current = next
				moved = true
				break
		if not moved:
			# Every neighbor of `current` is taken; branch off from a random
			# earlier room in the path instead of getting stuck.
			current = path[rng.randi_range(0, path.size() - 1)]

	return path

#------------------------------------------------------------------------------|
func _shuffled(arr: Array) -> Array:
	var result := arr.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result

#------------------------------------------------------------------------------|
func _instance_rooms(path: Array[Vector2i]) -> void:
	for i in path.size():
		var coord: Vector2i = path[i]
		var scene: PackedScene
		var room_type := Room.RoomType.GENERAL

		if i == 0:
			scene = entrance_scene
			room_type = Room.RoomType.ENTRANCE
		elif i == path.size() - 1:
			scene = exit_room_scene
			room_type = Room.RoomType.EXIT
		else:
			scene = general_room_scene
			room_type = Room.RoomType.GENERAL

		var room: Room = scene.instantiate()
		room.name = "Room_%d_%d" % [coord.x, coord.y]
		room.room_type = room_type
		room.position = Vector2(coord.x * room_spacing.x, coord.y * room_spacing.y)
		add_child(room)
		rooms[coord] = room

	# The room right before the exit doubles as the boss room.
	if path.size() >= 2:
		rooms[path[path.size() - 2]].room_type = Room.RoomType.BOSS

#------------------------------------------------------------------------------|
func _connect_rooms(path: Array[Vector2i]) -> void:
	for i in range(path.size() - 1):
		var a: Room = rooms[path[i]]
		var b: Room = rooms[path[i + 1]]
		var delta: Vector2i = path[i + 1] - path[i]
		a.open_side(_side_for_delta(delta))
		b.open_side(_side_for_delta(-delta))
		_build_corridor(i, a, b, delta)

#------------------------------------------------------------------------------|
## Bridges the gap between two adjacent rooms (room_spacing is larger than
## room_size) with a floor strip and a wall on each side, lined up with the
## doorways open_side() carved.
func _build_corridor(index: int, a: Room, b: Room, delta: Vector2i) -> void:
	var horizontal := delta.x != 0
	var length: float = (room_spacing.x - a.room_size.x) if horizontal else (room_spacing.y - a.room_size.y)
	if length <= 0.0:
		return

	var width: float = a.door_width
	var wall_thickness := 16.0

	var corridor := Node2D.new()
	corridor.name = "Corridor_%d" % index
	corridor.position = (a.position + b.position) / 2.0
	add_child(corridor)

	var floor_rect := ColorRect.new()
	var room_floor := a.get_node_or_null("Floor") as ColorRect
	floor_rect.color = room_floor.color if room_floor else Color(0.16, 0.13, 0.13)
	floor_rect.z_index = -10
	floor_rect.size = Vector2(length, width) if horizontal else Vector2(width, length)
	floor_rect.position = -floor_rect.size / 2.0
	corridor.add_child(floor_rect)

	var walls := StaticBody2D.new()
	walls.name = "Walls"
	corridor.add_child(walls)
	var side_offset: float = (width + wall_thickness) / 2.0
	for dir in [-1.0, 1.0]:
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(length, wall_thickness) if horizontal else Vector2(wall_thickness, length)
		collider.shape = shape
		collider.position = Vector2(0, dir * side_offset) if horizontal else Vector2(dir * side_offset, 0)
		walls.add_child(collider)

#------------------------------------------------------------------------------|
func _side_for_delta(delta: Vector2i) -> String:
	if delta == Vector2i.UP:
		return "north"
	if delta == Vector2i.DOWN:
		return "south"
	if delta == Vector2i.LEFT:
		return "west"
	return "east"

#------------------------------------------------------------------------------|
func _populate_rooms(path: Array[Vector2i]) -> void:
	var player_spawner := get_parent().get_node_or_null("PlayerSpawner")
	if player_spawner and rooms.has(path[0]):
		player_spawner.spawn_points = rooms[path[0]].get_player_spawn_points()

	for coord in path:
		var room: Room = rooms[coord]
		match room.room_type:
			Room.RoomType.GENERAL:
				_spawn_enemies(room)
			Room.RoomType.BOSS:
				_spawn_enemies(room)
				_spawn_boss(room)
			Room.RoomType.EXIT:
				var stairs := room.get_node_or_null("StairsArea")
				if stairs:
					stairs.stairs_activated.connect(_on_stairs_activated)
			_:
				pass

#------------------------------------------------------------------------------|
func _spawn_enemies(room: Room) -> void:
	var spawn_points := room.get_enemy_spawn_points()
	if enemy_scenes.is_empty() or spawn_points.is_empty():
		return
	# Cycle through a shuffled copy so enemies spread over the spawn points
	# instead of stacking on the same one.
	var shuffled_points := _shuffled(spawn_points)
	for i in enemies_per_room:
		var scene: PackedScene = enemy_scenes[rng.randi_range(0, enemy_scenes.size() - 1)]
		var enemy := scene.instantiate()
		# Explicit names keep node paths identical on every peer; Godot's
		# auto-generated "@Name@123" names for duplicates are not.
		enemy.name = "Enemy_%d" % i
		if "level" in enemy:
			enemy.level = dungeon_level
		room.add_child(enemy)
		var spawn: Node2D = shuffled_points[i % shuffled_points.size()]
		enemy.global_position = spawn.global_position

#------------------------------------------------------------------------------|
func _spawn_boss(room: Room) -> void:
	if not boss_scene:
		return
	var boss := boss_scene.instantiate()
	boss.name = "Boss"
	if "level" in boss:
		boss.level = dungeon_level
	room.add_child(boss)
	boss.global_position = room.global_position

#------------------------------------------------------------------------------|
func _on_stairs_activated() -> void:
	exit_reached.emit()
	get_parent().level_complete.emit()
