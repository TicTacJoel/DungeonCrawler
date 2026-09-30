extends Node

# Emit when someone does something worthy of a snarky comment
signal player_earned_achievement(player_name: String, achievement_title: String, ai_commentary: String)

# Emit this when a loot box drops
signal spawn_loot_box(position: Vector2, tier: int)

# Emit when the safe room is breached or secured
signal safe_room_status_changed(is_safe: bool)
