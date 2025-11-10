# game_over.gd
extends Control

@onready var title_label = $TitleLabel
@onready var cause_label = $CauseLabel
@onready var stats_container = $StatsContainer
@onready var main_menu_button = $MainMenuButton

func _ready():
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	AudioManager.play_music("defeat", 0.5)
	display_game_over()

func display_game_over():
	"""Show game over information"""
	# Determine cause of death
	var current_hp = GameManager.get_current_health()
	if current_hp <= 0:
		cause_label.text = "Your party has fallen in battle..."
	else:
		cause_label.text = "Your adventure has ended..."
	
	# Show run stats
	setup_stats()
	
	# Animate entrance
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.0)

func setup_stats():
	"""Display run statistics"""
	# Clear existing
	for child in stats_container.get_children():
		child.queue_free()
	
	var floor_reached = GameManager.current_run.get("currentFloor", 1)
	var coins_earned = GameManager.get_coins()
	var party = GameManager.get_current_party()
	
	var stats = [
		"Floor Reached: %d" % floor_reached,
		"Coins Earned: %d" % coins_earned,
		"Party Members: %d" % party.size()
	]
	
	for stat in stats:
		var label = Label.new()
		label.text = stat
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.741176, 0.764706, 0.780392, 1))
		label.add_theme_constant_override("outline_size", 4)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(label)
	
	# Show pending XP lost message
	var pending_xp = GameManager.current_run.get("pendingXP", {})
	var total_xp_lost = 0
	for char_id in pending_xp:
		total_xp_lost += int(pending_xp[char_id])
	
	if total_xp_lost > 0:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		stats_container.add_child(spacer)
		
		var xp_label = Label.new()
		xp_label.text = "Pending XP Lost: %d" % total_xp_lost
		xp_label.add_theme_font_size_override("font_size", 18)
		xp_label.add_theme_color_override("font_color", Color(0.905882, 0.298039, 0.235294, 1))
		xp_label.add_theme_constant_override("outline_size", 4)
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(xp_label)

func _on_main_menu_pressed():
	"""Return to main menu"""
	# Run already ended by BattleScene, just return to menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
