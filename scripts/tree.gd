extends Node2D

@export var tree_level: int = 1  # Initial level value for each tree
@export var max_tree_level: int = 15  # Max level a tree can reach
var tree_scene = preload ("res://scenes/tree.tscn")
var settlement_scene = preload("res://scenes/settlement.tscn")
@export var hut_spawn_chance: float = 0.10  # 4% chance to spawn a hut
@export var tree_spawn_chance: float = 0.15  # 15% chance to spawn a hut

@export var has_spawned_hut: bool = false



func on_new_turn():
	# This function is called when a new turn occurs (i.e., when a new tree is placed)
	if tree_level < max_tree_level:
		tree_level += 1
	%Sprite2D.frame = tree_level-1
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
	if randf() <= hut_spawn_chance:
		spawn_settlement_nearby()

func spawn_settlement_nearby():
	var attempts = 5  # Limit the number of attempts to find a valid position
	var placed = false

	while attempts > 0 and not placed:
		var offset = Vector2(randi_range(-3, 3), randi_range(-3, 3)) * 16  # Random offset within 5 tiles
		var potential_position = global_position + offset

		# Snap the potential position to the grid
		potential_position = potential_position.snapped(Vector2(16, 16))

		var grid_position = potential_position / 16.0

		# Check if the tile is not already occupied
		if not get_parent().occupied_tiles.has(grid_position):
			var settlement_instance = settlement_scene.instantiate()
			settlement_instance.global_position = potential_position
			get_parent().add_child(settlement_instance)
			get_parent().occupied_tiles[grid_position] = settlement_instance
			has_spawned_hut = true
			print("Settlement placed at: ", grid_position)

			placed = true

		attempts -= 1

	if not placed:
		print("Failed to place a settlement within 5 tiles.")
func try_to_spawn_tree():
	if randf() <= tree_spawn_chance:
		spawn_tree_nearby()

func spawn_tree_nearby():
	var attempts = 10  # Limit the number of attempts to find a valid position
	var placed = false

	while attempts > 0 and not placed:
		var offset = Vector2(randi_range(-3, 3), randi_range(-3, 3)) * 16  # Random offset within 3 tiles
		var potential_position = global_position + offset

		# Snap the potential position to the grid
		potential_position = potential_position.snapped(Vector2(16, 16))

		var grid_position = potential_position / 16.0

		# Check if the tile is not already occupied
		if not get_parent().occupied_tiles.has(grid_position):
			var tree_instance = tree_scene.instantiate()
			tree_instance.global_position = potential_position
			get_parent().add_child(tree_instance)

			# Correctly add the tree to the placed_trees dictionary using the grid position as the key
			get_parent().placed_trees[grid_position] = tree_instance
			get_parent().occupied_tiles[grid_position] = tree_instance

			tree_instance.add_to_group("trees")
			print("New tree placed at: ", grid_position)

			placed = true

		attempts -= 1

	if placed:
		pass
	else:
		print("Failed to place a tree within 3 tiles.")
