extends Node
class_name GlobalClasses

enum ActivityCost {
	ONE_ACTION,
	TWO_ACTIONS,
	THREE_ACTIONS,
	REACTION,
	FREE_ACTION,
	ONE_MINUTE,
	TEN_MINUTES,
	ONE_HOUR,
	ONE_OR_MORE_ACTIONS,
	TWO_OR_MORE_ACTIONS
}

enum CardType {
	ATTACK,
	HEALING,
	MOVEMENT,
	BUFF,
	DEBUFF,
	UTILITY,
	SOCIAL
}

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
	ActivityCost.ONE_ACTION: "1",
	ActivityCost.TWO_ACTIONS: "2",
	ActivityCost.THREE_ACTIONS: "3",
	ActivityCost.REACTION: "R",
	ActivityCost.FREE_ACTION: "F",
	ActivityCost.ONE_MINUTE: "M",
	ActivityCost.TEN_MINUTES: "X",
	ActivityCost.ONE_HOUR: "H",
	ActivityCost.ONE_OR_MORE_ACTIONS: "B",
	ActivityCost.TWO_OR_MORE_ACTIONS: "C"
}

var trait_colors: Dictionary = {}
var damage_types: Array[String] = [
	"fire",
	"sonic",
	"electricity",
	"cold",
	"void",
	"vitality",
	"spirit",
	"holy",
	"unholy",
	"bludgeoning",
	"piercing",
	"slashing",
	"physical",
	"bleed",
	"precision",
	"acid",
	"poison",
	"force",
	"mental"
]

# Fonts
const font_fname: String = "res://Fonts/GoodPro/GoodPro-"
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


func load_json_file(file_path: String) -> Variant:
	# Check if the file exists before opening
	if not FileAccess.file_exists(file_path):
		#print("File does not exist: ", file_path)
		return null
	
	# Open the file in read mode
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		#print("Failed to open file: ", FileAccess.get_open_error())
		return null
		
	# Read the entire file content as a text string
	var json_string = file.get_as_text()
	file.close() # Always close the file when done
	
	# Parse the string into a Godot Variant (Dictionary or Array)
	var data = JSON.parse_string(json_string)
	
	if data == null:
		#print("Failed to parse JSON string.")
		return null
		
	return data
	

func sleep(t: float) -> void:
	await get_tree().create_timer(t).timeout 


# Helper function to prevent division-by-zero when calculating scale
func _pack_result(new_a: float, new_b: float, orig_a: float, orig_b: float) -> Dictionary:
	return {
		"size_a": new_a,
		"scale_a": new_a / orig_a if orig_a != 0.0 else 1.0,
		"size_b": new_b,
		"scale_b": new_b / orig_b if orig_b != 0.0 else 1.0
	}
	
	
func calculate_box_sizes_with_margins(
	box_a: float, 
	box_b: float, 
	max_space: float, 
	a_threshold: float, 
	b_min: float,
	margin_left: float,
	margin_between: float,
	margin_right: float
) -> Dictionary:
	
	var total_margins: float = margin_left + margin_between + margin_right
	var total_box_size: float = box_a + box_b
	var total_size: float = total_box_size + total_margins
	
	# Step 1: If boxes AND margins fit perfectly within the original space, return.
	if total_size <= max_space:
		return _pack_result(box_a, box_b, box_a, box_b)
		
	# The excess is how much space we need to subtract from the boxes (margins are fixed)
	var excess: float = total_size - max_space
	
	# Calculate how much Box A is allowed to shrink before hitting its threshold
	var a_threshold_size: float = box_a * a_threshold
	var a_max_initial_squeeze: float = max(0.0, box_a - a_threshold_size)
	
	# Step 2 & 3: Squeeze Box A until it fits, up to its threshold.
	if excess <= a_max_initial_squeeze:
		var new_a: float = box_a - excess
		return _pack_result(new_a, box_b, box_a, box_b)
		
	# Step 4: Squeeze Box B as much as needed until its minimum length.
	var remaining_excess: float = excess - a_max_initial_squeeze
	var b_max_squeeze: float = max(0.0, box_b - b_min)
	
	# Step 5: If squeezing Box B was enough to fit, return.
	if remaining_excess <= b_max_squeeze:
		var new_b: float = box_b - remaining_excess
		return _pack_result(a_threshold_size, new_b, box_a, box_b)
		
	# Step 6: Keep Box B squeezed at its minimum, and squeeze Box A as much as necessary.
	remaining_excess -= b_max_squeeze
	var final_a: float = a_threshold_size - remaining_excess
	
	return _pack_result(final_a, b_min, box_a, box_b)
	
	
func _split_into_words(text: String) -> Array:
	var re_word: RegEx = RegEx.create_from_string("[A-z0-9]+")
	var re_sep: RegEx = RegEx.create_from_string("[^A-z0-9]+")
	
	var words: Array[RegExMatch] = re_word.search_all(text)
	words.append_array(re_sep.search_all(text))
	words.sort_custom(func(a, b): return a.get_start() < b.get_start())
	var parsed: Array = words.map(func(x): return x.get_string())

	return parsed


enum STREAM {
	OUTPUT,
	MEM_BOLD,
	MEM_REG
}
func color_content_pro(text: String, lookup: Dictionary, placeholder: String) -> Dictionary:
	var words: Array = _split_into_words(text)
	var re_number: RegEx = RegEx.create_from_string("[0-9]+d{0,1}[0-9]*")

	var streams: Array[String] = ["", "", ""]
	var pointer: int = STREAM.OUTPUT
	var color: String = "000000"
	const timeout: int = 7
	var timer: int = 0
	var arr: Array = []

	for i in range(len(words)):
		var w: String = words[i]
		var word: String = w.to_lower()
		##print("In:  %s "%w + "(%d) = "%pointer + "...%s"%streams[pointer].substr(max(0, streams[pointer].length() - 30)))
		
		if word[0] == ".":
			if pointer != STREAM.OUTPUT:
				streams[STREAM.OUTPUT] += "[b][color=#%s]"%color + streams[STREAM.MEM_BOLD] + "[/color][/b]" + streams[STREAM.MEM_REG]
				streams[STREAM.MEM_BOLD] = ""
				streams[STREAM.MEM_REG] = ""
				color = "000000"
				pointer = STREAM.OUTPUT

		if re_number.search(w) != null:
			if i+1 < len(words) and words[i+1][0] == "-":
				streams[pointer] += w
				
			else:
				if pointer != STREAM.OUTPUT:
					streams[STREAM.OUTPUT] += "[b][color=#%s]"%color + streams[STREAM.MEM_BOLD] + "[/color][/b]" + streams[STREAM.MEM_REG]
					streams[STREAM.MEM_BOLD] = ""
					streams[STREAM.MEM_REG] = ""
					color = "000000"
					
				streams[STREAM.MEM_BOLD] += w
				pointer = STREAM.MEM_REG
				timer = 0
			

		elif word in damage_types:
			color = lookup[word]

			if pointer == STREAM.MEM_REG:
				streams[STREAM.MEM_BOLD] += streams[STREAM.MEM_REG]
				streams[STREAM.MEM_REG] = ""
				pointer = STREAM.MEM_BOLD

			if pointer == STREAM.OUTPUT:
				streams[pointer] += "[b][color=#%s]"%lookup[word] + placeholder + w.to_upper() + "[/color][/b]"
				arr.append("res://Data/Tags/%s.png"%word)
				
				#arr.append("res://Data/Tags/%s.png"%word)
				color = "000000"
			else:
				streams[pointer] += placeholder + w
				arr.append("res://Data/Tags/%s.png"%word)
				pointer = STREAM.MEM_REG
			
		elif word == "damage" and pointer != STREAM.OUTPUT:
			streams[STREAM.MEM_REG] += w

			streams[STREAM.OUTPUT] += "[b][color=#%s]"%color + streams[STREAM.MEM_BOLD] + streams[STREAM.MEM_REG] + "[/color][/b]"
			streams[STREAM.MEM_BOLD] = ""
			streams[STREAM.MEM_REG] = ""

			pointer = STREAM.OUTPUT
			color = "000000"

		elif word in lookup.keys():
			streams[pointer] += "[b][color=#%s]"%lookup[word] + placeholder + w.to_upper() + "[/color][/b]"
			color = "000000"
			arr.append("res://Data/Tags/%s.png"%word)

		else:
			streams[pointer] += w

		if pointer != STREAM.OUTPUT:
			timer += 1
		else:
			timer = 0

		if timer > timeout:
			streams[STREAM.OUTPUT] += "[b][color=#%s]"%color + streams[STREAM.MEM_BOLD] + "[/color][/b]" + streams[STREAM.MEM_REG]
			streams[STREAM.MEM_BOLD] = ""
			streams[STREAM.MEM_REG] = ""
			color = "000000"
			
			
		##print("Out: %s "%w + "(%d) = "%pointer + "...%s"%streams[pointer].substr(max(0, streams[pointer].length() - 30))+"\n")
			

	if streams[STREAM.MEM_BOLD]:
		streams[STREAM.OUTPUT] += "[b][color=#%s]"%color + streams[STREAM.MEM_BOLD] + "[/color][/b]"
	if streams[STREAM.MEM_REG]:
		streams[STREAM.OUTPUT] += streams[STREAM.MEM_REG]

	return {"text": streams[STREAM.OUTPUT].replace("[b][color=#000000][/color][/b]", ""), "icons": arr}


func _ready() -> void:
	trait_colors = load_json_file("res://Data/trait_colors.json")


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
	regex.compile("\\[[^\\]]*\\]")
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


func find_substring_screen_positions(rtl: RichTextLabel, substring: String) -> Array[Rect2]:
	var results: Array[Rect2] = []
	if substring.is_empty():
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

	return results
