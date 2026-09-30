extends Resource
class_name AchievementData

## Definition of a single achievement. Whatever system tracks progress
## (kill counters, boss-death hooks, etc.) is responsible for calling
## EventBus.player_earned_achievement.emit(player_name, title, commentary)
## once `threshold` is reached — this resource only holds the data needed
## to describe that moment, DCC-narrator style.

enum ConditionType {
	KILL_COUNT,     ## kill `threshold` enemies (matching `tag`, or any if empty)
	BOSS_KILL,      ## kill a boss (matching `tag`, or any boss if empty)
	ITEM_COLLECTED, ## collect `threshold` items (matching `tag`)
	CUSTOM,         ## anything scripted elsewhere; this resource is just the flavor text
}

@export var achievement_id: String = ""
@export var title: String = "Untitled Achievement"
@export_multiline var description: String = ""
@export var condition_type: ConditionType = ConditionType.KILL_COUNT
@export var tag: String = ""
@export var threshold: int = 1
@export var loot_tier_reward: int = 1

## Snarky narrator lines to pick from when this achievement fires.
@export var narrator_lines: Array[String] = []

#------------------------------------------------------------------------------|
func get_random_commentary() -> String:
	if narrator_lines.is_empty():
		return "Achievement unlocked: %s" % title
	return narrator_lines[randi() % narrator_lines.size()]
