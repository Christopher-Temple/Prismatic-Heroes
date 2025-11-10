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
		# STARTER CHARACTERS (Tier 0)
		"res://resources/characters/knight.tres",
		"res://resources/characters/wizard.tres",
		"res://resources/characters/cleric.tres",
		
		# TIER 1 UNLOCKS (Cost: 200)
		"res://resources/characters/rogue.tres",
		"res://resources/characters/paladin.tres",
		"res://resources/characters/berserker.tres",
		"res://resources/characters/druid.tres",
		
		# TIER 2 UNLOCKS (Cost: 400)
		"res://resources/characters/necromancer.tres",
		"res://resources/characters/ranger.tres",
		"res://resources/characters/enchanter.tres",
		"res://resources/characters/monk.tres",
		
		# TIER 3 UNLOCKS (Cost: 600)
		"res://resources/characters/beastmaster.tres",
		"res://resources/characters/bladesinger.tres",
		"res://resources/characters/shadowmancer.tres",
		
		# TIER 4 UNLOCKS (Cost: 800)
		"res://resources/characters/valkyrie.tres",
		"res://resources/characters/warden.tres",
		"res://resources/characters/chronomancer.tres",
		
		# TIER 5 UNLOCKS (Cost: 1000)
		"res://resources/characters/geomancer.tres",
		"res://resources/characters/inquisitor.tres",
		"res://resources/characters/blood_knight.tres",
		
		# TIER 6 UNLOCKS (Cost: 1200)
		"res://resources/characters/fateweaver.tres",
		"res://resources/characters/archmage.tres",
		"res://resources/characters/dreadknight.tres",
		
		# TIER 7 UNLOCKS (Cost: 1500)
		"res://resources/characters/runemaster.tres",
		"res://resources/characters/spellblade.tres",
		"res://resources/characters/templar.tres",
		
		# TIER 8 UNLOCKS (Cost: 2000)
		"res://resources/characters/elementalist.tres",
		"res://resources/characters/lightbringer.tres",
		"res://resources/characters/voidwalker.tres",
		
		# TIER 9 UNLOCKS (Cost: 2500)
		"res://resources/characters/stormlord.tres",
		"res://resources/characters/archdruid.tres",
		"res://resources/characters/archon.tres",
		"res://resources/characters/demonologist.tres",
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

# TIER 0 - STARTER CHARACTERS

func create_knight():
	var char = create_character_base()
	char.id = "knight"
	char.character_name = "Sir Gareth"
	char.character_class = "Knight"
	char.class_type = "Tank"
	char.color = Color("#E63946")
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
	char.character_name = "Thaddeus Greybeard"
	char.character_class = "Wizard"
	char.class_type = "DPS"
	char.color = Color("#457B9D")
	char.ability_name = "Meteor Storm"
	char.ability_description = "Deals damage and removes random blocks from the board."
	char.ability_value_tier1 = 10
	char.ability_secondary_tier1 = 10
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
	char.character_name = "Jeremiah Peacekeeper"
	char.character_class = "Cleric"
	char.class_type = "Support"
	char.color = Color("#F1C40F")
	char.ability_name = "Healing Light"
	char.ability_description = "Restores health to the party."
	char.ability_value_tier1 = 30
	char.ability_value_tier2 = 45
	char.ability_value_tier3 = 60
	char.is_starter = true
	char.unlock_cost = 0
	char.unlock_tier = 0
	characters["cleric"] = char

# TIER 1 - 200 COST

func create_rogue():
	var char = create_character_base()
	char.id = "rogue"
	char.character_name = "Zara Swiftblade"
	char.character_class = "Rogue"
	char.class_type = "DPS"
	char.color = Color("#2ECC71")
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
	char.color = Color("#9B59B6")
	char.ability_name = "Purifying Light"
	char.ability_description = "Removes enemy-placed obstacles from the board."
	char.ability_value_tier1 = 1
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
	char.color = Color("#E67E22")
	char.ability_name = "Cleave"
	char.ability_description = "Deals damage to a target. If target dies, full damage carries to next enemy."
	char.ability_value_tier1 = 8
	char.ability_value_tier2 = 12
	char.ability_value_tier3 = 16
	char.unlock_cost = 200
	char.unlock_tier = 1
	characters["berserker"] = char

func create_druid():
	var char = create_character_base()
	char.id = "druid"
	char.character_name = "Willow Thornweave"
	char.character_class = "Druid"
	char.class_type = "Support"
	char.color = Color("#27AE60")
	char.ability_name = "Barkskin"
	char.ability_description = "Heals party over time and damages attackers."
	char.ability_value_tier1 = 5
	char.ability_secondary_tier1 = 5
	char.ability_duration_tier1 = 3
	char.ability_value_tier2 = 7
	char.ability_secondary_tier2 = 7
	char.ability_duration_tier2 = 4
	char.ability_value_tier3 = 10
	char.ability_secondary_tier3 = 10
	char.ability_duration_tier3 = 5
	char.unlock_cost = 200
	char.unlock_tier = 1
	characters["druid"] = char

# TIER 2 - 400 COST

func create_necromancer():
	var char = create_character_base()
	char.id = "necromancer"
	char.character_name = "Mortis"
	char.character_class = "Necromancer"
	char.class_type = "Hybrid"
	char.color = Color("#8E44AD")
	char.ability_name = "Drain Life"
	char.ability_description = "Drains enemy health, heals party, and converts neutral blocks."
	char.ability_value_tier1 = 3
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
	char.color = Color("#16A085")
	char.ability_name = "Multi-Shot"
	char.ability_description = "Splits damage between all active enemies."
	char.ability_value_tier1 = 12
	char.ability_value_tier2 = 18
	char.ability_value_tier3 = 24
	char.unlock_cost = 400
	char.unlock_tier = 2
	characters["ranger"] = char

func create_enchanter():
	var char = create_character_base()
	char.id = "enchanter"
	char.character_name = "Callum Runekeeper"
	char.character_class = "Enchanter"
	char.class_type = "Support"
	char.color = Color("#3498DB")
	char.ability_name = "Mesmerize"
	char.ability_description = "Stuns enemy, preventing attacks. Bosses only stunned for 1 turn."
	char.ability_duration_tier1 = 1
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
	char.color = Color("#D35400")
	char.ability_name = "Temporal Mastery"
	char.ability_description = "Extends all active buffs and debuffs."
	char.ability_duration_tier1 = 1
	char.ability_duration_tier2 = 2
	char.ability_duration_tier3 = 3
	char.unlock_cost = 400
	char.unlock_tier = 2
	characters["monk"] = char

# TIER 3 - 600 COST

func create_beastmaster():
	var char = create_character_base()
	char.id = "beastmaster"
	char.character_name = "Fang"
	char.character_class = "Beastmaster"
	char.class_type = "DPS"
	char.color = Color("#A0522D")
	char.ability_name = "Beast Summon"
	char.ability_description = "Summons a random companion to attack. Higher levels summon stronger beasts."
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
	char.color = Color("#E74C3C")
	char.ability_name = "Bladesong"
	char.ability_description = "Deals damage to random enemy and buffs random ally's next match."
	char.ability_value_tier1 = 2
	char.ability_secondary_tier1 = 2
	char.ability_value_tier2 = 4
	char.ability_secondary_tier2 = 4
	char.ability_value_tier3 = 6
	char.ability_secondary_tier3 = 6
	char.unlock_cost = 600
	char.unlock_tier = 3
	characters["bladesinger"] = char

func create_shadowmancer():
	var char = create_character_base()
	char.id = "shadowmancer"
	char.character_name = "Umbra Nightwhisper"
	char.character_class = "Shadowmancer"
	char.class_type = "DPS"
	char.color = Color(0.3, 0.15, 0.4, 1)
	char.ability_name = "Shadow Strike"
	char.ability_description = "Enemy's shadow attacks them for their own damage. Chance to delay all enemies."
	char.ability_value_tier1 = 15
	char.ability_value_tier2 = 20
	char.ability_value_tier3 = 25
	char.unlock_cost = 600
	char.unlock_tier = 3
	characters["shadowmancer"] = char

# TIER 4 - 800 COST

func create_valkyrie():
	var char = create_character_base()
	char.id = "valkyrie"
	char.character_name = "Freya Skyheart"
	char.character_class = "Valkyrie"
	char.class_type = "Hybrid"
	char.color = Color(0.9, 0.8, 0.3, 1)
	char.ability_name = "Divine Judgement"
	char.ability_description = "Massive damage to lowest HP enemy and creates protective shield."
	char.ability_value_tier1 = 25
	char.ability_secondary_tier1 = 30
	char.ability_value_tier2 = 35
	char.ability_secondary_tier2 = 45
	char.ability_value_tier3 = 45
	char.ability_secondary_tier3 = 60
	char.unlock_cost = 800
	char.unlock_tier = 4
	characters["valkyrie"] = char

func create_warden():
	var char = create_character_base()
	char.id = "warden"
	char.character_name = "Thorn Earthshield"
	char.character_class = "Warden"
	char.class_type = "Support"
	char.color = Color(0.4, 0.6, 0.3, 1)
	char.ability_name = "Healing Grove"
	char.ability_description = "Place a healing zone. Heals 1 HP per block in zone each turn for 5 turns."
	char.ability_value_tier1 = 2
	char.ability_value_tier2 = 3
	char.ability_value_tier3 = 4
	char.ability_duration_tier1 = 5
	char.ability_duration_tier2 = 5
	char.ability_duration_tier3 = 5
	char.unlock_cost = 800
	char.unlock_tier = 4
	characters["warden"] = char

func create_chronomancer():
	var char = create_character_base()
	char.id = "chronomancer"
	char.character_name = "Raistlin Timeweaver"
	char.character_class = "Chronomancer"
	char.class_type = "Utility"
	char.color = Color(0.5, 0.7, 0.9, 1)
	char.ability_name = "Time Warp"
	char.ability_description = "Delays all enemies and grants player an extra turn."
	char.ability_value_tier1 = 1
	char.ability_value_tier2 = 2
	char.ability_value_tier3 = 3
	char.unlock_cost = 800
	char.unlock_tier = 4
	characters["chronomancer"] = char

# TIER 5 - 1000 COST

func create_geomancer():
	var char = create_character_base()
	char.id = "geomancer"
	char.character_name = "Willow Stoneheart"
	char.character_class = "Geomancer"
	char.class_type = "Hybrid"
	char.color = Color(0.55, 0.4, 0.25, 1)
	char.ability_name = "Earthquake"
	char.ability_description = "Removes obstacles, deals damage, converts neutral blocks to earth blocks."
	char.ability_value_tier1 = 15
	char.ability_secondary_tier1 = 5
	char.ability_value_tier2 = 22
	char.ability_secondary_tier2 = 8
	char.ability_value_tier3 = 30
	char.ability_secondary_tier3 = 12
	char.unlock_cost = 1000
	char.unlock_tier = 5
	characters["geomancer"] = char

func create_inquisitor():
	var char = create_character_base()
	char.id = "inquisitor"
	char.character_name = "Jaichim Carridin"
	char.character_class = "Inquisitor"
	char.class_type = "DPS"
	char.color = Color(0.8, 0.75, 0.5, 1)
	char.ability_name = "Divine Retribution"
	char.ability_description = "Deals damage equal to a percentage of total damage party has taken this battle."
	char.ability_value_tier1 = 0.5
	char.ability_value_tier2 = 0.75
	char.ability_value_tier3 = 1.0
	char.unlock_cost = 1000
	char.unlock_tier = 5
	characters["inquisitor"] = char

func create_blood_knight():
	var char = create_character_base()
	char.id = "blood_knight"
	char.character_name = "Leif Eryx"
	char.character_class = "Blood Knight"
	char.class_type = "DPS"
	char.color = Color(0.7, 0.1, 0.1, 1)
	char.ability_name = "Crimson Strike"
	char.ability_description = "Deals bonus damage based on party's missing health."
	char.ability_value_tier1 = 10
	char.ability_secondary_tier1 = 0.5
	char.ability_value_tier2 = 15
	char.ability_secondary_tier2 = 0.5
	char.ability_value_tier3 = 20
	char.ability_secondary_tier3 = 0.5
	char.unlock_cost = 1000
	char.unlock_tier = 5
	characters["blood_knight"] = char

# TIER 6 - 1200 COST

func create_fateweaver():
	var char = create_character_base()
	char.id = "fateweaver"
	char.character_name = "Moirai Threadspinner"
	char.character_class = "Fateweaver"
	char.class_type = "Utility"
	char.color = Color(0.7, 0.6, 0.9, 1)
	char.ability_name = "Prophecy"
	char.ability_description = "Next pieces are all one color (not Fateweaver's color)."
	char.ability_value_tier1 = 2
	char.ability_value_tier2 = 3
	char.ability_value_tier3 = 4
	char.unlock_cost = 1200
	char.unlock_tier = 6
	characters["fateweaver"] = char

func create_archmage():
	var char = create_character_base()
	char.id = "archmage"
	char.character_name = "Mairwen The Wise"
	char.character_class = "Archmage"
	char.class_type = "Support"
	char.color = Color(0.5, 0.3, 0.8, 1)
	char.ability_name = "Elemental Fusion"
	char.ability_description = "Converts neutral blocks to character colors and grants power."
	char.ability_value_tier1 = 12
	char.ability_secondary_tier1 = 2
	char.ability_value_tier2 = 18
	char.ability_secondary_tier2 = 3
	char.ability_value_tier3 = 24
	char.ability_secondary_tier3 = 4
	char.unlock_cost = 1200
	char.unlock_tier = 6
	characters["archmage"] = char

func create_dreadknight():
	var char = create_character_base()
	char.id = "dreadknight"
	char.character_name = "Mortis Hollowsoul"
	char.character_class = "Dreadknight"
	char.class_type = "Tank"
	char.color = Color(0.2, 0.2, 0.25, 1)
	char.ability_name = "Death's Embrace"
	char.ability_description = "Sacrifice HP for massive AoE damage and 2 turns of immunity."
	char.ability_value_tier1 = 2
	char.ability_secondary_tier1 = 0.25
	char.ability_duration_tier1 = 2
	char.ability_value_tier2 = 3
	char.ability_secondary_tier2 = 0.25
	char.ability_duration_tier2 = 2
	char.ability_value_tier3 = 4
	char.ability_secondary_tier3 = 0.25
	char.ability_duration_tier3 = 2
	char.unlock_cost = 1200
	char.unlock_tier = 6
	characters["dreadknight"] = char

# TIER 7 - 1500 COST

func create_runemaster():
	var char = create_character_base()
	char.id = "runemaster"
	char.character_name = "Rune Inscriber"
	char.character_class = "Runemaster"
	char.class_type = "DPS"
	char.color = Color(0.9, 0.5, 0.2, 1)
	char.ability_name = "Rune Trap"
	char.ability_description = "Place a damage rune. Deals damage per block inside each turn for 5 turns."
	char.ability_value_tier1 = 3
	char.ability_secondary_tier1 = 2
	char.ability_duration_tier1 = 5
	char.ability_value_tier2 = 4
	char.ability_secondary_tier2 = 3
	char.ability_duration_tier2 = 5
	char.ability_value_tier3 = 5
	char.ability_secondary_tier3 = 4
	char.ability_duration_tier3 = 5
	char.unlock_cost = 1500
	char.unlock_tier = 7
	characters["runemaster"] = char

func create_spellblade():
	var char = create_character_base()
	char.id = "spellblade"
	char.character_name = "Arcane Edgewalker"
	char.character_class = "Spellblade"
	char.class_type = "DPS"
	char.color = Color(0.4, 0.7, 0.8, 1)
	char.ability_name = "Arcane Purge"
	char.ability_description = "Removes most abundant colored block and deals damage per block."
	char.ability_value_tier1 = 2
	char.ability_value_tier2 = 3
	char.ability_value_tier3 = 4
	char.unlock_cost = 1500
	char.unlock_tier = 7
	characters["spellblade"] = char

func create_templar():
	var char = create_character_base()
	char.id = "templar"
	char.character_name = "Geoffroi de Charney"
	char.character_class = "Templar"
	char.class_type = "Tank"
	char.color = Color(0.95, 0.85, 0.6, 1)
	char.ability_name = "Crusader's Aegis"
	char.ability_description = "Damage immunity for several turns. All damage becomes healing instead."
	char.ability_duration_tier1 = 3
	char.ability_duration_tier2 = 5
	char.ability_duration_tier3 = 7
	char.unlock_cost = 1500
	char.unlock_tier = 7
	characters["templar"] = char

# TIER 8 - 2000 COST

func create_elementalist():
	var char = create_character_base()
	char.id = "elementalist"
	char.character_name = "Primal Stormbringer"
	char.character_class = "Elementalist"
	char.class_type = "DPS"
	char.color = Color(0.3, 0.8, 0.7, 1)
	char.ability_name = "Cataclysm"
	char.ability_description = "Destroys all fire/ice/lightning/earth blocks and deals damage for each."
	char.ability_value_tier1 = 3
	char.ability_value_tier2 = 4
	char.ability_value_tier3 = 5
	char.unlock_cost = 2000
	char.unlock_tier = 8
	characters["elementalist"] = char

func create_lightbringer():
	var char = create_character_base()
	char.id = "lightbringer"
	char.character_name = "Radiance Dawnbringer"
	char.character_class = "Lightbringer"
	char.class_type = "Support"
	char.color = Color(1.0, 0.95, 0.7, 1)
	char.ability_name = "Solar Flare"
	char.ability_description = "Heals party, creates shield, blinds enemies (50% miss chance)."
	char.ability_value_tier1 = 40
	char.ability_secondary_tier1 = 30
	char.ability_value_tier2 = 60
	char.ability_secondary_tier2 = 45
	char.ability_value_tier3 = 80
	char.ability_secondary_tier3 = 60
	char.unlock_cost = 2000
	char.unlock_tier = 8
	characters["lightbringer"] = char

func create_voidwalker():
	var char = create_character_base()
	char.id = "voidwalker"
	char.character_name = "Void Shadowstep"
	char.character_class = "Voidwalker"
	char.class_type = "DPS"
	char.color = Color(0.15, 0.1, 0.2, 1)
	char.ability_name = "Void Rift"
	char.ability_description = "Removes tallest column, deals damage, stuns top enemy."
	char.ability_value_tier1 = 2
	char.ability_value_tier2 = 3
	char.ability_value_tier3 = 4
	char.unlock_cost = 2000
	char.unlock_tier = 8
	characters["voidwalker"] = char

# TIER 9 - 2500 COST

func create_stormlord():
	var char = create_character_base()
	char.id = "stormlord"
	char.character_name = "Thunder Skybreaker"
	char.character_class = "Stormlord"
	char.class_type = "DPS"
	char.color = Color(0.2, 0.5, 0.9, 1)
	char.ability_name = "Maelstrom"
	char.ability_description = "Adds permanent lightning strikes. Party gains +25% damage per strike. Max 4 strikes."
	char.ability_value_tier1 = 3
	char.ability_secondary_tier1 = 2
	char.ability_value_tier2 = 4
	char.ability_secondary_tier2 = 3
	char.ability_value_tier3 = 5
	char.ability_secondary_tier3 = 4
	char.special_data = {
		"max_strikes": 4
	}
	char.unlock_cost = 2500
	char.unlock_tier = 9
	characters["stormlord"] = char

func create_archdruid():
	var char = create_character_base()
	char.id = "archdruid"
	char.character_name = "Ancient Rootkeeper"
	char.character_class = "Archdruid"
	char.class_type = "Support"
	char.color = Color(0.2, 0.6, 0.2, 1)
	char.ability_name = "World Tree"
	char.ability_description = "Creates permanent tree that heals, damages enemies, and removes obstacles each turn."
	char.ability_value_tier1 = 8
	char.ability_secondary_tier1 = 1
	char.ability_value_tier2 = 12
	char.ability_secondary_tier2 = 2
	char.ability_value_tier3 = 16
	char.ability_secondary_tier3 = 3
	char.unlock_cost = 2500
	char.unlock_tier = 9
	characters["archdruid"] = char

func create_archon():
	var char = create_character_base()
	char.id = "archon"
	char.character_name = "Celestial Ascendant"
	char.character_class = "Archon"
	char.class_type = "Hybrid"
	char.color = Color(0.95, 0.95, 1.0, 1)
	char.ability_name = "Ascension"
	char.ability_description = "Transforms all blocks to white, matches all, deals damage and heals per block."
	char.ability_value_tier1 = 1
	char.ability_secondary_tier1 = 1
	char.ability_value_tier2 = 1.5
	char.ability_secondary_tier2 = 1.5
	char.ability_value_tier3 = 2
	char.ability_secondary_tier3 = 2
	char.unlock_cost = 2500
	char.unlock_tier = 9
	characters["archon"] = char

func create_demonologist():
	var char = create_character_base()
	char.id = "demonologist"
	char.character_name = "Infernal Summoner"
	char.character_class = "Demonologist"
	char.class_type = "DPS"
	char.color = Color(0.6, 0.1, 0.15, 1)
	char.ability_name = "Infernal Legion"
	char.ability_description = "Summons a demon that attacks independently for 5 turns."
	char.ability_duration_tier1 = 5
	char.ability_duration_tier2 = 5
	char.ability_duration_tier3 = 5
	char.special_data = {
		"demons": [
			{"name": "Imp", "damage": [5, 8, 12], "weight": [40, 30, 20]},
			{"name": "Hellhound", "damage": [10, 15, 20], "weight": [30, 30, 25]},
			{"name": "Fiend", "damage": [15, 22, 30], "weight": [20, 25, 30]},
			{"name": "Pit Lord", "damage": [25, 35, 50], "weight": [8, 12, 18]},
			{"name": "Archfiend", "damage": [40, 60, 80], "weight": [2, 3, 7]}
		]
	}
	char.unlock_cost = 2500
	char.unlock_tier = 9
	characters["demonologist"] = char

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

func get_characters_by_class_type(class_type: String) -> Array:
	"""Get all characters of a specific class type (DPS, Tank, Support, Hybrid, Utility)"""
	var result = []
	for char_id in characters:
		if characters[char_id].class_type == class_type:
			result.append(char_id)
	return result

func get_unlockable_characters() -> Array:
	"""Get all non-starter characters"""
	var result = []
	for char_id in characters:
		if not characters[char_id].is_starter:
			result.append(char_id)
	return result

func get_character_unlock_cost(character_id: String) -> int:
	"""Get the unlock cost for a character"""
	if characters.has(character_id):
		return characters[character_id].unlock_cost
	return 0

func is_character_starter(character_id: String) -> bool:
	"""Check if a character is a starter character"""
	if characters.has(character_id):
		return characters[character_id].is_starter
	return false
