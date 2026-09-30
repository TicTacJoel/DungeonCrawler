extends Node2D

@export var door_open: Sprite2D
@export var door_closed: Sprite2D
@export var collider: CollisionShape2D
@export var is_open: bool = false
@export var required_activators = 1

var current_activators = 0

func activate(state):
	if not multiplayer.is_server():
		return
	
	if state:
		current_activators += 1
	else:
		current_activators -= 1
	
	if current_activators >= required_activators:
		is_open = true
	else:
		is_open = false
	
	set_door_properties()

func set_door_properties():
	door_open.visible = is_open
	door_closed.visible = !is_open
	collider.set_deferred("disabled", is_open)

func _on_multiplayer_synchronizer_delta_synchronized():
	set_door_properties()
