extends Camera2D

var shake_strength: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

#------------------------------------------------------------------------------|
func camera_shake(strength: float, duration: float) -> void:
	# Take the stronger/longer of an overlapping shake rather than restarting
	shake_strength = max(shake_strength, strength)
	shake_duration = max(shake_duration, duration)
	shake_timer = max(shake_timer, duration)

#------------------------------------------------------------------------------|
func _process(delta: float) -> void:
	if shake_timer <= 0.0:
		offset = Vector2.ZERO
		return

	shake_timer -= delta
	var falloff := shake_timer / shake_duration if shake_duration > 0.0 else 0.0
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * falloff
