extends Node

# Dictionary of all character data, keyed by character ID
var characters: Dictionary = {}

# Quick lookup arrays
var starter_characters: Array[String] = []
var all_character_ids: Array[String] = []

func _ready():
	print("CharacterDatabase initializing...")
	load_all_characters()
	print("CharacterDatabase loaded %d characters" % characters.size())

func load_all_characters():
	"""Load all character resource files from disk"""
	var character_paths = [
		# STARTER CHARACTERS
		"res://resources/characters/knight.tres",
		"res://resources/characters/wizard.tres",
		"res://resources/characters/cleric.tres",
		
		# TIER 1 UNLOCKS
		"res://resources/characters/rogue.tres",
		"res://resources/characters/paladin.tres",
		"res://resources/characters/berserker.tres",
		"res://resources/characters/druid.tres",
		
		# TIER 2 UNLOCKS
		"res://resources/characters/necromancer.tres",
		"res://resources/characters/ranger.tres",
		"res://resources/characters/enchanter.tres",
		"res://resources/characters/monk.tres",
		
		# TIER 3 UNLOCKS
		"res://resources/characters/beastmaster.tres",
		"res://resources/characters/bladesinger.tres"
	]
	
	for path in character_paths:
		if ResourceLoader.exists(path):
			var char_data: CharacterData = load(path)
			if char_data and char_data.id != "":
				characters[char_data.id] = char_data
				all_character_ids.append(char_data.id)
				if char_data.is_starter:
					starter_characters.append(char_data.id)
			else:
				push_error("Failed to load character data from: %s" % path)
		else:
			push_error("Character resource not found: %s" % path)

func create_character_base() -> CharacterData:
	"""Helper to create a new CharacterData instance"""
	return CharacterData.new()

# === CHARACTER DEFINITIONS ===

func create_knight():
	var char = create_character_base()
	char.id = "knight"
	char.character_name = "Sir Gareth"
	char.character_class = "Knight"
	char.class_type = "Tank"
	char.color = Color("#E63946")  # Red
	char.ability_name = "Shield Wall"
	char.ability_description = "Absorbs incoming damage for the party."
	char.ability_value_tier1 = 25
	char.ability_value_tier2 = 37
	char.ability_value_tier3 = 50
	char.is_starter = true
	char.unlock_cost = 0
	char.unlock_tier = 0
	characters["knight"] = char

func create_wizard():
	var char = create_character_base()
	char.id = "wizard"
	char.character_name = "Mystara"
	char.character_class = "Wizard"
	char.class_type = "DPS"
	char.color = Color("#457B9D")  # Blue
	char.ability_name = "Meteor Storm"
	char.ability_description = "Deals damage and clears random blocks from the board."
	char.ability_value_tier1 = 10  # damage
	char.ability_secondary_tier1 = 10  # blocks cleared
	char.ability_value_tier2 = 15
	char.ability_secondary_tier2 = 15
	char.ability_value_tier3 = 20
	char.ability_secondary_tier3 = 20
	char.is_starter = true
	char.unlock_cost = 0
	char.unlock_tier = 0
	characters["wizard"] = char

func create_cleric():
	var char = create_character_base()
	char.id = "cleric"
	char.character_name = "Seraphina"
	char.character_class = "Cleric"
	char.class_type = "Support"
	char.color = Color("#F1C40F")  # Yellow
	char.ability_name = "Healing Light"
	char.ability_description = "Restores health to the party."
	char.ability_value_tier1 = 30
	char.ability_value_tier2 = 45
	char.ability_value_tier3 = 60
	char.is_starter = true
	char.unlock_cost = 0
	char.unlock_tier = 0
	characters["cleric"] = char

func create_rogue():
	var char = create_character_base()
	char.id = "rogue"
	char.character_name = "Shadowblade"
	char.character_class = "Rogue"
	char.class_type = "DPS"
	char.color = Color("#2ECC71")  # Green
	char.ability_name = "Assassinate"
	char.ability_description = "Deals massive damage to a single enemy."
	char.ability_value_tier1 = 15
	char.ability_value_tier2 = 22
	char.ability_value_tier3 = 30
	char.unlock_cost = 200
	char.unlock_tier = 1
	characters["rogue"] = char

func create_paladin():
	var char = create_character_base()
	char.id = "paladin"
	char.character_name = "Aldric the Pure"
	char.character_class = "Paladin"
	char.class_type = "Tank"
	char.color = Color("#9B59B6")  # Purple
	char.ability_name = "Purifying Light"
	char.ability_description = "Removes enemy-placed obstacles from the board."
	char.ability_value_tier1 = 1  # number of obstacles removed
	char.ability_value_tier2 = 2
	char.ability_value_tier3 = 3
	char.unlock_cost = 200
	char.unlock_tier = 1
	characters["paladin"] = char

func create_berserker():
	var char = create_character_base()
	char.id = "berserker"
	char.character_name = "Krag Ironjaw"
	char.character_class = "Berserker"
	char.class_type = "DPS"
	char.color = Color("#E67E22")  # Orange
	char.ability_name = "Cleave"
	char.ability_description = "Deals heavy damage. If target dies, full damage carries to next enemy."
	char.ability_value_tier1 = 8
	char.ability_value_tier2 = 12
	char.ability_value_tier3 = 16
	char.unlock_cost = 200
	char.unlock_tier = 1
	characters["berserker"] = char

func create_druid():
	var char = create_character_base()
	char.id = "druid"
	char.character_name = "Thornweave"
	char.character_class = "Druid"
	char.class_type = "Support"
	char.color = Color("#27AE60")  # Green (different shade from rogue)
	char.ability_name = "Barkskin"
	char.ability_description = "Heals party over time and damages attackers."
	char.ability_value_tier1 = 5  # heal per turn
	char.ability_secondary_tier1 = 5  # damage to attackers
	char.ability_duration_tier1 = 3  # turns
	char.ability_value_tier2 = 7
	char.ability_secondary_tier2 = 7
	char.ability_duration_tier2 = 4
	char.ability_value_tier3 = 10
	char.ability_secondary_tier3 = 10
	char.ability_duration_tier3 = 5
	char.unlock_cost = 200
	char.unlock_tier = 1
	characters["druid"] = char

func create_necromancer():
	var char = create_character_base()
	char.id = "necromancer"
	char.character_name = "Mortis"
	char.character_class = "Necromancer"
	char.class_type = "Hybrid"
	char.color = Color("#8E44AD")  # Dark purple
	char.ability_name = "Drain Life"
	char.ability_description = "Drains enemy health, heals party, and converts neutral blocks."
	char.ability_value_tier1 = 3  # HP drained/healed and blocks converted
	char.ability_value_tier2 = 5
	char.ability_value_tier3 = 7
	char.unlock_cost = 400
	char.unlock_tier = 2
	characters["necromancer"] = char

func create_ranger():
	var char = create_character_base()
	char.id = "ranger"
	char.character_name = "Artemis Swiftwind"
	char.character_class = "Ranger"
	char.class_type = "DPS"
	char.color = Color("#16A085")  # Teal
	char.ability_name = "Multi-Shot"
	char.ability_description = "Splits damage between all active enemies."
	char.ability_value_tier1 = 12  # total damage
	char.ability_value_tier2 = 18
	char.ability_value_tier3 = 24
	char.unlock_cost = 400
	char.unlock_tier = 2
	characters["ranger"] = char

func create_enchanter():
	var char = create_character_base()
	char.id = "enchanter"
	char.character_name = "Lumina"
	char.character_class = "Enchanter"
	char.class_type = "Support"
	char.color = Color("#3498DB")  # Light blue
	char.ability_name = "Mesmerize"
	char.ability_description = "Stuns enemy, preventing attacks. Bosses only stunned for 1 turn."
	char.ability_duration_tier1 = 1  # turns
	char.ability_duration_tier2 = 2
	char.ability_duration_tier3 = 3
	char.unlock_cost = 400
	char.unlock_tier = 2
	characters["enchanter"] = char

func create_monk():
	var char = create_character_base()
	char.id = "monk"
	char.character_name = "Zen Master Kai"
	char.character_class = "Monk"
	char.class_type = "Utility"
	char.color = Color("#D35400")  # Dark orange
	char.ability_name = "Temporal Mastery"
	char.ability_description = "Extends all active buffs and debuffs."
	char.ability_duration_tier1 = 1  # additional turns
	char.ability_duration_tier2 = 2
	char.ability_duration_tier3 = 3
	char.unlock_cost = 400
	char.unlock_tier = 2
	characters["monk"] = char

func create_beastmaster():
	var char = create_character_base()
	char.id = "beastmaster"
	char.character_name = "Fang"
	char.character_class = "Beastmaster"
	char.class_type = "DPS"
	char.color = Color("#A0522D")  # Brown
	char.ability_name = "Beast Summon"
	char.ability_description = "Summons a random companion to attack. Higher levels summon stronger beasts."
	# Beast table stored in special_data
	char.special_data = {
		"beasts": [
			{"name": "Hawk", "damage": [8, 12, 16], "weight": [40, 30, 20]},
			{"name": "Dire Wolf", "damage": [15, 22, 30], "weight": [30, 30, 25]},
			{"name": "Gryphon", "damage": [25, 37, 50], "weight": [20, 25, 30]},
			{"name": "Basilisk", "damage": [35, 52, 70], "weight": [8, 12, 18]},
			{"name": "Dragon", "damage": [50, 75, 100], "weight": [2, 3, 7]}
		]
	}
	char.unlock_cost = 600
	char.unlock_tier = 3
	characters["beastmaster"] = char

func create_bladesinger():
	var char = create_character_base()
	char.id = "bladesinger"
	char.character_name = "Sylvara Windstrike"
	char.character_class = "Bladesinger"
	char.class_type = "Hybrid"
	char.color = Color("#E74C3C")  # Bright red
	char.ability_name = "Bladesong"
	char.ability_description = "Deals damage to random enemy and buffs random ally's next match."
	char.ability_value_tier1 = 2  # damage
	char.ability_secondary_tier1 = 2  # buff amount
	char.ability_value_tier2 = 4
	char.ability_secondary_tier2 = 4
	char.ability_value_tier3 = 6
	char.ability_secondary_tier3 = 6
	char.unlock_cost = 600
	char.unlock_tier = 3
	characters["bladesinger"] = char

# === HELPER FUNCTIONS ===

func get_character(character_id: String) -> CharacterData:
	"""Get character data by ID"""
	return characters.get(character_id)

func get_character_display_name(character_id: String) -> String:
	"""Get character's fantasy name"""
	if characters.has(character_id):
		return characters[character_id].character_name
	return "Unknown"

func get_character_class(character_id: String) -> String:
	"""Get character's class"""
	if characters.has(character_id):
		return characters[character_id].character_class
	return "Unknown"

func get_all_characters() -> Array:
	"""Get array of all character IDs"""
	return all_character_ids.duplicate()

func get_starter_characters() -> Array:
	"""Get array of starter character IDs"""
	return starter_characters.duplicate()

func get_characters_by_tier(tier: int) -> Array:
	"""Get all characters in a specific unlock tier"""
	var result = []
	for char_id in characters:
		if characters[char_id].unlock_tier == tier:
			result.append(char_id)
	return result
