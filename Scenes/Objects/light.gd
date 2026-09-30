extends Node2D

enum PresetLightColor {
	CUSTOM, 
	LIGHT_GREEN,
	DARK_GREEN,
	BLUE,
	PURPLE,
	PINK,
	YELLOW,
	ORANGE,
	RED
}

const LIGHT_COLORS = {
	PresetLightColor.LIGHT_GREEN:	Color(0.5, 0.8, 0.3),
	PresetLightColor.DARK_GREEN:	Color(0.3, 0.5, 0.2),
	PresetLightColor.BLUE:			Color(0.3, 0.5, 1.0),
	PresetLightColor.PURPLE:		Color(0.6, 0.0, 0.8),
	PresetLightColor.PINK:			Color(1.0, 0.8, 1.0),
	PresetLightColor.YELLOW:		Color(1.0, 1.0, 0.4),
	PresetLightColor.ORANGE:		Color(0.8, 0.4, 0.1),
	PresetLightColor.RED:			Color(0.8, 0.3, 0.3),
}

@export var light_color: PresetLightColor = PresetLightColor.ORANGE
@export_color_no_alpha var custom_color: Color = Color.WHITE

@onready var point_light_2d: PointLight2D = $PointLight2D

#------------------------------------------------------------------------------|
func _ready() -> void:
	apply_light_color()

#------------------------------------------------------------------------------|
func apply_light_color() -> void: 
	if light_color == PresetLightColor.CUSTOM:
		point_light_2d.color = custom_color
	else:
		point_light_2d.color = LIGHT_COLORS[light_color]
