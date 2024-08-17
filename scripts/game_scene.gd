extends Node2D

# Path to the tree scene you want to instantiate
var tree_scene = preload ("res://scenes/tree.tscn")
var settlement_scene = preload("res://scenes/settlement.tscn")
@export var tile_size: float = 16.0

var lake_scene = preload("res://scenes/lake.tscn")  # Reference to the lake scene
@export var number_of_lakes: int = 50  # Number of lakes to place
@export var placement_range: int = 1000  # Range for random placement

# Stores the trees placed on the grid
var lakes: Array = []  # Track lakes in the game
var placed_trees: Dictionary = {}
var occupied_tiles: Dictionary = {}

@export var camera: Camera2D  # Reference to the Camera2D node
@export var scroll_speed: float = 200.0  # Speed of the camera scroll in pixels per second


func _ready():
	place_lakes_randomly()

	# Ensure the camera node is assigned
	if camera == null:
		camera = $Camera2D
	camera.make_current()

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
		if place_tree(event.global_position):
			process_turn()
			
func place_tree(global_position: Vector2) -> bool:
	var tile_position = global_position.snapped(Vector2(tile_size, tile_size))
	var grid_position = Vector2i(tile_position / tile_size)

	if occupied_tiles.has(grid_position):
		print("Tile at ", grid_position, " is already occupied. Cannot place tree.")
		return false

	var tree_instance = tree_scene.instantiate()
	#tree_instance.set("settlement_scene", settlement_scene)
	add_child(tree_instance)
	tree_instance.global_position = tile_position

	occupied_tiles[grid_position] = tree_instance
	placed_trees[grid_position] = tree_instance  # Store the tree in the dictionary
	tree_instance.add_to_group("trees")

	print("Tree placed at: ", grid_position)
	return true  # Tree was successfully placed

func place_lakes_randomly():
	for i in range(number_of_lakes):
		var random_x = randi_range(-placement_range, placement_range)
		var random_y = randi_range(-placement_range, placement_range)
		var random_position = Vector2(random_x, random_y)
		
		place_lake(random_position)

func place_lake(global_position: Vector2):
	var lake_instance = lake_scene.instantiate()
	add_child(lake_instance)
	lake_instance.global_position = global_position.snapped(Vector2(tile_size, tile_size))
	lake_instance.add_to_group("lakes")

	print("Lake placed at: ", lake_instance.global_position)

	print("Lake placed at: ", lake_instance.global_position)

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
