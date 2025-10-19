# PieceFactory.gd
extends Node
class_name PieceFactory

# Player color pool (will be set based on party)
var player_colors: Array[String] = ["red", "blue", "yellow"]
var neutral_colors: Array[String] = ["gray", "brown", "white"]

# Tetris piece definitions (4-block pieces)
var tetris_shapes = {
	"I": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	"O": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"T": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	"L": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	"J": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],
	"S": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"Z": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
}

# 3-block pieces
var small_shapes = {
	"I3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	"L3": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"T3": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
}

# 5-block pieces
var large_shapes = {
	"I5": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
	"Plus": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
	"T5": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)]
}

func set_player_colors(party: Array):
	"""Set player colors based on party (slot-based colors)"""
	player_colors = ["red", "blue", "yellow"]  # Fixed slot colors

func generate_colors(num_blocks: int, num_neutral: int) -> Array:
	"""Generate color array for piece"""
	var colors = []
	
	# Add neutral colors
	for i in range(num_neutral):
		colors.append(neutral_colors[randi() % neutral_colors.size()])
	
	# Fill rest with player colors
	while colors.size() < num_blocks:
		colors.append(player_colors[randi() % player_colors.size()])
	
	# Shuffle
	colors.shuffle()
	
	return colors

func generate_neutral_piece() -> Dictionary:
	"""Generate piece with only neutral colors (for enemy drops)"""
	# Use small pieces for enemy drops
	var shape_keys = small_shapes.keys()
	var shape_key = shape_keys[randi() % shape_keys.size()]
	var shape = small_shapes[shape_key].duplicate()
	
	var colors = []
	for i in range(shape.size()):
		colors.append(neutral_colors[randi() % neutral_colors.size()])
	
	return {
		"shape": shape,
		"colors": colors
	}

# Add to PieceFactory.gd

var last_pieces: Array = []  # Track recent pieces to avoid repeats

func generate_piece() -> Dictionary:
	"""Generate a random piece with colors"""
	# Randomly choose size
	var rand = randf()
	var shape_dict
	var num_neutral = 1
	
	if rand < 0.6:
		# 60% chance: 4-block Tetris piece
		shape_dict = tetris_shapes
		num_neutral = 1
	elif rand < 0.85:
		# 25% chance: 3-block piece
		shape_dict = small_shapes
		num_neutral = 1
	else:
		# 15% chance: 5-block piece
		shape_dict = large_shapes
		num_neutral = 2
	
	# Pick random shape (avoid last 2 pieces)
	var shape_keys = shape_dict.keys()
	var available_keys = []
	for key in shape_keys:
		if key not in last_pieces:
			available_keys.append(key)
	
	# If all filtered out, use any
	if available_keys.size() == 0:
		available_keys = shape_keys
	
	var shape_key = available_keys[randi() % available_keys.size()]
	var shape = shape_dict[shape_key].duplicate()
	
	# Track this piece
	last_pieces.append(shape_key)
	if last_pieces.size() > 2:
		last_pieces.pop_front()
	
	# Generate colors
	var colors = generate_colors(shape.size(), num_neutral)
	
	return {
		"shape": shape,
		"colors": colors
	}
