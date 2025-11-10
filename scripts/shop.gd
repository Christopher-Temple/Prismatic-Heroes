# shop.gd
extends Control

@onready var shop_title = $TitleLabel
@onready var coins_label = $CoinsLabel
@onready var items_container: VBoxContainer = $ScrollContainer/ItemsContainer
@onready var leave_button = $LeaveButton

# Shop state
var available_items: Array = []
var purchased_items: Dictionary = {}  # item_id: times_purchased
var items_purchased_this_visit: int = 0

func _ready():
	leave_button.pressed.connect(_on_leave_pressed)
	
	# Load purchased items for this run
	purchased_items = GameManager.current_run.get("shop_purchases", {})
	
	update_coins_display()
	generate_shop_inventory()

func update_coins_display():
	"""Update coins label"""
	coins_label.text = "Coins: %d" % GameManager.get_coins()

func generate_shop_inventory():
	"""Generate random shop items"""
	# Get 6 random available items
	available_items = ShopDatabase.get_available_shop_items(purchased_items, 6)
	
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# Create UI for each item
	for item in available_items:
		create_shop_item_ui(item)

func create_shop_item_ui(item: ShopDatabase.ShopItem):
	"""Create UI panel for shop item"""
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(1100, 140)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.172549, 0.243137, 0.313726, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = ShopDatabase.get_rarity_color(item.rarity)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	item_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	item_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# Item name with rarity color
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", ShopDatabase.get_rarity_color(item.rarity))
	name_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.92549, 0.941176, 0.945098, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(desc_label)
	
	# Cost and buy button
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
		# Calculate actual cost with discount
	var actual_cost = item.cost
	var discount_multiplier = 1.0
	
	# Check for merchant discount relic
	var relics = GameManager.current_run.get("relics", [])
	for relic in relics:
		if relic["type"] == "shop_discount":
			discount_multiplier = 1.0 - relic["data"].get("discount_percent", 0.0)
			break
	
	actual_cost = int(item.cost * discount_multiplier)

	var cost_label = Label.new()
	if discount_multiplier < 1.0:
		# Show original price crossed out + discounted price
		cost_label.text = "[s]💰 %d[/s] 💰 %d Coins" % [item.cost, actual_cost]
		cost_label.bbcode_enabled = true
	else:
		cost_label.text = "💰 %d Coins" % actual_cost
	cost_label.add_theme_font_size_override("font_size", 20)
	cost_label.add_theme_color_override("font_color", Color("#F39C12"))
	cost_label.add_theme_constant_override("outline_size", 4)
	hbox.add_child(cost_label)
	
	var buy_button = Button.new()
	buy_button.text = "Purchase"
	buy_button.custom_minimum_size = Vector2(120, 40)
	buy_button.pressed.connect(func(): _on_item_purchased(item, item_panel, buy_button, actual_cost))
	hbox.add_child(buy_button)
	
	# Disable if can't afford
	if GameManager.get_coins() < actual_cost:
		buy_button.disabled = true
		buy_button.text = "Cannot Afford"
	
	items_container.add_child(item_panel)

func _on_item_purchased(item: ShopDatabase.ShopItem, panel: Panel, button: Button, actual_cost: int):
	"""Handle purchasing an item"""
	AudioManager.play_button_click()
	var coins = GameManager.get_coins()
	
	if coins < actual_cost:
		return
	
	# Spend coins (use actual_cost instead of item.cost)
	if not GameManager.spend_coins(actual_cost):
		return
	AudioManager.play_sfx("coin_pickup")
	# Track purchase
	if not purchased_items.has(item.id):
		purchased_items[item.id] = 0
	purchased_items[item.id] += 1
	
	# Save purchase to run data
	GameManager.current_run["shop_purchases"] = purchased_items
	
	# Apply item effect
	apply_item_effect(item)
	
	# Update UI
	update_coins_display()
	button.disabled = true
	button.text = "Purchased"
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(0.5, 1.0, 0.5), 0.3)
	
	# Track Achievements
	items_purchased_this_visit += 1
	AchievementManager.track_shop_purchase(items_purchased_this_visit)

func apply_item_effect(item: ShopDatabase.ShopItem):
	"""Apply the item's effect to the current run"""
	match item.category:
		"health":
			apply_health_item(item)
		"relic":
			apply_relic(item)

func apply_health_item(item: ShopDatabase.ShopItem):
	"""Apply health item effects"""
	if item.item_type == "max_hp":
		var amount = item.data.get("amount", 20)
		GameManager.current_run["maxHealth"] += amount
		GameManager.current_run["currentHealth"] += amount

func apply_relic(item: ShopDatabase.ShopItem):
	"""Add relic to run inventory"""
	if not GameManager.current_run.has("relics"):
		GameManager.current_run["relics"] = []
	
	GameManager.current_run["relics"].append({
		"id": item.id,
		"type": item.item_type,
		"data": item.data
	})

	GameManager.save_game()

func _on_leave_pressed():
	"""Leave shop and return to map"""
	AudioManager.play_button_click()
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/map_view.tscn")
