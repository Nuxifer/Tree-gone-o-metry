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
			city_health = 2
		#print("No trees found near hut at ", global_position, " , remaining health is: ", city_health)
		if city_health <= 0:
			#print("Hut removed at ", global_position)
			queue_free()
	else:
		# If trees were consumed, reset city health
		city_health = 2
		
	%Sprite2D.frame = hut_level-1
		
func absorb_levels_from_lake():
	# Only allow absorption if the hut level is 3 or below
	if hut_level > 3:
		return  # Skip absorption if the hut level is above 3

	# Get overlapping areas (assumed to be lakes within a certain radius)
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("lakes"):
			var lake = area
			
			# Settlements absorb levels based on their consumption rate
			var absorbed_level = lake.consume_levels(consumption_rate)
			total_consumed += absorbed_level
			
			#print("Settlement at ", global_position, " absorbed ", absorbed_level, " levels from lake.")
			
# Function to consume tree levels within a certain radius
func consume_trees_in_radius() -> bool:
	var tree_found = false
	var total_absorbed_levels = 0
	var max_absorbable_levels = hut_level * 2  # Max levels that can be absorbed per turn
	var points_gained = 0

	# Iterate through overlapping areas (assumed to be trees within a certain radius)
	for tree in get_overlapping_areas():
		if tree.is_in_group("trees"):
			tree_found = true
			
			# Calculate the levels to consume from the tree
			var levels_to_consume = min(2, tree.tree_level)
			tree.tree_level -= levels_to_consume
			total_absorbed_levels += levels_to_consume

			# Calculate points for hut upgrade (1 point per 2 levels consumed)
			points_gained += levels_to_consume / 2

			# Check if the tree's level has reached 0
			if tree.tree_level <= 0:
				remove_tree(tree)

	# Cap the points gained according to hut level
	points_gained = min(points_gained, hut_level * 2)

	# Update total consumed points for hut upgrade
	total_consumed += points_gained
	
	# Perform hut upgrade if the threshold is reached
	if total_consumed >= upgrade_threshold and hut_level < max_hut_level:
		upgrade_hut()

	# Update settlement's health if any trees were consumed
	if tree_found:
		city_health = 2
	
	return tree_found  # Return whether any trees were consumed

# Function to handle tree removal when its levels reach 0
func remove_tree(tree):
	#print("Tree at position ", tree.global_position, " has been removed.")
	var tree_pos = Vector2i(tree.global_position / 16.0)
	if Global.occupied_tiles.has(tree_pos):
		Global.occupied_tiles.erase(tree_pos)
	Global.placed_trees.erase(tree_pos)
	Global.remove_tree.emit(tree)
	tree.queue_free()  # Free the tree instance

# Function to upgrade the hut level
func upgrade_hut():
	hut_level += 1
	consumption_rate = hut_level * 2  # Increase consumption rate with each upgrade
	upgrade_threshold += 3  # Increase the threshold for the next upgrade
	#print("Hut upgraded to level ", hut_level)

