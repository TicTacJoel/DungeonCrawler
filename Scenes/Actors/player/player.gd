extends CharacterBody2D

@export var player_camera: PackedScene
@export var camera_height = 257
@export var player_finder: Node2D
@export var push_force = 10

@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimationPlayer = $AnimatedSprite2D

# Class data
var player_class_data: ClassData
var current_health: float
var max_health: float
var spells: Array[SpellData] = []
var knockback_strength: float = 10.0

# Movement
var movement_speed = 300
var direction = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
#@onready var initial_sprite_scale = player_sprite.scale

# Multiplayer
var owner_id = 1
var camera_instance
var state = PlayerState.IDLE
var current_interactable
@export var target_position: Vector2 = Vector2.INF

# Spell cooldowns
var spell_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]

# UI reference
var spell_bar_ui: Node = null

enum PlayerState {
	IDLE,
	WALKING,
	CASTING, 
}

#------------------------------------------------------------------------------|
func _enter_tree():
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)
	
	# Initialize class for all players
	# The class data comes from PlayerManager which was synced in lobby
	if PlayerManager.players_data.has(owner_id):
		var player_info = PlayerManager.get_player_info(owner_id)
		initialize_class(player_info.class_type)
		print("Player ", owner_id, " initialized from PlayerManager data")
	elif owner_id == multiplayer.get_unique_id():
		# Fallback for local player if not in manager yet
		initialize_class(PlayerManager.local_player_class)
		print("Player ", owner_id, " initialized from local_player_class")
	
	if owner_id != multiplayer.get_unique_id():
		return
	
	set_up_camera()

#------------------------------------------------------------------------------|
func _ready() -> void:
	print("Player ", owner_id, " _ready() called")
	
	# Wait a frame to ensure everything is initialized
	await get_tree().process_frame
	
	# Apply visual changes
	apply_class_visuals()
	
	# Get spellbar
	spell_bar_ui = get_tree().get_first_node_in_group("spell_bar")
	
	# Register this player in the manager (only if not already registered)
	if player_class_data and not PlayerManager.players_data.has(owner_id):
		PlayerManager.register_player(owner_id, player_class_data.class_type)
		PlayerManager.update_player_health(owner_id, current_health)
		print("Player ", owner_id, " registered with class ", player_class_data.className)
		
		# Sync class to all peers
		if owner_id == multiplayer.get_unique_id():
			rpc("sync_class_to_remote", player_class_data.class_type)
	elif PlayerManager.players_data.has(owner_id):
		# Just update health if already registered
		PlayerManager.update_player_health(owner_id, current_health)
		print("Player ", owner_id, " already registered, updating health only")
	else:
		print("Player ", owner_id, " has no class data!")
	
	# Add to local_player group if this is our player
	if owner_id == multiplayer.get_unique_id():
		add_to_group("player")
		print("Player ", owner_id, " added to player group")
		
		# Set up spell bar directly
		await get_tree().create_timer(0.1).timeout
		var spell_bar = get_tree().get_first_node_in_group("spell_bar")
		if spell_bar and spells.size() > 0:
			spell_bar.setup_spells(spells, self)
			print("Player ", owner_id, " set up spell bar with ", spells.size(), " spells")

#------------------------------------------------------------------------------|
func _process(delta) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	
	# Update spell cooldowns
	for i in range(spell_cooldowns.size()):
		if spell_cooldowns[i] > 0:
			spell_cooldowns[i] = max(0, spell_cooldowns[i] - delta)
	
	# Check if this is not me
	if owner_id != multiplayer.get_unique_id():
		global_position = HelperFunctions.ClientInterpolate(global_position, target_position, delta)
		# current_health arrives through the synchronizer; mirror it for the party frames.
		PlayerManager.update_player_health(owner_id, current_health)
		return
	
	update_camera_pos()
	
	# Update player manager
	PlayerManager.update_player_position(owner_id, global_position)
	PlayerManager.update_player_health(owner_id, current_health)

#------------------------------------------------------------------------------|
func _physics_process(_delta) -> void:
	if owner_id != multiplayer.get_unique_id():
		return
	
	#if Input.is_action_just_pressed("interact"):
		#cast_spell(0) # Default first spell
	
	input_move()
	
	target_position = global_position
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var pushable = collision.get_collider() as PushableObject
		if pushable == null:
			continue
		var point = collision.get_position() - pushable.global_position
		pushable.push(-collision.get_normal() * push_force, point)
	
	#face_movement_direction(horizontal_input)

#------------------------------------------------------------------------------|
func initialize_class(class_type: ClassData.ClassType):
	print("Player ", owner_id, " initializing class: ", class_type)
	
	player_class_data = ClassData.get_class_by_type(class_type)
	
	# Set stats from class
	max_health = player_class_data.max_health
	current_health = max_health
	movement_speed = player_class_data.movement_speed
	spells = player_class_data.spells

	print("Player ", owner_id, " loaded ", spells.size(), " spells")

#------------------------------------------------------------------------------|
func apply_class_visuals():
	"""Apply class-specific visual changes (skin)"""
	if not player_class_data:
		return
	
	# Apply skin to sprite
	if sprite:
		if player_class_data.skin:
			sprite.texture = player_class_data.skin
			print("Player ", owner_id, " applied skin for ", player_class_data.className)

	# Apply class icon to the player finder marker
	if player_finder and player_class_data.icon:
		player_finder.set_class_icon(player_class_data.icon)

#------------------------------------------------------------------------------|
@rpc("any_peer", "call_local")
func sync_class(class_type: ClassData.ClassType):
	initialize_class(class_type)

#------------------------------------------------------------------------------|
@rpc("any_peer", "call_local", "reliable")
func sync_class_to_remote(class_type: ClassData.ClassType):
	# Remote players receive this and ensure they have the class data
	if owner_id != multiplayer.get_unique_id() and not player_class_data:
		initialize_class(class_type)
		print("Player ", owner_id, " received class sync: ", class_type)

#------------------------------------------------------------------------------|
func input_move() -> void:
	# Get speed and direction
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * movement_speed
	
	# Play animation
	if velocity.x != 0 or velocity.y != 0:
		animated_sprite.play("walk")
	else: 
		animated_sprite.play("idle")
	
	# Turn sprite
	if velocity.x > 0: # Right
		sprite.flip_h = false
	elif velocity.x < 0: # Left
		sprite.flip_h = true

	# Track last movement direction for facing-based spells (blink, etc.),
	# independent of sprite flipping so it also updates on vertical-only movement
	if direction != Vector2.ZERO:
		last_direction = direction

	move_and_slide()

#------------------------------------------------------------------------------|
func cast_spell(spell_index: int):
	# Check if spell slot exists
	if spell_index < 0 or spell_index >= spells.size():
		return

	# Check cooldown
	if spell_cooldowns[spell_index] > 0:
		return

	var spell = spells[spell_index]

	# Start cooldown
	spell_cooldowns[spell_index] = spell.cooldown
	if spell_bar_ui:
		spell_bar_ui.start_cooldown(spell_index, spell.cooldown)

	var target_point = spell.targeting.resolve(self)
	rpc("rpc_cast_spell", spell_index, global_position, target_point)

#------------------------------------------------------------------------------|
@rpc("authority", "call_local")
func rpc_cast_spell(spell_index: int, origin: Vector2, target_point: Vector2):
	var spell = spells[spell_index]
	if spell.cosmetics:
		spell.cosmetics.play_cast(self)
	spell.delivery.execute(self, spell, origin, target_point)

#------------------------------------------------------------------------------|
func handle_movement_state() -> void:
	# Decide State
	if is_zero_approx(velocity.x):
		state = PlayerState.IDLE
	elif not is_zero_approx(velocity.x):
		state = PlayerState.WALKING

	# Process State
	match state:
		PlayerState.IDLE:
			pass
			#player_sprite.play("idle")
		PlayerState.WALKING:
			pass
			#player_sprite.play("walk")

#------------------------------------------------------------------------------|
## Hits resolve on every peer (enemy/boss attacks are RPC'd to all), but only
## the owning peer applies them: it sees the player's true position, so a
## dodge on your own screen is a dodge. current_health is then synced.
func take_damage(amount: int) -> void:
	if not is_multiplayer_authority():
		return
	current_health = max(0, current_health - amount)
	PlayerManager.update_player_health(owner_id, current_health)
	
	if current_health <= 0:
		die()
	
	# Flash white when taking damage
	var flash_white_color: Color = Color(50, 50, 50)
	modulate = flash_white_color
	
	await get_tree().create_timer(0.2).timeout
	
	var original_color: Color = Color(1, 1, 1)
	modulate = original_color

#------------------------------------------------------------------------------|
func heal(amount: float):
	if not is_multiplayer_authority():
		return
	current_health = min(max_health, current_health + amount)
	PlayerManager.update_player_health(owner_id, current_health)

#------------------------------------------------------------------------------|
func die() -> void:
	print("Player died!")
	
	# TODO: implement respawn system
	
	#animation_player.play("death")
	#await get_tree().create_timer(1.0).timeout
	
	#queue_free()

#------------------------------------------------------------------------------|
func set_up_camera() -> void:
	camera_instance = player_camera.instantiate()
	#camera_instance.global_position.y = camera_height
	get_parent().add_child.call_deferred(camera_instance)

#------------------------------------------------------------------------------|
func update_camera_pos() -> void:
	camera_instance.global_position.x = global_position.x
	camera_instance.global_position.y = global_position.y

#------------------------------------------------------------------------------|
func camera_shake(strength: float, duration: float) -> void:
	# Remote replicas of other players have no camera_instance of their own
	if camera_instance:
		camera_instance.camera_shake(strength, duration)

#------------------------------------------------------------------------------|
func _on_interaction_handler_area_entered(area) -> void:
	current_interactable = area

#------------------------------------------------------------------------------|
func _on_interaction_handler_area_exited(area) -> void:
	if current_interactable == area:
		current_interactable = null

#------------------------------------------------------------------------------|
func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if player_finder:
		player_finder.visible = false

#------------------------------------------------------------------------------|
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if player_finder:
		player_finder.visible = true

#------------------------------------------------------------------------------|
func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"): 
		take_damage(body.damage)

#------------------------------------------------------------------------------|
func _on_sword_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	
	var distance_to_enemy: Vector2 = body.global_position - global_position
	var knockback_direction: Vector2 = distance_to_enemy.normalized()
	
	body.velocity += knockback_direction * knockback_strength
	
	body.take_damage()
