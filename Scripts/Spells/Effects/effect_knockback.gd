class_name EffectKnockback
extends SpellEffect

@export var force: float = 100.0

func apply(caster: Node, target: Node, _point: Vector2) -> void:
	if not (target is CharacterBody2D and caster is Node2D):
		return
	var direction: Vector2 = (target.global_position - caster.global_position).normalized()
	target.velocity += direction * force
