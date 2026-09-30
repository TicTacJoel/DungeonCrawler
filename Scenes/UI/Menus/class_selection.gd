extends Control

signal class_selected(class_type: ClassData.ClassType)

@onready var druid_button: Button = $Panel/MarginContainer/VBoxContainer/ClassGrid/DruidButton
@onready var hunter_button: Button = $Panel/MarginContainer/VBoxContainer/ClassGrid/HunterButton
@onready var mage_button: Button = $Panel/MarginContainer/VBoxContainer/ClassGrid/MageButton
@onready var necromancer_button: Button = $Panel/MarginContainer/VBoxContainer/ClassGrid/NecromancerButton
@onready var priest_button: Button = $Panel/MarginContainer/VBoxContainer/ClassGrid/PriestButton
@onready var rogue_button: Button = $Panel/MarginContainer/VBoxContainer/ClassGrid/RogueButton
@onready var warrior_button: Button = $Panel/MarginContainer/VBoxContainer/ClassGrid/WarriorButton

@onready var confirm_button: Button = $Panel/MarginContainer/VBoxContainer/ConfirmButton
@onready var description: Label = $Panel/MarginContainer/VBoxContainer/Description

var selected_class: ClassData.ClassType = ClassData.ClassType.WARRIOR

#------------------------------------------------------------------------------|
func _ready():
	# Class buttons
	druid_button.pressed.connect(_on_class_button_pressed.bind(ClassData.ClassType.DRUID))
	hunter_button.pressed.connect(_on_class_button_pressed.bind(ClassData.ClassType.HUNTER))
	mage_button.pressed.connect(_on_class_button_pressed.bind(ClassData.ClassType.MAGE))
	necromancer_button.pressed.connect(_on_class_button_pressed.bind(ClassData.ClassType.NECROMANCER))
	priest_button.pressed.connect(_on_class_button_pressed.bind(ClassData.ClassType.PRIEST))
	rogue_button.pressed.connect(_on_class_button_pressed.bind(ClassData.ClassType.ROGUE))
	warrior_button.pressed.connect(_on_class_button_pressed.bind(ClassData.ClassType.WARRIOR))
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# Set initial selection
	_update_class_description(ClassData.ClassType.WARRIOR)

# TODO: create buttons dynamically

#------------------------------------------------------------------------------|
func _on_class_button_pressed(class_type: ClassData.ClassType):
	selected_class = class_type
	_update_class_description(class_type)
	
	# Visual feedback - highlight selected button
	_reset_button_styles()
	match class_type:
		ClassData.ClassType.DRUID:
			druid_button.modulate = ClassData.ClassColors.druid_color
		ClassData.ClassType.HUNTER:
			hunter_button.modulate = ClassData.ClassColors.hunter_color
		ClassData.ClassType.MAGE:
			mage_button.modulate = ClassData.ClassColors.mage_color
		ClassData.ClassType.NECROMANCER:
			necromancer_button.modulate = ClassData.ClassColors.necromancer_color
		ClassData.ClassType.PRIEST:
			priest_button.modulate = ClassData.ClassColors.priest_color
		ClassData.ClassType.ROGUE:
			rogue_button.modulate = ClassData.ClassColors.rogue_color
		ClassData.ClassType.WARRIOR:
			warrior_button.modulate = ClassData.ClassColors.warrior_color

#------------------------------------------------------------------------------|
func _reset_button_styles():
	druid_button.modulate = Color.WHITE
	hunter_button.modulate = Color.WHITE
	mage_button.modulate = Color.WHITE
	necromancer_button.modulate = Color.WHITE
	priest_button.modulate = Color.WHITE
	rogue_button.modulate = Color.WHITE
	warrior_button.modulate = Color.WHITE

#------------------------------------------------------------------------------|
func _update_class_description(class_type: ClassData.ClassType):
	var class_data = ClassData.get_class_by_type(class_type)
	var role = ""
	
	match class_type:
		ClassData.ClassType.DRUID:
			role = "Healer - Allrounder"
		ClassData.ClassType.HUNTER:
			role = "Damage Dealer - Powerful ranged attacks, low health"
		ClassData.ClassType.MAGE:
			role = "Damage Dealer - Powerful spells, low health"
		ClassData.ClassType.NECROMANCER:
			role = "Damage Dealer - Powerful spells, low health"
		ClassData.ClassType.PRIEST:
			role = "Healer - Keeps the team alive"
		ClassData.ClassType.ROGUE:
			role = "Damage Dealer - Fast attacks, high mobility"
		ClassData.ClassType.WARRIOR:
			role = "Tank - High health, protects the team"
	
	description.text = class_data.className + "\n" + role + "\nHealth: " + str(class_data.max_health) + "\nSpeed: " + str(class_data.movement_speed)

#------------------------------------------------------------------------------|
func _on_confirm_pressed():
	PlayerManager.local_player_class = selected_class
	class_selected.emit(selected_class)
	hide()
