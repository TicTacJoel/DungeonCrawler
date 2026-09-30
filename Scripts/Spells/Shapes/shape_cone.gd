class_name ShapeCone
extends SpellShape

@export var radius: float = 100.0
@export var angle_degrees: float = 60.0

func get_targets(caster: Node2D, origin: Vector2, forward: Vector2) -> Array[Node]:
	var results: Array[Node] = []
	if affects_group == "self":
		return _resolve_self_or_targets(caster, results)

	var forward_dir := forward.normalized()
	var half_angle_rad := deg_to_rad(angle_degrees * 0.5)

	for node in caster.get_tree().get_nodes_in_group(affects_group):
		if node == caster or not node is Node2D:
			continue
		var to_node: Vector2 = node.global_position - origin
		if to_node.length() > radius:
			continue
		if to_node.is_zero_approx():
			results.append(node)
			continue
		if absf(forward_dir.angle_to(to_node)) <= half_angle_rad:
			results.append(node)
	return results

func is_caster_anchored() -> bool:
	return true

func get_outline(forward: Vector2) -> PackedVector2Array:
	if affects_group == "self":
		return PackedVector2Array()
	var center_angle := forward.angle() if not forward.is_zero_approx() else PI / 2.0
	var half_angle_rad := deg_to_rad(angle_degrees * 0.5)
	var segments := 16
	var points := PackedVector2Array([Vector2.ZERO])
	for i in segments + 1:
		var a := center_angle - half_angle_rad + (2.0 * half_angle_rad) * i / segments
		points.append(Vector2.from_angle(a) * radius)
	return points
