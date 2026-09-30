extends Area2D

## Generic delivery node backing both DeliveryAura (follow_caster = true)
## and DeliveryPlaced (follow_caster = false). Ticks SpellResolver on an
## interval at either the caster's live position or a fixed point.

var caster: Node2D
var spell: SpellData
var target_point: Vector2
var follow_caster: bool = false
var tick_interval: float = 1.0
var duration: float = 3.0
var initial_delay: float = 0.0

@onready var tick_timer: Timer = $TickTimer
@onready var duration_timer: Timer = $DurationTimer

#------------------------------------------------------------------------------|
func _ready() -> void:
	global_position = caster.global_position if follow_caster else target_point

	tick_timer.wait_time = tick_interval
	duration_timer.wait_time = duration

	if initial_delay > 0.0:
		await get_tree().create_timer(initial_delay).timeout
		if not is_instance_valid(self):
			return

	_tick()
	tick_timer.start()
	duration_timer.start()

#------------------------------------------------------------------------------|
func _process(_delta: float) -> void:
	if follow_caster and is_instance_valid(caster):
		global_position = caster.global_position

#------------------------------------------------------------------------------|
func _tick() -> void:
	if not is_instance_valid(caster):
		# An aura dies with its caster; a placed area keeps ticking on its own.
		if follow_caster:
			queue_free()
			return
		SpellResolver.resolve_at(self, spell, global_position, Vector2.DOWN)
		return
	SpellResolver.resolve_at(caster, spell, global_position, Vector2.DOWN)

#------------------------------------------------------------------------------|
func _on_tick_timer_timeout() -> void:
	_tick()

#------------------------------------------------------------------------------|
func _on_duration_timer_timeout() -> void:
	queue_free()
