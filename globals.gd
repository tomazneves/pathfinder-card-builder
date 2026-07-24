extends Node

var trait_colors: Dictionary = {}
var damage_types: Array[String] = [
	"fire", "sonic", "electricity", "cold", "void", "vitality", "spirit", "holy", "unholy", "bludgeoning", "piercing", "slashing", "physical", "bleed", "precision", "acid", "poison", "force", "mental"
]

func load_json_file(file_path: String) -> Variant:
	# Check if the file exists before opening
	if not FileAccess.file_exists(file_path):
		print("File does not exist: ", file_path)
		return null
	
	# Open the file in read mode
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file: ", FileAccess.get_open_error())
		return null
		
	# Read the entire file content as a text string
	var json_string = file.get_as_text()
	file.close() # Always close the file when done
	
	# Parse the string into a Godot Variant (Dictionary or Array)
	var data = JSON.parse_string(json_string)
	
	if data == null:
		print("Failed to parse JSON string.")
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
func color_content_pro(text: String, lookup: Dictionary) -> Dictionary:
	var words: Array = _split_into_words(text)
	var re_number: RegEx = RegEx.create_from_string("[0-9]+d{0,1}[0-9]*")

	var streams: Array[String] = ["", "", ""]
	var pointer: int = STREAM.OUTPUT
	var color: String = "000000"
	const timeout: int = 7
	var timer: int = 0
	var arr: Array = []

	for w in words:
		var word: String = w.to_lower()
		#print("In:  %s "%w + "(%d) = "%pointer + "...%s"%streams[pointer].substr(max(0, streams[pointer].length() - 30)))

		if re_number.search(w) != null:
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
				streams[pointer] += "[b][color=#%s]"%lookup[word] + w.to_upper() + "[/color][/b]"
				color = "000000"
			else:
				streams[pointer] += "[img=32]icon.svg[/img]$"%word + w
				arr.append("res://Data/Icons/%s.png"%word)
			pointer = STREAM.MEM_REG
			
		elif word == "damage" and pointer != STREAM.OUTPUT:
			streams[STREAM.MEM_REG] += w

			streams[STREAM.OUTPUT] += "[b][color=#%s]"%color + streams[STREAM.MEM_BOLD] + streams[STREAM.MEM_REG] + "[/color][/b]"
			streams[STREAM.MEM_BOLD] = ""
			streams[STREAM.MEM_REG] = ""

			pointer = STREAM.OUTPUT
			color = "000000"

		elif word in lookup.keys():
			streams[pointer] += "[img=32]res://icon.svg[/img]$[b][color=#%s]"%lookup[word] + w.to_upper() + "[/color][/b]"
			color = "000000"
			arr.append("res://Data/Icons/%s.png"%word)

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
			
			
		#print("Out: %s "%w + "(%d) = "%pointer + "...%s"%streams[pointer].substr(max(0, streams[pointer].length() - 30))+"\n")
			

	if streams[STREAM.MEM_BOLD]:
		streams[STREAM.OUTPUT] += "[b][color=#%s]"%color + streams[STREAM.MEM_BOLD] + "[/color][/b]"
	if streams[STREAM.MEM_REG]:
		streams[STREAM.OUTPUT] += streams[STREAM.MEM_REG]

	return {"text": streams[STREAM.OUTPUT], "icons": arr}

var test_text: String = """You're surrounded by orchestral music that shifts and changes to match your behavior.
This music provides a +1 status bonus to Performance checks. At the GM's discretion, it provides this bonus to Deception, Diplomacy, and Intimidation checks as the music changes to support you in social situations, though some creatures are unaffected by such obvious attempts to use music to illicit specific emotions.
This music moves with you and has a maximum volume equal to four humans shouting. You take a –4 penalty to Stealth checks while the music is playing. You can't control the exact music this spell creates. The music doesn't create intelligible words or singing. You can Dismiss this spell."""

func replace_and_find_dollars(text: String, replacement: String) -> Dictionary:
	var indices: Array[int] = []
	var search_index: int = 0
	
	# Find all indices of "$" in the original string
	while true:
		search_index = text.find("$", search_index)
		if search_index == -1:
			break
		indices.append(search_index)
		search_index += 1
		
	# Replace all instances of "$" with the new character
	var new_text: String = text.replace("$", replacement)
	
	return {
		"new_text": new_text,
		"indices": indices
	}

func overlay_images(label: RichTextLabel, icons: Array) -> void:
	print("Called!")
	
	# Retrieve the default font and size to calculate substring widths
	var font: Font = label.get_theme_font("normal_font")
	var font_size: int = label.get_theme_font_size("normal_font_size")
	
	# get_parsed_text() strips BBCode tags, giving us the raw string the user actually sees
	var plain_text: String = label.get_parsed_text()
	var indices: Array[int] = []
	var search_index: int = 0
	
	# Find all indices of "$" in the original string
	while true:
		search_index = plain_text.find("$", search_index)
		if search_index == -1:
			break
		indices.append(search_index - len(indices) - 1)
		search_index += 1
	
	label.text = label.text.replace("$", "")
	plain_text = label.get_parsed_text()
		
	var text_length: int = plain_text.length()
	
	# Extract margins to calculate the true usable width of the label
	var style: StyleBox = null
	if label.has_theme_stylebox("normal"):
		style = label.get_theme_stylebox("normal")
		
	var margin_left: float = style.get_margin(SIDE_LEFT) if style else 0.0
	var margin_right: float = style.get_margin(SIDE_RIGHT) if style else 0.0
	var margin_top: float = style.get_margin(SIDE_TOP) if style else 0.0
	
	var line_separation: int = label.get_theme_constant("line_separation")
	var line_height: float = font.get_height(font_size) + line_separation
	var usable_width: float = label.size.x - margin_left - margin_right
	
	
	for i in range(len(icons)):
		var index: int = indices[i]
		var filepath: String = icons[i]
		
		print(index,"\t", filepath, "\t", plain_text[index])
		
		if index < 0 or index >= text_length:
			continue
			
		var line_idx: int = label.get_character_line(index)
		
		# 1. Isolate the exact start and end of this visual line
		var line_start: int = index
		while line_start > 0 and label.get_character_line(line_start - 1) == line_idx:
			line_start -= 1
			
		var line_end: int = index
		while line_end < text_length and label.get_character_line(line_end) == line_idx:
			line_end += 1
			
		var line_text: String = plain_text.substr(line_start, line_end - line_start)
		
		# 2. Determine if this is the end of a paragraph (Godot doesn't justify paragraph-ending lines)
		var is_last_line: bool = false
		if line_end == text_length:
			is_last_line = true
		elif plain_text.substr(line_end - 1, 1) == "\n" or plain_text.substr(line_end, 1) == "\n":
			is_last_line = true
			
		# 3. Calculate the justified stretch factor per space algebraically
		var stretch_per_space: float = 0.0
		if not is_last_line:
			# Strip trailing whitespace; the TextServer ignores it for justification alignments
			var visual_line_text: String = line_text.rstrip(" \t\n\r")
			var num_spaces: int = visual_line_text.count(" ")
			
			if num_spaces > 0:
				var natural_width: float = font.get_string_size(visual_line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				if usable_width > natural_width:
					stretch_per_space = (usable_width - natural_width) / float(num_spaces)
					
		# 4. Calculate exact X position by evaluating the substring before the target index
		var text_before_target: String = plain_text.substr(line_start, index - line_start)
		var natural_x_pos: float = font.get_string_size(text_before_target, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		var x_pos: float = natural_x_pos + (text_before_target.count(" ") * stretch_per_space) + margin_left
		
		# 5. Calculate Y position based on line index 
		var y_pos: float = margin_top + (line_idx * line_height) + font.get_ascent(font_size) - 16.0
		
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
		texture_rect.position = Vector2(x_pos, y_pos)
		print(x_pos, "\t", y_pos)
		
		label.add_child(texture_rect)


func _ready() -> void:
	trait_colors = load_json_file("res://Data/trait_colors.json")
	print(len(trait_colors.keys()))
