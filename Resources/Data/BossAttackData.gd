extends Resource
class_name BossAttackData

## One entry in a boss's attack repertoire. `min_level` is what lets the same
## boss scene be reused at every dungeon depth: give it a big attacks[] list
## on the MonsterData/Boss side and low-level bosses simply won't have
## unlocked the later entries yet.

@export var attack_name: String = "Attack"
@export var min_level: int = 1

## The actual attack, expressed as a normal SpellData resource so it goes
## through the same SpellResolver/effects/cosmetics pipeline as player spells.
@export var spell: SpellData

## How long the boss telegraphs (stands still, plays a warning) before impact.
@export var telegraph_time: float = 0.6
## Cooldown before this specific attack (or another) can be used again.
@export var cooldown: float = 2.5
## true = area-effect centered on the boss itself (a slam). false = aimed at
## the current target's position (a melee swipe).
@export var is_self_centered: bool = false
