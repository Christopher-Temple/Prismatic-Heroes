# PuzzleGrid.gd - COMPLETE VERSION
extends Node2D
class_name PuzzleGrid

signal blocks_matched(matched_blocks: Array, color: String, count: int)
signal blocks_settled()
signal grid_full()
signal column_dissolved(column: int)

const GRID_WIDTH = 40
const GRID_HEIGHT = 23
const CELL_SIZE = 20

# Grid data structure
var grid: Array = []  # 2D array of BlockCells
var walls: Array = []  # Wall positions
var slimes: Array = []  # Active slime obstacles {x, y, trail: []}

# Visual container
@onready var blocks_container = $BlocksContainer
@onready var walls_container = $WallsContainer
@onready var obstacles_container = $ObstaclesContainer

class BlockCell:
	var color: String = ""  # "red", "blue", "yellow", "gray", "brown", "white", ""
	var is_wall: bool = false
	var is_obstacle: bool = false  # For webs, slime, etc
	var obstacle_type: String = ""  # "web", "slime"
	var is_slimed: bool = false  # Covered by slime trail
	var position: Vector2i = Vector2i.ZERO
	var sprite: Sprite2D = null
	var obstacle_sprite: Sprite2D = null

func _ready():
	# Create containers if they don't exist
	if not has_node("BlocksContainer"):
		blocks_container = Node2D.new()
		blocks_container.name = "BlocksContainer"
		add_child(blocks_container)
	
	if not has_node("WallsContainer"):
		walls_container = Node2D.new()
		walls_container.name = "WallsContainer"
		walls_container.z_index = -1
		add_child(walls_container)
	
	if not has_node("ObstaclesContainer"):
		obstacles_container = Node2D.new()
		obstacles_container.name = "ObstaclesContainer"
		obstacles_container.z_index = 1
		add_child(obstacles_container)
	
	initialize_grid()
	draw_grid_boundary()

func initialize_grid():
	"""Create empty grid"""
	grid = []
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			var cell = BlockCell.new()
			cell.position = Vector2i(x, y)
			row.append(cell)
		grid.append(row)

func set_wall(x: int, y: int):
	"""Mark a cell as a wall"""
	if is_valid_position(x, y):
		grid[y][x].is_wall = true
		walls.append(Vector2i(x, y))
		create_wall_sprite(x, y)

func create_wall_sprite(x: int, y: int):
	"""Create visual representation of wall"""
	var sprite = Sprite2D.new()
	sprite.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)
	# Use colored rect for now (replace with texture later)
	var texture = create_colored_texture(Color(0.3, 0.3, 0.3), CELL_SIZE)
	sprite.texture = texture
	walls_container.add_child(sprite)

func create_colored_texture(color: Color, size: int) -> ImageTexture:
	"""Create a simple colored square texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func is_valid_position(x: int, y: int) -> bool:
	"""Check if position is within grid bounds"""
	return x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT

func is_empty(x: int, y: int) -> bool:
	"""Check if cell is empty (no block, no wall, no obstacle)"""
	if not is_valid_position(x, y):
		return false
	var cell = grid[y][x]
	return cell.color == "" and not cell.is_wall and not cell.is_obstacle

func is_occupied(x: int, y: int) -> bool:
	"""Check if cell has a block, wall, or obstacle"""
	if not is_valid_position(x, y):
		return true
	var cell = grid[y][x]
	return cell.color != "" or cell.is_wall or cell.is_obstacle

func can_match(x: int, y: int) -> bool:
	"""Check if block at position can be matched (not slimed)"""
	if not is_valid_position(x, y):
		return false
	return not grid[y][x].is_slimed

func place_block(x: int, y: int, color: String) -> bool:
	"""Place a block at position"""
	if not is_valid_position(x, y) or grid[y][x].is_wall or grid[y][x].is_obstacle:
		return false
	
	grid[y][x].color = color
	create_block_sprite(x, y, color)
	return true

func create_block_sprite(x: int, y: int, color: String):
	"""Create visual sprite for block"""
	var sprite = Sprite2D.new()
	
	# Center sprite in cell
	sprite.position = Vector2(
		x * CELL_SIZE + CELL_SIZE / 2,
		y * CELL_SIZE + CELL_SIZE / 2
	)
	
	# Map color names to actual colors
	var color_map = {
		"red": Color("#E63946"),
		"blue": Color("#457B9D"),
		"yellow": Color("#F1C40F"),
		"gray": Color("#95A5A6"),
		"brown": Color("#8B4513"),
		"white": Color("#ECF0F1")
	}
	
	var block_color = color_map.get(color, Color.WHITE)
	
	# Make texture slightly smaller than cell for grid lines to show
	sprite.texture = create_colored_texture(block_color, CELL_SIZE - 2)  # 2px gap for grid lines
	sprite.name = "Block_%d_%d" % [x, y]
	
	grid[y][x].sprite = sprite
	blocks_container.add_child(sprite)

func remove_block(x: int, y: int):
	"""Remove block from position"""
	if is_valid_position(x, y):
		if grid[y][x].sprite:
			grid[y][x].sprite.queue_free()
			grid[y][x].sprite = null
		grid[y][x].color = ""

func get_block_color(x: int, y: int) -> String:
	"""Get color of block at position"""
	if is_valid_position(x, y):
		return grid[y][x].color
	return ""

# === WEB OBSTACLE METHODS ===

func place_web(x: int, y: int) -> bool:
	"""Place a web obstacle (only below row 3)"""
	if not is_valid_position(x, y) or y < 3:
		return false
	
	if grid[y][x].is_wall or grid[y][x].is_obstacle or grid[y][x].color != "":
		return false
	
	grid[y][x].is_obstacle = true
	grid[y][x].obstacle_type = "web"
	create_web_sprite(x, y)
	return true

func create_web_sprite(x: int, y: int):
	"""Create visual web sprite"""
	var sprite = Sprite2D.new()
	sprite.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)
	sprite.texture = create_colored_texture(Color(0.8, 0.8, 0.8, 0.6), CELL_SIZE)  # Semi-transparent gray
	sprite.name = "Web_%d_%d" % [x, y]
	grid[y][x].obstacle_sprite = sprite
	obstacles_container.add_child(sprite)

func block_touches_web(x: int, y: int) -> bool:
	"""Check if position has a web"""
	if is_valid_position(x, y):
		return grid[y][x].is_obstacle and grid[y][x].obstacle_type == "web"
	return false

func remove_web(x: int, y: int):
	"""Remove web obstacle"""
	if is_valid_position(x, y) and grid[y][x].obstacle_type == "web":
		if grid[y][x].obstacle_sprite:
			grid[y][x].obstacle_sprite.queue_free()
			grid[y][x].obstacle_sprite = null
		grid[y][x].is_obstacle = false
		grid[y][x].obstacle_type = ""

# === SLIME OBSTACLE METHODS ===

func place_slime(x: int) -> bool:
	"""Place slime at top of tallest column"""
	# Find highest block in column
	var start_y = 0
	for y in range(GRID_HEIGHT):
		if is_occupied(x, y):
			start_y = y - 1 if y > 0 else 0
			break
	
	if not is_valid_position(x, start_y):
		return false
	
	# Place slime head
	grid[start_y][x].is_obstacle = true
	grid[start_y][x].obstacle_type = "slime"
	create_slime_sprite(x, start_y)
	
	# Track slime
	slimes.append({"x": x, "y": start_y, "trail": []})
	return true

func create_slime_sprite(x: int, y: int):
	"""Create visual slime sprite"""
	var sprite = Sprite2D.new()
	sprite.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)
	sprite.texture = create_colored_texture(Color(0.2, 0.8, 0.2, 0.8), CELL_SIZE)  # Green slime
	sprite.name = "Slime_%d_%d" % [x, y]
	grid[y][x].obstacle_sprite = sprite
	obstacles_container.add_child(sprite)

func update_slimes():
	"""Move all slimes down one row"""
	var slimes_to_remove = []
	
	for i in range(slimes.size()):
		var slime_data = slimes[i]
		var x = slime_data["x"]
		var y = slime_data["y"]
		
		# Mark current position as trail
		grid[y][x].is_slimed = true
		slime_data["trail"].append(Vector2i(x, y))
		update_block_slime_visual(x, y)
		
		# Check if reached bottom
		if y >= GRID_HEIGHT - 1 or is_occupied(x, y + 1):
			# Dissolve entire column
			dissolve_column(x)
			slimes_to_remove.append(i)
		else:
			# Move slime down
			remove_slime_head(x, y)
			slime_data["y"] = y + 1
			grid[y + 1][x].is_obstacle = true
			grid[y + 1][x].obstacle_type = "slime"
			create_slime_sprite(x, y + 1)
	
	# Remove completed slimes
	for i in range(slimes_to_remove.size() - 1, -1, -1):
		slimes.remove_at(slimes_to_remove[i])

func remove_slime_head(x: int, y: int):
	"""Remove slime head sprite"""
	if is_valid_position(x, y):
		if grid[y][x].obstacle_sprite:
			grid[y][x].obstacle_sprite.queue_free()
			grid[y][x].obstacle_sprite = null
		grid[y][x].is_obstacle = false
		grid[y][x].obstacle_type = ""

func update_block_slime_visual(x: int, y: int):
	"""Add slime overlay to block sprite"""
	if is_valid_position(x, y) and grid[y][x].sprite:
		grid[y][x].sprite.modulate = Color(0.5, 1.0, 0.5)  # Green tint

func dissolve_column(column: int):
	"""Remove all blocks in a column"""
	for y in range(GRID_HEIGHT):
		if grid[y][column].color != "":
			remove_block(column, y)
		if grid[y][column].is_slimed:
			grid[y][column].is_slimed = false
	
	column_dissolved.emit(column)

func remove_all_slime_in_column(column: int):
	"""Remove slime and trail from column (Paladin ability)"""
	# Find and remove slime from tracking
	for i in range(slimes.size() - 1, -1, -1):
		if slimes[i]["x"] == column:
			var slime_data = slimes[i]
			# Remove trail
			for pos in slime_data["trail"]:
				if is_valid_position(pos.x, pos.y):
					grid[pos.y][pos.x].is_slimed = false
					if grid[pos.y][pos.x].sprite:
						grid[pos.y][pos.x].sprite.modulate = Color.WHITE
			# Remove head
			remove_slime_head(slime_data["x"], slime_data["y"])
			slimes.remove_at(i)

# === GRAVITY & MATCHING ===

func apply_gravity() -> bool:
	"""Make blocks fall down. Returns true if any blocks moved."""
	var blocks_moved = false
	
	for y in range(GRID_HEIGHT - 2, -1, -1):
		for x in range(GRID_WIDTH):
			if grid[y][x].color != "" and not grid[y][x].is_wall:
				var fall_distance = 0
				var check_y = y + 1
				
				while check_y < GRID_HEIGHT and is_empty(x, check_y):
					fall_distance += 1
					check_y += 1
				
				if fall_distance > 0:
					var color = grid[y][x].color
					var was_slimed = grid[y][x].is_slimed
					var sprite = grid[y][x].sprite
					
					grid[y][x].color = ""
					grid[y][x].sprite = null
					grid[y][x].is_slimed = false
					
					grid[y + fall_distance][x].color = color
					grid[y + fall_distance][x].sprite = sprite
					grid[y + fall_distance][x].is_slimed = was_slimed
					
					if sprite:
						sprite.position.y = (y + fall_distance) * CELL_SIZE + CELL_SIZE/2
					
					blocks_moved = true
	
	return blocks_moved

func find_matches() -> Array:
	"""Find all matching groups of 3+ blocks that can be matched (not slimed)"""
	var matches = []
	var checked = {}
	
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var color = grid[y][x].color
			if color == "" or grid[y][x].is_wall or not can_match(x, y):
				continue
			
			var key = "%d,%d" % [x, y]
			if checked.has(key):
				continue
			
			var h_match = check_horizontal_match(x, y, color)
			if h_match.size() >= 3:
				for pos in h_match:
					checked["%d,%d" % [pos.x, pos.y]] = true
				matches.append({"positions": h_match, "color": color})
			
			var v_match = check_vertical_match(x, y, color)
			if v_match.size() >= 3:
				for pos in v_match:
					checked["%d,%d" % [pos.x, pos.y]] = true
				matches.append({"positions": v_match, "color": color})
	
	return matches

func check_horizontal_match(start_x: int, y: int, color: String) -> Array:
	"""Find horizontal matching blocks"""
	var matches = []
	var x = start_x
	
	while x < GRID_WIDTH and grid[y][x].color == color and can_match(x, y):
		matches.append(Vector2i(x, y))
		x += 1
	
	return matches if matches.size() >= 3 else []

func check_vertical_match(x: int, start_y: int, color: String) -> Array:
	"""Find vertical matching blocks"""
	var matches = []
	var y = start_y
	
	while y < GRID_HEIGHT and grid[y][x].color == color and can_match(x, y):
		matches.append(Vector2i(x, y))
		y += 1
	
	return matches if matches.size() >= 3 else []

func clear_matches(matches: Array):
	"""Remove matched blocks and any webs they're in"""
	for match_data in matches:
		for pos in match_data["positions"]:
			# Remove web if block was stuck in one
			if block_touches_web(pos.x, pos.y):
				remove_web(pos.x, pos.y)
			remove_block(pos.x, pos.y)

func is_grid_full() -> bool:
	"""Check if top rows have blocks (game over)"""
	for y in range(2):  # Check top 2 rows
		for x in range(GRID_WIDTH):
			if grid[y][x].color != "":
				return true
	return false

func find_safe_spawn_column() -> int:
	"""Find a column where a piece can spawn safely"""
	var safe_columns = []
	
	for x in range(GRID_WIDTH):
		# Check if top 3 rows are clear
		var is_safe = true
		for y in range(3):
			if is_occupied(x, y):
				is_safe = false
				break
		if is_safe:
			safe_columns.append(x)
	
	if safe_columns.size() > 0:
		return safe_columns[randi() % safe_columns.size()]
	
	# No safe columns, return random
	return randi() % GRID_WIDTH

func draw_grid_boundary():
	"""Draw visual border around puzzle area"""
	var border = Line2D.new()
	border.width = 3
	border.default_color = Color("#F39C12")  # Gold border
	border.z_index = 10  # On top of everything
	
	# Draw rectangle around grid
	var width = GRID_WIDTH * CELL_SIZE
	var height = GRID_HEIGHT * CELL_SIZE
	
	border.add_point(Vector2(0, 0))
	border.add_point(Vector2(width, 0))
	border.add_point(Vector2(width, height))
	border.add_point(Vector2(0, height))
	border.add_point(Vector2(0, 0))  # Close the loop
	
	add_child(border)
	
	# Optional: Draw grid lines for cells
	draw_grid_lines()

func draw_grid_lines():
	"""Draw faint grid lines for visual reference"""
	# Vertical lines
	for x in range(1, GRID_WIDTH):
		var line = Line2D.new()
		line.width = 1
		line.default_color = Color(1, 1, 1, 0.1)  # Was 0.1, now 0.15 (more visible)
		line.z_index = 5
		line.add_point(Vector2(x * CELL_SIZE, 0))
		line.add_point(Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE))
		add_child(line)
	
	# Horizontal lines
	for y in range(1, GRID_HEIGHT):
		var line = Line2D.new()
		line.width = 1
		line.default_color = Color(1, 1, 1, 0.1)  # Was 0.1, now 0.15
		line.z_index = 5
		line.add_point(Vector2(0, y * CELL_SIZE))
		line.add_point(Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE))
		add_child(line)
