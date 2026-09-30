class_name EffectHeal
extends SpellEffect

@export var amount: float = 10.0

func apply(_caster: Node, target: Node, _point: Vector2) -> void:
	if target.has_method("heal"):
		target.heal(amount)
