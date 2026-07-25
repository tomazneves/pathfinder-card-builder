
var fixed_size: float = actions.get_rect().size.x + 38.0
var text_size: float = label.get_rect().size.x
var squeeze: float = 1.0

# No compromises
var target_text_size_0: float = right_bound - max_slope_x - slope_margin - fixed_size

# Compromise slope angle
var target_text_size_1: float = right_bound - min_slope_x - slope_margin - fixed_size

var squeeze_0: float = target_text_size_0 / text_size
var squeeze_1: float = target_text_size_1 / text_size

var min_squeezed_text_x: float = text_size * min_squeeze

# If can compress without compromise:
if min_squeezed_text_x <= target_text_size_0:
	# Compress text
	squeeze = squeeze_0
# Else:
else:
	# Compress slope as much as possible
	var slope_delta = right_bound - min_squeezed_text_x - slope_margin
	
	# Compress text to fit
	if slope_delta >= min_slope_x:
		squeeze = squeeze_0
		
	else:
		squeeze = squeeze_1
		
label.scale.x = squeeze
var bg_poly: PackedVector2Array = $Background.polygon
bg_poly[4].x = right_bound
bg_poly[5].x = 



func color_content(text: String, lookup: Dictionary, store: Dictionary) -> String:
	var re_word: RegEx = RegEx.create_from_string("[A-z0-9]+")
	var re_sep: RegEx = RegEx.create_from_string("[^A-z0-9]+")
	var re_value: RegEx = RegEx.create_from_string("[0-9]+d{0,1}[0-9]*")
	
	var words: Array[RegExMatch] = re_word.search_all(text)
	words.append_array(re_sep.search_all(text))
	words.sort_custom(func(a, b): return a.get_start() < b.get_start())
	var parsed: Array = words.map(func(x): return x.get_string())
	
	var new_text: String = ""
	var timeout: int = 10
	var timer: int = 0
	var scratch: String = ""
	var scratch_2: String = ""
	var scratch_enabled: int = 0
	var scratch_color: String = ""
	
	for word in parsed:
		if scratch_enabled:
			timer += 1
			
		if timer >= timeout:
			timer = 0
			scratch_enabled = 0
			if scratch_2 == "":
				new_text += scratch
			else:
				new_text += "[color=#%s][b]"%scratch_color + scratch + "[/b][/color]" + scratch_2
				
			scratch = ""
			scratch_2 = ""
			
		if re_value.search(word):
			scratch_enabled = 1
			
		if word.to_lower() in damage_types and scratch_enabled:
			scratch_color = lookup[word.to_lower()]
			
		if word.to_lower() == "damage" and scratch_enabled:
			scratch += scratch_2 + word
			new_text += "[color=#%s][b]"%scratch_color + scratch + "[/b][/color]"
			scratch_enabled = 0
			scratch = ""
			scratch_2 = ""
			continue
			
			
		if scratch_enabled == 1:
			scratch += word
		elif scratch_enabled == 2:
			scratch_2 += word
			
		elif word.to_lower() not in lookup.keys():
			new_text += word
		else:
			new_text += "[b][color=#%s]"%lookup[word.to_lower()] + word.to_upper() + "[/color][/b]"
				
		if word.to_lower() in damage_types and scratch_enabled == 1:
			scratch_enabled = 2
	if scratch != "":
		new_text += "[color=#%s][b]"%scratch_color + scratch + "[/b][/color]"
	if scratch_2 != "":
		new_text += scratch_2
	return new_text
	
func _split_into_words(text: String) -> Array:
	var re_word: RegEx = RegEx.create_from_string("[A-z0-9]+")
	var re_sep: RegEx = RegEx.create_from_string("[^A-z0-9]+")
	
	var words: Array[RegExMatch] = re_word.search_all(text)
	words.append_array(re_sep.search_all(text))
	words.sort_custom(func(a, b): return a.get_start() < b.get_start())
	var parsed: Array = words.map(func(x): return x.get_string())

	return parsed



func find_and_replace(text: String, query: String, replacement: String) -> Dictionary:
	var indices: Array[int] = []
	var search_index: int = 0
	
	# Find all indices of "$" in the original string
	while true:
		search_index = text.find(query, search_index)
		if search_index == -1:
			break
		indices.append(search_index - len(query) * len(indices))
		search_index += 1
		
	# Replace all instances of "$" with the new character
	var new_text: String = text.replace(query, replacement)
	
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

func get_character_bounding_boxes(label: RichTextLabel, indices: Array[int], paragraph: TextParagraph) -> Array[Rect2]:
	var normal_font: Font = label.get_theme_font("normal_font")
	var bold_font: Font = label.get_theme_font("bold_font")
	var font_size: int = label.get_theme_font_size("normal_font_size")
	var line_separation: int = label.get_theme_constant("line_separation")
	
	# Extract margins to calculate true layout bounds
	var style: StyleBox = label.get_theme_stylebox("normal") if label.has_theme_stylebox("normal") else null
	var margin_left: float = style.get_margin(SIDE_LEFT) if style else 0.0
	var margin_top: float = style.get_margin(SIDE_TOP) if style else 0.0
	var margin_right: float = style.get_margin(SIDE_RIGHT) if style else 0.0
	
	# TextParagraph handles multiline word-wrapping via TextServer
	
	# 1. Parse [b] and [/b] to reconstruct the shaped text spans
	var raw: String = label.text
	var pos: int = 0
	var is_bold: bool = false
	var current_text: String = ""
	var raw_len: int = raw.length()
	var text_length: int = 0
	var dump = ""
	
	while pos < raw_len:
		if raw.substr(pos, len("[color=#")) == "[color=#":
			pos += len("[color=#000000]")
		elif raw.substr(pos, len("[/color]")) == "[/color]":
			pos += len("[/color]")
		if raw.substr(pos, 3) == "[b]":
			if current_text != "":
				paragraph.add_string(current_text, bold_font if is_bold else normal_font, font_size)
				dump += current_text
				current_text = ""
			is_bold = true
			pos += 3
		elif raw.substr(pos, 4) == "[/b]":
			if current_text != "":
				paragraph.add_string(current_text, bold_font if is_bold else normal_font, font_size)
				dump += current_text
				current_text = ""
			is_bold = false
			pos += 4
		else:
			current_text += raw[pos]
			pos += 1
			text_length += 1
			
	if current_text != "":
		paragraph.add_string(current_text, bold_font if is_bold else normal_font, font_size)
		dump += current_text
		
	print(dump)
	# Apply width constraint to force identical line wrapping to the RichTextLabel
	paragraph.width = 710.0 - 2*48.0
	
	
	# 2. Retrieve bounding boxes using the primary TextServer interface
	var ts: TextServer = TextServerManager.get_primary_interface()
	var results: Array[Rect2] = []
	
	for target_idx in indices:
		print(target_idx)
		var found: bool = false
		var current_y: float = margin_top
		
		# Iterate over wrapped lines in the paragraph
		for line_idx in range(paragraph.get_line_count()):
			var char_range: Vector2i = paragraph.get_line_range(line_idx)
			print("Line %d: "%line_idx + "\"%s\""%dump.substr(char_range.x, char_range.y))
			
			# Check if target_idx falls into the character range for this specific line
			if target_idx >= char_range.x and target_idx < char_range.y:
				var line_rid: RID = paragraph.get_line_rid(line_idx)
				
				# Get the carets Dictionary
				var carets: Dictionary = ts.shaped_text_get_carets(line_rid, target_idx)
				
				if carets.has("leading_rect") and carets.has("trailing_rect"):
					var lead_rect: Rect2 = carets["leading_rect"]
					var trail_rect: Rect2 = carets["trailing_rect"]
					
					# The X position of the caret represents the edge of the character
					var lead_x: float = lead_rect.position.x
					var trail_x: float = trail_rect.position.x
					
					var char_x: float = min(lead_x, trail_x)
					var char_width: float = abs(trail_x - lead_x)
					
					var ascent: float = paragraph.get_line_ascent(line_idx)
					var descent: float = paragraph.get_line_descent(line_idx)
					
					# Construct the final bounding box
					var char_rect: Rect2 = Rect2(
						char_x + margin_left,
						current_y, 
						char_width,
						ascent + descent
					)
					
					print(char_rect)
					results.append(char_rect)
					found = true
					break
				
			# Advance Y to the next line's starting height
			current_y += paragraph.get_line_size(line_idx).y + line_separation
			
		if not found:
			results.append(Rect2()) # Fallback empty rect for out-of-bounds indices
			
	return results

func create_wireframes(parent: Node, rects: Array[Rect2], color: Color = Color.RED, thickness: float = 1.0) -> Array[ReferenceRect]:
	print(rects)
	var wireframes: Array[ReferenceRect] = []
	
	for rect in rects:
		rect.size.x = 32
		# ReferenceRect provides an empty bounding box with a colored border
		var wireframe: ReferenceRect = ReferenceRect.new()
		
		# By default, ReferenceRects are invisible in the running game.
		wireframe.editor_only = false 
		
		# Map the Rect2 coordinates to the node
		wireframe.position = rect.position
		wireframe.size = rect.size
		
		# Styling
		wireframe.border_color = color
		wireframe.border_width = thickness
		wireframe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		parent.add_child(wireframe)
		wireframes.append(wireframe)
		
	return wireframes

func position_images(parent: Node, rects: Array[Rect2], paths: Array) -> Array:
	var images: Array = []
	for i in range(len(rects)):
		var filepath: String = paths[i]
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
		texture_rect.position = rects[i].position
		
		parent.add_child(texture_rect)
		images.append(texture_rect)
		
	return images
	

# Task 1: Initialize a TextParagraph from a RichTextLabel with specific formatting
func create_paragraph_from_rtl(rtl: RichTextLabel) -> TextParagraph:
	var paragraph = TextParagraph.new()
	
	# Apply Justification and alignment properties
	paragraph.alignment = HORIZONTAL_ALIGNMENT_FILL
	var j_flags = TextServer.JUSTIFICATION_KASHIDA | TextServer.JUSTIFICATION_WORD_BOUND
	j_flags |= TextServer.JUSTIFICATION_SKIP_LAST_LINE
	paragraph.justification_flags = j_flags
	
	# Set the paragraph width to match the RichTextLabel's bounds (crucial for justification)
	paragraph.width = rtl.size.x
	
	# Grab default fonts and colors from the RichTextLabel's theme
	var normal_font = rtl.get_theme_font("normal_font")
	var bold_font = rtl.get_theme_font("bold_font")
	var font_size = rtl.get_theme_font_size("normal_font_size")
	var default_color = rtl.get_theme_color("default_color")
	
	var current_font = normal_font
	var current_color = default_color
	
	# Parse BBCode for [b], [/b], [color=#XXXXXX], and [/color]
	var regex = RegEx.create_from_string("\\[/?(b|color(=#[0-9a-fA-F]{6})?)\\]")
	var text = rtl.text
	var last_pos = 0
	
	for result in regex.search_all(text):
		var match_start = result.get_start()
		var match_end = result.get_end()
		var tag = result.get_string()
		
		# Add the text leading up to the tag
		if match_start > last_pos:
			var chunk = text.substr(last_pos, match_start - last_pos)
			paragraph.add_string(chunk, current_font, font_size)
			
		# Update styling based on the tag
		if tag == "[b]":
			current_font = bold_font
		elif tag == "[/b]":
			current_font = normal_font
		elif tag.begins_with("[color="):
			var hex_code = tag.substr(7, 7) # Extract the #XXXXXX portion
			current_color = Color(hex_code)
		elif tag == "[/color]":
			current_color = default_color
			
		last_pos = match_end
		
	# Append any remaining text after the final tag
	if last_pos < text.length():
		var chunk = text.substr(last_pos, text.length() - last_pos)
		paragraph.add_string(chunk, current_font, font_size)
		
	return paragraph

# Task 2: Get the local position of a character by its stripped index using carets
func get_character_position(paragraph: TextParagraph, char_index: int) -> Vector2:
	var y_offset = 0.0
	var text_server = TextServerManager.get_primary_interface()
	
	for line_idx in paragraph.get_line_count():
		var line_range = paragraph.get_line_range(line_idx)
		
		# Check if the requested character index falls within this line
		if char_index >= line_range.x and char_index < line_range.y:
			var line_rid = paragraph.get_line_rid(line_idx)
			var ascent = paragraph.get_line_ascent(line_idx)
			
			# Request the carets for this specific character index
			var carets: Dictionary = text_server.shaped_text_get_carets(line_rid, char_index)
			if carets.has("leading_rect") and carets.has("trailing_rect"):
				var lead_rect: Rect2 = carets["leading_rect"]
				var trail_rect: Rect2 = carets["trailing_rect"]
				
				# The X position of the caret represents the edge of the character
				var lead_x: float = lead_rect.position.x
				var trail_x: float = trail_rect.position.x
				
				var char_x: float = min(lead_x, trail_x)
				var char_width: float = abs(trail_x - lead_x)
				
				return Vector2(char_x, ascent)
			else:
				return Vector2.ZERO # Fallback if caret data is missing
			
		# Move our Y offset down by the total height of the current line
		y_offset += paragraph.get_line_size(line_idx).y
		
	# Fallback if the index is out of bounds
	return Vector2.ZERO
