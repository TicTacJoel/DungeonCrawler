class_name DeliveryPlaced
extends SpellDelivery

@export var area_scene: PackedScene = preload("res://Scenes/Attacks/spell_area.tscn")
@export var tick_interval: float = 1.0
@export var duration: float = 0.1
@export var initial_delay: float = 0.0

func execute(caster: Node2D, spell: SpellData, _origin: Vector2, target_point: Vector2) -> void:
	var area = area_scene.instantiate()
	area.caster = caster
	area.spell = spell
	area.target_point = target_point
	area.follow_caster = false
	area.tick_interval = tick_interval
	area.duration = duration
	area.initial_delay = initial_delay
	SpellDelivery.world_of(caster).add_child(area)
