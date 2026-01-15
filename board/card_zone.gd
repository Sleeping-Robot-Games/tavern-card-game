@tool
extends Sprite2D

signal card_placed(zone: Node2D, card: Node2D)
signal card_removed(zone: Node2D, card: Node2D)

@export_enum("blank", "well", "hand", "crafting", "bartop", "patron") var type = "blank":
	set(value):
		type = value
		if Engine.is_editor_hint():
			load_sprite()

var current_card: Node2D = null
var is_hovered_by_card: bool = false
var hovering_card: Node2D = null

func _ready():
	load_sprite()

func load_sprite():
	if type == "well":
		var sprite_path = "res://assets/Well.png"
		if ResourceLoader.exists(sprite_path):
			texture = load(sprite_path)

func _on_area_2d_area_entered(area: Area2D) -> void:
	var card = area.get_parent()
	if card.get("is_dragging") == true:
		is_hovered_by_card = true
		hovering_card = card

func _on_area_2d_area_exited(area: Area2D) -> void:
	var card = area.get_parent()
	if hovering_card == card:
		is_hovered_by_card = false
		hovering_card = null

func accepts_card(card: Node2D) -> bool:
	if card.type == "ingredient":
		return type in ["hand", "crafting", "well"]
	elif card.type == "patron":
		return type == "patron"
	elif card.type == "meal":
		return type in ["patron", "crafting"]
	return false

func place_card(card: Node2D) -> void:
	current_card = card
	card.current_zone = self
	card.snap_to_zone(self)
	card_placed.emit(self, card)

func remove_card() -> Node2D:
	var card = current_card
	if current_card:
		current_card.current_zone = null
		current_card = null
		card_removed.emit(self, card)
	return card

func has_card() -> bool:
	return current_card != null

func get_card() -> Node2D:
	return current_card
