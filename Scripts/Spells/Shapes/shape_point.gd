class_name ShapePoint
extends SpellShape

## How close a node must be to origin to count as "the point target".
@export var tolerance: float = 24.0

func get_targets(caster: Node2D, origin: Vector2, _forward: Vector2) -> Array[Node]:
	var results: Array[Node] = []
	if affects_group == "self":
		return _resolve_self_or_targets(caster, results)

	var closest: Node = null
	var closest_dist := tolerance
	for node in caster.get_tree().get_nodes_in_group(affects_group):
		if node == caster or not node is Node2D:
			continue
		var dist := origin.distance_to(node.global_position)
		if dist <= closest_dist:
			closest = node
			closest_dist = dist

	if closest:
		results.append(closest)
	return results

func get_outline(_forward: Vector2) -> PackedVector2Array:
	if affects_group == "self":
		return PackedVector2Array()
	return _circle_outline(tolerance, 16)
