extends Control

@onready var map_container = $MapContainer
@onready var title_label = $TitleOverlay/TitleLabel
@onready var title_overlay = $TitleOverlay

# Map data
var map_data: Dictionary
var objective_data: Dictionary
var node_buttons: Array = []

# Animation state
var can_interact: bool = false

# Node settings
const NODE_SIZE = 60

# Icon paths - place your 60x60 icons here
const ICON_PATHS = {
	"start": "res://assets/icons/start.png",
	"battle": "res://assets/icons/battle.png",
	"elite": "res://assets/icons/elite.png",
	"shop": "res://assets/icons/shop.png",
	"rest": "res://assets/icons/rest.png",
	"treasure": "res://assets/icons/treasure.png",
	"mystery": "res://assets/icons/mystery.png",
	"boss": "res://assets/icons/boss.png",
	"event": "res://assets/icons/event.png"
}

func _ready():
	# Load map and objective from GameManager
	map_data = GameManager.current_run.get("map", {})
	objective_data = GameManager.current_run.get("objective", {})
	
	if map_data.is_empty():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	
	# Build the map visually
	create_map_nodes()
	create_connections()
	AudioManager.play_music("main_menu", 2.0)
	# Start title sequence
	start_title_sequence()

func create_map_nodes():
	"""Create visual representations of all nodes"""
	for node_data in map_data["nodes"]:
		var node_button = create_node_button(node_data)
		map_container.add_child(node_button)
		node_buttons.append(node_button)

func create_node_button(node_data) -> TextureButton:
	"""Create a clickable node button with icon"""
	var button = TextureButton.new()
	button.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
	button.position = node_data.position
	
	# Get node type
	var type_id = node_data.node_type
	
	# Load icon texture
	var icon_path = ICON_PATHS.get(type_id, "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		button.texture_normal = texture
		button.texture_hover = texture
		button.texture_pressed = texture
		
		# Apply color tint based on node type
		var node_type = MissionDatabase.get_node_type(type_id) if type_id != "start" and type_id != "boss" else null
		if type_id == "start":
			button.modulate = Color("#2ECC71")  # Green
		elif type_id == "boss":
			button.modulate = Color("#C0392B")  # Dark Red
		elif node_type:
			button.modulate = node_type.color
	else:
		# Fallback: create colored rect if icon missing
		print("Warning: Icon not found for ", type_id, " at ", icon_path)
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
		color_rect.color = Color.GRAY
		button.add_child(color_rect)
	
	# Store node data
	button.set_meta("node_id", node_data.id)
	button.set_meta("node_type", type_id)
	
	# Connect click handler
	button.pressed.connect(func(): _on_node_clicked(node_data.id))
	
	# Initially disable
	button.disabled = true
	
	# Highlight if current
	if node_data.is_current:
		button.modulate = button.modulate.lightened(0.3)
	
	return button

func draw_connection(from_pos: Vector2, to_pos: Vector2, from_id: int, to_id: int):
	"""Draw a line between two nodes"""
	var line = Line2D.new()
	line.add_point(from_pos + Vector2(NODE_SIZE/2, NODE_SIZE/2))
	line.add_point(to_pos + Vector2(NODE_SIZE/2, NODE_SIZE/2))
	line.default_color = Color(0.6, 0.5, 0.4, 0.6)
	line.width = 4
	line.z_index = -1
	
	# Store connection info for later highlighting
	line.set_meta("from_id", from_id)
	line.set_meta("to_id", to_id)
	line.name = "Connection_%d_%d" % [from_id, to_id]
	
	map_container.add_child(line)

func create_connections():
	"""Draw lines between connected nodes"""
	for node_data in map_data["nodes"]:
		for connected_id in node_data.connections:
			var connected_node = get_node_by_id(connected_id)
			if connected_node:
				draw_connection(node_data.position, connected_node.position, node_data.id, connected_id)
	
	# Highlight already traveled path
	highlight_traveled_path()

func highlight_traveled_path():
	"""Highlight the path player has taken"""
	# Get visited nodes from map data
	var visited_ids = []
	for node_data in map_data["nodes"]:
		if node_data.is_visited:
			visited_ids.append(node_data.id)
	
	# Highlight connections between consecutive visited nodes
	for i in range(visited_ids.size() - 1):
		var from_id = visited_ids[i]
		var to_id = visited_ids[i + 1]
		var line_name = "Connection_%d_%d" % [from_id, to_id]
		var line = map_container.get_node_or_null(line_name)
		if line and line is Line2D:
			line.default_color = Color("#F39C12")  # Gold for traveled path
			line.width = 6

func _on_node_clicked(node_id: int):
	"""Handle clicking on a map node"""
	if not can_interact:
		return
	
	var node_data = get_node_by_id(node_id)
	if not node_data:
		return
	
	# Check if node is already visited
	if node_data.is_visited:
		print("Node already visited, cannot select again")
		return
	
	print("Moving to node: ", node_id, " (", node_data.node_type, ")")
	
	# Highlight path (same as before)
	var prev_node_id = map_data["current_node_id"]
	var line_name = "Connection_%d_%d" % [prev_node_id, node_id]
	var line = map_container.get_node_or_null(line_name)
	if line and line is Line2D:
		line.default_color = Color("#F39C12")
		line.width = 6
	
	if not map_data.has("path_history"):
		map_data["path_history"] = []
	map_data["path_history"].append({"from": prev_node_id, "to": node_id})
	
	# Update position
	map_data["current_node_id"] = node_id
	GameManager.current_run["map"] = map_data
	
	node_data.is_visited = true
	node_data.is_current = true
	
	var prev_node = get_node_by_id(prev_node_id)
	if prev_node:
		prev_node.is_current = false
	
	GameManager.save_game()
	
	var node_type = node_data.node_type
	
	# Handle boss node
	if node_type == "boss":
		print("Starting BOSS battle!")
		get_tree().change_scene_to_file("res://scenes/boss_intro.tscn")
		return
	
	# Handle battle nodes
	if node_type == "battle" or node_type == "elite":
		var is_elite = (node_type == "elite")
		print("Starting battle: Elite=%s" % is_elite)
		GameManager.start_battle(is_elite)
		
		var battle_scene_path = "res://scenes/battle_scene.tscn"
		if ResourceLoader.exists(battle_scene_path):
			print("Loading battle scene from: ", battle_scene_path)
			var result = get_tree().change_scene_to_file(battle_scene_path)
			if result != OK:
				print("ERROR: Failed to load battle scene! Error code: ", result)
		else:
			print("ERROR: Battle scene not found at: ", battle_scene_path)
		return
	
	# Handle other nodes
	var type_data = MissionDatabase.get_node_type(node_type)
	if type_data and type_data.scene_path != "":
		get_tree().change_scene_to_file(type_data.scene_path)
	else:
		print("Node type '%s' has no scene defined" % node_type)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func get_node_by_id(node_id: int):
	"""Find node data by ID"""
	for node_data in map_data["nodes"]:
		if node_data.id == node_id:
			return node_data
	return null

func start_title_sequence():
	"""Show title, then fade out"""
	can_interact = false
	
	# Check if we're returning from a battle (node already visited)
	var current_node = get_node_by_id(map_data["current_node_id"])
	if current_node and current_node.is_visited and current_node.id != 0:
		# Skip title animation, go straight to gameplay
		print("Returning from battle, skipping title")
		title_overlay.visible = false
		can_interact = true
		enable_available_nodes()
		return
	
	# Show title for first time
	title_label.text = objective_data["title"]
	title_label.modulate = Color(1, 1, 1, 0)
	title_overlay.visible = true
	
	# Animate title
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)  # Fade in
	tween.tween_interval(3.0)  # Hold for 3 seconds
	tween.tween_property(title_label, "modulate:a", 0.0, 1.0)  # Fade out
	
	await tween.finished
	
	# Hide overlay
	title_overlay.visible = false
	
	# Enable interaction
	can_interact = true
	enable_available_nodes()

func enable_available_nodes():
	"""Enable nodes that player can currently access"""
	for i in range(node_buttons.size()):
		var button = node_buttons[i]
		var node_data = map_data["nodes"][i]
		
		# Disable if already visited
		if node_data.is_visited:
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Dim visited nodes
		# Enable if current or available
		elif node_data.is_current or is_node_available(node_data):
			button.disabled = false
			button.modulate = Color(1, 1, 1, 1)
		else:
			button.disabled = true
			button.modulate = Color(1, 1, 1, 1)

func is_node_available(node_data) -> bool:
	"""Check if a node is accessible from current position"""
	var current_node_id = map_data["current_node_id"]
	var current_node = get_node_by_id(current_node_id)
	
	if current_node:
		return node_data.id in current_node.connections
	
	return false
