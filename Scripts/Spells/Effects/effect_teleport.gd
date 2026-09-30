class_name EffectTeleport
extends SpellEffect

## Moves the target to the resolved point. Pair with a "self" shape and
## an appropriate targeting component (e.g. TargetingFacing) to blink the
## caster themselves.

## Physics layers the teleport can't pass (default: Environment). The target
## is swept from its position toward the point and stops at the first hit.
@export_flags_2d_physics var blocked_by: int = 1

func apply(_caster: Node, target: Node, point: Vector2) -> void:
	if target is Node2D:
		target.global_position = _furthest_reachable(target, point)

#------------------------------------------------------------------------------|
func _furthest_reachable(target: Node2D, point: Vector2) -> Vector2:
	if blocked_by == 0 or not target.is_inside_tree():
		return point

	var from := target.global_position
	var motion := point - from
	var space := target.get_world_2d().direct_space_state

	# Sweep the target's own collider so it can't end up half inside a wall.
	var collider := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider and collider.shape:
		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = collider.shape
		params.transform = collider.global_transform
		params.motion = motion
		params.collision_mask = blocked_by
		var fractions := space.cast_motion(params)
		var safe: float = fractions[0] if fractions.size() > 0 else 1.0
		return from + motion * safe

	var query := PhysicsRayQueryParameters2D.create(from, point, blocked_by)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return point
	return hit.position - motion.normalized() * 8.0
