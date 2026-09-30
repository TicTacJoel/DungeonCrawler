class_name DeliveryAura
extends SpellDelivery

@export var area_scene: PackedScene = preload("res://Scenes/Attacks/spell_area.tscn")
@export var tick_interval: float = 1.0
@export var duration: float = 3.0

func execute(caster: Node2D, spell: SpellData, _origin: Vector2, target_point: Vector2) -> void:
	var area = area_scene.instantiate()
	area.caster = caster
	area.spell = spell
	area.target_point = target_point
	area.follow_caster = true
	area.tick_interval = tick_interval
	area.duration = duration
	SpellDelivery.world_of(caster).add_child(area)
