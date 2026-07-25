extends Node

var trait_colors: Dictionary = {}
var damage_types: Array[String] = [
	"fire", "sonic", "electricity", "cold", "void", "vitality", "spirit", "holy", "unholy", "bludgeoning", "piercing", "slashing", "physical", "bleed", "precision", "acid", "poison", "force", "mental"
]

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
	rtl.set_meta("_char_position_recorder", recorder)  # stash it on the node itself
	return recorder

## ------------------------------------------------------------------
## 2) Finds every occurrence of `substring` and returns its screen-space
##    Rect2 bounds. Handles BBCode ([b], [color], ...) and justification
##    (Kashida, Word Bound, Skip Last Line) because it reads positions
##    straight off the actual shaped/justified layout instead of
##    computing them itself.
##
## Must be awaited — it needs one draw pass to populate character
## positions:
##     var rects = await find_substring_screen_positions(rtl, "foo")
## ------------------------------------------------------------------
func find_substring_screen_positions(rtl: RichTextLabel, substring: String) -> Array[Rect2]:
	var results: Array[Rect2] = []
	if substring.is_empty():
		#print("Case 1: ", results)
		return results

	# --- Step 1: locate matches in the RENDERED (tag-stripped) text ---
	#print("> Step 1")
	var full_text: String = rtl.get_parsed_text()
	var match_starts: Array[int] = []
	var search_start := 0
	while true:
		var found := full_text.find(substring, search_start)
		if found == -1:
			break
		match_starts.append(found)
		search_start = found + 1  # overlap-permissive; use + substring.length() to disallow

	if match_starts.is_empty():
		#print("Case 2: ", results)
		return results

	# --- Reuse the same recorder every time, and wipe stale data ---
	var recorder := _get_or_create_recorder(rtl)
	recorder.char_positions.clear()  # discard positions from any earlier run

	var original_bbcode: String = rtl.text
	rtl.text = "[reclocpos]" + original_bbcode + "[/reclocpos]"

	rtl.queue_redraw()
	await rtl.get_tree().process_frame
	await rtl.get_tree().process_frame

	rtl.text = original_bbcode
	var canvas_xform: Transform2D = rtl.get_global_transform_with_canvas()
	var font: Font = rtl.get_theme_font("normal_font")
	var font_size: int = rtl.get_theme_font_size("normal_font_size")
	var line_height: float = font.get_height(font_size) if font else 20.0

	for start_index in match_starts:
		#print("start_index = ", start_index)
		var line_groups: Dictionary = {}   # rounded_y -> Array of x positions
		var ordered_ys: Array[float] = []

		for i in range(substring.length()):
			#print("i = ", i)
			var idx := start_index + i
			if not recorder.char_positions.has(idx):
				#print("recorder", recorder.char_positions)
				continue
			var pos: Vector2 = recorder.char_positions[idx]
			var y_key := snappedf(pos.y, 0.01)  # group characters on the same line

			if not line_groups.has(y_key):
				line_groups[y_key] = []
				ordered_ys.append(y_key)
			line_groups[y_key].append(pos.x)

		ordered_ys.sort()

		for y_key in ordered_ys:
			#print("y_key = ", y_key)
			var xs: Array = line_groups[y_key]
			xs.sort()
			var left: float = xs[0]
			var right: float = xs[xs.size() - 1]

			# Use the position of the very next character (if on the same
			# line) as the right edge — gives an exact width with no font
			# metrics guesswork.
			var last_char_index: int = start_index + substring.length() - 1
			if recorder.char_positions.has(last_char_index + 1):
				var next_pos: Vector2 = recorder.char_positions[last_char_index + 1]
				if is_equal_approx(snappedf(next_pos.y, 0.01), y_key):
					right = next_pos.x
			if right <= left and font:
				right = left + font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

			var local_rect := Rect2(Vector2(left, y_key), Vector2(right - left, line_height))
			var top_left: Vector2 = canvas_xform * local_rect.position
			var bottom_right: Vector2 = canvas_xform * (local_rect.position + local_rect.size)
			results.append(Rect2(top_left, bottom_right - top_left))

	#print("Case 3: ", results)
	return results
