# boss_intro.gd
extends Control

@onready var objective_title = $ObjectiveTitle
@onready var objective_text = $ObjectiveText
@onready var boss_portrait = $BossPortrait
@onready var boss_name_label = $BossNameLabel
@onready var boss_description = $BossDescription
@onready var prepare_button = $PrepareButton
@onready var stats_label = $StatsLabel

func _ready():
	prepare_button.pressed.connect(_on_prepare_pressed)
	AudioManager.play_music("boss_battle", 3.0)  # Slow fade for tension
	# Load objective data
	var objective = GameManager.current_run.get("objective", {})
	var boss_id = objective.get("boss_id", "dragon_boss")
	var boss_data = EnemyDatabase.get_enemy(boss_id)
	
	# Display objective
	objective_title.text = "Final Challenge"
	objective_text.text = objective.get("title", "Defeat the boss!")
	
	# Display boss info
	if boss_data:
		boss_name_label.text = boss_data.enemy_name
		boss_description.text = boss_data.attack_description
		
		# Load boss portrait
		if boss_data.sprite_path != "" and ResourceLoader.exists(boss_data.sprite_path):
			boss_portrait.texture = load(boss_data.sprite_path)
		else:
			boss_portrait.modulate = boss_data.color
		
		# Show boss stats
		var floor = GameManager.current_run.get("currentFloor", 1)
		var hp = boss_data.get_health_for_floor(floor)
		stats_label.text = "HP: %d | Attack: %d | Frequency: Every %d turns" % [
			hp,
			boss_data.attack_damage,
			boss_data.attack_frequency
		]
	
	# Animate entrance
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.0)

func _on_prepare_pressed():
	"""Start the boss battle"""
	# Set up boss battle in GameManager
	GameManager.start_battle(false)  # Not elite, but we'll mark it as boss
	GameManager.pending_battle["is_boss"] = true
	
	# Go to battle scene
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")
