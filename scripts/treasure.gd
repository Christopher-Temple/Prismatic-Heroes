# treasure.gd
extends Control

@onready var title_label = $TitleLabel
@onready var subtitle_label = $SubtitleLabel
@onready var shovels_label = $ShovelsLabel
@onready var treasure_grid = $TreasureGrid
@onready var continue_button = $ContinueButton
@onready var result_panel = $ResultPanel
@onready var result_label = $ResultPanel/ResultLabel

# Grid settings
const GRID_COLS = 15
const GRID_ROWS = 10
const CELL_SIZE = 50

# Game state
var shovels_remaining = 3
var grid_data: Array = []  # Contains what's buried at each position
var grid_cells: Array = []  # Visual cell references
var total_coins_found = 0
var relics_found: Array = []

# Treasure types
enum TreasureType {
	EMPTY,
	COINS_SMALL,   # 5-10 coins
	COINS_MEDIUM,  # 15-25 coins
	COINS_LARGE,   # 30-50 coins
	RELIC
}

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.visible = false
	result_panel.visible = false
	
	var relics = GameManager.current_run.get("relics", [])
	for relic in relics:
		if relic["type"] == "treasure_shovels":
			shovels_remaining += relic["data"].get("bonus_shovels", 0)

	setup_treasure_grid()
	generate_buried_treasure()
	update_shovels_display()

func setup_treasure_grid():
	"""Create the visual grid of dirt cells"""
	grid_cells = []
	
	for y in range(GRID_ROWS):
		var row = []
		for x in range(GRID_COLS):
			var cell = create_dirt_cell(x, y)
			treasure_grid.add_child(cell)
			row.append(cell)
		grid_cells.append(row)
	
	# Set grid layout
	treasure_grid.columns = GRID_COLS

func create_dirt_cell(x: int, y: int) -> Button:
	"""Create a single dirt cell button"""
	var cell = Button.new()
	cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	cell.text = ""
	
	# Style as dirt
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.3, 0.2)  # Brown dirt
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.2, 0.1)
	cell.add_theme_stylebox_override("normal", style)
	cell.add_theme_stylebox_override("hover", style)
	cell.add_theme_stylebox_override("pressed", style)
	
	# Connect click
	cell.pressed.connect(func(): _on_cell_clicked(x, y))
	
	# Store position
	cell.set_meta("grid_x", x)
	cell.set_meta("grid_y", y)
	cell.set_meta("dug", false)
	
	return cell

func generate_buried_treasure():
	"""Generate treasure layout in the grid"""
	grid_data = []
	
	# Initialize empty grid
	for y in range(GRID_ROWS):
		var row = []
		for x in range(GRID_COLS):
			row.append(TreasureType.EMPTY)
		grid_data.append(row)
	
	# Place coin piles (40-60 spots)
	var coin_spots = randi_range(40, 60)
	for i in range(coin_spots):
		var x = randi() % GRID_COLS
		var y = randi() % GRID_ROWS
		
		if grid_data[y][x] == TreasureType.EMPTY:
			var roll = randf()
			if roll < 0.5:
				grid_data[y][x] = TreasureType.COINS_SMALL
			elif roll < 0.85:
				grid_data[y][x] = TreasureType.COINS_MEDIUM
			else:
				grid_data[y][x] = TreasureType.COINS_LARGE
	
	# Place 0-2 relics
	var relic_count = randi_range(0, 2)
	var available_relics = get_available_relics()
	
	for i in range(relic_count):
		if available_relics.size() == 0:
			break
		
		# Find empty spot
		var placed = false
		var attempts = 0
		while not placed and attempts < 50:
			var x = randi() % GRID_COLS
			var y = randi() % GRID_ROWS
			
			if grid_data[y][x] == TreasureType.EMPTY:
				grid_data[y][x] = TreasureType.RELIC
				placed = true
			
			attempts += 1

func get_available_relics() -> Array:
	"""Get common/rare relics player doesn't have"""
	var available = []
	var purchased = GameManager.current_run.get("shop_purchases", {})
	var current_party = GameManager.get_current_party()
	
	for item_id in ShopDatabase.shop_items:
		var item = ShopDatabase.shop_items[item_id]
		
		# Only common and rare relics
		if item.category != "relic" or item.rarity == "epic":
			continue
		
		# Check unlock requirement
		if item.unlock_requirement != "":
			# For character-specific relics, only show if character is in party
			if not current_party.has(item.unlock_requirement):
				continue
			# Still check if character is unlocked
			if not GameManager.is_character_unlocked(item.unlock_requirement):
				continue
		
		# Check if already owned
		if purchased.has(item_id):
			continue
		
		available.append(item)
	
	return available

func _on_cell_clicked(x: int, y: int):
	"""Handle clicking on a dirt cell"""
	if shovels_remaining <= 0:
		return
	
	# Use a shovel
	shovels_remaining -= 1
	update_shovels_display()
	
	# Dig in pattern
	dig_pattern(x, y)
	
	# Check if game over
	if shovels_remaining <= 0:
		await get_tree().create_timer(1).timeout
		end_treasure_hunt()

func dig_pattern(center_x: int, center_y: int):
	"""Dig in the shovel pattern around center point"""
	# Pattern:
	# --x--
	# -xxx-
	# --x--
	
	var pattern = [
		Vector2i(0, -1),   # Top
		Vector2i(-1, 0),   # Left
		Vector2i(0, 0),    # Center
		Vector2i(1, 0),    # Right
		Vector2i(0, 1)     # Bottom
	]
	
	var coins_this_dig = 0
	var found_relic = false
	
	for offset in pattern:
		var dig_x = center_x + offset.x
		var dig_y = center_y + offset.y
		
		# Check bounds
		if dig_x < 0 or dig_x >= GRID_COLS or dig_y < 0 or dig_y >= GRID_ROWS:
			continue
		
		var cell = grid_cells[dig_y][dig_x]
		
		# Skip if already dug
		if cell.get_meta("dug"):
			continue
		
		cell.set_meta("dug", true)
		
		# Reveal what's buried
		var treasure = grid_data[dig_y][dig_x]
		reveal_treasure(cell, treasure)
		
		# Collect treasure
		match treasure:
			TreasureType.COINS_SMALL:
				coins_this_dig += randi_range(5, 10)
			TreasureType.COINS_MEDIUM:
				coins_this_dig += randi_range(15, 25)
			TreasureType.COINS_LARGE:
				coins_this_dig += randi_range(30, 50)
			TreasureType.RELIC:
				found_relic = true
	
	# Award coins
	if coins_this_dig > 0:
		# Check for coin magnet relic
		var coin_multiplier = 1.0
		var relics = GameManager.current_run.get("relics", [])
		for relic in relics:
			if relic["type"] == "treasure_coins":
				coin_multiplier = relic["data"].get("coin_multiplier", 1.0)
				break
		
		coins_this_dig = int(coins_this_dig * coin_multiplier)
		
		GameManager.add_coins(coins_this_dig)
		total_coins_found += coins_this_dig
		show_coin_popup(center_x, center_y, coins_this_dig)
	
	# Award relic
	if found_relic:
		award_random_relic()

func reveal_treasure(cell: Button, treasure: TreasureType):
	"""Change cell appearance to show what was found"""
	var style = StyleBoxFlat.new()
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	
	match treasure:
		TreasureType.EMPTY:
			style.bg_color = Color(0.2, 0.2, 0.2)  # Dark gray
			style.border_color = Color(0.1, 0.1, 0.1)
			cell.text = ""
		
		TreasureType.COINS_SMALL:
			style.bg_color = Color(0.8, 0.7, 0.3)  # Gold
			style.border_color = Color(0.6, 0.5, 0.1)
			cell.text = "💰"
		
		TreasureType.COINS_MEDIUM:
			style.bg_color = Color(0.9, 0.8, 0.4)  # Brighter gold
			style.border_color = Color(0.7, 0.6, 0.2)
			cell.text = "💰"
		
		TreasureType.COINS_LARGE:
			style.bg_color = Color(1.0, 0.9, 0.5)  # Brightest gold
			style.border_color = Color(0.8, 0.7, 0.3)
			cell.text = "💎"
		
		TreasureType.RELIC:
			style.bg_color = Color(0.6, 0.3, 0.8)  # Purple
			style.border_color = Color(0.4, 0.1, 0.6)
			cell.text = "✨"
	
	cell.add_theme_stylebox_override("normal", style)
	cell.add_theme_stylebox_override("hover", style)
	cell.add_theme_stylebox_override("pressed", style)
	cell.disabled = true
	
	# Animate reveal
	cell.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(cell, "modulate", Color.WHITE, 0.3)

func show_coin_popup(x: int, y: int, amount: int):
	"""Show floating text for coins found"""
	var label = Label.new()
	label.text = "+%d coins!" % amount
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("#F39C12"))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Position above the dig site
	label.position = Vector2(x * CELL_SIZE, y * CELL_SIZE - 30)
	treasure_grid.add_child(label)
	
	# Animate and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 1.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	
	await tween.finished
	label.queue_free()

func award_random_relic():
	"""Award a random available relic"""
	var available = get_available_relics()
	
	if available.size() == 0:
		# Fallback to coins if no relics available
		var coins = 50
		GameManager.add_coins(coins)
		total_coins_found += coins
		return
	
	var relic = available[randi() % available.size()]
	AchievementManager.track_relic_found()
	
	# Add to run
	if not GameManager.current_run.has("relics"):
		GameManager.current_run["relics"] = []
	
	GameManager.current_run["relics"].append({
		"id": relic.id,
		"type": relic.item_type,
		"data": relic.data
	})
	
	# Mark as owned
	if not GameManager.current_run.has("shop_purchases"):
		GameManager.current_run["shop_purchases"] = {}
	GameManager.current_run["shop_purchases"][relic.id] = 1
	
	GameManager.save_game()
	
	relics_found.append(relic)
	
	# Show relic notification
	show_relic_notification(relic)

func show_relic_notification(relic: ShopDatabase.ShopItem):
	"""Show popup for relic found"""
	var notification = PanelContainer.new()
	notification.position = Vector2(400, 200)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0862745, 0.129412, 0.243137, 1)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = ShopDatabase.get_rarity_color(relic.rarity)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	notification.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	notification.add_child(margin)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "✨ Relic Found! ✨"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var name_label = Label.new()
	name_label.text = relic.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", ShopDatabase.get_rarity_color(relic.rarity))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = relic.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(300, 0)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)
	
	add_child(notification)
	
	# Fade in
	notification.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(notification, "modulate", Color.WHITE, 0.5)
	
	# Auto-remove after 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	var fade_tween = create_tween()
	fade_tween.tween_property(notification, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	notification.queue_free()

func update_shovels_display():
	"""Update the shovels remaining label"""
	shovels_label.text = "Shovels Remaining: %d" % shovels_remaining
	
	if shovels_remaining == 0:
		shovels_label.add_theme_color_override("font_color", Color("#E74C3C"))  # Red

func end_treasure_hunt():
	"""Show final results"""
	# Disable all cells
	for row in grid_cells:
		for cell in row:
			cell.disabled = true
	# check if all cells were dug
	var all_dug = true
	for row in grid_cells:
		for cell in row:
			if not cell.get_meta("dug"):
				all_dug = false
				break
		if not all_dug:
			break
	
	if all_dug:
		AchievementManager.unlock_achievement("treasure_hunter")
	
	# Build result message
	var message = "Treasure Hunt Complete!\n\n"
	message += "Total Coins Found: %d\n" % total_coins_found
	
	if relics_found.size() > 0:
		message += "\nRelics Found:\n"
		for relic in relics_found:
			message += "• %s\n" % relic.name
	
	result_label.text = message
	result_panel.visible = true
	continue_button.visible = true
	
	# Animate result
	result_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(result_panel, "modulate", Color.WHITE, 0.5)

func _on_continue_pressed():
	"""Return to map"""
	get_tree().change_scene_to_file("res://scenes/map_view.tscn")
