# victory_screen.gd
extends Control

@onready var title_label = $TitleLabel
@onready var objective_complete = $ObjectiveComplete
@onready var stats_container = $StatsContainer
@onready var xp_container = $XPContainer
@onready var continue_button = $ContinueButton

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	AudioManager.play_music("victory", 0.5)
	display_victory()

func display_victory():
	"""Show victory information"""
	var objective = GameManager.current_run.get("objective", {})
	var party = GameManager.get_current_party()
	var relics_collected = GameManager.current_run.get("relics", []).size()
	if relics_collected == 0:
		AchievementManager.unlock_achievement("minimalist")
	if not GameManager.current_run.get("healing_used_this_run", false):
		AchievementManager.unlock_achievement("glass_cannon")
	if GameManager.get_current_health() == 1:
		AchievementManager.unlock_achievement("deaths_door")
	# Show objective completion
	objective_complete.text = objective.get("completion_text", "Victory!")
	
	# Show run stats
	setup_stats()
	
	# Show XP awards
	setup_xp_display()
	
	# Animate entrance
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.0)

func setup_stats():
	"""Display run statistics"""
	# Clear existing
	for child in stats_container.get_children():
		child.queue_free()
	
	var stats = [
		"Floor Reached: %d" % GameManager.current_run.get("currentFloor", 1),
		"Coins Earned: %d" % GameManager.get_coins(),
		"Final Health: %d/%d" % [GameManager.get_current_health(), GameManager.get_max_health()]
	]
	
	for stat in stats:
		var label = Label.new()
		label.text = stat
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.952941, 0.611765, 0.0705882, 1))
		label.add_theme_constant_override("outline_size", 4)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(label)

func setup_xp_display():
	"""Show XP gained for each character"""
	# Clear existing
	for child in xp_container.get_children():
		child.queue_free()
	
	var title = Label.new()
	title.text = "Experience Gained:"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.952941, 0.611765, 0.0705882, 1))
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_container.add_child(title)
	
	var party = GameManager.get_current_party()
	var pending_xp = GameManager.current_run.get("pendingXP", {})
	
	for char_id in party:
		var char_data = CharacterDatabase.get_character(char_id)
		if not char_data:
			continue
		
		var xp = pending_xp.get(char_id, 0)
		var old_level = GameManager.get_character_level(char_id)
		
		# Apply the XP
		GameManager.add_character_xp(char_id, xp)
		
		var new_level = GameManager.get_character_level(char_id)
		var level_ups = new_level - old_level
		
		# Display
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 10)
		
		var name_label = Label.new()
		name_label.text = char_data.character_name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.custom_minimum_size = Vector2(200, 0)
		hbox.add_child(name_label)
		
		var xp_label = Label.new()
		xp_label.text = "+%d XP" % int(xp)
		xp_label.add_theme_font_size_override("font_size", 18)
		xp_label.add_theme_color_override("font_color", Color("#F39C12"))
		xp_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(xp_label)
		
		if level_ups > 0:
			AudioManager.play_sfx("level_up")
			var level_label = Label.new()
			level_label.text = "LEVEL UP! (%d → %d)" % [old_level, new_level]
			level_label.add_theme_font_size_override("font_size", 18)
			level_label.add_theme_color_override("font_color", Color("#2ECC71"))
			level_label.add_theme_constant_override("outline_size", 4)
			hbox.add_child(level_label)
		
		xp_container.add_child(hbox)

func _on_continue_pressed():
	"""Complete the run and return to main menu"""
	# Mark run as successful
	GameManager.end_run(true)
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
