extends Node2D

# Path to the tree scene you want to instantiate
var tree_scene = preload ("res://scenes/tree.tscn")
var settlement_scene = preload("res://scenes/settlement.tscn")
@export var tile_size: float = 16.0
var tilemap : TileMap


# Rain system
@export var rain_intervals: Array[int] = []
@export var max_turns: int = 100  # Number of intervals in the rain cycle
@export var current_turn: int = 0  # Counter for the number of turns
@export var is_raining: bool = false  # Flag to check if it's raining

var turn_count: int = 0  # Total number of turns passed in the current rain cycle
var rain_cycle_index: int = 0  # Index to track the current position in the rain_intervals array

# Lake instantiation
var lake_scene = preload("res://scenes/lake.tscn")  # Reference to the lake scene
@export var number_of_lakes: int = 50  # Number of lakes to place
@export var placement_range: int = 1000  # Range for random placement

# Stores the trees placed on the grid



@export var camera: Camera2D  # Reference to the Camera2D node
@export var scroll_speed: float = 400.0  # Speed of the camera scroll in pixels per second

@onready var trees_objects = $trees_objects
@onready var lakes_objects = $lake_objects
@onready var settlements_objects = $settlements_objects

func _ready():
	place_lakes_randomly()
	tilemap = %TileMap
	# Ensure the camera node is assigned
	if camera == null:
		camera = $Camera2D
	camera.make_current()
	Global.spawn_tree.connect(place_tree)
	Global.spawn_settlement.connect(place_settlement)

	# Initialize the rain intervals array with 100 random numbers between 2 and 5
	rain_intervals.resize(max_turns)
	for i in range(max_turns):
		rain_intervals[i] = randi_range(2, 5)
	print("Rain intervals: ", rain_intervals)

func _process(delta: float):
	var move_vector = Vector2.ZERO

	# Check for input and set the move vector accordingly
	if Input.is_action_pressed("ui_left"):
		move_vector.x -= scroll_speed * delta
	if Input.is_action_pressed("ui_right"):
		move_vector.x += scroll_speed * delta
	if Input.is_action_pressed("ui_up"):
		move_vector.y -= scroll_speed * delta
	if Input.is_action_pressed("ui_down"):
		move_vector.y += scroll_speed * delta

	# Move the camera if there is any movement
	if move_vector != Vector2.ZERO:
		camera.position += move_vector
		
func _input(event: InputEvent):
	if Input.is_action_pressed("left_click") and event is InputEventMouseButton:
		# Convert the mouse position to world coordinates
		var world_position = camera.get_global_mouse_position()

		# Try to place a tree at the calculated position
		if place_tree(world_position):
			process_turn()

func place_tree(global_position: Vector2) -> bool:
	# Convert the global position to the nearest grid position
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	if Global.occupied_tiles.has(grid_position):
		print("Tile at ", grid_position, " is already occupied. Cannot place tree.")
		return false

	var tree_instance = tree_scene.instantiate()
	trees_objects.add_child(tree_instance)
	tree_instance.global_position = tile_position

	Global.occupied_tiles[grid_position] = tree_instance
	Global.placed_trees[grid_position] = tree_instance  # Store the tree in the dictionary
	tree_instance.add_to_group("trees")

	#print("Tree placed at: ", grid_position)
	return true  # Tree was successfully placed

func place_settlement(global_position: Vector2) -> bool:
	# Convert the global position to the nearest grid position
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	# Check if the grid position is already occupied
	if Global.occupied_tiles.has(grid_position):
		#print("Tile at ", grid_position, " is already occupied. Cannot place settlement.")
		return false

	# Instantiate the settlement
	var settlement_instance = settlement_scene.instantiate()
	
	# Add the settlement to the settlements group or scene tree
	settlements_objects.add_child(settlement_instance)
	settlement_instance.global_position = tile_position

	# Mark the tile as occupied in the occupied_tiles dictionary
	Global.occupied_tiles[grid_position] = settlement_instance

	# If you have a separate dictionary for settlements, use it
	Global.placed_settlements[grid_position] = settlement_instance  # Store the settlement in the correct dictionary

	settlement_instance.add_to_group("settlements")

	#print("Settlement placed at: ", grid_position)
	return true  # Settlement was successfully placed

func place_lakes_randomly():
	for i in range(number_of_lakes):
		var random_x = randi_range(-placement_range, placement_range)
		var random_y = randi_range(-placement_range, placement_range)
		var random_position = Vector2(random_x, random_y)
		
		place_lake(random_position)
func place_lake(global_position: Vector2):
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	# Check if the tile is already occupied
	if not Global.occupied_tiles.has(grid_position):
		var lake_instance = lake_scene.instantiate()
		lakes_objects.add_child(lake_instance)
		lake_instance.global_position = tile_position
		lake_instance.add_to_group("lakes")

		# Add the lake to the occupied tiles dictionary
		Global.occupied_tiles[grid_position] = lake_instance

		#print("Lake placed at: ", lake_instance.global_position)
	else:
		print("Tile at ", grid_position, " is already occupied. Skipping lake placement.")


func process_turn():
	# Increment the turn counter
	turn_count += 1

	# Check if the current turn count matches the next rain interval
	if turn_count == rain_intervals[rain_cycle_index]:
		if is_raining:
			print("Rain has stopped.")
			is_raining = false
		else:
			print("It's starting to rain!")
			is_raining = true

		# Move to the next interval and reset the turn count
		rain_cycle_index = (rain_cycle_index + 1) % max_turns
		turn_count = 0

	# Apply effects based on whether it is raining
	if is_raining:
		apply_rain_effects()

	# Normal tree growth if it's not raining
	apply_normal_growth()
	
	
	# Remove entries from placed_trees if they no longer reference valid instances
	var keys_to_remove = []
	for grid_position in Global.placed_trees.keys():
		var tree = Global.placed_trees[grid_position]
		if tree == null:
			keys_to_remove.append(grid_position)
		else:
			tree.on_new_turn()

	# Remove invalid (null) tree entries from both dictionaries
	for grid_position in keys_to_remove:
		Global.placed_trees.erase(grid_position)
		Global.occupied_tiles.erase(grid_position)

	# Process turns for all settlements
	for settlement in get_tree().get_nodes_in_group("settlements"):
		settlement.on_new_turn()

func apply_rain_effects():
	# Double the growth rate of trees during rain
	for tree in get_tree().get_nodes_in_group("trees"):
		tree.growth_factor = 2  
	
	
	# Refill all lakes to max level during rain
	for lake in get_tree().get_nodes_in_group("lakes"):
		lake.on_new_turn(is_raining)

func apply_normal_growth():
	# Normal growth rate for trees (increment by 1)
	for tree in get_tree().get_nodes_in_group("trees"):
		tree.growth_factor = 1  
		


