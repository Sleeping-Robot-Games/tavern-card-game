extends Node2D

func _ready():
	$CardZone.type = "bartop"

func has_space() -> bool:
	return not $CardZone.has_card()

func get_zone() -> Node2D:
	return $CardZone
