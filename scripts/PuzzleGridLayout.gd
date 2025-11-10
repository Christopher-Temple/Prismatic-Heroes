extends Resource
class_name PuzzleGridLayout

@export var id: String = ""
@export var name: String = ""
@export var difficulty: int = 1  # 1-5, affects which floors it can appear
@export var walls: Array[Vector2i] = []  # Wall positions

# Optional: Pre-defined spawn zones for pieces
@export var safe_spawn_columns: Array[int] = []  # If empty, use all non-walled columns
