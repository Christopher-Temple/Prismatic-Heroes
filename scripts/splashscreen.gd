# splashscreen.gd - Updated for separate save files

extends Control

const GAME_SAVE_PATH = "user://game_data.json"
const OPTIONS_SAVE_PATH = "user://settings.json"

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var game_data: Dictionary = {}
var options_data: Dictionary = {}
var game_ready: bool = false

func _ready():
	display_splash()
	await get_tree().create_timer(0.5).timeout 
	check_and_load_files()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and game_ready == true:
		transition_to_main_menu()

func display_splash():
	animation_player.play("splash_start")

func check_and_load_files():
	"""Load both game data and options"""
	# Load options first (needed for audio)
	if FileAccess.file_exists(OPTIONS_SAVE_PATH):
		load_options_file()
	else:
		create_default_options()
	
	# Then load game data
	if FileAccess.file_exists(GAME_SAVE_PATH):
		load_game_file()
	else:
		create_default_game_data()

# ========== OPTIONS FILE ==========

func load_options_file():
	
	var file = FileAccess.open(OPTIONS_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			options_data = json.data
			GameManager.load_options_data(options_data)
		else:
			create_default_options()
	else:
		create_default_options()

func create_default_options():
	options_data = {
		"masterVolume": 0.8,
		"musicVolume": 0.7,
		"sfxVolume": 0.9,
		"screenShake": true,
		"particleEffects": true,
		"colorblindMode": false,
		"showDamageNumbers": true
	}
	
	save_options_file()
	GameManager.load_options_data(options_data)

func save_options_file():
	var file = FileAccess.open(OPTIONS_SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(options_data, "\t")
		file.store_string(json_string)
		file.close()
	else:
		return

# ========== GAME DATA FILE ==========

func load_game_file():
	
	var file = FileAccess.open(GAME_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			game_data = json.data
			GameManager.load_game_data(game_data)
		else:
			create_default_game_data()
	else:
		create_default_game_data()

func create_default_game_data():
	
	game_data = {
		"gameData": {
			"totalCoins": 0,
			"totalPlayTime": 0,
			"totalRunsStarted": 0,
			"totalRunsCompleted": 0,
			"highestFloorReached": 0,
			
			"unlockedCharacters": ["knight", "wizard", "cleric"],
			
			"characterLevels": {
				"knight": {"level": 1, "currentXP": 0},
				"wizard": {"level": 1, "currentXP": 0},
				"cleric": {"level": 1, "currentXP": 0}
			},
			
			"statistics": {
				"totalEnemiesDefeated": 0,
				"totalBossesDefeated": 0,
				"totalBlocksCleared": 0,
				"largestCombo": 0,
				"mostUsedCharacter": ""
			}
		},
		
		"currentRun": {
			"isActive": false,
			"selectedParty": [],
			"currentHealth": 120,
			"maxHealth": 120,
			"currentFloor": 1,
			"mapSeed": 0,
			"visitedNodes": [],
			"pendingXP": {}
		}
	}
	
	save_game_file()
	GameManager.load_game_data(game_data)

func save_game_file():
	var file = FileAccess.open(GAME_SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(game_data, "\t")
		file.store_string(json_string)
		file.close()
	else:
		return

func transition_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func game_is_ready():
	game_ready = true
