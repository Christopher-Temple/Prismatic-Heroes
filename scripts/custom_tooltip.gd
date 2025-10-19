extends Control

# References to UI elements
@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var class_label = $Panel/VBoxContainer/ClassLabel
@onready var level_label = $Panel/VBoxContainer/LevelLabel
@onready var ability_name_label = $Panel/VBoxContainer/AbilityNameLabel
@onready var ability_desc_label = $Panel/VBoxContainer/AbilityDescLabel
@onready var stats_label = $Panel/VBoxContainer/StatsLabel
@onready var unlock_label = $Panel/VBoxContainer/UnlockLabel


var offset_from_mouse = Vector2(20, 20)

func _ready():
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	# Make sure all child controls ignore mouse too
	for child in get_children():
		if child is Control:
			child.mouse_filter = MOUSE_FILTER_IGNORE

func _process(_delta):
	if visible:
		# Follow mouse cursor
		global_position = get_viewport().get_mouse_position() + offset_from_mouse
		
		# Keep tooltip on screen
		var viewport_rect = get_viewport_rect()
		if global_position.x + size.x > viewport_rect.size.x:
			global_position.x = get_viewport().get_mouse_position().x - size.x - 10
		if global_position.y + size.y > viewport_rect.size.y:
			global_position.y = get_viewport().get_mouse_position().y - size.y - 10

func show_character_tooltip(character_id: String):
	"""Display tooltip for a character"""
	var char_data = CharacterDatabase.get_character(character_id)
	if not char_data:
		return
	
	var is_unlocked = GameManager.is_character_unlocked(character_id)
	var level = GameManager.get_character_level(character_id) if is_unlocked else 1
	
	# Set title and class
	title_label.text = char_data.character_name
	class_label.text = char_data.character_class + " (" + char_data.class_type + ")"
	
	# Level info
	if is_unlocked:
		var current_xp = GameManager.get_character_xp(character_id)
		level_label.text = "Level %d (%d/1000 XP)" % [level, current_xp]
		level_label.show()
	else:
		level_label.hide()
	
	# Ability info
	ability_name_label.text = "Ability: " + char_data.ability_name
	ability_desc_label.text = char_data.ability_description
	
	# Stats based on current level
	var ability_value = char_data.get_ability_value(level)
	var stats_text = "Power: %.0f" % ability_value
	
	# Add secondary/duration if applicable
	var secondary = char_data.get_ability_secondary(level)
	if secondary > 0:
		stats_text += " / %.0f" % secondary
	
	var duration = char_data.get_ability_duration(level)
	if duration > 0:
		stats_text += " (%d turns)" % duration
	
	stats_label.text = stats_text
	
	# Unlock status
	if is_unlocked:
		unlock_label.text = "UNLOCKED"
		unlock_label.modulate = Color("#2ECC71")  # Green
	else:
		unlock_label.text = "LOCKED - %d Coins to Unlock" % char_data.unlock_cost
		unlock_label.modulate = Color("#E74C3C")  # Red
	
	show()

func show_enemy_tooltip(enemy_id: String):
	"""Display tooltip for an enemy"""
	var enemy_data = EnemyDatabase.get_enemy(enemy_id)
	if not enemy_data:
		return
	
	# Set title and type
	title_label.text = enemy_data.enemy_name
	class_label.text = enemy_data.enemy_type + " Enemy"
	
	# No level for enemies
	level_label.hide()
	
	# Attack info
	ability_name_label.text = "Attack: Every %d turns" % enemy_data.attack_frequency
	ability_desc_label.text = enemy_data.attack_description
	
	# Stats
	var stats_text = "Base HP: %d | Damage: %d | Coins: %d" % [
		enemy_data.base_health,
		enemy_data.attack_damage,
		enemy_data.coin_reward
	]
	stats_label.text = stats_text
	
	# Special ability or unlock label (reuse for special ability)
	if enemy_data.has_special_ability:
		unlock_label.text = "Special: " + enemy_data.special_ability_name
		unlock_label.modulate = Color("#F39C12")  # Orange
	elif enemy_data.places_obstacles:
		unlock_label.text = "Places %s obstacles" % enemy_data.obstacle_type
		unlock_label.modulate = Color("#9B59B6")  # Purple
	elif enemy_data.can_summon:
		unlock_label.text = "Summons reinforcements"
		unlock_label.modulate = Color("#E74C3C")  # Red
	else:
		unlock_label.hide()
	
	show()

func hide_tooltip():
	"""Hide the tooltip"""
	hide()
