extends Control


# Path to save file
const SAVE_FILE_PATH = "user://save_data.json"
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Reference to the game manager (will handle global data)
var game_data: Dictionary = {}
var game_ready: bool = false

func _ready():
	# Show splash screen elements
	display_splash()
	
	# Check and load/create save file
	await get_tree().create_timer(0.5).timeout 
	check_and_load_save_file()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and game_ready == true:
		transition_to_main_menu()
func display_splash():
	animation_player.play("splash_start")

func check_and_load_save_file():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		load_save_file()
	else:
		create_default_save_file()

func load_save_file():
	print("Save file found. Loading...")
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			game_data = json.data
			print("Save file loaded successfully!")
			
			# Store in global autoload (we'll need to create GameManager autoload)
			if has_node("/root/GameManager"):
				get_node("/root/GameManager").load_game_data(game_data)
		else:
			print("Error parsing save file. Creating new save...")
			create_default_save_file()
	else:
		print("Error opening save file. Creating new save...")
		create_default_save_file()

func create_default_save_file():
	print("No save file found. Creating default save...")
	
	game_data = {
		"options": {
			"masterVolume": 0.8,
			"musicVolume": 0.7,
			"sfxVolume": 0.9,
			"screenShake": true,
			"particleEffects": true,
			"colorblindMode": false,
			"showDamageNumbers": true,
			"tutorialCompleted": false
		},
		
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
	
	save_game_data()
	
	# Store in global autoload
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").load_game_data(game_data)
	
	print("Default save file created!")

func save_game_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(game_data, "\t")
		file.store_string(json_string)
		file.close()
		print("Game data saved!")
	else:
		print("Error: Could not save game data!")

func transition_to_main_menu():
	# Change to main menu scene
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func game_is_ready():
	game_ready = true
