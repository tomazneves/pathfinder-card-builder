extends Control # Change to Node2D or your specific base node
class_name Card

const font_fname: String = "res://Fonts/GoodPro/GoodPro-"
const spacer: String = "|"
const TYPE_COLORS: Dictionary = {
	CardType.ATTACK: Color("a12c22"),
	CardType.HEALING: Color("52a25e"),
	CardType.MOVEMENT: Color("ddb726"),
	CardType.BUFF: Color("35bfd1"),
	CardType.DEBUFF: Color("662d91"),
	CardType.UTILITY: Color("625147"),
	CardType.SOCIAL: Color("f065a5")
}
const ACTIVITY_COST: Dictionary = {
	ActivityCost.A: "1",
	ActivityCost.AA: "2",
	ActivityCost.AAA: "3",
	ActivityCost.F: "F",
	ActivityCost.R: "R"
}
const placeholder: String = "JJII"
enum ActivityCost {A,AA,AAA,F,R,}
enum CardType {
	ATTACK,
	HEALING,
	MOVEMENT,
	BUFF,
	DEBUFF,
	UTILITY,
	SOCIAL
}

@onready var is_ready: bool = true

# Fonts
@onready var font_cond0_reg:  Font = preload(font_fname + "Regular.otf")
@onready var font_cond1_reg:  Font = preload(font_fname + "Narr.otf")
@onready var font_cond2_reg:  Font = preload(font_fname + "Cond.otf")
@onready var font_cond3_reg:  Font = preload(font_fname + "XCond.otf")
@onready var font_cond0_bold: Font = preload(font_fname + "Bold.otf")
@onready var font_cond1_bold: Font = preload(font_fname + "NarrBold.otf")
@onready var font_cond2_bold: Font = preload(font_fname + "CondBold.otf")
@onready var font_cond3_bold: Font = preload(font_fname + "XCondBold.otf")

@onready var fonts_regular: Array[Font] = [
	font_cond0_reg,  font_cond1_reg,  font_cond2_reg,  font_cond3_reg]
@onready var fonts_bold: 	Array[Font] = [
	font_cond0_bold, font_cond1_bold, font_cond2_bold, font_cond3_bold]

# Nodes
@onready var label: 			Label = 			$Header/MarginContainerName/Name
@onready var actions: 			Label = 			$Header/MarginContainerActions/Actions
@onready var category: 			Label = 			$MarginContainerCategory/Category
@onready var traits: 			RichTextLabel = 	$Content/VBoxContainer/MarginContainer/Traits
@onready var traits_sep: 		HSeparator = 		$Content/VBoxContainer/TraitsSep
@onready var parameters: 		RichTextLabel = 	$Content/VBoxContainer/Parameters
@onready var parameters_sep: 	HSeparator = 		$Content/VBoxContainer/ParametersSep
@onready var description: 		RichTextLabel = 	$Content/VBoxContainer/Description
@onready var content: 			MarginContainer = 	$Content
@onready var heightened: 		RichTextLabel = 	$Content/VBoxContainer/Heightened
@onready var heightened_sep: 	HSeparator = 		$Content/VBoxContainer/HeightenedSep

# Exports
@export var card_size: Vector2 = Vector2(710, 1093)
@export var card_type: CardType = CardType.ATTACK:
	set(value):
		card_type = value
		_update_card_visuals() # Updates the color automatically when changed
@export var card_name: String = "Activity":
	set(value):
		card_name = value
		_update_card_visuals()
		_recalculate_header_constants()
@export var card_cost: String = "1":
	set(value):
		card_cost = value
		_update_card_visuals()
@export var card_category: String = "Basic":
	set(value):
		card_category = value
		_update_card_visuals()
		_recalculate_header_constants()
@export var card_materials: String = "":
	set(value):
		card_materials = value
		_update_card_visuals()
@export var card_traits: Array[String] = ["Attack", "Concentrate", "Manipulate"]:
	set(value):
		card_traits = []
		for s in value:
			card_traits.append(s.to_lower())
		_update_card_visuals()
@export var card_traditions: Array[String] = ["Arcane", "Primal"]:
	set(value):
		card_traditions = value
		_update_card_visuals()
@export var card_range: String = "60 feet":
	set(value):
		card_range = value
		_update_card_visuals()
@export var card_frequency: String = "":
	set(value):
		card_frequency = value
		_update_card_visuals()
@export var card_targets: String = "1 creature":
	set(value):
		card_targets = value
		_update_card_visuals()
@export var card_area: String = "":
	set(value):
		card_area = value
		_update_card_visuals()
@export var card_defense: String = "Basic Fortitude":
	set(value):
		card_defense = value
		_update_card_visuals()
@export var card_duration: String = "Sustained":
	set(value):
		card_duration = value
		_update_card_visuals()
@export var card_requirements: String = "":
	set(value):
		card_requirements = value
		_update_card_visuals()
@export var card_trigger: String = "":
	set(value):
		card_trigger = value
		_update_card_visuals()
@export var condension: int = 0:
	set(value):
		condension = value
		_update_card_visuals()
@export_multiline var card_description: String = """Lorem ipsum.\nDolor sit amet.""":
	set(value):
		var regex := RegEx.create_from_string("\n+")
		var regex_clean_lists := RegEx.create_from_string("\n*(\\[\\/{0,1}[ou]l\\])\n*")
		card_description = regex.sub(value, "\n", true)
		card_description = regex_clean_lists.sub(card_description, "$1", true)
		_update_card_visuals()
@export var card_heightened: Dictionary[String, String] = {
	"Heightened (+1)": """The damage increases by:\n[ol]\nFire: 1d4\nCold: 1d6[/ol]\n and the weakness on a critical failure increases by 1."""
}:
	set(value):
		var regex := RegEx.create_from_string("\n+")
		var regex_clean_lists := RegEx.create_from_string("\n*(\\[\\/{0,1}[ou]l\\])\n*")
		card_heightened = {}
		for key in value.keys():
			var txt := regex.sub(value[key], "\n", true)
			txt = regex_clean_lists.sub(txt, "$1", true)
			card_heightened.get_or_add(key, txt)
		_update_card_visuals()
@export_multiline var test: Dictionary[String, String] = {"Heightened (+1)": "YEAG"}

# Metadata
var left_bound: float = 0.0
var right_bound: float = 710.0
var space_to_slope: float = 10.0
var point_of_slope: float = left_bound + space_to_slope + 59.0

# Functions
func _ready() -> void:
	_update_card_visuals()

func _recalculate_header_constants() -> void:
	if not is_ready:
		return
		
	await get_tree().process_frame
	self.left_bound = label.get_rect().size.x + actions.get_rect().size.x + 38
	self.right_bound = self.get_rect().size.x - category.get_rect().size.x - 48
	return
	

func get_type_color() -> Color:
	return TYPE_COLORS[card_type]

func _update_color() -> void:
	$Margin.color = get_type_color()
	var common: bool = true
	for rarity in ["uncommon", "rare"]:
		if rarity in card_traits:
			common = false
			var new_stylebox = StyleBoxLine.new()
			new_stylebox.color = Color("#" + Globals.trait_colors[rarity])
			new_stylebox.thickness = 2
			$Content/VBoxContainer/TraitsSep.add_theme_stylebox_override("separator", new_stylebox)
			$Content/VBoxContainer/HeightenedSep.add_theme_stylebox_override("separator", new_stylebox)
			$Content/VBoxContainer/ParametersSep.add_theme_stylebox_override("separator", new_stylebox)
			$Rarity.color = Color("#" + Globals.trait_colors[rarity])
			$Rarity.show()
	if common:
		$Rarity.hide()
		var new_stylebox = StyleBoxLine.new()
		new_stylebox.color = Color.BLACK
		new_stylebox.thickness = 2
		$Content/VBoxContainer/TraitsSep.add_theme_stylebox_override("separator", new_stylebox)
		$Content/VBoxContainer/HeightenedSep.add_theme_stylebox_override("separator", new_stylebox)
		$Content/VBoxContainer/ParametersSep.add_theme_stylebox_override("separator", new_stylebox)
		

func _update_header() -> void:
	const inset_height: float = 50.0
	const min_slope_x: float = 10.0
	const max_slope_x: float = inset_height
	const min_squeeze: float = 0.7
	const slope_margin: float = 10.0
	var slope_start: float = left_bound + slope_margin
	
	label.text = card_name
	actions.text = card_cost
	category.text = card_category
	category.add_theme_font_override("font", font_cond1_bold)
	label.scale.x = 1.0
	await _recalculate_header_constants()
	
	# If content doesn't fit, try to condense the Category text
	#if left_bound + slope_margin + max_slope_x > right_bound:
		#category.add_theme_font_override("font", font_cond2_bold)
		#await _recalculate_header_constants()
		
	# If still doesnt fit, squeeze Name text and slope
	var left_margin: float = actions.get_rect().size.x + 38
	var right_margin: float = category.get_rect().size.x + 58
	var sizing: Dictionary = Globals.calculate_box_sizes_with_margins(
		label.get_rect().size.x,
		50.0,
		card_size.x,
		min_squeeze,
		min_slope_x,
		left_margin,
		slope_margin,
		right_margin
	)
	
	var bg_poly: PackedVector2Array = $Background.polygon
	bg_poly[4].x = left_margin + sizing["size_a"] + slope_margin + sizing["size_b"]
	bg_poly[5].x = left_margin + sizing["size_a"] + slope_margin
	$Background.set("polygon", bg_poly)
	
	var rarity_poly: PackedVector2Array = bg_poly
	var px: float = 6.0
	rarity_poly[0] += Vector2(-px, -px)
	rarity_poly[1] += Vector2(-px, +px)
	rarity_poly[2] += Vector2(+px, +px)
	rarity_poly[3] += Vector2(+px, -px)
	rarity_poly[4] += Vector2(-px / 2, -px)
	rarity_poly[5] += Vector2(-px / 2, -px)
	$Rarity.set("polygon", rarity_poly)
	label.scale.x = sizing["scale_a"]

func _update_parameters() -> void:
	var param_string = ""
	var param_array = []
	if card_traditions:
		card_traditions.sort()
		param_array.append("[b]Traditions:[/b] " + ", ".join(card_traditions) + ".")
	if card_trigger:
		param_array.append("[b]Trigger:[/b] " + card_trigger + ".")
	if card_requirements:
		param_array.append("[b]Requirements:[/b] " + card_requirements + ".")
	if card_materials:
		param_array.append("[b]Materials:[/b] " + card_materials + ".")
	if card_frequency:
		param_array.append("[b]Frequency:[/b] " + card_frequency + ".")
		
	var range_targets_area: Array = []
	if card_range:
		range_targets_area.append("[b]Range:[/b] " + card_range)
	if card_targets:
		range_targets_area.append("[b]Targets:[/b] " + card_targets)
	if card_area:
		range_targets_area.append("[b]Area:[/b] " + card_area)
	if len(range_targets_area) > 0:
		param_array.append("; ".join(range_targets_area) + ".")
	
	if card_defense:
		param_array.append("[b]Defense:[/b] " + card_defense + ".")
	if card_duration:
		param_array.append("[b]Duration:[/b] " + card_duration + ".")
	
	if len(param_array) > 0:
		param_string = "\n".join(param_array)
		parameters.text = param_string
		parameters.show()
		parameters_sep.show()
	else:
		parameters.hide()
		parameters_sep.hide()

func _update_icons() -> void:
	var data: Dictionary = await Globals.color_content_pro(card_description, Globals.trait_colors, placeholder)
	description.text = data["text"]
	var icons = data["icons"]
	
	set_icons($IconManager/Description, icons, description, placeholder)
	
	if card_heightened:
		var heightened_array: Array[String] = []
		for key in card_heightened.keys():
			heightened_array.append("[b]" + key + ":[/b] " + card_heightened[key])
		var heightened_raw: String = "\n".join(heightened_array)
		data = await Globals.color_content_pro(heightened_raw, Globals.trait_colors, placeholder)
		print(data)
		heightened.text = data["text"]
		icons = data["icons"]
		set_icons($IconManager/Heightened, icons, heightened, placeholder)
		
		heightened.show()
		heightened_sep.show()
	else:
		heightened.hide()
		heightened_sep.hide()

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
		
	
func _update_content() -> void:
	$Content/VBoxContainer.scale.y = 1.0
	description.add_theme_font_override("bold_font", fonts_bold[0])
	description.add_theme_font_override("normal_font", fonts_regular[0])
	heightened.add_theme_font_override("bold_font", fonts_bold[0])
	heightened.add_theme_font_override("normal_font", fonts_regular[0])
	
	if card_traits:
		card_traits.sort_custom(_sort_traits)
		#var card_traits_colored: Array[String] = []
		#for t in card_traits:
			#t = t.to_lower()
			#var color_code: String = Globals.trait_colors.get(t, "999999")
			#card_traits_colored.append("[color=#%s]"%color_code + t.to_upper() + "[/color]")
		#traits.text = "   ".join(card_traits_colored)
		var base_text: String = "   ".join(card_traits).to_upper()
		var data: Dictionary = await Globals.color_content_pro(base_text, Globals.trait_colors, placeholder + "I")
		print("TRAITS: ", data)
		traits.text = data["text"]
		traits.show()
		traits_sep.show()
		
		await get_tree().process_frame
		
		var icons: Array = data["icons"]
		await set_icons($IconManager/Traits, icons, traits, placeholder + "I", true)
	else:
		traits.hide()
		traits_sep.hide()
		
	_update_parameters()
	await _update_icons()
		
	# Compress text if necessary.
	await get_tree().process_frame
	
	var bottom_line: float = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		description.add_theme_font_override("bold_font", fonts_bold[1])
		description.add_theme_font_override("normal_font", fonts_regular[1])
		await get_tree().process_frame
		await _update_icons()
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		heightened.add_theme_font_override("bold_font", fonts_bold[1])
		heightened.add_theme_font_override("normal_font", fonts_regular[1])
		await get_tree().process_frame
		await _update_icons()
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		description.add_theme_font_override("bold_font", fonts_bold[2])
		description.add_theme_font_override("normal_font", fonts_regular[2])
		await get_tree().process_frame
		await _update_icons()
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		heightened.add_theme_font_override("bold_font", fonts_bold[2])
		heightened.add_theme_font_override("normal_font", fonts_regular[2])
		await get_tree().process_frame
		await _update_icons()
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		description.add_theme_font_override("bold_font", fonts_bold[3])
		description.add_theme_font_override("normal_font", fonts_regular[3])
		await get_tree().process_frame
		await _update_icons()
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		heightened.add_theme_font_override("bold_font", fonts_bold[3])
		heightened.add_theme_font_override("normal_font", fonts_regular[3])
		await get_tree().process_frame
		await _update_icons()
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		var total_size: float = $Content/VBoxContainer.get_rect().size.y
		var allowed_size: float = size.y - 108.0 - 30.0
		$Content/VBoxContainer.scale.y = allowed_size / total_size
		await _update_icons()
			
		
		
@onready var paragraph: TextParagraph = TextParagraph.new()

func set_icons(parent: Node, icons: Array, label: RichTextLabel, placeholder: String, reset: bool = true, separator: String = "") -> Array[TextureRect]:
	print("Setting icons!")
	if reset:
		for child in parent.get_children():
			child.queue_free()
		
	var rects: Array = await Globals.find_substring_screen_positions(label, placeholder)
	var images: Array[TextureRect] = []
	label.text = label.text.replace(placeholder, "[color=#ffffff]%s%s[/color]"%[placeholder, separator])
	
	for i in range(len(rects)):
		var filepath: String = "res://icon.svg"
		if i < len(icons):
			filepath = icons[i]
		# 6. Instantiate and position the image
		var img: Image = Image.new()
		var err: Error = img.load(filepath)
		if err != OK:
			push_warning("Failed to load image at: %s" % filepath)
			continue
			
		img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
		var texture: ImageTexture = ImageTexture.create_from_image(img)
		
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.texture = texture
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("%s (%s): %s = "%[card_name, name, icons[i]], rects[i].position)
		
		parent.add_child(texture_rect)
		images.append(texture_rect)
		texture_rect.global_position = rects[i].position + Vector2(0, -30)
		
	return images

func _update_card_visuals() -> void:
	if not is_ready:
		return
		
	_update_color()
	_update_header()
	_update_content()
	
