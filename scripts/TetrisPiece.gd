# TetrisPiece.gd
extends Node2D
class_name TetrisPiece

signal piece_placed(blocks: Array)
signal piece_locked()

const CELL_SIZE = 20

var shape: Array = []
var colors: Array = []
var grid_position: Vector2i = Vector2i(5, 0)
var is_falling: bool = false
var can_move: bool = true

# Store reference to puzzle grid
var puzzle_grid: PuzzleGrid = null

# Visual sprites
var block_sprites: Array = []

# Movement
var fall_timer: float = 0.0
var fall_delay: float = 1.0
var initial_delay: float = 2.0
var initial_timer: float = 0.0
var has_started_falling: bool = false
var ghost_sprites: Array = []

func _ready():
	# Get puzzle grid reference (parent should be PuzzleGrid)
	if get_parent() is PuzzleGrid:
		puzzle_grid = get_parent()
	else:
		push_error("TetrisPiece must be child of PuzzleGrid!")
	
	create_sprites()
	#create_ghost_sprites()

func _process(delta):
	if not can_move or puzzle_grid == null:
		return
	
	# Handle initial 2-second delay
	if not has_started_falling:
		initial_timer += delta
		if initial_timer >= initial_delay:
			has_started_falling = true
			is_falling = true
	
	# Auto-fall
	if is_falling and has_started_falling:
		fall_timer += delta
		if fall_timer >= fall_delay:
			fall_timer = 0.0
			move_down()

func create_ghost_sprites():
	"""Create ghost/shadow showing where piece will land"""
	for i in range(shape.size()):
		var sprite = Sprite2D.new()
		sprite.texture = create_colored_texture(Color(1, 1, 1, 0.3), CELL_SIZE - 2)  # White, transparent
		sprite.modulate = Color(1, 1, 1, 0.3)
		ghost_sprites.append(sprite)
		add_child(sprite)
	#update_ghost_position()

func update_ghost_position():
	"""Update ghost piece to show landing position"""
	if puzzle_grid == null:
		return
	
	# Find where piece would land if hard dropped
	var ghost_y = grid_position.y
	while can_place_at(Vector2i(grid_position.x, ghost_y + 1)):
		ghost_y += 1
	
	# Position ghost sprites
	for i in range(shape.size()):
		var offset = shape[i]
		ghost_sprites[i].position = Vector2(
			(grid_position.x + offset.x) * CELL_SIZE + CELL_SIZE / 2,
			(ghost_y + offset.y) * CELL_SIZE + CELL_SIZE / 2
		)

func setup_piece(piece_shape: Array, piece_colors: Array, start_x: int):
	"""Initialize piece with shape and colors"""
	shape = piece_shape.duplicate()
	colors = piece_colors.duplicate()
	grid_position = Vector2i(start_x, 0)
	update_visual_position()

func create_sprites():
	"""Create visual representation of piece"""
	for i in range(shape.size()):
		var sprite = Sprite2D.new()
		sprite.texture = create_colored_texture(get_color_from_name(colors[i]), CELL_SIZE - 4)
		block_sprites.append(sprite)
		add_child(sprite)
	update_sprite_positions()

func create_colored_texture(color: Color, size: int) -> ImageTexture:
	"""Create colored square texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func get_color_from_name(color_name: String) -> Color:
	"""Convert color name to Color"""
	var color_map = {
		"red": Color("#E63946"),
		"blue": Color("#457B9D"),
		"yellow": Color("#F1C40F"),
		"gray": Color("#95A5A6"),
		"brown": Color("#8B4513"),
		"white": Color("#ECF0F1")
	}
	return color_map.get(color_name, Color.WHITE)

func update_visual_position():
	"""Update piece position on screen"""
	# Position should snap exactly to grid cells
	position = Vector2(
		grid_position.x * CELL_SIZE,
		grid_position.y * CELL_SIZE
	)
	#update_ghost_position() 

func lock_piece():
	"""Lock piece into grid"""
	if puzzle_grid == null:
		return
	
	can_move = false
	is_falling = false
	
	var blocks_to_place = []
	
	for i in range(shape.size()):
		var offset = shape[i]
		var block_pos = grid_position + offset
		
		if puzzle_grid.block_touches_web(block_pos.x, block_pos.y):
			puzzle_grid.place_block(block_pos.x, block_pos.y, colors[i])
			blocks_to_place.append({"pos": block_pos, "color": colors[i], "stuck": true})
		else:
			puzzle_grid.place_block(block_pos.x, block_pos.y, colors[i])
			blocks_to_place.append({"pos": block_pos, "color": colors[i], "stuck": false})
	
	piece_placed.emit(blocks_to_place)
	piece_locked.emit()
	
	# Remove all sprites
	#for sprite in block_sprites:
		#sprite.queue_free()
	#block_sprites.clear()
	#
	#for sprite in ghost_sprites:
		#sprite.queue_free()
	#ghost_sprites.clear()

func update_sprite_positions():
	"""Update sprite positions based on shape"""
	for i in range(shape.size()):
		var offset = shape[i]
		# Each sprite should be centered in its cell
		block_sprites[i].position = Vector2(
			offset.x * CELL_SIZE + CELL_SIZE / 2,
			offset.y * CELL_SIZE + CELL_SIZE / 2
		)

func move_left() -> bool:
	"""Try to move piece left"""
	if not can_move or puzzle_grid == null:
		return false
	
	var new_pos = grid_position + Vector2i(-1, 0)
	if can_place_at(new_pos):
		grid_position = new_pos
		update_visual_position()
		return true
	return false

func move_right() -> bool:
	"""Try to move piece right"""
	if not can_move or puzzle_grid == null:
		return false
	
	var new_pos = grid_position + Vector2i(1, 0)
	if can_place_at(new_pos):
		grid_position = new_pos
		update_visual_position()
		return true
	return false

func move_down() -> bool:
	"""Try to move piece down"""
	if not can_move or puzzle_grid == null:
		return false
	
	var new_pos = grid_position + Vector2i(0, 1)
	
	if can_place_at(new_pos):
		grid_position = new_pos
		update_visual_position()
		return true
	else:
		# Can't move down - lock piece
		lock_piece()
		return false

func hard_drop():
	"""Instantly drop piece to bottom"""
	if puzzle_grid == null:
		return
	
	has_started_falling = true
	is_falling = false
	can_move = false
	
	while can_place_at(grid_position + Vector2i(0, 1)):
		grid_position.y += 1
	
	update_visual_position()
	lock_piece()

func rotate_clockwise() -> bool:
	"""Rotate piece 90 degrees clockwise"""
	if not can_move or puzzle_grid == null:
		return false
	
	var rotated_shape = []
	for offset in shape:
		var new_offset = Vector2i(-offset.y, offset.x)
		rotated_shape.append(new_offset)
	
	var old_shape = shape.duplicate()
	shape = rotated_shape
	
	if can_place_at(grid_position):
		update_sprite_positions()
		return true
	else:
		shape = old_shape
		return false

func can_place_at(pos: Vector2i) -> bool:
	"""Check if piece can be placed at position"""
	if puzzle_grid == null:
		return false
	
	for offset in shape:
		var check_pos = pos + offset
		if not puzzle_grid.is_valid_position(check_pos.x, check_pos.y):
			return false
		if puzzle_grid.is_occupied(check_pos.x, check_pos.y):
			return false
	return true
