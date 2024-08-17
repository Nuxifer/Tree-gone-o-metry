extends Area2D


@export var max_level: int = 50  # Max level of the lake
@export var current_level: int = 50  # Starting level of the lake

func consume_levels(amount: int) -> int:
	# If the lake doesn't have enough levels, it will only provide what's available
	var consumed = min(amount, current_level)
	current_level -= consumed
	change_graphics()
	return consumed

func refill_levels():
	current_level = max_level

func change_graphics():
	if current_level == 0:
		%Sprite2D.frame = 1
	else:
		%Sprite2D.frame = 0
