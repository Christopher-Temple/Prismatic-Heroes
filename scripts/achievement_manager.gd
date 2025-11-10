# AchievementManager.gd - Autoload Singleton
extends Node

const ACHIEVEMENTS_SAVE_PATH = "user://achievements.json"

# Achievement data structure
class Achievement:
	var id: String
	var name: String
	var description: String
	var icon: String  # Icon name or emoji
	var category: String  # "combat", "progression", "collection", "special"
	var is_unlocked: bool = false
	var unlock_date: String = ""
	var progress: int = 0
	var max_progress: int = 1
	var reward_coins: int = 0
	var is_secret: bool = false  # Hidden until unlocked

# All achievements
var achievements: Dictionary = {}

# Signals
signal achievement_unlocked(achievement_id: String)
signal achievement_progress(achievement_id: String, current: int, max: int)

func _ready():
	setup_achievements()
	load_achievements()

func setup_achievements():
	"""Define all achievements"""
	
	# === COMBAT ACHIEVEMENTS ===
	add_achievement("first_blood", "First Blood", "Defeat your first enemy", "⚔️", "combat", 0)
	add_achievement("combo_apprentice", "Combo Apprentice", "Achieve a 3x combo", "🔥", "combat", 0)
	add_achievement("combo_master", "Combo Master", "Achieve a 5x combo", "💥", "combat", 50)
	add_achievement("synergy_strike", "Synergy Strike", "Activate a character synergy", "⚡", "combat", 25)
	add_achievement("triple_synergy", "Ultimate Synergy", "Activate a 3-character synergy", "✨", "combat", 100)
	add_achievement("overkill", "Overkill", "Deal over 50 damage in a single match", "💀", "combat", 50)
	add_achievement("no_damage", "Untouchable", "Complete a battle without taking damage", "🛡️", "combat", 75)
	add_achievement("perfect_power", "Perfect Timing", "Use 3 character abilities in one turn", "⏰", "combat", 100)
	
	# === PROGRESSION ACHIEVEMENTS ===
	add_achievement("first_victory", "First Victory", "Complete your first run", "🏆", "progression", 100)
	add_achievement("floor_5", "Dungeon Delver", "Reach floor 5", "🗿", "progression", 50)
	add_achievement("floor_10", "Deep Explorer", "Reach floor 10", "⛰️", "progression", 150)
	add_achievement("boss_slayer", "Boss Slayer", "Defeat your first boss", "👑", "progression", 100)
	add_achievement("dragon_slayer", "Dragon Slayer", "Defeat the Ancient Red Dragon", "🐲", "progression", 150)
	add_achievement("lich_slayer", "Lich Slayer", "Defeat Archlich Malachar", "💀", "progression", 150)
	add_achievement("demon_slayer", "Demon Slayer", "Defeat the Infernal Tyrant", "😈", "progression", 150)
	add_achievement("speed_runner", "Speed Runner", "Complete a run in under 20 minutes", "⚡", "progression", 200, true)
	
	# === COLLECTION ACHIEVEMENTS ===
	add_achievement("unlock_tier1", "Growing Party", "Unlock all Tier 1 characters", "👥", "collection", 100)
	add_achievement("unlock_tier2", "Expanding Roster", "Unlock all Tier 2 characters", "🎖️", "collection", 200)
	add_achievement("unlock_tier3", "Master Recruiter", "Unlock all Tier 3 characters", "👑", "collection", 300)
	add_achievement("unlock_all", "Full Roster", "Unlock all characters", "🌟", "collection", 500)
	add_achievement("max_level", "Dedication", "Get a character to level 10", "📈", "collection", 150)
	add_achievement("all_max", "True Master", "Get all characters to level 10", "💎", "collection", 1000, true)
	add_achievement("coin_collector", "Coin Collector", "Accumulate 1000 coins total", "💰", "collection", 50)
	add_achievement("wealthy", "Wealthy Adventurer", "Accumulate 5000 coins total", "💎", "collection", 200)
	
	# === SPECIAL ACHIEVEMENTS ===
	add_achievement("lucky_strike", "Lucky Strike", "Find a relic in treasure", "🍀", "special", 50)
	add_achievement("shopping_spree", "Shopping Spree", "Purchase 5 items in one shop visit", "🛒", "special", 100)
	add_achievement("hoarder", "Hoarder", "Have 10 relics in a single run", "📦", "special", 150, true)
	add_achievement("minimalist", "Minimalist", "Complete a run with no relics", "🎯", "special", 300, true)
	add_achievement("pacifist", "Pacifist Route", "Complete 5 rest sites in one run", "☮️", "special", 100)
	add_achievement("gambler", "High Roller", "Win the gambling den bet", "🎲", "special", 25)
	add_achievement("treasure_hunter", "Treasure Hunter", "Dig up all treasure in one treasure room", "⛏️", "special", 100)
	add_achievement("beast_master", "Beast Collector", "Summon all 5 beast types with Beastmaster", "🐾", "special", 200)
	
	# === CHALLENGE ACHIEVEMENTS ===
	add_achievement("solo_tank", "Solo Tank", "Complete a run with 3 tank characters", "🛡️", "special", 200, true)
	add_achievement("solo_dps", "Solo DPS", "Complete a run with 3 DPS characters", "⚔️", "special", 200, true)
	add_achievement("solo_support", "Solo Support", "Complete a run with 3 support characters", "💚", "special", 200, true)
	add_achievement("glass_cannon", "Glass Cannon", "Complete a run without using any healing", "💔", "special", 300, true)
	add_achievement("deaths_door", "Death's Door", "Win a battle with 1 HP remaining", "💀", "special", 150, true)

func add_achievement(id: String, name: String, desc: String, icon: String, category: String, reward: int, secret: bool = false):
	"""Add an achievement to the database"""
	var achievement = Achievement.new()
	achievement.id = id
	achievement.name = name
	achievement.description = desc
	achievement.icon = icon
	achievement.category = category
	achievement.reward_coins = reward
	achievement.is_secret = secret
	achievements[id] = achievement

# === SAVE/LOAD ===

func save_achievements():
	"""Save achievements to separate file"""
	var save_data = {
		"version": 1,
		"achievements": {}
	}
	
	for id in achievements:
		var ach = achievements[id]
		save_data["achievements"][id] = {
			"unlocked": ach.is_unlocked,
			"unlock_date": ach.unlock_date,
			"progress": ach.progress
		}
	
	var file = FileAccess.open(ACHIEVEMENTS_SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		return true
	else:
		return false

func load_achievements():
	"""Load achievements from file"""
	if not FileAccess.file_exists(ACHIEVEMENTS_SAVE_PATH):
		return
	
	var file = FileAccess.open(ACHIEVEMENTS_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.data
			var saved_achievements = data.get("achievements", {})
			
			for id in saved_achievements:
				if achievements.has(id):
					achievements[id].is_unlocked = saved_achievements[id].get("unlocked", false)
					achievements[id].unlock_date = saved_achievements[id].get("unlock_date", "")
					achievements[id].progress = saved_achievements[id].get("progress", 0)
			
			
		else:
			return
	else:
		return

# === UNLOCK FUNCTIONS ===

func unlock_achievement(achievement_id: String):
	"""Unlock an achievement"""
	if not achievements.has(achievement_id):
		return
	
	var ach = achievements[achievement_id]
	
	if ach.is_unlocked:
		return  # Already unlocked
	
	ach.is_unlocked = true
	ach.unlock_date = Time.get_datetime_string_from_system()
	
	# Award coins
	if ach.reward_coins > 0:
		GameManager.add_coins(ach.reward_coins)
	
	save_achievements()
	achievement_unlocked.emit(achievement_id)
	
	# Show notification
	show_achievement_notification(ach)
	

func show_achievement_notification(ach: Achievement):
	"""Display achievement unlock notification (implement in UI)"""
	# This will be called by the UI to show a popup
	# For now, just emit the signal
	pass

func check_achievement(achievement_id: String) -> bool:
	"""Check if an achievement is unlocked"""
	if achievements.has(achievement_id):
		return achievements[achievement_id].is_unlocked
	return false

func get_achievement(achievement_id: String) -> Achievement:
	"""Get achievement data"""
	return achievements.get(achievement_id)

func get_all_achievements() -> Array:
	"""Get all achievement IDs"""
	return achievements.keys()

func get_achievements_by_category(category: String) -> Array:
	"""Get all achievements in a category"""
	var result = []
	for id in achievements:
		if achievements[id].category == category:
			result.append(id)
	return result

func get_unlocked_count() -> int:
	"""Get number of unlocked achievements"""
	var count = 0
	for id in achievements:
		if achievements[id].is_unlocked:
			count += 1
	return count

func get_total_count() -> int:
	"""Get total number of achievements"""
	return achievements.size()

func get_completion_percentage() -> float:
	"""Get achievement completion percentage"""
	if achievements.size() == 0:
		return 0.0
	return (float(get_unlocked_count()) / float(achievements.size())) * 100.0

# === TRACKING FUNCTIONS (Call these from game events) ===

func track_enemy_defeated(enemy_id: String):
	"""Track enemy defeat for achievements"""
	unlock_achievement("first_blood")
	
	# Boss-specific
	match enemy_id:
		"dragon_boss":
			unlock_achievement("boss_slayer")
			unlock_achievement("dragon_slayer")
		"lich_boss":
			unlock_achievement("boss_slayer")
			unlock_achievement("lich_slayer")
		"demon_boss":
			unlock_achievement("boss_slayer")
			unlock_achievement("demon_slayer")

func track_combo(combo_level: int):
	"""Track combo achievements"""
	if combo_level >= 3:
		unlock_achievement("combo_apprentice")
	if combo_level >= 5:
		unlock_achievement("combo_master")

func track_synergy_activated(character_count: int):
	"""Track synergy achievements"""
	if character_count >= 2:
		unlock_achievement("synergy_strike")
	if character_count >= 3:
		unlock_achievement("triple_synergy")

func track_damage_dealt(damage: int):
	"""Track damage achievements"""
	if damage >= 50:
		unlock_achievement("overkill")

func track_battle_completed(damage_taken: int):
	"""Track battle completion achievements"""
	if damage_taken == 0:
		unlock_achievement("no_damage")

func track_floor_reached(floor: int):
	"""Track floor achievements"""
	if floor >= 5:
		unlock_achievement("floor_5")
	if floor >= 10:
		unlock_achievement("floor_10")

func track_run_completed(success: bool):
	"""Track run completion"""
	if success:
		unlock_achievement("first_victory")

func track_character_unlocked():
	"""Check character unlock achievements"""
	var tier1_complete = true
	var tier2_complete = true
	var tier3_complete = true
	var all_complete = true
	
	for char_id in CharacterDatabase.get_all_characters():
		if not GameManager.is_character_unlocked(char_id):
			all_complete = false
			var char_data = CharacterDatabase.get_character(char_id)
			match char_data.unlock_tier:
				1:
					tier1_complete = false
				2:
					tier2_complete = false
				3:
					tier3_complete = false
	
	if tier1_complete:
		unlock_achievement("unlock_tier1")
	if tier2_complete:
		unlock_achievement("unlock_tier2")
	if tier3_complete:
		unlock_achievement("unlock_tier3")
	if all_complete:
		unlock_achievement("unlock_all")

func track_character_max_level(char_id: String):
	"""Track max level achievements"""
	unlock_achievement("max_level")
	
	# Check if all characters are max level
	var all_max = true
	for character_id in GameManager.game_data.get("unlockedCharacters", []):
		if GameManager.get_character_level(character_id) < 10:
			all_max = false
			break
	
	if all_max:
		unlock_achievement("all_max")

func track_coins_accumulated():
	"""Track coin achievements"""
	var total_coins = GameManager.get_stat("totalCoinsEarned")
	if total_coins >= 1000:
		unlock_achievement("coin_collector")
	if total_coins >= 5000:
		unlock_achievement("wealthy")

func track_shop_purchase(items_bought: int):
	"""Track shop achievements"""
	if items_bought >= 5:
		unlock_achievement("shopping_spree")

func track_relic_found():
	"""Track treasure achievements"""
	unlock_achievement("lucky_strike")

func track_relics_in_run(count: int):
	"""Track relic collection in run"""
	if count >= 10:
		unlock_achievement("hoarder")

func track_abilities_used(count: int):
	"""Track ability usage in one turn"""
	if count >= 3:
		unlock_achievement("perfect_power")

func track_beast_summoned(beast_name: String):
	"""Track Beastmaster beast summons"""
	# TODO: Implement tracking for all 5 beast types
	pass

func track_run_with_party_type(party_types: Dictionary):
	"""Track special party composition runs"""
	# Count class types in party
	var tanks = party_types.get("Tank", 0)
	var dps = party_types.get("DPS", 0)
	var support = party_types.get("Support", 0)
	
	if tanks >= 3:
		unlock_achievement("solo_tank")
	if dps >= 3:
		unlock_achievement("solo_dps")
	if support >= 3:
		unlock_achievement("solo_support")

func get_filtered_achievements(filter_type: String) -> Array:
	"""Get achievements based on filter"""
	var result = []
	
	for achievement_id in achievements.keys():  # Changed from all_achievements
		var achievement = achievements[achievement_id]  # Changed from all_achievements
		
		match filter_type:
			"all":
				result.append(achievement)
			"unlocked":
				if achievement.is_unlocked:  # Check the is_unlocked property
					result.append(achievement)
			"locked":
				if not achievement.is_unlocked:  # Check the is_unlocked property
					result.append(achievement)
	
	return result

func get_total_achievements() -> int:
	"""Get total number of achievements"""
	return achievements.size()
