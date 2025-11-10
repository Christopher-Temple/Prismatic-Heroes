# enemy_spawn_manager.gd
extends Node
class_name EnemySpawnManager

## Manages enemy spawning for normal and elite battles

# Enemy types available (ALL ENEMIES)
enum EnemyType {
	# Normal Enemies - Original
	GOBLIN,
	GOBLIN_ARCHER,
	GOBLIN_MAGE,
	ORC,
	SKELETON,
	SKELETON_WARRIOR,
	SLIME,
	SPIDER,
	MUMMY,
	
	# Normal Enemies - New
	GIANT_RAT,
	FIRE_IMP,
	ICE_ELEMENTAL,
	DARK_CULTIST,
	SHADOW_ASSASSIN,
	WRAITH,
	GARGOYLE,
	HARPY,
	MIMIC,
	UNDEAD_WARRIOR,
	CORRUPTED_TREANT,
	BANDIT,
	
	# Elite Enemies - Original
	GOBLIN_CHIEF,
	ORC_SHAMAN,
	GOLEM,
	LYCANTHROPE,
	WEREWOLF,
	TROLL,
	
	# Elite Enemies - New
	DARK_SORCERER,
	FROST_GIANT,
	NECROMANCER_ELITE,
	MEDUSA,
	PLAGUE_BEARER,
	VAMPIRE_LORD,
	WAR_GOLEM,
	BERSERKER_CHAMPION,
	
	# Boss Enemies
	DRAGON_BOSS,
	LICH_BOSS,
	DEMON_BOSS,
	KRAKEN,
	VOID_HORROR
}

# Spawn pattern definition
class SpawnPattern:
	var initial_enemies: Array = []  # Enemies that start on field (EnemyType)
	var reinforcements: Array = []   # Queue of enemies to spawn (EnemyType)
	var turn_delays: Array = []      # Which turn each reinforcement spawns (int)
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

func initialize_normal_patterns():
	"""Create diverse normal battle spawn patterns"""
	
	# ===== DIFFICULTY 1 PATTERNS =====
	
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
	
	# Pattern 4: Rat Infestation
	var pattern4 = SpawnPattern.new()
	pattern4.name = "Rat Swarm"
	pattern4.initial_enemies = [EnemyType.GIANT_RAT]
	pattern4.reinforcements = [EnemyType.GIANT_RAT]
	pattern4.turn_delays = [3]
	pattern4.difficulty = 1
	normal_patterns.append(pattern4)
	
	# Pattern 5: Lone Bandit
	var pattern5 = SpawnPattern.new()
	pattern5.name = "Highway Robbery"
	pattern5.initial_enemies = [EnemyType.BANDIT]
	pattern5.reinforcements = []
	pattern5.difficulty = 1
	normal_patterns.append(pattern5)
	
	# ===== DIFFICULTY 2 PATTERNS =====
	
	# Pattern 6: Spider Nest
	var pattern6 = SpawnPattern.new()
	pattern6.name = "Spider Nest"
	pattern6.initial_enemies = [EnemyType.SPIDER, EnemyType.SPIDER]
	pattern6.reinforcements = [EnemyType.SPIDER]
	pattern6.turn_delays = [4]
	pattern6.difficulty = 2
	normal_patterns.append(pattern6)
	
	# Pattern 7: Lone Orc - Tough single enemy
	var pattern7 = SpawnPattern.new()
	pattern7.name = "Orc Patrol"
	pattern7.initial_enemies = [EnemyType.ORC]
	pattern7.reinforcements = []
	pattern7.difficulty = 2
	normal_patterns.append(pattern7)
	
	# Pattern 8: Slime Surprise
	var pattern8 = SpawnPattern.new()
	pattern8.name = "Slime Den"
	pattern8.initial_enemies = [EnemyType.SLIME]
	pattern8.reinforcements = [EnemyType.SLIME]
	pattern8.turn_delays = [3]
	pattern8.difficulty = 2
	normal_patterns.append(pattern8)
	
	# Pattern 9: Mixed Threat
	var pattern9 = SpawnPattern.new()
	pattern9.name = "Raiding Party"
	pattern9.initial_enemies = [EnemyType.GOBLIN_ARCHER, EnemyType.SKELETON]
	pattern9.reinforcements = [EnemyType.GOBLIN_MAGE]
	pattern9.turn_delays = [4]
	pattern9.difficulty = 2
	normal_patterns.append(pattern9)
	
	# Pattern 10: Fire Imp
	var pattern10 = SpawnPattern.new()
	pattern10.name = "Infernal Spawns"
	pattern10.initial_enemies = [EnemyType.FIRE_IMP]
	pattern10.reinforcements = [EnemyType.FIRE_IMP]
	pattern10.turn_delays = [4]
	pattern10.difficulty = 2
	normal_patterns.append(pattern10)
	
	# Pattern 11: Wraith
	var pattern11 = SpawnPattern.new()
	pattern11.name = "Phantom Encounter"
	pattern11.initial_enemies = [EnemyType.WRAITH]
	pattern11.reinforcements = [EnemyType.WRAITH]
	pattern11.turn_delays = [4]
	pattern11.difficulty = 2
	normal_patterns.append(pattern11)
	
	# Pattern 12: Corrupted Nature
	var pattern12 = SpawnPattern.new()
	pattern12.name = "Blighted Woods"
	pattern12.initial_enemies = [EnemyType.CORRUPTED_TREANT]
	pattern12.reinforcements = []
	pattern12.difficulty = 2
	normal_patterns.append(pattern12)
	
	# ===== DIFFICULTY 3 PATTERNS =====
	
	# Pattern 13: Undead Assault
	var pattern13 = SpawnPattern.new()
	pattern13.name = "Skeleton Squad"
	pattern13.initial_enemies = [EnemyType.SKELETON]
	pattern13.reinforcements = [EnemyType.SKELETON, EnemyType.SKELETON]
	pattern13.turn_delays = [2, 5]
	pattern13.difficulty = 3
	normal_patterns.append(pattern13)
	
	# Pattern 14: Orc + Goblins
	var pattern14 = SpawnPattern.new()
	pattern14.name = "Orc War Party"
	pattern14.initial_enemies = [EnemyType.ORC]
	pattern14.reinforcements = [EnemyType.GOBLIN, EnemyType.GOBLIN]
	pattern14.turn_delays = [3, 5]
	pattern14.difficulty = 3
	normal_patterns.append(pattern14)
	
	# Pattern 15: Spider + Slime combo
	var pattern15 = SpawnPattern.new()
	pattern15.name = "Cave Dwellers"
	pattern15.initial_enemies = [EnemyType.SPIDER, EnemyType.SLIME]
	pattern15.reinforcements = [EnemyType.SPIDER]
	pattern15.turn_delays = [5]
	pattern15.difficulty = 3
	normal_patterns.append(pattern15)
	
	# Pattern 16: Triple start
	var pattern16 = SpawnPattern.new()
	pattern16.name = "Goblin Ambush"
	pattern16.initial_enemies = [EnemyType.GOBLIN, EnemyType.GOBLIN, EnemyType.GOBLIN]
	pattern16.reinforcements = []
	pattern16.difficulty = 3
	normal_patterns.append(pattern16)
	
	# Pattern 17: Mummy Tomb
	var pattern17 = SpawnPattern.new()
	pattern17.name = "Cursed Tomb"
	pattern17.initial_enemies = [EnemyType.MUMMY]
	pattern17.reinforcements = [EnemyType.MUMMY, EnemyType.SKELETON_WARRIOR]
	pattern17.turn_delays = [3, 5]
	pattern17.difficulty = 3
	normal_patterns.append(pattern17)
	
	# Pattern 18: Goblin Squad
	var pattern18 = SpawnPattern.new()
	pattern18.name = "Goblin Squad"
	pattern18.initial_enemies = [EnemyType.GOBLIN_ARCHER, EnemyType.GOBLIN_ARCHER]
	pattern18.reinforcements = [EnemyType.GOBLIN_MAGE, EnemyType.GOBLIN]
	pattern18.turn_delays = [2, 4]
	pattern18.difficulty = 3
	normal_patterns.append(pattern18)
	
	# Pattern 19: Skeleton Warriors
	var pattern19 = SpawnPattern.new()
	pattern19.name = "Undead Warriors"
	pattern19.initial_enemies = [EnemyType.SKELETON_WARRIOR]
	pattern19.reinforcements = [EnemyType.SKELETON_WARRIOR, EnemyType.SKELETON]
	pattern19.turn_delays = [3, 6]
	pattern19.difficulty = 3
	normal_patterns.append(pattern19)
	
	# Pattern 20: Ice Elemental
	var pattern20 = SpawnPattern.new()
	pattern20.name = "Frozen Encounter"
	pattern20.initial_enemies = [EnemyType.ICE_ELEMENTAL]
	pattern20.reinforcements = [EnemyType.ICE_ELEMENTAL]
	pattern20.turn_delays = [4]
	pattern20.difficulty = 3
	normal_patterns.append(pattern20)
	
	# Pattern 21: Dark Cultists
	var pattern21 = SpawnPattern.new()
	pattern21.name = "Dark Ritual"
	pattern21.initial_enemies = [EnemyType.DARK_CULTIST]
	pattern21.reinforcements = [EnemyType.DARK_CULTIST]
	pattern21.turn_delays = [4]
	pattern21.difficulty = 3
	normal_patterns.append(pattern21)
	
	# Pattern 22: Shadow Assassins
	var pattern22 = SpawnPattern.new()
	pattern22.name = "Shadow Strike"
	pattern22.initial_enemies = [EnemyType.SHADOW_ASSASSIN, EnemyType.SHADOW_ASSASSIN]
	pattern22.reinforcements = []
	pattern22.difficulty = 3
	normal_patterns.append(pattern22)
	
	# Pattern 23: Flying Menace
	var pattern23 = SpawnPattern.new()
	pattern23.name = "Harpy Flock"
	pattern23.initial_enemies = [EnemyType.HARPY, EnemyType.HARPY]
	pattern23.reinforcements = [EnemyType.HARPY]
	pattern23.turn_delays = [4]
	pattern23.difficulty = 3
	normal_patterns.append(pattern23)
	
	# Pattern 24: Gargoyle Guard
	var pattern24 = SpawnPattern.new()
	pattern24.name = "Stone Sentinels"
	pattern24.initial_enemies = [EnemyType.GARGOYLE]
	pattern24.reinforcements = [EnemyType.GARGOYLE]
	pattern24.turn_delays = [5]
	pattern24.difficulty = 3
	normal_patterns.append(pattern24)
	
	# ===== DIFFICULTY 4 PATTERNS =====
	
	# Pattern 25: Elite appears! - Goblin Chief
	var pattern25 = SpawnPattern.new()
	pattern25.name = "Goblin Chief's Band"
	pattern25.initial_enemies = [EnemyType.GOBLIN]
	pattern25.reinforcements = [EnemyType.GOBLIN_CHIEF, EnemyType.GOBLIN]
	pattern25.turn_delays = [3, 5]
	pattern25.difficulty = 4
	normal_patterns.append(pattern25)
	
	# Pattern 26: Sustained assault
	var pattern26 = SpawnPattern.new()
	pattern26.name = "Endless Horde"
	pattern26.initial_enemies = [EnemyType.SKELETON]
	pattern26.reinforcements = [EnemyType.SKELETON, EnemyType.GOBLIN, EnemyType.SKELETON, EnemyType.GOBLIN]
	pattern26.turn_delays = [2, 4, 6, 8]
	pattern26.difficulty = 4
	normal_patterns.append(pattern26)
	
	# Pattern 27: Heavy hitters
	var pattern27 = SpawnPattern.new()
	pattern27.name = "Orc Brothers"
	pattern27.initial_enemies = [EnemyType.ORC, EnemyType.ORC]
	pattern27.reinforcements = [EnemyType.GOBLIN]
	pattern27.turn_delays = [4]
	pattern27.difficulty = 4
	normal_patterns.append(pattern27)
	
	# Pattern 28: Mimic Surprise
	var pattern28 = SpawnPattern.new()
	pattern28.name = "Treasure Trap"
	pattern28.initial_enemies = [EnemyType.MIMIC]
	pattern28.reinforcements = [EnemyType.BANDIT, EnemyType.BANDIT]
	pattern28.turn_delays = [3, 5]
	pattern28.difficulty = 4
	normal_patterns.append(pattern28)
	
	# Pattern 29: Undead Warriors
	var pattern29 = SpawnPattern.new()
	pattern29.name = "Cursed Warriors"
	pattern29.initial_enemies = [EnemyType.UNDEAD_WARRIOR, EnemyType.UNDEAD_WARRIOR]
	pattern29.reinforcements = [EnemyType.WRAITH]
	pattern29.turn_delays = [4]
	pattern29.difficulty = 4
	normal_patterns.append(pattern29)
	
	# Pattern 30: Elemental Mix
	var pattern30 = SpawnPattern.new()
	pattern30.name = "Elemental Chaos"
	pattern30.initial_enemies = [EnemyType.FIRE_IMP, EnemyType.ICE_ELEMENTAL]
	pattern30.reinforcements = [EnemyType.FIRE_IMP]
	pattern30.turn_delays = [4]
	pattern30.difficulty = 4
	normal_patterns.append(pattern30)
	
	# ===== DIFFICULTY 5 PATTERNS =====
	
	# Pattern 31: Elite + minions
	var pattern31 = SpawnPattern.new()
	pattern31.name = "Shaman's Curse"
	pattern31.initial_enemies = [EnemyType.GOBLIN]
	pattern31.reinforcements = [EnemyType.ORC_SHAMAN, EnemyType.ORC, EnemyType.GOBLIN]
	pattern31.turn_delays = [2, 4, 6]
	pattern31.difficulty = 5
	normal_patterns.append(pattern31)
	
	# Pattern 32: Maximum pressure
	var pattern32 = SpawnPattern.new()
	pattern32.name = "All-Out Assault"
	pattern32.initial_enemies = [EnemyType.ORC, EnemyType.SPIDER]
	pattern32.reinforcements = [EnemyType.SKELETON, EnemyType.GOBLIN, EnemyType.SLIME, EnemyType.SPIDER]
	pattern32.turn_delays = [2, 4, 6, 8]
	pattern32.difficulty = 5
	normal_patterns.append(pattern32)
	
	# Pattern 33: Dark Cult
	var pattern33 = SpawnPattern.new()
	pattern33.name = "Cultist Gathering"
	pattern33.initial_enemies = [EnemyType.DARK_CULTIST, EnemyType.DARK_CULTIST]
	pattern33.reinforcements = [EnemyType.SHADOW_ASSASSIN, EnemyType.DARK_CULTIST]
	pattern33.turn_delays = [3, 6]
	pattern33.difficulty = 5
	normal_patterns.append(pattern33)
	
	# Pattern 34: Flying Menace
	var pattern34 = SpawnPattern.new()
	pattern34.name = "Aerial Assault"
	pattern34.initial_enemies = [EnemyType.HARPY, EnemyType.GARGOYLE]
	pattern34.reinforcements = [EnemyType.HARPY, EnemyType.GARGOYLE]
	pattern34.turn_delays = [3, 6]
	pattern34.difficulty = 5
	normal_patterns.append(pattern34)

# ========== ELITE BATTLE PATTERNS ==========

func initialize_elite_patterns():
	"""Create challenging elite battle patterns"""
	
	# Elite 1: Goblin Warband
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
	
	# Elite 8: Lycanthrope Pack
	var elite8 = SpawnPattern.new()
	elite8.name = "Werewolf Den"
	elite8.initial_enemies = [EnemyType.LYCANTHROPE]
	elite8.reinforcements = [EnemyType.LYCANTHROPE, EnemyType.GOBLIN, EnemyType.ORC]
	elite8.turn_delays = [3, 5, 7]
	elite8.difficulty = 4
	elite_patterns.append(elite8)
	
	# Elite 9: Troll Bridge
	var elite9 = SpawnPattern.new()
	elite9.name = "Troll's Domain"
	elite9.initial_enemies = [EnemyType.TROLL]
	elite9.reinforcements = [EnemyType.GOBLIN_CHIEF, EnemyType.ORC, EnemyType.ORC]
	elite9.turn_delays = [4, 6, 8]
	elite9.difficulty = 5
	elite_patterns.append(elite9)
	
	# Elite 10: Mixed Elite Force
	var elite10 = SpawnPattern.new()
	elite10.name = "Elite Vanguard"
	elite10.initial_enemies = [EnemyType.LYCANTHROPE, EnemyType.ORC_SHAMAN]
	elite10.reinforcements = [EnemyType.TROLL, EnemyType.GOLEM]
	elite10.turn_delays = [4, 7]
	elite10.difficulty = 5
	elite_patterns.append(elite10)
	
	# Elite 11: Dark Sorcerer
	var elite11 = SpawnPattern.new()
	elite11.name = "Dark Magic Circle"
	elite11.initial_enemies = [EnemyType.DARK_SORCERER]
	elite11.reinforcements = [EnemyType.DARK_CULTIST, EnemyType.DARK_CULTIST, EnemyType.SHADOW_ASSASSIN]
	elite11.turn_delays = [3, 5, 7]
	elite11.difficulty = 5
	elite_patterns.append(elite11)
	
	# Elite 12: Frost Giant
	var elite12 = SpawnPattern.new()
	elite12.name = "Frozen Fortress"
	elite12.initial_enemies = [EnemyType.FROST_GIANT]
	elite12.reinforcements = [EnemyType.ICE_ELEMENTAL, EnemyType.ICE_ELEMENTAL, EnemyType.WRAITH]
	elite12.turn_delays = [3, 5, 7]
	elite12.difficulty = 5
	elite_patterns.append(elite12)
	
	# Elite 13: Necromancer Elite
	var elite13 = SpawnPattern.new()
	elite13.name = "Necromancer's Legion"
	elite13.initial_enemies = [EnemyType.NECROMANCER_ELITE]
	elite13.reinforcements = [EnemyType.SKELETON_WARRIOR, EnemyType.UNDEAD_WARRIOR, EnemyType.MUMMY]
	elite13.turn_delays = [3, 5, 7]
	elite13.difficulty = 5
	elite_patterns.append(elite13)
	
	# Elite 14: Medusa's Lair
	var elite14 = SpawnPattern.new()
	elite14.name = "Gorgon's Lair"
	elite14.initial_enemies = [EnemyType.MEDUSA]
	elite14.reinforcements = [EnemyType.GARGOYLE, EnemyType.GARGOYLE, EnemyType.HARPY]
	elite14.turn_delays = [3, 5, 7]
	elite14.difficulty = 5
	elite_patterns.append(elite14)
	
	# Elite 15: Plague Bearer
	var elite15 = SpawnPattern.new()
	elite15.name = "Pestilence"
	elite15.initial_enemies = [EnemyType.PLAGUE_BEARER]
	elite15.reinforcements = [EnemyType.GIANT_RAT, EnemyType.GIANT_RAT, EnemyType.CORRUPTED_TREANT]
	elite15.turn_delays = [3, 5, 7]
	elite15.difficulty = 5
	elite_patterns.append(elite15)
	
	# Elite 16: Vampire Lord
	var elite16 = SpawnPattern.new()
	elite16.name = "Vampire's Court"
	elite16.initial_enemies = [EnemyType.VAMPIRE_LORD]
	elite16.reinforcements = [EnemyType.WRAITH, EnemyType.SHADOW_ASSASSIN, EnemyType.MUMMY]
	elite16.turn_delays = [3, 5, 7]
	elite16.difficulty = 5
	elite_patterns.append(elite16)
	
	# Elite 17: War Golem
	var elite17 = SpawnPattern.new()
	elite17.name = "Siege Engine"
	elite17.initial_enemies = [EnemyType.WAR_GOLEM]
	elite17.reinforcements = [EnemyType.GOLEM, EnemyType.GARGOYLE, EnemyType.ORC]
	elite17.turn_delays = [4, 6, 8]
	elite17.difficulty = 5
	elite_patterns.append(elite17)
	
	# Elite 18: Berserker Champion
	var elite18 = SpawnPattern.new()
	elite18.name = "Berserker's Rage"
	elite18.initial_enemies = [EnemyType.BERSERKER_CHAMPION]
	elite18.reinforcements = [EnemyType.ORC, EnemyType.ORC, EnemyType.GOBLIN_CHIEF]
	elite18.turn_delays = [3, 5, 7]
	elite18.difficulty = 5
	elite_patterns.append(elite18)
	
	# Elite 19: Ultimate Challenge
	var elite19 = SpawnPattern.new()
	elite19.name = "Nightmare Gauntlet"
	elite19.initial_enemies = [EnemyType.FROST_GIANT, EnemyType.VAMPIRE_LORD]
	elite19.reinforcements = [EnemyType.DARK_SORCERER, EnemyType.MEDUSA]
	elite19.turn_delays = [4, 7]
	elite19.difficulty = 5
	elite_patterns.append(elite19)
	
	# Elite 20: Death Squad
	var elite20 = SpawnPattern.new()
	elite20.name = "Death Squad"
	elite20.initial_enemies = [EnemyType.NECROMANCER_ELITE, EnemyType.PLAGUE_BEARER]
	elite20.reinforcements = [EnemyType.VAMPIRE_LORD, EnemyType.TROLL]
	elite20.turn_delays = [4, 7]
	elite20.difficulty = 5
	elite_patterns.append(elite20)

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
		# Normal Enemies - Original
		EnemyType.GOBLIN: return "goblin"
		EnemyType.GOBLIN_ARCHER: return "goblin_archer"
		EnemyType.GOBLIN_MAGE: return "goblin_mage"
		EnemyType.ORC: return "orc"
		EnemyType.SKELETON: return "skeleton"
		EnemyType.SKELETON_WARRIOR: return "skeleton_warrior"
		EnemyType.SLIME: return "slime"
		EnemyType.SPIDER: return "spider"
		EnemyType.MUMMY: return "mummy"
		
		# Normal Enemies - New
		EnemyType.GIANT_RAT: return "giant_rat"
		EnemyType.FIRE_IMP: return "fire_imp"
		EnemyType.ICE_ELEMENTAL: return "ice_elemental"
		EnemyType.DARK_CULTIST: return "dark_cultist"
		EnemyType.SHADOW_ASSASSIN: return "shadow_assassin"
		EnemyType.WRAITH: return "wraith"
		EnemyType.GARGOYLE: return "gargoyle"
		EnemyType.HARPY: return "harpy"
		EnemyType.MIMIC: return "mimic"
		EnemyType.UNDEAD_WARRIOR: return "undead_warrior"
		EnemyType.CORRUPTED_TREANT: return "corrupted_treant"
		EnemyType.BANDIT: return "bandit"
		
		# Elite Enemies - Original
		EnemyType.GOBLIN_CHIEF: return "goblin_chief"
		EnemyType.ORC_SHAMAN: return "orc_shaman"
		EnemyType.GOLEM: return "golem"
		EnemyType.LYCANTHROPE: return "lycanthrope"
		EnemyType.WEREWOLF: return "werewolf"
		EnemyType.TROLL: return "troll"
		
		# Elite Enemies - New
		EnemyType.DARK_SORCERER: return "dark_sorcerer"
		EnemyType.FROST_GIANT: return "frost_giant"
		EnemyType.NECROMANCER_ELITE: return "necromancer_elite"
		EnemyType.MEDUSA: return "medusa"
		EnemyType.PLAGUE_BEARER: return "plague_bearer"
		EnemyType.VAMPIRE_LORD: return "vampire_lord"
		EnemyType.WAR_GOLEM: return "war_golem"
		EnemyType.BERSERKER_CHAMPION: return "berserker_champion"
		
		# Boss Enemies
		EnemyType.DRAGON_BOSS: return "dragon_boss"
		EnemyType.LICH_BOSS: return "lich_boss"
		EnemyType.DEMON_BOSS: return "demon_boss"
		EnemyType.KRAKEN: return "kraken"
		EnemyType.VOID_HORROR: return "void_horror"
	
	return "goblin"  # Fallback

func get_enemy_type_from_id(enemy_id: String) -> EnemyType:
	"""Convert database ID string to EnemyType enum"""
	match enemy_id:
		# Normal Enemies - Original
		"goblin": return EnemyType.GOBLIN
		"goblin_archer": return EnemyType.GOBLIN_ARCHER
		"goblin_mage": return EnemyType.GOBLIN_MAGE
		"orc": return EnemyType.ORC
		"skeleton": return EnemyType.SKELETON
		"skeleton_warrior": return EnemyType.SKELETON_WARRIOR
		"slime": return EnemyType.SLIME
		"spider": return EnemyType.SPIDER
		"mummy": return EnemyType.MUMMY
		
		# Normal Enemies - New
		"giant_rat": return EnemyType.GIANT_RAT
		"fire_imp": return EnemyType.FIRE_IMP
		"ice_elemental": return EnemyType.ICE_ELEMENTAL
		"dark_cultist": return EnemyType.DARK_CULTIST
		"shadow_assassin": return EnemyType.SHADOW_ASSASSIN
		"wraith": return EnemyType.WRAITH
		"gargoyle": return EnemyType.GARGOYLE
		"harpy": return EnemyType.HARPY
		"mimic": return EnemyType.MIMIC
		"undead_warrior": return EnemyType.UNDEAD_WARRIOR
		"corrupted_treant": return EnemyType.CORRUPTED_TREANT
		"bandit": return EnemyType.BANDIT
		
		# Elite Enemies - Original
		"goblin_chief": return EnemyType.GOBLIN_CHIEF
		"orc_shaman": return EnemyType.ORC_SHAMAN
		"golem": return EnemyType.GOLEM
		"lycanthrope": return EnemyType.LYCANTHROPE
		"werewolf": return EnemyType.WEREWOLF
		"troll": return EnemyType.TROLL
		
		# Elite Enemies - New
		"dark_sorcerer": return EnemyType.DARK_SORCERER
		"frost_giant": return EnemyType.FROST_GIANT
		"necromancer_elite": return EnemyType.NECROMANCER_ELITE
		"medusa": return EnemyType.MEDUSA
		"plague_bearer": return EnemyType.PLAGUE_BEARER
		"vampire_lord": return EnemyType.VAMPIRE_LORD
		"war_golem": return EnemyType.WAR_GOLEM
		"berserker_champion": return EnemyType.BERSERKER_CHAMPION
		
		# Boss Enemies
		"dragon_boss": return EnemyType.DRAGON_BOSS
		"lich_boss": return EnemyType.LICH_BOSS
		"demon_boss": return EnemyType.DEMON_BOSS
		"kraken": return EnemyType.KRAKEN
		"void_horror": return EnemyType.VOID_HORROR
	
	return EnemyType.GOBLIN  # Fallback

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
		# Normal Enemies - Original
		EnemyType.GOBLIN: return "Goblin Warrior"
		EnemyType.GOBLIN_ARCHER: return "Goblin Archer"
		EnemyType.GOBLIN_MAGE: return "Goblin Mage"
		EnemyType.ORC: return "Orc Bruiser"
		EnemyType.SKELETON: return "Skeleton Archer"
		EnemyType.SKELETON_WARRIOR: return "Skeleton Warrior"
		EnemyType.SLIME: return "Toxic Slime"
		EnemyType.SPIDER: return "Giant Spider"
		EnemyType.MUMMY: return "Mummy"
		
		# Normal Enemies - New
		EnemyType.GIANT_RAT: return "Giant Rat"
		EnemyType.FIRE_IMP: return "Fire Imp"
		EnemyType.ICE_ELEMENTAL: return "Ice Elemental"
		EnemyType.DARK_CULTIST: return "Dark Cultist"
		EnemyType.SHADOW_ASSASSIN: return "Shadow Assassin"
		EnemyType.WRAITH: return "Wraith"
		EnemyType.GARGOYLE: return "Gargoyle"
		EnemyType.HARPY: return "Harpy"
		EnemyType.MIMIC: return "Mimic"
		EnemyType.UNDEAD_WARRIOR: return "Undead Warrior"
		EnemyType.CORRUPTED_TREANT: return "Corrupted Treant"
		EnemyType.BANDIT: return "Bandit"
		
		# Elite Enemies - Original
		EnemyType.GOBLIN_CHIEF: return "Goblin Chief"
		EnemyType.ORC_SHAMAN: return "Orc Shaman"
		EnemyType.GOLEM: return "Stone Golem"
		EnemyType.LYCANTHROPE: return "Lycanthrope"
		EnemyType.WEREWOLF: return "Werewolf"
		EnemyType.TROLL: return "Troll"
		
		# Elite Enemies - New
		EnemyType.DARK_SORCERER: return "Dark Sorcerer"
		EnemyType.FROST_GIANT: return "Frost Giant"
		EnemyType.NECROMANCER_ELITE: return "Necromancer"
		EnemyType.MEDUSA: return "Medusa"
		EnemyType.PLAGUE_BEARER: return "Plague Bearer"
		EnemyType.VAMPIRE_LORD: return "Vampire Lord"
		EnemyType.WAR_GOLEM: return "War Golem"
		EnemyType.BERSERKER_CHAMPION: return "Berserker Champion"
		
		# Boss Enemies
		EnemyType.DRAGON_BOSS: return "Ancient Red Dragon"
		EnemyType.LICH_BOSS: return "Archlich Malachar"
		EnemyType.DEMON_BOSS: return "Infernal Tyrant"
		EnemyType.KRAKEN: return "Kraken, Terror of the Deep"
		EnemyType.VOID_HORROR: return "The Void Horror, Eater of Worlds"
	
	return "Unknown"
