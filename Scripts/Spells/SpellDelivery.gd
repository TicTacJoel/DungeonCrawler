class_name SpellDelivery
extends Resource

## Gets the spell from the caster to the world: spawns a node, or resolves instantly.
func execute(_caster: Node2D, _spell: SpellData, _origin: Vector2, _target_point: Vector2) -> void:
	push_error("SpellDelivery.execute() not implemented")

## Where spawned spell nodes (projectiles, areas, FX) go: the caster's level,
## so they're freed together with it on a level change. current_scene is the
## lobby menu, which outlives every level.
static func world_of(node: Node) -> Node:
	var current := node
	while current:
		if current.is_in_group("level"):
			return current
		current = current.get_parent()
	return node.get_tree().current_scene
