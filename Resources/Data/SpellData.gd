extends Resource
class_name SpellData

enum SpellType {
	DAMAGE,
	HEAL,
	BUFF,
	DEBUFF
}

@export var spell_name: String
@export var spell_type: SpellType
@export var icon: Texture2D
@export var cooldown: float = 1.0
@export var cast_range: float = 500.0
@export var mana_cost: float = 0.0

# Components
@export var targeting: SpellTargeting
@export var delivery: SpellDelivery
@export var shape: SpellShape
@export var effects: Array[SpellEffect] = []
@export var cosmetics: SpellCosmetics
