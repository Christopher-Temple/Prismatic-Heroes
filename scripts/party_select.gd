extends Control

# Preload card scene
const CardScene = preload("res://scenes/card_display.tscn")

@onready var available_grid = $AvailablePanel/ScrollContainer/GridContainer
@onready var selected_slot1 = $SelectedPanel/HBoxContainer/Slot1
@onready var selected_slot2 = $SelectedPanel/HBoxContainer/Slot2
@onready var selected_slot3 = $SelectedPanel/HBoxContainer/Slot3
@onready var tooltip = $CustomTooltip
@onready var start_button = $StartButton
@onready var back_button = $BackButton
@onready var title_label = $TitleLabel

# Selected party
var selected_party: Array[String] = ["", "", ""]
var selected_cards: Array = [null, null, null]

# Slot colors (position-based for gameplay)
const SLOT_COLORS = [
	Color("#E63946"),  # Slot 1 - Red
	Color("#457B9D"),  # Slot 2 - Blue
	Color("#F1C40F")   # Slot 3 - Yellow
]

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	# Setup slots
	setup_slot(selected_slot1, 0)
	setup_slot(selected_slot2, 1)
	setup_slot(selected_slot3, 2)
	
	# Populate available characters
	populate_available_characters()
	
	# Start button disabled until 3 selected
	update_start_button()

func setup_slot(slot: Control, slot_index: int):
	"""Setup a party slot"""
	# Set slot color indicator
	var color_indicator = slot.get_node_or_null("ColorIndicator")
	if color_indicator and color_indicator is ColorRect:
		color_indicator.color = SLOT_COLORS[slot_index]
	
	# Make slot clickable to deselect
	slot.gui_input.connect(func(event): _on_slot_clicked(event, slot_index))

func populate_available_characters():
	"""Create cards for all unlocked characters"""
	# Clear existing
	for child in available_grid.get_children():
		child.queue_free()
	
	# Get all unlocked characters
	var unlocked_chars = []
	for char_id in CharacterDatabase.get_all_characters():
		if GameManager.is_character_unlocked(char_id):
			unlocked_chars.append(char_id)
	
	# Sort by unlock tier
	unlocked_chars.sort_custom(func(a, b):
		var char_a = CharacterDatabase.get_character(a)
		var char_b = CharacterDatabase.get_character(b)
		return char_a.unlock_tier < char_b.unlock_tier
	)
	
	# Create cards
	for char_id in unlocked_chars:
		var card = CardScene.instantiate()
		available_grid.add_child(card)
		card.setup_character(char_id, tooltip)
		card.card_clicked.connect(_on_character_selected)

func _on_character_selected(character_id: String):
	"""Handle character card clicked"""
	# Check if already selected
	var existing_index = selected_party.find(character_id)
	if existing_index != -1:
		# Already selected, deselect it
		deselect_character(existing_index)
		return
	
	# Find first empty slot
	for i in range(3):
		if selected_party[i] == "":
			add_to_slot(character_id, i)
			break

func add_to_slot(character_id: String, slot_index: int):
	"""Add character to a specific slot"""
	selected_party[slot_index] = character_id
	
	# Get character data
	var char_data = CharacterDatabase.get_character(character_id)
	
	# Get the slot node
	var slot = get_slot_node(slot_index)
	
	# Clear existing portrait and label
	var old_portrait = slot.get_node_or_null("CharacterPortrait")
	if old_portrait:
		old_portrait.queue_free()
	var old_label = slot.get_node_or_null("NameLabel")
	if old_label:
		old_label.queue_free()
	
	# Create character display in slot
	var portrait = TextureRect.new()
	portrait.name = "CharacterPortrait"
	
	# Position below ColorIndicator (8px) and leave room for name (25px)
	portrait.position = Vector2(0, 8)
	portrait.size = Vector2(120, 107)  # 140 total - 8 (color bar) - 25 (name) = 107
	
	# Load portrait or use color
	if char_data.portrait_path != "" and ResourceLoader.exists(char_data.portrait_path):
		portrait.texture = load(char_data.portrait_path)
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		# Use colored rectangle instead
		var color_rect = ColorRect.new()
		color_rect.name = "CharacterPortrait"
		color_rect.color = char_data.color
		color_rect.position = Vector2(0, 8)
		color_rect.size = Vector2(120, 107)
		portrait.queue_free()
		portrait = color_rect
	
	slot.add_child(portrait)
	selected_cards[slot_index] = portrait
	
	# Add name label at bottom
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = char_data.character_name
	name_label.position = Vector2(-30, 115)
	name_label.size = Vector2(120, 25)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(name_label)
	
	update_start_button()

func deselect_character(slot_index: int):
	"""Remove character from slot"""
	selected_party[slot_index] = ""
	
	if selected_cards[slot_index]:
		selected_cards[slot_index].queue_free()
		selected_cards[slot_index] = null
	
	# Remove name label too
	var slot = get_slot_node(slot_index)
	var name_label = slot.get_node_or_null("NameLabel")
	if name_label:
		name_label.queue_free()
	
	update_start_button()

func _on_slot_clicked(event: InputEvent, slot_index: int):
	"""Handle clicking on a party slot to deselect"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_party[slot_index] != "":
			deselect_character(slot_index)

func get_slot_node(index: int) -> Control:
	"""Get slot node by index"""
	match index:
		0: return selected_slot1
		1: return selected_slot2
		2: return selected_slot3
	return null

func update_start_button():
	"""Enable/disable start button based on party selection"""
	var all_selected = true
	for char in selected_party:
		if char == "":
			all_selected = false
			break
	
	start_button.disabled = not all_selected

func _on_start_pressed():
	"""Start the run with selected party"""
	# Create clean party array
	var party = []
	for char_id in selected_party:
		if char_id != "":
			party.append(char_id)
	
	if party.size() != 3:
		print("Error: Must select exactly 3 characters")
		return
	
	print("Starting run with party: ", party)
	
	# Initialize the run in GameManager
	GameManager.start_new_run(party)
	
	# Generate objective and map
	var objective = MissionDatabase.generate_random_objective()
	var map_data = MapGenerator.generate_map(GameManager.current_run["mapSeed"])
	
	# Store in GameManager
	GameManager.current_run["objective"] = objective
	GameManager.current_run["map"] = map_data
	
	print("Objective: ", objective["title"])
	
	# Go to map scene
	get_tree().change_scene_to_file("res://scenes/map_view.tscn")

func _on_back_pressed():
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
