extends Control

# This script handles individual character/enemy cards in the collection

signal card_clicked(entity_id: String)

@onready var portrait_rect = $PortraitRect
@onready var name_label = $NameLabel


var entity_id: String = ""
var entity_type: String = "character"  # "character" or "enemy"
var is_unlocked: bool = false
var tooltip_parent: Control = null

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup_character(char_id: String, tooltip_ref: Control):
	"""Initialize card with character data"""
	entity_id = char_id
	entity_type = "character"
	tooltip_parent = tooltip_ref
	
	var char_data = CharacterDatabase.get_character(char_id)
	if not char_data:
		print("ERROR: Character data not found for: ", char_id)
		return
	
	# Set name
	name_label.text = char_data.character_name
	
	print("Setting up character: ", char_id)
	print("Portrait path: ", char_data.portrait_path)
	print("Portrait path exists: ", ResourceLoader.exists(char_data.portrait_path))
	
	# Load portrait if available, otherwise use color placeholder
	if char_data.portrait_path != "" and ResourceLoader.exists(char_data.portrait_path):
		print("Loading portrait texture...")
		var texture = load(char_data.portrait_path)
		print("Texture loaded: ", texture != null)
		
		# Check if portrait_rect is ColorRect and convert to TextureRect
		if portrait_rect is ColorRect:
			print("Converting ColorRect to TextureRect")
			# Create new TextureRect
			var texture_rect = TextureRect.new()
			texture_rect.name = "PortraitRect"
			texture_rect.texture = texture
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Copy properties
			texture_rect.position = portrait_rect.position
			texture_rect.size = portrait_rect.size
			texture_rect.anchor_left = portrait_rect.anchor_left
			texture_rect.anchor_top = portrait_rect.anchor_top
			texture_rect.anchor_right = portrait_rect.anchor_right
			texture_rect.anchor_bottom = portrait_rect.anchor_bottom
			texture_rect.offset_left = portrait_rect.offset_left
			texture_rect.offset_top = portrait_rect.offset_top
			texture_rect.offset_right = portrait_rect.offset_right
			texture_rect.offset_bottom = portrait_rect.offset_bottom
			texture_rect.pivot_offset = portrait_rect.pivot_offset
			
			# Replace in scene tree
			var parent = portrait_rect.get_parent()
			var index = portrait_rect.get_index()
			parent.remove_child(portrait_rect)
			parent.add_child(texture_rect)
			parent.move_child(texture_rect, index)
			portrait_rect.queue_free()
			portrait_rect = texture_rect
		elif portrait_rect is TextureRect:
			print("Already TextureRect, setting texture")
			portrait_rect.texture = texture
	else:
		print("Using color placeholder")
		# Use color placeholder
		if portrait_rect is ColorRect:
			portrait_rect.color = char_data.color
	
	# Check if unlocked
	is_unlocked = GameManager.is_character_unlocked(char_id)
	


func setup_enemy(enemy_id: String, tooltip_ref: Control):
	"""Initialize card with enemy data"""
	entity_id = enemy_id
	entity_type = "enemy"
	tooltip_parent = tooltip_ref
	
	var enemy_data = EnemyDatabase.get_enemy(enemy_id)
	if not enemy_data:
		print("ERROR: Enemy data not found for: ", enemy_id)
		return
	
	# Set name
	name_label.text = enemy_data.enemy_name
	
	print("Setting up enemy: ", enemy_id)
	print("Sprite path: ", enemy_data.sprite_path)
	print("Sprite path exists: ", ResourceLoader.exists(enemy_data.sprite_path) if enemy_data.sprite_path != "" else false)
	
	# Load portrait if available, otherwise use color placeholder
	if enemy_data.sprite_path != "" and ResourceLoader.exists(enemy_data.sprite_path):
		print("Loading enemy sprite texture...")
		var texture = load(enemy_data.sprite_path)
		print("Texture loaded: ", texture != null)
		
		# Check if portrait_rect is ColorRect and convert to TextureRect
		if portrait_rect is ColorRect:
			print("Converting ColorRect to TextureRect for enemy")
			var texture_rect = TextureRect.new()
			texture_rect.name = "PortraitRect"
			texture_rect.texture = texture
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Copy properties
			texture_rect.position = portrait_rect.position
			texture_rect.size = portrait_rect.size
			texture_rect.anchor_left = portrait_rect.anchor_left
			texture_rect.anchor_top = portrait_rect.anchor_top
			texture_rect.anchor_right = portrait_rect.anchor_right
			texture_rect.anchor_bottom = portrait_rect.anchor_bottom
			texture_rect.offset_left = portrait_rect.offset_left
			texture_rect.offset_top = portrait_rect.offset_top
			texture_rect.offset_right = portrait_rect.offset_right
			texture_rect.offset_bottom = portrait_rect.offset_bottom
			texture_rect.pivot_offset = portrait_rect.pivot_offset
			
			# Replace in scene tree
			var parent = portrait_rect.get_parent()
			var index = portrait_rect.get_index()
			parent.remove_child(portrait_rect)
			parent.add_child(texture_rect)
			parent.move_child(texture_rect, index)
			portrait_rect.queue_free()
			portrait_rect = texture_rect
		elif portrait_rect is TextureRect:
			print("Already TextureRect, setting texture for enemy")
			portrait_rect.texture = texture
	else:
		print("Using color placeholder for enemy")
		# Use color placeholder
		if portrait_rect is ColorRect:
			portrait_rect.color = enemy_data.color
	


func _on_mouse_entered():
	"""Show tooltip when hovering"""
	if tooltip_parent:
		if entity_type == "character":
			tooltip_parent.show_character_tooltip(entity_id)
		else:
			tooltip_parent.show_enemy_tooltip(entity_id)
	
	# Hover effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)

func _on_mouse_exited():
	"""Hide tooltip when mouse leaves"""
	if tooltip_parent:
		tooltip_parent.hide_tooltip()
	
	# Reset scale
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _on_gui_input(event: InputEvent):
	"""Handle clicks on card"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(entity_id)
