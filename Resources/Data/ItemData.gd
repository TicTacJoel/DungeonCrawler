extends Resource
class_name ItemData

@export var item_name: String = "Unknown Trash"
@export_multiline var description: String
@export var icon: Texture2D
@export_enum("Common", "Uncommon", "Rare", "Epic", "Legendary") var rarity: int = 0
@export var damage_bonus: int = 0
@export var tags: Array[String] = []
@export var price: int = 0
