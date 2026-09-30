extends Control

var lobby_scene_path: String = Constants.PATH_MENU_LOBBY

#------------------------------------------------------------------------------|
func _on_singleplayer_btn_pressed() -> void:
	Globals.isSingleplayer = true
	Globals.isDebug = false
	
	get_tree().change_scene_to_file(lobby_scene_path)

#------------------------------------------------------------------------------|
func _on_debug_btn_pressed() -> void:
	Globals.isDebug = true
	Globals.isSingleplayer = true
	
	get_tree().change_scene_to_file(lobby_scene_path)

#------------------------------------------------------------------------------|
func _on_multiplayer_btn_pressed():
	Globals.isSingleplayer = false
	Globals.isDebug = false
	
	get_tree().change_scene_to_file(lobby_scene_path)

#------------------------------------------------------------------------------|
func _on_exit_btn_pressed():
	get_tree().quit()
