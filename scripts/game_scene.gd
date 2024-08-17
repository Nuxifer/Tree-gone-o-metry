extends Node2D

# Path to the tree scene you want to instantiate
var tree_scene = preload ("res://scenes/tree.tscn")
@export var tile_size: float = 16.0  # Updated to 16x16 tiles

# Dictionary to store occupied tile positions
var occupied_tiles = {}


# Global score and score range counters
var global_score: int = 0
var less_than_5: int = 0
var between_5_and_10: int = 0
var between_10_and_20: int = 0
var more_than_20: int = 0

# Stores all placed trees
var placed_trees = []

func _input(event: InputEvent):
	if Input.is_action_pressed("left_click") and event is InputEventMouseButton:
		place_tree(event.global_position)

func place_tree(global_position: Vector2):
	# Snap the global position to the grid to get the tile position
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))

	# Convert the tile position to a grid coordinate
	var grid_position = tile_position / tile_size

	# Check if the tile is already occupied
	if occupied_tiles.has(grid_position):
		print("Tile at ", grid_position, " is already occupied. Cannot place tree.")
		return

	# Create a new tree instance
	var tree_instance = tree_scene.instantiate()
	add_child(tree_instance)

	# Set tree's position to the snapped tile position
	tree_instance.global_position = tile_position

	# Add the tree to the occupied tiles dictionary
	occupied_tiles[grid_position] = tree_instance

	# Add the tree to the list of placed trees
	placed_trees.append(tree_instance)

	# Add tree to "trees" group for detection purposes
	tree_instance.add_to_group("trees")

	# Update scores
	calculate_tree_score(tree_instance)
	update_global_score()

	print("Tree placed at: ", grid_position, " with initial score: ", tree_instance.get("score"))

func calculate_tree_score(tree_instance: Node2D):
	# Reset score
	var score = 1  # Start with 1 for the tree itself

	# Get the tree's Area2D node (the hitbox for detecting neighbors)
	var hitbox = tree_instance.get_node("Area2D")
	
	# Check that the hitbox exists
	if hitbox == null:
		print("Error: Tree instance is missing an Area2D node")
		return

	# Check for other trees within the hitbox area
	for other_tree in placed_trees:
		if other_tree != tree_instance:
			# Get the other tree's Area2D node
			var other_hitbox = other_tree.get_node("Area2D")
			
			# Check that the other tree's hitbox exists
			if other_hitbox == null:
				print("Warning: Another tree is missing an Area2D node")
				continue

			# Check if the hitboxes overlap
			if hitbox.overlaps_area(other_hitbox):
				score += 1

	# Store the score in the tree instance
	tree_instance.set("score", score)
func update_global_score():
	# Reset global score and counters
	global_score = 0
	less_than_5 = 0
	between_5_and_10 = 0
	between_10_and_20 = 0
	more_than_20 = 0

	# Calculate the global score and update the score range counters
	for tree in placed_trees:
		var score = tree.get("score")
		global_score += score
		
		if score < 5:
			less_than_5 += 1
		elif score >= 5 and score < 10:
			between_5_and_10 += 1
		elif score >= 10 and score < 20:
			between_10_and_20 += 1
		elif score >= 20:
			more_than_20 += 1
#
	#%global_score.set_text("Global Score: ", global_score)
	#%less_than_5.set_text("Trees with score < 5: ", less_than_5)
	#%"5_to_10".set_text("Trees with score 5-10: ", between_5_and_10)
	#%"10_to_20".set_text("Trees with score 10-20: ", between_10_and_20)
	#%"more than 20".set_text("Trees with score > 20: ", more_than_20)
