extends Control # Change to Node2D or your specific base node
class_name CardFront

const spacer: String = "|"
const placeholder: String = "[img=32]res://blank_pixel.png[/img]"
const card_size: Vector2 = Vector2(710, 1093)
var j := 0
var is_rendering_icons: bool = false
var is_processing_screenspace: bool = false

enum STATES {
	COMPRESS_DESC_0,
	COMPRESS_HEIGHT_0,
	COMPRESS_DESC_1,
	COMPRESS_HEIGHT_1,
	COMPRESS_DESC_2,
	COMPRESS_HEIGHT_2,
	COMPRESS_DESC_3,
	COMPRESS_HEIGHT_3,
	SQUEEZE_CONTENT
}

@onready var is_ready: bool = true

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

@export var card_materials: String = "":
	set(value):
		card_materials = value
		_update_card_visuals()

@export var card_traits: Array[String] = []:
	set(value):
		card_traits = []
		for s in value:
			card_traits.append(s.to_lower())
		_update_card_visuals()

@export var card_traditions: Array[String] = []:
	set(value):
		card_traditions = value
		_update_card_visuals()

@export var card_range: String = "":
	set(value):
		card_range = value
		_update_card_visuals()

@export var card_frequency: String = "":
	set(value):
		card_frequency = value
		_update_card_visuals()

@export var card_targets: String = "":
	set(value):
		card_targets = value
		_update_card_visuals()

@export var card_area: String = "":
	set(value):
		card_area = value
		_update_card_visuals()

@export var card_defense: String = "":
	set(value):
		card_defense = value
		_update_card_visuals()

@export var card_duration: String = "":
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

@export var card_source: String = "Homebrewed":
	set(value):
		card_source = value
		_update_card_visuals()

func _clean_text(value: String) -> String:
	var regex_clean_newlines := RegEx.create_from_string("\n+")
	var regex_clean_lists := RegEx.create_from_string("\n*(\\[/?(?:ol|ul)(?:[\\s=][^\\]]*)?\\])\n*")
	
	value = value.replace("Legacy Content\n", "")
	value = value.replace("\nSuccess", "\n[b]Success:[/b]")
	value = value.replace("\nCritical Success", "\n[b]Critical Success:[/b]")
	value = value.replace("\nFailure", "\n[b]Failure:[/b]")
	value = value.replace("\nCritical Failure", "\n[b]Critical Failure:[/b]")
	
	value = value.replace("\\n", "\n")
	value = regex_clean_newlines.sub(value, "\n", true)
	value = regex_clean_lists.sub(value, "$1", true)
	value = value.replace("[li]", "").replace("[/li]", "")
	return value
	

@export_multiline var card_description: String = "Lorem ipsum.":
	set(value):
		print("SETTING CARD DESC FOR ", name)
		card_description = _clean_text(value)
		_update_card_visuals()

@export var card_heightened: Dictionary[String, String] = {}:
	set(dict):
		card_heightened = {}
		for key in dict.keys():
			card_heightened.get_or_add(key, _clean_text(dict[key]))
			
		_update_card_visuals()

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
	return Globals.TYPE_COLORS[card_type]


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
	const min_slope_x: float = 10.0
	const min_squeeze: float = 0.7
	const slope_margin: float = 10.0
	
	label.text = card_name
	actions.text = Globals.ACTIVITY_COST[card_cost]
	category.text = card_category
	category.add_theme_font_override("font", Globals.fonts_bold[1])
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
	var data: Dictionary = await Globals.color_text(card_description, placeholder)
	description.text = data["text"]
	var icons = data["icons"]
	
	set_icons($IconManager/Description, icons, description, placeholder)
	
	if card_heightened:
		heightened.show()
		heightened_sep.show()
		$IconManager/Heightened.show()
		var heightened_array: Array[String] = []
		for key in card_heightened.keys():
			heightened_array.append("[b]" + key + ":[/b] " + card_heightened[key])
		var heightened_raw: String = "\n".join(heightened_array)
		data = await Globals.color_text(heightened_raw, placeholder)
		heightened.text = data["text"]
		icons = data["icons"]
		set_icons($IconManager/Heightened, icons, heightened, placeholder)
	else:
		heightened.hide()
		heightened_sep.hide()
		$IconManager/Heightened.hide()

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
	$SourceMargin/Source.text = "Source: " + card_source
	$Content/VBoxContainer.scale.y = 1.0
	description.add_theme_font_override("bold_font", Globals.fonts_bold[0])
	description.add_theme_font_override("normal_font", Globals.fonts_regular[0])
	heightened.add_theme_font_override("bold_font", Globals.fonts_bold[0])
	heightened.add_theme_font_override("normal_font", Globals.fonts_regular[0])
	if card_traits:
		card_traits.sort_custom(_sort_traits)
		#var card_traits_colored: Array[String] = []
		#for t in card_traits:
			#t = t.to_lower()
			#var color_code: String = Globals.trait_colors.get(t, "999999")
			#card_traits_colored.append("[color=#%s]"%color_code + t.to_upper() + "[/color]")
		#traits.text = "   ".join(card_traits_colored)
		var base_text: String = "   ".join(card_traits).to_upper()
		var data: Dictionary = await Globals.color_text(base_text, placeholder)
		traits.text = data["text"]
		traits.show()
		traits_sep.show()
		$IconManager/Traits.show()
		
		await get_tree().process_frame
		
		var icons: Array = data["icons"]
		await set_icons($IconManager/Traits, icons, traits, placeholder)
	else:
		traits.hide()
		traits_sep.hide()
		$IconManager/Traits.hide()
		
	_update_parameters()
	await _update_icons()
		
	# Compress text if necessary.
	await get_tree().process_frame
	
	var bottom_line: float = $Content/VBoxContainer/End.position.y
	var bottom_margin: float = 45.0
	
	#var state: STATES = STATES.COMPRESS_DESC_0
	for state in range(len(STATES.keys())) :
		if bottom_line + 108.0 + bottom_margin <= size.y:
			break
			
		match state:
			STATES.COMPRESS_DESC_0:
				description.add_theme_font_override("bold_font", Globals.fonts_bold[1])
				description.add_theme_font_override("normal_font", Globals.fonts_regular[1])
			STATES.COMPRESS_HEIGHT_0:
				heightened.add_theme_font_override("bold_font", Globals.fonts_bold[1])
				heightened.add_theme_font_override("normal_font", Globals.fonts_regular[1])
			STATES.COMPRESS_DESC_1:
				description.add_theme_font_override("bold_font", Globals.fonts_bold[2])
				description.add_theme_font_override("normal_font", Globals.fonts_regular[2])
			STATES.COMPRESS_HEIGHT_1:
				heightened.add_theme_font_override("bold_font", Globals.fonts_bold[2])
				heightened.add_theme_font_override("normal_font", Globals.fonts_regular[2])
			STATES.COMPRESS_DESC_2:
				description.add_theme_font_override("bold_font", Globals.fonts_bold[3])
				description.add_theme_font_override("normal_font", Globals.fonts_regular[3])
			STATES.COMPRESS_HEIGHT_2:
				heightened.add_theme_font_override("bold_font", Globals.fonts_bold[3])
				heightened.add_theme_font_override("normal_font", Globals.fonts_regular[3])
			_:
				var total_size: float = $Content/VBoxContainer.get_rect().size.y
				var allowed_size: float = size.y - 108.0 - bottom_margin
				$Content/VBoxContainer.scale.y = allowed_size / total_size
				
		await get_tree().process_frame
		await _update_icons()
		state += 1


func set_icons(parent: Node, icons: Array, rich_text_label: RichTextLabel, placeholder_string: String) -> Array[TextureRect]:
	const fallback_icon: String = "res://icon.svg"
	for child in parent.get_children():
		child.queue_free()

	var rects: Array = await find_substring_screen_positions(rich_text_label, placeholder_string)
	var images: Array[TextureRect] = []
	#rich_text_label.text = rich_text_label.text.replace(placeholder_string, "[color=#ffffff]%s[/color]"%[placeholder_string])
	
	print("%s: Found %d spaces, %d icons"%[name, len(rects), len(icons)])
	for i in range(len(rects)):
		var filepath: String = fallback_icon
		if i < len(icons):
			filepath = "res://Data/Tags/%s.png"%icons[i]
		
		var img: Image = Image.new()
		var err: Error = img.load(filepath)
		if err != OK:
			push_warning("Failed to load image at: %s" % filepath)
			err = img.load(fallback_icon)
			
			continue
			
		img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
		var texture: ImageTexture = ImageTexture.create_from_image(img)
		
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.texture = texture
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		parent.add_child(texture_rect)
		images.append(texture_rect)
		texture_rect.global_position = rects[i].position + Vector2(0, -30)
		
	return images


func _update_card_visuals() -> void:
	j += 1
	if not is_ready:
		return
		
	await get_tree().process_frame
	_update_color()
	await get_tree().process_frame
	_update_header()
	await get_tree().process_frame
	_update_content()
	await get_tree().process_frame
	await get_tree().process_frame
	
	
func to_json_string() -> String:
	var data: Dictionary = {
		"card_type": Globals.CardType.keys()[card_type],
		"card_name": card_name,
		"card_cost": Globals.ActivityCost.keys()[card_cost],
		"card_category": card_category,
		"card_materials": card_materials,
		"card_traits": card_traits,
		"card_traditions": card_traditions,
		"card_range": card_range,
		"card_frequency": card_frequency,
		"card_targets": card_targets,
		"card_area": card_area,
		"card_defense": card_defense,
		"card_duration": card_duration,
		"card_requirements": card_requirements,
		"card_trigger": card_trigger,
		"card_source": card_source,
		"card_description": card_description,
		"card_heightened": card_heightened
	}
	
	# The "\t" argument pretty-prints the JSON. 
	# Remove it if you want a minified string.
	return JSON.stringify(data, "\t")

func from_json_string(json_str: String) -> void:
	var data = JSON.parse_string(json_str)
	
	if not data is Dictionary:
		push_error("Failed to parse Card data: Invalid JSON or not a JSON Object.")
		return

	# Direct assignments with safe fallbacks
	var card_type_aux = data.get("card_type", "UTILITY")
	if card_type_aux in Globals.CardType.keys():
		card_type = Globals.CardType[card_type_aux]
	else:
		card_type = Globals.CardType["UTILITY"] as Globals.CardType
	card_name = data.get("card_name", "Activity")
	var card_cost_aux = data.get("card_cost", "ONE_ACTION")
	if card_cost_aux in Globals.ActivityCost.keys():
		card_cost = Globals.ActivityCost[card_cost_aux]
	else:
		card_cost = Globals.ActivityCost["ONE_ACTION"] as Globals.ActivityCost
	card_category = data.get("card_category", "Basic")
	card_materials = data.get("card_materials", "")
	
	# Safely cast Untyped Arrays from JSON to Array[String]
	if data.has("card_traits") and data["card_traits"] is Array:
		var temp_traits: Array[String] = []
		for item in data["card_traits"]:
			temp_traits.append(str(item))
		card_traits = temp_traits
		
	if data.has("card_traditions") and data["card_traditions"] is Array:
		var temp_traditions: Array[String] = []
		for item in data["card_traditions"]:
			temp_traditions.append(str(item))
		card_traditions = temp_traditions

	# Standard Strings
	card_range = data.get("card_range", "")
	card_frequency = data.get("card_frequency", "")
	card_targets = data.get("card_targets", "")
	card_area = data.get("card_area", "")
	card_defense = data.get("card_defense", "")
	card_duration = data.get("card_duration", "")
	card_requirements = data.get("card_requirements", "")
	card_trigger = data.get("card_trigger", "")
	card_source = data.get("card_source", "Homebrewed")
	card_description = data.get("card_description", "")
	
	# Safely cast Untyped Dictionary from JSON to Dictionary[String, String]
	if data.has("card_heightened") and data["card_heightened"] is Dictionary:
		var temp_dict: Dictionary[String, String] = {}
		for key in data["card_heightened"].keys():
			temp_dict[str(key)] = str(data["card_heightened"][key])
		card_heightened = temp_dict

	_update_card_visuals()

func _show():
	$White.hide()
	
func _hide():
	$White.show()
	

func find_substring_screen_positions(rtl: RichTextLabel, substring: String) -> Array[Rect2]:
		
	
	is_processing_screenspace = true
	var results: Array[Rect2] = []
	if substring.is_empty():
		#print(">>> Substring is empty")
		is_processing_screenspace = false
		return results

	var original_bbcode: String = rtl.text
	var tokens: Array = _tokenize_bbcode(original_bbcode)

	# --- Build OUR OWN "virtual parsed text" from literal segments only. ---
	# List bullets/numbers are synthesized by Godot at draw time and never
	# exist in the raw source, so they simply can't appear here — no
	# assumption about Godot's internal indexing is needed at all.
	var virtual_text := ""
	var char_segment_map: Array = []  # parallel to virtual_text: [seg_id, local_idx]
	var rebuilt_bbcode := ""
	var seg_id := 0

	for token in tokens:
		if token["is_tag"]:
			rebuilt_bbcode += token["text"]
		else:
			var text: String = token["text"]
			if text.is_empty():
				continue
			rebuilt_bbcode += "[reclocpos id=%d]%s[/reclocpos]" % [seg_id, text]
			for local_idx in range(text.length()):
				char_segment_map.append([seg_id, local_idx])
			virtual_text += text
			seg_id += 1

	# --- Locate matches against OUR OWN virtual text ---
	var match_starts: Array[int] = []
	var search_start := 0
	while true:
		var found := virtual_text.find(substring, search_start)
		if found == -1:
			break
		match_starts.append(found)
		search_start = found + 1

	if match_starts.is_empty():
		#print(">>> match_starts is empty")
		is_processing_screenspace = false
		return results

	# --- Install/reuse the recorder, draw with tagged segments, restore ---
	var recorder := _get_or_create_recorder(rtl)
	recorder.positions_by_segment.clear()

	rtl.text = rebuilt_bbcode
	rtl.queue_redraw()
	await rtl.get_tree().process_frame
	await rtl.get_tree().process_frame

	rtl.text = original_bbcode

	# --- Build Rect2s per matched occurrence, split by visual line ---
	var canvas_xform: Transform2D = rtl.get_global_transform_with_canvas()
	var font: Font = rtl.get_theme_font("normal_font")
	var font_size: int = rtl.get_theme_font_size("normal_font_size")
	var line_height: float = font.get_height(font_size) if font else 20.0

	for start_index in match_starts:
		var line_groups: Dictionary = {}
		var ordered_ys: Array[float] = []

		for i in range(substring.length()):
			var map_idx := start_index + i
			if map_idx >= char_segment_map.size():
				continue
			var seg: int = char_segment_map[map_idx][0]
			var local_idx: int = char_segment_map[map_idx][1]

			if not recorder.positions_by_segment.has(seg):
				continue
			if not recorder.positions_by_segment[seg].has(local_idx):
				continue

			var pos: Vector2 = recorder.positions_by_segment[seg][local_idx]
			var y_key := snappedf(pos.y, 0.01)

			if not line_groups.has(y_key):
				line_groups[y_key] = []
				ordered_ys.append(y_key)
			line_groups[y_key].append(pos.x)

		ordered_ys.sort()

		for y_key in ordered_ys:
			var xs: Array = line_groups[y_key]
			xs.sort()
			var left: float = xs[0]
			var right: float = xs[xs.size() - 1]

			var last_map_idx: int = start_index + substring.length() - 1
			if last_map_idx + 1 < char_segment_map.size():
				var next_seg: int = char_segment_map[last_map_idx + 1][0]
				var next_local: int = char_segment_map[last_map_idx + 1][1]
				if recorder.positions_by_segment.has(next_seg) and recorder.positions_by_segment[next_seg].has(next_local):
					var next_pos: Vector2 = recorder.positions_by_segment[next_seg][next_local]
					if is_equal_approx(snappedf(next_pos.y, 0.01), y_key):
						right = next_pos.x

			if right <= left and font:
				right = left + font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

			var local_rect := Rect2(Vector2(left, y_key), Vector2(right - left, line_height))
			var top_left: Vector2 = canvas_xform * local_rect.position
			var bottom_right: Vector2 = canvas_xform * (local_rect.position + local_rect.size)
			results.append(Rect2(top_left, bottom_right - top_left))

	#print(">>> Results = ", results)
	is_processing_screenspace = false
	return results


## ------------------------------------------------------------------
## Returns the RichTextLabel's persistent CharPositionRecorder,
## creating and installing it only the first time it's needed.
## Re-installing a new effect on every call was the bug: RichTextLabel
## resolves the [reclocpos] tag to whichever effect first claimed it,
## so later recorder instances were silently never invoked.
## ------------------------------------------------------------------
func _get_or_create_recorder(rtl: RichTextLabel) -> CharPositionRecorder:
	var existing = rtl.get_meta("_char_position_recorder", null)
	if existing != null and is_instance_valid(existing):
		return existing
	var recorder := CharPositionRecorder.new()
	rtl.install_effect(recorder)
	rtl.set_meta("_char_position_recorder", recorder)
	return recorder


## Splits raw BBCode source into alternating tag / literal-text tokens.
## Every `[...]` is treated as an opaque tag boundary; this works for
## [b], [color], [ul]/[ol]/[list], tables, etc. without needing to
## understand what any given tag does.
func _tokenize_bbcode(source: String) -> Array:
	var tokens: Array = []
	var regex := RegEx.new()
	regex.compile("\\[(?!/?[iI][mM][gG](?:[\\]=\\s]))[^\\]]+\\]")
	var cursor := 0

	for result in regex.search_all(source):
		var tag_start: int = result.get_start()
		var tag_end: int = result.get_end()
		if tag_start > cursor:
			tokens.append({"is_tag": false, "text": source.substr(cursor, tag_start - cursor)})
		tokens.append({"is_tag": true, "text": source.substr(tag_start, tag_end - tag_start)})
		cursor = tag_end

	if cursor < source.length():
		tokens.append({"is_tag": false, "text": source.substr(cursor)})

	return tokens
