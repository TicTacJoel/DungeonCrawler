class_name TargetingMouse
extends SpellTargeting

func resolve(caster: Node2D) -> Vector2:
	return caster.get_global_mouse_position()
