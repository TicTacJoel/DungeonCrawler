class_name TargetingSelf
extends SpellTargeting

func resolve(caster: Node2D) -> Vector2:
	return caster.global_position
