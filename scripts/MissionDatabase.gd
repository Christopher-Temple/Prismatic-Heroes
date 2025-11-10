extends Node

# Dictionaries for all data
var objectives: Dictionary = {}
var node_types: Dictionary = {}
var treasure_items: Array[String] = []
var legendary_items: Array[String] = []

func _ready():
	setup_objectives()
	setup_node_types()
	setup_items()

# === OBJECTIVES ===

func setup_objectives():
	"""Create all objective types in code (could be .tres files later)"""
	
	# 1. Rescue missions
	var rescue = ObjectiveData.new()
	rescue.id = "rescue"
	rescue.objective_type = "rescue"
	rescue.title_template = "Rescue the {target} from {boss}!"
	rescue.requires_target = true
	rescue.target_options = ["Princess", "Prince", "Merchant", "Scholar", "Knight", "Child", "Elder"]
	rescue.completion_text = "The {target} has been saved!"
	objectives["rescue"] = rescue
	
	# 2. Retrieve item missions
	var retrieve = ObjectiveData.new()
	retrieve.id = "retrieve"
	retrieve.objective_type = "retrieve"
	retrieve.title_template = "Retrieve the {item} from {boss}!"
	retrieve.requires_item = true
	retrieve.completion_text = "The {item} has been recovered!"
	objectives["retrieve"] = retrieve
	
	# 3. Slay the boss
	var slay = ObjectiveData.new()
	slay.id = "slay"
	slay.objective_type = "slay"
	slay.title_template = "Defeat {boss}!"
	slay.completion_text = "{boss} has been vanquished!"
	objectives["slay"] = slay
	
	# 4. Escort mission
	var escort = ObjectiveData.new()
	escort.id = "escort"
	escort.objective_type = "escort"
	escort.title_template = "Escort the {target} to safety past {boss}!"
	escort.requires_target = true
	escort.target_options = ["Caravan", "Diplomat", "Refugee", "Pilgrim", "Emissary"]
	escort.completion_text = "The {target} arrived safely!"
	objectives["escort"] = escort
	
	# 5. Defend location
	var defend = ObjectiveData.new()
	defend.id = "defend"
	defend.objective_type = "defend"
	defend.title_template = "Defend {location} from {boss}!"
	defend.requires_location = true
	defend.location_options = ["the Village", "the Temple", "the Castle", "the Shrine", "the Outpost"]
	defend.completion_text = "{location} is safe!"
	objectives["defend"] = defend
	
	# 6. Purify corrupted area
	var purify = ObjectiveData.new()
	purify.id = "purify"
	purify.objective_type = "purify"
	purify.title_template = "Purify {location} by defeating {boss}!"
	purify.requires_location = true
	purify.location_options = ["the Cursed Grove", "the Tainted Well", "the Desecrated Tomb", "the Corrupted Sanctum"]
	purify.completion_text = "{location} has been cleansed!"
	objectives["purify"] = purify
	
	# 7. Stop ritual
	var ritual = ObjectiveData.new()
	ritual.id = "stop_ritual"
	ritual.objective_type = "ritual"
	ritual.title_template = "Stop {boss}'s dark ritual!"
	ritual.completion_text = "The ritual has been disrupted!"
	objectives["stop_ritual"] = ritual
	
	# 8. Reclaim territory
	var reclaim = ObjectiveData.new()
	reclaim.id = "reclaim"
	reclaim.objective_type = "reclaim"
	reclaim.title_template = "Reclaim {location} from {boss}!"
	reclaim.requires_location = true
	reclaim.location_options = ["the Ancient Ruins", "the Lost Fortress", "the Abandoned Mine", "the Sacred Grove"]
	reclaim.completion_text = "{location} has been reclaimed!"
	objectives["reclaim"] = reclaim
	
	# 9. Break siege
	var siege = ObjectiveData.new()
	siege.id = "break_siege"
	siege.objective_type = "siege"
	siege.title_template = "Break {boss}'s siege on {location}!"
	siege.requires_location = true
	siege.location_options = ["the City", "the Keep", "the Monastery", "the Stronghold"]
	siege.completion_text = "The siege has been broken!"
	objectives["break_siege"] = siege
	
	# 10. Seal evil
	var seal = ObjectiveData.new()
	seal.id = "seal"
	seal.objective_type = "seal"
	seal.title_template = "Seal {boss} back in {location}!"
	seal.requires_location = true
	seal.location_options = ["the Abyss", "the Void Prison", "the Shadow Realm", "the Nether"]
	seal.completion_text = "{boss} has been sealed away!"
	objectives["seal"] = seal
	
	# 11. Avenge fallen
	var avenge = ObjectiveData.new()
	avenge.id = "avenge"
	avenge.objective_type = "avenge"
	avenge.title_template = "Avenge the fallen by defeating {boss}!"
	avenge.completion_text = "Justice has been served!"
	objectives["avenge"] = avenge
	
	# 12. Investigate threat
	var investigate = ObjectiveData.new()
	investigate.id = "investigate"
	investigate.objective_type = "investigate"
	investigate.title_template = "Investigate and eliminate the threat of {boss}!"
	investigate.completion_text = "The threat has been eliminated!"
	objectives["investigate"] = investigate

# === NODE TYPES ===

func setup_node_types():
	"""Create all node types"""
	
	# 1. Battle - Normal enemy encounter
	var battle = NodeTypeData.new()
	battle.id = "battle"
	battle.display_name = "Battle"
	battle.color = Color("#E74C3C")  # Red
	battle.description = "Fight enemies"
	battle.is_combat = true
	battle.spawn_weight = 30
	battle.scene_path = "res://scenes/battle_scene.tscn"
	node_types["battle"] = battle
	
	# 2. Elite Battle - Harder encounter
	var elite = NodeTypeData.new()
	elite.id = "elite"
	elite.display_name = "Elite Battle"
	elite.color = Color("#9B59B6")  # Purple
	elite.description = "Fight a powerful enemy"
	elite.is_combat = true
	elite.spawn_weight = 10
	elite.max_per_map = 2
	elite.scene_path = "res://scenes/battle_scene.tscn"
	node_types["elite"] = elite
	
	# 3. Shop
	var shop = NodeTypeData.new()
	shop.id = "shop"
	shop.display_name = "Shop"
	shop.color = Color("#F39C12")
	shop.description = "Purchase upgrades"
	shop.spawn_weight = 8  # Changed from 15 to 8
	shop.max_per_map = 2
	shop.scene_path = "res://scenes/shop.tscn"
	node_types["shop"] = shop

	# 4. Rest Site
	var rest = NodeTypeData.new()
	rest.id = "rest"
	rest.display_name = "Campfire"
	rest.color = Color("#2ECC71")
	rest.description = "Rest and recover"
	rest.spawn_weight = 8  # Changed from 15 to 8
	rest.max_per_map = 2
	rest.scene_path = "res://scenes/rest_site.tscn"
	node_types["rest"] = rest
	
	# 5. Treasure
	var treasure = NodeTypeData.new()
	treasure.id = "treasure"
	treasure.display_name = "Treasure"
	treasure.color = Color("#F1C40F")  # Yellow
	treasure.description = "Find valuable loot"
	treasure.spawn_weight = 8
	treasure.max_per_map = 2
	treasure.scene_path = "res://scenes/treasure.tscn"
	node_types["treasure"] = treasure
	
	# 6. Mystery
	var mystery = NodeTypeData.new()
	mystery.id = "mystery"
	mystery.display_name = "Mystery"
	mystery.color = Color("#3498DB")  # Blue
	mystery.description = "Unknown encounter"
	mystery.spawn_weight = 0
	mystery.max_per_map = 0
	mystery.scene_path = "res://scenes/Mystery.tscn"
	node_types["mystery"] = mystery
	
	# 7. Boss
	var boss = NodeTypeData.new()
	boss.id = "boss"
	boss.display_name = "Boss"
	boss.color = Color("#C0392B")  # Dark Red
	boss.description = "Face the final challenge"
	boss.is_combat = true
	boss.is_mandatory = true
	boss.spawn_weight = 0  # Never randomly spawned
	boss.scene_path = "res://scenes/PuzzleGame.tscn"
	node_types["boss"] = boss
	
	# 8. Event
	var event = NodeTypeData.new()
	event.id = "event"
	event.display_name = "Event"
	event.color = Color("#1ABC9C")  # Teal
	event.description = "A special occurrence"
	event.spawn_weight = 8
	event.max_per_map = 2
	event.scene_path = "res://scenes/event.tscn"
	node_types["event"] = event

# === ITEMS (for retrieve missions) ===

func setup_items():
	"""Setup lists of retrievable items"""
	treasure_items = [
		"Golden Chalice",
		"Ancient Tome",
		"Crown of Kings",
		"Sacred Relic",
		"Dragon Egg",
		"Magic Sword",
		"Enchanted Staff",
		"Holy Grail",
		"Cursed Amulet",
		"Phoenix Feather"
	]
	
	legendary_items = [
		"Blade of Destiny",
		"Orb of Eternity",
		"Jade Necklace",
		"Crystal of Power",
		"Scepter of Light",
		"Ring of Shadows",
		"Crown of Thorns",
		"Heart of the Mountain"
	]

# === HELPER FUNCTIONS ===

func generate_random_objective() -> Dictionary:
	"""Generate a complete random objective with boss"""
	var objective_list = objectives.keys()
	var objective_id = objective_list[randi() % objective_list.size()]
	var objective = objectives[objective_id]
	
	# Get random boss
	var boss_id = EnemyDatabase.get_random_boss()
	var boss_data = EnemyDatabase.get_enemy(boss_id)
	var boss_name = boss_data.enemy_name if boss_data else "Dark Lord"
	
	# Generate required components
	var item_name = ""
	var target_name = ""
	var location_name = ""
	
	if objective.requires_item:
		var all_items = treasure_items + legendary_items
		item_name = all_items[randi() % all_items.size()]
	
	if objective.requires_target:
		target_name = objective.target_options[randi() % objective.target_options.size()]
	
	if objective.requires_location:
		location_name = objective.location_options[randi() % objective.location_options.size()]
	
	# Generate title
	var title = objective.generate_title(boss_name, item_name, target_name, location_name)
	
	return {
		"objective_id": objective_id,
		"boss_id": boss_id,
		"title": title,
		"item": item_name,
		"target": target_name,
		"location": location_name,
		"completion_text": objective.completion_text.replace("{target}", target_name).replace("{item}", item_name).replace("{location}", location_name).replace("{boss}", boss_name)
	}

func get_node_type(type_id: String) -> NodeTypeData:
	"""Get node type data"""
	return node_types.get(type_id)

func get_random_node_type(exclude_types: Array = []) -> String:
	"""Get random node type ID based on spawn weights"""
	var available_types = []
	var weights = []
	
	for type_id in node_types:
		var node_type = node_types[type_id]
		if node_type.spawn_weight > 0 and type_id not in exclude_types:
			available_types.append(type_id)
			weights.append(node_type.spawn_weight)
	
	if available_types.size() == 0:
		return "battle"
	
	# Weighted random selection
	var total_weight = 0
	for w in weights:
		total_weight += w
	
	var random_value = randi() % total_weight
	var cumulative = 0
	
	for i in range(weights.size()):
		cumulative += weights[i]
		if random_value < cumulative:
			return available_types[i]
	
	return available_types[0]
