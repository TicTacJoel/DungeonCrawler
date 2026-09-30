class_name EffectStatus
extends SpellEffect

## Stub — no real buff/debuff system exists yet. Kept as an extension
## point so status-effect spells can be composed today and wired up later.
@export var status_name: String = ""
@export var duration: float = 0.0

func apply(_caster: Node, _target: Node, _point: Vector2) -> void:
	pass
