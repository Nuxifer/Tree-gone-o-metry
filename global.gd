extends Node

signal spawn_tree
signal spawn_lake
signal spawn_settlement
signal settlement_spawn_rate_changed(value)
signal tree_spawn_rate_changed(value)
signal fade_in
signal fade_out
signal remove_tree
signal remove_settlement

var occupied_tiles: Dictionary = {}

var lakes: Array = []  # Track lakes in the game
var placed_trees: Dictionary = {}
var placed_settlements: Dictionary = {}

var hut_spawn_chance: float = 0.04  # 4% chance to spawn a hut
var tree_spawn_chance: float = 0.15  # 15% chance to spawn a tree

# Called when the node enters the scene tree for the first time.
func _ready():
	tree_spawn_rate_changed.connect(_on_tree_spawn_rate_changed)
	settlement_spawn_rate_changed.connect(_on_settlement_spawn_rate_changed)


func _on_tree_spawn_rate_changed(value):
	tree_spawn_chance = value
func _on_settlement_spawn_rate_changed(value):
	hut_spawn_chance = value


