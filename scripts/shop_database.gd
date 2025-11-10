# ShopDatabase.gd - Autoload singleton
extends Node

class ShopItem:
	var id: String
	var name: String
	var description: String
	var cost: int
	var category: String  # "health", "relic"
	var item_type: String  # specific type within category
	var rarity: String = "common"  # "common", "rare", "epic"
	var unlock_requirement: String = ""  # character ID if requires unlock
	var max_purchases: int = -1  # -1 = unlimited, for this run
	var data: Dictionary = {}  # Additional item data

var shop_items: Dictionary = {}

func _ready():
	setup_shop_items()

func setup_shop_items():
	"""Define all shop items"""
	
	# ========== HEALTH ==========
	add_item(
		"max_hp_small", 
		"Small Fortitude Elixir", 
		"Increase Max HP by 20 for this run", 
		30, 
		"health", 
		"max_hp", 
		"common",
		"", 
		3, 
		{"amount": 20}
	)
	
	add_item(
		"max_hp_medium", 
		"Fortitude Elixir", 
		"Increase Max HP by 40 for this run", 
		50, 
		"health", 
		"max_hp", 
		"rare",
		"", 
		2, 
		{"amount": 40}
	)
	
	add_item(
		"max_hp_large", 
		"Greater Fortitude Elixir", 
		"Increase Max HP by 60 for this run", 
		80, 
		"health", 
		"max_hp", 
		"epic",
		"", 
		1, 
		{"amount": 60}
	)
	
	# ========== CHARACTER POWER GAIN RELICS ==========
	# ALL CHARACTERS (Tier 0-9)
	var characters = [
		# Tier 0
		"knight", "wizard", "cleric",
		# Tier 1
		"rogue", "paladin", "berserker", "druid",
		# Tier 2
		"necromancer", "ranger", "enchanter", "monk",
		# Tier 3
		"beastmaster", "bladesinger", "shadowmancer",
		# Tier 4
		"valkyrie", "warden", "chronomancer",
		# Tier 5
		"geomancer", "inquisitor", "blood_knight",
		# Tier 6
		"fateweaver", "archmage", "dreadknight",
		# Tier 7
		"runemaster", "spellblade", "templar",
		# Tier 8
		"elementalist", "lightbringer", "voidwalker",
		# Tier 9
		"stormlord", "archdruid", "archon", "demonologist"
	]
	
	for char_id in characters:
		var char_data = CharacterDatabase.get_character(char_id)
		if not char_data:
			continue
		
		# Minor version (+2 power per block)
		add_item(
			char_id + "_power_minor",
			char_data.character_name + "'s Minor Crest",
			"Matching " + char_data.character_name + "'s blocks grants +2 extra power",
			40,
			"relic",
			"power_gain",
			"common",
			char_id,
			1,
			{"character": char_id, "bonus": 2}
		)
		
		# Major version (+4 power per block)
		add_item(
			char_id + "_power_major",
			char_data.character_name + "'s Major Crest",
			"Matching " + char_data.character_name + "'s blocks grants +4 extra power",
			80,
			"relic",
			"power_gain",
			"epic",
			char_id,
			1,
			{"character": char_id, "bonus": 4}
		)
	
	# ========== CHARACTER ABILITY BOOST RELICS ==========
	for char_id in characters:
		var char_data = CharacterDatabase.get_character(char_id)
		if not char_data:
			continue
		
		# Minor version (+25% ability power)
		add_item(
			char_id + "_ability_minor",
			char_data.character_name + "'s Minor Focus",
			"Increases " + char_data.character_name + "'s ability effectiveness by 25%",
			50,
			"relic",
			"ability_boost",
			"rare",
			char_id,
			1,
			{"character": char_id, "multiplier": 1.25}
		)
		
		# Major version (+50% ability power)
		add_item(
			char_id + "_ability_major",
			char_data.character_name + "'s Major Focus",
			"Increases " + char_data.character_name + "'s ability effectiveness by 50%",
			100,
			"relic",
			"ability_boost",
			"epic",
			char_id,
			1,
			{"character": char_id, "multiplier": 1.5}
		)
	
	# ========== CHARACTER POWER CONVERTER RELICS ==========
	for char_id in characters:
		var char_data = CharacterDatabase.get_character(char_id)
		if not char_data:
			continue
		
		# Minor version (+5 power per neutral block matched)
		add_item(
			char_id + "_converter_minor",
			char_data.character_name + "'s Minor Converter",
			"Matching neutral blocks grants " + char_data.character_name + " +5 power",
			45,
			"relic",
			"power_converter",
			"rare",
			char_id,
			1,
			{"character": char_id, "power_per_block": 5}
		)
		
		# Major version (+10 power per neutral block matched)
		add_item(
			char_id + "_converter_major",
			char_data.character_name + "'s Major Converter",
			"Matching neutral blocks grants " + char_data.character_name + " +10 power",
			90,
			"relic",
			"power_converter",
			"epic",
			char_id,
			1,
			{"character": char_id, "power_per_block": 10}
		)
	
	# ========== COMBO MULTIPLIER ==========
	add_item(
		"combo_minor",
		"Minor Combo Medal",
		"Cascade matches deal +25% damage",
		50,
		"relic",
		"combo_boost",
		"rare",
		"",
		1,
		{"multiplier": 1.25}
	)
	
	add_item(
		"combo_major",
		"Major Combo Medal",
		"Cascade matches deal +50% damage",
		100,
		"relic",
		"combo_boost",
		"epic",
		"",
		1,
		{"multiplier": 1.5}
	)
	
	# ========== BLOCK CONVERTER ==========
	add_item(
		"block_converter",
		"Prismatic Lens",
		"Neutral blocks can now spawn as character colors",
		70,
		"relic",
		"block_converter",
		"epic",
		"",
		1,
		{}
	)
	
	# ========== LUCKY COIN ==========
	add_item(
		"coin_minor",
		"Minor Lucky Charm",
		"Earn +25% coins from battles",
		35,
		"relic",
		"coin_boost",
		"common",
		"",
		1,
		{"multiplier": 1.25}
	)
	
	add_item(
		"coin_major",
		"Major Lucky Charm",
		"Earn +50% coins from battles",
		70,
		"relic",
		"coin_boost",
		"rare",
		"",
		1,
		{"multiplier": 1.5}
	)
	
	# ========== TIME WARPER ==========
	add_item(
		"time_warper",
		"Time Warper",
		"Take 2 player turns for every 1 enemy turn",
		150,
		"relic",
		"time_warper",
		"epic",
		"",
		1,
		{}
	)
	
	# ========== NEW UNIVERSAL RELICS ==========
	
	# Treasure Hunt Relics
	add_item(
		"treasure_map_minor",
		"Minor Treasure Hunter's Map",
		"Start treasure hunts with +1 shovel (4 total)",
		40,
		"relic",
		"treasure_shovels",
		"common",
		"",
		1,
		{"bonus_shovels": 1}
	)
	
	add_item(
		"treasure_map_major",
		"Major Treasure Hunter's Map",
		"Start treasure hunts with +2 shovels (5 total)",
		80,
		"relic",
		"treasure_shovels",
		"rare",
		"",
		1,
		{"bonus_shovels": 2}
	)
	
	# Life-Saving Relics (One-Time Use)
	add_item(
		"phoenix_feather_minor",
		"Minor Phoenix Feather",
		"Once per run, restore 25% HP when you would die, then breaks",
		60,
		"relic",
		"phoenix_feather",
		"rare",
		"",
		1,
		{"heal_percent": 0.25}
	)
	
	add_item(
		"phoenix_feather_major",
		"Major Phoenix Feather",
		"Once per run, restore 50% HP when you would die, then breaks",
		120,
		"relic",
		"phoenix_feather",
		"epic",
		"",
		1,
		{"heal_percent": 0.5}
	)
	
	# Damage Boosting
	add_item(
		"executioner_axe",
		"Executioner's Axe",
		"Deal +50% damage to enemies below 25% HP",
		70,
		"relic",
		"execute",
		"rare",
		"",
		1,
		{"damage_bonus": 0.5, "hp_threshold": 0.25}
	)
	
	add_item(
		"giant_slayer",
		"Giant Slayer",
		"Deal +25% damage to Elite and Boss enemies",
		100,
		"relic",
		"giant_slayer",
		"epic",
		"",
		1,
		{"damage_bonus": 0.25}
	)
	
	add_item(
		"first_strike",
		"First Strike Medal",
		"Deal +3 damage on the first match each turn",
		45,
		"relic",
		"first_strike",
		"common",
		"",
		1,
		{"bonus_damage": 3}
	)
	
	add_item(
		"finishing_blow",
		"Finishing Blow",
		"When killing an enemy, excess damage carries over to next enemy",
		65,
		"relic",
		"overkill",
		"rare",
		"",
		1,
		{}
	)
	
	# Block Manipulation
	add_item(
		"alchemist_stone",
		"Alchemist's Stone",
		"15% chance to convert a random neutral block to your color each turn",
		75,
		"relic",
		"block_alchemy",
		"rare",
		"",
		1,
		{"conversion_chance": 0.15}
	)
	
	add_item(
		"block_duplicator",
		"Block Duplicator",
		"When you match 5+ blocks, spawn 1 extra block of that color at the top",
		110,
		"relic",
		"block_spawn",
		"epic",
		"",
		1,
		{"min_match": 5}
	)
	
	add_item(
		"chaos_orb",
		"Chaos Orb",
		"At the start of each turn, shuffle 3 random blocks on the grid",
		60,
		"relic",
		"chaos_shuffle",
		"rare",
		"",
		1,
		{"blocks_to_shuffle": 3}
	)
	
	add_item(
		"rainbow_prism",
		"Rainbow Prism",
		"Wild blocks can match with any color (spawns 1 wild block every 3 turns)",
		130,
		"relic",
		"wild_blocks",
		"epic",
		"",
		1,
		{"spawn_frequency": 3}
	)
	
	# Power Generation
	add_item(
		"meditation_beads",
		"Meditation Beads",
		"All characters start each battle with +20 power",
		50,
		"relic",
		"starting_power_bonus",
		"common",
		"",
		1,
		{"power_bonus": 20}
	)
	
	add_item(
		"power_surge",
		"Power Surge Charm",
		"Matching 5+ blocks grants +10 extra power to that character",
		85,
		"relic",
		"power_surge",
		"rare",
		"",
		1,
		{"min_blocks": 5, "bonus_power": 10}
	)
	
	add_item(
		"neutral_affinity",
		"Neutral Affinity",
		"Matching neutral blocks grants +3 power to all characters",
		40,
		"relic",
		"neutral_power",
		"common",
		"",
		1,
		{"power_per_block": 3}
	)
	
	add_item(
		"teamwork_charm",
		"Teamwork Charm",
		"When one character uses their ability, the other 2 gain +15 power",
		110,
		"relic",
		"teamwork",
		"epic",
		"",
		1,
		{"power_bonus": 15}
	)
	
	# Turn/Time Manipulation
	add_item(
		"hourglass",
		"Hourglass of Patience",
		"Enemy attack cooldowns are +1 turn longer",
		90,
		"relic",
		"slow_enemies",
		"rare",
		"",
		1,
		{"cooldown_bonus": 1}
	)
	
	# Defense & Survival
	add_item(
		"adamantine_armor",
		"Adamantine Armor",
		"Reduce all damage taken by 2 (minimum 1 damage)",
		140,
		"relic",
		"damage_reduction",
		"epic",
		"",
		1,
		{"flat_reduction": 2}
	)
	
	add_item(
		"regeneration_ring",
		"Regeneration Ring",
		"Heal 1 HP every 3 player turns",
		70,
		"relic",
		"passive_regen",
		"rare",
		"",
		1,
		{"heal_amount": 1, "turn_frequency": 3}
	)
	
	add_item(
		"last_stand",
		"Last Stand Banner",
		"When below 30% HP, all damage dealt increases by 50%",
		100,
		"relic",
		"last_stand",
		"epic",
		"",
		1,
		{"hp_threshold": 0.3, "damage_bonus": 0.5}
	)
	
	# Economic
	add_item(
		"merchant_discount",
		"Merchant's Discount Card",
		"All shop items cost 30% less",
		200,
		"relic",
		"shop_discount",
		"epic",
		"",
		1,
		{"discount_percent": 0.3}
	)
	
	add_item(
		"coin_magnet",
		"Coin Magnet",
		"Treasure hunts give +50% more coins",
		45,
		"relic",
		"treasure_coins",
		"common",
		"",
		1,
		{"coin_multiplier": 1.5}
	)
	
	# Grid/Obstacle Management
	add_item(
		"obstacle_destroyer",
		"Obstacle Destroyer",
		"Remove 1 random obstacle at the start of your turn",
		75,
		"relic",
		"auto_clear_obstacle",
		"rare",
		"",
		1,
		{}
	)
	
	add_item(
		"cleansing_light",
		"Cleansing Light",
		"Automatically destroy the first obstacle placed each battle",
		95,
		"relic",
		"first_obstacle_immunity",
		"epic",
		"",
		1,
		{}
	)
	
	# Special Mechanics
	add_item(
		"lucky_rabbits_foot",
		"Lucky Rabbit's Foot",
		"20% chance to gain 50 power back after using an ability",
		80,
		"relic",
		"power_refund",
		"rare",
		"",
		1,
		{"refund_chance": 0.2, "refund_amount": 50}
	)
	
	add_item(
		"vengeful_spirit",
		"Vengeful Spirit",
		"When you take 15+ damage in one hit, deal 10 damage back",
		70,
		"relic",
		"thorns",
		"rare",
		"",
		1,
		{"damage_threshold": 15, "reflect_damage": 10}
	)
	
	add_item(
		"chain_reaction",
		"Chain Reaction",
		"Combos start at x2 instead of x1",
		120,
		"relic",
		"combo_start",
		"epic",
		"",
		1,
		{"starting_combo": 2}
	)
	
	add_item(
		"perfectionist_crown",
		"Perfectionist's Crown",
		"Matching exactly 5 blocks deals +5 damage and grants +15 power",
		150,
		"relic",
		"perfect_match",
		"epic",
		"",
		1,
		{"exact_blocks": 5, "bonus_damage": 5, "bonus_power": 15}
	)
	
	# Risk/Reward
	add_item(
		"berserker_rage",
		"Berserker's Rage",
		"Deal +1 damage for every 10 HP you're missing",
		60,
		"relic",
		"missing_hp_damage",
		"rare",
		"",
		1,
		{"damage_per_10hp": 1}
	)
	
	add_item(
		"glass_cannon",
		"Glass Cannon",
		"Deal +30% damage but take +15% damage",
		55,
		"relic",
		"glass_cannon",
		"rare",
		"",
		1,
		{"damage_bonus": 0.3, "damage_taken_penalty": 0.15}
	)
	
	add_item(
		"all_or_nothing",
		"All or Nothing",
		"Combos of 3+ deal double damage, but solo matches deal -2 damage",
		100,
		"relic",
		"combo_or_bust",
		"epic",
		"",
		1,
		{"combo_multiplier": 2.0, "solo_penalty": 2}
	)
	
	# Replacement Relics
	add_item(
		"second_wind",
		"Second Wind",
		"When an ability is used, that character immediately gains +25 power",
		70,
		"relic",
		"ability_power_gain",
		"rare",
		"",
		1,
		{"power_gain": 25}
	)
	
	add_item(
		"block_breaker",
		"Block Breaker",
		"Matching 4+ blocks of the same color destroys 1 adjacent obstacle",
		50,
		"relic",
		"match_clear_obstacle",
		"common",
		"",
		1,
		{"min_blocks": 4}
	)
	
	add_item(
		"spell_echo",
		"Spell Echo",
		"The first ability used each battle triggers twice (50% effectiveness on second cast)",
		140,
		"relic",
		"first_ability_double",
		"epic",
		"",
		1,
		{"second_cast_multiplier": 0.5}
	)

func add_item(id: String, name: String, desc: String, cost: int, category: String, 
			  item_type: String, rarity: String, unlock_req: String, max_purchases: int, data: Dictionary):
	"""Add item to shop database"""
	var item = ShopItem.new()
	item.id = id
	item.name = name
	item.description = desc
	item.cost = cost
	item.category = category
	item.item_type = item_type
	item.rarity = rarity
	item.unlock_requirement = unlock_req
	item.max_purchases = max_purchases
	item.data = data
	shop_items[id] = item

func get_item(item_id: String) -> ShopItem:
	"""Get item by ID"""
	return shop_items.get(item_id)

func get_available_shop_items(purchased_items: Dictionary, num_items: int = 6) -> Array:
	"""Get random available items for shop (filters by unlocks and purchase limits)"""
	var available = []
	var current_party = GameManager.get_current_party()
	
	for item_id in shop_items:
		var item = shop_items[item_id]
		
		# Check unlock requirement
		if item.unlock_requirement != "":
			# For character-specific relics, only show if character is in party
			if not current_party.has(item.unlock_requirement):
				continue
			# Still check if character is unlocked
			if not GameManager.is_character_unlocked(item.unlock_requirement):
				continue
		
		# Check if already purchased (for items with max_purchases = 1)
		if item.max_purchases == 1 and purchased_items.has(item_id):
			continue
		
		# Check purchase limit
		if item.max_purchases > 0:
			var times_purchased = purchased_items.get(item_id, 0)
			if times_purchased >= item.max_purchases:
				continue
		
		available.append(item)
	
	# Shuffle and return random selection
	available.shuffle()
	
	# Return up to num_items
	var result = []
	for i in range(min(num_items, available.size())):
		result.append(available[i])
	
	return result

func get_rarity_color(rarity: String) -> Color:
	"""Get color for rarity"""
	match rarity:
		"common":
			return Color("#ECF0F1")  # Light gray
		"rare":
			return Color("#3498DB")  # Blue
		"epic":
			return Color("#9B59B6")  # Purple
		_:
			return Color.WHITE
