extends CharacterBody2D
class_name Boss

## Simple state machine: chase until in range of an unlocked attack, telegraph
## it (stand still, flash a warning), then resolve it through the normal
## SpellData pipeline. `attacks` is deliberately a flat list gated by
## min_level rather than a separate boss-per-level scene — raising `level`
## (set by the dungeon generator) both scales stats via monster_data and
## unlocks later attacks in the list, so one Boss scene/scene-instance is
## reusable across dungeon depths.
##
## Networking (same model as Enemy): the server runs the state machine and
## owns `health`; the synchronizer replicates `sync_position`, `health` and
## the sprite flip. Telegraph start and attack execution are RPC'd with the
## locked aim, so every peer draws the same telegraph and resolves the same
## attack — each player's own peer then decides whether it was hit.

enum BossState {
	IDLE,
	CHASE,
	TELEGRAPH,
	ATTACKING,
	RECOVER,
	DEAD,
}

@export var monster_data: MonsterData
@export var level: int = 1
@export var attacks: Array[BossAttackData] = []
@export var acceleration: float = 8.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")

signal died(boss: Node)
signal health_changed(current: float, maximum: float)

var health: float = 100.0:
	set(value):
		health = value
		# Runs on clients too when the synchronizer updates it.
		if health_bar:
			health_bar.value = health
		health_changed.emit(health, max_health)
var max_health: float = 100.0
var damage: float = 10.0
var movement_speed: float = 80.0

var target: Node2D
var target_list: Array = []

var state: BossState = BossState.IDLE
var _state_timer: float = 0.0
var _pending_attack: BossAttackData
# Aim is locked when the telegraph starts, so moving out of the drawn area
# during the wind-up actually dodges the attack.
var _attack_origin: Vector2
var _attack_target: Vector2
var _telegraph: ShapeTelegraph
var _global_attack_cooldown: float = 0.0
## Server → clients position; clients interpolate toward it.
var sync_position: Vector2 = Vector2.INF

#------------------------------------------------------------------------------|
func _ready() -> void:
	_apply_monster_data()

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false

#------------------------------------------------------------------------------|
func _apply_monster_data() -> void:
	if not monster_data:
		max_health = health
		return
	max_health = monster_data.get_health(level)
	health = max_health
	damage = monster_data.get_damage(level)
	movement_speed = monster_data.get_movement_speed(level)

#------------------------------------------------------------------------------|
func _physics_process(delta: float) -> void:
	if state == BossState.DEAD:
		return

	if not multiplayer.is_server():
		global_position = HelperFunctions.ClientInterpolate(global_position, sync_position, delta)
		_update_telegraph(delta)
		return

	_global_attack_cooldown = maxf(0.0, _global_attack_cooldown - delta)

	match state:
		BossState.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration)
			if target:
				state = BossState.CHASE
		BossState.CHASE:
			_process_chase()
		BossState.TELEGRAPH:
			velocity = Vector2.ZERO
			_update_telegraph(delta)
			if _state_timer <= 0.0:
				rpc_execute_attack.rpc()
		BossState.ATTACKING:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration)
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = BossState.RECOVER
				_state_timer = 0.4
		BossState.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration)
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = BossState.CHASE if target else BossState.IDLE

	animate()
	move_and_slide()
	sync_position = global_position

#------------------------------------------------------------------------------|
func _update_telegraph(delta: float) -> void:
	if state != BossState.TELEGRAPH:
		return
	_state_timer -= delta
	if _telegraph and _pending_attack:
		_telegraph.progress = 1.0 - _state_timer / maxf(_pending_attack.telegraph_time, 0.01)

#------------------------------------------------------------------------------|
func _process_chase() -> void:
	if not target:
		state = BossState.IDLE
		return

	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	velocity = velocity.move_toward(to_target.normalized() * movement_speed, acceleration)

	if _global_attack_cooldown <= 0.0:
		var attack := _pick_attack(distance)
		if attack:
			var aim := global_position
			if not attack.is_self_centered:
				aim = target.global_position
			rpc_begin_telegraph.rpc(attacks.find(attack), global_position, aim)

#------------------------------------------------------------------------------|
func _pick_attack(distance: float) -> BossAttackData:
	var usable: Array[BossAttackData] = []
	for attack in attacks:
		if level < attack.min_level or not attack.spell:
			continue
		if attack.is_self_centered or distance <= attack.spell.cast_range:
			usable.append(attack)
	if usable.is_empty():
		return null
	return usable[randi() % usable.size()]

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "reliable")
func rpc_begin_telegraph(attack_index: int, origin: Vector2, aim: Vector2) -> void:
	if attack_index < 0 or attack_index >= attacks.size():
		return
	var attack := attacks[attack_index]
	_pending_attack = attack
	state = BossState.TELEGRAPH
	_state_timer = attack.telegraph_time
	velocity = Vector2.ZERO

	_clear_telegraph()
	_attack_origin = origin
	_attack_target = aim

	var shape := attack.spell.shape
	if shape:
		# Mirror DeliveryInstant: anchored shapes (cone/line) sit on the boss,
		# the rest on the aimed point.
		var at := _attack_origin if shape.is_caster_anchored() else _attack_target
		_telegraph = ShapeTelegraph.create(shape, at, _attack_target - _attack_origin)
		add_child(_telegraph)

	modulate = Color(1.6, 1.2, 1.2)

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "reliable")
func rpc_execute_attack() -> void:
	_clear_telegraph()
	modulate = Color.WHITE

	var attack := _pending_attack
	_pending_attack = null
	state = BossState.ATTACKING
	_state_timer = 0.2
	_global_attack_cooldown = attack.cooldown if attack else 2.0

	if not attack or not attack.spell:
		return

	if attack.spell.cosmetics:
		attack.spell.cosmetics.play_cast(self)

	attack.spell.delivery.execute(self, attack.spell, _attack_origin, _attack_target)

#------------------------------------------------------------------------------|
func _clear_telegraph() -> void:
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null

#------------------------------------------------------------------------------|
func animate() -> void:
	if velocity.x > 0.1:
		sprite.flip_h = true
	elif velocity.x < -0.1:
		sprite.flip_h = false

#------------------------------------------------------------------------------|
func _on_player_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_list.append(body)
		target = target_list.front()
		if health_bar:
			health_bar.visible = true

#------------------------------------------------------------------------------|
func _on_player_detect_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if target_list.has(body):
			target_list.erase(body)
		target = target_list.front() if not target_list.is_empty() else null

#------------------------------------------------------------------------------|
## Spell hits resolve on every peer; only the server's copy counts.
func take_damage(amount: int) -> void:
	if state == BossState.DEAD or not multiplayer.is_server():
		return

	health = maxf(0.0, health - amount)

	if health <= 0:
		rpc_die.rpc()
		return
	rpc_hit_flash.rpc()

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "unreliable")
func rpc_hit_flash() -> void:
	modulate = Color(10, 0, 0)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self) and state != BossState.DEAD:
		modulate = Color.WHITE

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "reliable")
func rpc_die() -> void:
	die()

#------------------------------------------------------------------------------|
func die() -> void:
	if state == BossState.DEAD:
		return
	state = BossState.DEAD
	health = 0.0
	_clear_telegraph()
	died.emit(self)
	if multiplayer.is_server():
		EventBus.spawn_loot_box.emit(global_position, 3)

	sprite.visible = false
	collision_shape.set_deferred("disabled", true)
	if health_bar:
		health_bar.visible = false

	await get_tree().create_timer(1.5).timeout

	queue_free()
