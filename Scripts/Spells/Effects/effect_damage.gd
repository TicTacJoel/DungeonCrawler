class_name EffectDamage
extends SpellEffect

@export var amount: float = 10.0

func apply(_caster: Node, target: Node, _point: Vector2) -> void:
	if target.has_method("take_damage"):
		target.take_damage(amount)
