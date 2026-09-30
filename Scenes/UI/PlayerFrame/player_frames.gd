extends VBoxContainer

@export var player_frame_scene: PackedScene

var player_frames: Dictionary = {}  # player_id: PlayerFrame

#------------------------------------------------------------------------------|
func _ready():
	# Connect signals
	PlayerManager.connect("player_added", _on_player_added)
	PlayerManager.connect("player_removed", _on_player_removed)
	
	# Wait a frame for players to register, then refresh
	await get_tree().process_frame
	refresh_all_frames()
	
	print("PartyFrames: Ready and waiting for players")

#------------------------------------------------------------------------------|
func _process(_delta):
	# Update all player frames
	for player_id in player_frames.keys():
		var player_info = PlayerManager.get_player_info(player_id)
		if player_info:
			player_frames[player_id].update_health(player_info.current_health, player_info.max_health)

#------------------------------------------------------------------------------|
func _on_player_added(player_id: int):
	print("PartyFrames: Player added signal received for ", player_id)
	
	if player_frames.has(player_id):
		print("PartyFrames: Frame already exists for ", player_id)
		return
	
	var player_info = PlayerManager.get_player_info(player_id)
	if not player_info:
		print("PartyFrames: No player info found for ", player_id)
		return
	
	var frame = _create_player_frame(player_info)
	add_child(frame)
	player_frames[player_id] = frame
	print("PartyFrames: Created frame for player ", player_id)

#------------------------------------------------------------------------------|
func _on_player_removed(player_id: int):
	if player_frames.has(player_id):
		player_frames[player_id].queue_free()
		player_frames.erase(player_id)

#------------------------------------------------------------------------------|
func _create_player_frame(player_info) -> PlayerFrame:
	print("PartyFrames: Create Frame for ", player_info)
	
	var frame: PlayerFrame
	
	if player_frame_scene:
		frame = player_frame_scene.instantiate()
	else:
		frame = PlayerFrame.new()
	
	var class_data = ClassData.get_class_by_type(player_info.class_type)
	frame.setup(player_info.player_name, class_data)
	
	return frame

#------------------------------------------------------------------------------|
func refresh_all_frames():
	print("PartyFrames: Refreshing all frames...")
	
	# Clear existing frames
	for frame in player_frames.values():
		frame.queue_free()
	player_frames.clear()
	
	# Create frames for all players
	var all_players = PlayerManager.get_all_players()
	print("PartyFrames: Found ", all_players.size(), " players")
	
	for player_info in all_players:
		var frame = _create_player_frame(player_info)
		add_child(frame)
		player_frames[player_info.player_id] = frame
		print("PartyFrames: Created frame for player ", player_info.player_id)
