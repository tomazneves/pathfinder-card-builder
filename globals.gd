extends Node
class_name GlobalClasses

var is_processing_screenspace: bool = false


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
const conditions: Array[String] = [
	"blinded", "broken", "clumsy", "concealed", "confused", "controlled",
	"dazzled", "deafened", "doomed", "drained", "dying", "encumbered",
	"enfeebled", "fascinated", "fatigued", "fleeing", "frightened",
	"grabbed", "hidden", "immobilized", "invisible", "off-guard",
	"paralyzed", "petrified", "prone", "quickened", "restrained",
	"sickened", "slowed", "stunned", "stupefied", "unconscious", "wounded",
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
	
	var test_text = """You send out a ray of colored light streaming toward your enemy, with a magical effect depending on the ray's color. Make a spell attack roll. If you hit, roll 1d4 to see which beam you cast. If the ray deals damage, that damage is doubled on a critical hit. Any additional traits that apply to a ray are listed in parentheses just after the name of the color.\n[ul]\nRed (fire) The ray deals 30 fire damage to the target.\nOrange (acid) The ray deals 40 acid damage to the target.\nYellow (electricity) The ray deals 50 electricity damage to the target.\nGreen (poison) The ray deals 25 poison damage to the target, and the target must succeed at a Fortitude save or be enfeebled 1 for 1 minute (enfeebled 2 on a critical failure).\n[/ul]"""

	print(test_text)
	
	print("\t\t|\n\t\tV")
	
	print(color_text(test_text, "(XX)"))

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
	
	
# =============================================================================
# Formats raw Pathfinder 2e activity text into BBCode suitable for a
# RichTextLabel (bbcode_enabled = true), highlighting:
#   1. Traits            -> bold, UPPERCASE, color = Globals.trait_colors,
#                            placeholder-prefixed, EXCEPT when the trait word
#                            is actually part of a damage reference.
#   2. Damage references  -> bold, color = Globals.damage_types. NOT
#                            placeholder-prefixed (see note at bottom of file
#                            if you want that behavior instead).
#   3. Conditions         -> bold, color = Globals.TYPE_COLORS[CardType.DEBUFF],
#                            placeholder-prefixed.
#   4. Degree-of-success headers ("\nCritical Success", "\nFailure", ...)
#                         -> bold, with a trailing semicolon.
#
# Returns a Dictionary:
#   {
#     "text":         the formatted BBCode string,
#     "placeholders": the lowercase name of each trait/condition that
#                      received a placeholder, IN THE ORDER the placeholders
#                      occur in "text". Use this to walk the string
#                      afterwards (e.g. String.find(placeholder_text, from))
#                      and swap each occurrence for an icon, in order, one
#                      name per hit.
#   }
# =============================================================================

static func color_text(raw_text: String, placeholder_text: String) -> Dictionary:
	var placeholder_names: Array = []
	var all_matches: Array = []  # each entry: {start, end, priority, text, name?}

	# ---- small helpers ------------------------------------------------------
	var escape_re := func(s: String) -> String:
		var out := s
		for ch in ["\\", "+", "*", "?", ".", "(", ")", "[", "]", "{", "}", "^", "$", "|"]:
			out = out.replace(ch, "\\" + ch)
		return out

	var build_alt := func(keys: Array) -> String:
		var escaped: Array = []
		for k in keys:
			escaped.append(escape_re.call(k))
		# Longest-first so a short key (e.g. "fire") can never swallow part
		# of a longer one that happens to contain it.
		escaped.sort_custom(func(a, b): return a.length() > b.length())
		return "|".join(escaped)

	var overlaps_existing := func(s: int, e: int) -> bool:
		for existing in all_matches:
			if s < existing["end"] and e > existing["start"]:
				return true
		return false

	# =========================================================================
	# 1. DAMAGE REFERENCES  (bold + color, NO placeholder)
	# =========================================================================
	var damage_alt: String = build_alt.call(Globals.damage_types)

	if not damage_alt.is_empty():
		# "2d6 fire damage" / "1 persistent bleed damage"
		var dmg_re_typed := RegEx.new()
		dmg_re_typed.compile(
			"(?i)\\b(\\d+d\\d+(?:\\s*[+-]\\s*\\d+)?|\\d+)\\s+(persistent\\s+)?(" + damage_alt + ")\\s+damage\\b"
		)
		for m in dmg_re_typed.search_all(raw_text):
			var type_name: String = m.get_string(3).to_lower()
			var color: Color = Globals.trait_colors.get(type_name, Color.BLACK)
			all_matches.append({
				"start": m.get_start(), "end": m.get_end(), "priority": 3,
				"text": placeholder_text + "[b][color=#%s]%s[/color][/b]" % [color.to_html(false), m.get_string()],
				"name": type_name
			})

		# "cold damage increases by 1" / "damage increases by 1d6" (type optional)
		var dmg_re_increase := RegEx.new()
		dmg_re_increase.compile(
			"(?i)\\b(?:(" + damage_alt + ")\\s+)?damage\\s+increases\\s+by\\s+(\\d+d\\d+(?:\\s*[+-]\\s*\\d+)?|\\d+)\\b"
		)
		for m in dmg_re_increase.search_all(raw_text):
			var type_name2: String = m.get_string(1).to_lower()
			var color2: Color = Globals.trait_colors.get(type_name2, Color.BLACK) if type_name2 != "" else Color.BLACK
			all_matches.append({
				"start": m.get_start(), "end": m.get_end(), "priority": 3,
				"text": placeholder_text + "[b][color=#%s]%s[/color][/b]" % [color2.to_html(false), m.get_string()],
				"name": type_name2,
			})

	# Plain "2d6 damage" with no type word at all. Not one of the spec's
	# examples, but common in PF2e text -- delete this block if unwanted.
	var dmg_re_untyped := RegEx.new()
	dmg_re_untyped.compile("(?i)\\b(\\d+d\\d+(?:\\s*[+-]\\s*\\d+)?|\\d+)\\s+damage\\b")
	for m in dmg_re_untyped.search_all(raw_text):
		var s: int = m.get_start()
		var e: int = m.get_end()
		if overlaps_existing.call(s, e):
			continue
		var color3: Color = Globals.trait_colors.get("untyped", Color.BLACK)
		all_matches.append({
			"start": s, "end": e, "priority": 3,
			"text": "[b][color=#%s]%s[/color][/b]" % [color3.to_html(false), m.get_string()],
		})

	# "Fast Healing 2" / "Healing 10" -- not phrased with the word "damage",
	# but treated as a damage-type reference using Globals.damage_types["healing"].
	var healing_re := RegEx.new()
	healing_re.compile("(?i)\\b((?:fast\\s+)?healing)\\s+(\\d+)\\b")
	for m in healing_re.search_all(raw_text):
		var heal_color: Color = Globals.trait_colors.get("healing", Color.WHITE)
		all_matches.append({
			"start": m.get_start(), "end": m.get_end(), "priority": 3,
			"text": placeholder_text + "[b][color=#%s]%s[/color][/b]" % [heal_color.to_html(false), m.get_string()],
			"name": "healing"
		})
 
	# "restores 5 HP" / "gains 1d8 temporary HP" / "regaining 3 Hit Points" etc.
	# -- "restores?"/"heals?"/"gains?"/"regains?" also pick up the bare
	# "restore"/"heal"/"gain"/"regain" forms for free (plural-subject phrasing).
	var hp_verbs := "restores?|restoring|heals?|healing|gains?|gaining|regains?|regaining"
	var hp_gain_re := RegEx.new()
	hp_gain_re.compile(
		"(?i)\\b(?:" + hp_verbs + ")\\s+(\\d+d\\d+(?:\\s*[+-]\\s*\\d+)?|\\d+)\\s+(temporary\\s+)?(?:HP|hit\\s+points?)\\b"
	)
	for m in hp_gain_re.search_all(raw_text):
		var is_temp: bool = m.get_string(2) != ""
		var hp_type_key: String = "temp_hp" if is_temp else "healing"
		var hp_color: Color = Globals.trait_colors.get(hp_type_key, Globals.TYPE_COLORS[Globals.CardType.BUFF])
		all_matches.append({
			"start": m.get_start(), "end": m.get_end(), "priority": 3,
			"text": placeholder_text + "[b][color=#%s]%s[/color][/b]" % [hp_color.to_html(false), m.get_string()],
			"name": hp_type_key
		})

	# =========================================================================
	# 2. CONDITIONS  (bold + placeholder + DEBUFF color)
	# =========================================================================
	var cond_alt: String = build_alt.call(Globals.conditions)

	if not cond_alt.is_empty():
		var cond_re := RegEx.new()
		cond_re.compile("(?i)\\b(" + cond_alt + ")\\b(\\s+increases\\s+by\\s+\\d+|\\s+\\d+)?")

		var debuff_color: Color = Globals.TYPE_COLORS[Globals.CardType.DEBUFF]
		for m in cond_re.search_all(raw_text):
			var s2: int = m.get_start()
			var e2: int = m.get_end()
			if overlaps_existing.call(s2, e2):
				continue
			var cond_name: String = m.get_string(1).to_lower()
			all_matches.append({
				"start": s2, "end": e2, "priority": 2,
				"text": placeholder_text + "[b][color=#%s]%s[/color][/b]" % [debuff_color.to_html(false), m.get_string()],
				"name": cond_name,
			})

	# =========================================================================
	# 3. TRAITS  (bold + UPPERCASE + placeholder + color), skipped if the
	#    matched word falls inside anything already claimed above (i.e. it's
	#    actually part of a damage reference, or overlaps a condition)
	# =========================================================================
	var trait_alt: String = build_alt.call(Globals.trait_colors.keys())

	if not trait_alt.is_empty():
		var trait_re := RegEx.new()
		trait_re.compile("(?i)\\b(" + trait_alt + ")\\b")

		for m in trait_re.search_all(raw_text):
			var s3: int = m.get_start()
			var e3: int = m.get_end()
			if overlaps_existing.call(s3, e3):
				continue
			var trait_name: String = m.get_string(1).to_lower()
			var t_color: Color = Globals.trait_colors[trait_name]
			all_matches.append({
				"start": s3, "end": e3, "priority": 1,
				"text": placeholder_text + "[b][color=#%s]%s[/color][/b]" % [t_color.to_html(false), trait_name.to_upper()],
				"name": trait_name,
			})

	# =========================================================================
	# 4. DEGREES OF SUCCESS  (bold, ends in ";")
	# =========================================================================
	var degree_re := RegEx.new()
	degree_re.compile("(?m)^(Critical Success|Success|Critical Failure|Failure)\\b")
	for m in degree_re.search_all(raw_text):
		all_matches.append({
			"start": m.get_start(), "end": m.get_end(), "priority": 0,
			"text": "[b]%s;[/b]" % m.get_string(),
		})

	# =========================================================================
	# Resolve overlaps (higher priority wins a tie at the same start) and
	# assemble the final string left-to-right.
	# =========================================================================
	all_matches.sort_custom(func(a, b):
		if a["start"] != b["start"]:
			return a["start"] < b["start"]
		return a["priority"] > b["priority"]
	)

	var accepted: Array = []
	var cursor := -1
	for entry in all_matches:
		if entry["start"] < cursor:
			continue  # overlaps something already accepted; drop it
		accepted.append(entry)
		cursor = entry["end"]

	var out := ""
	var pos := 0
	for entry in accepted:
		out += raw_text.substr(pos, entry["start"] - pos)
		out += entry["text"]
		pos = entry["end"]
		if entry.has("name"):
			placeholder_names.append(entry["name"])
	out += raw_text.substr(pos)

	return {
		"text": out,
		"icons": placeholder_names,
	}


# -----------------------------------------------------------------------------
# Want damage types to ALSO get a placeholder (e.g. a flame icon before
# "fire damage")? In the two damage loops above, change the appended text to:
#
#   "text": placeholder_text + "[b][color=#%s]%s[/color][/b]" % [...],
#   "name": type_name,
#
# and it'll behave exactly like traits/conditions do.
# -----------------------------------------------------------------------------
