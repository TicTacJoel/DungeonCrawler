class_name SpellCosmetics
extends Resource

@export var cast_sfx: AudioStream
@export var impact_sfx: AudioStream
@export var travel_sprite: Texture2D
@export var impact_particles: PackedScene
@export var cast_animation: StringName = &""
@export var screenshake_strength: float = 0.0
@export var screenshake_duration: float = 0.0

## Played once when the caster casts the spell, before delivery executes.
func play_cast(caster: Node2D) -> void:
	if cast_sfx:
		_play_sfx(caster, cast_sfx)
	if cast_animation != &"":
		var anim := caster.get_node_or_null("AnimatedSprite2D") as AnimationPlayer
		if anim and anim.has_animation(cast_animation):
			anim.play(cast_animation)

## Played once at the point a spell resolves against its targets.
func play_impact(caster: Node2D, point: Vector2) -> void:
	if impact_sfx:
		_play_sfx(caster, impact_sfx, point)
	if impact_particles:
		var fx := impact_particles.instantiate()
		fx.global_position = point
		SpellDelivery.world_of(caster).add_child(fx)
	if screenshake_strength > 0.0 and caster.has_method("camera_shake"):
		caster.camera_shake(screenshake_strength, screenshake_duration)

#------------------------------------------------------------------------------|
func _play_sfx(caster: Node2D, stream: AudioStream, at_point: Variant = null) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = at_point if at_point is Vector2 else caster.global_position
	SpellDelivery.world_of(caster).add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
