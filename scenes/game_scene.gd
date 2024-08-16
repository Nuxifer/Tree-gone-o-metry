extends TileMap

# Path to the tree scene you want to instantiate
var tree_scene = preload ("res://scenes/tree.tscn")
var tree_level_2_scene = preload ("res://scenes/tree_lvl2.tscn")

# Stores the trees placed on the grid
var placed_trees = {}

func _input(event: InputEvent):
	if Input.is_action_pressed("left_click"):
		place_tree(event.global_position)

func place_tree(mouse_position: Vector2):
	# Convert the global mouse position to tile coordinates
	var cell_position = local_to_map(to_local(mouse_position))
	if cell_position in placed_trees:
		print("A tree is already placed here!")
		return

	# Instantiate the tree scene
	var tree_instance = tree_scene.instantiate()
	add_child(tree_instance)

	# Convert tile coordinates back to the local position on the grid
	var cell_world_position = to_global(map_to_local(cell_position))
	tree_instance.global_position = cell_world_position

	# Store the tree instance in the dictionary with the cell position as the key
	placed_trees[cell_position] = tree_instance

	print("Tree placed at cell: ", cell_position)
	
	
	# Check for neighboring trees and replace with a level 2 tree if conditions are met
	check_and_replace_neighbors(cell_position)

func check_and_replace_neighbors(cell_position: Vector2i):
	# Define the relative positions of the neighboring cells
	var neighbors = [
		Vector2i(-1, 0), Vector2i(1, 0),  # Left and Right
		Vector2i(0, -1), Vector2i(0, 1)   # Up and Down
	]

	for i in range(0, neighbors.size(), 2):
		var neighbor_pos_1 = cell_position + neighbors[i]
		var neighbor_pos_2 = cell_position + neighbors[i + 1]

		if neighbor_pos_1 in placed_trees and neighbor_pos_2 in placed_trees:
			print("Neighboring trees found at: ", neighbor_pos_1, " and ", neighbor_pos_2)

			# Remove the three trees
			placed_trees[cell_position].queue_free()
			placed_trees[neighbor_pos_1].queue_free()
			placed_trees[neighbor_pos_2].queue_free()

			placed_trees.erase(cell_position)
			placed_trees.erase(neighbor_pos_1)
			placed_trees.erase(neighbor_pos_2)

			# Replace with a level 2 tree at the current position
			var level_2_tree_instance = tree_level_2_scene.instantiate()
			add_child(level_2_tree_instance)
			level_2_tree_instance.global_position = to_global(map_to_local(cell_position))

			# Store the level 2 tree in the dictionary
			placed_trees[cell_position] = level_2_tree_instance

			print("Level 2 tree placed at cell: ", cell_position)

			# Exit loop since the tree was replaced
			break
