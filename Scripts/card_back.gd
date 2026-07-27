extends Control
class_name CardBack

var is_ready: bool = false
func _ready():
	is_ready = true
	_update_card_visuals()

@export var card_type: GlobalClasses.CardType = Globals.CardType.UTILITY:
	set(value):
		card_type = value
		_update_card_visuals()
@export var card_name: String = "Activity":
	set(value):
		card_name = value
		_update_card_visuals()
@export var card_cost: GlobalClasses.ActivityCost = Globals.ActivityCost.ONE_ACTION:
	set(value):
		card_cost = value
		_update_card_visuals()
@export var card_category: String = "Basic":
	set(value):
		card_category = value
		_update_card_visuals()
@export var card_traits: Array[String] = []:
	set(value):
		card_traits = []
		for s in value:
			card_traits.append(s.to_lower())
		card_traits.sort_custom(_sort_traits)
		_update_card_visuals()
		
	

func _sort_traits(a, b) -> bool:
	# true if a < b
	if b == "rare":
		return false
		
	elif a == "rare":
		return true
		
	elif a == "uncommon":
		return true
		
	elif b == "uncommon":
		return false
		
	else:
		return a < b
	
func _update_card_visuals() -> void:
	if not is_ready:
		return
		
	$Background.color = Globals.TYPE_COLORS[card_type]
	$Content/VBoxContainer/Actions.text = Globals.ACTIVITY_COST[card_cost]
	$Content/VBoxContainer/Name.text = card_name
	$Content/VBoxContainer/Category.text = card_category
	
	var labels: Array[Label] = [
		$Content/VBoxContainer/Actions,
		$Content/VBoxContainer/Name,
		$Content/VBoxContainer/Category
	]
	var rarity_color: Color = Color.WHITE
	
	if "uncommon" in card_traits:
		var uncommon_color_string: String = "#" + Globals.trait_colors["uncommon"]
		rarity_color = Color(uncommon_color_string)
	elif "rare" in card_traits:
		var rare_color_string: String = "#" + Globals.trait_colors["rare"]
		rarity_color = Color(rare_color_string)
		
	if rarity_color != Color.WHITE:
		for label in labels:
			label.add_theme_constant_override("outline_size", 35)
			label.add_theme_color_override("font_outline_color", rarity_color)
	else:
		for label in labels:
			label.add_theme_constant_override("outline_size", 0)


	_load_trait_pictures()

func _assign_rows(traits: Array) -> Dictionary:
	if len(traits) > 10:
		print("WARNING: SOME TRAITS WERE CUT OFF.")
	traits.sort_custom(_sort_traits)
	
	var d: Dictionary = {}
	var threshold: int = 5
	if len(traits) < 5:
		threshold = 5
	elif len(traits) < 6:
		threshold = 3
	elif len(traits) < 9:
		threshold = 4
	else:
		threshold = 5
	
	for i in range(min(len(traits), 10)):
		if i < threshold:
			d[traits[i]] = 0
		else:
			d[traits[i]] = 1
			
	return d

func _load_trait_pictures(directory: String = "res://Data/Icons/", filter_no_icon: bool = true) -> void:
	if not is_ready:
		return
		
	var row_1: HBoxContainer = $Traits/VBoxContainer/Row1
	var row_2: HBoxContainer = $Traits/VBoxContainer/Row2
	var rows: Array[HBoxContainer] = [row_1, row_2]
	
	for row in rows:
		for child in row.get_children():
			child.queue_free()
			
		
	# Filters out traits with no icon
	var filtered_card_traits: Array = []
	for trait_name in card_traits:
		if not filter_no_icon or trait_name in Globals.trait_colors.keys():
			filtered_card_traits.append(trait_name)
			
	var guide: Dictionary = _assign_rows(filtered_card_traits)
	for trait_name in guide.keys():
		var filepath: String = directory + trait_name + ".png"
		#var img: Image = Image.new()
		#var err: Error = img.load(filepath)
		#if err != OK:
			#push_warning("Failed to load image at: %s" % filepath)
			#continue
			
		#var texture: ImageTexture = ImageTexture.create_from_image(img)
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.texture = load(filepath)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		rows[guide[trait_name]].add_child(texture_rect)


func from_json_string(json_str: String) -> void:
	var data = JSON.parse_string(json_str)
	
	if not data is Dictionary:
		push_error("Failed to parse Card data: Invalid JSON or not a JSON Object.")
		return

	# Direct assignments with safe fallbacks
	card_name = data.get("card_name", "Activity")
	card_category = data.get("card_category", "Basic")
	var card_type_aux = data.get("card_type", "UTILITY")
	if card_type_aux in Globals.CardType.keys():
		card_type = Globals.CardType[card_type_aux]
	else:
		card_type = Globals.CardType["UTILITY"]
	card_name = data.get("card_name", "Activity")
	var card_cost_aux = data.get("card_cost", "ONE_ACTION")
	if card_cost_aux in Globals.ActivityCost.keys():
		card_cost = Globals.ActivityCost[card_cost_aux]
	else:
		card_cost = Globals.ActivityCost["ONE_ACTION"]
	
	# Safely cast Untyped Arrays from JSON to Array[String]
	if data.has("card_traits") and data["card_traits"] is Array:
		var temp_traits: Array[String] = []
		for item in data["card_traits"]:
			temp_traits.append(str(item))
		card_traits = temp_traits
		

	_update_card_visuals()


func _show():
	$White.hide()
	
func _hide():
	$White.show()
