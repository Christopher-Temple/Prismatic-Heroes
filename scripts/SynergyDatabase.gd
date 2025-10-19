# SynergyDatabase.gd - Autoload
extends Node

# Synergy name lookup table
var synergy_names = {}

func _ready():
	print("SynergyDatabase initializing...")
	setup_synergy_names()
	print("SynergyDatabase loaded!")

func setup_synergy_names():
	"""Create all synergy combination names"""
	
	# TWO-CHARACTER SYNERGIES
	
	# Knight combinations
	synergy_names[["knight", "wizard"]] = "Arcane Guard"
	synergy_names[["knight", "cleric"]] = "Holy Bulwark"
	synergy_names[["knight", "rogue"]] = "Shadow Shield"
	synergy_names[["knight", "paladin"]] = "Divine Fortress"
	synergy_names[["knight", "berserker"]] = "Iron Fury"
	synergy_names[["knight", "druid"]] = "Nature's Armor"
	synergy_names[["knight", "necromancer"]] = "Death's Sentinel"
	synergy_names[["knight", "ranger"]] = "Tactical Defense"
	synergy_names[["knight", "enchanter"]] = "Warded Bastion"
	synergy_names[["knight", "monk"]] = "Zen Protector"
	synergy_names[["knight", "beastmaster"]] = "Primal Guardian"
	synergy_names[["knight", "bladesinger"]] = "Dancing Aegis"
	
	# Wizard combinations
	synergy_names[["wizard", "cleric"]] = "Celestial Arcana"
	synergy_names[["wizard", "rogue"]] = "Shadowflame"
	synergy_names[["wizard", "paladin"]] = "Radiant Sorcery"
	synergy_names[["wizard", "berserker"]] = "Raging Inferno"
	synergy_names[["wizard", "druid"]] = "Stormblossom"
	synergy_names[["wizard", "necromancer"]] = "Dark Ritual"
	synergy_names[["wizard", "ranger"]] = "Arcane Volley"
	synergy_names[["wizard", "enchanter"]] = "Spellweaver's Bond"
	synergy_names[["wizard", "monk"]] = "Mystic Harmony"
	synergy_names[["wizard", "beastmaster"]] = "Feral Magic"
	synergy_names[["wizard", "bladesinger"]] = "Spell Blade"
	
	# Cleric combinations
	synergy_names[["cleric", "rogue"]] = "Sanctified Strike"
	synergy_names[["cleric", "paladin"]] = "Light's Chosen"
	synergy_names[["cleric", "berserker"]] = "Blessed Rage"
	synergy_names[["cleric", "druid"]] = "Life's Embrace"
	synergy_names[["cleric", "necromancer"]] = "Soul Reaver"
	synergy_names[["cleric", "ranger"]] = "Hunter's Prayer"
	synergy_names[["cleric", "enchanter"]] = "Sacred Charm"
	synergy_names[["cleric", "monk"]] = "Tranquil Grace"
	synergy_names[["cleric", "beastmaster"]] = "Nature's Blessing"
	synergy_names[["cleric", "bladesinger"]] = "Graceful Benediction"
	
	# Rogue combinations
	synergy_names[["rogue", "paladin"]] = "Twilight Justice"
	synergy_names[["rogue", "berserker"]] = "Savage Ambush"
	synergy_names[["rogue", "druid"]] = "Wild Hunt"
	synergy_names[["rogue", "necromancer"]] = "Nightmare's Edge"
	synergy_names[["rogue", "ranger"]] = "Twin Shadows"
	synergy_names[["rogue", "enchanter"]] = "Illusory Assassin"
	synergy_names[["rogue", "monk"]] = "Silent Strike"
	synergy_names[["rogue", "beastmaster"]] = "Predator's Mark"
	synergy_names[["rogue", "bladesinger"]] = "Phantom Dance"
	
	# Paladin combinations
	synergy_names[["paladin", "berserker"]] = "Righteous Wrath"
	synergy_names[["paladin", "druid"]] = "Sacred Grove"
	synergy_names[["paladin", "necromancer"]] = "Purging Flame"
	synergy_names[["paladin", "ranger"]] = "Divine Marksman"
	synergy_names[["paladin", "enchanter"]] = "Blessed Ward"
	synergy_names[["paladin", "monk"]] = "Enlightened Crusader"
	synergy_names[["paladin", "beastmaster"]] = "Sacred Beast"
	synergy_names[["paladin", "bladesinger"]] = "Valiant Flourish"
	
	# Berserker combinations
	synergy_names[["berserker", "druid"]] = "Feral Fury"
	synergy_names[["berserker", "necromancer"]] = "Blood Reaper"
	synergy_names[["berserker", "ranger"]] = "Wild Barrage"
	synergy_names[["berserker", "enchanter"]] = "Frenzied Hex"
	synergy_names[["berserker", "monk"]] = "Controlled Chaos"
	synergy_names[["berserker", "beastmaster"]] = "Primal Rampage"
	synergy_names[["berserker", "bladesinger"]] = "Whirling Carnage"
	
	# Druid combinations
	synergy_names[["druid", "necromancer"]] = "Circle of Decay"
	synergy_names[["druid", "ranger"]] = "Forest's Vengeance"
	synergy_names[["druid", "enchanter"]] = "Verdant Charm"
	synergy_names[["druid", "monk"]] = "Natural Balance"
	synergy_names[["druid", "beastmaster"]] = "Alpha's Call"
	synergy_names[["druid", "bladesinger"]] = "Leaf on the Wind"
	
	# Necromancer combinations
	synergy_names[["necromancer", "ranger"]] = "Death's Arrow"
	synergy_names[["necromancer", "enchanter"]] = "Cursed Binding"
	synergy_names[["necromancer", "monk"]] = "Spirit Walker"
	synergy_names[["necromancer", "beastmaster"]] = "Undead Pack"
	synergy_names[["necromancer", "bladesinger"]] = "Reaper's Waltz"
	
	# Ranger combinations
	synergy_names[["ranger", "enchanter"]] = "Bewitched Arrows"
	synergy_names[["ranger", "monk"]] = "Patient Hunter"
	synergy_names[["ranger", "beastmaster"]] = "Companion's Shot"
	synergy_names[["ranger", "bladesinger"]] = "Piercing Rhythm"
	
	# Enchanter combinations
	synergy_names[["enchanter", "monk"]] = "Mind's Eye"
	synergy_names[["enchanter", "beastmaster"]] = "Charmed Beast"
	synergy_names[["enchanter", "bladesinger"]] = "Enchanted Blade"
	
	# Monk combinations
	synergy_names[["monk", "beastmaster"]] = "Spirit Animal"
	synergy_names[["monk", "bladesinger"]] = "Flowing Steel"
	
	# Beastmaster + Bladesinger
	synergy_names[["beastmaster", "bladesinger"]] = "Savage Elegance"
	
	# THREE-CHARACTER SYNERGIES (Key combinations)
	synergy_names[["knight", "wizard", "cleric"]] = "Legendary Trio"
	synergy_names[["knight", "paladin", "berserker"]] = "Unbreakable Vanguard"
	synergy_names[["wizard", "rogue", "berserker"]] = "Triple Threat"
	synergy_names[["wizard", "rogue", "ranger"]] = "Deadly Trinity"
	synergy_names[["wizard", "berserker", "ranger"]] = "Storm of Blades"
	synergy_names[["rogue", "berserker", "ranger"]] = "Assassin's Pact"
	synergy_names[["wizard", "rogue", "bladesinger"]] = "Shadow Storm"
	synergy_names[["wizard", "berserker", "bladesinger"]] = "Infernal Dance"
	synergy_names[["wizard", "ranger", "bladesinger"]] = "Arcane Barrage"
	synergy_names[["rogue", "berserker", "bladesinger"]] = "Crimson Tempest"
	synergy_names[["rogue", "ranger", "bladesinger"]] = "Silent Death"
	synergy_names[["berserker", "ranger", "bladesinger"]] = "Brutal Precision"
	synergy_names[["cleric", "druid", "enchanter"]] = "Harmony's Grace"
	synergy_names[["knight", "cleric", "paladin"]] = "Bastion of Light"
	synergy_names[["wizard", "cleric", "druid"]] = "Elemental Sanctuary"
	synergy_names[["knight", "wizard", "necromancer"]] = "Arcane Vanguard"
	synergy_names[["knight", "rogue", "ranger"]] = "Tactical Supremacy"
	synergy_names[["wizard", "necromancer", "monk"]] = "Ethereal Nexus"
	synergy_names[["cleric", "paladin", "monk"]] = "Holy Trinity"
	synergy_names[["druid", "beastmaster", "ranger"]] = "Wilderness Warband"
	synergy_names[["rogue", "enchanter", "bladesinger"]] = "Phantom Ensemble"
	synergy_names[["knight", "necromancer", "paladin"]] = "Twilight Order"
	synergy_names[["wizard", "druid", "monk"]] = "Elemental Wisdom"
	synergy_names[["berserker", "druid", "beastmaster"]] = "Savage Pack"
	synergy_names[["cleric", "necromancer", "paladin"]] = "Light and Shadow"
	synergy_names[["rogue", "monk", "bladesinger"]] = "Perfect Form"

func get_synergy_name(character_ids: Array) -> String:
	"""Get synergy name for character combination"""
	if character_ids.size() < 2:
		return ""
	
	# Sort for consistent lookup
	var sorted_ids = character_ids.duplicate()
	sorted_ids.sort()
	
	# Check if we have a named synergy
	if synergy_names.has(sorted_ids):
		return synergy_names[sorted_ids]
	
	# Fallback names
	if sorted_ids.size() == 2:
		return "Dual Strike"
	elif sorted_ids.size() == 3:
		return "Ultimate Synergy"
	
	return ""

func get_synergy_multiplier(num_characters: int) -> float:
	"""Get damage multiplier based on number of characters with full power"""
	match num_characters:
		2:
			return 1.25  # 25% bonus
		3:
			return 1.5   # 50% bonus
		_:
			return 1.0
