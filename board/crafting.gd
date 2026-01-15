extends Node2D

signal crafting_started(recipe: String)
signal crafting_completed(recipe: String)

var card_scene = preload("res://card/card.tscn")

var recipes = {
	"Bread": { "ingredients": ["Water", "Grain"], "time": 2.0, "type": "meal" },
	"Ale": { "ingredients": ["Water", "Grain", "Hops"], "time": 3.0, "type": "meal" },
	"Mead": { "ingredients": ["Water", "Honey"], "time": 4.0, "type": "meal" },
	"Meal": { "ingredients": ["Bread", "Ale"], "time": 0.0, "type": "meal" }
}

var is_crafting: bool = false
var current_recipe: String = ""
var craft_time: float = 0.0
var craft_progress: float = 0.0

@onready var game = get_parent()
@onready var zones = [$CardZone, $CardZone2, $CardZone3]

func _ready():
	for zone in zones:
		zone.card_placed.connect(_on_card_placed)
		zone.card_removed.connect(_on_card_removed)
	$ProgressBar.value = 0
	$ProgressBar.visible = false

func _process(delta: float) -> void:
	if is_crafting:
		craft_progress += delta
		$ProgressBar.value = (craft_progress / craft_time) * 100.0
		if craft_progress >= craft_time:
			_complete_craft()

func _on_card_placed(_zone: Node2D, _card: Node2D) -> void:
	_check_recipes()

func _on_card_removed(_zone: Node2D, _card: Node2D) -> void:
	pass

func _get_current_ingredients() -> Array[String]:
	var ingredients: Array[String] = []
	for zone in zones:
		if zone.has_card():
			ingredients.append(zone.get_card().card)
	return ingredients

func _check_recipes() -> void:
	var current_ingredients = _get_current_ingredients()
	if current_ingredients.is_empty():
		return

	# Check if bar top has space
	var bar_top = game.get_node_or_null("BarTop")
	if not bar_top or not bar_top.has_space():
		return

	# Check each recipe
	for recipe_name in recipes:
		var recipe = recipes[recipe_name]
		var recipe_ingredients = recipe["ingredients"].duplicate()

		# Check if we have exactly the right ingredients
		if current_ingredients.size() != recipe_ingredients.size():
			continue

		var is_match = true
		var temp_ingredients = current_ingredients.duplicate()
		for ingredient in recipe_ingredients:
			var idx = temp_ingredients.find(ingredient)
			if idx == -1:
				is_match = false
				break
			temp_ingredients.remove_at(idx)

		if is_match:
			# If already crafting same recipe, do nothing
			if is_crafting and current_recipe == recipe_name:
				return
			# Start or restart crafting with this recipe
			_start_craft(recipe_name, recipe["time"])
			return

func _start_craft(recipe_name: String, time: float) -> void:
	is_crafting = true
	current_recipe = recipe_name
	craft_time = time
	craft_progress = 0.0

	if craft_time > 0:
		$ProgressBar.visible = true
		$ProgressBar.value = 0
		crafting_started.emit(recipe_name)
	else:
		# Instant craft (like Meal)
		_complete_craft()

func _complete_craft() -> void:
	is_crafting = false
	$ProgressBar.visible = false
	$ProgressBar.value = 0

	var bar_top = game.get_node_or_null("BarTop")
	if not bar_top or not bar_top.has_space():
		# Re-enable cards if bar top is full
		_enable_craft_cards()
		return

	# Destroy ingredient cards
	for zone in zones:
		if zone.has_card():
			var card = zone.get_card()
			zone.current_card = null
			var card_index = game.hand.find(card)
			if card_index >= 0:
				game.hand.remove_at(card_index)
			card.queue_free()

	# Create the result card on bar top
	var result_card = card_scene.instantiate()
	result_card.type = "meal"
	result_card.card = current_recipe
	game.add_child(result_card)

	bar_top.get_zone().place_card(result_card)

	crafting_completed.emit(current_recipe)
	current_recipe = ""

func _enable_craft_cards() -> void:
	for zone in zones:
		if zone.has_card():
			var card = zone.get_card()
			card.set_process_input(true)
			if card.has_node("Area2D"):
				card.get_node("Area2D").input_pickable = true
