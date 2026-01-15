@tool
extends Node2D

signal drag_started(card: Node2D)
signal drag_ended(card: Node2D)
signal patron_timeout(card: Node2D)

@export_enum("ingredient", "patron", "upgrade", "well", "meal") var type = ""
@export var card: String = "":
	set(value):
		card = value
		if Engine.is_editor_hint():
			load_sprite()

# Patron-specific properties
var patron_wants: String = ""
var patron_pays: int = 0
var patron_patience: float = 0.0
var patience_remaining: float = 0.0
var patience_timer_active: bool = false

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
	if type == 'patron':
		$ProgressBar.show()
		$PayLabel.show()
		$WantLabel.show()
		_setup_patron_display()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Engine.is_editor_hint():
		return
	# Patron cards are not draggable
	if type == "patron":
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

func _setup_patron_display() -> void:
	if not is_node_ready():
		await ready
	$PayLabel.text = str(patron_pays) + " coins"
	$WantLabel.text = patron_wants
	$ProgressBar.max_value = patron_patience
	$ProgressBar.value = patron_patience
	patience_remaining = patron_patience

func start_patience_timer() -> void:
	patience_remaining = patron_patience
	patience_timer_active = true

func stop_patience_timer() -> void:
	patience_timer_active = false

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if patience_timer_active and type == "patron":
		patience_remaining -= delta
		$ProgressBar.value = patience_remaining
		if patience_remaining <= 0:
			patience_timer_active = false
			_on_patron_timeout()

func _on_patron_timeout() -> void:
	print("Patron timed out! Customer wanted: ", patron_wants, " but wasn't served in time.")
	patron_timeout.emit(self)
