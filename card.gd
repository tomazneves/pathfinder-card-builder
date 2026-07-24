extends Control # Change to Node2D or your specific base node
class_name Card

const font_fname: String = "res://Fonts/GoodPro/GoodPro-"
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
		card_traits = value
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
		card_description = value
		_update_card_visuals()
@export var card_heightened: Dictionary[String, String] = {
	"Heightened (+1)": """The damage increases by 1d4 and the weakness on a critical failure increases by 1."""
}:
	set(value):
		card_heightened = value
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
	
	# For testing:
	var poly_left: Polygon2D = $LeftPoly
	var poly_right: Polygon2D = $RightPoly
	
	var new_array_left: PackedVector2Array = poly_left.polygon
	var new_array_right: PackedVector2Array = poly_right.polygon
	
	new_array_left[2].x = left_bound
	new_array_left[3].x = left_bound
	new_array_right[2].x = right_bound
	new_array_right[3].x = right_bound
	
	poly_left.set("polygon", new_array_left)
	poly_right.set("polygon", new_array_right)
	

func get_type_color() -> Color:
	return TYPE_COLORS[card_type]

func _update_color() -> void:
	$Margin.color = get_type_color()

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

func _update_content() -> void:
	$Content/VBoxContainer.scale.y = 1.0
	description.add_theme_font_override("bold_font", fonts_bold[0])
	description.add_theme_font_override("normal_font", fonts_regular[0])
	heightened.add_theme_font_override("bold_font", fonts_bold[0])
	heightened.add_theme_font_override("normal_font", fonts_regular[0])
	
	if card_traits:
		card_traits.sort()
		var card_traits_colored: Array[String] = []
		for t in card_traits:
			t = t.to_lower()
			var color_code: String = Globals.trait_colors.get(t, "999999")
			card_traits_colored.append("[color=#%s]"%color_code + t.to_upper() + "[/color]")
		traits.text = "   ".join(card_traits_colored)
		traits.show()
		traits_sep.show()
	else:
		traits.hide()
		traits_sep.hide()
		
	_update_parameters()
	
	var data: Dictionary = Globals.color_content_pro(card_description, Globals.trait_colors)
	description.text = data["text"]
	print(data["icons"])
	#description.add_theme_font_override("bold_font", fonts_bold[clampi(condension, 0, 3)])
	#description.add_theme_font_override("normal_font", fonts_regular[clampi(condension, 0, 3)])
	
	if card_heightened:
		var heightened_array: Array[String] = []
		for key in card_heightened.keys():
			data = Globals.color_content_pro(card_heightened[key], Globals.trait_colors)
			heightened_array.append("[b]" + key + ":[/b] " + data["text"])
		heightened.text = "\n".join(heightened_array)
		heightened.show()
		heightened_sep.show()
	else:
		heightened.hide()
		heightened_sep.hide()
		
	# Compress text if necessary.
	await get_tree().process_frame
	
	var bottom_line: float = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		description.add_theme_font_override("bold_font", fonts_bold[1])
		description.add_theme_font_override("normal_font", fonts_regular[1])
		await get_tree().process_frame
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		heightened.add_theme_font_override("bold_font", fonts_bold[1])
		heightened.add_theme_font_override("normal_font", fonts_regular[1])
		await get_tree().process_frame
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		description.add_theme_font_override("bold_font", fonts_bold[2])
		description.add_theme_font_override("normal_font", fonts_regular[2])
		await get_tree().process_frame
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		heightened.add_theme_font_override("bold_font", fonts_bold[2])
		heightened.add_theme_font_override("normal_font", fonts_regular[2])
		await get_tree().process_frame
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		description.add_theme_font_override("bold_font", fonts_bold[3])
		description.add_theme_font_override("normal_font", fonts_regular[3])
		await get_tree().process_frame
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		heightened.add_theme_font_override("bold_font", fonts_bold[3])
		heightened.add_theme_font_override("normal_font", fonts_regular[3])
		await get_tree().process_frame
		bottom_line = $Content/VBoxContainer/End.position.y
	if bottom_line + 108.0 + 30.0 > size.y:
		var total_size: float = $Content/VBoxContainer.get_rect().size.y
		var allowed_size: float = size.y - 108.0 - 30.0
		$Content/VBoxContainer.scale.y = allowed_size / total_size
			
		

		
		
	
func _update_card_visuals() -> void:
	if not is_ready:
		return
		
	_update_color()
	_update_header()
	_update_content()
	#Globals.overlay_images($Content/VBoxContainer/Description, ["res://Data/Icons/acid.png", "res://Data/Icons/bleed.png"])
	
