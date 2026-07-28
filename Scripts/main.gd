extends Control

@onready var default_front: CardFront = $DefaultFront
@onready var default_back: CardBack = $DefaultBack
@onready var buttons: Array[Node] = $Buttons.get_children()
@onready var cards: Array[Node] = $Cards.get_children()
@onready var backs: Array[Node] = $CardBacks.get_children()
@onready var card_editor := $PopupPanel/VBoxContainer/CardEditor
@onready var timer: Timer = $Digestion

@onready var card_pairs := [
	[cards[0], backs[2]],
	[cards[1], backs[1]],
	[cards[2], backs[0]],
	[cards[3], backs[5]],
	[cards[4], backs[4]],
	[cards[5], backs[3]],
	[cards[6], backs[8]],
	[cards[7], backs[7]],
	[cards[8], backs[6]]
]

var save_prefix: String = "print_pg_"

var selected_card: CardFront = null
var save_directory: String = "user://"
var plate: Array[String]
var current_page: int = 100

func _save_front() -> void:
	$CardBacks.hide()
	$Cards.show()
	$CuttingGuide.show()
	$PageNum.text = "%d\n"%current_page
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	save_to_image(save_prefix + "%s_front.png"%current_page, save_directory)
	
func _save_back() -> void:
	$CardBacks.show()
	$Cards.hide()
	$CuttingGuide.hide()
	$PageNum.text = "%d\n"%current_page
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await save_to_image(save_prefix + "%s_back.png"%current_page, save_directory)
	
func _digest_information(data: Array[String]) -> Array[String]:
	$CardBacks.hide()
	$Cards.show()
	$CuttingGuide.show()
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var chewing: Array[String] = data.slice(0, 9)
	for i in range(9):
		cards[i]._hide()
		backs[i]._hide()
	
	for i in range(len(chewing)):
		for card in card_pairs[i]:
			card._show()
			await card.from_json_string(chewing[i])
			await Globals.sleep(0.2)
			await get_tree().process_frame
			await get_tree().process_frame
			await card._update_card_visuals()
			await Globals.sleep(0.2)
			await get_tree().process_frame
			await get_tree().process_frame
			await card._update_card_visuals()
		print(i, ": ", Globals.CardType.keys()[cards[i].card_type])
		data.remove_at(0)
			
	return data
		
func _parse_json(json: String) -> Array[String]:
	var plate: Array[String] = []
	
	var list: Array = JSON.parse_string(json)
	if list == null:
		print("ERROR: STRING NOT CORRECT.")
		return plate
		
	list.sort_custom(func(a, b): return a.get("card_type", "") > b.get("card_type", ""))
	for dict in list:
		print(dict["card_type"], " ", dict["card_name"])
		plate.append(JSON.stringify(dict))
		
		
	return plate

func _on_card_selected(card: CardFront) -> void:
	if selected_card != null:
		apply_changes(selected_card)
		
	selected_card = card
	print(selected_card.name, ": ", selected_card)
	card_editor.set_card_info(selected_card.to_json_string())
	$PopupPanel.popup_centered()

func _set_buttons() -> void:
	for i in range(len(buttons)):
		var button: Button = buttons[i]
		button.focus_neighbor_bottom = buttons[(i+3)%9].get_path()
		button.focus_neighbor_top = buttons[(i-3)%9].get_path()
		button.focus_neighbor_right = buttons[i/3 + (i+1)%3].get_path()
		button.focus_neighbor_left = buttons[i/3 + (i-1)%3].get_path()
		button.focus_next = buttons[(i+1)%3].get_path()
		button.focus_previous = buttons[(i-1)%3].get_path()

		button.pressed.connect(_on_card_selected.bind(cards[i]))

func _ready():
	for attr in ["materials", "traditions", "range", "frequency", "targets", "area", "defense", "duration", "requirements", "trigger", "description", "heightened"]:
		print("\tcard.card_%s = data.get(\"%s\", default_front.card_%s)"%[attr, attr, attr])
	_set_buttons()
	
func _hide_all_cards() -> void:
	for i in range(9):
		var card_index = i + 1
		var card_node = get_node("GridContainer/Card" + str(card_index))
		card_node.hide()

func save_to_image(filename: String, directory: String = "user://") -> void:
	$MarginContainer.hide()
	$Buttons.hide()
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var capture = get_viewport().get_texture().get_image()
	var error = capture.save_png(directory.path_join(filename))
	if error == OK:
		print("Saved page to: ", directory.path_join(filename))
	else:
		push_error("Failed to save image. Error code: ", error)
	$MarginContainer.show()
	$Buttons.show()

func build_card_front(data: Dictionary, card: CardFront) -> void:
	card.card_name =         data.get("name",         default_front.card_name)
	card.card_category =     data.get("category",     default_front.card_category)
	card.card_traits =       data.get("traits",       default_front.card_traits)
	card.card_materials =    data.get("materials",    default_front.card_materials)
	card.card_traditions =   data.get("traditions",   default_front.card_traditions)
	card.card_range =        data.get("range",        default_front.card_range)
	card.card_frequency =    data.get("frequency",    default_front.card_frequency)
	card.card_targets =      data.get("targets",      default_front.card_targets)
	card.card_area =         data.get("area",         default_front.card_area)
	card.card_defense =      data.get("defense",      default_front.card_defense)
	card.card_duration =     data.get("duration",     default_front.card_duration)
	card.card_requirements = data.get("requirements", default_front.card_requirements)
	card.card_trigger =      data.get("trigger",      default_front.card_trigger)
	card.card_description =  data.get("description",  default_front.card_description)
	card.card_heightened =   data.get("heightened",   default_front.card_heightened)
	card.card_source =       data.get("source",       default_front.card_source)
	var card_type_str: String = data.get("type", "UTILITY").to_upper()
	if Globals.CardType.keys().has(card_type_str):
		card.card_type = Globals.CardType.get(card_type_str)
	else:
		print("Warning: %s (%s) has type \"%s\", defaulted to \"UTILITY\""%[card.name, card.card_name, card_type_str])
		card.card_type = default_front.card_type
		
	var card_cost_str: String = data.get("cost", "ONE_ACTION").to_upper().replace("-", "_")
	if Globals.CardCost.keys().has(card_cost_str):
		card.card_cost = Globals.CardCost.get(card_cost_str)
	else:
		print("Warning: %s (%s) has cost \"%s\", defaulted to \"ONE_ACTION\""%[card.name, card.card_name, card_cost_str])
		card.card_cost = default_front.card_cost


func apply_changes(card: CardFront) -> String:
	var card_info: String = card_editor.get_card_info()
	card.from_json_string(card_info)
	await card._update_card_visuals()
	await get_tree().process_frame
	await card._update_card_visuals()
	await get_tree().process_frame
	return card_info


func _on_close_button_pressed() -> void:
	$PopupPanel.hide()


func _on_popup_panel_popup_hide() -> void:
	apply_changes(selected_card)
	selected_card = null


func _on_load_pressed() -> void:
	var test_json: String = FileAccess.get_file_as_string(save_directory.path_join("export.json"))
	#print(test_json)
	plate = _parse_json(test_json)
	print("\n\n\n\n\n")
	current_page = 1
	if len(plate) > 0:
		timer = $Digestion
		$Digestion.start()
		print("Digesting (%d remaining), Timer = %.2f"%[len(plate), $Digestion.time_left])
		plate = await _digest_information(plate)
		await get_tree().process_frame

func _on_digestion_timeout() -> void:
	$CardBacks.hide()
	$Cards.show()
	$CuttingGuide.show()
	_save_front()
	timer = $SaveFront
	$SaveFront.start()
	

func _on_save_json_pressed() -> void:
	var export: Array = []
	
	for card in cards:
		var json_string: String = card.to_json_string()
		var json_dict: Dictionary = JSON.parse_string(json_string)
		export.append(json_dict)
		
	var file = FileAccess.open(save_directory.path_join("export.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(export, "    "))
	file.close()
		
func _process(delta: float) -> void:
	if timer.is_stopped():
		$MarginContainer/LoadingBar.custom_minimum_size.x = 0.0
		return
		
	$MarginContainer/LoadingBar.custom_minimum_size.x = get_viewport_rect().size.x * (1 - timer.time_left / timer.wait_time)

pass # Replace with function body.


func _on_save_front_timeout() -> void:
	_save_back()
	timer = $SaveBack
	$SaveBack.start()


func _on_save_back_timeout() -> void:
	current_page += 1
	if len(plate) == 0:
		print("Digestion finished. Yummy!")
	else:
		timer = $Digestion
		$Digestion.start()
		print("Digesting (%d remaining), Timer = %.2f"%[len(plate), $Digestion.time_left])
		plate = await _digest_information(plate)
