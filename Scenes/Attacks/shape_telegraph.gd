extends Node2D
class_name ShapeTelegraph

## Draws a SpellShape's area on the floor so players can see an attack
## before it lands. `progress` (0..1) fills the shape from its origin
## outward — the boss drives it over the telegraph time. With `lifetime` > 0
## it instead fades out and frees itself (SpellResolver's debug flash).
##
## Spell shapes are pure geometry queries, not physics bodies, so this is
## the only way to see them — "Visible Collision Shapes" can't show them.

var outline: PackedVector2Array
var color: Color = Color(1.0, 0.15, 0.1)
var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var lifetime: float = 0.0

var _age: float = 0.0
var _alpha: float = 1.0

#------------------------------------------------------------------------------|
static func create(shape: SpellShape, at: Vector2, forward: Vector2) -> ShapeTelegraph:
	var telegraph := ShapeTelegraph.new()
	telegraph.outline = shape.get_outline(forward)
	# Positioned in world space regardless of parent, so it can hang off a
	# moving caster and still stay where the attack will land.
	telegraph.top_level = true
	telegraph.position = at
	telegraph.z_index = -5 # above the floor (-10), below actors
	return telegraph

#------------------------------------------------------------------------------|
func _process(delta: float) -> void:
	if lifetime <= 0.0:
		return
	_age += delta
	_alpha = 1.0 - _age / lifetime
	queue_redraw()
	if _age >= lifetime:
		queue_free()

#------------------------------------------------------------------------------|
func _draw() -> void:
	if outline.size() < 3:
		return

	var fill := color
	fill.a = 0.2 * _alpha
	draw_colored_polygon(outline, fill)

	if progress > 0.0:
		var inner := PackedVector2Array()
		for point in outline:
			inner.append(point * progress)
		fill.a = 0.35 * _alpha
		draw_colored_polygon(inner, fill)

	var edge := color
	edge.a = 0.8 * _alpha
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, edge, 1.0)
