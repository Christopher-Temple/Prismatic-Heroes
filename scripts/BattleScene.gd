# BattleScene.gd - COMPLETE WITH FULL UI
extends Control

# Scene references
@onready var puzzle_grid: PuzzleGrid = $PuzzleGrid
@onready var next_piece_preview = $NextPiecePreview
@onready var game_over_panel = $GameOverPanel
@onready var combat_log: RichTextLabel = $CombatLog

# Character UI - Left side
@onready var character_panel = $CharacterPanel
@onready var char1_container = $CharacterPanel/Character1
@onready var char2_container = $CharacterPanel/Character2
@onready var char3_container = $CharacterPanel/Character3
@onready var party_health_bar: Panel = $CharacterPanel/PartyHealthBar

# Enemy UI - Right side
@onready var enemy_panel = $EnemyPanel
@onready var enemy1_container = $EnemyPanel/Enemy1
@onready var enemy2_container = $EnemyPanel/Enemy2
@onready var enemy3_container = $EnemyPanel/Enemy3

# Game state
var current_piece: TetrisPiece = null
var next_piece_data: Dictionary = {}
var piece_factory: PieceFactory = null

var party: Array = []  # Character IDs
var enemies: Array = []  # Currently active enemies (max 3)
var enemy_spawn_queue: Array = []  # Enemies waiting to spawn
var current_turn: int = 0

var spawn_manager: EnemySpawnManager = null

var is_player_turn: bool = true
var is_processing_matches: bool = false
var game_over: bool = false

# Character power tracking
var character_power: Dictionary = {}
const MAX_POWER: int = 100

# Character UI references
var character_ui: Array = []  # Stores UI node references for each character

# Enemy UI references  
var enemy_ui: Array = []  # Stores UI node references for each enemy

# Enemy turn counter
var player_moves_made: int = 0

# REMOVED: moves_until_enemy_action - enemies act every turn now

func _ready():
	# Initialize
	piece_factory = PieceFactory.new()
	add_child(piece_factory)
	
	spawn_manager = EnemySpawnManager.new()
	add_child(spawn_manager)
	
	# Load battle data
	load_battle_data()
	
	# Setup UI
	setup_party_health()
	setup_characters()
	setup_enemies()
	
	# Generate first pieces
	next_piece_data = piece_factory.generate_piece()
	
	# Start game
	spawn_player_piece()

func _input(event):
	if game_over or not is_player_turn or is_processing_matches:
		return
	
	if current_piece and current_piece.can_move:
		if event.is_action_pressed("ui_left"):
			current_piece.move_left()
		elif event.is_action_pressed("ui_right"):
			current_piece.move_right()
		elif event.is_action_pressed("ui_down"):
			current_piece.has_started_falling = true
			current_piece.is_falling = true
		elif event.is_action_pressed("ui_up"):
			current_piece.rotate_clockwise()
		elif event.is_action_pressed("ui_accept"):
			current_piece.hard_drop()

func load_battle_data():
	"""Load party and setup enemy spawn pattern"""
	party = GameManager.get_current_party()
	
	# Set player colors
	piece_factory.set_player_colors(party)
	
	# Initialize character power
	for char_id in party:
		character_power[char_id] = 0
	
	# Get battle info from GameManager
	var battle_info = GameManager.get_battle_info()
	var is_elite_battle = battle_info.get("is_elite", false)
	var difficulty_level = battle_info.get("difficulty", 1)
	
	
	# Setup battle spawn pattern
	var battle_data = spawn_manager.setup_battle(is_elite_battle, difficulty_level)
	
		
	# Spawn initial enemies with RANDOMIZED cooldowns
	for enemy_type in battle_data["initial_enemies"]:
		var enemy = spawn_manager.create_enemy_instance(enemy_type, difficulty_level)
		if enemy:
			# Randomize starting cooldown (1 to max cooldown)
			enemy["current_cooldown"] = randi_range(1, enemy["attack_cooldown"])
			enemies.append(enemy)
			
	
	# Store spawn queue
	enemy_spawn_queue = battle_data["spawn_queue"].duplicate()
	
	if enemy_spawn_queue.size() > 0:
		
		for spawn_data in enemy_spawn_queue:
			var enemy_name = spawn_manager.get_enemy_name(spawn_data["enemy"])
			

# ========== CHARACTER UI ==========

func setup_party_health():
	"""Setup party health bar"""
	var vbox = party_health_bar.get_node("VBoxContainer")
	var health_bar = vbox.get_node("HealthBar")
	var health_label = health_bar.get_node("HealthValueLabel")
	
	var current_hp = GameManager.get_current_health()
	var max_hp = GameManager.get_max_health()
	
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_label.text = "%d/%d" % [current_hp, max_hp]
	
	# Connect to health change signal
	GameManager.health_changed.connect(_on_party_health_changed)
	


func _on_party_health_changed(current_hp: int, max_hp: int):
	"""Update party health bar when health changes"""
	if not party_health_bar:
		return
	
	var vbox = party_health_bar.get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	var health_bar = vbox.get_node_or_null("HealthBar")
	var health_label = health_bar.get_node_or_null("HealthValueLabel") if health_bar else null
	
	if health_bar:
		health_bar.value = current_hp
	
	if health_label:
		health_label.text = "%d/%d" % [current_hp, max_hp]
	
	# Flash red when damaged
	if health_bar:
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate", Color.RED, 0.1)
		tween.tween_property(health_bar, "modulate", Color.WHITE, 0.2)
	
	# Check for game over
	if current_hp <= 0:
		trigger_game_over()

func setup_characters():
	"""Create character UI panels"""
	character_ui = []
	
	var containers = [char1_container, char2_container, char3_container]
	
	for i in range(party.size()):
		var char_id = party[i]
		var char_data = CharacterDatabase.get_character(char_id)
		
		if not char_data:
			
			continue
		
		
		
		var container = containers[i]
		
		# Check if container exists
		if not container:
			
			continue
		
		# Get nodes with error checking
		var vbox = container.get_node_or_null("VBoxContainer")
		if not vbox:
			
			continue
		
		var portrait = vbox.get_node_or_null("Portrait")
		var name_label = vbox.get_node_or_null("NameLabel")
		var class_label = vbox.get_node_or_null("ClassLabel")
		var power_bar = vbox.get_node_or_null("PowerBar")
		var power_label = power_bar.get_node_or_null("PowerLabel") if power_bar else null
		
		# Create UI structure
		var ui = {
			"container": container,
			"portrait": portrait,
			"name_label": name_label,
			"class_label": class_label,
			"power_bar": power_bar,
			"power_label": power_label
		}
		
		# Set character info
		ui["name_label"].text = char_data.character_name
		ui["class_label"].text = char_data.character_class
		
		# Load portrait if exists
		if char_data.portrait_path != "" and ResourceLoader.exists(char_data.portrait_path):
			var texture = load(char_data.portrait_path)
			ui["portrait"].texture = texture
			
		else:
			
			ui["portrait"].modulate = char_data.color
		
		# Set power bar color based on character color
		ui["power_bar"].modulate = char_data.color
		ui["power_bar"].value = 0
		ui["power_label"].text = "0/100"
		
		# Show container
		container.visible = true
		
		character_ui.append(ui)
		
	
	# Hide unused character slots
	for i in range(party.size(), 3):
		containers[i].visible = false
	

func update_character_power(char_index: int):
	"""Update character power bar display"""
	if char_index >= character_ui.size():
		return
	
	var char_id = party[char_index]
	var power = character_power[char_id]
	var ui = character_ui[char_index]
	
	ui["power_bar"].value = power
	ui["power_label"].text = "%d/100" % power
	
	# Visual effect when at full power
	if power >= MAX_POWER:
		ui["power_bar"].modulate = Color.WHITE  # Glow effect
		# TODO: Add pulse animation

# ========== ENEMY UI ==========

func setup_enemies():
	"""Create/update enemy UI panels"""
	enemy_ui = []	
	
	var containers = [enemy1_container, enemy2_container, enemy3_container]
	
	# Clear all containers first
	for container in containers:
		container.visible = false
	
	# Setup active enemies
	for i in range(enemies.size()):
		var enemy = enemies[i]
		var container = containers[i]
		
		
		
		# Check if container exists
		if not container:
			
			continue
		
		# Get nodes with error checking
		var vbox = container.get_node_or_null("VBoxContainer")
		if not vbox:
			
			continue
		
		var portrait = vbox.get_node_or_null("Portrait")
		var name_label = vbox.get_node_or_null("NameLabel")
		var type_label = vbox.get_node_or_null("TypeLabel")
		var hp_bar = vbox.get_node_or_null("HPBar")
		var hp_label = hp_bar.get_node_or_null("HPLabel") if hp_bar else null
		var cooldown_label = vbox.get_node_or_null("CooldownLabel")
		
		# Create UI structure
		var ui = {
			"container": container,
			"portrait": portrait,
			"name_label": name_label,
			"type_label": type_label,
			"hp_bar": hp_bar,
			"hp_label": hp_label,
			"cooldown_label": cooldown_label
		}
		
		# Set enemy info
		ui["name_label"].text = enemy["data"].enemy_name
		ui["type_label"].text = enemy["data"].enemy_type
		
		# Load portrait if exists
		if enemy["data"].sprite_path != "" and ResourceLoader.exists(enemy["data"].sprite_path):
			var texture = load(enemy["data"].sprite_path)
			ui["portrait"].texture = texture
			
		else:
			# Fallback: colored rect
		
			ui["portrait"].modulate = enemy["data"].color
		
		# Set HP bar
		ui["hp_bar"].max_value = enemy["max_hp"]
		ui["hp_bar"].value = enemy["current_hp"]
		ui["hp_label"].text = "%d/%d" % [enemy["current_hp"], enemy["max_hp"]]
		
		# Set cooldown display
		update_enemy_cooldown_display(ui, enemy)
		
		# Show container
		container.visible = true
		
		enemy_ui.append(ui)
		
func update_enemy_hp(enemy_index: int):
	"""Update enemy HP bar display"""
	if enemy_index >= enemy_ui.size():
		return
	
	var enemy = enemies[enemy_index]
	var ui = enemy_ui[enemy_index]
	
	ui["hp_bar"].value = enemy["current_hp"]
	ui["hp_label"].text = "%d/%d" % [enemy["current_hp"], enemy["max_hp"]]
	
	# Flash red when damaged
	var tween = create_tween()
	tween.tween_property(ui["hp_bar"], "modulate", Color.RED, 0.1)
	tween.tween_property(ui["hp_bar"], "modulate", Color.WHITE, 0.2)

func update_enemy_cooldown_display(ui: Dictionary, enemy: Dictionary):
	"""Update enemy attack cooldown display"""
	var cooldown = enemy["current_cooldown"]
	
	if cooldown <= 0:
		ui["cooldown_label"].text = "⚔ ACTING NOW!"
		ui["cooldown_label"].modulate = Color.RED
	elif cooldown == 1:
		ui["cooldown_label"].text = "⚠ Acts next turn!"
		ui["cooldown_label"].modulate = Color.ORANGE
	else:
		ui["cooldown_label"].text = "Acts in: %d turns" % cooldown
		ui["cooldown_label"].modulate = Color.WHITE

func show_reinforcement_notification(enemy_name: String):
	"""Show notification when enemy reinforcement spawns"""
	# TODO: Create popup notification
	log_combat_event("🔔 Reinforcement: %s joins the battle!" % enemy_name, Color(1, 0.9, 0.5))


# ========== PIECE SPAWNING ==========

func spawn_player_piece():
	"""Spawn a new piece for the player"""
	if game_over:
		return
	
	if puzzle_grid.is_grid_full():
		trigger_game_over()
		return
	
	# Limit spawn range to avoid pieces spawning off-grid
	# Grid is 40 wide, pieces can be up to 4 wide
	# Safe spawn range: 5 to 35 (leaves 5 blocks margin on each side)
	var safe_min = 5
	var safe_max = puzzle_grid.GRID_WIDTH - 5
	var spawn_x = randi_range(safe_min, safe_max)
	
	current_piece = TetrisPiece.new()
	current_piece.setup_piece(next_piece_data["shape"], next_piece_data["colors"], spawn_x)
	current_piece.piece_locked.connect(_on_piece_locked)
	
	puzzle_grid.add_child(current_piece)
	
	next_piece_data = piece_factory.generate_piece()
	update_next_piece_preview()

func update_next_piece_preview():
	"""Update the next piece preview display"""
	# TODO: Show next piece visually
	pass

# ========== PIECE LOCKING & TURN FLOW ==========

func _on_piece_locked():
	"""Handle when piece locks into grid"""
	is_player_turn = false
	current_piece.queue_free()
	current_piece = null
	
	player_moves_made += 1
	current_turn += 1
	
	# Check for reinforcements on this turn
	check_for_reinforcements()
	
	# Start match/cascade process
	await get_tree().create_timer(0.3).timeout
	process_matches_and_gravity()

func check_for_reinforcements():
	"""Spawn any enemies scheduled for this turn"""
	var spawned_this_turn = []
	
	for i in range(enemy_spawn_queue.size() - 1, -1, -1):
		var spawn_data = enemy_spawn_queue[i]
		
		if spawn_data["turn"] <= current_turn:
			# Time to spawn this enemy
			if enemies.size() < 3:  # Only spawn if there's room
				var current_floor = GameManager.current_run.get("currentFloor", 1)
				var enemy = spawn_manager.create_enemy_instance(spawn_data["enemy"], current_floor)
				
				if enemy:
					# Randomize starting cooldown
					enemy["current_cooldown"] = randi_range(1, enemy["attack_cooldown"])
					enemies.append(enemy)
					spawned_this_turn.append(enemy["data"].enemy_name)
					show_reinforcement_notification(enemy["data"].enemy_name)
					
			
			# Remove from queue
			enemy_spawn_queue.remove_at(i)
	
	if spawned_this_turn.size() > 0:
		setup_enemies()  # Refresh enemy UI

# ========== MATCH PROCESSING ==========

func process_matches_and_gravity():
	"""Handle matching, damage, gravity in cascade"""
	is_processing_matches = true
	
	while true:
		# Apply gravity
		var blocks_fell = puzzle_grid.apply_gravity()
		if blocks_fell:
			await get_tree().create_timer(0.2).timeout
		
		# Find matches
		var matches = puzzle_grid.find_matches()
		
		if matches.size() == 0:
			break
		
		# Process each match
		for match_data in matches:
			var color = match_data["color"]
			var count = match_data["positions"].size()
			
			# Deal damage
			deal_damage_to_enemy(count)
			
			# Add power to matching character
			add_character_power(color, count)
		
		# Clear matched blocks
		puzzle_grid.clear_matches(matches)
		
		# Visual delay
		await get_tree().create_timer(0.3).timeout
	
	is_processing_matches = false
	
	# Check for character abilities
	await check_and_activate_abilities()
	
	# Check if all enemies dead
	if are_all_enemies_defeated():
		trigger_victory()
		return
	
	# Enemy turn happens EVERY player turn now
	await enemy_turn()
	
	# Spawn next piece
	is_player_turn = true
	spawn_player_piece()

# ========== DAMAGE & POWER ==========

func deal_damage_to_enemy(damage: int):
	"""Deal damage to the first active enemy"""
	if enemies.size() == 0:
		return
	
	var enemy = enemies[0]
	enemy["current_hp"] -= damage
	
	log_combat_event("🗡 You dealt %d damage to %s! (HP: %d/%d)" % [damage, enemy["data"].enemy_name, enemy["current_hp"], enemy["max_hp"]], Color(1, 0.5, 0.5))
	
	# Update enemy UI
	update_enemy_hp(0)
	
	# Check if enemy died
	if enemy["current_hp"] <= 0:
		enemy_defeated(0)

func add_character_power(color: String, blocks_cleared: int):
	"""Add power to character based on color"""
	# Map color to character slot
	var color_to_slot = {
		"red": 0,
		"blue": 1,
		"yellow": 2
	}
	
	if not color_to_slot.has(color):
		return  # Neutral color
	
	var slot = color_to_slot[color]
	if slot >= party.size():
		return
	
	var char_id = party[slot]
	var power_gain = blocks_cleared * 10  # 10 power per block
	
	character_power[char_id] = min(character_power[char_id] + power_gain, MAX_POWER)
	
	log_combat_event("%s gained %d power (%d/100)" % [char_id.capitalize(), power_gain, character_power[char_id]], Color(0.6, 0.8, 1))
	
	# Update character UI
	update_character_power(slot)

func enemy_defeated(enemy_index: int):
	"""Handle enemy death and spawn next from queue"""
	var enemy = enemies[enemy_index]
	log_combat_event("💀 %s was defeated!" % enemy["data"].enemy_name, Color(0.8, 0.8, 0.8))

	
	# Award coins
	GameManager.add_coins(enemy["data"].coin_reward)
	
	# Remove enemy
	enemies.remove_at(enemy_index)
	
	# Try to spawn next enemy from queue immediately
	if enemies.size() < 3 and enemy_spawn_queue.size() > 0:
		var spawn_data = enemy_spawn_queue[0]
		var current_floor = GameManager.current_run.get("currentFloor", 1)
		var new_enemy = spawn_manager.create_enemy_instance(spawn_data["enemy"], current_floor)
		
		if new_enemy:
			# Randomize starting cooldown for new enemy
			new_enemy["current_cooldown"] = randi_range(1, new_enemy["attack_cooldown"])
			enemies.append(new_enemy)
			enemy_spawn_queue.remove_at(0)
	
	# Refresh enemy UI
	setup_enemies()

func are_all_enemies_defeated() -> bool:
	"""Check if battle is won"""
	return enemies.size() == 0 and enemy_spawn_queue.size() == 0

# ========== CHARACTER ABILITIES ==========

func check_and_activate_abilities():
	"""Check each character for full power and activate"""
	var characters_at_full = []
	
	for i in range(party.size()):
		var char_id = party[i]
		if character_power[char_id] >= MAX_POWER:
			characters_at_full.append(char_id)
	
	if characters_at_full.size() == 0:
		return
	
	# Get synergy multiplier
	var multiplier = SynergyDatabase.get_synergy_multiplier(characters_at_full.size())
	var synergy_name = SynergyDatabase.get_synergy_name(characters_at_full)
	
	if synergy_name != "":
		log_combat_event("⚡ Synergy Activated: %s! (%.0f%% boost)" % [synergy_name, (multiplier - 1.0) * 100], Color(1, 1, 0.5))

	
	# Activate each character's ability
	for char_id in characters_at_full:
		await activate_character_ability(char_id, multiplier)
		character_power[char_id] = 0
		
		# Update UI
		var char_index = party.find(char_id)
		if char_index >= 0:
			update_character_power(char_index)

func activate_character_ability(char_id: String, multiplier: float):
	"""Activate a character's ability"""
	var char_data = CharacterDatabase.get_character(char_id)
	if not char_data:
		return
	
	var level = GameManager.get_character_level(char_id)
	var ability_value = char_data.get_ability_value(level) * multiplier
	
	log_combat_event("✨ %s uses %s! (%.0f power)" % [char_data.character_name, char_data.ability_name, ability_value], Color(1, 1, 0.6))

	
	# Execute ability
	match char_id:
		"knight":
			pass  # TODO: Shield system
		"wizard":
			deal_damage_to_enemy(int(ability_value))
			var blocks_to_clear = int(char_data.get_ability_secondary(level) * multiplier)
			clear_random_blocks(blocks_to_clear)
		"cleric":
			heal_party(int(ability_value))
		"rogue":
			deal_damage_to_enemy(int(ability_value))
	
	await get_tree().create_timer(0.5).timeout

func clear_random_blocks(count: int):
	"""Clear random blocks from grid"""
	var all_blocks = []
	
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			if puzzle_grid.get_block_color(x, y) != "":
				all_blocks.append(Vector2i(x, y))
	
	all_blocks.shuffle()
	for i in range(min(count, all_blocks.size())):
		var pos = all_blocks[i]
		puzzle_grid.remove_block(pos.x, pos.y)
	
	# Apply gravity after clearing blocks
	await get_tree().create_timer(0.2).timeout
	puzzle_grid.apply_gravity()
	
	# Apply gravity after clearing blocks
	await get_tree().create_timer(0.2).timeout
	puzzle_grid.apply_gravity()

func heal_party(amount: int):
	"""Heal the party"""
	var current_hp = GameManager.get_current_health()
	var max_hp = GameManager.get_max_health()
	var new_hp = min(current_hp + amount, max_hp)
	
	GameManager.modify_health(amount)
	log_combat_event("❤️ The party heals for %d HP! (%d/%d)" % [amount, new_hp, max_hp], Color(0.8, 1, 0.8))


# ========== ENEMY TURN ==========

func enemy_turn():
	"""Handle enemy actions"""
	for i in range(enemies.size()):
		var enemy = enemies[i]
		
		# Decrease cooldown
		enemy["current_cooldown"] -= 1
		
		if enemy["current_cooldown"] <= 0:
			await enemy_attack(enemy)
			enemy["current_cooldown"] = enemy["attack_cooldown"]
		else:
			await enemy_drop_block()
		
		# Update UI
		if i < enemy_ui.size():
			update_enemy_cooldown_display(enemy_ui[i], enemy)
	
	# Update slimes
	puzzle_grid.update_slimes()
	
	await get_tree().create_timer(0.5).timeout

func enemy_attack(enemy: Dictionary):
	"""Enemy performs attack"""
	var damage = enemy["data"].attack_damage
	GameManager.modify_health(-damage)
	
	log_combat_event("💥 %s attacks for %d damage!" % [enemy["data"].enemy_name, damage], Color(1, 0.4, 0.4))
	
	# TODO: Visual attack effect
	
	await get_tree().create_timer(0.3).timeout

func enemy_drop_block():
	"""Enemy drops a neutral block"""
	var piece_data = piece_factory.generate_neutral_piece()
	var spawn_x = randi() % puzzle_grid.GRID_WIDTH
	
	for i in range(piece_data["shape"].size()):
		var offset = piece_data["shape"][i]
		var pos = Vector2i(spawn_x + offset.x, offset.y)
		
		var final_y = pos.y
		while final_y < puzzle_grid.GRID_HEIGHT - 1 and puzzle_grid.is_empty(pos.x, final_y + 1):
			final_y += 1
		
		puzzle_grid.place_block(pos.x, final_y, piece_data["colors"][i])
	
	await get_tree().create_timer(0.2).timeout

# ========== GAME END ==========

func trigger_game_over():
	"""Handle game over"""
	game_over = true
	log_combat_event("💀 GAME OVER!", Color(1, 0.3, 0.3))
	
	GameManager.clear_battle_info()
	
	# TODO: Show game over screen
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/map_view.tscn")

func trigger_victory():
	"""Handle victory"""
	game_over = true
	log_combat_event("🎉 VICTORY! You have defeated all enemies!", Color(1, 1, 0.6))
	
	GameManager.clear_battle_info()
	
	# TODO: Show victory screen
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/map_view.tscn")

func log_combat_event(message: String, color: Color = Color.WHITE):
	"""Add a message to the combat log."""
	if combat_log:
		combat_log.push_color(color)
		combat_log.append_text(message + "\n")
		combat_log.pop()
	else:
		print("[CombatLog Missing] " + message)
