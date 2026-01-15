extends Node2D

## When a card gets dragged here, discard the card and replace it with a water card in their hand

var card_scene = preload("res://card/card.tscn")

func _ready():
	$CardZone.card_placed.connect(_on_card_zone_card_placed)

func _on_card_zone_card_placed(_zone: Node2D, card: Node2D) -> void:
	# Get reference to game
	var game = get_parent()

	# Water cards just get destroyed
	if card.card == "Water":
		_destroy_card(game, card)
		return

	# Find an empty hand zone for the new water card
	var empty_zone = game._find_empty_hand_zone()
	if not empty_zone:
		# No room in hand, return the card to where it came from
		return

	# Clear the well zone
	$CardZone.current_card = null

	# Create a new water card
	var water_card = card_scene.instantiate()
	water_card.type = "ingredient"
	water_card.card = "Water"
	game.add_child(water_card)
	game.hand.append(water_card)
	water_card.drag_started.connect(game._on_card_drag_started)
	water_card.drag_ended.connect(game._on_card_drag_ended)

	# Place water in the empty hand zone
	empty_zone.place_card(water_card)

	# Remove the original card from hand array and destroy it
	_destroy_card(game, card)

func _destroy_card(game: Node2D, card: Node2D) -> void:
	$CardZone.current_card = null
	var card_index = game.hand.find(card)
	if card_index >= 0:
		game.hand.remove_at(card_index)
	card.queue_free()
