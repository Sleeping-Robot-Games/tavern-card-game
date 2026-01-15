extends Node2D

var hand: Array[Node2D] = []
var dragging_card: Node2D = null
var valid_drop_zones: Array[Node2D] = []

@export var card_spacing: float = 50.0
@export var hand_offset: Vector2 = Vector2(100, 0)

func _ready():
	$IngredientDeck.card_drawn.connect(_on_deck_card_drawn)
	_collect_drop_zones()

func _collect_drop_zones() -> void:
	# Gather hand zones
	for child in $Hand.get_children():
		if child is Sprite2D and child.has_method("place_card"):
			child.type = "hand"
			valid_drop_zones.append(child)
	# Gather crafting zones
	for child in $CraftZone.get_children():
		if child is Sprite2D and child.has_method("place_card"):
			child.type = "crafting"
			valid_drop_zones.append(child)
	# Gather well zone
	var well_zone = $Well.get_node_or_null("CardZone")
	if well_zone:
		valid_drop_zones.append(well_zone)

func _on_deck_card_drawn(card_instance: Node2D) -> void:
	add_child(card_instance)

	# Find first empty hand zone
	var target_zone = _find_empty_hand_zone()
	if target_zone:
		target_zone.place_card(card_instance)
	else:
		# Fallback positioning if no zone available
		var hand_position = $IngredientDeck.global_position + hand_offset + Vector2(hand.size() * card_spacing, 0)
		card_instance.global_position = hand_position

	hand.append(card_instance)

	# Connect drag signals
	card_instance.drag_started.connect(_on_card_drag_started)
	card_instance.drag_ended.connect(_on_card_drag_ended)

func _find_empty_hand_zone() -> Node2D:
	for child in $Hand.get_children():
		if child is Sprite2D and child.has_method("has_card"):
			if not child.has_card():
				return child
	return null

func _on_card_drag_started(card: Node2D) -> void:
	dragging_card = card
	# Temporarily clear the zone's card reference while dragging
	if card.current_zone:
		card.current_zone.current_card = null

func _on_card_drag_ended(card: Node2D) -> void:
	if not dragging_card:
		return

	var target_zone = _find_hovered_zone()

	if target_zone and target_zone.accepts_card(card):
		if target_zone.has_card():
			_swap_cards(card, target_zone)
		else:
			_place_card_in_zone(card, target_zone)
	else:
		_return_card_to_origin(card)

	dragging_card = null

func _find_hovered_zone() -> Node2D:
	for zone in valid_drop_zones:
		if zone.is_hovered_by_card and zone.hovering_card == dragging_card:
			return zone
	return null

func _swap_cards(incoming_card: Node2D, target_zone: Node2D) -> void:
	var existing_card = target_zone.get_card()
	var source_zone = incoming_card.current_zone

	# Remove existing card from target zone
	target_zone.remove_card()

	# Place incoming card in target zone
	target_zone.place_card(incoming_card)

	# Place existing card in source zone if it exists
	if source_zone:
		source_zone.place_card(existing_card)
	else:
		existing_card.global_position = incoming_card.original_position

func _place_card_in_zone(card: Node2D, zone: Node2D) -> void:
	# Clear old zone reference
	if card.current_zone:
		card.current_zone.current_card = null
	zone.place_card(card)

func _return_card_to_origin(card: Node2D) -> void:
	if card.current_zone:
		card.current_zone.place_card(card)
	else:
		card.return_to_original()

func is_hand_full() -> bool:
	var filled_zones = 0
	for child in $Hand.get_children():
		if child is Sprite2D and child.has_method("has_card"):
			if child.has_card():
				filled_zones += 1
	return filled_zones >= 6

func get_hand_cards() -> Array[Node2D]:
	var cards: Array[Node2D] = []
	for child in $Hand.get_children():
		if child is Sprite2D and child.has_method("get_card"):
			var card = child.get_card()
			if card:
				cards.append(card)
	return cards
