extends Node2D

signal level_complete

@onready var players_container: Node2D = $PlayersContainer
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

@export var key_door: KeyDoor

func _enter_tree() -> void:
	# Spell deliveries parent their projectiles/areas here (SpellDelivery.world_of).
	add_to_group("level")

func _ready() -> void:
	if not multiplayer.is_server():
		return
	multiplayer.peer_disconnected.connect(delete_player)
	
	# add late joiners to the game
	#multiplayer.peer_connected.connect(add_player)
	
	for id in multiplayer.get_peers():
		add_player(id)
	
	add_player(1) # add server
	
	#key_door.all_players_finished.connect(_on_all_players_finished)

func _exit_tree():
	if multiplayer.multiplayer_peer == null:
		return
	if not multiplayer.is_server():
		return
	multiplayer.peer_disconnected.disconnect(delete_player)

func add_player(id):
	player_spawner.spawn(id)

func delete_player(id):
	# if there is no player with this id anymore -> do nothing
	if not players_container.has_node(str(id)):
		return
	players_container.get_node(str(id)).queue_free()

func _on_all_players_finished():
	key_door.all_players_finished.disconnect(_on_all_players_finished)
	level_complete.emit()
