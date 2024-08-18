extends Area2D

@export var hut_level: int = 1  # Initial level of the hut
@export var consumption_rate: int = 1  # Points consumed from each tree in the radius

@export var upgrade_threshold: int = 3  # Points needed to upgrade to the next hut level
@export var max_hut_level: int = 5  # Max level of a hut
@export var total_consumed: int = 0
@export var city_health: int = 3

func on_new_turn():
	absorb_levels_from_lake()
	# Check if the hut consumes trees
	var trees_consumed = consume_trees_in_radius()
	# If no trees were consumed, reduce city health
	if not trees_consumed:
		city_health -= 1
		hut_level -= 1
		if city_health <= hut_level:
			city_health = hut_level
		if hut_level == 1:
			city_health = 3
		#print("No trees found near hut at ", global_position, " , remaining health is: ", city_health)
		if city_health <= 0:
			print("Hut removed at ", global_position)
			queue_free()
	else:
		# If trees were consumed, reset city health
		city_health = 3
		
	%Sprite2D.frame = hut_level-1
		
func absorb_levels_from_lake():
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("lakes"):
			var lake = area
			var absorbed_level = lake.consume_levels(consumption_rate)  # Settlements absorb levels based on their consumption rate
			total_consumed += absorbed_level
			#print("Settlement at ", global_position, " absorbed ", absorbed_level, " levels from lake.")
			
func consume_trees_in_radius() -> bool:
	var tree_found = false
	
	for tree in get_overlapping_areas():
		if tree.is_in_group("trees"):
			consume_tree(tree)
			tree_found = true
			city_health = 3

	return tree_found  # Return whether any trees were consumed

func consume_tree(tree):
	var amount_to_consume = consumption_rate

	tree.tree_level -= amount_to_consume
	#print("Consumed ", amount_to_consume, " points from tree. New tree level: ", tree.tree_level)

	if tree.tree_level <= 0:
		print("Tree at position ", tree.global_position, " has been removed.")
		var tree_pos = tree.global_position / 16.0
		if Global.occupied_tiles.has(tree_pos):
			Global.occupied_tiles.erase(tree_pos)
		Global.placed_trees.erase(tree)
		tree.queue_free()  # Remove the tree if its level reaches 0

	total_consumed += amount_to_consume

	if total_consumed >= upgrade_threshold and hut_level < max_hut_level:
		upgrade_hut()

func upgrade_hut():
	
	hut_level += 1
	consumption_rate = hut_level  # Increase consumption rate with each upgrade
	upgrade_threshold += 3  # Increase the threshold for the next upgrade
	print("Hut upgraded to level ", hut_level)
