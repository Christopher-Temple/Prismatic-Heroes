extends Control

# References to UI elements
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var new_run_button = $VBoxContainer/NewRunButton
@onready var characters_button = $VBoxContainer/CharactersButton
@onready var statistics_button = $VBoxContainer/StatisticsButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var enemy_button: Button = $VBoxContainer/EnemyButton
@onready var achievements_button = $VBoxContainer/AchievementsButton

@onready var coins_label = $Footer/CoinsLabel
@onready var highest_floor_label = $Footer/HighestFloorLabel
@onready var version_label = $Footer/VersionLabel

# Animation
var button_hover_scale = 1.05
var button_normal_scale = 1.0

func _ready():
	# Connect button signals
	continue_button.pressed.connect(_on_continue_pressed)
	new_run_button.pressed.connect(_on_new_run_pressed)
	characters_button.pressed.connect(_on_characters_pressed)
	enemy_button.pressed.connect(_on_enemy_pressed)
	statistics_button.pressed.connect(_on_statistics_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	
	# Setup hover effects for all buttons
	setup_button_hover(continue_button)
	setup_button_hover(new_run_button)
	setup_button_hover(characters_button)
	setup_button_hover(enemy_button)
	setup_button_hover(statistics_button)
	setup_button_hover(options_button)
	setup_button_hover(quit_button)
	
	# Update UI based on game state
	update_ui()
	AudioManager.play_music("main_menu")

func update_ui():
	# Check if there's an active run
	var has_active_run = GameManager.is_run_active()
	continue_button.visible = has_active_run
	
	# Add glow effect to continue button if active
	if has_active_run:
		add_glow_effect(continue_button)
	
	# Update footer information
	coins_label.text = "Coins: %d" % GameManager.get_coins()
	highest_floor_label.text = "Highest Floor: %d" % GameManager.game_data.get("highestFloorReached", 0)
	version_label.text = "v1.0.0"

func setup_button_hover(button: Button):
	"""Setup hover animations for a button"""
	button.mouse_entered.connect(func(): 
		on_button_hover(button, true)
		AudioManager.play_button_hover()
	)
	
	button.mouse_exited.connect(func(): on_button_hover(button, false))

func on_button_hover(button: Button, is_hovering: bool):
	"""Animate button on hover"""
	button.pivot_offset = button.size / 2
	var target_scale = button_hover_scale if is_hovering else button_normal_scale
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.2)

func add_glow_effect(button: Button):
	"""Add a pulsing glow effect to the continue button"""
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Pulse between two modulate values (normal and brighter)
	tween.tween_property(button, "modulate", Color(1.3, 1.2, 1.0), 1.0)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0), 1.0)

# Button callbacks
func _on_continue_pressed():
	AudioManager.play_button_click()
	# Load the game scene with current run data
	get_tree().change_scene_to_file("res://scenes/PartySelect.tscn")

func _on_new_run_pressed():
	AudioManager.play_button_click()
	# Go to party selection screen
	get_tree().change_scene_to_file("res://scenes/party_select.tscn")
	
func _on_achievements_pressed():
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/achievements.tscn")

func _on_characters_pressed():
	AudioManager.play_button_click()
	# Go to character collection screen
	get_tree().change_scene_to_file("res://scenes/character_collection.tscn")
	
func _on_enemy_pressed():
	AudioManager.play_button_click()
	# Go to enemy collection screen
	get_tree().change_scene_to_file("res://scenes/enemy_collection.tscn")

func _on_statistics_pressed():
	AudioManager.play_button_click()
	# Go to statistics screen
	get_tree().change_scene_to_file("res://scenes/Statistics.tscn")

func _on_options_pressed():
	AudioManager.play_button_click()
	# Go to options screen
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_quit_pressed():
	AudioManager.play_button_click()
	# Quit the game
	get_tree().quit()
