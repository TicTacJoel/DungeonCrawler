extends Resource
class_name ClassData

@export var className: String
@export var class_type: ClassType
@export var icon: Texture2D
@export var skin: Texture2D
@export var max_health: float = 100.0
@export var movement_speed: float = 300.0
@export var color: Color = Color.WHITE

# Spell data
@export var spells: Array[SpellData] = []

#------------------------------------------------------------------------------|
enum ClassType {
	DRUID,
	HUNTER,  
	MAGE, 
	NECROMANCER, 
	PRIEST, 
	ROGUE, 
	WARRIOR, 
}

#------------------------------------------------------------------------------|
const ClassSkins = {
	ClassType.DRUID: preload(Constants.PATH_DRUID_SKIN), 
	#ClassType.HUNTER: preload(), 
	ClassType.MAGE: preload(Constants.PATH_MAGE_SKIN), 
	ClassType.NECROMANCER: preload(Constants.PATH_NECROMANCER_SKIN), 
	#ClassType.PRIEST: preload(), 
	ClassType.ROGUE: preload(Constants.PATH_ROGUE_SKIN), 
	#ClassType.WARRIOR: preload(), 
}

#------------------------------------------------------------------------------|
const ClassIcon = {
	ClassType.DRUID: preload(Constants.PATH_DRUID_ICON), 
	#ClassType.HUNTER: preload(), 
	ClassType.MAGE: preload(Constants.PATH_MAGE_ICON), 
	ClassType.NECROMANCER: preload(Constants.PATH_NECROMANCER_ICON), 
	#ClassType.PRIEST: preload(), 
	ClassType.ROGUE: preload(Constants.PATH_ROGUE_ICON), 
	#ClassType.WARRIOR: preload(), 
}

#------------------------------------------------------------------------------|
const ClassSpells = {
	ClassType.DRUID: [
		preload(Constants.PATH_SPELL_FIREBALL),
		preload(Constants.PATH_SPELL_FROSTBOLT),
		preload(Constants.PATH_SPELL_ARCANE_EXPLOSION),
		preload(Constants.PATH_SPELL_BLINK),
	],
	ClassType.MAGE: [
		preload(Constants.PATH_SPELL_FIREBALL),
		preload(Constants.PATH_SPELL_FROSTBOLT),
		preload(Constants.PATH_SPELL_ARCANE_EXPLOSION),
		preload(Constants.PATH_SPELL_BLINK),
	],
	ClassType.NECROMANCER: [
		preload(Constants.PATH_SPELL_FIREBALL),
		preload(Constants.PATH_SPELL_FROSTBOLT),
		preload(Constants.PATH_SPELL_ARCANE_EXPLOSION),
		preload(Constants.PATH_SPELL_BLINK),
	],
	ClassType.ROGUE: [
		preload(Constants.PATH_SPELL_BACKSTAB),
		preload(Constants.PATH_SPELL_POISON_STRIKE),
		preload(Constants.PATH_SPELL_FAN_OF_KNIVES),
		preload(Constants.PATH_SPELL_STEALTH),
	],
}

#------------------------------------------------------------------------------|
static var ClassColors = {
	druid_color 		= Color(0.5, 0.8, 0.3), # Light Green
	hunter_color 		= Color(0.3, 0.5, 0.2), # Dark Green
	mage_color 			= Color(0.3, 0.5, 1.0), # Blue
	necromancer_color 	= Color(0.6, 0.0, 0.8), # Purple
	priest_color 		= Color(1.0, 0.8, 1.0), # Light pink
	rogue_color 		= Color(1.0, 1.0, 0.4), # Light yellow
	warrior_color 		= Color(0.8, 0.3, 0.3), # Red
}

#------------------------------------------------------------------------------|
static func get_class_by_type(type: ClassType) -> ClassData:
	var class_data = ClassData.new()
	
	match type:
		ClassType.DRUID:
			class_data.className = "Druid"
			class_data.class_type = ClassType.DRUID
			class_data.max_health = 100.0
			class_data.movement_speed = 200.0
			class_data.color = ClassColors.druid_color
			class_data.icon = ClassIcon[ClassType.DRUID]
			class_data.skin = ClassSkins[ClassType.DRUID]
		
		ClassType.MAGE:
			class_data.className = "Mage"
			class_data.class_type = ClassType.MAGE
			class_data.max_health = 80.0
			class_data.movement_speed = 200.0
			class_data.color = ClassColors.mage_color
			class_data.icon = ClassIcon[ClassType.MAGE]
			class_data.skin = ClassSkins[ClassType.MAGE]
		
		ClassType.NECROMANCER:
			class_data.className = "Necromancer"
			class_data.class_type = ClassType.NECROMANCER
			class_data.max_health = 80.0
			class_data.movement_speed = 200.0
			class_data.color = ClassColors.necromancer_color
			class_data.icon = ClassIcon[ClassType.NECROMANCER]
			class_data.skin = ClassSkins[ClassType.NECROMANCER]
		
		#ClassType.PRIEST:
			#class_data.className = "Priest"
			#class_data.class_type = ClassType.PRIEST
			#class_data.max_health = 100.0
			#class_data.movement_speed = 180.0
			#class_data.color = ClassColors.priest_color
			#class_data.icon = ClassIcon[ClassType.PRIEST]
			#class_data.skin = ClassSkins[ClassType.PRIEST]
		
		ClassType.ROGUE:
			class_data.className = "Rogue"
			class_data.class_type = ClassType.ROGUE
			class_data.max_health = 90.0
			class_data.movement_speed = 250.0
			class_data.color = ClassColors.rogue_color
			class_data.icon = ClassIcon[ClassType.ROGUE]
			class_data.skin = ClassSkins[ClassType.ROGUE]
		
		#ClassType.WARRIOR:
			#class_data.className = "Warrior"
			#class_data.class_type = ClassType.WARRIOR
			#class_data.max_health = 150.0
			#class_data.movement_speed = 250.0
			#class_data.color = ClassColors.warrior_color
			#class_data.icon = ClassIcon[ClassType.WARRIOR]
			#class_data.skin = ClassSkins[ClassType.WARRIOR]

	var spell_list: Array[SpellData] = []
	spell_list.assign(ClassSpells.get(type, []))
	class_data.spells = spell_list

	return class_data

#------------------------------------------------------------------------------|
static func get_all_classes() -> Array[ClassData]:
	var classes: Array[ClassData] = []
	for type in ClassType.values():
		classes.append(get_class_by_type(type))
	return classes
