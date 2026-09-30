extends Node2D
class_name Room

## Base script for every dungeon room. DungeonGenerator instances one of
## these per grid cell, positions it, then calls open_side() for whichever
## directions actually connect to a neighboring room, and reads
## get_enemy_spawn_points()/get_player_spawn_points() to populate it. Room
## content (floor art, decorations) is placeholder blockout geometry — swap
## it for real tile art in the editor once the layout/flow feels right.
##
## Lookups below resolve nodes on demand via get_node_or_null() rather than
## caching in _ready(): the generator calls open_side()/get_*_spawn_points()
## on a room the same frame it instances it, before that room's own _ready()
## notification has had a chance to fire.

enum RoomType {
	ENTRANCE,
	GENERAL,
	BOSS,
	EXIT,
}

@export var room_type: RoomType = RoomType.GENERAL
## World-space footprint. The generator spaces rooms apart using this.
@export var room_size: Vector2 = Vector2(320, 192)
## Width of the gap carved into a wall by open_side(). Must match the
## corridor width the generator builds.
@export var door_width: float = 48.0

#------------------------------------------------------------------------------|
## Carves a doorway into the middle of the wall on `side`
## ("north"/"south"/"east"/"west") so an adjacent room can be walked into.
## The wall's single collider is swapped for two segments either side of
## the gap, so the rest of that side stays solid.
func open_side(side: String) -> void:
	var wall := get_node_or_null("Walls/" + side.capitalize())
	if not wall:
		return
	var collider := wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collider or not collider.shape is RectangleShape2D:
		return

	var size: Vector2 = collider.shape.size
	var vertical := size.y > size.x
	var length: float = size.y if vertical else size.x
	var thickness: float = size.x if vertical else size.y
	var segment_length: float = (length - door_width) / 2.0
	var offset: float = (door_width + segment_length) / 2.0

	for dir in [-1.0, 1.0]:
		var segment := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(thickness, segment_length) if vertical else Vector2(segment_length, thickness)
		segment.shape = shape
		segment.position = Vector2(0, dir * offset) if vertical else Vector2(dir * offset, 0)
		wall.add_child(segment)

	collider.queue_free()

#------------------------------------------------------------------------------|
func get_enemy_spawn_points() -> Array[Node2D]:
	return _collect_points("EnemySpawnPoints")

#------------------------------------------------------------------------------|
func get_player_spawn_points() -> Array[Node2D]:
	return _collect_points("PlayerSpawnPoints")

#------------------------------------------------------------------------------|
func _collect_points(container_name: String) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var container := get_node_or_null(container_name)
	if container:
		for child in container.get_children():
			if child is Node2D:
				result.append(child)
	return result
