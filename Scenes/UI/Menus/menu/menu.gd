extends Node

@export var ui: Control
@export var level_container: Node
@export var level_scene: PackedScene
@export var ip_line_edit: LineEdit
@export var status_label: Label
@export var not_connected_hbox: HBoxContainer
@export var host_hbox: HBoxContainer
@export var class_selection_ui: Control
@export var lobby_players_list: VBoxContainer

@onready var startButton = $UI/HostHBox/StartButton

# Simple tracking - just IDs of connected players
var connected_players: Array[int] = []

#------------------------------------------------------------------------------|
func _ready():
	if Globals.isSingleplayer:
		not_connected_hbox.visible = false
		var my_id = multiplayer.get_unique_id()
		connected_players.append(my_id)
		_refresh_lobby_list()

		if Globals.isDebug:
			_on_class_selected(ClassData.ClassType.MAGE)
	
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	startButton.disabled = true
	
	# Setup class selection
	if class_selection_ui:
		class_selection_ui.class_selected.connect(_on_class_selected)
		class_selection_ui.hide()
	
	# Connect to PlayerManager signals
	PlayerManager.player_added.connect(_on_player_registered)
	PlayerManager.player_removed.connect(_on_player_unregistered)

#------------------------------------------------------------------------------|
func _on_host_button_pressed():
	not_connected_hbox.hide()
	startButton.disabled = true
	Lobby.create_game()
	status_label.text = "Hosting!"
	
	# Add host to connected players
	var host_id = multiplayer.get_unique_id()
	if not connected_players.has(host_id):
		connected_players.append(host_id)
	
	_refresh_lobby_list()

#------------------------------------------------------------------------------|
func _on_join_button_pressed():
	not_connected_hbox.hide()
	Lobby.join_game(ip_line_edit.text)
	status_label.text = "Connecting..."

#------------------------------------------------------------------------------|
func _on_connected_to_server():
	status_label.text = "Connected!"
	
	# Add self to connected players
	var my_id = multiplayer.get_unique_id()
	if not connected_players.has(my_id):
		connected_players.append(my_id)
	
	# Notify server we connected
	rpc_id(1, "notify_player_connected", my_id)

#------------------------------------------------------------------------------|
@rpc("any_peer", "call_local")
func notify_player_connected(player_id: int):
	if not connected_players.has(player_id):
		connected_players.append(player_id)
		print("Player ", player_id, " joined lobby")
		_refresh_lobby_list()

#------------------------------------------------------------------------------|
func _on_class_selected(class_type: ClassData.ClassType) -> void:
	# Store in PlayerManager (single source of truth)
	PlayerManager.local_player_class = class_type
	
	var my_id = multiplayer.get_unique_id()
	
	# Register in PlayerManager (this triggers player_added signal)
	PlayerManager.register_player(my_id, class_type)
	
	# Sync to all peers
	rpc("sync_player_class", my_id, class_type)

#------------------------------------------------------------------------------|
@rpc("any_peer", "call_local")
func sync_player_class(player_id: int, class_type: ClassData.ClassType):
	# Register in PlayerManager on all clients
	if not PlayerManager.players_data.has(player_id):
		PlayerManager.register_player(player_id, class_type)
	
	_refresh_lobby_list()
	_update_start_button()

#------------------------------------------------------------------------------|
func _on_player_registered(player_id: int):
	# PlayerManager signal - player selected class
	_refresh_lobby_list()
	_update_start_button()

#------------------------------------------------------------------------------|
func _on_player_unregistered(player_id: int):
	# PlayerManager signal - player left
	_refresh_lobby_list()
	_update_start_button()

#------------------------------------------------------------------------------|
func _on_peer_connected(id: int):
	print("Player connected: ", id)
	
	# Add to connected players
	if not connected_players.has(id):
		connected_players.append(id)
	
	# Notify all clients
	rpc("notify_player_connected", id)
	
	# Send current state to new player
	if multiplayer.is_server():
		# Send all registered players (who selected classes)
		for player_id in PlayerManager.players_data.keys():
			var player_info = PlayerManager.get_player_info(player_id)
			rpc_id(id, "sync_player_class", player_id, player_info.class_type)

#------------------------------------------------------------------------------|
func _on_peer_disconnected(id: int):
	print("Player disconnected: ", id)
	
	# Remove from connected players
	if connected_players.has(id):
		connected_players.erase(id)
	
	# Remove from PlayerManager
	PlayerManager.unregister_player(id)
	
	# Notify all clients
	rpc("notify_player_disconnected", id)

#------------------------------------------------------------------------------|
@rpc("any_peer", "call_local")
func notify_player_disconnected(player_id: int):
	if connected_players.has(player_id):
		connected_players.erase(player_id)
	
	PlayerManager.unregister_player(player_id)
	
	_refresh_lobby_list()
	_update_start_button()

#------------------------------------------------------------------------------|
func _refresh_lobby_list():
	if not lobby_players_list:
		return
	
	# Clear existing list
	for child in lobby_players_list.get_children():
		child.queue_free()
	
	# Show all connected players
	for player_id in connected_players:
		var player_entry = HBoxContainer.new()
		player_entry.custom_minimum_size = Vector2(0, 40)
		
		# Player info label
		var label = Label.new()
		var player_name = "Player " + str(player_id)
		if player_id == multiplayer.get_unique_id():
			player_name += " (You)"
		
		# Check if player has selected class (registered in PlayerManager)
		var player_info = PlayerManager.get_player_info(player_id)
		if player_info:
			# Has selected class
			var class_data = ClassData.get_class_by_type(player_info.class_type)
			label.text = player_name + " - " + class_data.className
			label.modulate = class_data.color
		else:
			# Still selecting
			label.text = player_name + " - Selecting class..."
			label.modulate = Color.GRAY
		
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_entry.add_child(label)
		
		# Kick button (only for server and not for self)
		if multiplayer.is_server() and player_id != multiplayer.get_unique_id():
			var kick_button = Button.new()
			kick_button.text = "Kick"
			kick_button.custom_minimum_size = Vector2(60, 0)
			kick_button.pressed.connect(_on_kick_player_pressed.bind(player_id))
			player_entry.add_child(kick_button)
		
		lobby_players_list.add_child(player_entry)

#------------------------------------------------------------------------------|
func _update_start_button():
	if not multiplayer.is_server():
		return
	
	# Check if all connected players have selected a class
	var all_ready = true
	var player_count = connected_players.size()
	
	if player_count == 0:
		all_ready = false
	else:
		for player_id in connected_players:
			# Check if player is registered in PlayerManager (has selected class)
			if not PlayerManager.players_data.has(player_id):
				all_ready = false
				break
	
	startButton.disabled = not all_ready
	
	if all_ready:
		status_label.text = "All players ready! (" + str(player_count) + " players)"
	else:
		status_label.text = "Waiting for players to select classes..."

#------------------------------------------------------------------------------|
func _on_kick_player_pressed(player_id: int):
	if not multiplayer.is_server():
		return
	
	print("Kicking player ", player_id)
	
	# Notify the player they're being kicked
	rpc_id(player_id, "kicked_from_lobby")
	
	# Remove from our lists
	connected_players.erase(player_id)
	PlayerManager.unregister_player(player_id)
	
	# Disconnect them
	multiplayer.multiplayer_peer.disconnect_peer(player_id)
	
	# Notify all clients
	rpc("notify_player_disconnected", player_id)

#------------------------------------------------------------------------------|
@rpc("authority", "call_remote")
func kicked_from_lobby():
	status_label.text = "You were kicked from the lobby"
	
	# Disconnect
	multiplayer.multiplayer_peer.close()
	
	# Show connection UI again
	not_connected_hbox.show()
	
	# Clear data
	connected_players.clear()
	PlayerManager.clear_all_players()
	_refresh_lobby_list()

#------------------------------------------------------------------------------|
func _on_start_button_pressed():
	if not multiplayer.is_server():
		return
	
	# Double check all players are ready
	for player_id in connected_players:
		if not PlayerManager.players_data.has(player_id):
			status_label.text = "Not all players have selected a class!"
			return
	
	# PlayerManager already has all class data, just need to sync
	sync_all_classes.rpc()

	await get_tree().create_timer(0.5).timeout

	start_game.rpc()

#------------------------------------------------------------------------------|
@rpc("authority", "call_local")
func sync_all_classes():
	# PlayerManager already has all the data
	# This just ensures consistency before starting
	print("All classes synced, ", PlayerManager.players_data.size(), " players registered")

#------------------------------------------------------------------------------|
func change_level(scene):
	for child in level_container.get_children():
		level_container.remove_child(child)
		if child.has_signal("level_complete"):
			child.level_complete.disconnect(_on_level_complete)
		child.queue_free()
	
	var new_level = scene.instantiate()
	level_container.add_child(new_level)
	if new_level.has_signal("level_complete"):
		new_level.level_complete.connect(_on_level_complete)

#------------------------------------------------------------------------------|
func _on_connection_failed():
	status_label.text = "Failed to connect"
	not_connected_hbox.show()
	
	# Clear data
	connected_players.clear()
	PlayerManager.clear_all_players()
	_refresh_lobby_list()

#------------------------------------------------------------------------------|
@rpc("authority", "call_local", "reliable")
func start_game():
	ui.hide()
	change_level(level_scene)

#------------------------------------------------------------------------------|
func _on_level_complete():
	start_game.rpc()

#------------------------------------------------------------------------------|
func _on_back_button_pressed():
	# Notify others we're leaving
	if multiplayer.multiplayer_peer != null:
		var my_id = multiplayer.get_unique_id()
		rpc("notify_player_disconnected", my_id)
		
		# Disconnect
		multiplayer.multiplayer_peer.close()
	
	# Clear data
	connected_players.clear()
	PlayerManager.clear_all_players()
	
	get_tree().change_scene_to_file(Constants.PATH_MENU_MAIN)

#------------------------------------------------------------------------------|
func _on_select_class_button_pressed() -> void:
	# Show class selection
	if class_selection_ui:
		class_selection_ui.show()

#------------------------------------------------------------------------------|
func _notification(what):
	# Handle window close / game exit
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_back_button_pressed()
