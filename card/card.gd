@tool
extends Node2D

@export_enum("ingredient", "patron", "upgrade", "well", "meal") var type = ""
@export var card: String = "":
	set(value):
		card = value
		if Engine.is_editor_hint():
			load_sprite()

func _ready():
	if card:
		load_sprite()
		
func load_sprite():
	var sprite_path = "res://assets/" + card.capitalize() + ".png"
	if ResourceLoader.exists(sprite_path):
		$Sprite2D.texture = load(sprite_path)
