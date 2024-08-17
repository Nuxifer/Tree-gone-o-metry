extends Node2D

@export var tree_size: float = 16.0  # Assuming a 32x32 tile size or similar

# Property to store the tree's score
var score: int = 1  # Start with 1 for the tree itself



func _on_area_2d_area_entered(area):
	# Check if the other area is another tree
	if area.get_parent().is_in_group("trees"):
		score += 1
		print("Tree at ", global_position, " increased score to: ", score)
