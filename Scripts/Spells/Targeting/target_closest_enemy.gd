class_name TargetingClosestEnemy
extends SpellTargeting

@export var group: String = "enemy"
@export var max_range: float = 500.0

func resolve(caster: Node2D) -> Vector2:
	var closest: Node2D = null
	var closest_dist := INF

	for node in caster.get_tree().get_nodes_in_group(group):
		if not node is Node2D:
			continue
		var dist := caster.global_position.distance_to(node.global_position)
		if dist < closest_dist and dist <= max_range:
			closest = node
			closest_dist = dist

	return closest.global_position if closest else caster.get_global_mouse_position()
