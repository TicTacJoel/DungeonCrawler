extends CharacterBody2D
class_name Enemy

## Optional re-usable stat block. When set, health/damage/speed/experience
## below are overwritten in _ready() with monster_data's stats scaled for
## `level`, so a single MonsterData resource can back any number of enemy
## scenes/instances. Leaving it empty keeps the old per-scene @export stats
## (e.g. GoblinSpear, which hasn't been switched over yet).
##
## Networking: the server is authoritative. Every peer instances the same
## enemy at the same node path (DungeonGenerator), but only the server runs
## AI, movement, damage and death. It replicates `sync_position`, `health`
## and the sprite flip via the MultiplayerSynchronizer; clients just
## interpolate. Attacks and deaths are RPC'd so every peer sees them.
@export var monster_data: MonsterData
@export var level: int = 1

@export var movement_speed: float = 100.0
@export var acceleration: float = 5
@export var health: int = 10
@export var experience: int = 1
@export var damage = 2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal remove_from_array(object)
signal died(enemy: Node)

var target: Node2D
var target_list: Array = []
var max_health: int = 10
var is_dead: bool = false
## Server → clients position; clients interpolate toward it.
var sync_position: Vector2 = Vector2.INF

#------------------------------------------------------------------------------|
func _ready() -> void:
	_apply_monster_data()

#------------------------------------------------------------------------------|
func _apply_monster_data() -> void:
	if not monster_data:
		max_health = health
		return
	health = int(round(monster_data.get_health(level)))
	max_health = health
	damage = int(round(monster_data.get_damage(level)))
	movement_speed = monster_data.get_movement_speed(level)
	experience = monster_data.get_experience(level)

#------------------------------------------------------------------------------|
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not multiplayer.is_server():
		global_position = HelperFunctions.ClientInterpolate(global_position, sync_position, delta)
		return

	server_process(delta)
	sync_position = global_position

#------------------------------------------------------------------------------|
## Server-only AI tick. Subclasses override this instead of _physics_process.
func server_process(_delta: float) -> void:
	chase_target()
	animate_enemy()
	move_and_slide()

#------------------------------------------------------------------------------|
func chase_target() -> void:
	if target:
		var distance_to_player: Vector2
		distance_to_player = target.global_position - global_position

		var direction_normal: Vector2 = distance_to_player.normalized()

		velocity = velocity.move_toward(direction_normal * movement_speed, acceleration)

#------------------------------------------------------------------------------|
func animate_enemy() -> void:
	var normal_velocity: Vector2 = velocity.normalized()

	if normal_velocity.x > 0.1:
		sprite.flip_h = true
		#animation_player.play("walk")
	elif normal_velocity.x < -0.1:
		sprite.flip_h = false
		#animation_player.play("walk")
	#else:
		#animation_player.stop()

#------------------------------------------------------------------------------|
func _on_player_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_list.append(body)
		if not target_list.is_empty():
			target = target_list.front()

#------------------------------------------------------------------------------|
func _on_player_detect_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if target_list.has(body):
			target_list.erase(body)

		if target_list.is_empty():
			target = null
			velocity = Vector2.ZERO
		else:
			target = target_list.front()

#------------------------------------------------------------------------------|
## Spell hits resolve on every peer (player casts are RPC'd call_local), so
## only the server's copy of the hit counts.
func take_damage(amount: int) -> void:
	if is_dead or not multiplayer.is_server():
		return

	health -= amount
	if health <= 0:
		rpc_die.rpc()
		return
	rpc_hit_flash.rpc()

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "unreliable")
func rpc_hit_flash() -> void:
	#play_damage_sfx()
	modulate = Color(10, 0, 0)

	await get_tree().create_timer(0.2).timeout

	if is_instance_valid(self):
		modulate = Color(1, 1, 1)

#------------------------------------------------------------------------------|
## Server decides to attack; every peer spawns the same projectile/effect.
## Damage to players is then applied by each player's own peer.
@rpc("authority", "call_local", "reliable")
func rpc_cast_spell(spell_index: int, origin: Vector2, target_point: Vector2) -> void:
	if not monster_data or spell_index >= monster_data.spells.size():
		return
	var spell: SpellData = monster_data.spells[spell_index]
	if spell.cosmetics:
		spell.cosmetics.play_cast(self)
	spell.delivery.execute(self, spell, origin, target_point)

#------------------------------------------------------------------------------|
#func play_damage_sfx() -> void:
	#damage_sfx.play()

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "reliable")
func rpc_die() -> void:
	die()

#------------------------------------------------------------------------------|
func die() -> void:
	if is_dead:
		return
	is_dead = true
	health = 0
	died.emit(self)

	sprite.visible = false
	collision_shape.set_deferred("disabled", true)

	await get_tree().create_timer(1).timeout

	queue_free()
