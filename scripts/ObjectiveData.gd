extends Resource
class_name ObjectiveData

# Identification
@export var id: String = ""  # "save_princess", "retrieve_item", etc.
@export var objective_type: String = ""  # "rescue", "retrieve", "slay", "escort", "defend"
@export var title_template: String = ""  # "Save the {target} from {boss}!"

# What this objective needs
@export var requires_target: bool = false  # Does it need a princess/merchant/etc?
@export var requires_item: bool = false  # Does it need an item name?
@export var requires_location: bool = false  # Does it need a location?

# Possible targets (if requires_target)
@export var target_options: Array = []

# Possible locations (if requires_location)
@export var location_options: Array = []

# Flavor text for completion
@export var completion_text: String = ""

func generate_title(boss_name: String, item_name: String = "", target_name: String = "", location_name: String = "") -> String:
	"""Generate the full objective title"""
	var title = title_template
	title = title.replace("{boss}", boss_name)
	title = title.replace("{item}", item_name)
	title = title.replace("{target}", target_name)
	title = title.replace("{location}", location_name)
	return title
