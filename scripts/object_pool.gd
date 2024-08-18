extends Node

var tree_scene = preload("res://scenes/tree.tscn")
var settlement_scene = preload("res://scenes/settlement.tscn")
var pool_size: int = 500

var tree_pool: Array = []
var settlement_pool: Array = []


func _ready():
	# Initialize the pools with instances
	for i in range(pool_size):
		var tree_instance = tree_scene.instantiate()
		tree_pool.append(tree_instance)
		
		var settlement_instance = settlement_scene.instantiate()
		settlement_pool.append(settlement_instance)
func get_tree_instance() -> Node:
	# Check if the pool has available instances
	for tree_instance in tree_pool:
		if is_instance_valid(tree_instance):
			tree_pool.erase(tree_instance)
			return tree_instance
	# If not, instantiate a new one
	return tree_scene.instantiate()

func return_tree_instance(tree_instance: Node):
	if is_instance_valid(tree_instance):
		tree_pool.append(tree_instance)
	else:
		# Handle case where instance is not valid (e.g., log an error)
		print("Warning: Attempted to return an invalid tree instance.")

func get_settlement_instance() -> Node:
	# Check if the pool has available instances
	for settlement_instance in settlement_pool:
		if is_instance_valid(settlement_instance):
			settlement_pool.erase(settlement_instance)
			return settlement_instance
	# If not, instantiate a new one
	return settlement_scene.instantiate()

func return_settlement_instance(settlement_instance: Node):
	if is_instance_valid(settlement_instance):
		settlement_pool.append(settlement_instance)
	else:
		# Handle case where instance is not valid (e.g., log an error)
		print("Warning: Attempted to return an invalid settlement instance.")
