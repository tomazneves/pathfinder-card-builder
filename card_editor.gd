extends MarginContainer
var is_ready: bool = false

@onready var card_front: CardFront = $VBoxContainer/HBoxContainer/CardFront
@onready var card_back: CardBack = $VBoxContainer/HBoxContainer/CardBack
@onready var height_edit: TextEdit = $VBoxContainer/HBoxContainer2/ScrollContainer/VBoxContainer/HeightenedEdit

@export var json_string: String = "{}"

func set_card_info(json: String, aux: bool = true) -> void:
	json_string = json
	card_front.from_json_string(json_string)
	card_back.from_json_string(json_string)
	populate_grid_container($VBoxContainer/HBoxContainer2/ScrollContainer/VBoxContainer/GridContainer, json_string)
	$VBoxContainer/HBoxContainer2/ScrollContainer/VBoxContainer/DescriptionEdit.text = card_front.card_description
	
	var height_str = ""
	for key in card_front.card_heightened:
		height_str += key + ": " + card_front.card_heightened[key] + "\n"
	height_edit.text = height_str.strip_edges()
	
	if aux:
		$VBoxContainer/HBoxContainer2/JSONEdit.text = json_string
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_ready = true
	
	var height_edit = $VBoxContainer/HBoxContainer2/ScrollContainer/VBoxContainer/HeightenedEdit
	height_edit.text_changed.connect(func():
		var dict: Dictionary[String, String] = {}
		for line in height_edit.text.split("\n", false):
			var parts = line.split(":", true, 1) # Split by first colon
			if parts.size() == 2:
				dict[parts[0].strip_edges()] = parts[1].strip_edges()
		card_front.card_heightened = dict
		update_json()
	)
	
func _process(delta: float) -> void:
	#json_string = card_front.to_json_string()
	#$VBoxContainer/HBoxContainer2/TextEdit.text = json_string
	#card_back.from_json_string(json_string)
	pass

func update_json( ) -> void:
	json_string = card_front.to_json_string()
	card_back.from_json_string(json_string)
	$VBoxContainer/HBoxContainer2/JSONEdit.text = json_string

func get_card_info() -> String:
	return card_front.to_json_string()

func populate_grid_container(grid_container: GridContainer, json_str: String) -> void:
	# Parse the JSON string
	var parsed_data = JSON.parse_string(json_str)
	var data: Dictionary = {}
	if parsed_data is Dictionary:
		data = parsed_data
	else:
		push_error("Invalid JSON string. Falling back to default empty fields.")

	# Clear existing children to prevent duplicates if called multiple times
	for child in grid_container.get_children():
		child.queue_free()

	# Set container columns to 2 (Label | Input)
	grid_container.columns = 2

	# Helper lambda to add a row (Label + Control)
	var add_row = func(label_text: String, control: Control, node: Control = grid_container):
		var label = Label.new()
		label.text = label_text
		node.add_child(label)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_child(control)

	# Helper lambda for simple string fields (LineEdit)
	var add_string_field = func(prop_name: String, current_value: String, setter: Callable):
		var edit = LineEdit.new()
		edit.text = current_value
		edit.text_changed.connect(setter)
		add_row.call(prop_name.capitalize().replace("_", " "), edit)

	# Helper lambda for String Arrays (LineEdit with comma separation)
	var add_array_field = func(prop_name: String, current_value: Array[String], setter: Callable):
		var edit = LineEdit.new()
		edit.text = ", ".join(current_value)
		edit.text_changed.connect(func(t: String):
			var arr: Array[String] = []
			for s in t.split(",", false):
				arr.append(s.strip_edges())
			setter.call(arr)
		)
		add_row.call(prop_name.capitalize().replace("_", " "), edit)

	# --- 1. Vector2 Property ---
	var init_size_x: float = 710
	var init_size_y: float = 1093
	if data.has("card_size") and data["card_size"] is Dictionary:
		init_size_x = data["card_size"].get("x", 710)
		init_size_y = data["card_size"].get("y", 1093)
		
	var size_hbox = HBoxContainer.new()
	var spin_x = SpinBox.new()
	var spin_y = SpinBox.new()
	spin_x.max_value = 10000; spin_y.max_value = 10000
	spin_x.value = init_size_x; spin_y.value = init_size_y
	spin_x.prefix = "X:" ; spin_y.prefix = "Y:"
	spin_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_y.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_hbox.add_child(spin_x); size_hbox.add_child(spin_y)
	spin_x.value_changed.connect(func(v): card_front.card_size.x = v)
	spin_y.value_changed.connect(func(v): card_front.card_size.y = v)
	add_row.call("Size", size_hbox)

	# --- 2. Enum Properties ---
	var init_type = data.get("card_type", Globals.CardType.UTILITY) as int
	var type_opt = OptionButton.new()
	for key in GlobalClasses.CardType.keys():
		type_opt.add_item(key.capitalize().replace("_", " "))
	type_opt.selected = init_type
	type_opt.item_selected.connect(func(idx): card_front.card_type = GlobalClasses.CardType.values()[idx]; update_json())
	add_row.call("Type", type_opt)

	var init_cost = data.get("card_cost", Globals.ActivityCost.ONE_ACTION) as int
	var cost_opt = OptionButton.new()
	for key in GlobalClasses.ActivityCost.keys():
		cost_opt.add_item(key.capitalize().replace("_", " "))
	cost_opt.selected = init_cost
	cost_opt.item_selected.connect(func(idx): card_front.card_cost = GlobalClasses.ActivityCost.values()[idx]; update_json())
	add_row.call("Cost", cost_opt)

	# --- Extract and cast Array properties safely ---
	var init_traits: Array[String] = []
	if data.has("card_traits") and data["card_traits"] is Array:
		for item in data["card_traits"]: init_traits.append(str(item))

	var init_traditions: Array[String] = []
	if data.has("card_traditions") and data["card_traditions"] is Array:
		for item in data["card_traditions"]: init_traditions.append(str(item))

	# --- 3. String & Array Properties ---
	add_string_field.call("Name", data.get("card_name", "Activity"), func(t): card_front.card_name = t; update_json())
	add_string_field.call("Category", data.get("card_category", "Basic"), func(t): card_front.card_category = t; update_json())
	add_string_field.call("Materials", data.get("card_materials", ""), func(t): card_front.card_materials = t; update_json())
	add_array_field.call("Traits", init_traits, func(arr): card_front.card_traits = arr)
	add_array_field.call("Traditions", init_traditions, func(arr): card_front.card_traditions = arr)
	add_string_field.call("Range", data.get("card_range", ""), func(t): card_front.card_range = t; update_json())
	add_string_field.call("Frequency", data.get("card_frequency", ""), func(t): card_front.card_frequency = t; update_json())
	add_string_field.call("Targets", data.get("card_targets", ""), func(t): card_front.card_targets = t; update_json())
	add_string_field.call("Area", data.get("card_area", ""), func(t): card_front.card_area = t; update_json())
	add_string_field.call("Defense", data.get("card_defense", ""), func(t): card_front.card_defense = t; update_json())
	add_string_field.call("Duration", data.get("card_duration", ""), func(t): card_front.card_duration = t; update_json())
	add_string_field.call("Requirements", data.get("card_requirements", ""), func(t): card_front.card_requirements = t; update_json())
	add_string_field.call("Trigger", data.get("card_trigger", ""), func(t): card_front.card_trigger = t; update_json())
	add_string_field.call("Source", data.get("card_source", "Homebrewed"), func(t): card_front.card_source = t; update_json())

	# --- 4. Multiline String Property ---
	#var desc_edit = TextEdit.new()
	#desc_edit.text = data.get("card_description", "")
	#desc_edit.custom_minimum_size = Vector2(0, 150)
	#desc_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	#desc_edit.text_changed.connect(func(): card_front.card_description = desc_edit.text)
	#desc_edit.size_flags_vertical = TextEdit.SIZE_EXPAND_FILL
	#add_row.call("Description", desc_edit, grid_container.get_parent())
	



func _on_json_edit_text_changed() -> void:
	if $Timer.is_stopped():
		$Timer.start()

func _on_timer_timeout() -> void:
	var new_dict = JSON.parse_string($VBoxContainer/HBoxContainer2/JSONEdit.text)
	if new_dict == null:
		return
		
	json_string = $VBoxContainer/HBoxContainer2/JSONEdit.text
	set_card_info(json_string, false)


func _on_description_edit_text_changed() -> void:
	card_front.card_description = $VBoxContainer/HBoxContainer2/ScrollContainer/VBoxContainer/DescriptionEdit.text
	update_json()
