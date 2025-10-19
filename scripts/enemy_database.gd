extends Node

# Dictionary of all enemy data, keyed by enemy ID
var enemies: Dictionary = {}

# Quick lookup arrays
var normal_enemies: Array[String] = []
var elite_enemies: Array[String] = []
var boss_enemies: Array[String] = []
var all_enemy_ids: Array[String] = []

func _ready():
	print("EnemyDatabase initializing...")
	load_all_enemies()
	print("EnemyDatabase loaded %d enemies" % enemies.size())

func load_all_enemies():
	"""Load all enemy resource files from disk"""
	var enemy_paths = [
		# NORMAL ENEMIES
		"res://resources/enemies/goblin.tres",
		"res://resources/enemies/orc.tres",
		"res://resources/enemies/skeleton.tres",
		"res://resources/enemies/slime.tres",
		"res://resources/enemies/spider.tres",
		
		# ELITE ENEMIES
		"res://resources/enemies/goblin_chief.tres",
		"res://resources/enemies/orc_shaman.tres",
		"res://resources/enemies/golem.tres",
		
		# BOSSES
		"res://resources/enemies/dragon_boss.tres",
		"res://resources/enemies/lich_boss.tres",
		"res://resources/enemies/demon_boss.tres"
	]
	
	for path in enemy_paths:
		if ResourceLoader.exists(path):
			var enemy_data: EnemyData = load(path)
			if enemy_data and enemy_data.id != "":
				enemies[enemy_data.id] = enemy_data
				all_enemy_ids.append(enemy_data.id)
				
				# Categorize by type
				match enemy_data.enemy_type:
					"Normal":
						normal_enemies.append(enemy_data.id)
					"Elite":
						elite_enemies.append(enemy_data.id)
					"Boss":
						boss_enemies.append(enemy_data.id)
			else:
				push_error("Failed to load enemy data from: %s" % path)
		else:
			push_error("Enemy resource not found: %s" % path)

# === HELPER FUNCTIONS ===

func get_enemy(enemy_id: String) -> EnemyData:
	"""Get enemy data by ID"""
	return enemies.get(enemy_id)

func get_enemy_name(enemy_id: String) -> String:
	"""Get enemy's display name"""
	if enemies.has(enemy_id):
		return enemies[enemy_id].enemy_name
	return "Unknown"

func get_random_normal_enemy() -> String:
	"""Get random normal enemy ID"""
	if normal_enemies.size() > 0:
		return normal_enemies[randi() % normal_enemies.size()]
	return ""

func get_random_elite_enemy() -> String:
	"""Get random elite enemy ID"""
	if elite_enemies.size() > 0:
		return elite_enemies[randi() % elite_enemies.size()]
	return ""

func get_random_boss() -> String:
	"""Get random boss enemy ID"""
	if boss_enemies.size() > 0:
		return boss_enemies[randi() % boss_enemies.size()]
	return ""

func get_all_normal_enemies() -> Array:
	"""Get array of all normal enemy IDs"""
	return normal_enemies.duplicate()

func get_all_elite_enemies() -> Array:
	"""Get array of all elite enemy IDs"""
	return elite_enemies.duplicate()

func get_all_bosses() -> Array:
	"""Get array of all boss enemy IDs"""
	return boss_enemies.duplicate()
