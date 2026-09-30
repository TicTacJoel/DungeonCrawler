class_name SpellResolver
extends RefCounted

## Finds targets at a point via the spell's shape, runs every effect on
## each, then plays impact cosmetics. Shared by every delivery type so the
## "resolve + apply + play impact" loop only exists once.
static func resolve_at(caster: Node2D, spell: SpellData, point: Vector2, forward: Vector2) -> void:
	if spell.shape:
		var targets := spell.shape.get_targets(caster, point, forward)
		for target in targets:
			for effect in spell.effects:
				effect.apply(caster, target, point)
		_debug_flash(caster, spell.shape, point, forward)

	if spell.cosmetics:
		spell.cosmetics.play_impact(caster, point)

#------------------------------------------------------------------------------|
## With Debug > Visible Collision Shapes on, briefly draws every resolved
## shape — spell shapes are geometry queries the physics debug can't show.
static func _debug_flash(caster: Node2D, shape: SpellShape, point: Vector2, forward: Vector2) -> void:
	if not caster.is_inside_tree() or not caster.get_tree().debug_collisions_hint:
		return
	var flash := ShapeTelegraph.create(shape, point, forward)
	flash.color = Color(1.0, 0.9, 0.2)
	flash.progress = 1.0
	flash.lifetime = 0.4
	SpellDelivery.world_of(caster).add_child(flash)
