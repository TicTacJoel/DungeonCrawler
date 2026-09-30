class_name DeliveryProjectile
extends SpellDelivery

@export var projectile_scene: PackedScene = preload("res://Scenes/Attacks/projectile.tscn")
@export var speed: float = 200.0
## By default a projectile stops (and resolves) on the first wall it hits.
## Enable for spells that are meant to fly through the environment.
@export var passes_through_walls: bool = false

const ENVIRONMENT_LAYER := 1

func execute(caster: Node2D, spell: SpellData, origin: Vector2, target_point: Vector2) -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = origin
	projectile.target = target_point
	projectile.speed = speed
	projectile.caster = caster
	projectile.spell = spell
	projectile.set_collision_mask_value(ENVIRONMENT_LAYER, not passes_through_walls)
	SpellDelivery.world_of(caster).add_child(projectile)
