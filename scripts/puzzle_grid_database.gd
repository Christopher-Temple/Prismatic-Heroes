extends Node

var layouts: Dictionary = {}
var layouts_by_difficulty: Dictionary = {
	1: [],
	2: [],
	3: [],
	4: [],
	5: []
}

func _ready():
	load_all_layouts()

func load_all_layouts():
	"""Load all puzzle layout resources"""
	var layout_paths = [
		"res://resources/puzzle_layouts/open_grid.tres",
		"res://resources/puzzle_layouts/pillars_left_right.tres",
		"res://resources/puzzle_layouts/center_pillar.tres",
		# Add more as you create them
	]
	
	for path in layout_paths:
		if ResourceLoader.exists(path):
			var layout: PuzzleGridLayout = load(path)
			if layout and layout.id != "":
				layouts[layout.id] = layout
				
				# Categorize by difficulty
				if layout.difficulty >= 1 and layout.difficulty <= 5:
					layouts_by_difficulty[layout.difficulty].append(layout.id)
		else:
			push_error("Layout not found: %s" % path)

func get_layout(layout_id: String) -> PuzzleGridLayout:
	"""Get layout by ID"""
	return layouts.get(layout_id)

func get_random_layout(difficulty: int = 1) -> PuzzleGridLayout:
	"""Get random layout appropriate for difficulty"""
	var available = []
	
	# Include layouts from current difficulty and below
	for diff in range(1, difficulty + 1):
		if layouts_by_difficulty.has(diff):
			available.append_array(layouts_by_difficulty[diff])
	
	if available.size() == 0:
		# Fallback to any layout
		return layouts.values()[0] if layouts.size() > 0 else null
	
	var random_id = available[randi() % available.size()]
	return layouts[random_id]
