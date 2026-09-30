class_name SpellShape
extends Resource

## Group filter for who counts as a target. The literal value "self" means
## "just the caster, no geometry check" (used by self-only spells).
@export var affects_group: String = "enemy"

## Returns the nodes affected by this spell at the given origin/forward.
func get_targets(_caster: Node2D, _origin: Vector2, _forward: Vector2) -> Array[Node]:
	push_error("SpellShape.get_targets() not implemented")
	return []

## true if the shape grows out of the caster (cone, line) rather than sitting
## on the aimed point (circle, point). Instant deliveries resolve anchored
## shapes at the caster's position and only use the aim for direction.
func is_caster_anchored() -> bool:
	return false

## The shape's area as a polygon relative to its origin, for telegraphs and
## debug drawing (see ShapeTelegraph). Empty when there's nothing to draw.
func get_outline(_forward: Vector2) -> PackedVector2Array:
	return PackedVector2Array()

## Shared "self" special-case so every shape subclass gets it for free.
func _resolve_self_or_targets(caster: Node2D, targets: Array[Node]) -> Array[Node]:
	if affects_group == "self":
		var result: Array[Node] = [caster]
		return result
	return targets

#------------------------------------------------------------------------------|
static func _circle_outline(radius: float, segments: int = 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		points.append(Vector2.from_angle(TAU * i / segments) * radius)
	return points
