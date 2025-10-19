# BattleScene.gd - Main battle controller
extends Control

# Scene references
@onready var puzzle_grid: PuzzleGrid = $PuzzleGrid
@onready var character_panel = $CharacterPanel
@onready var enemy_panel = $EnemyPanel
@onready var next_piece_preview = $NextPiecePreview
@onready var game_over_panel = $GameOverPanel

# Game state
var current_piece: TetrisPiece = null
var next_piece_data: Dictionary = {}
var piece_factory: PieceFactory = null

var party: Array = []  # Character IDs
var enemies: Array = []  # Enemy data
var current_enemy_index: int = 0

var is_player_turn: bool = true
var is_processing_matches: bool = false
var game_over: bool = false

# Character power tracking
var character_power: Dictionary = {}  # {char_id: current_power}
const MAX_POWER: int = 100

# Enemy turn counter
var enemy_turn_timer: float = 0.0
var moves_until_enemy_action: int = 5  # Enemy acts every 5 player moves
var player_moves_made: int = 0

func _ready():
	# Initialize
	piece_factory = PieceFactory.new()
	add_child(piece_factory)
	
	# Load party and enemies from GameManager
	load_battle_data()
	
	# Setup UI
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
			current_piece.move_left()  # No parameter needed now
		elif event.is_action_pressed("ui_right"):
			current_piece.move_right()  # No parameter needed now
		elif event.is_action_pressed("ui_down"):
			# Start falling immediately
			current_piece.has_started_falling = true
			current_piece.is_falling = true
		elif event.is_action_pressed("ui_up"):
			current_piece.rotate_clockwise()  # No parameter needed now
		elif event.is_action_pressed("ui_accept"):
			current_piece.hard_drop()  # No parameter needed now

func load_battle_data():
	"""Load party and enemies from current run"""
	party = GameManager.get_current_party()
	
	# Set player colors based on party positions
	piece_factory.set_player_colors(party)
	
	# Initialize character power
	for char_id in party:
		character_power[char_id] = 0
	
	# Load enemies for this battle
	# For now, generate test enemies
	# TODO: Load from current map node
	enemies = generate_test_enemies()

func generate_test_enemies() -> Array:
	"""Generate test enemies for development"""
	var test_enemies = []
	
	# Create 3 normal enemies
	for i in range(3):
		var enemy_id = EnemyDatabase.get_random_normal_enemy()
		var enemy_data = EnemyDatabase.get_enemy(enemy_id)
		if enemy_data:
			test_enemies.append({
				"id": enemy_id,
				"data": enemy_data,
				"current_hp": enemy_data.base_health,
				"max_hp": enemy_data.base_health,
				"attack_cooldown": enemy_data.attack_frequency,
				"current_cooldown": enemy_data.attack_frequency
			})
	
	return test_enemies

func setup_characters():
	"""Create character UI panels"""
	# TODO: Create character portraits, names, power bars
	pass

func setup_enemies():
	"""Create enemy UI panels"""
	# TODO: Create enemy displays, health bars
	pass

func spawn_player_piece():
	"""Spawn a new piece for the player"""
	if game_over:
		return
	
	if puzzle_grid.is_grid_full():
		trigger_game_over()
		return
	
	var spawn_x = puzzle_grid.find_safe_spawn_column()
	
	current_piece = TetrisPiece.new()
	current_piece.setup_piece(next_piece_data["shape"], next_piece_data["colors"], spawn_x)
	current_piece.piece_locked.connect(_on_piece_locked)
	
	# Add as child of grid, not BattleScene
	puzzle_grid.add_child(current_piece)
	# No position needed - relative to grid now
	
	next_piece_data = piece_factory.generate_piece()
	update_next_piece_preview()
	
func update_next_piece_preview():
	"""Update the next piece preview display"""
	# TODO: Show next piece visually
	pass

func _on_piece_locked():
	"""Handle when piece locks into grid"""
	is_player_turn = false
	current_piece.queue_free()
	current_piece = null
	
	player_moves_made += 1
	
	# Start match/cascade process
	await get_tree().create_timer(0.3).timeout
	process_matches_and_gravity()

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
			# No more matches
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
	if are_all_enemies_dead():
		trigger_victory()
		return
	
	# Enemy turn
	if player_moves_made >= moves_until_enemy_action:
		player_moves_made = 0
		await enemy_turn()
	
	# Spawn next piece
	is_player_turn = true
	spawn_player_piece()

func deal_damage_to_enemy(damage: int):
	"""Deal damage to the top enemy"""
	if enemies.size() == 0:
		return
	
	var enemy = enemies[0]
	enemy["current_hp"] -= damage
	
	print("Dealt %d damage to %s (HP: %d/%d)" % [damage, enemy["data"].enemy_name, enemy["current_hp"], enemy["max_hp"]])
	
	# Update enemy UI
	# TODO: Update health bar
	
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
	
	print("%s gained %d power (%d/100)" % [char_id, power_gain, character_power[char_id]])
	
	# Update character UI
	# TODO: Update power bar

func enemy_defeated(enemy_index: int):
	"""Handle enemy death"""
	var enemy = enemies[enemy_index]
	print("%s defeated!" % enemy["data"].enemy_name)
	
	# Award coins
	GameManager.add_coins(enemy["data"].coin_reward)
	
	# Remove enemy
	enemies.remove_at(enemy_index)
	
	# TODO: Remove enemy UI
	
	# Spawn next enemy if available
	# TODO: Load next wave/enemy

func are_all_enemies_dead() -> bool:
	"""Check if battle is won"""
	return enemies.size() == 0

func check_and_activate_abilities():
	"""Check each character for full power and activate"""
	var characters_at_full = []
	
	# Check which characters are at full power
	for char_id in party:
		if character_power[char_id] >= MAX_POWER:
			characters_at_full.append(char_id)
	
	if characters_at_full.size() == 0:
		return
	
	# Get synergy multiplier
	var multiplier = SynergyDatabase.get_synergy_multiplier(characters_at_full.size())
	var synergy_name = SynergyDatabase.get_synergy_name(characters_at_full)
	
	if synergy_name != "":
		print("SYNERGY: %s! (%.0f%% boost)" % [synergy_name, (multiplier - 1.0) * 100])
	
	# Activate each character's ability in order
	for char_id in characters_at_full:
		await activate_character_ability(char_id, multiplier)
		character_power[char_id] = 0  # Reset power
		# TODO: Update power bar

func activate_character_ability(char_id: String, multiplier: float):
	"""Activate a character's ability"""
	var char_data = CharacterDatabase.get_character(char_id)
	if not char_data:
		return
	
	var level = GameManager.get_character_level(char_id)
	var ability_value = char_data.get_ability_value(level) * multiplier
	
	print("%s uses %s! (Power: %.0f)" % [char_data.character_name, char_data.ability_name, ability_value])
	
	# Execute ability based on character
	match char_id:
		"knight":
			# Shield Wall - absorb damage
			pass  # TODO: Implement shield system
		"wizard":
			# Meteor Storm - damage + clear blocks
			deal_damage_to_enemy(int(ability_value))
			var blocks_to_clear = int(char_data.get_ability_secondary(level) * multiplier)
			clear_random_blocks(blocks_to_clear)
		"cleric":
			# Healing Light - heal party
			heal_party(int(ability_value))
		"rogue":
			# Assassinate - single target damage
			deal_damage_to_enemy(int(ability_value))
		# TODO: Implement other character abilities
	
	await get_tree().create_timer(0.5).timeout

func clear_random_blocks(count: int):
	"""Clear random blocks from grid (Wizard ability)"""
	var all_blocks = []
	
	# Find all blocks
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			if puzzle_grid.get_block_color(x, y) != "":
				all_blocks.append(Vector2i(x, y))
	
	# Clear random ones
	all_blocks.shuffle()
	for i in range(min(count, all_blocks.size())):
		var pos = all_blocks[i]
		puzzle_grid.remove_block(pos.x, pos.y)

func heal_party(amount: int):
	"""Heal the party (Cleric ability)"""
	var current_hp = GameManager.get_current_health()
	var max_hp = GameManager.get_max_health()
	var new_hp = min(current_hp + amount, max_hp)
	
	GameManager.modify_health(amount)
	print("Party healed for %d HP! (%d/%d)" % [amount, new_hp, max_hp])

func enemy_turn():
	"""Handle enemy actions"""
	print("=== ENEMY TURN ===")
	
	for enemy in enemies:
		# Decrease cooldown
		enemy["current_cooldown"] -= 1
		
		if enemy["current_cooldown"] <= 0:
			# Enemy attacks
			await enemy_attack(enemy)
			enemy["current_cooldown"] = enemy["attack_cooldown"]
		else:
			# Enemy drops neutral block
			await enemy_drop_block()
	
	# Update slimes
	puzzle_grid.update_slimes()
	
	await get_tree().create_timer(0.5).timeout

func enemy_attack(enemy: Dictionary):
	"""Enemy performs attack"""
	var damage = enemy["data"].attack_damage
	GameManager.modify_health(-damage)
	
	print("%s attacks for %d damage!" % [enemy["data"].enemy_name, damage])
	
	# TODO: Visual attack effect
	# TODO: Check if party died
	
	await get_tree().create_timer(0.3).timeout

func enemy_drop_block():
	"""Enemy drops a neutral block"""
	var piece_data = piece_factory.generate_neutral_piece()
	var spawn_x = randi() % puzzle_grid.GRID_WIDTH
	
	# Place directly on grid (instant drop)
	for i in range(piece_data["shape"].size()):
		var offset = piece_data["shape"][i]
		var pos = Vector2i(spawn_x + offset.x, offset.y)
		
		# Drop it down
		var final_y = pos.y
		while final_y < puzzle_grid.GRID_HEIGHT - 1 and puzzle_grid.is_empty(pos.x, final_y + 1):
			final_y += 1
		
		puzzle_grid.place_block(pos.x, final_y, piece_data["colors"][i])
	
	await get_tree().create_timer(0.2).timeout

func trigger_game_over():
	"""Handle game over"""
	game_over = true
	print("GAME OVER!")
	
	# TODO: Show game over screen
	# Return to map
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func trigger_victory():
	"""Handle victory"""
	game_over = true
	print("VICTORY!")
	
	# Award XP
	for char_id in party:
		var pending_xp = GameManager.current_run["pendingXP"].get(char_id, 0)
		# XP was accumulated during battle, will be applied on run completion
	
	# TODO: Show victory screen
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")
