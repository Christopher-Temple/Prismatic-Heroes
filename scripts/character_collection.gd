extends Control

# Preload the card scene
const CardScene = preload("res://scenes/card_display.tscn")

@onready var grid_container = $ScrollContainer/GridContainer
@onready var tooltip = $CustomTooltip
@onready var back_button = $BackButton
@onready var title_label = $TitleLabel
@onready var coins_label = $CoinsLabel

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	
	# Update UI
	title_label.text = "Character Collection"
	update_coins_display()
	
	# Populate grid with all characters
	populate_character_grid()
	
	# Connect to GameManager signals
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.character_unlocked.connect(_on_character_unlocked)

func populate_character_grid():
	"""Create cards for all characters"""
	# Clear existing cards
	for child in grid_container.get_children():
		child.queue_free()
	
	# Get all characters sorted by unlock tier
	var all_chars = CharacterDatabase.get_all_characters()
	all_chars.sort_custom(func(a, b):
		var char_a = CharacterDatabase.get_character(a)
		var char_b = CharacterDatabase.get_character(b)
		if char_a.unlock_tier != char_b.unlock_tier:
			return char_a.unlock_tier < char_b.unlock_tier
		return char_a.unlock_cost < char_b.unlock_cost
	)
	
	# Create a card for each character
	for char_id in all_chars:
		var card = CardScene.instantiate()
		grid_container.add_child(card)
		card.setup_character(char_id, tooltip)
		card.card_clicked.connect(_on_card_clicked)

func _on_card_clicked(character_id: String):
	"""Handle clicking on a character card"""
	var char_data = CharacterDatabase.get_character(character_id)
	
	# If locked, try to unlock
	if not GameManager.is_character_unlocked(character_id):
		if GameManager.get_coins() >= char_data.unlock_cost:
			# Show confirmation dialog
			show_unlock_confirmation(character_id, char_data)
		else:
			show_insufficient_funds_message(char_data.unlock_cost)
	else:
		# Already unlocked, just show info (tooltip already visible)
		pass

func show_unlock_confirmation(character_id: String, char_data: CharacterData):
	"""Show dialog to confirm character unlock"""
	# For now, just unlock directly. Later you can add a proper confirmation dialog
	if GameManager.spend_coins(char_data.unlock_cost):
		GameManager.unlock_character(character_id)
		print("Unlocked %s!" % char_data.character_name)

func show_insufficient_funds_message(cost: int):
	"""Show message that player doesn't have enough coins"""
	var needed = cost - GameManager.get_coins()
	print("Need %d more coins to unlock!" % needed)
	# Later: Show proper UI message

func _on_character_unlocked(character_id: String):
	"""Refresh grid when a character is unlocked"""
	populate_character_grid()

func _on_coins_changed(new_amount: int):
	"""Update coins display"""
	update_coins_display()

func update_coins_display():
	"""Update the coins label"""
	coins_label.text = "Coins: %d" % GameManager.get_coins()

func _on_back_pressed():
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
