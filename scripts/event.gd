# event.gd
extends Control

@onready var title_label = $TitleLabel
@onready var description_label = $DescriptionLabel
@onready var options_container = $OptionsContainer
@onready var result_panel = $ResultPanel
@onready var result_label = $ResultPanel/MarginContainer/ResultLabel
@onready var continue_button = $ContinueButton

# Merchant panel
@onready var merchant_panel = $MerchantPanel
@onready var merchant_relics_container = $MerchantPanel/MarginContainer/VBoxContainer/RelicsContainer
@onready var merchant_back_button = $MerchantPanel/MarginContainer/VBoxContainer/BackButton

var event_chosen: bool = false
var current_event: Dictionary = {}

# All events
var events: Array = []

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	merchant_back_button.pressed.connect(_on_merchant_back)
	continue_button.visible = false
	result_panel.visible = false
	merchant_panel.visible = false
	
	setup_events()
	select_random_event()

func setup_events():
	"""Define all 20 events"""
	events = [
		{
			"title": "Wandering Merchant",
			"description": "A mysterious merchant with exotic wares appears before you.",
			"options": [
				{"text": "Browse Wares", "callback": _event_merchant},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Fountain of Youth",
			"description": "A pristine fountain emanates healing energy.",
			"options": [
				{"text": "Drink (Restore 20 HP, +20 power all)", "callback": _event_fountain_drink},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Training Dummy",
			"description": "A well-worn training dummy stands ready for practice.",
			"options": [
				{"text": "Practice Combat", "callback": _event_training},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Mysterious Stranger",
			"description": "A cloaked figure watches you intently.",
			"options": [
				{"text": "Challenge Them", "callback": _event_stranger_challenge},
				{"text": "Ask for Help", "callback": _event_stranger_help},
				{"text": "Ignore", "callback": _event_leave}
			]
		},
		{
			"title": "Abandoned Camp",
			"description": "Scattered belongings suggest a hasty departure.",
			"options": [
				{"text": "Search Thoroughly", "callback": _event_camp_search},
				{"text": "Grab Visible Items", "callback": _event_camp_quick},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Ancient Library",
			"description": "Dust-covered tomes line the shelves, containing forgotten knowledge.",
			"options": [
				{"text": "Study Combat Techniques", "callback": _event_library_combat},
				{"text": "Research Magic", "callback": _event_library_magic},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Wishing Well",
			"description": "A magical well shimmers with possibility. Coins glitter at the bottom.",
			"options": [
				{"text": "Make a Wish (30 coins)", "callback": _event_well_wish},
				{"text": "Steal the Coins", "callback": _event_well_steal},
				{"text": "Walk Away", "callback": _event_leave}
			]
		},
		{
			"title": "Gambling Den",
			"description": "Shady figures huddle around dice and cards in a smoky room.",
			"options": [
				{"text": "Bet 40 Coins", "callback": _event_gamble_bet},
				{"text": "Cheat", "callback": _event_gamble_cheat},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Ritual Circle",
			"description": "Ancient runes glow with dark power around a stone circle.",
			"options": [
				{"text": "Perform Ritual", "callback": _event_ritual_perform},
				{"text": "Break the Symbols", "callback": _event_ritual_break},
				{"text": "Back Away", "callback": _event_leave}
			]
		},
		{
			"title": "Wounded Soldier",
			"description": "A soldier lies injured, clutching their side.",
			"options": [
				{"text": "Tend Their Wounds", "callback": _event_soldier_help},
				{"text": "Rob Them", "callback": _event_soldier_rob},
				{"text": "Ignore", "callback": _event_leave}
			]
		},
		{
			"title": "Enchanted Armor",
			"description": "A magnificent suit of armor radiates magical energy.",
			"options": [
				{"text": "Put It On", "callback": _event_armor_wear},
				{"text": "Study Its Properties", "callback": _event_armor_study},
				{"text": "Leave It", "callback": _event_leave}
			]
		},
		{
			"title": "Fork in the Road",
			"description": "Two paths diverge before you. Left looks dangerous, right seems safe.",
			"options": [
				{"text": "Take Left Path (Risky)", "callback": _event_fork_left},
				{"text": "Take Right Path (Safe)", "callback": _event_fork_right},
				{"text": "Turn Back", "callback": _event_leave}
			]
		},
		{
			"title": "Singing Siren",
			"description": "An enchanting melody fills the air, beckoning you closer.",
			"options": [
				{"text": "Fight the Call", "callback": _event_siren},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Blacksmith's Forge",
			"description": "A master blacksmith works metal, sparks flying.",
			"options": [
				{"text": "Upgrade Weapons (50 coins)", "callback": _event_blacksmith_weapon},
				{"text": "Upgrade Armor (50 coins)", "callback": _event_blacksmith_armor},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Mysterious Portal",
			"description": "A swirling vortex of energy hums before you.",
			"options": [
				{"text": "Step Through", "callback": _event_portal_enter},
				{"text": "Study the Portal", "callback": _event_portal_study},
				{"text": "Leave", "callback": _event_leave}
			]
		},
		{
			"title": "Desperate Beggar",
			"description": "A poor soul extends their hand, asking for charity.",
			"options": [
				{"text": "Give 25 Coins", "callback": _event_beggar_generous},
				{"text": "Give 5 Coins", "callback": _event_beggar_small},
				{"text": "Ignore Them", "callback": _event_beggar_ignore}
			]
		},
		{
			"title": "Mad Alchemist",
			"description": "A wild-eyed alchemist offers you strange bubbling potions.",
			"options": [
				{"text": "Drink Red Potion", "callback": _event_alchemist_red},
				{"text": "Drink Blue Potion", "callback": _event_alchemist_blue},
				{"text": "Decline", "callback": _event_leave}
			]
		},
		{
			"title": "Treasure Map",
			"description": "You find a weathered map marked with an X.",
			"options": [
				{"text": "Follow the Map", "callback": _event_map_follow},
				{"text": "Sell the Map", "callback": _event_map_sell},
				{"text": "Ignore It", "callback": _event_leave}
			]
		},
		{
			"title": "Ghostly Apparition",
			"description": "A spectral figure materializes, seeking something.",
			"options": [
				{"text": "Listen to Their Story", "callback": _event_ghost_listen},
				{"text": "Banish Them", "callback": _event_ghost_banish},
				{"text": "Run Away", "callback": _event_leave}
			]
		},
		{
			"title": "Magic Crystal Cave",
			"description": "Luminescent crystals pulse with arcane power.",
			"options": [
				{"text": "Mine Crystals", "callback": _event_crystal_mine},
				{"text": "Study Crystals", "callback": _event_crystal_study},
				{"text": "Leave", "callback": _event_leave}
			]
		}
	]

func select_random_event():
	"""Pick and display a random event"""
	current_event = events[randi() % events.size()]
	
	title_label.text = current_event["title"]
	description_label.text = current_event["description"]
	
	# Create option buttons
	for option in current_event["options"]:
		create_option_button(option["text"], option["callback"])

func create_option_button(text: String, callback: Callable):
	"""Create an option button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(600, 50)
	button.pressed.connect(callback)
	options_container.add_child(button)

func disable_all_options():
	"""Disable all option buttons"""
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true

func show_result(message: String):
	"""Show result and enable continue"""
	result_label.text = message
	result_panel.visible = true
	continue_button.visible = true
	
	result_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(result_panel, "modulate", Color.WHITE, 0.5)

# ========== EVENT IMPLEMENTATIONS ==========

# 1. Wandering Merchant
func _event_merchant():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	merchant_panel.visible = true
	setup_merchant_relics()

func setup_merchant_relics():
	"""Show 3 random relics at 50% off"""
	for child in merchant_relics_container.get_children():
		child.queue_free()
	
	var available = get_purchasable_relics()
	available.shuffle()
	
	for i in range(min(3, available.size())):
		var relic = available[i]
		create_merchant_relic_card(relic)

func get_purchasable_relics() -> Array:
	"""Get relics player doesn't have"""
	var available = []
	var purchased = GameManager.current_run.get("shop_purchases", {})
	
	for item_id in ShopDatabase.shop_items:
		var item = ShopDatabase.shop_items[item_id]
		if item.category != "relic": continue
		if item.unlock_requirement != "" and not GameManager.is_character_unlocked(item.unlock_requirement): continue
		if purchased.has(item_id): continue
		available.append(item)
	
	return available

func create_merchant_relic_card(relic: ShopDatabase.ShopItem):
	"""Create buyable relic card"""
	var card = PanelContainer.new()
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = relic.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", ShopDatabase.get_rarity_color(relic.rarity))
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = relic.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(350, 0)
	vbox.add_child(desc_label)
	
	var discounted_cost = int(relic.cost * 0.5)
	var buy_button = Button.new()
	buy_button.text = "Buy for %d coins (50%% off!)" % discounted_cost
	buy_button.pressed.connect(func(): purchase_merchant_relic(relic, discounted_cost, buy_button))
	vbox.add_child(buy_button)
	
	if GameManager.get_coins() < discounted_cost:
		buy_button.disabled = true
	
	merchant_relics_container.add_child(card)

func purchase_merchant_relic(relic: ShopDatabase.ShopItem, cost: int, button: Button):
	"""Buy relic from merchant"""
	if not GameManager.spend_coins(cost): return
	
	add_relic(relic)
	button.text = "Purchased!"
	button.disabled = true

func _on_merchant_back():
	"""Close merchant panel"""
	merchant_panel.visible = false
	show_result("You browse the merchant's wares and leave.")

# 2. Fountain of Youth
func _event_fountain_drink():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.modify_health(20)
	add_power_all_characters(20)
	
	show_result("You drink from the fountain!\n\nRestored 20 HP\nAll characters gained 20 power!")

# 3. Training Dummy
func _event_training():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.6:
		add_xp_all_characters(30)
		show_result("Your training pays off!\n\nAll characters gained 30 XP!")
	else:
		GameManager.modify_health(-20)
		show_result("You push too hard and injure yourself.\n\nLost 20 HP")

# 4. Mysterious Stranger
func _event_stranger_challenge():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.5:
		add_xp_all_characters(30)
		show_result("You best the stranger in combat!\n\nAll characters gained 30 XP!")
	else:
		GameManager.modify_health(-25)
		show_result("The stranger defeats you soundly.\n\nLost 25 HP")

func _event_stranger_help():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.4:
		GameManager.modify_health(50)
		show_result("The stranger takes pity on you.\n\nHealed 50 HP!")
	else:
		show_result("The stranger ignores your plea and walks away.")

# 5. Abandoned Camp
func _event_camp_search():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.7:
		GameManager.add_coins(40)
		show_result("You find supplies hidden in the camp!\n\nGained 40 coins!")
	else:
		GameManager.modify_health(-25)
		show_result("Enemies were waiting in ambush!\n\nTook 25 damage!")

func _event_camp_quick():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.add_coins(15)
	show_result("You grab what you can see.\n\nGained 15 coins!")

# 6. Ancient Library
func _event_library_combat():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	add_temp_buff("bonus_damage_double", 1)
	add_temp_buff("power_gain_half", 1)
	show_result("You learn devastating combat techniques!\n\nNext battle: Double damage, but half power gain")

func _event_library_magic():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	add_temp_buff("power_gain_double", 1)
	add_temp_buff("damage_half", 1)
	show_result("You master magical power control!\n\nNext battle: Double power gain, but half damage")

# 7. Wishing Well
func _event_well_wish():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if GameManager.get_coins() < 30:
		show_result("You don't have enough coins!")
		return
	
	GameManager.spend_coins(30)
	
	# Random good effect
	var roll = randi() % 4
	match roll:
		0:
			GameManager.modify_health(40)
			show_result("Your wish is granted!\n\nHealed 40 HP!")
		1:
			GameManager.add_coins(60)
			show_result("Your wish is granted!\n\nGained 60 coins!")
		2:
			add_xp_all_characters(40)
			show_result("Your wish is granted!\n\nAll characters gained 40 XP!")
		3:
			add_power_all_characters(30)
			show_result("Your wish is granted!\n\nAll characters gained 30 power!")

func _event_well_steal():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.5:
		GameManager.add_coins(100)
		show_result("You successfully steal the coins!\n\nGained 100 coins!")
	else:
		GameManager.modify_health(-20)
		show_result("You slip and fall into the well!\n\nTook 20 damage!")

# 8. Gambling Den
func _event_gamble_bet():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if GameManager.get_coins() < 40:
		show_result("You don't have enough coins to bet!")
		return
	
	GameManager.spend_coins(40)
	
	if randf() < 0.5:
		GameManager.add_coins(80)
		show_result("You win the bet!\n\nGained 80 coins (net +40)!")
		AchievementManager.unlock_achievement("gambler")
	else:
		show_result("You lose the bet.\n\nLost 40 coins.")

func _event_gamble_cheat():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.65:
		GameManager.add_coins(100)
		show_result("You successfully cheat and win!\n\nGained 100 coins!")
	else:
		GameManager.modify_health(-30)
		show_result("You're caught cheating and beaten!\n\nTook 30 damage!")

# 9. Ritual Circle
func _event_ritual_perform():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.current_run["maxHealth"] -= 20
	GameManager.save_game()
	add_xp_all_characters(50)
	show_result("Dark power flows through you!\n\nLost 20 max HP\nAll characters gained 50 XP!")

func _event_ritual_break():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.current_run["maxHealth"] += 20
	var current_hp = GameManager.get_current_health()
	GameManager.current_run["currentHealth"] = int(current_hp * 0.5)
	GameManager.save_game()
	show_result("You shatter the ritual!\n\nGained 20 max HP\nBut lost half your current HP!")

# 10. Wounded Soldier
func _event_soldier_help():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.modify_health(-20)
	GameManager.add_coins(50)
	show_result("You tend to their wounds.\n\nLost 20 HP\nGained 50 coins as thanks!")

func _event_soldier_rob():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.add_coins(60)
	
	# Lose XP but not below 0
	var party = GameManager.get_current_party()
	for char_id in party:
		var current_xp = GameManager.get_character_xp(char_id)
		var new_xp = max(0, current_xp - 100)
		GameManager.game_data["characterLevels"][char_id]["currentXP"] = new_xp
	
	GameManager.save_game()
	show_result("You rob the helpless soldier.\n\nGained 60 coins\nLost 100 XP per character (guilt)")

# 11. Enchanted Armor
func _event_armor_wear():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.6:
		GameManager.current_run["maxHealth"] += 20
		GameManager.modify_health(20)
		GameManager.save_game()
		show_result("The armor fits perfectly!\n\nGained 20 max HP!")
	else:
		GameManager.current_run["maxHealth"] -= 20
		var current = GameManager.get_current_health()
		if current > GameManager.current_run["maxHealth"]:
			GameManager.current_run["currentHealth"] = GameManager.current_run["maxHealth"]
		GameManager.save_game()
		show_result("The armor is cursed!\n\nLost 20 max HP!")

func _event_armor_study():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.6:
		add_power_gain_modifier(1.5)
		show_result("You learn to channel power!\n\n+50% power gain for rest of run!")
	else:
		add_power_gain_modifier(0.5)
		show_result("The magic backfires!\n\n-50% power gain for rest of run!")

# 12. Fork in the Road
func _event_fork_left():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.7:
		var available = get_purchasable_relics()
		var rare_relics = []
		for relic in available:
			if relic.rarity == "rare":
				rare_relics.append(relic)
		
		if rare_relics.size() > 0:
			var relic = rare_relics[randi() % rare_relics.size()]
			add_relic(relic)
			show_result("You find a treasure chest!\n\nFound: %s" % relic.name)
		else:
			GameManager.add_coins(50)
			show_result("You find a treasure chest!\n\nGained 50 coins!")
	else:
		GameManager.modify_health(-30)
		show_result("Bandits ambush you!\n\nTook 30 damage!")

func _event_fork_right():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.add_coins(40)
	show_result("You take the safe path.\n\nGained 40 coins!")

# 13. Singing Siren
func _event_siren():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.4:
		add_xp_all_characters(25)
		show_result("You resist the siren's call!\n\nAll characters gained 25 XP!")
	else:
		GameManager.modify_health(-20)
		show_result("You're lulled by the enchanting song.\n\nTook 20 damage!")

# 14. Blacksmith's Forge
func _event_blacksmith_weapon():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if GameManager.get_coins() < 50:
		show_result("You don't have enough coins!")
		return
	
	GameManager.spend_coins(50)
	add_permanent_damage(3)
	show_result("The blacksmith sharpens your weapons!\n\n+3 damage for rest of run!")

func _event_blacksmith_armor():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if GameManager.get_coins() < 50:
		show_result("You don't have enough coins!")
		return
	
	GameManager.spend_coins(50)
	GameManager.current_run["maxHealth"] += 20
	GameManager.modify_health(20)
	GameManager.save_game()
	show_result("The blacksmith reinforces your armor!\n\n+20 max HP!")

# 15. Portal
func _event_portal_enter():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	skip_next_nodes(2)
	show_result("You step through the portal!\n\nSkipped ahead 2 nodes!")

func _event_portal_study():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.75:
		add_power_all_characters(20)
		show_result("You understand the portal's power!\n\nAll characters gained 20 power!")
	else:
		add_power_all_characters(-20)
		show_result("The portal drains your energy!\n\nAll characters lost 20 power!")

# 16. Beggar
func _event_beggar_generous():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if GameManager.get_coins() < 25:
		show_result("You don't have enough coins!")
		return
	
	GameManager.spend_coins(25)
	add_temp_buff("coin_boost_15", 2)
	show_result("The beggar blesses you!\n\n+15% coin drops for 2 battles!")

func _event_beggar_small():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if GameManager.get_coins() < 5:
		show_result("You don't have enough coins!")
		return
	
	GameManager.spend_coins(5)
	show_result("You give a small donation.\n\nThe beggar nods gratefully.")

func _event_beggar_ignore():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	add_temp_buff("coin_penalty_15", 2)
	show_result("You ignore the beggar's plea.\n\n-15% coin drops for 2 battles (karma)")

# 17. Mad Alchemist
func _event_alchemist_red():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.current_run["maxHealth"] += 30
	GameManager.modify_health(-30)
	GameManager.save_game()
	show_result("The potion transforms you!\n\n+30 max HP, but -30 current HP!")

func _event_alchemist_blue():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	var party = GameManager.get_current_party()
	var char_id = party[randi() % party.size()]
	var char_data = CharacterDatabase.get_character(char_id)
	
	if randf() < 0.5:
		var current_level = GameManager.get_character_level(char_id)
		if current_level < 10:
			GameManager.game_data["characterLevels"][char_id]["level"] += 1
			GameManager.save_game()
			show_result("The potion empowers %s!\n\nGained 1 level!" % char_data.character_name)
		else:
			show_result("The potion has no effect on max level %s." % char_data.character_name)
	else:
		var current_level = GameManager.get_character_level(char_id)
		if current_level > 1:
			GameManager.game_data["characterLevels"][char_id]["level"] -= 1
			GameManager.save_game()
			show_result("The potion weakens %s!\n\nLost 1 level!" % char_data.character_name)
		else:
			show_result("The potion has no effect on level 1 %s." % char_data.character_name)

# 18. Treasure Map
func _event_map_follow():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	clear_all_power()
	GameManager.add_coins(80)
	show_result("You follow the map and find treasure!\n\nGained 80 coins\nBut the journey exhausted you (lost all power)")

func _event_map_sell():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.add_coins(35)
	show_result("You sell the map to a collector.\n\nGained 35 coins!")

# 19. Ghostly Apparition
func _event_ghost_listen():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	add_xp_all_characters(25)
	show_result("The ghost shares ancient wisdom.\n\nAll characters gained 25 XP!")

func _event_ghost_banish():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	if randf() < 0.6:
		GameManager.add_coins(50)
		show_result("You successfully banish the ghost!\n\nGained 50 coins!")
	else:
		GameManager.modify_health(-25)
		show_result("The ghost lashes out in anger!\n\nTook 25 damage!")

# 20. Magic Crystal Cave
func _event_crystal_mine():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	GameManager.modify_health(-10)
	GameManager.add_coins(50)
	show_result("You carefully extract crystals.\n\nLost 10 HP\nGained 50 coins!")

func _event_crystal_study():
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	
	# Random effect - 50% good, 50% bad
	var roll = randi() % 6
	match roll:
		0:  # Good - Heal
			GameManager.modify_health(40)
			show_result("The crystals resonate with healing energy!\n\nHealed 40 HP!")
		1:  # Good - Coins
			GameManager.add_coins(60)
			show_result("The crystals reveal hidden treasure!\n\nGained 60 coins!")
		2:  # Good - Power
			add_power_all_characters(40)
			show_result("The crystals overflow with power!\n\nAll characters gained 40 power!")
		3:  # Bad - Damage
			GameManager.modify_health(-30)
			show_result("The crystals explode with unstable energy!\n\nTook 30 damage!")
		4:  # Bad - Lost coins
			var lost = min(30, GameManager.get_coins())
			GameManager.spend_coins(lost)
			show_result("The crystals drain your wealth!\n\nLost %d coins!" % lost)
		5:  # Bad - Lost power
			add_power_all_characters(-30)
			show_result("The crystals sap your strength!\n\nAll characters lost 30 power!")

func _event_leave():
	"""Leave without choosing"""
	if event_chosen: return
	event_chosen = true
	disable_all_options()
	show_result("You decide to move on.")

# ========== HELPER FUNCTIONS ==========

func add_xp_all_characters(amount: int):
	"""Add XP to all party members"""
	var party = GameManager.get_current_party()
	for char_id in party:
		GameManager.add_pending_xp(char_id, amount)

func add_power_all_characters(amount: int):
	"""Add or remove power from all characters"""
	var power = GameManager.current_run.get("character_power", {})
	var party = GameManager.get_current_party()
	
	for char_id in party:
		if not power.has(char_id):
			power[char_id] = 0
		power[char_id] = clamp(power[char_id] + amount, 0, 100)
	
	GameManager.current_run["character_power"] = power
	GameManager.save_game()

func clear_all_power():
	"""Reset all character power to 0"""
	var power = GameManager.current_run.get("character_power", {})
	var party = GameManager.get_current_party()
	
	for char_id in party:
		power[char_id] = 0
	
	GameManager.current_run["character_power"] = power
	GameManager.save_game()

func add_temp_buff(buff_type: String, duration: int):
	"""Add a temporary buff"""
	if not GameManager.current_run.has("temp_buffs"):
		GameManager.current_run["temp_buffs"] = []
	
	var buff_data = {}
	
	match buff_type:
		"bonus_damage_double":
			buff_data = {"type": "damage_multiplier", "multiplier": 2.0, "duration": duration}
		"power_gain_half":
			buff_data = {"type": "power_multiplier", "multiplier": 0.5, "duration": duration}
		"power_gain_double":
			buff_data = {"type": "power_multiplier", "multiplier": 2.0, "duration": duration}
		"damage_half":
			buff_data = {"type": "damage_multiplier", "multiplier": 0.5, "duration": duration}
		"coin_boost_15":
			buff_data = {"type": "coin_multiplier", "multiplier": 1.15, "duration": duration}
		"coin_penalty_15":
			buff_data = {"type": "coin_multiplier", "multiplier": 0.85, "duration": duration}
	
	GameManager.current_run["temp_buffs"].append(buff_data)
	GameManager.save_game()

func add_relic(relic: ShopDatabase.ShopItem):
	"""Add a relic to the run"""
	if not GameManager.current_run.has("relics"):
		GameManager.current_run["relics"] = []
	
	GameManager.current_run["relics"].append({
		"id": relic.id,
		"type": relic.item_type,
		"data": relic.data
	})
	
	if not GameManager.current_run.has("shop_purchases"):
		GameManager.current_run["shop_purchases"] = {}
	GameManager.current_run["shop_purchases"][relic.id] = 1
	
	GameManager.save_game()

func add_power_gain_modifier(multiplier: float):
	"""Add permanent power gain modifier for rest of run"""
	if not GameManager.current_run.has("power_gain_modifier"):
		GameManager.current_run["power_gain_modifier"] = 1.0
	
	GameManager.current_run["power_gain_modifier"] *= multiplier
	GameManager.save_game()

func add_permanent_damage(amount: int):
	"""Add permanent damage bonus for rest of run"""
	if not GameManager.current_run.has("permanent_damage_bonus"):
		GameManager.current_run["permanent_damage_bonus"] = 0
	
	GameManager.current_run["permanent_damage_bonus"] += amount
	GameManager.save_game()

func skip_next_nodes(count: int):
	"""Skip ahead on the map (Portal event)"""
	var map_data = GameManager.current_run.get("map", {})
	if map_data.is_empty():
		return
	
	var current_node_id = map_data["current_node_id"]
	var current_node = null
	
	# Find current node
	for node in map_data["nodes"]:
		if node.id == current_node_id:
			current_node = node
			break
	
	if not current_node:
		return
	
	# Try to skip ahead by following connections
	var next_node_id = current_node_id
	var skipped = 0
	
	for i in range(count):
		# Find next unvisited node
		var candidates = []
		for node in map_data["nodes"]:
			if node.id in get_node_connections(next_node_id, map_data):
				if not node.is_visited and node.node_type != "boss":
					candidates.append(node)
		
		if candidates.size() == 0:
			break
		
		# Pick a random candidate and mark as visited
		var next_node = candidates[randi() % candidates.size()]
		next_node.is_visited = true
		next_node_id = next_node.id
		skipped += 1
	
	# Update map data
	GameManager.current_run["map"] = map_data
	GameManager.save_game()

func get_node_connections(node_id: int, map_data: Dictionary) -> Array:
	"""Get connections for a node"""
	for node in map_data["nodes"]:
		if node.id == node_id:
			return node.get("connections", [])
	return []

func _on_continue_pressed():
	"""Return to map"""
	get_tree().change_scene_to_file("res://scenes/map_view.tscn")
