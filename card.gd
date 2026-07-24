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
@onready var font_cond0_reg:  Font = preload(font_fname + "Regular.otf")
@onready var font_cond1_reg:  Font = preload(font_fname + "Narr.otf")
@onready var font_cond2_reg:  Font = preload(font_fname + "Cond.otf")
@onready var font_cond3_reg:  Font = preload(font_fname + "XCond.otf")
@onready var font_cond0_bold: Font = preload(font_fname + "Bold.otf")
@onready var font_cond1_bold: Font = preload(font_fname + "NarrBold.otf")
@onready var font_cond2_bold: Font = preload(font_fname + "CondBold.otf")
@onready var font_cond3_bold: Font = preload(font_fname + "XCondBold.otf")
@onready var label: Label = $MarginContainer2/HBoxContainer/MarginContainer/Name
@onready var actions: Label = $MarginContainer2/HBoxContainer/Actions
@onready var category: Label = $MarginContainer3/Type
@onready var traits: RichTextLabel = $Content/MarginContainer/VBoxContainer/MarginContainer/Traits
@onready var traits_sep: HSeparator = $Content/MarginContainer/VBoxContainer/TraitsSep
@onready var parameters: RichTextLabel = $Content/MarginContainer/VBoxContainer/Parameters
@onready var parameters_sep: HSeparator = $Content/MarginContainer/VBoxContainer/ParametersSep
@onready var description: RichTextLabel = $Content/MarginContainer/VBoxContainer/Description
@onready var content: MarginContainer = $Content
@onready var heightened: RichTextLabel = $Content/MarginContainer/VBoxContainer/Heightened
@onready var heightened_sep: HSeparator = $Content/MarginContainer/VBoxContainer/HeightenedSep

@onready var fonts_regular: Array[Font] = [font_cond0_reg, font_cond1_reg, font_cond2_reg, font_cond3_reg]
@onready var fonts_bold: Array[Font] = [font_cond0_bold, font_cond1_bold, font_cond2_bold, font_cond3_bold]

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
@export var card_category: String = "Focus":
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
@export_multiline var card_heightened: String = """[b]Heightened (+1):[/b] The damage increases by 1d4 and the weakness on a critical failure increases by 1.""":
	set(value):
		card_heightened = value
		_update_card_visuals()

var bound: float = 0.0
var antibound: float = 710.0
var space_to_slope: float = 10.0
var point_of_slope: float = bound + space_to_slope + 59.0

func sleep(t: float) -> void:
	await get_tree().create_timer(t).timeout 

func apply_rects(left: int, right: int) -> void:
	$LeftPoly.polygon[2].x = left
	$LeftPoly.polygon[3].x = left
	$RightPoly.polygon[2].x = right
	$RightPoly.polygon[3].x = right

func _recalculate_header_constants() -> void:
	if not is_ready:
		return
	#await get_tree().process_frame

	self.bound = label.get_character_bounds(len(label.text)-1).end.x + self.actions.get_character_bounds(len(actions.text)-1).end.x + 38
	
	self.antibound = self.get_rect().size.x - category.get_rect().size.x - 48
	self.point_of_slope = bound + space_to_slope + 59.0
	
	apply_rects(self.bound, self.antibound)
	

func _ready() -> void:
	_update_card_visuals()

func get_type_color() -> Color:
	return TYPE_COLORS[card_type]

func _update_color() -> void:
	$MarginColorRect.color = get_type_color()
	$Polygon2D.color = get_type_color()
	
func _update_header() -> void:
	label.text = card_name
	actions.text = card_cost
	category.text = card_category
	category.add_theme_font_override("font", font_cond1_bold)
	
	_recalculate_header_constants()
	
	if point_of_slope > antibound:
		category.add_theme_font_override("font", font_cond2_bold)
		_recalculate_header_constants()
		
	if point_of_slope > antibound:
		category.add_theme_font_override("font", font_cond3_bold)
		_recalculate_header_constants()
		
	
	_recalculate_header_constants()
	$Polygon2D.polygon[2].x = 10.0 + bound
	$Polygon2D.polygon[3].x = clamp(point_of_slope, 10.0 + bound, antibound)
	if $Polygon2D.polygon[3].x < $Polygon2D.polygon[2].x:
		$Polygon2D.polygon[3].x = $Polygon2D.polygon[2].x
	
	_recalculate_header_constants()

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
		$Content/MarginContainer/VBoxContainer/ParametersSep.show()
	else:
		parameters.hide()
		parameters_sep.hide()

func _update_content() -> void:
	if card_traits:
		card_traits.sort()
		traits.text = "   ".join(card_traits).to_upper()
		traits.show()
		traits_sep.show()
	else:
		traits.hide()
		traits_sep.hide()
		
	_update_parameters()
	
	description.text = card_description
	description.add_theme_font_override("bold_font", fonts_bold[clampi(condension, 0, 3)])
	description.add_theme_font_override("normal_font", fonts_regular[clampi(condension, 0, 3)])
	
	if card_heightened:
		heightened.text = card_heightened
		heightened.show()
		heightened_sep.show()
	else:
		heightened.hide()
		heightened_sep.hide()
		
	
func _update_card_visuals() -> void:
	if not is_ready:
		return
		
	_update_color()
	_recalculate_header_constants()
	_update_header()
	_update_content()
	_recalculate_header_constants()
	
