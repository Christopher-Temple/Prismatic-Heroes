# achievements.gd
extends Control

@onready var achievements_container = $ScrollContainer/AchievementsContainer
@onready var progress_label = $ProgressLabel
@onready var back_button = $BackButton
@onready var filter_all = $FilterButtons/AllButton
@onready var filter_unlocked = $FilterButtons/UnlockedButton
@onready var filter_locked = $FilterButtons/LockedButton

var current_filter = "all"

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	filter_all.pressed.connect(func(): set_filter("all"))
	filter_unlocked.pressed.connect(func(): set_filter("unlocked"))
	filter_locked.pressed.connect(func(): set_filter("locked"))
	
	populate_achievements()

func set_filter(filter_type: String):
	current_filter = filter_type
	populate_achievements()
	
	# Update button states
	filter_all.disabled = (filter_type == "all")
	filter_unlocked.disabled = (filter_type == "unlocked")
	filter_locked.disabled = (filter_type == "locked")

func populate_achievements():
	# Clear existing
	for child in achievements_container.get_children():
		child.queue_free()
	
	# Get achievements from AchievementManager
	var achievements = AchievementManager.get_filtered_achievements(current_filter)
	
	# Update progress label
	var total = AchievementManager.get_total_achievements()
	var unlocked = AchievementManager.get_unlocked_count()
	progress_label.text = "Unlocked: %d/%d" % [unlocked, total]
	
	# Create achievement cards
	for achievement in achievements:
		create_achievement_card(achievement)

func create_achievement_card(achievement: AchievementManager.Achievement):  # Changed from Dictionary
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(1150, 100)
	
	# Style the card
	var style = StyleBoxFlat.new()
	if achievement.is_unlocked:
		style.bg_color = Color(0.172549, 0.243137, 0.313726, 1)
		style.border_color = Color(0.180392, 0.8, 0.443137, 1)  # Green border for unlocked
	else:
		style.bg_color = Color(0.1, 0.1, 0.1, 1)
		style.border_color = Color(0.3, 0.3, 0.3, 1)  # Gray border for locked
	
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Content container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = achievement.icon
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.custom_minimum_size = Vector2(60, 60)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)
	
	# Text content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Name
	var name_label = Label.new()
	if achievement.is_secret and not achievement.is_unlocked:
		name_label.text = "???"
	else:
		name_label.text = achievement.name
	name_label.add_theme_font_size_override("font_size", 24)
	if achievement.is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.952941, 0.611765, 0.0705882, 1))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	if achievement.is_secret and not achievement.is_unlocked:
		desc_label.text = "Hidden achievement - unlock to reveal"
	else:
		desc_label.text = achievement.description
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.741176, 0.764706, 0.780392, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Reward info
	if achievement.reward_coins > 0:
		var reward_label = Label.new()
		reward_label.text = "Reward: %d coins" % achievement.reward_coins
		reward_label.add_theme_font_size_override("font_size", 14)
		reward_label.add_theme_color_override("font_color", Color(0.952941, 0.611765, 0.0705882, 1))
		vbox.add_child(reward_label)
	
	# Unlock date (if unlocked)
	if achievement.is_unlocked and achievement.unlock_date != "":
		var date_label = Label.new()
		date_label.text = "Unlocked: " + achievement.unlock_date
		date_label.add_theme_font_size_override("font_size", 12)
		date_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		vbox.add_child(date_label)
	
	achievements_container.add_child(card)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
