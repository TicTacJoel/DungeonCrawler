class_name SpellEffect
extends Resource

## Applies one action to a single target. `point` is the world position the
## spell resolved against (where the projectile hit, the instant cast's aim
## point, the aura's current tick position, ...) — most effects only need
## `target`, but point-based effects like teleport need it too.
func apply(_caster: Node, _target: Node, _point: Vector2) -> void:
	push_error("SpellEffect.apply() not implemented")
