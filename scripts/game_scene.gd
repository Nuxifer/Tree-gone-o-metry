extends Node2D

# Path to the tree scene you want to instantiate
var tree_scene = preload ("res://scenes/tree.tscn")
var settlement_scene = preload("res://scenes/settlement.tscn")
var mountain_scene = preload ("res://scenes/mountain.tscn")
@export var tile_size: float = 24.0
var tilemap : TileMap

# Load the ObjectPool script
@onready var ObjectPool = preload("res://scenes/object_pool.tscn")
@onready var object_pool = ObjectPool.instantiate()

# Rain system
@export var rain_intervals: Array[int] = []
@export var max_turns: int = 100  # Number of intervals in the rain cycle
@export var current_turn: int = 0  # Counter for the number of turns
@export var is_raining: bool = false  # Flag to check if it's raining

var turn_count: int = 0  # Total number of turns passed in the current rain cycle
var rain_cycle_index: int = 0  # Index to track the current position in the rain_intervals array

# Lake instantiation
var lake_scene = preload("res://scenes/lake.tscn")  # Reference to the lake scene
@export var number_of_lakes: int = 1000  # Number of lakes to place
@export var placement_range: int = 5000  # Range for random placement
@export var number_of_mountains : int = 750

var tree_index = 0
var settlement_index = 0


@export var camera: Camera2D  # Reference to the Camera2D node
@export var scroll_speed: float = 400.0  # Speed of the camera scroll in pixels per second

@onready var trees_objects = $trees_objects
@onready var lakes_objects = $lake_objects
@onready var settlements_objects = $settlements_objects
@onready var mountains_objects = $mountains_objects

var can_click : bool = true

func _ready():
	place_lakes_randomly()
	place_mountains_randomly()
	# Assuming ObjectPool.gd is a script attached to a Node in the scene
	
	add_child(object_pool)
	
	
	object_pool.tree_scene = tree_scene
	object_pool.settlement_scene = settlement_scene
	object_pool.pool_size = 50000
	
	tilemap = %TileMap
	# Ensure the camera node is assigned
	if camera == null:
		camera = $Camera2D
	camera.make_current()
	Global.spawn_tree.connect(place_tree)
	Global.spawn_settlement.connect(place_settlement)
	Global.remove_tree.connect(remove_tree)
	Global.remove_settlement.connect(remove_settlement)

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
	if Input.is_action_pressed("left_click") and event is InputEventMouseButton and can_click:
		can_click = false
		%Timer.start()
		Global.click_sound.emit()
		# Convert the mouse position to world coordinates
		var world_position = camera.get_global_mouse_position()

		# Try to place a tree at the calculated position
		if place_tree(world_position):
			process_turn()
			
func place_tree(global_position: Vector2) -> bool:
	# Convert the global position to the nearest grid position
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	# Check if the position is already occupied
	if Global.occupied_tiles.has(grid_position):
		#print("Tile at ", grid_position, " is already occupied. Cannot place tree.")
		return false

	# Get a tree instance from the object pool
	var tree_instance = object_pool.get_tree_instance()

	# Check if the tree instance already has a parent
	if tree_instance.get_parent() != null:
		tree_instance.get_parent().remove_child(tree_instance)
	
	# Add the tree instance to the scene and set its position
	trees_objects.add_child(tree_instance)
	tree_instance.global_position = tile_position

	# Update the global dictionaries
	Global.occupied_tiles[grid_position] = tree_instance
	Global.placed_trees[grid_position] = tree_instance

	# Add the tree to the "trees" group
	tree_instance.add_to_group("trees")

	#print("Tree placed at: ", grid_position)
	return true  # Tree was successfully placed



func remove_tree(tree_instance: Node):
	object_pool.return_tree_instance(tree_instance)

func place_settlement(global_position: Vector2) -> bool:
	# Convert the global position to the nearest grid position
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	# Check if the grid position is already occupied
	if Global.occupied_tiles.has(grid_position):
		#print("Tile at ", grid_position, " is already occupied. Cannot place settlement.")
		return false

	# Get a settlement instance from the object pool
	var settlement_instance = object_pool.get_settlement_instance()
	
	# Add the settlement to the scene and set its position
	settlements_objects.add_child(settlement_instance)
	settlement_instance.global_position = tile_position

	# Update the global dictionaries
	Global.occupied_tiles[grid_position] = settlement_instance
	Global.placed_settlements[grid_position] = settlement_instance

	# Add the settlement to the "settlements" group
	settlement_instance.add_to_group("settlements")

	# Optionally, print the settlement placement for debugging
	#print("Settlement placed at: ", grid_position)

	return true  # Settlement was successfully placed


func remove_settlement(settlement_instance: Node):
	object_pool.return_settlement_instance(settlement_instance)
	
func place_lakes_randomly():
	for i in range(number_of_lakes):
		var random_x = randi_range(-placement_range, placement_range)
		var random_y = randi_range(-placement_range, placement_range)
		var random_position = Vector2(random_x, random_y)
		
		place_lake(random_position)
		
func place_mountains_randomly():
	for i in range(number_of_mountains):
		var random_x = randi_range(-placement_range, placement_range)
		var random_y = randi_range(-placement_range, placement_range)
		var random_position = Vector2(random_x, random_y)
		
		place_mountain(random_position)
	
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

func place_mountain(global_position: Vector2):
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	# Check if the tile is already occupied
	if not Global.occupied_tiles.has(grid_position):
		var mountain_instance = mountain_scene.instantiate()
		mountains_objects.add_child(mountain_instance)
		mountain_instance.global_position = tile_position
		mountain_instance.add_to_group("mountain")

		# Add the lake to the occupied tiles dictionary
		Global.occupied_tiles[grid_position] = mountain_instance

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
			Global.fade_out.emit()
			is_raining = false
		else:
			print("It's starting to rain!")
			Global.fade_in.emit()
			is_raining = true

		# Move to the next interval and reset the turn count
		rain_cycle_index = (rain_cycle_index + 1) % max_turns
		turn_count = 0

	# Start the coroutines for processing trees and settlements
	start_processing_trees()
	start_processing_settlements()
	
	# Handle rain effects asynchronously
	if is_raining:
		await(apply_rain_effects())

func start_processing_trees():
	# Start processing trees in batches
	tree_index = 0
	process_tree_batch()

func process_tree_batch():
# Initialize an array to keep track of keys to remove
	var keys_to_remove: Array[Vector2i] = []

	# Iterate through the keys in the Global.placed_trees dictionary
	for grid_position in Global.placed_trees.keys():
		var tree = Global.placed_trees[grid_position]
		
		# Check if the tree instance is valid (not null)
		if not tree or tree.is_queued_for_deletion():
			# Add the grid position to the keys_to_remove array if the tree is null
			keys_to_remove.append(grid_position)
		else:
			# Call the tree's on_new_turn method
			tree.on_new_turn()

	# Remove invalid (null) tree entries from both dictionaries
	for grid_position in keys_to_remove:
		Global.placed_trees.erase(grid_position)
		Global.occupied_tiles.erase(grid_position)

	# Process turns for all settlements
	for settlement in get_tree().get_nodes_in_group("settlements"):
		settlement.on_new_turn()

func start_processing_settlements():
	# Start processing settlements in batches
	settlement_index = 0
	process_settlement_batch()

func process_settlement_batch():
	var batch_size = 5  # Adjust batch size based on performance needs
	var processed = 0
	
	while settlement_index < get_tree().get_nodes_in_group("settlements").size() and processed < batch_size:
		var settlement = get_tree().get_nodes_in_group("settlements")[settlement_index]
		settlement.on_new_turn()

		settlement_index += 1
		processed += 1

	if settlement_index < get_tree().get_nodes_in_group("settlements").size():
		# If not all settlements are processed, continue in the next frame
		await(get_tree().create_timer(0.01))
		process_settlement_batch()
#func process_turn():
	#
	#
	## Increment the turn counter
	#turn_count += 1
#
	## Check if the current turn count matches the next rain interval
	#if turn_count == rain_intervals[rain_cycle_index]:
		#if is_raining:
			#print("Rain has stopped.")
			#Global.fade_out.emit()
			#is_raining = false
		#else:
			#print("It's starting to rain!")
			#Global.fade_in.emit()
			#is_raining = true
#
		## Move to the next interval and reset the turn count
		#rain_cycle_index = (rain_cycle_index + 1) % max_turns
		#turn_count = 0
#
	## Apply effects based on whether it is raining
	#if is_raining:
		#apply_rain_effects()
#
	## Normal tree growth if it's not raining
#
	#apply_normal_growth()
	#
	#
	## Remove entries from placed_trees if they no longer reference valid instances
	#var keys_to_remove = []
	#for grid_position in Global.placed_trees.keys():
		#var tree = Global.placed_trees[grid_position]
		#if tree == null:
			#keys_to_remove.append(grid_position)
		#else:
			#tree.on_new_turn()
#
	## Remove invalid (null) tree entries from both dictionaries
	#for grid_position in keys_to_remove:
		#Global.placed_trees.erase(grid_position)
		#Global.occupied_tiles.erase(grid_position)
#
	## Process turns for all settlements
	#for settlement in get_tree().get_nodes_in_group("settlements"):
		#settlement.on_new_turn()

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
		




func _on_timer_timeout():
	can_click = true # Replace with function body.
