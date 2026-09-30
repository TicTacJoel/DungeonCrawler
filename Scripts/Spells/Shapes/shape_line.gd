class_name ShapeLine
extends SpellShape

@export var length: float = 150.0
@export var width: float = 32.0

func get_targets(caster: Node2D, origin: Vector2, forward: Vector2) -> Array[Node]:
	var results: Array[Node] = []
	if affects_group == "self":
		return _resolve_self_or_targets(caster, results)

	var forward_dir := forward.normalized()
	var end_point := origin + forward_dir * length

	for node in caster.get_tree().get_nodes_in_group(affects_group):
		if node == caster or not node is Node2D:
			continue
		var closest_point := Geometry2D.get_closest_point_to_segment(node.global_position, origin, end_point)
		if closest_point.distance_to(node.global_position) <= width * 0.5:
			results.append(node)
	return results

func is_caster_anchored() -> bool:
	return true

func get_outline(forward: Vector2) -> PackedVector2Array:
	if affects_group == "self":
		return PackedVector2Array()
	var dir := forward.normalized() if not forward.is_zero_approx() else Vector2.DOWN
	var side := dir.orthogonal() * width * 0.5
	var tip := dir * length
	return PackedVector2Array([side, tip + side, tip - side, -side])
