class_name ShapeCircle
extends SpellShape

@export var radius: float = 80.0

func get_targets(caster: Node2D, origin: Vector2, _forward: Vector2) -> Array[Node]:
	var results: Array[Node] = []
	if affects_group == "self":
		return _resolve_self_or_targets(caster, results)

	for node in caster.get_tree().get_nodes_in_group(affects_group):
		if node == caster or not node is Node2D:
			continue
		if origin.distance_to(node.global_position) <= radius:
			results.append(node)
	return results

func get_outline(_forward: Vector2) -> PackedVector2Array:
	if affects_group == "self":
		return PackedVector2Array()
	return _circle_outline(radius)
