# audio_manager.gd - Updated with new sound effects
extends Node

# Audio bus indices
var master_bus_idx: int
var music_bus_idx: int
var sfx_bus_idx: int

# Music players
var music_player: AudioStreamPlayer
var music_crossfade_player: AudioStreamPlayer

# SFX player pool (for overlapping sounds)
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 16

# Current music track
var current_music: String = ""
var is_fading: bool = false

# Volume settings (0.0 to 1.0)
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.9

# Low health warning
var low_health_player: AudioStreamPlayer
var is_low_health_playing: bool = false

# Audio paths
var music_tracks = {
	"main_menu": "res://assets/audio/music/main_menu.wav",
	"battle": "res://assets/audio/music/battle.ogg",
	"boss_battle": "res://assets/audio/music/boss_battle.WAV",
	"victory": "res://assets/audio/music/victory.wav",
	"defeat": "res://assets/audio/music/defeat.wav"
}

var sfx_sounds = {
	# Block sounds
	"block_match": "res://assets/audio/sfx/sfx_exp_short_hard1.wav",
	"block_land": "res://assets/audio/sfx/block_land.ogg",
	"block_rotate": "res://assets/audio/sfx/block_rotate.ogg",
	
	# Enemy damage/death sounds
	"enemy_damage_monster": "res://assets/audio/sfx/sfx_deathscream_alien1.wav",  # Golem, etc.
	"enemy_damage_spider": "res://assets/audio/sfx/sfx_deathscream_alien2.wav",   # Spiders
	"enemy_damage_humanoid": "res://assets/audio/sfx/sfx_deathscream_human2.wav", # Orcs, Goblins
	
	# Combat sounds
	"damage_deal": "res://assets/audio/sfx/damage_deal.ogg",
	"damage_heavy": "res://assets/audio/sfx/damage_heavy.ogg",
	
	# UI sounds
	"button_hover": "res://assets/audio/sfx/sfx_menu_move1.wav",
	"button_click": "res://assets/audio/sfx/sfx_menu_select1.wav",
	"coin_pickup": "res://assets/audio/sfx/coin_pickup.ogg",
	"level_up": "res://assets/audio/sfx/level_up.ogg",
	
	# Warning sounds
	"low_health_warning": "res://assets/audio/sfx/sfx_lowhealth_alarmloop1.wav",
	
	# Power/ability sounds
	"power_gain": "res://assets/audio/sfx/power_gain.ogg",
	"power_full": "res://assets/audio/sfx/power_full.ogg",
	"ability_activate": "res://assets/audio/sfx/ability_activate.ogg",
	"heal": "res://assets/audio/sfx/heal.ogg",
	"buff": "res://assets/audio/sfx/buff.ogg",
	"stun": "res://assets/audio/sfx/stun.ogg",
	
	# Combo sounds
	"combo_x2": "res://assets/audio/sfx/combo_x2.ogg",
	"combo_x3": "res://assets/audio/sfx/combo_x3.ogg",
	"combo_x4": "res://assets/audio/sfx/combo_x4.ogg"
}

func _ready():	
	# Get bus indices
	master_bus_idx = AudioServer.get_bus_index("Master")
	music_bus_idx = AudioServer.get_bus_index("Music")
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	
	# Create music players
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	music_crossfade_player = AudioStreamPlayer.new()
	music_crossfade_player.bus = "Music"
	add_child(music_crossfade_player)
	
	# Create low health warning player (looping)
	low_health_player = AudioStreamPlayer.new()
	low_health_player.bus = "SFX"
	add_child(low_health_player)
	
	# Create SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		sfx_players.append(player)
		add_child(player)
	
	# Load volume settings from GameManager
	load_volume_settings()
	apply_volume_settings()
	

func load_volume_settings():
	"""Load volume settings from GameManager"""
	if GameManager.options.has("masterVolume"):
		master_volume = GameManager.options["masterVolume"]
	if GameManager.options.has("musicVolume"):
		music_volume = GameManager.options["musicVolume"]
	if GameManager.options.has("sfxVolume"):
		sfx_volume = GameManager.options["sfxVolume"]

func apply_volume_settings():
	"""Apply volume to audio buses"""
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(sfx_volume))

func set_master_volume(volume: float):
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(master_volume))
	GameManager.set_option("masterVolume", master_volume)

func set_music_volume(volume: float):
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(music_volume))
	GameManager.set_option("musicVolume", music_volume)

func set_sfx_volume(volume: float):
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(sfx_volume))
	GameManager.set_option("sfxVolume", sfx_volume)

# ========== MUSIC FUNCTIONS ==========

func play_music(track_name: String, fade_duration: float = 1.0):
	"""Play a music track with optional crossfade"""
	if current_music == track_name and music_player.playing:
		return
	
	if not music_tracks.has(track_name):
		return
	
	var track_path = music_tracks[track_name]
	if not ResourceLoader.exists(track_path):
		return
	
	var stream = load(track_path)
	
	if music_player.playing:
		await crossfade_music(stream, fade_duration)
	else:
		music_player.stream = stream
		music_player.play()
	
	current_music = track_name

func crossfade_music(new_stream: AudioStream, duration: float):
	"""Crossfade between current and new music"""
	if is_fading:
		return
	
	is_fading = true
	
	music_crossfade_player.stream = new_stream
	music_crossfade_player.volume_db = -80
	music_crossfade_player.play()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(music_player, "volume_db", -80, duration)
	tween.tween_property(music_crossfade_player, "volume_db", 0, duration)
	
	await tween.finished
	
	music_player.stop()
	music_player.stream = new_stream
	music_player.volume_db = 0
	music_player.play()
	music_crossfade_player.stop()
	
	is_fading = false

func stop_music(fade_duration: float = 1.0):
	"""Stop music with fade out"""
	if not music_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, fade_duration)
	await tween.finished
	
	music_player.stop()
	music_player.volume_db = 0
	current_music = ""

# ========== SFX FUNCTIONS ==========

func play_sfx(sfx_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0):
	"""Play a sound effect"""
	if not sfx_sounds.has(sfx_name):
		return
	
	var sfx_path = sfx_sounds[sfx_name]
	if not ResourceLoader.exists(sfx_path):
		return
	
	var player = get_available_sfx_player()
	if not player:
		return
	
	var stream = load(sfx_path)
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()

func get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available SFX player from the pool"""
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]

# ========== SPECIAL SOUND FUNCTIONS ==========

func play_enemy_damage_sound(enemy_id: String):
	"""Play appropriate damage sound based on enemy type"""
	var sound_name = "enemy_damage_humanoid"  # Default
	
	# Determine sound based on enemy ID
	match enemy_id:
		"golem":
			sound_name = "enemy_damage_monster"
		"spider":
			sound_name = "enemy_damage_spider"
		"goblin", "goblin_chief", "orc", "orc_shaman", "skeleton":
			sound_name = "enemy_damage_humanoid"
		"slime":
			sound_name = "enemy_damage_spider"  # High pitched for slime
		"dragon_boss", "demon_boss", "lich_boss":
			sound_name = "enemy_damage_monster"
	
	play_sfx(sound_name)

func start_low_health_warning():
	"""Start playing the low health warning loop"""
	if is_low_health_playing:
		return
	
	var sfx_path = sfx_sounds["low_health_warning"]
	if not ResourceLoader.exists(sfx_path):
		return
	
	var stream = load(sfx_path)
	low_health_player.stream = stream
	low_health_player.play()
	is_low_health_playing = true

func stop_low_health_warning():
	"""Stop the low health warning loop"""
	if not is_low_health_playing:
		return
	
	low_health_player.stop()
	is_low_health_playing = false

# ========== HELPER FUNCTIONS ==========

func play_button_click():
	"""Convenience function for button clicks"""
	play_sfx("button_click")

func play_button_hover():
	"""Convenience function for button hover"""
	play_sfx("button_hover", 1.0, -10.0)

func play_combo_sound(combo_level: int):
	"""Play combo sound based on combo level"""
	if combo_level == 2:
		play_sfx("combo_x2")
	elif combo_level == 3:
		play_sfx("combo_x3")
	elif combo_level >= 4:
		play_sfx("combo_x4")

func play_match_sound(combo_level: int = 1):
	"""Play block match sound with pitch variation"""
	var pitch = 1.0 + (combo_level - 1) * 0.15
	play_sfx("block_match", pitch)
