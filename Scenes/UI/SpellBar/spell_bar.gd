extends HBoxContainer

@export var spell_button_scene: PackedScene

var spell_buttons: Array[SpellButton] = []
var current_spells: Array[SpellData] = []
var local_player: Node = null

#------------------------------------------------------------------------------|
func _ready():
	add_to_group("spell_bar")
	print("Spellbar: Ready and waiting for setup")

#------------------------------------------------------------------------------|
func setup_spells(spells: Array[SpellData], player: Node = null):
	print("Spellbar: Setting up ", spells.size(), " spells")
	
	# Store player reference
	if player:
		local_player = player
		print("Spellbar: Stored player reference: ", player.owner_id)
	else: 
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			local_player = players[0]
			print("Spellbar: Found player in group: ", local_player.owner_id)
	
	# Clear existing buttons
	for button in spell_buttons:
		button.queue_free()
	spell_buttons.clear()
	
	current_spells = spells
	
	# Create buttons for each spell (max 4)
	for i in range(min(4, spells.size())):
		var spell_button = _create_spell_button(spells[i], i + 1)
		add_child(spell_button)
		spell_buttons.append(spell_button)
		print("Spellbar: Created button for spell ", spells[i].spell_name)

#------------------------------------------------------------------------------|
func _create_spell_button(spell: SpellData, hotkey: int) -> SpellButton:
	var button: SpellButton
	
	if spell_button_scene:
		button = spell_button_scene.instantiate()
	else:
		button = SpellButton.new()
	
	button.setup(spell, hotkey)
	button.spell_cast.connect(_on_spell_cast)
	
	return button

#------------------------------------------------------------------------------|
func _on_spell_cast(spell_index: int):
	if spell_index < 0 or spell_index >= current_spells.size():
		print("Spellbar: Invalid spell index ", spell_index)
		return
	
	if local_player and local_player.has_method("cast_spell"):
		local_player.cast_spell(spell_index)
		print("Spellbar: Cast spell ", spell_index, " (", current_spells[spell_index].spell_name, ")")
	else:
		print("Spellbar: No local player found to cast spell")

#------------------------------------------------------------------------------|
func start_cooldown(spell_index: int, cooldown_time: float):
	if spell_index >= 0 and spell_index < spell_buttons.size():
		spell_buttons[spell_index].start_cooldown(cooldown_time)

#------------------------------------------------------------------------------|
func _input(event):
	if event.is_action_pressed("spell_1"):
		_on_spell_cast(0)
	elif event.is_action_pressed("spell_2"):
		_on_spell_cast(1)
	elif event.is_action_pressed("spell_3"):
		_on_spell_cast(2)
	elif event.is_action_pressed("spell_4"):
		_on_spell_cast(3)
