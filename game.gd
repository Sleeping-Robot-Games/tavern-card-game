extends Node2D

var hand: Array[Node2D] = []
var dragging_card: Node2D = null
var valid_drop_zones: Array[Node2D] = []
var patron_zones: Array[Node2D] = []

@export var card_spacing: float = 50.0
@export var hand_offset: Vector2 = Vector2(100, 0)

func _ready():
	$IngredientDeck.card_drawn.connect(_on_deck_card_drawn)
	$PatronDeck.card_drawn.connect(_on_patron_deck_card_drawn)
	_collect_drop_zones()
	_collect_patron_zones()

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

func _collect_patron_zones() -> void:
	for child in $PatronZone.get_children():
		if child is Sprite2D and child.has_method("place_card"):
			child.type = "patron"
			patron_zones.append(child)

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

func _on_patron_deck_card_drawn(card_instance: Node2D) -> void:
	var target_zone = _find_empty_patron_zone()
	if not target_zone:
		# No available patron zone, card cannot be placed
		card_instance.queue_free()
		return

	add_child(card_instance)
	target_zone.place_card(card_instance)

	# Connect timeout signal
	card_instance.patron_timeout.connect(_on_patron_timeout)

	# Start the patience timer
	card_instance.start_patience_timer()

func _find_empty_patron_zone() -> Node2D:
	for zone in patron_zones:
		if not zone.has_card():
			return zone
	return null

func _on_patron_timeout(card: Node2D) -> void:
	_handle_patron_timeout(card)

func _handle_patron_timeout(card: Node2D) -> void:
	# TODO: Implement patron timeout consequences (reputation loss, etc.)
	print("GAME: Patron ", card.card, " left unhappy! They wanted: ", card.patron_wants)
	
func clean_meal_and_patron(patron_zone, patron_card, meal_card):
	# Remove patron from zone
	patron_zone.remove_card()
	patron_card.queue_free()

	# Remove meal card
	if meal_card.current_zone:
		meal_card.current_zone.remove_card()
	meal_card.queue_free()

func _serve_patron(meal_card: Node2D, patron_zone: Node2D) -> void:
	var patron_card = patron_zone.get_card()

	# Check if the meal matches what the patron wants
	if meal_card.card == patron_card.patron_wants:
		# TODO: Implement successful serve (add coins, reputation, etc.)
		print("GAME: Served ", patron_card.card, " with ", meal_card.card, "! Earned ", patron_card.patron_pays, " coins.")
		patron_card.stop_patience_timer()

		clean_meal_and_patron(patron_zone, patron_card, meal_card)
	else:
		# Wrong meal
		print("GAME: Patron wanted ", patron_card.patron_wants, " but was offered ", meal_card.card)
		clean_meal_and_patron(patron_zone, patron_card, meal_card)

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
		# Special handling for meal cards dropped on patron zones
		if card.type == "meal" and target_zone.type == "patron":
			if target_zone.has_card():
				_serve_patron(card, target_zone)
			else:
				# No patron in this zone, return meal to origin
				_return_card_to_origin(card)
		elif target_zone.has_card():
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
	# Also check patron zones for meal cards
	for zone in patron_zones:
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
