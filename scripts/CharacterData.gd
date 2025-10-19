extends Resource
class_name CharacterData

# Identification
@export var id: String = ""  # Internal ID: "knight", "wizard", etc.
@export var character_name: String = ""  # Fantasy name: "Sir Gareth", "Mystara", etc.
@export var character_class: String = ""  # Class: "Knight", "Wizard", etc.
@export var class_type: String = ""  # Role: "Tank", "DPS", "Support", "Hybrid"

# Visual
@export var color: Color = Color.WHITE  # Matching block color for this character
@export var portrait_path: String = ""  # Path to character portrait (for later)

# Ability Info
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""

# Ability values at each tier
# Tier 1: Levels 1-3
# Tier 2: Levels 4-6  
# Tier 3: Levels 7-10
@export var ability_value_tier1: float = 0
@export var ability_value_tier2: float = 0
@export var ability_value_tier3: float = 0

# Additional ability properties (for abilities with multiple values)
@export var ability_secondary_tier1: float = 0  # For abilities like Druid's heal + damage
@export var ability_secondary_tier2: float = 0
@export var ability_secondary_tier3: float = 0

@export var ability_duration_tier1: int = 0  # For abilities with duration (Barkskin, Mesmerize, etc.)
@export var ability_duration_tier2: int = 0
@export var ability_duration_tier3: int = 0

# Unlock Info
@export var unlock_cost: int = 0  # Coins needed to unlock (0 = starter character)
@export var unlock_tier: int = 0  # 0=starter, 1=tier1, 2=tier2, 3=tier3
@export var is_starter: bool = false  # Quick check for starter characters

# Special Data (for unique abilities like Beastmaster's beast table)
@export var special_data: Dictionary = {}

# Helper function to get ability value based on character level
func get_ability_value(level: int) -> float:
	if level <= 3:
		return ability_value_tier1
	elif level <= 6:
		return ability_value_tier2
	else:
		return ability_value_tier3

func get_ability_secondary(level: int) -> float:
	if level <= 3:
		return ability_secondary_tier1
	elif level <= 6:
		return ability_secondary_tier2
	else:
		return ability_secondary_tier3

func get_ability_duration(level: int) -> int:
	if level <= 3:
		return ability_duration_tier1
	elif level <= 6:
		return ability_duration_tier2
	else:
		return ability_duration_tier3

func get_display_text() -> String:
	"""Returns formatted display text: 'Gareth (Knight)'"""
	return "%s (%s)" % [character_name, character_class]
