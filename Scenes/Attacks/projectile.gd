extends Area2D

var speed: float = 100.0

var angle: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var caster: Node2D
var spell: SpellData
var has_hit: bool = false

signal remove_from_array(object)

#------------------------------------------------------------------------------|
func _ready() -> void:
	angle = global_position.direction_to(target)

	if spell and spell.cosmetics and spell.cosmetics.travel_sprite:
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.texture = spell.cosmetics.travel_sprite

#------------------------------------------------------------------------------|
func _physics_process(delta: float) -> void:
	position += angle * speed * delta

#------------------------------------------------------------------------------|
func _on_timer_timeout() -> void:
	emit_signal("remove_from_array", self)
	queue_free()

#------------------------------------------------------------------------------|
func _on_body_entered(_body: Node2D) -> void:
	if has_hit:
		return
	has_hit = true
	# The caster may have died (or its level been swapped out) while this was
	# in flight; the projectile itself then stands in as the source.
	var source: Node2D = caster if is_instance_valid(caster) else self
	SpellResolver.resolve_at(source, spell, global_position, angle)
	queue_free()
