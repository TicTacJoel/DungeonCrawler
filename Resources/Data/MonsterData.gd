extends Resource
class_name MonsterData

## Re-usable stat block for an enemy or boss. One MonsterData resource can be
## shared by every instance of a monster type; `level` (set per-instance on
## the enemy/boss node) drives the scaling functions below so the same data
## produces a weaker or stronger monster depending on dungeon depth.

enum AIType {
	MELEE,
	RANGED,
	BOSS,
}

@export var monster_name: String = "Unknown Monster"
@export var ai_type: AIType = AIType.MELEE
@export var icon: Texture2D

# Base stats, i.e. the stats at level 1.
@export var base_health: float = 10.0
@export var base_damage: float = 2.0
@export var base_movement_speed: float = 100.0
@export var base_experience: int = 1

# Per-level growth, applied as base * growth^(level - 1). 1.0 = no scaling.
@export var health_growth: float = 1.15
@export var damage_growth: float = 1.1
@export var experience_growth: float = 1.1

# AI ranges, shared vocabulary for melee/ranged/boss AI.
@export var detection_radius: float = 100.0
@export var attack_range: float = 250.0
## Ranged enemies back away from their target inside this distance. 0 = never retreat.
@export var retreat_range: float = 0.0

## Spells this monster can cast. Ranged enemies use spells[0] as their attack;
## bosses pick from BossAttackData entries that each reference one of these.
## Re-uses the exact same SpellData/SpellDelivery/SpellShape/SpellEffect
## pipeline the player classes use, so new monster attacks are just new
## SpellData resources instead of new code.
@export var spells: Array[SpellData] = []

# Loot hooks, wired up once a loot table system exists.
@export var loot_tags: Array[String] = []
@export var min_loot_tier: int = 0
@export var max_loot_tier: int = 1

#------------------------------------------------------------------------------|
func get_health(level: int) -> float:
	return base_health * pow(health_growth, maxi(level, 1) - 1)

#------------------------------------------------------------------------------|
func get_damage(level: int) -> float:
	return base_damage * pow(damage_growth, maxi(level, 1) - 1)

#------------------------------------------------------------------------------|
func get_experience(level: int) -> int:
	return int(round(base_experience * pow(experience_growth, maxi(level, 1) - 1)))

#------------------------------------------------------------------------------|
func get_movement_speed(_level: int) -> float:
	return base_movement_speed
