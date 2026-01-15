extends Node2D

var hand: Array[Node2D] = []

@export var card_spacing: float = 50.0
@export var hand_offset: Vector2 = Vector2(100, 0)

func _ready():
	$Deck.card_drawn.connect(_on_deck_card_drawn)

func _on_deck_card_drawn(card_instance: Node2D) -> void:
	add_child(card_instance)
	var hand_position = $Deck.global_position + hand_offset + Vector2(hand.size() * card_spacing, 0)
	card_instance.global_position = hand_position
	hand.append(card_instance)
	print(hand)

func is_hand_full():
	return hand.size() >= 6
