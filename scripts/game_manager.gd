extends Node


# This is an autoload singleton that manages global game state

const SAVE_FILE_PATH = "user://save_data.json"

# Game data structure
var options: Dictionary = {}
var game_data: Dictionary = {}
var current_run: Dictionary = {}

# Signals for other systems to respond to data changes
signal coins_changed(new_amount)
signal character_unlocked(character_name)
signal character_leveled_up(character_name, new_level)
signal health_changed(current_health, max_health)

func _ready():
	print("GameManager initialized")

func load_game_data(data: Dictionary):
	"""Load game data from the save file"""
	options = data.get("options", {})
	game_data = data.get("gameData", {})
	current_run = data.get("currentRun", {})
	print("Game data loaded into GameManager")

func save_game():
	"""Save current game state to file"""
	var save_dict = {
		"options": options,
		"gameData": game_data,
		"currentRun": current_run
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict, "\t")
		file.store_string(json_string)
		file.close()
		print("Game saved successfully!")
		return true
	else:
		print("Error: Could not save game!")
		return false

# === COINS ===
func get_coins() -> int:
	return game_data.get("totalCoins", 0)

func add_coins(amount: int):
	game_data["totalCoins"] = game_data.get("totalCoins", 0) + amount
	coins_changed.emit(game_data["totalCoins"])
	save_game()

func spend_coins(amount: int) -> bool:
	if game_data.get("totalCoins", 0) >= amount:
		game_data["totalCoins"] -= amount
		coins_changed.emit(game_data["totalCoins"])
		save_game()
		return true
	return false

# === CHARACTERS ===
func is_character_unlocked(character_name: String) -> bool:
	return character_name in game_data.get("unlockedCharacters", [])

func unlock_character(character_name: String):
	if not is_character_unlocked(character_name):
		game_data["unlockedCharacters"].append(character_name)
		
		# Initialize character level data
		if not game_data["characterLevels"].has(character_name):
			game_data["characterLevels"][character_name] = {
				"level": 1,
				"currentXP": 0
			}
		
		character_unlocked.emit(character_name)
		save_game()

func get_character_level(character_name: String) -> int:
	if game_data["characterLevels"].has(character_name):
		return game_data["characterLevels"][character_name].get("level", 1)
	return 1

func get_character_xp(character_name: String) -> int:
	if game_data["characterLevels"].has(character_name):
		return game_data["characterLevels"][character_name].get("currentXP", 0)
	return 0

func add_character_xp(character_name: String, xp_amount: float):
	if not game_data["characterLevels"].has(character_name):
		return
	
	var char_data = game_data["characterLevels"][character_name]
	char_data["currentXP"] += int(xp_amount)
	
	# Check for level up (max level 10)
	while char_data["currentXP"] >= 1000 and char_data["level"] < 10:
		char_data["currentXP"] -= 1000
		char_data["level"] += 1
		character_leveled_up.emit(character_name, char_data["level"])
		print("%s leveled up to level %d!" % [character_name, char_data["level"]])
	
	save_game()

func get_unlocked_characters() -> Array:
	return game_data.get("unlockedCharacters", [])

# === CURRENT RUN ===
func start_new_run(party: Array):
	"""Initialize a new run with selected party"""
	current_run = {
		"isActive": true,
		"selectedParty": party,
		"currentHealth": 120,
		"maxHealth": 120,
		"currentFloor": 1,
		"mapSeed": randi(),
		"visitedNodes": [],
		"pendingXP": {}
	}
	
	# Initialize pending XP for party members
	for character in party:
		current_run["pendingXP"][character] = 0.0
	
	game_data["totalRunsStarted"] += 1
	save_game()

func end_run(success: bool):
	"""End the current run and apply pending XP"""
	if success:
		game_data["totalRunsCompleted"] += 1
		
		# Apply pending XP only on success
		for character in current_run["pendingXP"]:
			var xp = current_run["pendingXP"][character]
			if xp > 0:
				add_character_xp(character, xp)
	
	# Update highest floor
	if current_run["currentFloor"] > game_data.get("highestFloorReached", 0):
		game_data["highestFloorReached"] = current_run["currentFloor"]
	
	# Clear current run
	current_run = {
		"isActive": false,
		"selectedParty": [],
		"currentHealth": 120,
		"maxHealth": 120,
		"currentFloor": 1,
		"mapSeed": 0,
		"visitedNodes": [],
		"pendingXP": {}
	}
	
	save_game()

func is_run_active() -> bool:
	return current_run.get("isActive", false)

func get_current_party() -> Array:
	return current_run.get("selectedParty", [])

func get_current_health() -> int:
	return current_run.get("currentHealth", 120)

func get_max_health() -> int:
	return current_run.get("maxHealth", 120)

func modify_health(amount: int):
	"""Add or remove health (negative amount for damage)"""
	current_run["currentHealth"] = clamp(
		current_run["currentHealth"] + amount,
		0,
		current_run["maxHealth"]
	)
	health_changed.emit(current_run["currentHealth"], current_run["maxHealth"])
	save_game()

func add_pending_xp(character_name: String, xp_amount: float):
	"""Add XP to pending pool (applied at end of successful run)"""
	if current_run["pendingXP"].has(character_name):
		current_run["pendingXP"][character_name] += xp_amount

# === STATISTICS ===
func increment_stat(stat_name: String, amount: int = 1):
	"""Increment a statistic value"""
	if game_data["statistics"].has(stat_name):
		game_data["statistics"][stat_name] += amount
		save_game()

func get_stat(stat_name: String) -> int:
	return game_data["statistics"].get(stat_name, 0)

# === OPTIONS ===
func get_option(option_name: String):
	return options.get(option_name)

func set_option(option_name: String, value):
	options[option_name] = value
	save_game()
