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
const MATCH_HIGHLIGHT_COLOR = Color(1.5, 1.5, 1.5, 1.0)  # Bright white glow
const MATCH_ANIMATION_DURATION = 0.4

# Grid data structure
var grid: Array = []  # 2D array of BlockCells
var walls: Array = []  # Wall positions
var slimes: Array = []  # Active slime obstacles {x, y, trail: []}
var current_layout: PuzzleGridLayout = null

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
	await get_tree().process_frame
	setup_random_layout()
	draw_grid_boundary()
	
var puzzle_layouts = [
	{
		"name": "Empty Arena",
		"walls": []
	},
	{
		"name": "Center Pillar",
		"walls": [
			Vector2i(19, 10), Vector2i(20, 10), Vector2i(19, 11), Vector2i(20, 11),
			Vector2i(19, 12), Vector2i(20, 12)
		]
	},
	{
		"name": "Side Walls",
		"walls": [
			# Left wall
			Vector2i(5, 8), Vector2i(5, 9), Vector2i(5, 10), Vector2i(5, 11), Vector2i(5, 12), Vector2i(5, 13), Vector2i(5, 14),
			# Right wall
			Vector2i(34, 8), Vector2i(34, 9), Vector2i(34, 10), Vector2i(34, 11), Vector2i(34, 12), Vector2i(34, 13), Vector2i(34, 14)
		]
	},
	{
		"name": "Bottom Pillars",
		"walls": [
			# Left pillar
			Vector2i(10, 18), Vector2i(11, 18), Vector2i(10, 19), Vector2i(11, 19),
			# Right pillar
			Vector2i(28, 18), Vector2i(29, 18), Vector2i(28, 19), Vector2i(29, 19)
		]
	},
	{
		"name": "Scattered Blocks",
		"walls": [
			Vector2i(8, 10), Vector2i(15, 12), Vector2i(24, 9), Vector2i(31, 14),
			Vector2i(12, 17), Vector2i(27, 16), Vector2i(19, 13)
		]
	}
]

func setup_random_layout():
	"""Apply a random puzzle grid layout"""
	var layout = puzzle_layouts[randi() % puzzle_layouts.size()]
	print("Setting up puzzle layout: ", layout["name"])
	
	# Clear any existing walls
	for child in walls_container.get_children():
		child.queue_free()
	walls.clear()
	
	# Apply new layout
	for wall_pos in layout["walls"]:
		set_wall(wall_pos.x, wall_pos.y)

func setup_layout(layout: PuzzleGridLayout):
	"""Setup grid with a specific layout"""
	current_layout = layout
	
	initialize_grid()
	
	# Place walls from layout
	for wall_pos in layout.walls:
		set_wall(wall_pos.x, wall_pos.y)
	
	draw_grid_boundary()

# Add helper function
func get_safe_spawn_columns() -> Array:
	"""Get columns where a piece can spawn safely (top 5 rows clear)"""
	var safe_columns: Array[int] = []
	
	for x in range(GRID_WIDTH):
		var is_safe = true
		for y in range(5):  # Check top 5 rows
			if is_occupied(x, y):
				is_safe = false
				break
		if is_safe:
			safe_columns.append(x)
	
	return safe_columns

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
	if not is_valid_position(x, y):
		print("Warning: Attempted to set wall at invalid position: ", x, ", ", y)
		return
	
	if y >= grid.size():
		print("Warning: Grid not fully initialized. y=", y, " but grid.size()=", grid.size())
		return
	
	grid[y][x].is_wall = true
	walls.append(Vector2i(x, y))
	create_wall_sprite(x, y)
	print("Wall created at: ", x, ", ", y)  # ADD THIS DEBUG LINE

func create_wall_sprite(x: int, y: int):
	"""Create visual representation of wall"""
	var sprite = Sprite2D.new()
	sprite.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)
	# Use a bright, obvious color for debugging
	var texture = create_colored_texture(Color(1.0, 0.0, 0.0), CELL_SIZE)  # Bright red
	sprite.texture = texture
	sprite.z_index = 10  # Make sure it's on top
	walls_container.add_child(sprite)
	print("Wall sprite created at position: ", sprite.position)  # ADD THIS DEBUG LINE

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

func place_block(x: int, y: int, color: String):
	"""Place a block at grid position with the given color"""
	if not is_valid_position(x, y):
		return
	
	var cell = grid[y][x]
	
	# Remove existing block if any
	if cell.color_rect:
		cell.color_rect.queue_free()
		cell.color_rect = null
	
	# Create new colored block
	var block = ColorRect.new()
	
	match color:
		"red":
			block.color = Color("#E63946")
		"blue":
			block.color = Color("#457B9D")
		"yellow":
			block.color = Color("#F1C40F")
		"gray":
			block.color = Color("#808080")
		"brown":
			block.color = Color("#8B4513")
		"white":
			block.color = Color("#FFFFFF")
		"purple":
			block.color = Color("#9B59B6")  # Wild block - distinctive purple
			
			# Add sparkle effect to wild blocks
			var sparkle = Label.new()
			sparkle.text = "✨"
			sparkle.add_theme_font_size_override("font_size", 24)
			sparkle.position = Vector2(-2, -8)
			sparkle.z_index = 1
			block.add_child(sparkle)
			
			# Animate sparkle
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(sparkle, "modulate:a", 0.3, 0.5)
			tween.tween_property(sparkle, "modulate:a", 1.0, 0.5)
		_:
			block.color = Color.WHITE
	
	block.size = Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
	block.position = Vector2(x * CELL_SIZE + 1, y * CELL_SIZE + 1)
	
	add_child(block)
	cell.color_rect = block
	
	

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
	"""Get the color of a block at position"""
	if not is_valid_position(x, y):
		return ""
	
	if grid[y][x].color_rect:
		# Map the actual Color to our string colors
		var color = grid[y][x].color_rect.color
		
		# Check for exact matches first
		if color == Color("#E63946"):
			return "red"
		elif color == Color("#457B9D"):
			return "blue"
		elif color == Color("#F1C40F"):
			return "yellow"
		elif color == Color("#808080"):
			return "gray"
		elif color == Color("#8B4513"):
			return "brown"
		elif color == Color("#FFFFFF"):
			return "white"
		elif color == Color("#9B59B6") or color.is_equal_approx(Color("#9B59B6")):
			return "purple"  # Wild block color
		
		# If no exact match, try to match by proximity
		var colors = {
			"red": Color("#E63946"),
			"blue": Color("#457B9D"),
			"yellow": Color("#F1C40F"),
			"gray": Color("#808080"),
			"brown": Color("#8B4513"),
			"white": Color("#FFFFFF"),
			"purple": Color("#9B59B6")
		}
		
		var closest = ""
		var closest_distance = 999.0
		
		for color_name in colors:
			var dist = color.distance_to(colors[color_name])
			if dist < closest_distance:
				closest_distance = dist
				closest = color_name
		
		return closest
	
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
		
		# Check if slime can move down
		var can_move_down = true
		var next_y = y + 1
		
		# Check if reached bottom or hit an obstacle/block
		if next_y >= GRID_HEIGHT or is_occupied(x, next_y):
			can_move_down = false
		
		if can_move_down:
			# Move slime down one row
			# Mark current position as trail
			grid[y][x].is_slimed = true
			slime_data["trail"].append(Vector2i(x, y))
			update_block_slime_visual(x, y)
			
			# Remove slime head from current position
			remove_slime_head(x, y)
			
			# Move slime to next position
			slime_data["y"] = next_y
			grid[next_y][x].is_obstacle = true
			grid[next_y][x].obstacle_type = "slime"
			create_slime_sprite(x, next_y)
		else:
			# Slime has reached bottom or hit something - dissolve column
			# Mark current position as trail first
			grid[y][x].is_slimed = true
			slime_data["trail"].append(Vector2i(x, y))
			
			dissolve_column(x)
			slimes_to_remove.append(i)
	
	# Remove completed slimes (iterate backwards to avoid index issues)
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
	"""Find all matching groups of 3+ blocks"""
	var matches = []
	var checked = {}  # Track which cells we've already included in matches
	
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var color = get_block_color(x, y)
			
			# Skip empty, obstacles, and already-checked cells
			if color == "" or grid[y][x].is_obstacle:
				continue
			
			var cell_key = Vector2i(x, y)
			if checked.has(cell_key):
				continue
			
			# Check horizontal match
			var h_match = find_horizontal_match(x, y, color)
			if h_match.size() >= 3:
				# Mark as matched color (use first non-wild color found)
				var actual_color = get_actual_color_from_match(h_match)
				matches.append({
					"color": actual_color,
					"positions": h_match
				})
				for pos in h_match:
					checked[pos] = true
			
			# Check vertical match (only if not already in horizontal match)
			if not checked.has(cell_key):
				var v_match = find_vertical_match(x, y, color)
				if v_match.size() >= 3:
					var actual_color = get_actual_color_from_match(v_match)
					matches.append({
						"color": actual_color,
						"positions": v_match
					})
					for pos in v_match:
						checked[pos] = true
	
	return matches

func find_horizontal_match(start_x: int, start_y: int, start_color: String) -> Array:
	"""Find horizontal matching blocks including wilds"""
	var match_positions = [Vector2i(start_x, start_y)]
	var actual_color = start_color if start_color != "purple" else ""
	
	# Check right
	var x = start_x + 1
	while x < GRID_WIDTH:
		var color = get_block_color(x, start_y)
		
		if color == "":
			break
		
		if grid[start_y][x].is_obstacle:
			break
		
		# Purple (wild) matches anything
		if color == "purple":
			match_positions.append(Vector2i(x, start_y))
			x += 1
			continue
		
		# If we haven't determined actual color yet, use this
		if actual_color == "":
			actual_color = color
		
		# Check if colors match
		if colors_match(color, actual_color):
			match_positions.append(Vector2i(x, start_y))
			x += 1
		else:
			break
	
	# Check left
	x = start_x - 1
	while x >= 0:
		var color = get_block_color(x, start_y)
		
		if color == "":
			break
		
		if grid[start_y][x].is_obstacle:
			break
		
		# Purple (wild) matches anything
		if color == "purple":
			match_positions.append(Vector2i(x, start_y))
			x -= 1
			continue
		
		# If we haven't determined actual color yet, use this
		if actual_color == "":
			actual_color = color
		
		# Check if colors match
		if colors_match(color, actual_color):
			match_positions.append(Vector2i(x, start_y))
			x -= 1
		else:
			break
	
	return match_positions

func find_vertical_match(start_x: int, start_y: int, start_color: String) -> Array:
	"""Find vertical matching blocks including wilds"""
	var match_positions = [Vector2i(start_x, start_y)]
	var actual_color = start_color if start_color != "purple" else ""
	
	# Check down
	var y = start_y + 1
	while y < GRID_HEIGHT:
		var color = get_block_color(start_x, y)
		
		if color == "":
			break
		
		if grid[y][start_x].is_obstacle:
			break
		
		# Purple (wild) matches anything
		if color == "purple":
			match_positions.append(Vector2i(start_x, y))
			y += 1
			continue
		
		# If we haven't determined actual color yet, use this
		if actual_color == "":
			actual_color = color
		
		# Check if colors match
		if colors_match(color, actual_color):
			match_positions.append(Vector2i(start_x, y))
			y += 1
		else:
			break
	
	# Check up
	y = start_y - 1
	while y >= 0:
		var color = get_block_color(start_x, y)
		
		if color == "":
			break
		
		if grid[y][start_x].is_obstacle:
			break
		
		# Purple (wild) matches anything
		if color == "purple":
			match_positions.append(Vector2i(start_x, y))
			y -= 1
			continue
		
		# If we haven't determined actual color yet, use this
		if actual_color == "":
			actual_color = color
		
		# Check if colors match
		if colors_match(color, actual_color):
			match_positions.append(Vector2i(start_x, y))
			y -= 1
		else:
			break
	
	return match_positions

func colors_match(color1: String, color2: String) -> bool:
	"""Check if two colors match (treating purple as wild)"""
	if color1 == "purple" or color2 == "purple":
		return true
	return color1 == color2

func get_actual_color_from_match(positions: Array) -> String:
	"""Get the actual color from a match (first non-wild color)"""
	for pos in positions:
		var color = get_block_color(pos.x, pos.y)
		if color != "purple" and color != "":
			return color
	
	# If all blocks are wild (purple), default to purple
	return "purple"

func clear_matches(matches: Array):
	"""Remove matched blocks and any webs they're in"""
	for match_data in matches:
		var color = match_data["color"]
		var block_color = get_color_from_name(color)
		
		for pos in match_data["positions"]:
			# Create explosion particle effect
			create_explosion_particles(pos.x, pos.y, block_color)
			
			# Remove web if block was stuck in one
			if block_touches_web(pos.x, pos.y):
				remove_web(pos.x, pos.y)
			remove_block(pos.x, pos.y)

func get_color_from_name(color_name: String) -> Color:
	"""Convert color name to Color for particles"""
	var color_map = {
		"red": Color("#E63946"),
		"blue": Color("#457B9D"),
		"yellow": Color("#F1C40F"),
		"gray": Color("#95A5A6"),
		"brown": Color("#8B4513"),
		"white": Color("#ECF0F1")
	}
	return color_map.get(color_name, Color.WHITE)

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

func create_explosion_particles(x: int, y: int, color: Color):
	"""Create particle effect when blocks are cleared"""
	var particles = CPUParticles2D.new()
	particles.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 8
	particles.lifetime = 0.6
	particles.spread = 180
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.gravity = Vector2(0, 100)
	particles.color = color
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	
	blocks_container.add_child(particles)
	
	# Remove particles after animation
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()
	
func animate_matched_blocks(matches: Array):
	"""Animate blocks before clearing them - glow and shake effect"""
	var all_matched_positions = []
	
	# Collect all matched positions
	for match_data in matches:
		for pos in match_data["positions"]:
			all_matched_positions.append(pos)
	
	# Create animation tweens for each matched block
	var tweens = []
	for pos in all_matched_positions:
		if is_valid_position(pos.x, pos.y):
			var cell = grid[pos.y][pos.x]
			if cell.sprite:
				# Create glow effect
				var tween = create_tween()
				tween.set_parallel(true)
				
				# Pulse/glow effect
				tween.tween_property(cell.sprite, "modulate", MATCH_HIGHLIGHT_COLOR, MATCH_ANIMATION_DURATION / 2)
				tween.tween_property(cell.sprite, "modulate", Color.WHITE, MATCH_ANIMATION_DURATION / 2).set_delay(MATCH_ANIMATION_DURATION / 2)
				
				# Shake effect - random small movements
				var original_pos = cell.sprite.position
				for i in range(4):
					var shake_offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
					tween.tween_property(cell.sprite, "position", original_pos + shake_offset, 0.05).set_delay(i * 0.05)
				
				# Return to original position
				tween.tween_property(cell.sprite, "position", original_pos, 0.05).set_delay(0.2)
				
				# Scale pulse (pop effect)
				tween.tween_property(cell.sprite, "scale", Vector2(1.2, 1.2), MATCH_ANIMATION_DURATION / 2)
				tween.tween_property(cell.sprite, "scale", Vector2(1.0, 1.0), MATCH_ANIMATION_DURATION / 2).set_delay(MATCH_ANIMATION_DURATION / 2)
				
				tweens.append(tween)
	
	# Wait for all animations to complete
	if tweens.size() > 0:
		await tweens[0].finished

	
func apply_gravity_animated() -> bool:
	"""Make blocks fall down with smooth animation. Returns true if any blocks moved."""
	var blocks_moved = false
	var animations = []
	
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
					
					# Animate the sprite falling
					if sprite:
						var tween = create_tween()
						tween.set_ease(Tween.EASE_IN)
						tween.set_trans(Tween.TRANS_BOUNCE)
						var target_y = (y + fall_distance) * CELL_SIZE + CELL_SIZE/2
						tween.tween_property(sprite, "position:y", target_y, 0.3)
						animations.append(tween)
					
					blocks_moved = true
	
	# Wait for all animations to complete
	if animations.size() > 0:
		await animations[0].finished
	
	return blocks_moved
