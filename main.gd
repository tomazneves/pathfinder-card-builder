extends Control


func sleep(t: float) -> void:
	await get_tree().create_timer(t).timeout 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func save_to_image_2() -> void:
	await RenderingServer.frame_post_draw
	var capture = get_viewport().get_texture().get_image()
	var filename = "user://Screenshot-test-pf2ecard.png"
	capture.save_png(filename)

func _on_button_pressed() -> void:
	var s: String = \
"""{
  "type": "Attack",
  "name": "Chromatic Ray",
  "cost": "aa",
  "category": "Spell 4",
  "traits": [
    "Attack",
    "Concentrate",
    "Manipulate",
    "Light"
  ],
  "traditions": [
    "Arcane",
    "Occult"
  ],
  "range": "30 feet",
  "frequency": "",
  "targets": "1 creature",
  "area": "",
  "defense": "AC",
  "duration": "",
  "requirements": "",
  "trigger": "",
  "materials": "",
  "condension": 0,
  "description": "You send out a ray of colored light streaming toward your enemy, with a magical effect depending on the ray's color. Make a spell attack roll. If you hit, roll 1d4 to see which beam you cast. If the ray deals damage, that damage is doubled on a critical hit. Any additional traits that apply to a ray are listed in parentheses just after the name of the color.
[ol type=1]
[b]Red:[/b] (fire) The ray deals 30 fire damage to the target.
[b]Orange:[/b] (acid) The ray deals 40 acid damage to the target.
[b]Yellow:[/b] (electricity) The ray deals 50 electricity damage to the target.
[b]Green:[/b] (poison) The ray deals 25 poison damage to the target, and the target must succeed at a Fortitude save or be enfeebled 1 for 1 minute (enfeebled 2 on a critical failure).
[/ol]",
  "heightened": ""
}"""

	var flense: String =\
"""{
  "type": "Attack",
  "name": "Fortissimo Composition",
  "cost": "aa",
  "category": "Focus 1",
  "traits": [
    "Uncommon",
    "Necromancy",
    "Concentrate",
    "Manipulate"
  ],
  "traditions": [
    "Arcane",
    "Divine"
  ],
  "range": "touch",
  "frequency": "",
  "targets": "1 creature or corpse",
  "area": "",
  "defense": "AC",
  "duration": "",
  "requirements": "",
  "trigger": "",
  "materials": "",
  "condension": 3,
  "description": "haha 67",
  "heightened": "[b]Heightened (+1):[/b] The slashing damage to living and undead creatures increases by 2d6, and the persistent bleed damage to living creatures increases by 1d4."
}"""

	parse_json(s, $GridContainer/Card9)
	parse_json(flense, $GridContainer/Card8)
	await save_to_image(99)

func parse_json(data, card: Card) -> void:
	if typeof(data) == TYPE_STRING:
		data = JSON.parse_string(data)
	
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Failed to parse JSON string or JSON is not a Dictionary.")
		return
	
	# Handle the Enum conversion for card_type based on the previous snippet
	var type_string: String = data.get("type", "").to_upper()
	if Card.CardType.keys().has(type_string):
		card.card_type = Card.CardType.get(type_string)
		
	card.card_name = data.get("name", "")
	print("doing...")
	card._update_card_visuals()
	card.card_cost = data.get("cost", "").to_upper() # Capitalizes "aa" to "AA"
	print("doing...")
	card._update_card_visuals()
	card.card_category = data.get("category", "")
	print("doing...")
	card._update_card_visuals()
	card.card_materials = data.get("materials", "")
	print("doing...")
	card._update_card_visuals()
	
	# Godot 4 requires explicit casting for typed arrays
	var parsed_traits: Array[String] = []
	for t in data.get("traits", []):
		parsed_traits.append(str(t))
	card.card_traits = parsed_traits
	print("doing...")
	card._update_card_visuals()
	
	var parsed_traditions: Array[String] = []
	for t in data.get("traditions", []):
		parsed_traditions.append(str(t))
	card.card_traditions = parsed_traditions
	print("doing...")
	card._update_card_visuals()
	
	card.card_range = data.get("range", "")
	print("doing...")
	card._update_card_visuals()
	card.card_frequency = data.get("frequency", "")
	print("doing...")
	card._update_card_visuals()
	card.card_targets = data.get("targets", "")
	print("doing...")
	card._update_card_visuals()
	card.card_area = data.get("area", "")
	print("doing...")
	card._update_card_visuals()
	card.card_defense = data.get("defense", "")
	print("doing...")
	card._update_card_visuals()
	card.card_duration = data.get("duration", "")
	print("doing...")
	card._update_card_visuals()
	card.card_requirements = data.get("requirements", "")
	print("doing...")
	card._update_card_visuals()
	card.card_trigger = data.get("trigger", "")
	print("doing...")
	card._update_card_visuals()
	card.card_description = data.get("description", "")
	print("doing...")
	card._update_card_visuals()
	card.card_heightened = data.get("heightened", "")
	print("doing...")
	card._update_card_visuals()
	card._recalculate_header_constants()
	card._update_card_visuals()
	
func _hide_all_cards() -> void:
	for i in range(9):
		var card_index = i + 1
		var card_node = get_node("GridContainer/Card" + str(card_index))
		card_node.hide()
		
func parse_many_cards(json_string: String) -> void:
	var card_list = JSON.parse_string(json_string)
	
	if typeof(card_list) != TYPE_ARRAY:
		push_error("Failed to parse JSON string or JSON is not an Array.")
		return
		
	var current_page: int = 1
	var card_index: int = 1

	_hide_all_cards()

	for card_data in card_list:
		var card: Card = get_node("GridContainer/Card" + str(card_index))
		card.show()
		parse_json(card_data, card)
		await get_tree().process_frame
		
		if card_index == 9:
			await save_to_image(current_page)
			current_page += 1
			card_index = 1
			_hide_all_cards()
		else:
			card_index += 1
			
	if card_index > 1:
		await save_to_image(current_page)

func save_to_image(page_number: int) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var file_path: String = "user://card_page_%s.png" % str(page_number)

	var error = image.save_png(file_path)
	if error == OK:
		print("Saved page to: ", file_path)
	else:
		push_error("Failed to save image. Error code: ", error)

var test_multicard_string: String = \
"""[{"type": "Healing","name": "Soothe","cost": "2","category": "Spell 1","traits": ["Concentrate","Emotion","Healing","Manipulate","Mental"],"traditions": ["Occult"],"range": "30 feet","frequency": "","targets": "1 willing creature","area": "","defense": "","duration": "1 minute","requirements": "","trigger": "","materials": "","condension": 0,"description": "You grace the target's mind, boosting its mental defenses and healing its wounds. The target regains 1d10+4 Hit Points when you Cast the Spell and gains a +2 status bonus to saves against mental effects for the duration.","heightened": "[b]Heightened (+1): [/b]The amount of healing increases by 1d10+4."},{"type": "Attack","name": "Debilitating Dichotomy","cost": "2","category": "Feat 8","traits": ["Concentrate","Cursebound","Divine","Mental","Oracle"],"traditions": [],"range": "30 feet","frequency": "","targets": "You and 1 creature","area": "","defense": "Basic Will","duration": "","requirements": "","trigger": "","materials": "","condension": 0,"description": "You reveal a glimpse of the impossible conflicts between the divine anathema behind your curse, forcing you to reckon with another's conflicts as well. You and one creature within 30 feet each take 9d6 mental damage with a basic Will save, and the target is stunned 1 if it critically fails its save. You get a degree of success one better than you rolled for your saving throw. At 10th level, and every 2 levels thereafter, the damage increases by 3d6.","heightened": ""},{"type": "Debuff","name": "Disturbing Knowledge","cost": "2","category": "Feat 7","traits": ["Emotion","Fear","General","Mental","Skill"],"traditions": [],"range": "30 feet","frequency": "","targets": "1 enemy","area": "","defense": "","duration": "","requirements": "master in Occultism","trigger": "","materials": "","condension": 0,"description": "You utter a litany of dreadful names, prophecies, and descriptions of realms beyond mortal comprehension, drawn from your study of forbidden tomes and scrolls. Even those who don't understand your language are unsettled by these dire secrets. Attempt an Occultism check and compare the result to the Will DC of an enemy within 30 feet, or to the Will DCs of any number of enemies within 30 feet if you are legendary in Occultism. Those creatures are temporarily immune for 24 hours.\n[ul]\n[b]Critical Success:[/b] The target becomes confused for 1 round and frightened 1.\n[b]Success:[/b] The target becomes frightened 1.\n[b]Failure:[/b] The target is unaffected.\n[b]Critical Failure:[/b] You get overly caught up in your own words and become frightened 1.\n[/ul]","heightened": ""},{"type": "Attack","name": "Blazing Wave","cost": "2","category": "Feat 4","traits": ["Fire","Impulse","Kineticist","Overflow","Primal"],"traditions": [],"range": "","frequency": "","targets": "","area": "30-foot cone","defense": "basic Reflex","duration": "","requirements": "","trigger": "","materials": "","condension": 0,"description": "Flames flow out of you in a cascade, engulfing everyone in a 30-foot cone. Each creature in the area takes 4d6 fire damage with a basic Reflex save against your class DC. A creature that critically fails its save is knocked prone.","heightened": "[b]Level (+2): [/b]The damage increases by 1d6."}]"""


func _on_button_2_pressed() -> void:
	parse_many_cards(test_multicard_string)
