extends Area2D
class_name StairsExit

## Descending requires at least n-1 of the n connected players standing in
## the stairwell at once (solo play just requires the one player). This is a
## live headcount, not a ratchet — leaving the area lowers the count again.

signal stairs_activated

var _bodies_in_area: Dictionary = {}
var _activated: bool = false

#------------------------------------------------------------------------------|
func _on_body_entered(body: Node2D) -> void:
	if not _is_server():
		return
	if not body.is_in_group("player"):
		return
	_bodies_in_area[body.get_instance_id()] = true
	_check_threshold()

#------------------------------------------------------------------------------|
func _on_body_exited(body: Node2D) -> void:
	if not _is_server():
		return
	_bodies_in_area.erase(body.get_instance_id())

#------------------------------------------------------------------------------|
## body_exited also fires while the level is being torn down, when this node
## is already out of the tree and `multiplayer` is null.
func _is_server() -> bool:
	return is_inside_tree() and multiplayer.is_server()

#------------------------------------------------------------------------------|
func _check_threshold() -> void:
	if _activated:
		return
	var total_players: int = len(multiplayer.get_peers()) + 1
	var required: int = maxi(1, total_players - 1)
	if _bodies_in_area.size() >= required:
		_activated = true
		# Deferred: listeners swap out the whole level, which must not happen
		# in the middle of a physics callback.
		stairs_activated.emit.call_deferred()
