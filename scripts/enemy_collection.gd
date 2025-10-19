extends Control

# Preload the card scene
const CardScene = preload("res://scenes/card_display.tscn")

@onready var grid_container = $ScrollContainer/GridContainer
@onready var tooltip = $CustomTooltip
@onready var back_button = $BackButton
@onready var title_label = $TitleLabel
@onready var filter_all = $FilterButtons/AllButton
@onready var filter_normal = $FilterButtons/NormalButton
@onready var filter_elite = $FilterButtons/EliteButton
@onready var filter_boss = $FilterButtons/BossButton

var current_filter = "all"

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	filter_all.pressed.connect(func(): set_filter("all"))
	filter_normal.pressed.connect(func(): set_filter("normal"))
	filter_elite.pressed.connect(func(): set_filter("elite"))
	filter_boss.pressed.connect(func(): set_filter("boss"))
	
	# Update UI
	title_label.text = "Enemy Bestiary"
	
	# Populate grid with all enemies
	populate_enemy_grid()

func set_filter(filter_type: String):
	"""Change the enemy filter"""
	current_filter = filter_type
	populate_enemy_grid()
	
	# Update button states (visual feedback)
	filter_all.disabled = (filter_type == "all")
	filter_normal.disabled = (filter_type == "normal")
	filter_elite.disabled = (filter_type == "elite")
	filter_boss.disabled = (filter_type == "boss")

func populate_enemy_grid():
	"""Create cards for filtered enemies"""
	# Clear existing cards
	for child in grid_container.get_children():
		child.queue_free()
	
	# Get enemies based on filter
	var enemy_list = []
	match current_filter:
		"all":
			enemy_list = EnemyDatabase.all_enemy_ids.duplicate()
		"normal":
			enemy_list = EnemyDatabase.get_all_normal_enemies()
		"elite":
			enemy_list = EnemyDatabase.get_all_elite_enemies()
		"boss":
			enemy_list = EnemyDatabase.get_all_bosses()
	
	# Sort by type then by base health
	enemy_list.sort_custom(func(a, b):
		var enemy_a = EnemyDatabase.get_enemy(a)
		var enemy_b = EnemyDatabase.get_enemy(b)
		
		# Sort order: Normal < Elite < Boss
		var type_order = {"Normal": 0, "Elite": 1, "Boss": 2}
		var order_a = type_order.get(enemy_a.enemy_type, 0)
		var order_b = type_order.get(enemy_b.enemy_type, 0)
		
		if order_a != order_b:
			return order_a < order_b
		return enemy_a.base_health < enemy_b.base_health
	)
	
	# Create a card for each enemy
	for enemy_id in enemy_list:
		var card = CardScene.instantiate()
		grid_container.add_child(card)
		card.setup_enemy(enemy_id, tooltip)
		# Enemies don't need click interaction (just display info)

func _on_back_pressed():
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
