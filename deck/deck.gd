@tool
extends Node2D

signal card_drawn(card_instance: Node2D)

@export_enum("ingredient", "patron", "upgrade", "meal") var type = "ingredient":
	set(value):
		type = value
		if Engine.is_editor_hint():
			load_sprite()
			update_label()

@onready var game = get_parent()

var cards: Array[String] = []
var is_hovered: bool = false
var card_scene = preload("res://card/card.tscn")

func _ready():
	if type:
		load_sprite()
	if not Engine.is_editor_hint():
		_initialize_deck()

func _initialize_deck():
	if type == "ingredient":
		cards.clear()
		for i in range(8):
			cards.append("Water")
		for i in range(6):
			cards.append("Grain")
		for i in range(4):
			cards.append("Hops")
		for i in range(2):
			cards.append("Honey")
			
		randomize()
		cards.shuffle()

func load_sprite():
	var sprite_path = "res://assets/" + type.to_lower() + "-cardback.png"
	if ResourceLoader.exists(sprite_path):
		$Sprite2D.texture = load(sprite_path)

func update_label():
	match type:
		'ingredient':
			$Label.text = "Ingredients"
		'patron':
			$Label.text = "Patrons"
		'upgrade':
			$Label.text = "Upgrades"

func draw_card() -> Node2D:
	if game.is_hand_full() or cards.is_empty():
		return null
	var card_value = cards.pop_back()
	var card_instance = card_scene.instantiate()
	card_instance.type = type
	card_instance.card = card_value
	return card_instance

func _on_area_2d_mouse_entered() -> void:
	is_hovered = true

func _on_area_2d_mouse_exited() -> void:
	is_hovered = false

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_hovered and not cards.is_empty():
			var card_instance = draw_card()
			if card_instance:
				card_drawn.emit(card_instance)
