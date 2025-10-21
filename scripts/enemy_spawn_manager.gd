# enemy_spawn_manager.gd
extends Node
class_name EnemySpawnManager

## Manages enemy spawning for normal and elite battles

# Enemy types available (ONLY enemies you have resources for)
enum EnemyType {
	# Normal Enemies
	GOBLIN,
	ORC,
	SKELETON,
	SLIME,
	SPIDER,
	# Elite Enemies
	GOBLIN_CHIEF,
	ORC_SHAMAN,
	GOLEM,
	# Boss Enemies (for reference, not used in patterns)
	DRAGON_BOSS,
	LICH_BOSS,
	DEMON_BOSS
}

# Spawn pattern definition
class SpawnPattern:
	var initial_enemies: Array = []  # Enemies that start on field
	var reinforcements: Array = []   # Queue of enemies to spawn
	var turn_delays: Array = []      # Which turn each reinforcement spawns
	var difficulty: int = 1          # 1-5 difficulty rating
	var name: String = ""

# Normal battle spawn patterns
var normal_patterns: Array[SpawnPattern] = []

# Elite battle spawn patterns  
var elite_patterns: Array[SpawnPattern] = []

func _ready():
	initialize_normal_patterns()
	initialize_elite_patterns()

# ========== NORMAL BATTLE PATTERNS ==========
# Normal battles: Mostly normal enemies, occasionally 1 elite

func initialize_normal_patterns():
	"""Create diverse normal battle spawn patterns"""
	
	# Pattern 1: Single Goblin - Easiest
	var pattern1 = SpawnPattern.new()
	pattern1.name = "Lone Goblin"
	pattern1.initial_enemies = [EnemyType.GOBLIN]
	pattern1.reinforcements = []
	pattern1.difficulty = 1
	normal_patterns.append(pattern1)
	
	# Pattern 2: Skeleton Sniper
	var pattern2 = SpawnPattern.new()
	pattern2.name = "Skeleton Ambush"
	pattern2.initial_enemies = [EnemyType.SKELETON]
	pattern2.reinforcements = []
	pattern2.difficulty = 1
	normal_patterns.append(pattern2)
	
	# Pattern 3: Two Goblins
	var pattern3 = SpawnPattern.new()
	pattern3.name = "Goblin Duo"
	pattern3.initial_enemies = [EnemyType.GOBLIN]
	pattern3.reinforcements = [EnemyType.GOBLIN]
	pattern3.turn_delays = [3]
	pattern3.difficulty = 1
	normal_patterns.append(pattern3)
	
	# Pattern 4: Spider Nest
	var pattern4 = SpawnPattern.new()
	pattern4.name = "Spider Nest"
	pattern4.initial_enemies = [EnemyType.SPIDER, EnemyType.SPIDER]
	pattern4.reinforcements = [EnemyType.SPIDER]
	pattern4.turn_delays = [4]
	pattern4.difficulty = 2
	normal_patterns.append(pattern4)
	
	# Pattern 5: Lone Orc - Tough single enemy
	var pattern5 = SpawnPattern.new()
	pattern5.name = "Orc Patrol"
	pattern5.initial_enemies = [EnemyType.ORC]
	pattern5.reinforcements = []
	pattern5.difficulty = 2
	normal_patterns.append(pattern5)
	
	# Pattern 6: Slime Surprise
	var pattern6 = SpawnPattern.new()
	pattern6.name = "Slime Den"
	pattern6.initial_enemies = [EnemyType.SLIME]
	pattern6.reinforcements = [EnemyType.SLIME]
	pattern6.turn_delays = [3]
	pattern6.difficulty = 2
	normal_patterns.append(pattern6)
	
	# Pattern 7: Mixed Threat
	var pattern7 = SpawnPattern.new()
	pattern7.name = "Raiding Party"
	pattern7.initial_enemies = [EnemyType.GOBLIN, EnemyType.SKELETON]
	pattern7.reinforcements = [EnemyType.GOBLIN]
	pattern7.turn_delays = [4]
	pattern7.difficulty = 2
	normal_patterns.append(pattern7)
	
	# Pattern 8: Undead Assault
	var pattern8 = SpawnPattern.new()
	pattern8.name = "Skeleton Squad"
	pattern8.initial_enemies = [EnemyType.SKELETON]
	pattern8.reinforcements = [EnemyType.SKELETON, EnemyType.SKELETON]
	pattern8.turn_delays = [2, 5]
	pattern8.difficulty = 3
	normal_patterns.append(pattern8)
	
	# Pattern 9: Orc + Goblins
	var pattern9 = SpawnPattern.new()
	pattern9.name = "Orc War Party"
	pattern9.initial_enemies = [EnemyType.ORC]
	pattern9.reinforcements = [EnemyType.GOBLIN, EnemyType.GOBLIN]
	pattern9.turn_delays = [3, 5]
	pattern9.difficulty = 3
	normal_patterns.append(pattern9)
	
	# Pattern 10: Spider + Slime combo
	var pattern10 = SpawnPattern.new()
	pattern10.name = "Cave Dwellers"
	pattern10.initial_enemies = [EnemyType.SPIDER, EnemyType.SLIME]
	pattern10.reinforcements = [EnemyType.SPIDER]
	pattern10.turn_delays = [5]
	pattern10.difficulty = 3
	normal_patterns.append(pattern10)
	
	# Pattern 11: Triple start
	var pattern11 = SpawnPattern.new()
	pattern11.name = "Goblin Ambush"
	pattern11.initial_enemies = [EnemyType.GOBLIN, EnemyType.GOBLIN, EnemyType.GOBLIN]
	pattern11.reinforcements = []
	pattern11.difficulty = 3
	normal_patterns.append(pattern11)
	
	# Pattern 12: Elite appears! - Goblin Chief
	var pattern12 = SpawnPattern.new()
	pattern12.name = "Goblin Chief's Band"
	pattern12.initial_enemies = [EnemyType.GOBLIN]
	pattern12.reinforcements = [EnemyType.GOBLIN_CHIEF, EnemyType.GOBLIN]
	pattern12.turn_delays = [3, 5]
	pattern12.difficulty = 4
	normal_patterns.append(pattern12)
	
	# Pattern 13: Sustained assault
	var pattern13 = SpawnPattern.new()
	pattern13.name = "Endless Horde"
	pattern13.initial_enemies = [EnemyType.SKELETON]
	pattern13.reinforcements = [EnemyType.SKELETON, EnemyType.GOBLIN, EnemyType.SKELETON, EnemyType.GOBLIN]
	pattern13.turn_delays = [2, 4, 6, 8]
	pattern13.difficulty = 4
	normal_patterns.append(pattern13)
	
	# Pattern 14: Heavy hitters
	var pattern14 = SpawnPattern.new()
	pattern14.name = "Orc Brothers"
	pattern14.initial_enemies = [EnemyType.ORC, EnemyType.ORC]
	pattern14.reinforcements = [EnemyType.GOBLIN]
	pattern14.turn_delays = [4]
	pattern14.difficulty = 4
	normal_patterns.append(pattern14)
	
	# Pattern 15: Elite + minions
	var pattern15 = SpawnPattern.new()
	pattern15.name = "Shaman's Curse"
	pattern15.initial_enemies = [EnemyType.GOBLIN]
	pattern15.reinforcements = [EnemyType.ORC_SHAMAN, EnemyType.ORC, EnemyType.GOBLIN]
	pattern15.turn_delays = [2, 4, 6]
	pattern15.difficulty = 5
	normal_patterns.append(pattern15)
	
	# Pattern 16: Maximum pressure
	var pattern16 = SpawnPattern.new()
	pattern16.name = "All-Out Assault"
	pattern16.initial_enemies = [EnemyType.ORC, EnemyType.SPIDER]
	pattern16.reinforcements = [EnemyType.SKELETON, EnemyType.GOBLIN, EnemyType.SLIME, EnemyType.SPIDER]
	pattern16.turn_delays = [2, 4, 6, 8]
	pattern16.difficulty = 5
	normal_patterns.append(pattern16)

# ========== ELITE BATTLE PATTERNS ==========
# Elite battles: 3-4 elite enemies with normal enemy support

func initialize_elite_patterns():
	"""Create challenging elite battle patterns"""
	
	# Elite 1: Goblin Chief with troops
	var elite1 = SpawnPattern.new()
	elite1.name = "Goblin Warband"
	elite1.initial_enemies = [EnemyType.GOBLIN_CHIEF, EnemyType.GOBLIN]
	elite1.reinforcements = [EnemyType.GOBLIN_CHIEF, EnemyType.GOBLIN, EnemyType.GOBLIN]
	elite1.turn_delays = [3, 5, 7]
	elite1.difficulty = 4
	elite_patterns.append(elite1)
	
	# Elite 2: Orc Shaman ritual
	var elite2 = SpawnPattern.new()
	elite2.name = "Dark Ritual"
	elite2.initial_enemies = [EnemyType.ORC_SHAMAN]
	elite2.reinforcements = [EnemyType.ORC_SHAMAN, EnemyType.ORC, EnemyType.ORC, EnemyType.SKELETON]
	elite2.turn_delays = [2, 4, 6, 8]
	elite2.difficulty = 5
	elite_patterns.append(elite2)
	
	# Elite 3: Stone Golem fortress
	var elite3 = SpawnPattern.new()
	elite3.name = "Golem Guardian"
	elite3.initial_enemies = [EnemyType.GOLEM]
	elite3.reinforcements = [EnemyType.GOLEM, EnemyType.ORC_SHAMAN, EnemyType.ORC]
	elite3.turn_delays = [4, 6, 8]
	elite3.difficulty = 5
	elite_patterns.append(elite3)
	
	# Elite 4: Triple elite start
	var elite4 = SpawnPattern.new()
	elite4.name = "Elite Strike Force"
	elite4.initial_enemies = [EnemyType.GOBLIN_CHIEF, EnemyType.ORC_SHAMAN, EnemyType.GOLEM]
	elite4.reinforcements = [EnemyType.ORC, EnemyType.GOBLIN]
	elite4.turn_delays = [5, 7]
	elite4.difficulty = 5
	elite_patterns.append(elite4)
	
	# Elite 5: Dual Golem defense
	var elite5 = SpawnPattern.new()
	elite5.name = "Golem Twins"
	elite5.initial_enemies = [EnemyType.GOLEM, EnemyType.GOLEM]
	elite5.reinforcements = [EnemyType.ORC_SHAMAN, EnemyType.GOBLIN_CHIEF]
	elite5.turn_delays = [4, 7]
	elite5.difficulty = 5
	elite_patterns.append(elite5)
	
	# Elite 6: Shaman army
	var elite6 = SpawnPattern.new()
	elite6.name = "Coven of Shamans"
	elite6.initial_enemies = [EnemyType.ORC_SHAMAN, EnemyType.ORC_SHAMAN]
	elite6.reinforcements = [EnemyType.GOBLIN_CHIEF, EnemyType.ORC, EnemyType.ORC]
	elite6.turn_delays = [3, 5, 7]
	elite6.difficulty = 5
	elite_patterns.append(elite6)
	
	# Elite 7: Maximum elite count
	var elite7 = SpawnPattern.new()
	elite7.name = "Champion's Arena"
	elite7.initial_enemies = [EnemyType.GOLEM, EnemyType.GOBLIN_CHIEF]
	elite7.reinforcements = [EnemyType.ORC_SHAMAN, EnemyType.GOBLIN_CHIEF, EnemyType.GOLEM]
	elite7.turn_delays = [3, 5, 8]
	elite7.difficulty = 5
	elite_patterns.append(elite7)

# ========== SPAWN LOGIC ==========

func get_random_normal_pattern(difficulty_level: int = 1) -> SpawnPattern:
	"""Get a random normal battle pattern appropriate for difficulty"""
	var valid_patterns = []
	
	# Filter patterns within difficulty range
	for pattern in normal_patterns:
		if pattern.difficulty <= difficulty_level + 1 and pattern.difficulty >= max(1, difficulty_level - 1):
			valid_patterns.append(pattern)
	
	if valid_patterns.is_empty():
		return normal_patterns[0]  # Fallback to easiest
	
	return valid_patterns[randi() % valid_patterns.size()]

func get_random_elite_pattern() -> SpawnPattern:
	"""Get a random elite battle pattern"""
	return elite_patterns[randi() % elite_patterns.size()]

func get_initial_enemy_count(pattern: SpawnPattern) -> int:
	"""Determine how many enemies spawn initially (1-3 weighted)"""
	var max_initial = min(pattern.initial_enemies.size(), 3)
	
	if max_initial == 1:
		return 1
	
	var roll = randf()
	
	if max_initial >= 3:
		if roll < 0.50:  # 50% chance for 1 enemy
			return 1
		elif roll < 0.90:  # 40% chance for 2 enemies
			return 2
		else:  # 10% chance for 3 enemies
			return 3
	
	elif max_initial >= 2:
		if roll < 0.60:  # 60% chance for 1 enemy
			return 1
		else:  # 40% chance for 2 enemies
			return 2
	
	return 1

func create_enemy_instance(enemy_type: EnemyType, floor: int = 1) -> Dictionary:
	"""Create an enemy instance with stats scaled for current floor"""
	var enemy_id = get_enemy_id_from_type(enemy_type)
	var enemy_data = EnemyDatabase.get_enemy(enemy_id)
	
	if not enemy_data:
		push_error("Failed to create enemy: " + str(enemy_type))
		return {}
	
	return {
		"id": enemy_id,
		"type": enemy_type,
		"data": enemy_data,
		"current_hp": enemy_data.get_health_for_floor(floor),
		"max_hp": enemy_data.get_health_for_floor(floor),
		"attack_cooldown": enemy_data.attack_frequency,
		"current_cooldown": enemy_data.attack_frequency
	}

func get_enemy_id_from_type(enemy_type: EnemyType) -> String:
	"""Convert EnemyType enum to database ID string"""
	match enemy_type:
		EnemyType.GOBLIN: return "goblin"
		EnemyType.ORC: return "orc"
		EnemyType.SKELETON: return "skeleton"
		EnemyType.SLIME: return "slime"
		EnemyType.SPIDER: return "spider"
		EnemyType.GOBLIN_CHIEF: return "goblin_chief"
		EnemyType.ORC_SHAMAN: return "orc_shaman"
		EnemyType.GOLEM: return "golem"
		EnemyType.DRAGON_BOSS: return "dragon_boss"
		EnemyType.LICH_BOSS: return "lich_boss"
		EnemyType.DEMON_BOSS: return "demon_boss"
	return "goblin"  # Fallback

func setup_battle(is_elite: bool = false, difficulty_level: int = 1) -> Dictionary:
	"""
	Setup a battle and return all necessary spawn data
	Returns: {
		"initial_enemies": [EnemyType, ...],
		"spawn_queue": [{"enemy": EnemyType, "turn": int}, ...],
		"pattern_name": String
	}
	"""
	var pattern: SpawnPattern
	
	if is_elite:
		pattern = get_random_elite_pattern()
	else:
		pattern = get_random_normal_pattern(difficulty_level)
	
	var initial_count = get_initial_enemy_count(pattern)
	var initial_enemies = pattern.initial_enemies.slice(0, initial_count)
	
	# Build spawn queue for reinforcements
	var spawn_queue = []
	for i in range(pattern.reinforcements.size()):
		spawn_queue.append({
			"enemy": pattern.reinforcements[i],
			"turn": pattern.turn_delays[i] if i < pattern.turn_delays.size() else 999
		})
	
	return {
		"initial_enemies": initial_enemies,
		"spawn_queue": spawn_queue,
		"pattern_name": pattern.name,
		"difficulty": pattern.difficulty
	}

# ========== HELPER FUNCTIONS ==========

func get_enemy_name(enemy_type: EnemyType) -> String:
	"""Get display name for enemy type"""
	match enemy_type:
		EnemyType.GOBLIN: return "Goblin Warrior"
		EnemyType.ORC: return "Orc Bruiser"
		EnemyType.SKELETON: return "Skeleton Archer"
		EnemyType.SLIME: return "Toxic Slime"
		EnemyType.SPIDER: return "Giant Spider"
		EnemyType.GOBLIN_CHIEF: return "Goblin Chief"
		EnemyType.ORC_SHAMAN: return "Orc Shaman"
		EnemyType.GOLEM: return "Stone Golem"
		EnemyType.DRAGON_BOSS: return "Ancient Red Dragon"
		EnemyType.LICH_BOSS: return "Archlich Malachar"
		EnemyType.DEMON_BOSS: return "Infernal Tyrant"
	return "Unknown"
