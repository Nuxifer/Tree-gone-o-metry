extends Area2D

@export var tree_level: int = 1  # Initial level value for each tree
@export var max_tree_level: int = 15  # Max level a tree can reach
var tree_scene = preload ("res://scenes/tree.tscn")
var settlement_scene = preload("res://scenes/settlement.tscn")


@export var has_spawned_hut: bool = false

var growth_factor : int = 1


func on_new_turn():
	# This function is called when a new turn occurs (i.e., when a new tree is placed)
	
	
	if tree_level < max_tree_level:
		tree_level += growth_factor
	absorb_levels_from_lake()
	
	%Sprite2D.frame = tree_level-2
		#print("Tree level increased to ", tree_level)
	
	

	if tree_level >= 3 and not has_spawned_hut:
		try_to_spawn_hut()
	
	if tree_level >= 5:
		try_to_spawn_tree()
	
	if tree_level >= 10:
		try_to_spawn_tree()
		try_to_spawn_tree()
	
	
	if tree_level >= 15:
		try_to_spawn_tree()
		try_to_spawn_tree()
		try_to_spawn_tree()
	

func try_to_spawn_hut():
	if randf() <= Global.hut_spawn_chance:
		spawn_settlement_nearby()
		
func absorb_levels_from_lake():
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("lakes"):
			var lake = area
			var absorbed_level = lake.consume_levels(1)  # Trees absorb 1 level per turn
			tree_level += absorbed_level
			#print("Tree at ", global_position, " absorbed ", absorbed_level, " levels from lake.")
func spawn_settlement_nearby():
	
	var attempts = 5  # Limit the number of attempts to find a valid position
	var placed = false

	while attempts > 0 and not placed:
		# Generate a random offset within 3 tiles in each direction
		var offset = Vector2(randi_range(-3, 3), randi_range(-3, 3)) * 16
		var potential_position = global_position + offset

		# Snap the potential position to the grid
		potential_position = potential_position.snapped(Vector2(16, 16))
		var grid_position = Vector2i(potential_position / 16.0)

		# Check if the tile is not already occupied
		if not Global.occupied_tiles.has(grid_position):
			# Emit the signal to place the settlement if the tile is free
			Global.spawn_settlement.emit(potential_position)

			# Mark the position as occupied
			Global.occupied_tiles[grid_position] = true

			placed = true  # Mark as placed to stop further attempts
			#print("Settlement placed at: ", grid_position)
		else:
			print("Tile at ", grid_position, " is already occupied.")

		attempts -= 1  # Decrease the attempt count after each try

	if not placed:
		print("Failed to place a settlement within 5 tiles.")
		
func try_to_spawn_tree():
	if randf() <= Global.tree_spawn_chance:
		spawn_tree_nearby()

func spawn_tree_nearby():
	var attempts = 10  # Limit the number of attempts to find a valid position
	var placed = false

	while attempts > 0 and not placed:
		var offset = Vector2(randi_range(-3, 3), randi_range(-3, 3)) * 16  # Random offset within 3 tiles
		var potential_position = global_position + offset
		Global.spawn_tree.emit(potential_position)
		placed = true
#
		## Snap the potential position to the grid
		#potential_position = potential_position.snapped(Vector2(16, 16))
#
		#var grid_position = potential_position / 16.0
#
		## Check if the tile is not already occupied
		#if not Global.occupied_tiles.has(grid_position):
			#var tree_instance = tree_scene.instantiate()
			#tree_instance.global_position = potential_position
			#get_node("game_scene/trees_objects").add_child(tree_instance)
#
			## Correctly add the tree to the placed_trees dictionary using the grid position as the key
			#get_parent().placed_trees[grid_position] = tree_instance
			#Global.occupied_tiles[grid_position] = tree_instance
#
			#tree_instance.add_to_group("trees")
			##print("New tree placed at: ", grid_position)
#

		attempts -= 1

	if placed:
		pass
	else:
		print("Failed to place a tree within 3 tiles.")
