extends Resource
class_name EnemyData

# Identification
@export var id: String = ""  # Internal ID: "goblin", "orc", etc.
@export var enemy_name: String = ""  # Display name: "Goblin Warrior", "Orc Shaman", etc.
@export var enemy_type: String = ""  # Type: "Normal", "Elite", "Boss"

# Visual
@export var color: Color = Color.WHITE  # Enemy color for placeholder art
@export var sprite_path: String = ""  # Path to enemy sprite (for later)

# Stats
@export var base_health: int = 40  # Starting HP
@export var health_scaling: float = 1.2  # HP multiplier per floor (e.g., Floor 5 = base_health * 1.2^4)
@export var coin_reward: int = 5  # Coins given on defeat

# Combat Behavior
@export var attack_frequency: int = 5  # Attacks every X player moves
@export var attack_damage: int = 10  # Damage dealt per attack
@export_multiline var attack_description: String = ""  # What the attack does

# Special Abilities
@export var has_special_ability: bool = false
@export var special_ability_name: String = ""
@export_multiline var special_ability_description: String = ""
@export var special_ability_trigger: String = ""  # "on_spawn", "turn_5", "on_damaged", "on_death", etc.
@export var special_ability_data: Dictionary = {}  # Custom data for ability

# Obstacle Properties (if this enemy places obstacles)
@export var places_obstacles: bool = false
@export var obstacle_type: String = ""  # "slime", "ice", "poison", etc.
@export var obstacle_frequency: int = 0  # Places obstacle every X attacks
@export var obstacle_count: int = 1  # Number of obstacles placed

# Reinforcement (for hybrid wave system)
@export var can_summon: bool = false
@export var summon_enemy_id: String = ""  # ID of enemy to summon
@export var summon_delay: int = 0  # Turns before summoning
@export var summon_count: int = 1  # Number of enemies summoned

# Helper function to get scaled health based on floor
func get_health_for_floor(floor: int) -> int:
	if floor <= 1:
		return base_health
	# Floor 1 = base, Floor 2 = base * 1.2, Floor 3 = base * 1.44, etc.
	return int(base_health * pow(health_scaling, floor - 1))

# Helper function to check if enemy is a boss
func is_boss() -> bool:
	return enemy_type == "Boss"

# Helper function to check if enemy is elite
func is_elite() -> bool:
	return enemy_type == "Elite"
