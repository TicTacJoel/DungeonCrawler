extends "res://Scenes/Actors/enemies/regular/enemy.gd"
class_name RangedCasterEnemy

## Keeps its distance and casts monster_data.spells[0] at the target instead
## of chasing into melee range. Re-uses the player spell pipeline directly —
## no bespoke "enemy projectile" code, just a SpellData resource whose shape
## targets the "player" group.

var _attack_cooldown: float = 0.0

#------------------------------------------------------------------------------|
func server_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	chase_target()

	animate_enemy()

	move_and_slide()

#------------------------------------------------------------------------------|
func chase_target() -> void:
	if not target:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)
		return

	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	var direction_normal: Vector2 = to_target.normalized()

	var retreat_range: float = monster_data.retreat_range if monster_data else 0.0
	var attack_range: float = monster_data.attack_range if monster_data else 200.0

	if retreat_range > 0.0 and distance < retreat_range:
		velocity = velocity.move_toward(-direction_normal * movement_speed, acceleration)
	elif distance > attack_range:
		velocity = velocity.move_toward(direction_normal * movement_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)

	var spell := _get_attack_spell()
	if spell and distance <= attack_range and _attack_cooldown <= 0.0:
		_attack_cooldown = spell.cooldown
		rpc_cast_spell.rpc(0, global_position, target.global_position)

#------------------------------------------------------------------------------|
func _get_attack_spell() -> SpellData:
	if monster_data and monster_data.spells.size() > 0:
		return monster_data.spells[0]
	return null
