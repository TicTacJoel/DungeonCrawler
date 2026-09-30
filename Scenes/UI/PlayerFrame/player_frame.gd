#------------------------------------------------------------------------------|
# Individual player frame class
class_name PlayerFrame
extends PanelContainer

var player_name_label: Label
var health_bar: ProgressBar
var class_icon: TextureRect
var class_data: ClassData

#------------------------------------------------------------------------------|
func _init():
	custom_minimum_size = Vector2(200, 60)
	
	# Create UI immediately
	_create_ui()

#------------------------------------------------------------------------------|
func _ready():
	pass
	# Create UI structure if not from scene
	#if get_child_count() == 0:
		#_create_ui()

#------------------------------------------------------------------------------|
func _create_ui():
	var hbox = HBoxContainer.new()
	add_child(hbox)
	
	# Icon
	class_icon = TextureRect.new()
	class_icon.custom_minimum_size = Vector2(48, 48)
	class_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	class_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(class_icon)
	
	# Nname + health bar
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	player_name_label = Label.new()
	player_name_label.text = "Player"
	vbox.add_child(player_name_label)
	
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(0, 20)
	health_bar.max_value = 100
	health_bar.value = 100
	vbox.add_child(health_bar)

#------------------------------------------------------------------------------|
func setup(p_name: String, p_class_data: ClassData):
	if not player_name_label:
		push_error("PlayerFrame: player_name_label is null!")
		return
	
	if not health_bar:
		push_error("PlayerFrame: health_bar is null!")
		return
	
	player_name_label.text = p_name
	class_data = p_class_data
	
	if class_icon and p_class_data.icon:
		class_icon.texture = p_class_data.icon
	
	# Set color based on class
	if health_bar:
		var style = StyleBoxFlat.new()
		style.bg_color = p_class_data.color
		health_bar.add_theme_stylebox_override("fill", style)
	
	health_bar.max_value = p_class_data.max_health
	health_bar.value = p_class_data.max_health
	
	print("PlayerFrame: Setup complete for ", p_name, " (", p_class_data.className, ")")

#------------------------------------------------------------------------------|
func update_health(current: float, maximum: float):
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		
		# Update color based on health percentage
		var percentage = current / maximum
		var color = class_data.color
		
		if percentage < 0.3:
			color = Color.RED
		elif percentage < 0.6:
			color = Color.ORANGE
		
		var style = StyleBoxFlat.new()
		style.bg_color = color
		health_bar.add_theme_stylebox_override("fill", style)
