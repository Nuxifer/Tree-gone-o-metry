extends Node2D

# Path to the tree scene you want to instantiate
var tree_scene = preload ("res://scenes/tree.tscn")
var settlement_scene = preload("res://scenes/settlement.tscn")
@export var tile_size: float = 16.0

# Stores the trees placed on the grid
var placed_trees: Dictionary = {}
var occupied_tiles: Dictionary = {}

func _input(event: InputEvent):
	if Input.is_action_pressed("left_click") and event is InputEventMouseButton:
		if place_tree(event.global_position):
			process_turn()
func place_tree(global_position: Vector2) -> bool:
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	if occupied_tiles.has(grid_position):
		print("Tile at ", grid_position, " is already occupied. Cannot place tree.")
		return false

	var tree_instance = tree_scene.instantiate()
	tree_instance.set("settlement_scene", settlement_scene)
	add_child(tree_instance)
	tree_instance.global_position = tile_position

	occupied_tiles[grid_position] = tree_instance
	placed_trees[grid_position] = tree_instance  # Store the tree in the dictionary
	tree_instance.add_to_group("trees")

	print("Tree placed at: ", grid_position)
	return true  # Tree was successfully placed

func process_turn():
	# Remove entries from placed_trees if they no longer reference valid instances
	var keys_to_remove = []
	for grid_position in placed_trees.keys():
		var tree = placed_trees[grid_position]
		if tree == null:
			keys_to_remove.append(grid_position)
		else:
			tree.on_new_turn()

	# Remove invalid (null) tree entries from both dictionaries
	for grid_position in keys_to_remove:
		placed_trees.erase(grid_position)
		occupied_tiles.erase(grid_position)

	# Process turns for all settlements
	for settlement in get_tree().get_nodes_in_group("settlements"):
		settlement.on_new_turn()
