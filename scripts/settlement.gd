extends Area2D

@export var hut_level: int = 1  # Initial level of the hut
@export var consumption_rate: int = 1  # Points consumed from each tree in the radius

@export var upgrade_threshold: int = 3  # Points needed to upgrade to the next hut level
@export var max_hut_level: int = 5  # Max level of a hut
@export var total_consumed: int = 0
@export var city_health: int = 3

# In the _init or _ready function of the settlement
func _ready():
	hut_level = 1  # Ensure hut_level is initialized to 1 or a positive value
	consumption_rate = 2  # Set an initial consumption rate if needed
	upgrade_threshold = 3  # Set the initial upgrade threshold
	total_consumed = 0  # Initialize total_consumed to 0
	max_hut_level = 5  # Set a maximum hut level
	
func on_new_turn():
	# Ensure hut_level never goes negative
	
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
		%Sprite2D.frame = hut_level-1
		#print("No trees found near hut at ", global_position, " , remaining health is: ", city_health)
		if city_health <= 0:
			#print("Hut removed at ", global_position)
			queue_free()
	else:
		# If trees were consumed, reset city health
		city_health = 2
	if hut_level < 1:
		hut_level = 1
		print("Warning: Hut level reset to 1 due to invalid value.")

		
		
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
			
			
func consume_trees_in_radius() -> bool:
	var tree_found = false
	var total_absorbed_levels = 0
	var points_gained = 0
	var max_absorbable_levels = hut_level * 2  # Max levels that can be absorbed per turn
	var max_points_per_turn = hut_level * 2  # Max points towards hut level upgrade per turn

	# Debugging: Initial state
	#print("Starting consumption for settlement at level ", hut_level)

	# Iterate through overlapping areas (assumed to be trees within a certain radius)
	for tree in get_overlapping_areas():
		if tree.is_in_group("trees"):
			tree_found = true

			# Calculate the levels to consume from the tree
			var levels_to_consume = min(2, tree.tree_level)
			levels_to_consume = min(levels_to_consume, max_absorbable_levels - total_absorbed_levels)

			# Ensure we don't consume a negative amount
			if levels_to_consume > 0:
				tree.tree_level -= levels_to_consume
				total_absorbed_levels += levels_to_consume

				# Calculate points for hut upgrade (1 point per 2 levels consumed)
				points_gained += levels_to_consume / 2

				# Debugging: Tree and points information
				#print("Tree Levels Consumed: ", levels_to_consume)
				#print("Total Absorbed Levels: ", total_absorbed_levels)
				#print("Points Gained This Turn: ", points_gained)

				# Check if the tree's level has reached 0
				if tree.tree_level <= 0:
					#print("Removing tree at position ", tree.global_position)
					remove_tree(tree)

				# Stop consuming if we've reached the max absorbable levels
				if total_absorbed_levels >= max_absorbable_levels:
					break
			else:
				print("No levels to consume from tree at position ", tree.global_position)

	# Cap the points gained according to hut level
	points_gained = min(points_gained, max_points_per_turn)

	# Update total consumed points for hut upgrade
	total_consumed += points_gained
	
	# Debugging: Final state
	print("Total Consumed: ", total_consumed, " / Upgrade Threshold: ", upgrade_threshold)
	
	# Check if the total consumed points meet or exceed the threshold for upgrading
	if total_consumed >= upgrade_threshold and hut_level < max_hut_level:
		upgrade_hut()

	return tree_found  # Return whether any trees were consumed


# Function to handle tree removal when its levels reach 0
func remove_tree(tree):
	#print("Tree at position ", tree.global_position, " has been removed.")
	var tree_pos = Vector2i(tree.global_position / 24.0)
	if Global.occupied_tiles.has(tree_pos):
		Global.occupied_tiles.erase(tree_pos)
	Global.placed_trees.erase(tree_pos)
	Global.remove_tree.emit(tree)

# Function to upgrade the hut level
func upgrade_hut():
	hut_level += 1
	consumption_rate = hut_level * 2  # Increase consumption rate with each upgrade
	upgrade_threshold += 3  # Increase the threshold for the next upgrade
	print("Hut upgraded to level ", hut_level)
	%Sprite2D.frame = hut_level-1

