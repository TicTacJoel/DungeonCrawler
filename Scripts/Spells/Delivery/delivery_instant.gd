class_name DeliveryInstant
extends SpellDelivery

func execute(caster: Node2D, spell: SpellData, origin: Vector2, target_point: Vector2) -> void:
	var forward := (target_point - origin)
	# Cones/lines sweep out from the caster toward the aim; resolving them at
	# the aim point would put the target at the apex and always hit it.
	var point := origin if spell.shape and spell.shape.is_caster_anchored() else target_point
	SpellResolver.resolve_at(caster, spell, point, forward)
