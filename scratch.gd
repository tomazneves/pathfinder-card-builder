
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
