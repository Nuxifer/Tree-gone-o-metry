extends Area2D


@export var max_level: int = 50  # Max level of the lake
@export var current_level: int = 50  # Starting level of the lake
var tree_scene = preload("res://scenes/tree.tscn") # Reference to the tree scene to instantiate
@export var spawn_chance: float = 0.1  # Chance to spawn a tree during rain (10%)

var tile_size: float = 16.0  # Size of each tile (for snapping and placement)
var placement_range: int = 5  # Range within which to spawn trees (in tiles)


func on_new_turn(is_raining: bool):
	if is_raining:
		refill_levels()
		try_to_spawn_tree()
		
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

func try_to_spawn_tree():
	# Roll for a chance to spawn a tree
	if randf() <= spawn_chance:
		var spawn_position = find_valid_spawn_position()
		if spawn_position != Vector2(-1, -1):
			Global.spawn_tree.emit(spawn_position)
		else:
			print("No valid position found for spawning a tree.")

func find_valid_spawn_position() -> Vector2:
	var attempt_count = 0
	var max_attempts = 10  # Limit the number of attempts to find a valid position

	while attempt_count < max_attempts:
		# Generate a random position within 5 tiles of the lake's position
		var offset_x = randi_range(-placement_range, placement_range) * tile_size
		var offset_y = randi_range(-placement_range, placement_range) * tile_size
		var potential_position = global_position + Vector2(offset_x, offset_y)
		
		# Snap to the grid
		potential_position = potential_position.snapped(Vector2(tile_size, tile_size))
		var grid_position = Vector2i(potential_position / tile_size)

 # Check if the position is not occupied using the global occupied_tiles
		if not Global.occupied_tiles.has(grid_position):
			return potential_position

		attempt_count += 1
	
	return Vector2(-1,-1)  # Return null if no valid position was found
#
