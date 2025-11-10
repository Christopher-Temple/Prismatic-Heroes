# Options.tscn structure (create this scene in Godot)
# This is the script that will control it

# options.gd
extends Control

@onready var title_label = $TitleLabel
@onready var back_button = $BackButton

# Audio sliders
@onready var master_slider = $OptionsContainer/MasterVolume/Slider
@onready var master_value = $OptionsContainer/MasterVolume/ValueLabel
@onready var music_slider = $OptionsContainer/MusicVolume/Slider
@onready var music_value = $OptionsContainer/MusicVolume/ValueLabel
@onready var sfx_slider = $OptionsContainer/SFXVolume/Slider
@onready var sfx_value = $OptionsContainer/SFXVolume/ValueLabel

# Gameplay toggles
@onready var screen_shake_check = $OptionsContainer/ScreenShake/CheckBox
@onready var particles_check = $OptionsContainer/Particles/CheckBox
@onready var damage_numbers_check = $OptionsContainer/DamageNumbers/CheckBox
@onready var colorblind_check = $OptionsContainer/ColorblindMode/CheckBox

# Display mode
@onready var fullscreen_check = $OptionsContainer/Fullscreen/CheckBox
@onready var vsync_check = $OptionsContainer/VSync/CheckBox

# Reset button
@onready var reset_button = $ResetButton

func _ready():
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Audio sliders
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Gameplay toggles
	screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	particles_check.toggled.connect(_on_particles_toggled)
	damage_numbers_check.toggled.connect(_on_damage_numbers_toggled)
	colorblind_check.toggled.connect(_on_colorblind_toggled)
	
	# Display toggles
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	
	# Load current settings
	load_settings()
	
	# Play test sound when entering
	AudioManager.play_button_click()

func load_settings():
	"""Load current settings from GameManager"""
	# Audio settings
	master_slider.value = GameManager.options.get("masterVolume", 0.8) * 100
	music_slider.value = GameManager.options.get("musicVolume", 0.7) * 100
	sfx_slider.value = GameManager.options.get("sfxVolume", 0.9) * 100
	
	update_volume_labels()
	
	# Gameplay settings
	screen_shake_check.button_pressed = GameManager.options.get("screenShake", true)
	particles_check.button_pressed = GameManager.options.get("particleEffects", true)
	damage_numbers_check.button_pressed = GameManager.options.get("showDamageNumbers", true)
	colorblind_check.button_pressed = GameManager.options.get("colorblindMode", false)
	
	# Display settings
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED

func update_volume_labels():
	"""Update volume percentage labels"""
	master_value.text = "%d%%" % int(master_slider.value)
	music_value.text = "%d%%" % int(music_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)

# ========== AUDIO CALLBACKS ==========

func _on_master_volume_changed(value: float):
	"""Master volume slider changed"""
	AudioManager.set_master_volume(value / 100.0)
	update_volume_labels()

func _on_music_volume_changed(value: float):
	"""Music volume slider changed"""
	AudioManager.set_music_volume(value / 100.0)
	update_volume_labels()

func _on_sfx_volume_changed(value: float):
	"""SFX volume slider changed"""
	AudioManager.set_sfx_volume(value / 100.0)
	update_volume_labels()
	
	# Play test sound
	AudioManager.play_button_click()

# ========== GAMEPLAY CALLBACKS ==========

func _on_screen_shake_toggled(enabled: bool):
	"""Screen shake toggle changed"""
	GameManager.set_option("screenShake", enabled)
	AudioManager.play_button_click()

func _on_particles_toggled(enabled: bool):
	"""Particle effects toggle changed"""
	GameManager.set_option("particleEffects", enabled)
	AudioManager.play_button_click()

func _on_damage_numbers_toggled(enabled: bool):
	"""Damage numbers toggle changed"""
	GameManager.set_option("showDamageNumbers", enabled)
	AudioManager.play_button_click()

func _on_colorblind_toggled(enabled: bool):
	"""Colorblind mode toggle changed"""
	GameManager.set_option("colorblindMode", enabled)
	AudioManager.play_button_click()
	
	# Show warning about restart
	if enabled:
		show_restart_warning()

# ========== DISPLAY CALLBACKS ==========

func _on_fullscreen_toggled(enabled: bool):
	"""Fullscreen toggle changed"""
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	AudioManager.play_button_click()

func _on_vsync_toggled(enabled: bool):
	"""VSync toggle changed"""
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	AudioManager.play_button_click()

# ========== RESET ==========

func _on_reset_pressed():
	"""Reset all settings to default"""
	AudioManager.play_button_click()
	
	# Show confirmation dialog
	show_reset_confirmation()

func show_reset_confirmation():
	"""Show dialog to confirm reset"""
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Reset all settings to default?"
	dialog.ok_button_text = "Reset"
	dialog.cancel_button_text = "Cancel"
	
	dialog.confirmed.connect(func():
		reset_to_defaults()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func reset_to_defaults():
	"""Reset all settings to default values"""
	# Audio
	GameManager.set_option("masterVolume", 0.8)
	GameManager.set_option("musicVolume", 0.7)
	GameManager.set_option("sfxVolume", 0.9)
	
	AudioManager.set_master_volume(0.8)
	AudioManager.set_music_volume(0.7)
	AudioManager.set_sfx_volume(0.9)
	
	# Gameplay
	GameManager.set_option("screenShake", true)
	GameManager.set_option("particleEffects", true)
	GameManager.set_option("showDamageNumbers", true)
	GameManager.set_option("colorblindMode", false)
	
	# Display
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	
	# Reload UI
	load_settings()
	
	AudioManager.play_sfx("level_up")  # Success sound

func show_restart_warning():
	"""Show warning that some changes require restart"""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Colorblind mode will take effect on next battle."
	dialog.ok_button_text = "OK"
	
	dialog.confirmed.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

# ========== NAVIGATION ==========

func _on_back_pressed():
	"""Return to main menu"""
	AudioManager.play_button_click()
	GameManager.save_options()  # Only save options, not game data
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
