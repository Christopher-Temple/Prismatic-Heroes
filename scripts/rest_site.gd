# rest_site.gd
extends Control

@onready var title_label = $TitleLabel
@onready var options_container = $OptionsContainer
@onready var continue_button = $ContinueButton
@onready var result_panel = $ResultPanel
@onready var result_label = $ResultPanel/ResultLabel
@onready var swap_panel = $SwapPanel
@onready var current_party_container = $SwapPanel/MarginContainer/VBoxContainer/CurrentPartyContainer
@onready var available_chars_container = $SwapPanel/MarginContainer/VBoxContainer/ScrollContainer/AvailableCharsContainer
@onready var swap_confirm_button = $SwapPanel/MarginContainer/VBoxContainer/ConfirmButton
@onready var swap_cancel_button = $SwapPanel/MarginContainer/VBoxContainer/CancelButton

var option_chosen: bool = false
var selected_to_remove: String = ""  # Character ID to remove
var selected_to_add: String = ""  # Character ID to add

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.visible = false
	result_panel.visible = false
	
	setup_rest_options()

func setup_rest_options():
	"""Create buttons for each rest option"""
	create_option_button(
		"Rest by the Fire",
		"Restore 20% of maximum HP",
		"💤",
		_on_rest_chosen
	)
	
	create_option_button(
		"Swap Characters",
		"Replace a party member with another unlocked character",
		"🔄",
		_on_swap_chosen
	)
	
	create_option_button(
		"Meditate",
		"All party members gain bonus XP",
		"🧘",
		_on_meditate_chosen
	)
	
	create_option_button(
		"Scavenge the Area",
		"Search for resources (80% coins, 10% relic, 10% damage)",
		"🔍",
		_on_scavenge_chosen
	)
	
	create_option_button(
		"Pray at the Shrine",
		"Start next battle with 50% power on all characters",
		"🙏",
		_on_pray_chosen
	)
	
	create_option_button(
		"Sharpen Blades",
		"All matches deal +2 bonus damage in next battle",
		"⚔️",
		_on_sharpen_chosen
	)

func create_option_button(title: String, description: String, icon: String, callback: Callable):
	"""Create a stylized option button"""
	var button_container = PanelContainer.new()
	button_container.custom_minimum_size = Vector2(800, 80)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.172549, 0.243137, 0.313726, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.952941, 0.611765, 0.0705882, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	button_container.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	button_container.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 40)
	icon_label.custom_minimum_size = Vector2(60, 60)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)
	
	# Text content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.952941, 0.611765, 0.0705882, 1))
	title_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.741176, 0.764706, 0.780392, 1))
	vbox.add_child(desc_label)
	
	# Action button
	var action_button = Button.new()
	action_button.text = "Choose"
	action_button.custom_minimum_size = Vector2(100, 60)
	action_button.pressed.connect(callback)
	hbox.add_child(action_button)
	
	options_container.add_child(button_container)

func disable_all_options():
	"""Disable all option buttons after one is chosen"""
	for container in options_container.get_children():
		for child in container.get_children():
			if child is MarginContainer:
				for hbox_child in child.get_children():
					if hbox_child is HBoxContainer:
						for button in hbox_child.get_children():
							if button is Button:
								button.disabled = true

func show_result(message: String):
	"""Show result message and enable continue button"""
	result_label.text = message
	result_panel.visible = true
	continue_button.visible = true
	
	# Animate result panel
	result_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(result_panel, "modulate", Color.WHITE, 0.5)

# ========== REST OPTION HANDLERS ==========

func _on_rest_chosen():
	AudioManager.play_button_click()
	"""Heal 20% of max HP"""
	if option_chosen:
		return
	option_chosen = true
	disable_all_options()
	
	var max_hp = GameManager.get_max_health()
	var current_hp = GameManager.get_current_health()
	var heal_amount = int(max_hp * 0.2)
	
	GameManager.modify_health(heal_amount)
	
	var new_hp = GameManager.get_current_health()
	show_result("You rest by the fire and feel refreshed.\n\nRestored %d HP (%d/%d)" % [heal_amount, new_hp, max_hp])

func _on_swap_chosen():
	AudioManager.play_button_click()
	"""Open character swap UI"""
	if option_chosen:
		return
	option_chosen = true
	disable_all_options()
	
	# TODO: Implement character swap UI
	# For now, just show a message
	show_result("Character swapping is not yet implemented.\n\nThis feature is coming soon!")

func _on_meditate_chosen():
	AudioManager.play_button_click()
	"""Grant bonus XP to all party members"""
	if option_chosen:
		return
	option_chosen = true
	disable_all_options()
	
	var party = GameManager.get_current_party()
	var bonus_xp = 50  # Base XP bonus per character
	
	var messages = ["You meditate and reflect on your journey.\n"]
	
	for char_id in party:
		GameManager.add_pending_xp(char_id, bonus_xp)
		var char_data = CharacterDatabase.get_character(char_id)
		if char_data:
			messages.append("%s gained %d XP" % [char_data.character_name, bonus_xp])
	
	show_result("\n".join(messages))

func _on_scavenge_chosen():
	AudioManager.play_button_click()
	"""Random event: coins, relic, or damage"""
	if option_chosen:
		return
	option_chosen = true
	disable_all_options()
	
	var roll = randf()
	
	if roll < 0.80:
		# 80% - Find coins
		var coins = randi_range(25, 45)
		GameManager.add_coins(coins)
		show_result("You scavenge the area and find supplies!\n\nFound %d coins" % coins)
	
	elif roll < 0.90:
		# 10% - Find a relic
		var common_relics = get_common_relics()
		if common_relics.size() > 0:
			var relic = common_relics[randi() % common_relics.size()]
			add_relic_to_run(relic)
			show_result("You discover something valuable!\n\nFound: %s\n%s" % [relic.name, relic.description])
		else:
			# Fallback to coins
			var coins = 30
			GameManager.add_coins(coins)
			show_result("You scavenge the area and find supplies!\n\nFound %d coins" % coins)
	
	else:
		# 10% - Take damage
		var damage = 20
		GameManager.modify_health(-damage)
		var current_hp = GameManager.get_current_health()
		var max_hp = GameManager.get_max_health()
		show_result("You disturb a sleeping creature!\n\nTook %d damage (%d/%d HP remaining)" % [damage, current_hp, max_hp])

func _on_pray_chosen():
	AudioManager.play_button_click()
	"""Grant starting power buff for next battle"""
	if option_chosen:
		return
	option_chosen = true
	disable_all_options()
	
	# Add temporary buff to run data
	if not GameManager.current_run.has("temp_buffs"):
		GameManager.current_run["temp_buffs"] = []
	
	GameManager.current_run["temp_buffs"].append({
		"type": "starting_power",
		"amount": 50,
		"duration": 1  # Next battle only
	})
	
	GameManager.save_game()
	
	show_result("You pray at the shrine and feel divine energy.\n\nYour party will start the next battle with 50% power!")

func _on_sharpen_chosen():
	AudioManager.play_button_click()
	"""Grant bonus damage for next battle"""
	if option_chosen:
		return
	option_chosen = true
	disable_all_options()
	
	# Add temporary buff to run data
	if not GameManager.current_run.has("temp_buffs"):
		GameManager.current_run["temp_buffs"] = []
	
	GameManager.current_run["temp_buffs"].append({
		"type": "bonus_damage",
		"amount": 2,
		"duration": 1  # Next battle only
	})
	
	GameManager.save_game()
	
	show_result("You sharpen your weapons to a keen edge.\n\nAll matches will deal +2 bonus damage in the next battle!")

# ========== HELPER FUNCTIONS ==========

func get_common_relics() -> Array:
	"""Get list of common relics that player doesn't have"""
	var available = []
	var purchased = GameManager.current_run.get("shop_purchases", {})
	
	for item_id in ShopDatabase.shop_items:
		var item = ShopDatabase.shop_items[item_id]
		
		# Only common relics
		if item.rarity != "common" or item.category != "relic":
			continue
		
		# Check unlock requirement
		if item.unlock_requirement != "" and not GameManager.is_character_unlocked(item.unlock_requirement):
			continue
		
		# Check if already owned
		if purchased.has(item_id):
			continue
		
		available.append(item)
	
	return available

func add_relic_to_run(item: ShopDatabase.ShopItem):
	"""Add a relic to the current run"""
	if not GameManager.current_run.has("relics"):
		GameManager.current_run["relics"] = []
	
	GameManager.current_run["relics"].append({
		"id": item.id,
		"type": item.item_type,
		"data": item.data
	})
	
	# Mark as purchased to prevent duplicates
	if not GameManager.current_run.has("shop_purchases"):
		GameManager.current_run["shop_purchases"] = {}
	GameManager.current_run["shop_purchases"][item.id] = 1
	
	GameManager.save_game()

func _on_continue_pressed():
	"""Continue to map"""
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/map_view.tscn")
