class_name SpellButton
extends Button

signal spell_cast(spell_index: int)

var spell_data: SpellData
var spell_index: int
var is_on_cooldown: bool = false

@onready var spell_icon: TextureRect = $Icon
@onready var hotkey_label: Label = $HotKeyLabel
@onready var cooldown_label: Label = $CooldownLabel
@onready var cooldown_clock: TextureProgressBar = $CooldownClock

#------------------------------------------------------------------------------|
func _ready() -> void:
	# Get references to children - they should exist if from scene
	cooldown_label = get_node_or_null("CooldownLabel")
	hotkey_label = get_node_or_null("HotKeyLabel")
	spell_icon = get_node_or_null("Icon")
	
	# Create them if they don't exist (for programmatic creation)
	if not hotkey_label:
		hotkey_label = Label.new()
		hotkey_label.name = "HotKeyLabel"
		hotkey_label.position = Vector2(4, 2)
		hotkey_label.add_theme_color_override("font_outline_color", Color.BLACK)
		hotkey_label.add_theme_constant_override("outline_size", 2)
		add_child(hotkey_label)
		move_child(hotkey_label, get_child_count() - 1)  # Move to front
	
	if not spell_icon:
		spell_icon = TextureRect.new()
		spell_icon.name = "Icon"
		spell_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		spell_icon.offset_left = 4
		spell_icon.offset_top = 4
		spell_icon.offset_right = -4
		spell_icon.offset_bottom = -4
		spell_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		spell_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(spell_icon)
	
	if not cooldown_label:
		cooldown_label = Label.new()
		cooldown_label.name = "CooldownLabel"
		cooldown_label.set_anchors_preset(Control.PRESET_CENTER)
		cooldown_label.add_theme_color_override("font_outline_color", Color.BLACK)
		cooldown_label.add_theme_constant_override("outline_size", 3)
		cooldown_label.add_theme_font_size_override("font_size", 20)
		cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(cooldown_label)
		move_child(cooldown_label, get_child_count() - 1)  # Move to front

#------------------------------------------------------------------------------|
func setup(spell: SpellData, hotkey: int):
	"""Setup button with specific spell depending on class and slot"""
	spell_data = spell
	spell_index = hotkey - 1
	
	# Set button properties
	custom_minimum_size = Vector2(64, 64)
	
	# Wait for _ready if children aren't available yet
	if not hotkey_label or not is_node_ready():
		await ready
	
	# Setup hotkey label
	if hotkey_label:
		hotkey_label.text = str(hotkey)
		print("SpellButton: Set hotkey to ", hotkey, " for ", spell.spell_name)
	else:
		push_error("SpellButton: hotkey_label still null after ready!")
	
	# Setup icon or colored background
	if spell.icon and spell_icon:
		spell_icon.texture = spell.icon
	elif spell_icon:
		# Create colored background for spell type
		var color_rect = ColorRect.new()
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_rect.offset_left = 4
		color_rect.offset_top = 4
		color_rect.offset_right = -4
		color_rect.offset_bottom = -4
		
		match spell.spell_type:
			SpellData.SpellType.DAMAGE:
				color_rect.color = Color(0.8, 0.2, 0.2)  # Red
			SpellData.SpellType.HEAL:
				color_rect.color = Color(0.2, 0.8, 0.2)  # Green
			SpellData.SpellType.BUFF:
				color_rect.color = Color(0.3, 0.3, 0.8)  # Blue
			SpellData.SpellType.DEBUFF:
				color_rect.color = Color(0.6, 0.2, 0.6)  # Purple
		
		spell_icon.add_child(color_rect)
	
	tooltip_text = spell.spell_name + "\nCooldown: " + str(spell.cooldown) + "s"
	
	pressed.connect(_on_pressed)

#------------------------------------------------------------------------------|
func _on_pressed():
	"""On spell button pressed"""
	if not is_on_cooldown:
		spell_cast.emit(spell_index)

#------------------------------------------------------------------------------|
func start_cooldown(cooldown_time: float):
	"""Start cooldown and set cooldown overlay visible"""
	if is_on_cooldown:
		return
	
	is_on_cooldown = true
	disabled = true
	
	if cooldown_clock:
		cooldown_clock.visible = true
		cooldown_clock.max_value = cooldown_time
		cooldown_clock.value = cooldown_time
	
	var tween = create_tween()
	
	# Animate clockwise wipe
	tween.tween_property(cooldown_clock, "value", 0.0, cooldown_time)
	# Animate text
	tween.parallel().tween_method(_update_cooldown_label, cooldown_time, 0.0, cooldown_time)
	# Reset on cooldown
	tween.finished.connect(_on_cooldown_finished)

#------------------------------------------------------------------------------|
func _update_cooldown_label(time_left: float):
	"""Update cooldown label"""
	if cooldown_label:
		cooldown_label.text = "%.1f" % time_left

#------------------------------------------------------------------------------|
func _on_cooldown_finished():
	"""Resets cooldown and sets invisible"""
	is_on_cooldown = false
	disabled = false
	if cooldown_clock:
		cooldown_clock.visible = false
	if cooldown_label:
		cooldown_label.text = ""
