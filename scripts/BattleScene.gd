# BattleScene.gd - COMPLETE WITH FULL UI
class_name BattleScene
extends Control

@onready var pause_menu: Panel = null
var is_paused: bool = false
var abilities_used_this_turn: int = 0
var current_combo: int = 0
var is_boss_battle: bool = false
var enemy_special_ability_counters: Dictionary = {}
var is_placing_rune: bool = false
var rune_placement_data: Dictionary = {}
var rune_preview_sprite: Sprite2D = null

# Scene references
@onready var puzzle_grid: PuzzleGrid = $PuzzleGrid
@onready var next_piece_preview = $NextPiecePreview
@onready var game_over_panel = $GameOverPanel
@onready var combat_log: RichTextLabel = $CombatLog
@onready var party_health_bar: Panel = $CharacterPanel/PartyHealthBar

# Character UI - Left side
@onready var character_panel = $CharacterPanel
@onready var char1_container = $CharacterPanel/Character1
@onready var char2_container = $CharacterPanel/Character2
@onready var char3_container = $CharacterPanel/Character3

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

# Combat log
var combat_log_lines: Array = []
const MAX_LOG_LINES: int = 15

# Enemy turn counter
var player_moves_made: int = 0

# Relic effects
var active_relics: Array = []
var combo_multiplier: float = 1.0
var coin_multiplier: float = 1.0
var has_block_converter: bool = false
var has_time_warper: bool = false
var enemy_turns_per_player: int = 1  # Changed by time warper
var player_turns_taken: int = 0

var damage_multiplier: float = 1.0
var power_gain_multiplier: float = 1.0
var permanent_damage_bonus: int = 0

var bonus_damage: int = 0
var starting_power_bonus: int = 0

var bound_characters: Dictionary = {}  # Track which characters are bound by Mummy

func _ready():
	# Initialize
	piece_factory = PieceFactory.new()
	add_child(piece_factory)
	
	spawn_manager = EnemySpawnManager.new()
	add_child(spawn_manager)
	create_background_particles()
	create_pause_menu()
	# Load battle data
	load_battle_data()
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var difficulty = GameManager.current_run.get("currentFloor", 1)
	var layout = PuzzleGridDatabase.get_random_layout(difficulty)
	if layout:
		puzzle_grid.setup_layout(layout)
	else:
		# Fallback: setup empty grid
		puzzle_grid.initialize_grid()
		puzzle_grid.draw_grid_boundary()
	
	# Setup UI
	setup_party_health()
	setup_characters()
	setup_enemies()
	setup_combat_log()
	load_relics()
	
	# Load power from previous battle
	load_character_power()
	
	# Generate first pieces
	next_piece_data = piece_factory.generate_piece()
	if is_boss_battle:
		AudioManager.play_music("boss_battle", 2.0)  # 2 second fade
	else:
		AudioManager.play_music("battle", 1.5)  # 1.5 second fade
	# Start game
	spawn_player_piece()


# ========== COMBAT LOG ==========

func setup_combat_log():
	"""Initialize combat log"""
	if combat_log:
		combat_log.clear()
		add_to_combat_log("=== BATTLE START ===")
		add_to_combat_log("Pattern: %s" % GameManager.get_battle_info().get("pattern_name", "Unknown"))


func start_rune_placement(rune_type: String, data: Dictionary):
	"""Begin rune placement mode"""
	is_placing_rune = true
	rune_placement_data = {
		"type": rune_type,
		"data": data
	}
	
	# Disable piece movement during placement
	if current_piece:
		current_piece.can_move = false
	
	# Create preview sprite
	create_rune_preview(rune_type)
	
	# Show instruction
	add_to_combat_log("📍 Click on the grid to place %s!" % get_rune_name(rune_type))

func create_rune_preview(rune_type: String):
	"""Create a preview sprite that follows the mouse"""
	rune_preview_sprite = Sprite2D.new()
	rune_preview_sprite.z_index = 100
	
	# Create a 3x3 colored square for the rune preview
	var size = puzzle_grid.CELL_SIZE * 3
	var color = get_rune_color(rune_type)
	rune_preview_sprite.texture = create_rune_texture(size, color)
	rune_preview_sprite.modulate = Color(color.r, color.g, color.b, 0.5)  # Semi-transparent
	
	puzzle_grid.add_child(rune_preview_sprite)

func create_rune_texture(size: int, color: Color) -> ImageTexture:
	"""Create a colored square texture with border"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Fill with color
	image.fill(color)
	
	# Draw border
	var border_color = color.lightened(0.3)
	for i in range(size):
		# Top and bottom borders
		image.set_pixel(i, 0, border_color)
		image.set_pixel(i, 1, border_color)
		image.set_pixel(i, size - 1, border_color)
		image.set_pixel(i, size - 2, border_color)
		
		# Left and right borders
		image.set_pixel(0, i, border_color)
		image.set_pixel(1, i, border_color)
		image.set_pixel(size - 1, i, border_color)
		image.set_pixel(size - 2, i, border_color)
	
	return ImageTexture.create_from_image(image)

func get_rune_name(rune_type: String) -> String:
	"""Get display name for rune type"""
	match rune_type:
		"rune_trap":
			return "Rune Trap"
		"healing_grove":
			return "Healing Grove"
		_:
			return "Rune"

func _process(delta):
	# Update rune preview position if placing
	if is_placing_rune and rune_preview_sprite:
		var mouse_pos = puzzle_grid.get_local_mouse_position()
		
		# Snap to grid (center of 3x3 area)
		var grid_x = int(mouse_pos.x / puzzle_grid.CELL_SIZE)
		var grid_y = int(mouse_pos.y / puzzle_grid.CELL_SIZE)
		
		# Clamp to valid positions (keeping 3x3 area within bounds)
		grid_x = clamp(grid_x, 1, puzzle_grid.GRID_WIDTH - 2)
		grid_y = clamp(grid_y, 1, puzzle_grid.GRID_HEIGHT - 2)
		
		# Center the preview sprite
		rune_preview_sprite.position = Vector2(
			grid_x * puzzle_grid.CELL_SIZE + puzzle_grid.CELL_SIZE / 2,
			grid_y * puzzle_grid.CELL_SIZE + puzzle_grid.CELL_SIZE / 2
		)
		

func get_rune_color(rune_type: String) -> Color:
	"""Get color for rune type"""
	match rune_type:
		"rune_trap":
			return Color(0.9, 0.3, 0.1, 1)  # Red-orange for damage
		"healing_grove":
			return Color(0.2, 0.8, 0.3, 1)  # Green for healing
		_:
			return Color(0.5, 0.5, 0.5, 1)

func add_to_combat_log(message: String):
	"""Add a message to the combat log with highlight animation"""
	if not combat_log:
		return
	
	# Add to lines array
	combat_log_lines.append(message)
	
	# Keep only last MAX_LOG_LINES
	if combat_log_lines.size() > MAX_LOG_LINES:
		combat_log_lines.remove_at(0)
	
	# Update text display with newest line highlighted
	var log_text = ""
	for i in range(combat_log_lines.size()):
		if i == combat_log_lines.size() - 1:
			# Highlight newest line
			log_text += "[color=yellow]" + combat_log_lines[i] + "[/color]\n"
		else:
			log_text += combat_log_lines[i] + "\n"
	
	combat_log.text = log_text
	
	# Auto-scroll to bottom
	if combat_log is RichTextLabel:
		combat_log.scroll_to_line(combat_log.get_line_count() - 1)

func load_relics():
	"""Load and apply relics and temp buffs for this battle"""
	active_relics = GameManager.current_run.get("relics", [])
	AchievementManager.track_relics_in_run(active_relics.size())
	
	for relic in active_relics:
		match relic["type"]:
			"combo_boost":
				combo_multiplier = relic["data"].get("multiplier", 1.0)
			
			"coin_boost":
				coin_multiplier = relic["data"].get("multiplier", 1.0)
			
			"block_converter":
				has_block_converter = true
				piece_factory.enable_character_colors_in_neutral()
			
			"time_warper":
				has_time_warper = true
				enemy_turns_per_player = 2
			
			"starting_power_bonus":
				# Meditation Beads
				var power_bonus = relic["data"].get("power_bonus", 20)
				for char_id in party:
					character_power[char_id] = min(character_power[char_id] + power_bonus, MAX_POWER)
			
			"slow_enemies":
				# Hourglass of Patience - applied when enemies spawn
				pass
			
			"combo_start":
				# Chain Reaction - handled in process_matches_and_gravity
				pass
			
			"glass_cannon":
				# Applied in deal_damage_to_enemy and enemy_attack
				pass
			
			"damage_reduction":
				# Adamantine Armor - applied in enemy_attack
				pass
			
			"passive_regen":
				# Regeneration Ring - applied in enemy_turn
				pass
	
	# Load temporary buffs
	load_temp_buffs()

func load_temp_buffs():
	"""Load and apply temporary buffs from rest sites and events"""
	var temp_buffs = GameManager.current_run.get("temp_buffs", [])
	var buffs_to_remove = []
	
	for i in range(temp_buffs.size()):
		var buff = temp_buffs[i]
		
		match buff["type"]:
			"starting_power":
				starting_power_bonus = buff.get("amount", 0)
				add_to_combat_log("✨ Divine blessing! Starting with %d%% power!" % starting_power_bonus)
			
			"bonus_damage":
				bonus_damage = buff.get("amount", 0)
				add_to_combat_log("⚔️ Sharpened blades! +%d damage to all matches!" % bonus_damage)
			
			"damage_multiplier":
				damage_multiplier = buff.get("multiplier", 1.0)
				if damage_multiplier > 1.0:
					add_to_combat_log("💥 Damage multiplier: %.0f%%!" % (damage_multiplier * 100))
				else:
					add_to_combat_log("⚠️ Damage reduced to %.0f%%" % (damage_multiplier * 100))
			
			"power_multiplier":
				power_gain_multiplier = buff.get("multiplier", 1.0)
				if power_gain_multiplier > 1.0:
					add_to_combat_log("⚡ Power gain multiplier: %.0f%%!" % (power_gain_multiplier * 100))
				else:
					add_to_combat_log("⚠️ Power gain reduced to %.0f%%" % (power_gain_multiplier * 100))
			
			"coin_multiplier":
				var mult = buff.get("multiplier", 1.0)
				if mult != coin_multiplier:  # Avoid stacking
					coin_multiplier = mult
				if mult > 1.0:
					add_to_combat_log("💰 Coin bonus: +%.0f%%!" % ((mult - 1.0) * 100))
				else:
					add_to_combat_log("💸 Coin penalty: -%.0f%%" % ((1.0 - mult) * 100))
		
		# Decrease duration
		buff["duration"] -= 1
		if buff["duration"] <= 0:
			buffs_to_remove.append(i)
	
	# Remove expired buffs
	for i in range(buffs_to_remove.size() - 1, -1, -1):
		temp_buffs.remove_at(buffs_to_remove[i])
	
	# Load permanent modifiers from events
	power_gain_multiplier *= GameManager.current_run.get("power_gain_modifier", 1.0)
	permanent_damage_bonus = GameManager.current_run.get("permanent_damage_bonus", 0)
	
	if permanent_damage_bonus > 0:
		add_to_combat_log("⚔️ Permanent damage bonus: +%d!" % permanent_damage_bonus)
	
	GameManager.current_run["temp_buffs"] = temp_buffs
	GameManager.save_game()
	
func get_power_gain_bonus(char_id: String) -> int:
	"""Get bonus power gain for character from relics"""
	var bonus = 0
	for relic in active_relics:
		if relic["type"] == "power_gain" and relic["data"].get("character") == char_id:
			bonus += relic["data"].get("bonus", 0)
	return bonus

func get_power_converter_bonus(char_id: String, is_neutral: bool) -> int:
	"""Get power from matching neutral blocks"""
	if not is_neutral:
		return 0
	
	var bonus = 0
	for relic in active_relics:
		if relic["type"] == "power_converter" and relic["data"].get("character") == char_id:
			bonus += relic["data"].get("power_per_block", 0)
	return bonus

func get_ability_multiplier(char_id: String) -> float:
	"""Get ability boost multiplier for character"""
	var multiplier = 1.0
	for relic in active_relics:
		if relic["type"] == "ability_boost" and relic["data"].get("character") == char_id:
			multiplier *= relic["data"].get("multiplier", 1.0)
	return multiplier

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_pause()

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
	# Handle rune placement
	if is_placing_rune and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = puzzle_grid.get_local_mouse_position()
			
			# Convert to grid coordinates
			var grid_x = int(mouse_pos.x / puzzle_grid.CELL_SIZE)
			var grid_y = int(mouse_pos.y / puzzle_grid.CELL_SIZE)
			
			# Check if valid position (within bounds for 3x3 area)
			if grid_x >= 1 and grid_x < puzzle_grid.GRID_WIDTH - 1 and \
			   grid_y >= 1 and grid_y < puzzle_grid.GRID_HEIGHT - 1:
				place_rune_at(grid_x, grid_y)
			else:
				add_to_combat_log("❌ Invalid placement position!")
		
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel placement
			cancel_rune_placement()
		
		return  # Consume the input event

func place_rune_at(center_x: int, center_y: int):
	"""Place the rune at the specified grid position"""
	var rune_type = rune_placement_data["type"]
	var data = rune_placement_data["data"]
	
	# Create the rune zone
	var rune_zone = {
		"type": rune_type,
		"center": Vector2i(center_x, center_y),
		"size": 3,  # 3x3 area
		"data": data
	}
	
	# Add to active buffs
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	match rune_type:
		"rune_trap":
			GameManager.current_run["active_buffs"].append({
				"type": "rune_trap_zone",
				"center": Vector2i(center_x, center_y),
				"damage_per_block": data["damage_per_block"],
				"turns_remaining": data["duration"]
			})
			add_to_combat_log("🔥 Rune Trap placed at (%d, %d)!" % [center_x, center_y])
		
		"healing_grove":
			GameManager.current_run["active_buffs"].append({
				"type": "healing_grove_zone",
				"center": Vector2i(center_x, center_y),
				"heal_per_block": data["heal_per_block"],
				"turns_remaining": data["duration"]
			})
			add_to_combat_log("🌳 Healing Grove placed at (%d, %d)!" % [center_x, center_y])
	
	GameManager.save_game()
	
	# Create persistent visual indicator on the grid
	create_rune_visual(center_x, center_y, rune_type)
	
	# End placement mode
	end_rune_placement()

func create_rune_visual(center_x: int, center_y: int, rune_type: String):
	"""Create a persistent visual indicator for the rune zone"""
	var zone_visual = Node2D.new()
	zone_visual.name = "RuneZone_%d_%d" % [center_x, center_y]
	zone_visual.z_index = -1  # Behind blocks but above grid
	
	# Create 3x3 overlay
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var x = center_x + dx
			var y = center_y + dy
			
			if puzzle_grid.is_valid_position(x, y):
				var cell_sprite = Sprite2D.new()
				cell_sprite.position = Vector2(
					x * puzzle_grid.CELL_SIZE + puzzle_grid.CELL_SIZE / 2,
					y * puzzle_grid.CELL_SIZE + puzzle_grid.CELL_SIZE / 2
				)
				
				var color = get_rune_color(rune_type)
				cell_sprite.texture = create_colored_texture(color, puzzle_grid.CELL_SIZE - 4)
				cell_sprite.modulate = Color(color.r, color.g, color.b, 0.3)  # Very transparent
				
				zone_visual.add_child(cell_sprite)
	
	# Add pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(zone_visual, "modulate:a", 0.5, 1.0)
	tween.tween_property(zone_visual, "modulate:a", 1.0, 1.0)
	
	puzzle_grid.add_child(zone_visual)

func create_colored_texture(color: Color, size: int) -> ImageTexture:
	"""Create a simple colored square texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func end_rune_placement():
	"""End rune placement mode"""
	is_placing_rune = false
	rune_placement_data = {}
	
	# Remove preview sprite
	if rune_preview_sprite:
		rune_preview_sprite.queue_free()
		rune_preview_sprite = null
	
	# Re-enable piece movement
	if current_piece:
		current_piece.can_move = true

func cancel_rune_placement():
	"""Cancel rune placement"""
	add_to_combat_log("❌ Rune placement cancelled")
	end_rune_placement()

func count_blocks_in_zone(center: Vector2i, size: int) -> int:
	"""Count number of blocks in a zone"""
	var count = 0
	var radius = int(size / 2)
	
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x = center.x + dx
			var y = center.y + dy
			
			if puzzle_grid.is_valid_position(x, y):
				if puzzle_grid.get_block_color(x, y) != "":
					count += 1
	
	return count
	
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
	is_boss_battle = battle_info.get("is_boss", false)
	var is_elite_battle = battle_info.get("is_elite", false)
	var difficulty_level = battle_info.get("difficulty", 1)
	
	if is_boss_battle:
		
		setup_boss_battle()
	else:
		
		# Setup normal battle spawn pattern
		var battle_data = spawn_manager.setup_battle(is_elite_battle, difficulty_level)
		
		# Spawn initial enemies with RANDOMIZED cooldowns
		for enemy_type in battle_data["initial_enemies"]:
			var enemy = spawn_manager.create_enemy_instance(enemy_type, difficulty_level)
			if enemy:
				enemy["current_cooldown"] = randi_range(1, enemy["attack_cooldown"])
				enemies.append(enemy)
				
		# Store spawn queue
		enemy_spawn_queue = battle_data["spawn_queue"].duplicate()
		
		if enemy_spawn_queue.size() > 0:			
			for spawn_data in enemy_spawn_queue:
				var enemy_name = spawn_manager.get_enemy_name(spawn_data["enemy"])
				

func setup_boss_battle():
	"""Setup a boss battle"""
	var objective = GameManager.current_run.get("objective", {})
	var boss_id = objective.get("boss_id", "dragon_boss")
	var boss_data = EnemyDatabase.get_enemy(boss_id)
	
	if not boss_data:
	
		return
	
	var difficulty = GameManager.current_run.get("currentFloor", 1)
	
	# Create boss enemy instance
	var boss = {
		"id": boss_id,
		"data": boss_data,
		"current_hp": boss_data.get_health_for_floor(difficulty),
		"max_hp": boss_data.get_health_for_floor(difficulty),
		"attack_cooldown": boss_data.attack_frequency,
		"current_cooldown": boss_data.attack_frequency
	}
	
	enemies.append(boss)
	enemy_spawn_queue = []  # No reinforcements for boss
	
	
	add_to_combat_log("=== BOSS BATTLE ===")
	add_to_combat_log("Face %s!" % boss_data.enemy_name)

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
	if float(current_hp) / float(max_hp) <= 0.3 and current_hp > 0:
		AudioManager.start_low_health_warning()
	else:
		AudioManager.stop_low_health_warning()
	# Check for game over
	if current_hp <= 0:
		trigger_game_over()

func setup_characters():
	"""Create character UI panels"""
	character_ui = []
	
	# Define slot colors (matches block colors)
	var slot_colors = [
		Color("#E63946"),  # Red - Slot 0
		Color("#457B9D"),  # Blue - Slot 1
		Color("#F1C40F")   # Yellow - Slot 2
	]

	
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
		
		if not portrait or not name_label or not class_label or not power_bar or not power_label:
			
			continue
		
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
		
		# Set power bar color based on SLOT, not character color
		var slot_color = slot_colors[i]
		ui["power_bar"].modulate = slot_color
		ui["power_bar"].value = 0
		ui["power_label"].text = "0/100"
		
		
		
		# Show container
		container.visible = true
		
		character_ui.append(ui)
		
	
	# Hide unused character slots
	for i in range(party.size(), 3):
		containers[i].visible = false
			
# Add this new function
func load_character_power():
	"""Load character power from previous battle"""
	var saved_power = GameManager.current_run.get("character_power", {})
	
	for char_id in party:
		if saved_power.has(char_id):
			character_power[char_id] = saved_power[char_id]
			var slot_index = party.find(char_id)
			if slot_index >= 0:
				update_character_power(slot_index)
				
		else:
			character_power[char_id] = 0
	
	# Apply starting power bonus from buffs
	if starting_power_bonus > 0:
		for char_id in party:
			character_power[char_id] = min(character_power[char_id] + starting_power_bonus, MAX_POWER)
		
		for i in range(character_ui.size()):
			update_character_power(i)


func update_character_power(char_index: int):
	"""Update character power bar display"""
	if char_index >= character_ui.size():
		return
	
	var char_id = party[char_index]
	var power = character_power[char_id]
	var ui = character_ui[char_index]
	
	ui["power_bar"].value = power
	ui["power_label"].text = "%d/100" % power
	
	# Keep slot-based color (don't change modulate on power level)
	# Visual effect when at full power - make it brighter
	var slot_colors = [
		Color("#E63946"),  # Red
		Color("#457B9D"),  # Blue
		Color("#F1C40F")   # Yellow
	]
	
	if power >= MAX_POWER:
		# Brighten the color at full power AND PULSE
		ui["power_bar"].modulate = slot_colors[char_index].lightened(0.3)
		
		# Add pulsing animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(ui["power_bar"], "modulate", slot_colors[char_index].lightened(0.5), 0.5)
		tween.tween_property(ui["power_bar"], "modulate", slot_colors[char_index].lightened(0.3), 0.5)
	else:
		# Normal slot color
		ui["power_bar"].modulate = slot_colors[char_index]
		
		# Flash on power gain
		var tween = create_tween()
		tween.tween_property(ui["power_bar"], "modulate", slot_colors[char_index].lightened(0.4), 0.1)
		tween.tween_property(ui["power_bar"], "modulate", slot_colors[char_index], 0.2)
		

# ========== ENEMY UI ==========

func setup_enemies():
	"""Create/update enemy UI panels"""
	enemy_ui = []
	
	var containers = [enemy1_container, enemy2_container, enemy3_container]
	
	# Clear all containers first
	for container in containers:
		container.visible = false

	# Check for Hourglass of Patience relic
	var cooldown_bonus = 0
	for relic in active_relics:
		if relic["type"] == "slow_enemies":
			cooldown_bonus = relic["data"].get("cooldown_bonus", 1)
			break
	# Setup active enemies
	for i in range(enemies.size()):
		var enemy = enemies[i]
		
		# Apply cooldown bonus if not already applied
		if cooldown_bonus > 0 and not enemy.get("hourglass_applied", false):
			enemy["attack_cooldown"] += cooldown_bonus
			enemy["current_cooldown"] += cooldown_bonus
			enemy["hourglass_applied"] = true
		
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
		
		if not portrait or not name_label or not type_label or not hp_bar or not hp_label or not cooldown_label:
			continue
		
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
	
	# Update enemy count display
	update_enemy_count_display()

func update_enemy_hp(enemy_index: int):
	"""Update enemy HP bar display with smooth animation and color change"""
	if enemy_index >= enemy_ui.size():
		return
	
	var enemy = enemies[enemy_index]
	var ui = enemy_ui[enemy_index]
	
	# Calculate HP percentage
	var hp_percent = float(enemy["current_hp"]) / float(enemy["max_hp"])
	
	# Change color based on HP
	var bar_color = Color.GREEN
	if hp_percent < 0.3:
		bar_color = Color.RED
	elif hp_percent < 0.6:
		bar_color = Color.YELLOW
	
	# Animate HP bar draining and color change
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ui["hp_bar"], "value", enemy["current_hp"], 0.3)
	tween.tween_property(ui["hp_bar"].get_theme_stylebox("fill"), "bg_color", bar_color, 0.3)
	
	ui["hp_label"].text = "%d/%d" % [enemy["current_hp"], enemy["max_hp"]]
	
	# Flash red when damaged
	var flash_tween = create_tween()
	flash_tween.tween_property(ui["hp_bar"], "modulate", Color.RED, 0.1)
	flash_tween.tween_property(ui["hp_bar"], "modulate", Color.WHITE, 0.2)

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

# ========== PIECE SPAWNING ==========

func spawn_player_piece():
	"""Spawn a new piece for the player"""
	if game_over:
		return
	
	if puzzle_grid.is_grid_full():
		trigger_game_over()
		return
	
	# Always spawn at center of grid (top)
	var spawn_x = int(puzzle_grid.GRID_WIDTH / 2)  # Middle column
	
	current_piece = TetrisPiece.new()
	current_piece.setup_piece(next_piece_data["shape"], next_piece_data["colors"], spawn_x)
	current_piece.piece_locked.connect(_on_piece_locked)
	
	puzzle_grid.add_child(current_piece)
	
	next_piece_data = piece_factory.generate_piece()



# ========== PIECE LOCKING & TURN FLOW ==========

func _on_piece_locked():
	"""Handle when piece locks into grid"""
	is_player_turn = false
	current_piece.queue_free()
	current_piece = null
	abilities_used_this_turn = 0
	player_moves_made += 1
	current_turn += 1
	
	# Check for Rainbow Prism (spawn wild block every 3 turns)
	for relic in active_relics:
		if relic["type"] == "wild_blocks":
			var frequency = relic["data"].get("spawn_frequency", 3)
			if current_turn % frequency == 0:
				spawn_wild_block()
				add_to_combat_log("🌈 Rainbow Prism spawned a wild block!")
			break

	# Check for reinforcements on this turn
	check_for_reinforcements()
	
	# Start match/cascade process
	await get_tree().create_timer(0.3).timeout
	process_matches_and_gravity()

func spawn_wild_block():
	"""Spawn a wild block that can match any color"""
	var valid_columns = []
	
	# Find columns that have room
	for x in range(puzzle_grid.GRID_WIDTH):
		if puzzle_grid.is_empty(x, 0):
			valid_columns.append(x)
	
	if valid_columns.size() == 0:
		return
	
	var spawn_x = valid_columns[randi() % valid_columns.size()]
	# Wild blocks use "purple" color or a special marker
	puzzle_grid.place_block(spawn_x, 0, "purple")  # You'll need to handle purple as wild in matching logic

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
		setup_enemies()  # Refresh enemy UI and count

# ========== MATCH PROCESSING ==========

func process_matches_and_gravity():
	"""Handle matching, damage, gravity in cascade"""
	is_processing_matches = true
	
	# Check for Chain Reaction relic (start combo at 2)
	var starting_combo = 0
	for relic in active_relics:
		if relic["type"] == "combo_start":
			starting_combo = relic["data"].get("starting_combo", 2) - 1
			break
	
	current_combo = starting_combo
	
	# Reset first strike flag
	set_meta("first_strike_used", false)
	
	while true:
		# Apply gravity WITH ANIMATION
		var blocks_fell = await puzzle_grid.apply_gravity_animated()
		if blocks_fell:
			await get_tree().create_timer(1).timeout
		
		# Find matches
		var matches = puzzle_grid.find_matches()
		
		if matches.size() == 0:
			break
		
		# Check Block Breaker relic
		for match_data in matches:
			check_block_breaker_clear(match_data["positions"])
		
		# Group matches by color to detect multi-color matches on same drop
		var colors_matched = []
		for match_data in matches:
			if not colors_matched.has(match_data["color"]):
				colors_matched.append(match_data["color"])
		
		# If multiple different colors matched, increase combo by number of colors - 1
		# This rewards matching multiple colors at once
		if colors_matched.size() > 1:
			current_combo += colors_matched.size()
			add_to_combat_log("🎯 Multi-color match! %d colors cleared!" % colors_matched.size())
		else:
			current_combo += 1
		
		# Play match sound with pitch variation
		if current_combo >= 2:
			AudioManager.play_combo_sound(current_combo)
		AudioManager.play_match_sound(current_combo)
		
		# Calculate combo multiplier: 1.0, 1.5, 2.0, 2.5, etc.
		var combo_damage_multiplier = 1.0 + (current_combo - 1) * 0.5
		
		# Check for All or Nothing relic
		var has_combo_penalty = false
		for relic in active_relics:
			if relic["type"] == "combo_or_bust":
				if current_combo >= 3:
					combo_damage_multiplier *= relic["data"].get("combo_multiplier", 2.0)
					add_to_combat_log("🎲 All or Nothing! Combo damage DOUBLED!")
				has_combo_penalty = true
				break

		# Update combo display
		update_combo_display()
		
		# ANIMATE MATCHED BLOCKS BEFORE CLEARING
		await puzzle_grid.animate_matched_blocks(matches)
		
		# Process each match
		for match_data in matches:
			var color = match_data["color"]
			var count = match_data["positions"].size()
			
			# Calculate base damage
			var base_damage = count
			
			# Check for Perfectionist's Crown damage bonus
			for relic in active_relics:
				if relic["type"] == "perfect_match":
					if count == relic["data"].get("exact_blocks", 5):
						base_damage += relic["data"].get("bonus_damage", 5)
						break

			# Apply combo multiplier
			var damage = int(base_damage * combo_damage_multiplier)
			
			# Check for All or Nothing solo penalty
			if has_combo_penalty and current_combo < 3:
				for relic in active_relics:
					if relic["type"] == "combo_or_bust":
						damage = max(1, damage - relic["data"].get("solo_penalty", 2))
						break

			# Apply relic combo boost if exists
			if combo_multiplier > 1.0 and current_combo > 1:
				damage = int(damage * combo_multiplier)
			
			if current_combo > 1:
				add_to_combat_log("🔥 Combo x%d! (%.1fx damage)" % [current_combo, combo_damage_multiplier])
			
			# Add camera shake for combos
			if current_combo >= 3:
				shake_camera(5.0 * current_combo)
			
			# Deal damage
			deal_damage_to_enemy(damage)
			
			# Add power to matching character
			add_character_power(color, count)
			
			# Check for Block Duplicator relic (5+ blocks = spawn 1 extra)
			for relic in active_relics:
				if relic["type"] == "block_spawn":
					if count >= relic["data"].get("min_match", 5):
						# Spawn a block of this color at top
						spawn_bonus_block(color)
						add_to_combat_log("📦 Block Duplicator spawned a %s block!" % color)
						break

		
		# Clear matched blocks
		puzzle_grid.clear_matches(matches)
		
		# Visual delay after clearing
		await get_tree().create_timer(1.0).timeout
		
		# CHECK IF ALL ENEMIES DEFEATED AFTER EACH MATCH
		if are_all_enemies_defeated():
			is_processing_matches = false
			current_combo = 0
			update_combo_display()
			trigger_victory()
			return
	
	is_processing_matches = false
	
	# Reset combo display
	current_combo = 0
	update_combo_display()
	
	# Check for character abilities
	await check_and_activate_abilities()
	
	# Check if all enemies dead
	if are_all_enemies_defeated():
		trigger_victory()
		return
	
	# Time Warper: enemies act every 2 player turns
	player_turns_taken += 1
	if has_time_warper and player_turns_taken < enemy_turns_per_player:
		# Player gets another turn
		is_player_turn = true
		spawn_player_piece()
		return
	
	# Reset counter and do enemy turn
	player_turns_taken = 0
	await enemy_turn()
	
	# Spawn next piece
	is_player_turn = true
	spawn_player_piece()

func spawn_bonus_block(color: String):
	"""Spawn a bonus block at the top of a random column"""
	var valid_columns = []
	
	# Find columns that have room
	for x in range(puzzle_grid.GRID_WIDTH):
		if puzzle_grid.is_empty(x, 0):
			valid_columns.append(x)
	
	if valid_columns.size() == 0:
		return
	
	var spawn_x = valid_columns[randi() % valid_columns.size()]
	puzzle_grid.place_block(spawn_x, 0, color)

func update_combo_display():
	"""Update the combo label"""
	var info_panel = get_node_or_null("InfoPanel")
	if not info_panel:
		return
	
	var combo_label = info_panel.get_node_or_null("ComboLabel")
	if combo_label:
		if current_combo > 1:
			combo_label.text = "Combo: x%d" % current_combo
			combo_label.modulate = Color(1.0, 0.8, 0.2)  # Gold color for active combo
		else:
			combo_label.text = "Combo: x0"
			combo_label.modulate = Color.WHITE

# ========== DAMAGE & POWER ==========

func deal_damage_to_enemy(damage: int):
	"""Deal damage to the first active enemy"""
	if enemies.size() == 0:
		return
	
	# Apply bonus damage, multiplier, and permanent bonus
	var total_damage = int((damage + bonus_damage + permanent_damage_bonus) * damage_multiplier)
	
	
	# Check for First Strike Medal (only first match of turn)
	if not get_meta("first_strike_used", false):
		for relic in active_relics:
			if relic["type"] == "first_strike":
				total_damage += relic["data"].get("bonus_damage", 3)
				set_meta("first_strike_used", true)
				add_to_combat_log("⚡ First Strike! +%d damage" % relic["data"].get("bonus_damage", 3))
				break
	
	# Check for Glass Cannon
	for relic in active_relics:
		if relic["type"] == "glass_cannon":
			total_damage = int(total_damage * (1.0 + relic["data"].get("damage_bonus", 0.3)))
			break
		# Check for Berserker's Rage (damage based on missing HP)
	var current_hp = GameManager.get_current_health()
	var max_hp = GameManager.get_max_health()
	var missing_hp = max_hp - current_hp
	for relic in active_relics:
		if relic["type"] == "missing_hp_damage":
			var bonus = int(missing_hp / 10) * relic["data"].get("damage_per_10hp", 1)
			if bonus > 0:
				total_damage += bonus
			break
	
	# Check for Last Stand (below 30% HP)
	var hp_percent = float(current_hp) / float(max_hp)
	for relic in active_relics:
		if relic["type"] == "last_stand":
			if hp_percent <= relic["data"].get("hp_threshold", 0.3):
				total_damage = int(total_damage * (1.0 + relic["data"].get("damage_bonus", 0.5)))
				break
	var enemy = enemies[0]
	# Check for Giant Slayer (bonus vs Elite/Boss)
	for relic in active_relics:
		if relic["type"] == "giant_slayer":
			if enemy["data"].enemy_type == "Elite" or enemy["data"].enemy_type == "Boss":
				total_damage = int(total_damage * (1.0 + relic["data"].get("damage_bonus", 0.25)))
				break
	
	# Check for Executioner's Axe (bonus vs low HP enemies)
	var enemy_hp_percent = float(enemy["current_hp"]) / float(enemy["max_hp"])
	for relic in active_relics:
		if relic["type"] == "execute":
			if enemy_hp_percent <= relic["data"].get("hp_threshold", 0.25):
				total_damage = int(total_damage * (1.0 + relic["data"].get("damage_bonus", 0.5)))
				add_to_combat_log("💀 EXECUTE!")
				break
				
	if total_damage >= 20:
		flash_screen(0.2)
		
	# Check for Wraith evasion
	if enemy.get("id", "") == "wraith":
		var ability_data = enemy["data"].special_ability_data
		var evade_chance = ability_data.get("evade_chance", 0.3)
		if randf() < evade_chance:
			add_to_combat_log("👻 %s phases through the attack!" % enemy["data"].enemy_name)
			return
	
	# Check for Gargoyle stone skin (first damage reduced by 50%)
	if enemy.get("id", "") == "gargoyle":
		if not enemy.get("stone_skin_broken", false):
			var ability_data = enemy["data"].special_ability_data
			var reduction = ability_data.get("damage_reduction", 0.5)
			total_damage = int(total_damage * (1.0 - reduction))
			enemy["stone_skin_broken"] = true
			add_to_combat_log("🗿 Stone Skin reduces damage by 50%!")
			# Reset for next turn
			await get_tree().create_timer(0.1).timeout
			enemy["stone_skin_broken"] = false
	
	# Check for Stone Golem damage reduction
	if enemy.get("id", "") == "golem":
		total_damage = int(total_damage * 0.5)  # 50% damage reduction
		add_to_combat_log("🛡️ Stone Golem's Stone Skin reduces damage by 50%!")
	
	var overkill_damage = 0
	enemy["current_hp"] -= total_damage
	
	# Check for overkill (Finishing Blow relic)
	if enemy["current_hp"] < 0:
		for relic in active_relics:
			if relic["type"] == "overkill":
				overkill_damage = abs(enemy["current_hp"])
				add_to_combat_log("⚔️ Overkill! %d excess damage" % overkill_damage)
				break

	AudioManager.play_enemy_damage_sound(enemy["id"])
	AchievementManager.track_damage_dealt(total_damage)
	var log_msg = "⚔️ Dealt %d damage to %s" % [total_damage, enemy["data"].enemy_name]
	
	# Check for Vampire Lord life drain on damage
	if enemy.get("id", "") == "vampire_lord":
		var ability_data = enemy["data"].special_ability_data
		var heal_percent = ability_data.get("heal_percent", 0.5)
		var heal_amount = int(total_damage * heal_percent)
		enemy["current_hp"] = min(enemy["max_hp"], enemy["current_hp"] + heal_amount)
		add_to_combat_log("🧛 Vampire Lord drains %d HP!" % heal_amount)
	
	add_to_combat_log(log_msg)
	
	# Show floating damage number
	show_floating_damage(0, total_damage)
	
	# Update enemy UI
	update_enemy_hp(0)
	
	# Check if enemy died
	if enemy["current_hp"] <= 0:
		# Check for Undead Warrior revive
		if enemy.get("id", "") == "undead_warrior" and not enemy.get("has_revived", false):
			var ability_data = enemy["data"].special_ability_data
			var revive_chance = ability_data.get("revive_chance", 0.25)
			var revive_hp_percent = ability_data.get("revive_hp_percent", 0.5)
			
			if randf() < revive_chance:
				enemy["has_revived"] = true
				enemy["current_hp"] = int(enemy["max_hp"] * revive_hp_percent)
				add_to_combat_log("💀 Undead Warrior refuses to die! Revives with %d HP!" % enemy["current_hp"])
				update_enemy_hp(0)
				flash_screen(0.3)
				return
		
		enemy_defeated(0)
		
		# Apply overkill damage to next enemy
		if overkill_damage > 0 and enemies.size() > 0:
			await get_tree().create_timer(0.3).timeout
			deal_damage_to_enemy(overkill_damage)

func add_character_power(color: String, blocks_cleared: int):
	"""Add power to character based on color"""
	# Map color to character slot
	var color_to_slot = {
		"red": 0,
		"blue": 1,
		"yellow": 2
	}
	
	# If purple (wild) was matched, it already converted to actual color in find_matches
	# So this should work as-is, but let's add a safety check
	if color == "purple":
		# This shouldn't happen, but if it does, treat as neutral
		return
	
	var is_neutral = not color_to_slot.has(color)
	
	# Track neutral blocks for Troll regeneration
	if is_neutral:
		troll_regeneration(blocks_cleared)
	
	# Check for Neutral Affinity relic
	if is_neutral:
		for relic in active_relics:
			if relic["type"] == "neutral_power":
				var power_per_block = relic["data"].get("power_per_block", 3)
				var total_power = blocks_cleared * power_per_block
				
				for i in range(party.size()):
					var char_id = party[i]
					if bound_characters.has(char_id):
						continue
					
					character_power[char_id] = min(character_power[char_id] + total_power, MAX_POWER)
					update_character_power(i)
				
				add_to_combat_log("✨ Neutral Affinity grants %d power to all!" % total_power)
				break

	# Handle neutral blocks with converters
	if is_neutral:
		for i in range(party.size()):
			var char_id = party[i]
			
			# Check if character is bound by Mummy
			if bound_characters.has(char_id):
				add_to_combat_log("⛓️ %s is bound and cannot gain power!" % CharacterDatabase.get_character(char_id).character_name)
				continue
			
			var converter_power = get_power_converter_bonus(char_id, true)
			if converter_power > 0:
				var power_gain = int(blocks_cleared * converter_power * power_gain_multiplier)
				character_power[char_id] = min(character_power[char_id] + power_gain, MAX_POWER)
				var char_data = CharacterDatabase.get_character(char_id)
				if char_data:
					add_to_combat_log("🔄 %s converted %d blocks (+%d power)" % [char_data.character_name, blocks_cleared, power_gain])
				update_character_power(i)
		return
	
	var slot = color_to_slot[color]
	if slot >= party.size():
		return
	
	var char_id = party[slot]
	
	# Check if character is bound by Mummy
	if bound_characters.has(char_id):
		add_to_combat_log("⛓️ %s is bound and cannot gain power!" % CharacterDatabase.get_character(char_id).character_name)
		return
	
	var base_power = 10  # 10 power per block
	var bonus_power = get_power_gain_bonus(char_id)
	
	# Check for Power Surge relic (5+ blocks = +10 power)
	for relic in active_relics:
		if relic["type"] == "power_surge":
			if blocks_cleared >= relic["data"].get("min_blocks", 5):
				bonus_power += relic["data"].get("bonus_power", 10)
				add_to_combat_log("⚡ Power Surge! +10 bonus power")
				break
	
	# Check for Perfectionist's Crown (exactly 5 blocks)
	for relic in active_relics:
		if relic["type"] == "perfect_match":
			if blocks_cleared == relic["data"].get("exact_blocks", 5):
				bonus_power += relic["data"].get("bonus_power", 15)
				# Bonus damage handled in process_matches_and_gravity
				add_to_combat_log("👑 PERFECT MATCH! +15 power")
				break
	
	var power_per_block = base_power + bonus_power
	var power_gain = int(blocks_cleared * power_per_block * power_gain_multiplier)
	
	character_power[char_id] = min(character_power[char_id] + power_gain, MAX_POWER)
	
	var char_data = CharacterDatabase.get_character(char_id)
	if char_data:
		var log_msg = "✨ %s +%d power (%d/100)" % [char_data.character_name, power_gain, character_power[char_id]]
		add_to_combat_log(log_msg)
	
	update_character_power(slot)

	
func enemy_defeated(enemy_index: int):
	"""Handle enemy death and spawn next from queue"""
	var enemy = enemies[enemy_index]
	AchievementManager.track_enemy_defeated(enemy["id"])
	var log_msg = "💀 %s defeated!" % enemy["data"].enemy_name
	
	add_to_combat_log(log_msg)
	
	# Animate defeat BEFORE removing from array
	if enemy_index < enemy_ui.size():
		await animate_enemy_defeat(enemy_index)
	
	# Award coins with multiplier
	var coins = int(enemy["data"].coin_reward * coin_multiplier)
	GameManager.add_coins(coins)
	if coin_multiplier > 1.0:
		add_to_combat_log("💰 +%d coins (bonus!)" % coins)
	else:
		add_to_combat_log("💰 +%d coins" % coins)
	
	# Remove enemy from array
	enemies.remove_at(enemy_index)
	await get_tree().create_timer(.2).timeout
	# Try to spawn next enemy from queue immediately
	if enemies.size() < 3 and enemy_spawn_queue.size() > 0:
		var spawn_data = enemy_spawn_queue[0]
		var current_floor = GameManager.current_run.get("currentFloor", 1)
		var new_enemy = spawn_manager.create_enemy_instance(spawn_data["enemy"], current_floor)
		
		if new_enemy:
			# Randomize starting cooldown for new enemy
			new_enemy["current_cooldown"] = randi_range(1, new_enemy["attack_cooldown"])
			enemies.append(new_enemy)
			
			var spawn_msg = "➡️ %s joins the battle!" % new_enemy["data"].enemy_name
			
			add_to_combat_log(spawn_msg)
			
			enemy_spawn_queue.remove_at(0)
	
	# IMPORTANT: Completely rebuild enemy UI from scratch
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
		
		show_synergy_banner(synergy_name, multiplier)
		AchievementManager.track_synergy_activated(characters_at_full.size())
	# Activate each character's ability
	for char_id in characters_at_full:
		var char_index = party.find(char_id)
		if char_index >= 0:
			flash_character_portrait(char_index)
		
		await activate_character_ability(char_id, multiplier)
		character_power[char_id] = 0
		
		# Update UI
		if char_index >= 0:
			update_character_power(char_index)

func activate_character_ability(char_id: String, multiplier: float):
	"""Activate a character's ability"""
	
	var char_data = CharacterDatabase.get_character(char_id)
	if not char_data:
		return
	abilities_used_this_turn += 1
	
	# Check for Spell Echo (first ability of battle gets doubled)
	var is_spell_echo = false
	if not get_meta("spell_echo_used", false):
		for relic in active_relics:
			if relic["type"] == "first_ability_double":
				is_spell_echo = true
				set_meta("spell_echo_used", true)
				add_to_combat_log("🔮 Spell Echo! Ability triggers twice!")
				break

	
	AchievementManager.track_abilities_used(abilities_used_this_turn)
	var level = GameManager.get_character_level(char_id)
	
	# Apply relic bonus
	var relic_multiplier = get_ability_multiplier(char_id)
	var total_multiplier = multiplier * relic_multiplier
	
	var ability_value = char_data.get_ability_value(level) * total_multiplier
	
	add_to_combat_log("✨ %s uses %s!" % [char_data.character_name, char_data.ability_name])
	
	# Execute ability based on character
	match char_id:
		# TIER 0 - STARTERS
		"knight":
			knight_shield_wall(int(ability_value))
		"wizard":
			wizard_meteor_storm(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"cleric":
			cleric_healing_light(int(ability_value))
		
		# TIER 1
		"rogue":
			rogue_assassinate(int(ability_value))
		"paladin":
			paladin_purify(int(ability_value))
		"berserker":
			berserker_cleave(int(ability_value))
		"druid":
			druid_barkskin(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier), char_data.get_ability_duration(level))
		
		# TIER 2
		"necromancer":
			necromancer_drain_life(int(ability_value))
		"ranger":
			ranger_multishot(int(ability_value))
		"enchanter":
			enchanter_mesmerize(char_data.get_ability_duration(level))
		"monk":
			monk_temporal_mastery(char_data.get_ability_duration(level))
		
		# TIER 3
		"beastmaster":
			beastmaster_summon(char_data, level, multiplier)
		"bladesinger":
			bladesinger_bladesong(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"shadowmancer":
			shadowmancer_shadow_strike(int(ability_value))
		
		# TIER 4
		"valkyrie":
			valkyrie_divine_judgement(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"warden":
			warden_healing_grove(int(ability_value), char_data.get_ability_duration(level))
		"chronomancer":
			chronomancer_time_warp(int(ability_value))
		
		# TIER 5
		"geomancer":
			geomancer_earthquake(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"inquisitor":
			inquisitor_divine_retribution(ability_value)
		"blood_knight":
			blood_knight_crimson_strike(int(ability_value), char_data.get_ability_secondary(level))
		
		# TIER 6
		"fateweaver":
			fateweaver_prophecy(int(ability_value))
		"archmage":
			archmage_elemental_fusion(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"dreadknight":
			dreadknight_deaths_embrace(int(ability_value), char_data.get_ability_secondary(level), char_data.get_ability_duration(level))
		
		# TIER 7
		"runemaster":
			runemaster_rune_trap(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier), char_data.get_ability_duration(level))
		"spellblade":
			spellblade_arcane_purge(int(ability_value))
		"templar":
			templar_crusaders_aegis(char_data.get_ability_duration(level))
		
		# TIER 8
		"elementalist":
			elementalist_cataclysm(int(ability_value))
		"lightbringer":
			lightbringer_solar_flare(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"voidwalker":
			voidwalker_void_rift(int(ability_value))
		
		# TIER 9
		"stormlord":
			stormlord_maelstrom(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"archdruid":
			archdruid_world_tree(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
		"archon":
			archon_ascension(ability_value, char_data.get_ability_secondary(level))
		"demonologist":
			demonologist_infernal_legion(char_data, level, multiplier, char_data.get_ability_duration(level))
	
	# If Spell Echo, cast again at 50% effectiveness
	if is_spell_echo:
		await get_tree().create_timer(0.5).timeout
		add_to_combat_log("🔮 Spell Echo activates!")
		
		var echo_multiplier = 0.5
		var echo_value = char_data.get_ability_value(level) * total_multiplier * echo_multiplier
		
		# Execute ability again (you'd need to extract ability logic to a separate function
		# to avoid duplication, but for now we can just call the main logic)
		match char_id:
			# TIER 0 - STARTERS
			"knight":
				knight_shield_wall(int(ability_value))
			"wizard":
				wizard_meteor_storm(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"cleric":
				cleric_healing_light(int(ability_value))
			
			# TIER 1
			"rogue":
				rogue_assassinate(int(ability_value))
			"paladin":
				paladin_purify(int(ability_value))
			"berserker":
				berserker_cleave(int(ability_value))
			"druid":
				druid_barkskin(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier), char_data.get_ability_duration(level))
			
			# TIER 2
			"necromancer":
				necromancer_drain_life(int(ability_value))
			"ranger":
				ranger_multishot(int(ability_value))
			"enchanter":
				enchanter_mesmerize(char_data.get_ability_duration(level))
			"monk":
				monk_temporal_mastery(char_data.get_ability_duration(level))
			
			# TIER 3
			"beastmaster":
				beastmaster_summon(char_data, level, multiplier)
			"bladesinger":
				bladesinger_bladesong(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"shadowmancer":
				shadowmancer_shadow_strike(int(ability_value))
			
			# TIER 4
			"valkyrie":
				valkyrie_divine_judgement(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"warden":
				warden_healing_grove(int(ability_value), char_data.get_ability_duration(level))
			"chronomancer":
				chronomancer_time_warp(int(ability_value))
			
			# TIER 5
			"geomancer":
				geomancer_earthquake(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"inquisitor":
				inquisitor_divine_retribution(ability_value)
			"blood_knight":
				blood_knight_crimson_strike(int(ability_value), char_data.get_ability_secondary(level))
			
			# TIER 6
			"fateweaver":
				fateweaver_prophecy(int(ability_value))
			"archmage":
				archmage_elemental_fusion(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"dreadknight":
				dreadknight_deaths_embrace(int(ability_value), char_data.get_ability_secondary(level), char_data.get_ability_duration(level))
			
			# TIER 7
			"runemaster":
				runemaster_rune_trap(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier), char_data.get_ability_duration(level))
			"spellblade":
				spellblade_arcane_purge(int(ability_value))
			"templar":
				templar_crusaders_aegis(char_data.get_ability_duration(level))
			
			# TIER 8
			"elementalist":
				elementalist_cataclysm(int(ability_value))
			"lightbringer":
				lightbringer_solar_flare(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"voidwalker":
				voidwalker_void_rift(int(ability_value))
			
			# TIER 9
			"stormlord":
				stormlord_maelstrom(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"archdruid":
				archdruid_world_tree(int(ability_value), int(char_data.get_ability_secondary(level) * multiplier))
			"archon":
				archon_ascension(ability_value, char_data.get_ability_secondary(level))
			"demonologist":
				demonologist_infernal_legion(char_data, level, multiplier, char_data.get_ability_duration(level))

	await get_tree().create_timer(0.5).timeout
	
	# Check for Lucky Rabbit's Foot (20% chance to refund 50 power)
	for relic in active_relics:
		if relic["type"] == "power_refund":
			if randf() < relic["data"].get("refund_chance", 0.2):
				var refund = relic["data"].get("refund_amount", 50)
				character_power[char_id] = min(character_power[char_id] + refund, MAX_POWER)
				var char_index = party.find(char_id)
				if char_index >= 0:
					update_character_power(char_index)
				add_to_combat_log("🍀 Lucky! Refunded %d power!" % refund)
			break
	
	# Check for Second Wind (gain +25 power immediately)
	for relic in active_relics:
		if relic["type"] == "ability_power_gain":
			var power_gain = relic["data"].get("power_gain", 25)
			character_power[char_id] = min(character_power[char_id] + power_gain, MAX_POWER)
			var char_index = party.find(char_id)
			if char_index >= 0:
				update_character_power(char_index)
			add_to_combat_log("💨 Second Wind! +%d power" % power_gain)
			break
	
	# Check for Teamwork Charm (other characters gain +15 power)
	for relic in active_relics:
		if relic["type"] == "teamwork":
			var power_bonus = relic["data"].get("power_bonus", 15)
			for other_char_id in party:
				if other_char_id != char_id:
					character_power[other_char_id] = min(character_power[other_char_id] + power_bonus, MAX_POWER)
					var other_index = party.find(other_char_id)
					if other_index >= 0:
						update_character_power(other_index)
			add_to_combat_log("🤝 Teamwork! Others gain +%d power" % power_bonus)
			break
# ========== NEW CHARACTER ABILITY IMPLEMENTATIONS ==========

# TIER 3 ABILITIES

func shadowmancer_shadow_strike(damage: int):
	"""Shadowmancer's Shadow Strike - enemy attacks themselves, chance to delay"""
	if enemies.size() == 0:
		return
	
	# Deal damage based on enemy's own attack damage
	var enemy = enemies[0]
	var shadow_damage = damage
	
	enemy["current_hp"] -= shadow_damage
	add_to_combat_log("🌑 %s's shadow strikes for %d damage!" % [enemy["data"].enemy_name, shadow_damage])
	update_enemy_hp(0)
	
	if enemy["current_hp"] <= 0:
		enemy_defeated(0)
		return
	
	# 50% chance to delay all enemies
	if randf() < 0.5:
		for i in range(enemies.size()):
			var e = enemies[i]
			e["current_cooldown"] = min(e["current_cooldown"] + 1, e["attack_cooldown"] + 2)
			if i < enemy_ui.size():
				update_enemy_cooldown_display(enemy_ui[i], e)
		add_to_combat_log("⏰ All enemies delayed!")

# TIER 4 ABILITIES

func valkyrie_divine_judgement(damage: int, shield: int):
	"""Valkyrie's Divine Judgement - massive damage to lowest HP enemy + shield"""
	if enemies.size() == 0:
		return
	
	# Find lowest HP enemy
	var lowest_index = 0
	var lowest_hp = enemies[0]["current_hp"]
	
	for i in range(1, enemies.size()):
		if enemies[i]["current_hp"] < lowest_hp:
			lowest_hp = enemies[i]["current_hp"]
			lowest_index = i
	
	# Deal damage
	var enemy = enemies[lowest_index]
	enemy["current_hp"] -= damage
	add_to_combat_log("⚔️ Divine Judgement strikes %s for %d!" % [enemy["data"].enemy_name, damage])
	update_enemy_hp(lowest_index)
	
	if enemy["current_hp"] <= 0:
		enemy_defeated(lowest_index)
	
	# Create shield
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "shield_wall",
		"shield_remaining": shield
	})
	
	add_to_combat_log("🛡️ Divine shield created! Absorbs up to %d damage" % shield)
	GameManager.save_game()

func warden_healing_grove(heal_per_block: int, duration: int):
	"""Warden's Healing Grove - place healing zone"""
	start_rune_placement("healing_grove", {
		"heal_per_block": heal_per_block,
		"duration": duration
	})
	
	# Wait for placement to complete
	await get_tree().create_timer(0.1).timeout
	while is_placing_rune:
		await get_tree().create_timer(0.1).timeout

func chronomancer_time_warp(delay_amount: int):
	"""Chronomancer's Time Warp - delay enemies and grant extra turn"""
	# Delay all enemies
	for i in range(enemies.size()):
		var enemy = enemies[i]
		enemy["current_cooldown"] += delay_amount
		if i < enemy_ui.size():
			update_enemy_cooldown_display(enemy_ui[i], enemy)
	
	add_to_combat_log("⏰ Time Warp! All enemies delayed by %d turns!" % delay_amount)
	
	# Grant extra turn (handled by battle flow - reset player turn counter)
	player_turns_taken = 0

# TIER 5 ABILITIES

func geomancer_earthquake(damage: int, conversions: int):
	"""Geomancer's Earthquake - remove obstacles, damage, convert blocks"""
	# Deal damage
	deal_damage_to_enemy(damage)
	
	# Remove all obstacles
	var obstacles_removed = 0
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var cell = puzzle_grid.grid[y][x]
			if cell.is_obstacle:
				if cell.obstacle_type == "web":
					puzzle_grid.remove_web(x, y)
				elif cell.obstacle_type == "slime":
					puzzle_grid.remove_slime_head(x, y)
				obstacles_removed += 1
	
	if obstacles_removed > 0:
		add_to_combat_log("🪨 Earthquake removes %d obstacles!" % obstacles_removed)
	
	# Convert neutral blocks to "earth" (brown)
	var converted = 0
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color == "gray" or color == "white":
				puzzle_grid.remove_block(x, y)
				puzzle_grid.place_block(x, y, "brown")
				converted += 1
				if converted >= conversions:
					break
		if converted >= conversions:
			break
	
	if converted > 0:
		add_to_combat_log("🌍 Converted %d blocks to earth!" % converted)

func inquisitor_divine_retribution(percentage: float):
	"""Inquisitor's Divine Retribution - damage based on total damage taken"""
	var max_hp = GameManager.get_max_health()
	var current_hp = GameManager.get_current_health()
	var damage_taken = max_hp - current_hp
	
	var retribution_damage = int(damage_taken * percentage)
	
	if retribution_damage > 0:
		deal_damage_to_enemy(retribution_damage)
		add_to_combat_log("⚖️ Divine Retribution deals %d damage!" % retribution_damage)
	else:
		add_to_combat_log("⚖️ No damage taken yet - minimal retribution!")
		deal_damage_to_enemy(5)  # Minimum damage

func blood_knight_crimson_strike(base_damage: int, missing_hp_multiplier: float):
	"""Blood Knight's Crimson Strike - bonus damage based on missing HP"""
	var max_hp = GameManager.get_max_health()
	var current_hp = GameManager.get_current_health()
	var missing_hp = max_hp - current_hp
	
	var bonus_damage = int(missing_hp * missing_hp_multiplier)
	var total_damage = base_damage + bonus_damage
	
	deal_damage_to_enemy(total_damage)
	add_to_combat_log("🩸 Crimson Strike deals %d damage! (+%d from wounds)" % [total_damage, bonus_damage])

# TIER 6 ABILITIES

func fateweaver_prophecy(num_pieces: int):
	"""Fateweaver's Prophecy - next pieces are all one color"""
	# This would need to be implemented in PieceFactory
	# For now, just show message
	add_to_combat_log("🔮 Prophecy activated! Next %d pieces will be uniform!" % num_pieces)
	
	# TODO: Add buff to force next pieces to be single color

func archmage_elemental_fusion(blocks_to_convert: int, power_gain: int):
	"""Archmage's Elemental Fusion - convert neutral blocks and grant power"""
	var converted = 0
	var player_colors = ["red", "blue", "yellow"]
	
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color == "gray" or color == "brown" or color == "white":
				var new_color = player_colors[randi() % player_colors.size()]
				puzzle_grid.remove_block(x, y)
				puzzle_grid.place_block(x, y, new_color)
				converted += 1
				if converted >= blocks_to_convert:
					break
		if converted >= blocks_to_convert:
			break
	
	if converted > 0:
		add_to_combat_log("✨ Elemental Fusion converts %d blocks!" % converted)
	
	# Grant power to all characters
	for char_id in party:
		character_power[char_id] = min(character_power[char_id] + power_gain, MAX_POWER)
	
	for i in range(party.size()):
		update_character_power(i)
	
	add_to_combat_log("⚡ All characters gain %d power!" % power_gain)

func dreadknight_deaths_embrace(damage_multiplier: int, hp_sacrifice_percent: float, immunity_turns: int):
	"""Dreadknight's Death's Embrace - sacrifice HP for AoE damage and immunity"""
	var current_hp = GameManager.get_current_health()
	var sacrifice = int(current_hp * hp_sacrifice_percent)
	
	# Sacrifice HP
	GameManager.modify_health(-sacrifice)
	add_to_combat_log("💀 Dreadknight sacrifices %d HP!" % sacrifice)
	
	# Deal AoE damage based on sacrifice
	var aoe_damage = sacrifice * damage_multiplier
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		enemy["current_hp"] -= aoe_damage
		update_enemy_hp(i)
		
		if enemy["current_hp"] <= 0:
			enemy_defeated(i)
			i -= 1
	
	add_to_combat_log("💥 Death's Embrace deals %d AoE damage!" % aoe_damage)
	
	# Grant immunity
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "immunity",
		"turns_remaining": immunity_turns
	})
	
	add_to_combat_log("🛡️ Dreadknight gains %d turns of immunity!" % immunity_turns)
	GameManager.save_game()

# TIER 7 ABILITIES

func runemaster_rune_trap(damage_per_block: int, blocks_count: int, duration: int):
	"""Runemaster's Rune Trap - place damage rune"""
	start_rune_placement("rune_trap", {
		"damage_per_block": damage_per_block,
		"duration": duration
	})
	
	# Wait for placement to complete
	await get_tree().create_timer(0.1).timeout
	while is_placing_rune:
		await get_tree().create_timer(0.1).timeout
	


func spellblade_arcane_purge(damage_per_block: int):
	"""Spellblade's Arcane Purge - remove most abundant block color and deal damage"""
	# Count each color
	var color_counts = {}
	
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color != "" and color != "gray" and color != "brown" and color != "white":
				if not color_counts.has(color):
					color_counts[color] = 0
				color_counts[color] += 1
	
	if color_counts.size() == 0:
		add_to_combat_log("🗡️ No colored blocks to purge!")
		return
	
	# Find most abundant
	var most_abundant = ""
	var max_count = 0
	
	for color in color_counts:
		if color_counts[color] > max_count:
			max_count = color_counts[color]
			most_abundant = color
	
	# Remove all of that color
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			if puzzle_grid.get_block_color(x, y) == most_abundant:
				puzzle_grid.remove_block(x, y)
	
	# Deal damage
	var total_damage = max_count * damage_per_block
	deal_damage_to_enemy(total_damage)
	
	add_to_combat_log("🗡️ Arcane Purge removes %d %s blocks for %d damage!" % [max_count, most_abundant, total_damage])
	
	# Apply gravity
	await get_tree().create_timer(0.2).timeout
	puzzle_grid.apply_gravity()

func templar_crusaders_aegis(duration: int):
	"""Templar's Crusader's Aegis - damage immunity, damage becomes healing"""
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "crusaders_aegis",
		"turns_remaining": duration
	})
	GameManager.current_run["healing_used_this_run"] = true
	add_to_combat_log("✨ Crusader's Aegis! Damage becomes healing for %d turns!" % duration)
	GameManager.save_game()

# TIER 8 ABILITIES

func elementalist_cataclysm(damage_per_block: int):
	"""Elementalist's Cataclysm - destroy all elemental blocks and deal damage"""
	var elemental_colors = ["brown", "white"]  # Earth, ice (can add more)
	var total_destroyed = 0
	
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color in elemental_colors:
				puzzle_grid.remove_block(x, y)
				total_destroyed += 1
	
	if total_destroyed > 0:
		var total_damage = total_destroyed * damage_per_block
		deal_damage_to_enemy(total_damage)
		add_to_combat_log("🌪️ Cataclysm destroys %d blocks for %d damage!" % [total_destroyed, total_damage])
		
		# Apply gravity
		await get_tree().create_timer(0.2).timeout
		puzzle_grid.apply_gravity()
	else:
		add_to_combat_log("🌪️ No elemental blocks to destroy!")

func lightbringer_solar_flare(heal_amount: int, shield_amount: int):
	"""Lightbringer's Solar Flare - heal, shield, blind enemies"""
	# Heal
	GameManager.modify_health(heal_amount)
	add_to_combat_log("☀️ Solar Flare heals for %d HP!" % heal_amount)
	GameManager.current_run["healing_used_this_run"] = true
	# Create shield
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "shield_wall",
		"shield_remaining": shield_amount
	})
	
	# Blind enemies (50% miss chance for next attack)
	GameManager.current_run["active_buffs"].append({
		"type": "blind",
		"turns_remaining": 1
	})
	
	add_to_combat_log("🛡️ Shield created! Enemies blinded!")
	GameManager.save_game()

func voidwalker_void_rift(damage_per_block: int):
	"""Voidwalker's Void Rift - remove tallest column, deal damage, stun top enemy"""
	# Find tallest column
	var tallest_col = 0
	var tallest_height = 0
	
	for x in range(puzzle_grid.GRID_WIDTH):
		var height = 0
		for y in range(puzzle_grid.GRID_HEIGHT):
			if puzzle_grid.get_block_color(x, y) != "":
				height += 1
		
		if height > tallest_height:
			tallest_height = height
			tallest_col = x
	
	if tallest_height == 0:
		add_to_combat_log("🌀 No columns to rift!")
		return
	
	# Remove column
	for y in range(puzzle_grid.GRID_HEIGHT):
		puzzle_grid.remove_block(tallest_col, y)
	
	# Deal damage
	var total_damage = tallest_height * damage_per_block
	deal_damage_to_enemy(total_damage)
	
	add_to_combat_log("🌀 Void Rift removes column for %d damage!" % total_damage)
	
	# Stun top enemy
	if enemies.size() > 0:
		if not GameManager.current_run.has("active_buffs"):
			GameManager.current_run["active_buffs"] = []
		
		GameManager.current_run["active_buffs"].append({
			"type": "stun",
			"turns_remaining": 1
		})
		
		add_to_combat_log("😵 Top enemy stunned!")
		GameManager.save_game()

# TIER 9 ABILITIES

func stormlord_maelstrom(damage: int, strikes_to_add: int):
	"""Stormlord's Maelstrom - add permanent lightning strikes"""
	# Track lightning strikes
	if not GameManager.current_run.has("lightning_strikes"):
		GameManager.current_run["lightning_strikes"] = 0
	
	var max_strikes = 4
	var current_strikes = GameManager.current_run["lightning_strikes"]
	var strikes_added = min(strikes_to_add, max_strikes - current_strikes)
	
	if strikes_added > 0:
		GameManager.current_run["lightning_strikes"] += strikes_added
		
		# Deal damage
		deal_damage_to_enemy(damage * strikes_added)
		
		# Calculate damage bonus
		var damage_bonus = strikes_added * 25
		
		add_to_combat_log("⚡ Maelstrom adds %d lightning strike(s)!" % strikes_added)
		add_to_combat_log("⚡ Party damage increased by %d%%!" % damage_bonus)
		
		GameManager.save_game()
	else:
		add_to_combat_log("⚡ Maximum lightning strikes reached!")

func archdruid_world_tree(heal_per_turn: int, obstacles_per_turn: int):
	"""Archdruid's World Tree - permanent healing/damage/obstacle removal"""
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "world_tree",
		"heal_per_turn": heal_per_turn,
		"damage_per_turn": heal_per_turn,
		"obstacles_per_turn": obstacles_per_turn,
		"turns_remaining": 999  # Permanent
	})
	GameManager.current_run["healing_used_this_run"] = true
	add_to_combat_log("🌳 World Tree planted! Permanent healing and damage!")
	GameManager.save_game()

func archon_ascension(damage_per_block: float, heal_per_block: float):
	"""Archon's Ascension - transform all blocks to white, match all"""
	var total_blocks = 0
	
	# Count and transform all blocks
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color != "":
				puzzle_grid.remove_block(x, y)
				puzzle_grid.place_block(x, y, "white")
				total_blocks += 1
	
	if total_blocks == 0:
		add_to_combat_log("✨ No blocks to ascend!")
		return
	
	# Deal damage and heal
	var total_damage = int(total_blocks * damage_per_block)
	var total_heal = int(total_blocks * heal_per_block)
	
	deal_damage_to_enemy(total_damage)
	GameManager.modify_health(total_heal)
	GameManager.current_run["healing_used_this_run"] = true
	add_to_combat_log("✨ Ascension! %d damage and %d healing!" % [total_damage, total_heal])
	
	# Clear all blocks
	await get_tree().create_timer(0.5).timeout
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			if puzzle_grid.get_block_color(x, y) == "white":
				puzzle_grid.remove_block(x, y)

func demonologist_infernal_legion(char_data: CharacterData, level: int, multiplier: float, duration: int):
	"""Demonologist's Infernal Legion - summon demon that attacks independently"""
	var demons = char_data.special_data.get("demons", [])
	if demons.is_empty():
		return
	
	var tier_index = 0
	if level <= 3:
		tier_index = 0
	elif level <= 6:
		tier_index = 1
	else:
		tier_index = 2
	
	# Weighted random selection
	var weighted_demons = []
	for demon in demons:
		var weight = demon["weight"][tier_index]
		for i in range(weight):
			weighted_demons.append(demon)
	
	var demon = weighted_demons[randi() % weighted_demons.size()]
	var damage = int(demon["damage"][tier_index] * multiplier)
	
	add_to_combat_log("😈 %s summons a %s!" % [char_data.character_name, demon["name"]])
	
	# Add demon buff that deals damage each turn
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "summoned_demon",
		"demon_name": demon["name"],
		"damage_per_turn": damage,
		"turns_remaining": duration
	})
	
	add_to_combat_log("😈 %s will attack for %d turns!" % [demon["name"], duration])
	GameManager.save_game()

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
	
	var log_msg = "❤️ Party healed for %d HP! (%d/%d)" % [amount, new_hp, max_hp]
	
	add_to_combat_log(log_msg)

# ========== ENEMY TURN ==========

# Replace the enemy_turn() function in BattleScene.gd

func enemy_turn():
	"""Handle enemy actions"""
	
	# Process active buffs (Barkskin, etc.)
	process_active_buffs()
	await get_tree().create_timer(0.5).timeout
	# Check for Regeneration Ring
	if not has_meta("regen_turn_counter"):
		set_meta("regen_turn_counter", 0)
	
	var regen_counter = get_meta("regen_turn_counter") + 1
	set_meta("regen_turn_counter", regen_counter)
	
	for relic in active_relics:
		if relic["type"] == "passive_regen":
			var frequency = relic["data"].get("turn_frequency", 3)
			if regen_counter >= frequency:
				var heal = relic["data"].get("heal_amount", 1)
				GameManager.modify_health(heal)
				add_to_combat_log("💚 Regeneration Ring heals %d HP!" % heal)
				set_meta("regen_turn_counter", 0)
			break
	
	# Check for Obstacle Destroyer
	for relic in active_relics:
		if relic["type"] == "auto_clear_obstacle":
			var obstacles_found = []
			for y in range(puzzle_grid.GRID_HEIGHT):
				for x in range(puzzle_grid.GRID_WIDTH):
					var cell = puzzle_grid.grid[y][x]
					if cell.is_obstacle:
						obstacles_found.append(Vector2i(x, y))
			
			if obstacles_found.size() > 0:
				var pos = obstacles_found[randi() % obstacles_found.size()]
				var cell = puzzle_grid.grid[pos.y][pos.x]
				
				match cell.obstacle_type:
					"web":
						puzzle_grid.remove_web(pos.x, pos.y)
					"slime":
						puzzle_grid.remove_all_slime_in_column(pos.x)
					"rock", _:
						puzzle_grid.remove_block(pos.x, pos.y)
						cell.is_obstacle = false
						cell.obstacle_type = ""
				
				add_to_combat_log("🔨 Obstacle Destroyer removed an obstacle!")
			break
	
	# Check for Alchemist's Stone (15% chance to convert neutral block)
	for relic in active_relics:
		if relic["type"] == "block_alchemy":
			if randf() < relic["data"].get("conversion_chance", 0.15):
				var neutral_blocks = []
				for y in range(puzzle_grid.GRID_HEIGHT):
					for x in range(puzzle_grid.GRID_WIDTH):
						var color = puzzle_grid.get_block_color(x, y)
						if color == "gray" or color == "brown" or color == "white":
							neutral_blocks.append(Vector2i(x, y))
				
				if neutral_blocks.size() > 0:
					var pos = neutral_blocks[randi() % neutral_blocks.size()]
					var player_colors = ["red", "blue", "yellow"]
					var new_color = player_colors[randi() % player_colors.size()]
					puzzle_grid.remove_block(pos.x, pos.y)
					puzzle_grid.place_block(pos.x, pos.y, new_color)
					add_to_combat_log("🔮 Alchemist's Stone converted a block to %s!" % new_color)
			break
	
	# Check for Chaos Orb (shuffle 3 random blocks)
	for relic in active_relics:
		if relic["type"] == "chaos_shuffle":
			var blocks_to_shuffle = relic["data"].get("blocks_to_shuffle", 3)
			var all_blocks = []
			
			for y in range(puzzle_grid.GRID_HEIGHT):
				for x in range(puzzle_grid.GRID_WIDTH):
					var color = puzzle_grid.get_block_color(x, y)
					if color != "":
						all_blocks.append({"pos": Vector2i(x, y), "color": color})
			
			if all_blocks.size() >= blocks_to_shuffle:
				all_blocks.shuffle()
				var blocks_to_move = all_blocks.slice(0, blocks_to_shuffle)
				
				# Store colors
				var colors = []
				for block_data in blocks_to_move:
					colors.append(block_data["color"])
				
				# Shuffle colors
				colors.shuffle()
				
				# Replace with shuffled colors
				for i in range(blocks_to_move.size()):
					var pos = blocks_to_move[i]["pos"]
					puzzle_grid.remove_block(pos.x, pos.y)
					puzzle_grid.place_block(pos.x, pos.y, colors[i])
				
				add_to_combat_log("🌀 Chaos Orb shuffled %d blocks!" % blocks_to_shuffle)
			break
	
	await get_tree().create_timer(0.5).timeout
	
	# Check if enemies are stunned
	if is_enemy_stunned():
		add_to_combat_log("😵 Enemies are stunned and cannot act!")
		await get_tree().create_timer(0.5).timeout
		
		# Player gets another turn
		player_turns_taken = 0
		is_player_turn = true
		spawn_player_piece()
		return
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		
		# Decrease cooldown
		enemy["current_cooldown"] -= 1
		
		if enemy["current_cooldown"] <= 0:
			# Check if this enemy has special ability
			if enemy["data"].has_special_ability:
				await handle_enemy_special_ability(enemy)
			# Check if this enemy places obstacles
			elif enemy["data"].places_obstacles:
				# Check for Cleansing Light relic (first obstacle immunity)
				var is_first_obstacle = not get_meta("first_obstacle_placed", false)
				var has_cleansing = false
				
				if is_first_obstacle:
					for relic in active_relics:
						if relic["type"] == "first_obstacle_immunity":
							has_cleansing = true
							set_meta("first_obstacle_placed", true)
							add_to_combat_log("✨ Cleansing Light prevents first obstacle!")
							break
				
				if not has_cleansing:
					# Track obstacle frequency
					if not enemy.has("obstacle_counter"):
						enemy["obstacle_counter"] = 0
					
					enemy["obstacle_counter"] += 1
					
					# Place obstacle every N attacks
					if enemy["obstacle_counter"] >= enemy["data"].obstacle_frequency:
						await enemy_place_obstacle(enemy)
						enemy["obstacle_counter"] = 0
					else:
						# Normal attack
						await enemy_attack(enemy)
				else:
					# Just do normal attack instead
					await enemy_attack(enemy)
			else:
				# Normal attack
				await enemy_attack(enemy)
			
			# Reset cooldown
			enemy["current_cooldown"] = enemy["attack_cooldown"]
		else:
			# Not attacking this turn - drop blocks
			await enemy_drop_block()
		
		# Update UI
		if i < enemy_ui.size():
			update_enemy_cooldown_display(enemy_ui[i], enemy)
	
	# Update slimes
	puzzle_grid.update_slimes()
	
	await get_tree().create_timer(0.5).timeout

func check_block_breaker_clear(match_positions: Array):
	"""Check if Block Breaker relic should clear adjacent obstacles"""
	for relic in active_relics:
		if relic["type"] == "match_clear_obstacle":
			if match_positions.size() >= relic["data"].get("min_blocks", 4):
				# Find adjacent obstacles
				for pos in match_positions:
					var adjacent = [
						Vector2i(pos.x - 1, pos.y),
						Vector2i(pos.x + 1, pos.y),
						Vector2i(pos.x, pos.y - 1),
						Vector2i(pos.x, pos.y + 1)
					]
					
					for adj_pos in adjacent:
						if puzzle_grid.is_valid_position(adj_pos.x, adj_pos.y):
							var cell = puzzle_grid.grid[adj_pos.y][adj_pos.x]
							if cell.is_obstacle:
								match cell.obstacle_type:
									"web":
										puzzle_grid.remove_web(adj_pos.x, adj_pos.y)
									"slime":
										puzzle_grid.remove_all_slime_in_column(adj_pos.x)
									"rock", _:
										puzzle_grid.remove_block(adj_pos.x, adj_pos.y)
										cell.is_obstacle = false
										cell.obstacle_type = ""
								
								add_to_combat_log("🔨 Block Breaker destroyed an obstacle!")
								return  # Only destroy 1 obstacle per match
			break

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

# Update trigger_victory() to save power
func trigger_victory():
	"""Handle victory with fade transition"""
	game_over = true
	AudioManager.stop_low_health_warning()
	AudioManager.play_music("victory", 1.0)
	var damage_taken = GameManager.get_max_health() - GameManager.get_current_health()
	
	# Award XP to party
	award_battle_xp()
	
	# Save character power for next battle (unless boss)
	if not is_boss_battle:
		GameManager.current_run["character_power"] = character_power.duplicate()
	
	GameManager.save_game()
	GameManager.clear_battle_info()
	
	# Fade to black
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.z_index = 2000
	add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0)
	
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	
	if is_boss_battle:
		get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/map_view.tscn")

func trigger_game_over():
	"""Handle game over"""
	game_over = true
	AudioManager.stop_low_health_warning()
	AudioManager.play_music("defeat", 1.0)
	
	# Clear character power on death
	if GameManager.current_run.has("character_power"):
		GameManager.current_run.erase("character_power")
	
	# End run as failure
	GameManager.end_run(false)
	GameManager.clear_battle_info()
	
	# Go to game over screen
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func berserker_cleave(damage: int):
	"""Berserker Cleave - damage carries to next enemy if overkill"""
	if enemies.size() == 0:
		return
	
	var remaining_damage = damage
	var enemy_index = 0
	
	while remaining_damage > 0 and enemy_index < enemies.size():
		var enemy = enemies[enemy_index]
		var overkill = max(0, remaining_damage - enemy["current_hp"])
		
		enemy["current_hp"] -= remaining_damage
		add_to_combat_log("⚔️ Cleaved %s for %d damage!" % [enemy["data"].enemy_name, min(remaining_damage, enemy["max_hp"])])
		
		update_enemy_hp(enemy_index)
		
		if enemy["current_hp"] <= 0:
			enemy_defeated(enemy_index)
			remaining_damage = overkill
		else:
			break
	
	if remaining_damage > 0:
		add_to_combat_log("💥 Overkill damage: %d" % remaining_damage)

func necromancer_drain_life(amount: int):
	"""Necromancer Drain Life - damage enemy, heal party, convert blocks"""
	if enemies.size() > 0:
		var enemy = enemies[0]
		var actual_damage = min(amount, enemy["current_hp"])
		enemy["current_hp"] -= actual_damage
		add_to_combat_log("🧛 Drained %d life from %s!" % [actual_damage, enemy["data"].enemy_name])
		update_enemy_hp(0)
		
		heal_party(actual_damage)
		
		if enemy["current_hp"] <= 0:
			enemy_defeated(0)
	
	var converted = 0
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var block_color = puzzle_grid.get_block_color(x, y)
			if block_color == "gray" or block_color == "brown" or block_color == "white":
				var new_colors = ["red", "blue", "yellow"]
				var new_color = new_colors[randi() % new_colors.size()]
				puzzle_grid.remove_block(x, y)
				puzzle_grid.place_block(x, y, new_color)
				converted += 1
				if converted >= amount:
					return
	
	if converted > 0:
		add_to_combat_log("🔮 Converted %d neutral blocks!" % converted)

func ranger_multishot(total_damage: int):
	"""Ranger Multi-Shot - split damage between all enemies"""
	if enemies.size() == 0:
		return
	
	var damage_per_enemy = int(total_damage / enemies.size())
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		enemy["current_hp"] -= damage_per_enemy
		update_enemy_hp(i)
		
		if enemy["current_hp"] <= 0:
			enemy_defeated(i)
			i -= 1
	
	add_to_combat_log("🏹 Multi-Shot hit %d enemies for %d each!" % [enemies.size(), damage_per_enemy])

func beastmaster_summon(char_data: CharacterData, level: int, multiplier: float):
	"""Beastmaster summons a random beast"""
	var beasts = char_data.special_data.get("beasts", [])
	if beasts.is_empty():
		return
	
	var tier_index = 0
	if level <= 3:
		tier_index = 0
	elif level <= 6:
		tier_index = 1
	else:
		tier_index = 2
	
	var weighted_beasts = []
	for beast in beasts:
		var weight = beast["weight"][tier_index]
		for i in range(weight):
			weighted_beasts.append(beast)
	
	var beast = weighted_beasts[randi() % weighted_beasts.size()]
	var damage = int(beast["damage"][tier_index] * multiplier)
	
	add_to_combat_log("🐾 %s summons a %s!" % [char_data.character_name, beast["name"]])
	deal_damage_to_enemy(damage)

func bladesinger_bladesong(damage: int, buff_amount: int):
	"""Bladesinger deals damage and buffs ally"""
	if enemies.size() > 0:
		var target_index = randi() % enemies.size()
		var enemy = enemies[target_index]
		enemy["current_hp"] -= damage
		update_enemy_hp(target_index)
		add_to_combat_log("💃 Bladesong strikes %s for %d!" % [enemy["data"].enemy_name, damage])
		
		if enemy["current_hp"] <= 0:
			enemy_defeated(target_index)
	
	if party.size() > 0:
		var ally = party[randi() % party.size()]
		add_to_combat_log("✨ %s's next match boosted by %d!" % [ally.capitalize(), buff_amount])
	

func enemy_attack(enemy: Dictionary):
	"""Enemy deals damage to party"""
	var damage = enemy["data"].attack_damage
	
	# Check for Crusader's Aegis (Templar ability)
	var has_aegis = false
	if GameManager.current_run.has("active_buffs"):
		for buff in GameManager.current_run["active_buffs"]:
			if buff["type"] == "crusaders_aegis" and buff["turns_remaining"] > 0:
				has_aegis = true
				break
	
	if has_aegis:
		# Damage becomes healing
		GameManager.modify_health(damage)
		add_to_combat_log("✨ Aegis converts %d damage to healing!" % damage)
		return
	
	# Check for immunity (Dreadknight ability)
	var has_immunity = false
	if GameManager.current_run.has("active_buffs"):
		for buff in GameManager.current_run["active_buffs"]:
			if buff["type"] == "immunity" and buff["turns_remaining"] > 0:
				has_immunity = true
				break
	
	if has_immunity:
		add_to_combat_log("🛡️ Immunity blocks all damage!")
		return
	
	# Check for blind effect (Lightbringer)
	var is_blinded = false
	if GameManager.current_run.has("active_buffs"):
		for buff in GameManager.current_run["active_buffs"]:
			if buff["type"] == "blind" and buff["turns_remaining"] > 0:
				if randf() < 0.5:  # 50% miss chance
					is_blinded = true
				break
	
	if is_blinded:
		add_to_combat_log("☀️ %s's attack misses (blinded)!" % enemy["data"].enemy_name)
		return
	
	# Apply Glass Cannon penalty
	for relic in active_relics:
		if relic["type"] == "glass_cannon":
			damage = int(damage * (1.0 + relic["data"].get("damage_taken_penalty", 0.15)))
			break
	
	# Apply Adamantine Armor reduction
	for relic in active_relics:
		if relic["type"] == "damage_reduction":
			var reduction = relic["data"].get("flat_reduction", 2)
			damage = max(1, damage - reduction)
			add_to_combat_log("🛡️ Armor reduces damage by %d!" % reduction)
			break

	# Normal damage processing continues...
	damage = apply_shield_wall(damage)
	
	# Check for Barkskin reflect damage
	var reflected = apply_barkskin_reflect()
	if reflected > 0:
		# Deal reflect damage to attacking enemy
		for i in range(enemies.size()):
			if enemies[i] == enemy:
				enemy["current_hp"] -= reflected
				add_to_combat_log("🌿 Barkskin reflects %d damage!" % reflected)
				update_enemy_hp(i)
				
				if enemy["current_hp"] <= 0:
					enemy_defeated(i)
				break
	
	if damage > 0:
		# Check for Vengeful Spirit
		for relic in active_relics:
			if relic["type"] == "thorns":
				if damage >= relic["data"].get("damage_threshold", 15):
					var reflect_dmg = relic["data"].get("reflect_damage", 10)
					for i in range(enemies.size()):
						if enemies[i] == enemy:
							enemy["current_hp"] -= reflect_dmg
							add_to_combat_log("👻 Vengeful Spirit reflects %d damage!" % reflect_dmg)
							update_enemy_hp(i)
							if enemy["current_hp"] <= 0:
								enemy_defeated(i)
							break
					break
		
		# Check for Phoenix Feather before taking lethal damage
		var current_hp = GameManager.get_current_health()
		if current_hp - damage <= 0:
			var relics = GameManager.current_run.get("relics", [])
			for i in range(relics.size() - 1, -1, -1):
				var relic = relics[i]
				if relic["type"] == "phoenix_feather":
					# Activate phoenix feather
					var heal_percent = relic["data"].get("heal_percent", 0.25)
					var max_hp = GameManager.get_max_health()
					var heal_amount = int(max_hp * heal_percent)
					
					add_to_combat_log("🔥 PHOENIX FEATHER ACTIVATES!")
					flash_screen(0.5)
					GameManager.modify_health(heal_amount)
					add_to_combat_log("💖 Restored %d HP! (Relic destroyed)" % heal_amount)
					
					# Remove the relic (it breaks)
					relics.remove_at(i)
					GameManager.current_run
					GameManager.current_run["relics"] = relics
					GameManager.save_game()
					
					# Don't take the damage that would have killed us
					damage = 0
					break
		
		GameManager.modify_health(-damage)
		add_to_combat_log("💥 %s attacks for %d damage!" % [enemy["data"].enemy_name, damage])
	
	await get_tree().create_timer(0.3).timeout


func handle_enemy_special_ability(enemy: Dictionary):
	"""Handle enemy special abilities"""
	var enemy_data = enemy["data"]
	var trigger = enemy_data.special_ability_trigger
	var enemy_id = enemy.get("id", "")
	
	# Initialize counter if needed
	if not enemy_special_ability_counters.has(enemy_id):
		enemy_special_ability_counters[enemy_id] = 0
	
	match trigger:
		"on_attack":  # Multiple enemies with on-attack abilities
			match enemy_id:
				"lycanthrope":
					await lycanthrope_transform(enemy)
				"goblin_mage":
					await goblin_mage_buff(enemy)
				"mummy":
					await mummy_bind(enemy)
				"giant_rat":
					await giant_rat_disease(enemy)
				"shadow_assassin":
					await shadow_assassin_critical(enemy)
				"mimic":
					# Mimic's surprise attack only happens on spawn, not on_attack
					await enemy_attack(enemy)
				_:
					# Default attack
					var damage = enemy_data.attack_damage
					GameManager.modify_health(-damage)
					add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])
		
		"on_spawn":  # Mimic surprise attack
			if enemy_id == "mimic":
				await mimic_surprise_attack(enemy)
		
		"passive":  # Stone Golem damage reduction, Troll regeneration, Wraith evasion, Gargoyle stone skin
			# Passive abilities are handled elsewhere
			# Just do normal attack
			var damage = enemy_data.attack_damage
			GameManager.modify_health(-damage)
			add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])
		
		"passive_aura":  # Plague Bearer
			if enemy_id == "plague_bearer":
				await plague_bearer_aura(enemy)
		
		"every_3_attacks":  # Orc Shaman, Harpy, Medusa
			enemy_special_ability_counters[enemy_id] += 1
			if enemy_special_ability_counters[enemy_id] >= 3:
				enemy_special_ability_counters[enemy_id] = 0
				match enemy_id:
					"orc_shaman":
						await orc_shaman_curse(enemy)
					"harpy":
						await harpy_wind_gust(enemy)
					"medusa":
						await medusa_petrifying_gaze(enemy)
					_:
						await enemy_attack(enemy)
			else:
				await enemy_attack(enemy)
		
		"every_4_attacks":  # Dragon Boss, War Golem
			enemy_special_ability_counters[enemy_id] += 1
			if enemy_special_ability_counters[enemy_id] >= 4:
				enemy_special_ability_counters[enemy_id] = 0
				match enemy_id:
					"dragon_boss":
						await dragon_fury(enemy)
					"war_golem":
						await war_golem_siege_mode(enemy)
					_:
						await enemy_attack(enemy)
			else:
				await enemy_attack(enemy)
		
		"every_5_attacks":  # Dark Sorcerer
			enemy_special_ability_counters[enemy_id] += 1
			if enemy_special_ability_counters[enemy_id] >= 5:
				enemy_special_ability_counters[enemy_id] = 0
				if enemy_id == "dark_sorcerer":
					await dark_sorcerer_arcane_missiles(enemy)
				else:
					await enemy_attack(enemy)
			else:
				await enemy_attack(enemy)
		
		"every_5_turns":  # Demon Boss
			enemy_special_ability_counters[enemy_id] += 1
			if enemy_special_ability_counters[enemy_id] >= 5:
				enemy_special_ability_counters[enemy_id] = 0
				await demon_presence(enemy)
			else:
				await enemy_attack(enemy)
		
		"turn_5":  # Goblin Chief, Frost Giant
			if current_turn >= 5 and not enemy_special_ability_counters.get(enemy_id + "_used", false):
				enemy_special_ability_counters[enemy_id + "_used"] = true
				match enemy_id:
					"goblin_chief":
						await goblin_chief_summon(enemy)
					"frost_giant":
						await frost_giant_blizzard(enemy)
					_:
						await enemy_attack(enemy)
			else:
				await enemy_attack(enemy)
		
		"health_50_percent":  # Lich Boss
			if not enemy_special_ability_counters.get(enemy_id + "_summoned", false):
				if enemy["current_hp"] <= enemy["max_hp"] / 2:
					enemy_special_ability_counters[enemy_id + "_summoned"] = true
					await lich_raise_dead(enemy)
					return
			await enemy_attack(enemy)
		
		"health_thresholds":  # Necromancer Elite
			if enemy_id == "necromancer_elite":
				await necromancer_raise_dead(enemy)
			else:
				await enemy_attack(enemy)
		
		"on_death":  # Undead Warrior
			if enemy_id == "undead_warrior":
				# Handled in enemy_defeated function
				await enemy_attack(enemy)
			else:
				await enemy_attack(enemy)
		
		"on_damaged":  # Berserker Champion
			if enemy_id == "berserker_champion":
				await berserker_champion_enrage(enemy)
			else:
				await enemy_attack(enemy)
		
		"multi_phase":  # Kraken, Void Horror
			match enemy_id:
				"kraken":
					await kraken_multi_phase(enemy)
				"void_horror":
					await void_horror_multi_phase(enemy)
				_:
					await enemy_attack(enemy)
		
		_:
			# Unknown trigger, just attack
			await enemy_attack(enemy)
	
	await get_tree().create_timer(0.3).timeout

# === BOSS SPECIAL ABILITIES ===

func dragon_fury(enemy: Dictionary):
	"""Dragon destroys blocks and deals bonus damage"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	add_to_combat_log("🔥 %s uses Dragon's Fury!" % enemy_data.enemy_name)
	
	# Destroy random blocks
	var blocks_to_destroy = ability_data.get("blocks_destroyed", 8)
	clear_random_blocks(blocks_to_destroy)
	
	# Deal bonus damage
	var bonus_damage = ability_data.get("bonus_damage", 15)
	GameManager.modify_health(-bonus_damage)
	add_to_combat_log("☄️ Devastating flames deal %d damage!" % bonus_damage)

func lich_raise_dead(enemy: Dictionary):
	"""Lich summons skeleton minions"""
	var enemy_data = enemy["data"]
	
	add_to_combat_log("💀 %s raises the dead!" % enemy_data.enemy_name)
	
	# Summon 2 skeletons
	for i in range(2):
		if enemies.size() >= 3:
			break
		
		var skeleton_type = EnemySpawnManager.EnemyType.SKELETON
		var difficulty = GameManager.current_run.get("currentFloor", 1)
		var skeleton = spawn_manager.create_enemy_instance(skeleton_type, difficulty)
		
		if skeleton:
			skeleton["current_cooldown"] = randi_range(1, skeleton["attack_cooldown"])
			enemies.append(skeleton)
			add_to_combat_log("💀 %s rises!" % skeleton["data"].enemy_name)
	
	setup_enemies()

func demon_presence(enemy: Dictionary):
	"""Demon increases its attack damage permanently"""
	var enemy_data = enemy["data"]
	
	add_to_combat_log("😈 %s emanates demonic power!" % enemy_data.enemy_name)
	
	# Increase attack damage by 2
	enemy_data.attack_damage += 2
	
	add_to_combat_log("⚠️ %s's attacks grow stronger! (Now %d damage)" % [enemy_data.enemy_name, enemy_data.attack_damage])

# === ELITE SPECIAL ABILITIES ===

func goblin_chief_summon(enemy: Dictionary):
	"""Goblin Chief summons a goblin"""
	var enemy_data = enemy["data"]
	
	add_to_combat_log("📢 %s calls for reinforcements!" % enemy_data.enemy_name)
	
	if enemies.size() >= 3:
		add_to_combat_log("But there's no room!")
		return
	
	var goblin_type = EnemySpawnManager.EnemyType.GOBLIN
	var difficulty = GameManager.current_run.get("currentFloor", 1)
	var goblin = spawn_manager.create_enemy_instance(goblin_type, difficulty)
	
	if goblin:
		goblin["current_cooldown"] = randi_range(1, goblin["attack_cooldown"])
		enemies.append(goblin)
		add_to_combat_log("⚔️ %s answers the call!" % goblin["data"].enemy_name)
		setup_enemies()

func orc_shaman_curse(enemy: Dictionary):
	"""Orc Shaman converts character blocks to neutral"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	add_to_combat_log("🌀 %s curses your blocks!" % enemy_data.enemy_name)
	
	var blocks_to_convert = ability_data.get("blocks_to_convert", 3)
	var character_blocks = []
	
	# Find all character-colored blocks
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color == "red" or color == "blue" or color == "yellow":
				character_blocks.append(Vector2i(x, y))
	
	if character_blocks.size() == 0:
		add_to_combat_log("But there are no blocks to curse!")
		return
	
	# Randomly select blocks to convert
	character_blocks.shuffle()
	var converted = 0
	
	for i in range(min(blocks_to_convert, character_blocks.size())):
		var pos = character_blocks[i]
		puzzle_grid.remove_block(pos.x, pos.y)
		puzzle_grid.place_block(pos.x, pos.y, "gray")
		converted += 1
	
	add_to_combat_log("🔮 Converted %d blocks to neutral!" % converted)
	
	await get_tree().create_timer(0.3).timeout

func enemy_place_obstacle(enemy: Dictionary):
	"""Enemy places an obstacle on the grid"""
	var enemy_data = enemy["data"]
	var obstacle_type = enemy_data.obstacle_type
	var obstacle_count = max(1, enemy_data.obstacle_count)
	
	add_to_combat_log("🕸️ %s places obstacles!" % enemy_data.enemy_name)
	
	match obstacle_type:
		"web":
			for i in range(obstacle_count):
				place_random_web()
			add_to_combat_log("  Placed %d webs!" % obstacle_count)
		
		"slime":
			var column = randi() % puzzle_grid.GRID_WIDTH
			puzzle_grid.place_slime(column)
			add_to_combat_log("  Slime column at %d!" % column)
		
		"rock":
			for i in range(obstacle_count):
				place_random_rock()
			add_to_combat_log("  Placed %d rocks!" % obstacle_count)
		
		"fire":
			for i in range(obstacle_count):
				place_random_web()  # Use web as fire placeholder
			add_to_combat_log("  Placed %d fire obstacles!" % obstacle_count)
		
		"corruption":
			for i in range(obstacle_count):
				place_random_rock()  # Use rock as corruption placeholder
			add_to_combat_log("  Placed %d corrupted blocks!" % obstacle_count)
		
		_:
			# Unknown obstacle type, just attack instead
			var damage = enemy_data.attack_damage
			GameManager.modify_health(-damage)
			add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])
	
	await get_tree().create_timer(0.3).timeout

func enemy_summon(enemy: Dictionary):
	"""Enemy summons reinforcements"""
	var enemy_data = enemy["data"]
	var summon_id = enemy_data.summon_enemy_id
	var summon_count = enemy_data.summon_count
	
	add_to_combat_log("🌀 %s summons!" % enemy_data.enemy_name)
	
	for i in range(summon_count):
		if enemies.size() >= 3:
			break
		
		var current_floor = GameManager.current_run.get("currentFloor", 1)
		var summoned_type = get_enemy_type_from_summon_id(summon_id)
		var summoned = spawn_manager.create_enemy_instance(summoned_type, current_floor)
		
		if summoned:
			summoned["current_cooldown"] = randi_range(1, summoned["attack_cooldown"])
			enemies.append(summoned)
			add_to_combat_log("  %s joins!" % summoned["data"].enemy_name)
	
	if enemy_data.can_summon:
		enemy["next_summon_turn"] = current_turn + enemy_data.summon_delay
	
	setup_enemies()
	await get_tree().create_timer(0.3).timeout

# Add these functions to BattleScene.gd

func remove_random_obstacles(count: int) -> int:
	"""Remove random obstacles from the grid (Paladin ability). Returns number removed."""
	var obstacles_found = []
	
	# Find all obstacles
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var cell = puzzle_grid.grid[y][x]
			if cell.is_obstacle:
				obstacles_found.append(Vector2i(x, y))
	
	if obstacles_found.size() == 0:
		return 0
	
	# Remove random obstacles up to count
	obstacles_found.shuffle()
	var removed = 0
	for i in range(min(count, obstacles_found.size())):
		var pos = obstacles_found[i]
		var cell = puzzle_grid.grid[pos.y][pos.x]
		
		match cell.obstacle_type:
			"web":
				puzzle_grid.remove_web(pos.x, pos.y)
				removed += 1
			"slime":
				# Remove slime column
				puzzle_grid.remove_all_slime_in_column(pos.x)
				removed += 1
			"rock":
				puzzle_grid.remove_block(pos.x, pos.y)
				cell.is_obstacle = false
				cell.obstacle_type = ""
				removed += 1
	
	return removed

func place_random_web():
	"""Place a web obstacle in a random valid location (below row 3)"""
	var valid_positions = []
	
	# Find all valid positions (below row 3, empty, no obstacles)
	for y in range(3, puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			if puzzle_grid.is_empty(x, y):
				valid_positions.append(Vector2i(x, y))
	
	if valid_positions.size() == 0:
		return  # No valid positions
	
	# Place web at random position
	var pos = valid_positions[randi() % valid_positions.size()]
	puzzle_grid.place_web(pos.x, pos.y)
	add_to_combat_log("🕸️ Web placed at (%d, %d)" % [pos.x, pos.y])

func place_random_rock():
	"""Place a rock obstacle in a random valid location"""
	var valid_positions = []
	
	# Find all valid positions (empty, no obstacles, below row 3)
	for y in range(3, puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			if puzzle_grid.is_empty(x, y):
				valid_positions.append(Vector2i(x, y))
	
	if valid_positions.size() == 0:
		return  # No valid positions
	
	# Place rock at random position
	var pos = valid_positions[randi() % valid_positions.size()]
	puzzle_grid.grid[pos.y][pos.x].is_obstacle = true
	puzzle_grid.grid[pos.y][pos.x].obstacle_type = "rock"
	puzzle_grid.place_block(pos.x, pos.y, "gray")  # Rocks are gray colored
	add_to_combat_log("🪨 Rock placed at (%d, %d)" % [pos.x, pos.y])

func get_enemy_type_from_summon_id(summon_id: String) -> EnemySpawnManager.EnemyType:
	"""Convert summon enemy ID string to EnemyType enum"""
	# Use the spawn_manager's conversion function
	return spawn_manager.get_enemy_type_from_id(summon_id)

func award_battle_xp():
	"""Award XP to party members after battle"""
	var base_xp = 20  # Base XP per battle
	
	# Bonus XP based on battle info
	var battle_info = GameManager.get_battle_info()
	var is_elite = battle_info.get("is_elite", false)
	var difficulty = battle_info.get("difficulty", 1)
	
	var xp_multiplier = 1.0
	if is_elite:
		xp_multiplier = 2.0  # Elite battles give 2x XP
	
	# Scale with difficulty (floor number)
	var total_xp = base_xp * difficulty * xp_multiplier
	
	# Award XP to each party member
	for char_id in party:
		GameManager.add_pending_xp(char_id, total_xp)
		var char_data = CharacterDatabase.get_character(char_id)
		if char_data:
			
			add_to_combat_log("⭐ %s gained %.0f XP!" % [char_data.character_name, total_xp])

# ========== CHARACTER ABILITY IMPLEMENTATIONS ==========

func knight_shield_wall(shield_amount: int):
	"""Knight's Shield Wall - absorbs damage"""
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "shield_wall",
		"shield_remaining": shield_amount
	})
	
	add_to_combat_log("🛡️ Shield Wall raised! Absorbs up to %d damage" % shield_amount)
	GameManager.save_game()

func wizard_meteor_storm(damage: int, blocks_to_clear: int):
	"""Wizard's Meteor Storm - damage and clear blocks"""
	if enemies.size() > 0:
		deal_damage_to_enemy(damage)
		add_to_combat_log("☄️ Meteor deals %d damage!" % damage)
	else:
		add_to_combat_log("☄️ Meteor finds no target!")
	
	clear_random_blocks(blocks_to_clear)
	add_to_combat_log("☄️ Clears %d random blocks!" % blocks_to_clear)

func cleric_healing_light(amount: int):
	"""Cleric's Healing Light - restore party HP"""
	var current_hp = GameManager.get_current_health()
	var max_hp = GameManager.get_max_health()
	var actual_heal = min(amount, max_hp - current_hp)
	GameManager.current_run["healing_used_this_run"] = true
	
	GameManager.modify_health(amount)
	
	var new_hp = GameManager.get_current_health()
	add_to_combat_log("❤️ Healed party for %d HP! (%d/%d)" % [actual_heal, new_hp, max_hp])

func rogue_assassinate(damage: int):
	"""Rogue's Assassinate - massive single target damage"""
	if enemies.size() > 0:
		deal_damage_to_enemy(damage)
		add_to_combat_log("🗡️ Assassinate deals %d damage!" % damage)
	else:
		add_to_combat_log("🗡️ No target for Assassinate!")

func paladin_purify(obstacles_count: int):
	"""Paladin's Purifying Light - remove obstacles"""
	var removed = remove_random_obstacles(obstacles_count)
	if removed > 0:
		add_to_combat_log("✨ Purifying Light removes %d obstacles!" % removed)
	else:
		add_to_combat_log("✨ No obstacles to purify!")

func druid_barkskin(heal_per_turn: int, reflect_damage: int, duration: int):
	"""Druid's Barkskin - heal over time and reflect damage"""
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	GameManager.current_run["healing_used_this_run"] = true
	GameManager.current_run["active_buffs"].append({
		"type": "barkskin",
		"heal_per_turn": heal_per_turn,
		"reflect_damage": reflect_damage,
		"turns_remaining": duration
	})
	
	add_to_combat_log("🌿 Barkskin: +%d HP/turn, %d reflect for %d turns" % [heal_per_turn, reflect_damage, duration])
	GameManager.save_game()


func enchanter_mesmerize(stun_duration: int):
	"""Enchanter's Mesmerize - stun enemies"""
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	# Bosses only stunned for 1 turn
	var actual_duration = stun_duration
	if is_boss_battle:
		actual_duration = 1
		add_to_combat_log("😵 Boss resists! Stunned for only 1 turn")
	else:
		add_to_combat_log("😵 Enemies mesmerized for %d turns!" % actual_duration)
	
	GameManager.current_run["active_buffs"].append({
		"type": "stun",
		"turns_remaining": actual_duration
	})
	GameManager.save_game()

func monk_temporal_mastery(extra_turns: int):
	"""Monk's Temporal Mastery - extend buffs"""
	if not GameManager.current_run.has("active_buffs"):
		add_to_combat_log("⏰ No buffs to extend")
		return
	
	var buffs = GameManager.current_run["active_buffs"]
	var extended_count = 0
	
	for buff in buffs:
		if buff.has("turns_remaining") and buff["type"] != "stun":
			buff["turns_remaining"] += extra_turns
			extended_count += 1
	
	if extended_count > 0:
		add_to_combat_log("⏰ Extended %d buff(s) by %d turns!" % [extended_count, extra_turns])
		GameManager.save_game()
	else:
		add_to_combat_log("⏰ No buffs to extend")

func process_active_buffs():
	"""Process buffs like Barkskin at start of enemy turn"""
	bound_characters.clear()
	
	if not GameManager.current_run.has("active_buffs"):
		return
	
	var buffs = GameManager.current_run["active_buffs"]
	var buffs_to_remove = []
	
	for i in range(buffs.size()):
		var buff = buffs[i]
		
		match buff["type"]:
			"disease":
				# Deal disease damage
				var damage = buff["damage_per_turn"]
				GameManager.modify_health(-damage)
				add_to_combat_log("🦠 Disease deals %d damage!" % damage)
				
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("🦠 Disease wears off...")
			"barkskin":
				# Heal party
				var heal = buff["heal_per_turn"]
				GameManager.modify_health(heal)
				add_to_combat_log("🌿 Barkskin heals party for %d HP" % heal)
				
				# Decrease duration
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("🌿 Barkskin fades...")
			
			"stun":
				# Decrease stun duration
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("😵 Stun wears off...")
					
			"rune_trap_zone":
				# Count blocks in zone
				var blocks_in_zone = count_blocks_in_zone(buff["center"], 3)
				
				if blocks_in_zone > 0:
					var damage = blocks_in_zone * buff["damage_per_block"]
					deal_damage_to_enemy(damage)
					add_to_combat_log("🔥 Rune Trap: %d blocks = %d damage!" % [blocks_in_zone, damage])
				
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("🔥 Rune Trap expires...")
					# Remove visual
					var zone_node = puzzle_grid.get_node_or_null("RuneZone_%d_%d" % [buff["center"].x, buff["center"].y])
					if zone_node:
						zone_node.queue_free()
			
			"healing_grove_zone":
				# Count blocks in zone
				var blocks_in_zone = count_blocks_in_zone(buff["center"], 3)
				
				if blocks_in_zone > 0:
					var heal = blocks_in_zone * buff["heal_per_block"]
					GameManager.modify_health(heal)
					add_to_combat_log("🌳 Healing Grove: %d blocks = %d healing!" % [blocks_in_zone, heal])
				
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("🌳 Healing Grove withers...")
					# Remove visual
					var zone_node = puzzle_grid.get_node_or_null("RuneZone_%d_%d" % [buff["center"].x, buff["center"].y])
					if zone_node:
						zone_node.queue_free()
			
			"world_tree":
				# Heal, damage, and remove obstacles
				var heal = buff["heal_per_turn"]
				var damage = buff["damage_per_turn"]
				var obstacles = buff["obstacles_per_turn"]
				
				GameManager.modify_health(heal)
				deal_damage_to_enemy(damage)
				
				# Remove obstacles
				var removed = 0
				for y in range(puzzle_grid.GRID_HEIGHT):
					for x in range(puzzle_grid.GRID_WIDTH):
						if puzzle_grid.grid[y][x].is_obstacle and removed < obstacles:
							if puzzle_grid.grid[y][x].obstacle_type == "web":
								puzzle_grid.remove_web(x, y)
							removed += 1
				
				add_to_combat_log("🌳 World Tree: %d heal, %d damage, %d obstacles removed" % [heal, damage, removed])
				
				# World Tree is permanent (turns_remaining = 999)
			
			"summoned_demon":
				# Demon attacks
				var damage = buff["damage_per_turn"]
				deal_damage_to_enemy(damage)
				add_to_combat_log("😈 %s attacks for %d damage!" % [buff["demon_name"], damage])
				
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("😈 %s returns to the infernal plane..." % buff["demon_name"])
			
			"immunity":
				# Dreadknight immunity
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("🛡️ Immunity fades...")
			
			"crusaders_aegis":
				# Templar's Aegis - handled in enemy_attack()
				buff["turns_remaining"] -= 1
				if buff["turns_remaining"] <= 0:
					buffs_to_remove.append(i)
					add_to_combat_log("✨ Crusader's Aegis fades...")
	
	# Remove expired buffs
	for i in range(buffs_to_remove.size() - 1, -1, -1):
		buffs.remove_at(buffs_to_remove[i])
	
	GameManager.current_run["active_buffs"] = buffs
	GameManager.save_game()

func apply_shield_wall(incoming_damage: int) -> int:
	"""Apply Shield Wall damage absorption, return remaining damage"""
	if not GameManager.current_run.has("active_buffs"):
		return incoming_damage
	
	var buffs = GameManager.current_run["active_buffs"]
	var buffs_to_remove = []
	var remaining_damage = incoming_damage
	
	for i in range(buffs.size()):
		var buff = buffs[i]
		if buff["type"] == "shield_wall":
			var shield = buff["shield_remaining"]
			var absorbed = min(shield, remaining_damage)
			
			buff["shield_remaining"] -= absorbed
			remaining_damage -= absorbed
			
			add_to_combat_log("🛡️ Shield Wall absorbs %d damage!" % absorbed)
			
			if buff["shield_remaining"] <= 0:
				buffs_to_remove.append(i)
				add_to_combat_log("🛡️ Shield Wall shattered!")
			
			break  # Only one shield at a time
	
	# Remove broken shields
	for i in range(buffs_to_remove.size() - 1, -1, -1):
		buffs.remove_at(buffs_to_remove[i])
	
	GameManager.current_run["active_buffs"] = buffs
	GameManager.save_game()
	
	return remaining_damage

func is_enemy_stunned() -> bool:
	"""Check if enemies are currently stunned"""
	if not GameManager.current_run.has("active_buffs"):
		return false
	
	var buffs = GameManager.current_run["active_buffs"]
	for buff in buffs:
		if buff["type"] == "stun" and buff["turns_remaining"] > 0:
			return true
	
	return false
	
func apply_barkskin_reflect() -> int:
	"""Check if Barkskin is active and return reflect damage"""
	if not GameManager.current_run.has("active_buffs"):
		return 0
	
	var buffs = GameManager.current_run["active_buffs"]
	for buff in buffs:
		if buff["type"] == "barkskin":
			return buff["reflect_damage"]
	
	return 0

func update_enemy_count_display():
	"""Update the enemy count label"""
	var info_panel = get_node_or_null("InfoPanel")
	if not info_panel:
		return
	
	var enemy_count_label = info_panel.get_node_or_null("EnemyCountLabel")
	if enemy_count_label:
		var total_enemies = enemies.size() + enemy_spawn_queue.size()
		enemy_count_label.text = "Enemies: %d" % total_enemies


		
func shake_camera(intensity: float):
	"""Shake the camera for impact"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var original_offset = camera.offset
	var shake_count = 6
	var shake_duration = 0.05
	
	for i in range(shake_count):
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		camera.offset = original_offset + shake_offset
		await get_tree().create_timer(shake_duration).timeout
	
	camera.offset = original_offset

func show_floating_damage(enemy_index: int, damage: int):
	"""Show floating damage number above enemy"""
	if enemy_index >= enemy_ui.size():
		return
	
	var enemy_ui_data = enemy_ui[enemy_index]
	var container = enemy_ui_data["container"]
	
	var damage_label = Label.new()
	damage_label.text = "-%d" % damage
	damage_label.add_theme_font_size_override("font_size", 32)
	damage_label.add_theme_color_override("font_color", Color("#E74C3C"))
	damage_label.add_theme_constant_override("outline_size", 6)
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	damage_label.position = Vector2(container.position.x + 40, container.position.y + 20)
	damage_label.z_index = 100
	
	enemy_panel.add_child(damage_label)
	
	# Animate floating up and fading
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 50, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	
	await tween.finished
	damage_label.queue_free()

func create_background_particles():
	"""Add subtle floating particles to background"""
	var particles = CPUParticles2D.new()
	particles.position = Vector2(640, 360)  # Center of screen
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 8.0
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE  # Changed from EMISSION_SHAPE_BOX
	particles.emission_rect_extents = Vector2(640, 360)  # Changed from emission_box_extents
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.gravity = Vector2(0, -20)
	particles.initial_velocity_min = 10
	particles.initial_velocity_max = 30
	particles.angular_velocity_min = -45
	particles.angular_velocity_max = 45
	particles.scale_amount_min = 1
	particles.scale_amount_max = 3
	particles.color = Color(1, 1, 1, 0.1)
	particles.z_index = -5
	
	add_child(particles)

func flash_character_portrait(char_index: int):
	"""Flash character portrait when using ability"""
	if char_index >= character_ui.size():
		return
	
	var ui = character_ui[char_index]
	var portrait = ui["portrait"]
	
	var tween = create_tween()
	tween.set_loops(2)
	tween.tween_property(portrait, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.2)
	tween.tween_property(portrait, "modulate", Color.WHITE, 0.2)

func animate_enemy_defeat(enemy_index: int):
	"""Animate enemy defeat - fade and scale out"""
	if enemy_index >= enemy_ui.size():
		return
	
	var ui = enemy_ui[enemy_index]
	if not ui or not ui.has("container"):
		return
		
	var container = ui["container"]
	if not is_instance_valid(container):
		return
	
	# Store original scale
	var original_scale = container.scale
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "modulate:a", 0.0, 0.5)
	tween.tween_property(container, "scale", original_scale * 1.2, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	# Reset for next use
	if is_instance_valid(container):
		container.modulate.a = 1.0
		container.scale = original_scale

func flash_screen(intensity: float = 0.3):
	"""Flash the screen white for impact"""
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, intensity)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 1000
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	await tween.finished
	flash.queue_free()

func show_synergy_banner(synergy_name: String, multiplier: float):
	"""Show a banner when synergy activates"""
	var banner = PanelContainer.new()
	banner.position = Vector2(640 - 200, 100)
	banner.z_index = 500
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.3, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.8, 0.0)
	banner.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	banner.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚡ SYNERGY ⚡"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var name_label = Label.new()
	name_label.text = synergy_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	var mult_label = Label.new()
	mult_label.text = "%.0f%% Damage!" % (multiplier * 100)
	mult_label.add_theme_font_size_override("font_size", 18)
	mult_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(mult_label)
	
	add_child(banner)
	
	# Animate in and out
	banner.modulate.a = 0.0
	banner.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(2.5).timeout
	
	var fade_tween = create_tween()
	fade_tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	banner.queue_free()

func create_pause_menu():
	"""Create the pause menu overlay"""
	pause_menu = Panel.new()
	pause_menu.name = "PauseMenu"
	pause_menu.z_index = 1000  # Above everything
	pause_menu.visible = false
	
	# Center on screen using anchors
	pause_menu.set_anchors_preset(Control.PRESET_CENTER)
	pause_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pause_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	pause_menu.custom_minimum_size = Vector2(400, 500)
	pause_menu.offset_left = -200  # Half of width
	pause_menu.offset_top = -250   # Half of height
	pause_menu.offset_right = 200
	pause_menu.offset_bottom = 250
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0862745, 0.129412, 0.243137, 0.95)  # Dark blue, semi-transparent
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.952941, 0.611765, 0.0705882, 1)  # Gold
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	pause_menu.add_theme_stylebox_override("panel", style)
	
	# Content
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	pause_menu.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.952941, 0.611765, 0.0705882, 1))
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Resume button
	var resume_btn = create_pause_button("Resume")
	resume_btn.pressed.connect(_on_pause_resume)
	vbox.add_child(resume_btn)
	
	# Mute/Unmute button
	var mute_btn = create_pause_button("Mute Audio")
	mute_btn.name = "MuteButton"
	mute_btn.pressed.connect(_on_pause_mute)
	vbox.add_child(mute_btn)
	
	# Fullscreen toggle
	var fullscreen_btn = create_pause_button("Toggle Fullscreen")
	fullscreen_btn.pressed.connect(_on_pause_fullscreen)
	vbox.add_child(fullscreen_btn)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	# Give Up button (warning color)
	var give_up_btn = create_pause_button("Give Up")
	give_up_btn.pressed.connect(_on_pause_give_up)
	# Make it red
	give_up_btn.add_theme_color_override("font_color", Color(0.905882, 0.298039, 0.235294, 1))
	vbox.add_child(give_up_btn)
	
	# Exit Game button
	var exit_btn = create_pause_button("Exit Game")
	exit_btn.pressed.connect(_on_pause_exit)
	vbox.add_child(exit_btn)
	
	add_child(pause_menu)

func create_pause_button(text: String) -> Button:
	"""Create a styled pause menu button"""
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 50)
	
	# Style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.172549, 0.243137, 0.313726, 1)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.952941, 0.611765, 0.0705882, 1)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.corner_radius_bottom_left = 8
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.203922, 0.286275, 0.368627, 1)
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_font_size_override("font_size", 20)
	
	return btn

func toggle_pause():
	"""Toggle pause state"""
	if not pause_menu:
		return
	
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused
	
	# Update mute button text
	update_mute_button_text()
	
	if is_paused:
		AudioManager.play_button_click()

func update_mute_button_text():
	"""Update the mute button to show current state"""
	var mute_btn = pause_menu.find_child("MuteButton")
	if mute_btn:
		var is_muted = AudioManager.master_volume == 0.0
		mute_btn.text = "Unmute Audio" if is_muted else "Mute Audio"

# ========== PAUSE MENU CALLBACKS ==========

func _on_pause_resume():
	"""Resume game"""
	AudioManager.play_button_click()
	toggle_pause()

func _on_pause_mute():
	"""Toggle audio mute"""
	AudioManager.play_button_click()
	
	# Toggle mute
	if AudioManager.master_volume > 0.0:
		# Mute
		GameManager.set_option("previousMasterVolume", AudioManager.master_volume)
		AudioManager.set_master_volume(0.0)
	else:
		# Unmute
		var previous = GameManager.options.get("previousMasterVolume", 0.8)
		AudioManager.set_master_volume(previous)
	
	update_mute_button_text()

func _on_pause_fullscreen():
	"""Toggle fullscreen"""
	AudioManager.play_button_click()
	
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_pause_give_up():
	"""Give up current run (treat as loss)"""
	AudioManager.play_button_click()
	
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Give up this battle?\n\nYour run will end and all progress will be lost."
	dialog.ok_button_text = "Give Up"
	dialog.cancel_button_text = "Cancel"
	
	# Style the dialog
	dialog.add_theme_font_size_override("font_size", 18)
	
	dialog.confirmed.connect(func():
		# Unpause
		get_tree().paused = false
		
		# Stop music/sounds
		AudioManager.stop_low_health_warning()
		
		# End run as failure
		GameManager.end_run(false)
		GameManager.clear_battle_info()
		
		# Go to game over screen
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
		
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _on_pause_exit():
	"""Exit game completely"""
	AudioManager.play_button_click()
	
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.dialog_text = "Exit to desktop?\n\nYour current battle progress will be lost."
	dialog.ok_button_text = "Exit"
	dialog.cancel_button_text = "Cancel"
	
	dialog.confirmed.connect(func():
		get_tree().quit()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func lycanthrope_transform(enemy: Dictionary):
	"""Lycanthrope attempts transformation into werewolf"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	var transform_chance = ability_data.get("transform_chance", 0.4)
	
	if randf() < transform_chance:
		# TRANSFORMATION!
		add_to_combat_log("🐺 %s transforms into a WEREWOLF!" % enemy_data.enemy_name)
		
		# Update stats
		var werewolf_health = ability_data.get("werewolf_health", 65)
		enemy["current_hp"] = werewolf_health
		enemy["max_hp"] = werewolf_health
		enemy["data"].attack_damage = ability_data.get("werewolf_damage", 13)
		enemy["attack_cooldown"] = ability_data.get("werewolf_frequency", 5)
		enemy["current_cooldown"] = ability_data.get("werewolf_frequency", 5)
		
		# Change ID and name
		enemy["id"] = "werewolf"
		enemy["data"].enemy_name = "Werewolf"
		enemy["data"].special_ability_name = ""
		enemy["data"].has_special_ability = false
		
		# Visual update
		setup_enemies()
		
		add_to_combat_log("⚡ Werewolf healed to full HP and gains increased power!")
	else:
		# Normal attack
		var damage = enemy_data.attack_damage
		GameManager.modify_health(-damage)
		add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])

func goblin_mage_buff(enemy: Dictionary):
	"""Goblin Mage buffs all goblin allies"""
	var enemy_data = enemy["data"]
	
	# Count goblin allies
	var goblins_buffed = 0
	var buff_type = ["damage", "haste", "heal"][randi() % 3]
	
	for other_enemy in enemies:
		var other_id = other_enemy.get("id", "")
		if "goblin" in other_id:
			match buff_type:
				"damage":
					other_enemy["data"].attack_damage += 2
					goblins_buffed += 1
				"haste":
					other_enemy["current_cooldown"] = max(1, other_enemy["current_cooldown"] - 1)
					goblins_buffed += 1
				"heal":
					other_enemy["current_hp"] = min(other_enemy["max_hp"], other_enemy["current_hp"] + 5)
					goblins_buffed += 1
	
	if goblins_buffed > 0:
		add_to_combat_log("✨ %s casts Goblin Blessing! (%s)" % [enemy_data.enemy_name, buff_type])
		setup_enemies()  # Refresh UI
	else:
		# No goblins to buff, just attack
		var damage = enemy_data.attack_damage
		GameManager.modify_health(-damage)
		add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])

func mummy_bind(enemy: Dictionary):
	"""Mummy attempts to bind a character"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	var bind_chance = ability_data.get("bind_chance", 0.25)
	
	# Normal attack first
	var damage = enemy_data.attack_damage
	GameManager.modify_health(-damage)
	add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])
	
	# Try to bind
	if randf() < bind_chance and party.size() > 0:
		var target_char = party[randi() % party.size()]
		var char_data = CharacterDatabase.get_character(target_char)
		
		bound_characters[target_char] = 1  # Bound for 1 turn (until mummy's next turn)
		add_to_combat_log("🎃 %s binds %s! No power gain until next turn!" % [enemy_data.enemy_name, char_data.character_name])

func troll_regeneration(neutral_blocks_matched: int):
	"""Troll regenerates when neutral blocks are matched"""
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.get("id", "") == "troll":
			var heal_amount = neutral_blocks_matched * 3
			enemy["current_hp"] = min(enemy["max_hp"], enemy["current_hp"] + heal_amount)
			
			add_to_combat_log("🩹 Troll regenerates %d HP from neutral matches!" % heal_amount)
			update_enemy_hp(i)
# ========== NEW ENEMY ABILITIES ==========

func giant_rat_disease(enemy: Dictionary):
	"""Giant Rat inflicts disease damage over time"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	# Normal attack first
	var damage = enemy_data.attack_damage
	GameManager.modify_health(-damage)
	add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])
	
	# Apply disease
	if not GameManager.current_run.has("active_buffs"):
		GameManager.current_run["active_buffs"] = []
	
	GameManager.current_run["active_buffs"].append({
		"type": "disease",
		"damage_per_turn": ability_data.get("disease_damage", 1),
		"turns_remaining": ability_data.get("disease_duration", 3)
	})
	
	add_to_combat_log("🦠 Party is diseased! Losing %d HP per turn!" % ability_data.get("disease_damage", 1))
	GameManager.save_game()

func shadow_assassin_critical(enemy: Dictionary):
	"""Shadow Assassin has chance to deal double damage"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	var damage = enemy_data.attack_damage
	
	var crit_chance = ability_data.get("crit_chance", 0.3)
	var crit_multiplier = ability_data.get("crit_multiplier", 2.0)
	
	if randf() < crit_chance:
		damage = int(damage * crit_multiplier)
		add_to_combat_log("🗡️ CRITICAL STRIKE!")
		flash_screen(0.3)
	
	GameManager.modify_health(-damage)
	add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])

func mimic_surprise_attack(enemy: Dictionary):
	"""Mimic attacks immediately on spawn"""
	var enemy_data = enemy["data"]
	var damage = enemy_data.attack_damage
	
	add_to_combat_log("😱 %s surprises you!" % enemy_data.enemy_name)
	GameManager.modify_health(-damage)
	add_to_combat_log("💥 Surprise attack deals %d damage!" % damage)

func plague_bearer_aura(enemy: Dictionary):
	"""Plague Bearer damages party each turn"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	# Check if aura should be active this turn
	var starts_turn = ability_data.get("starts_turn", 2)
	if current_turn >= starts_turn:
		var aura_damage = ability_data.get("aura_damage", 3)
		GameManager.modify_health(-aura_damage)
		add_to_combat_log("☠️ Pestilence aura deals %d damage!" % aura_damage)
	
	# Normal attack too
	var damage = enemy_data.attack_damage
	GameManager.modify_health(-damage)
	add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, damage])

func dark_sorcerer_arcane_missiles(enemy: Dictionary):
	"""Dark Sorcerer destroys random player blocks"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	add_to_combat_log("🌟 %s unleashes Arcane Missiles!" % enemy_data.enemy_name)
	
	var blocks_to_destroy = ability_data.get("blocks_to_destroy", 5)
	var player_blocks = []
	
	# Find all player-colored blocks
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color == "red" or color == "blue" or color == "yellow":
				player_blocks.append(Vector2i(x, y))
	
	if player_blocks.size() == 0:
		add_to_combat_log("But there are no player blocks to destroy!")
		await enemy_attack(enemy)
		return
	
	# Destroy random blocks
	player_blocks.shuffle()
	var destroyed = 0
	for i in range(min(blocks_to_destroy, player_blocks.size())):
		var pos = player_blocks[i]
		puzzle_grid.remove_block(pos.x, pos.y)
		destroyed += 1
	
	add_to_combat_log("💥 Destroyed %d player blocks!" % destroyed)
	
	# Apply gravity
	await get_tree().create_timer(0.2).timeout
	puzzle_grid.apply_gravity()

func frost_giant_blizzard(enemy: Dictionary):
	"""Frost Giant freezes blocks and deals AoE damage"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	add_to_combat_log("❄️ %s unleashes Blizzard!" % enemy_data.enemy_name)
	
	# Deal AoE damage
	var aoe_damage = ability_data.get("aoe_damage", 8)
	GameManager.modify_health(-aoe_damage)
	add_to_combat_log("💥 Blizzard deals %d damage to party!" % aoe_damage)
	
	# Freeze random blocks (convert to ice)
	var blocks_to_freeze = ability_data.get("blocks_to_freeze", 10)
	var all_blocks = []
	
	for y in range(puzzle_grid.GRID_HEIGHT):
		for x in range(puzzle_grid.GRID_WIDTH):
			if puzzle_grid.get_block_color(x, y) != "":
				all_blocks.append(Vector2i(x, y))
	
	all_blocks.shuffle()
	var frozen = 0
	for i in range(min(blocks_to_freeze, all_blocks.size())):
		var pos = all_blocks[i]
		puzzle_grid.remove_block(pos.x, pos.y)
		puzzle_grid.place_block(pos.x, pos.y, "white")  # Ice blocks are white
		frozen += 1
	
	add_to_combat_log("❄️ Froze %d blocks!" % frozen)

func necromancer_raise_dead(enemy: Dictionary):
	"""Necromancer summons skeletons at health thresholds"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	var thresholds = ability_data.get("health_thresholds", [0.5, 0.25])
	
	var hp_percent = float(enemy["current_hp"]) / float(enemy["max_hp"])
	
	# Check each threshold
	for threshold in thresholds:
		var threshold_key = enemy["id"] + "_threshold_" + str(threshold)
		if hp_percent <= threshold and not enemy_special_ability_counters.get(threshold_key, false):
			enemy_special_ability_counters[threshold_key] = true
			
			add_to_combat_log("💀 %s raises the dead!" % enemy_data.enemy_name)
			
			# Summon skeletons
			var summon_count = ability_data.get("summon_count", 2)
			for i in range(summon_count):
				if enemies.size() >= 3:
					break
				
				var skeleton_type = EnemySpawnManager.EnemyType.SKELETON
				var difficulty = GameManager.current_run.get("currentFloor", 1)
				var skeleton = spawn_manager.create_enemy_instance(skeleton_type, difficulty)
				
				if skeleton:
					skeleton["current_cooldown"] = randi_range(1, skeleton["attack_cooldown"])
					enemies.append(skeleton)
					add_to_combat_log("💀 Skeleton rises!")
			
			setup_enemies()
			return
	
	# Normal attack if no threshold triggered
	await enemy_attack(enemy)

func medusa_petrifying_gaze(enemy: Dictionary):
	"""Medusa turns bottom rows to stone"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	add_to_combat_log("👁️ %s uses Petrifying Gaze!" % enemy_data.enemy_name)
	
	var rows_to_petrify = ability_data.get("rows_to_petrify", 2)
	var petrified = 0
	
	# Turn bottom rows to gray (stone)
	for row in range(rows_to_petrify):
		var y = puzzle_grid.GRID_HEIGHT - 1 - row
		for x in range(puzzle_grid.GRID_WIDTH):
			var color = puzzle_grid.get_block_color(x, y)
			if color != "" and color != "gray":
				puzzle_grid.remove_block(x, y)
				puzzle_grid.place_block(x, y, "gray")
				petrified += 1
	
	if petrified > 0:
		add_to_combat_log("🗿 Petrified %d blocks!" % petrified)
	else:
		add_to_combat_log("But the bottom rows are empty!")

func harpy_wind_gust(enemy: Dictionary):
	"""Harpy shuffles blocks in random columns"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	add_to_combat_log("💨 %s uses Wind Gust!" % enemy_data.enemy_name)
	
	var columns_to_shuffle = ability_data.get("columns_to_shuffle", 2)
	
	for i in range(columns_to_shuffle):
		var column = randi() % puzzle_grid.GRID_WIDTH
		
		# Get all blocks in column
		var column_blocks = []
		for y in range(puzzle_grid.GRID_HEIGHT):
			var color = puzzle_grid.get_block_color(column, y)
			if color != "":
				column_blocks.append(color)
				puzzle_grid.remove_block(column, y)
		
		# Shuffle and replace
		column_blocks.shuffle()
		var block_index = 0
		for y in range(puzzle_grid.GRID_HEIGHT - 1, -1, -1):
			if block_index < column_blocks.size():
				puzzle_grid.place_block(column, y, column_blocks[block_index])
				block_index += 1
	
	add_to_combat_log("💨 Shuffled %d columns!" % columns_to_shuffle)

func war_golem_siege_mode(enemy: Dictionary):
	"""War Golem places rocks and gains damage"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	add_to_combat_log("⚙️ %s enters Siege Mode!" % enemy_data.enemy_name)
	
	# Place rocks
	var rocks_to_place = ability_data.get("rocks_to_place", 3)
	for i in range(rocks_to_place):
		place_random_rock()
	
	# Increase damage
	var damage_increase = ability_data.get("damage_increase", 5)
	enemy_data.attack_damage += damage_increase
	
	add_to_combat_log("⚔️ Attack damage increased to %d!" % enemy_data.attack_damage)

func berserker_champion_enrage(enemy: Dictionary):
	"""Berserker Champion gains damage when hit"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	
	# Track damage bonus
	if not enemy.has("enrage_bonus"):
		enemy["enrage_bonus"] = 0
	
	var damage_per_hit = ability_data.get("damage_per_hit", 2)
	var max_bonus = ability_data.get("max_damage_bonus", 10)
	
	enemy["enrage_bonus"] = min(enemy["enrage_bonus"] + damage_per_hit, max_bonus)
	
	add_to_combat_log("😡 %s enrages! (+%d damage)" % [enemy_data.enemy_name, enemy["enrage_bonus"]])
	
	# Attack with bonus damage
	var total_damage = enemy_data.attack_damage + enemy["enrage_bonus"]
	GameManager.modify_health(-total_damage)
	add_to_combat_log("💥 %s attacks for %d damage!" % [enemy_data.enemy_name, total_damage])
	
	# Reset bonus after attack
	enemy["enrage_bonus"] = 0

func kraken_multi_phase(enemy: Dictionary):
	"""Kraken has multiple phases based on HP"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	var hp_percent = float(enemy["current_hp"]) / float(enemy["max_hp"])
	
	# Check for phase 2 transition
	if hp_percent <= 0.5 and not enemy_special_ability_counters.get(enemy["id"] + "_phase2", false):
		enemy_special_ability_counters[enemy["id"] + "_phase2"] = true
		
		add_to_combat_log("🌊 Kraken enters Phase 2!")
		
		var phase2 = ability_data.get("phase_2", {})
		
		# Clear columns
		var columns_to_clear = phase2.get("columns_to_clear", 2)
		for i in range(columns_to_clear):
			var column = randi() % puzzle_grid.GRID_WIDTH
			for y in range(puzzle_grid.GRID_HEIGHT):
				puzzle_grid.remove_block(column, y)
		
		add_to_combat_log("🌊 Whirlpool clears %d columns!" % columns_to_clear)
		
		# Deal damage
		var whirlpool_damage = phase2.get("whirlpool_damage", 15)
		GameManager.modify_health(-whirlpool_damage)
		add_to_combat_log("💥 Whirlpool deals %d damage!" % whirlpool_damage)
		
		# Increase attack damage
		var damage_increase = phase2.get("damage_increase", 5)
		enemy_data.attack_damage += damage_increase
		
		# Summon minions if room
		var summon_count = phase2.get("summon_count", 2)
		for i in range(summon_count):
			if enemies.size() >= 3:
				break
			# Note: "giant_squid" would need to be added as an enemy type
			# For now, summon something else as placeholder
			add_to_combat_log("🦑 Kraken summons tentacles!")
		
		setup_enemies()
	else:
		# Normal attack
		await enemy_attack(enemy)

func void_horror_multi_phase(enemy: Dictionary):
	"""Void Horror has three devastating phases"""
	var enemy_data = enemy["data"]
	var ability_data = enemy_data.special_ability_data
	var hp_percent = float(enemy["current_hp"]) / float(enemy["max_hp"])
	
	# Phase 3 (≤33% HP)
	if hp_percent <= 0.33 and not enemy_special_ability_counters.get(enemy["id"] + "_phase3", false):
		enemy_special_ability_counters[enemy["id"] + "_phase3"] = true
		
		add_to_combat_log("🌀 APOCALYPSE PHASE!")
		
		var phase3 = ability_data.get("phase_3", {})
		
		# Massive damage
		var apocalypse_damage = phase3.get("apocalypse_damage", 25)
		GameManager.modify_health(-apocalypse_damage)
		add_to_combat_log("💥 Reality-warping chaos deals %d damage!" % apocalypse_damage)
		
		# Increase attack speed and damage
		var freq_reduction = phase3.get("frequency_reduction", 2)
		enemy["attack_cooldown"] = max(1, enemy["attack_cooldown"] - freq_reduction)
		
		var damage_increase = phase3.get("damage_increase", 7)
		enemy_data.attack_damage += damage_increase
		
		add_to_combat_log("⚠️ Void Horror becomes even more dangerous!")
		
	# Phase 2 (≤66% HP)
	elif hp_percent <= 0.66 and not enemy_special_ability_counters.get(enemy["id"] + "_phase2", false):
		enemy_special_ability_counters[enemy["id"] + "_phase2"] = true
		
		add_to_combat_log("🌀 Void Horror consumes reality!")
		
		var phase2 = ability_data.get("phase_2", {})
		
		# Heal
		var heal_amount = phase2.get("heal_amount", 30)
		enemy["current_hp"] = min(enemy["max_hp"], enemy["current_hp"] + heal_amount)
		add_to_combat_log("💜 Void Horror heals %d HP!" % heal_amount)
		update_enemy_hp(0)
		
		# Summon void spawns if room
		var summon_count = phase2.get("summon_count", 2)
		for i in range(summon_count):
			if enemies.size() >= 3:
				break
			add_to_combat_log("👾 Void spawn emerges!")
		
	else:
		# Phase 1 - Reality Tear
		var phase1 = ability_data.get("phase_1", {})
		
		# Teleport random blocks
		var blocks_to_teleport = phase1.get("blocks_to_teleport", 10)
		var all_blocks = []
		
		for y in range(puzzle_grid.GRID_HEIGHT):
			for x in range(puzzle_grid.GRID_WIDTH):
				var color = puzzle_grid.get_block_color(x, y)
				if color != "":
					all_blocks.append({"pos": Vector2i(x, y), "color": color})
		
		all_blocks.shuffle()
		
		# Remove and re-place in random positions
		var blocks_to_move = all_blocks.slice(0, min(blocks_to_teleport, all_blocks.size()))
		for block_data in blocks_to_move:
			puzzle_grid.remove_block(block_data["pos"].x, block_data["pos"].y)
		
		for block_data in blocks_to_move:
			var new_x = randi() % puzzle_grid.GRID_WIDTH
			var new_y = randi() % puzzle_grid.GRID_HEIGHT
			if puzzle_grid.is_empty(new_x, new_y):
				puzzle_grid.place_block(new_x, new_y, block_data["color"])
		
		add_to_combat_log("🌀 Reality tears! Blocks teleported!")
		
		# Normal attack
		await enemy_attack(enemy)
