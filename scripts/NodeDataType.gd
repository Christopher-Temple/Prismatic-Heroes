extends Resource
class_name NodeTypeData

# Identification
@export var id: String = ""  # "battle", "shop", "rest", etc.
@export var display_name: String = ""
@export var icon_path: String = ""  # Path to node icon (for now we'll use symbols)
@export var color: Color = Color.WHITE

# Node behavior
@export_multiline var description: String = ""
@export var is_combat: bool = false
@export var is_mandatory: bool = false  # Must appear in every map?

# Spawn rules
@export var spawn_weight: int = 10  # Higher = more common
@export var min_floor: int = 1  # First floor this can appear
@export var max_per_map: int = 99  # Limit how many can spawn

# What happens when entered
@export var scene_path: String = ""  # Scene to load when entering this node
