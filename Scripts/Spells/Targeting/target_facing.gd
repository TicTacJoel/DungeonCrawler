class_name TargetingFacing
extends SpellTargeting

## Resolves to a point `distance` units ahead of the caster's last movement
## direction (falls back to facing down if the caster has never moved).
@export var distance: float = 150.0

func resolve(caster: Node2D) -> Vector2:
	var raw: Variant = caster.get("last_direction")
	var dir: Vector2 = raw if raw is Vector2 and raw != Vector2.ZERO else Vector2.DOWN
	return caster.global_position + dir.normalized() * distance
