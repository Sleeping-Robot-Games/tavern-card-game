@tool
extends Node2D

signal drag_started(card: Node2D)
signal drag_ended(card: Node2D)

@export_enum("ingredient", "patron", "upgrade", "well", "meal") var type = ""
@export var card: String = "":
	set(value):
		card = value
		if Engine.is_editor_hint():
			load_sprite()

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var current_zone: Node2D = null

func _ready():
	if card:
		load_sprite()
	if not Engine.is_editor_hint():
		$Area2D.input_event.connect(_on_area_2d_input_event)

func load_sprite():
	var sprite_path = "res://assets/" + card.capitalize() + ".png"
	if ResourceLoader.exists(sprite_path):
		$Sprite2D.texture = load(sprite_path)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			get_viewport().set_input_as_handled()
			start_drag(event.global_position)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if is_dragging:
		if event is InputEventMouseMotion:
			global_position = event.global_position - drag_offset
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			end_drag()

func start_drag(mouse_pos: Vector2) -> void:
	is_dragging = true
	original_position = global_position
	drag_offset = mouse_pos - global_position
	z_index = 100
	drag_started.emit(self)

func end_drag() -> void:
	is_dragging = false
	z_index = 0
	drag_ended.emit(self)

func snap_to_zone(zone: Node2D) -> void:
	current_zone = zone
	global_position = zone.global_position

func return_to_original() -> void:
	global_position = original_position
