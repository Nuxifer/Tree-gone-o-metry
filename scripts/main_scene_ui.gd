extends Node2D

@onready var tree_label = %tree_label
@onready var city_label = %city_label


@onready var rain_scene = preload("res://scenes/rain_scene.tscn")
var animation_player

func _ready():
	Global.fade_in.connect(_on_fade_in)
	Global.fade_out.connect(_on_fade_out)
	%rain_container.modulate = Color(1,1,1,0)
	# Get the size of the screen
	var screen_size = get_viewport().get_visible_rect().size
	#var screen_size = get_viewport().get_visible_rect().size
	
	# Assuming your AnimatedSprite2D has a size of 64x64 pixels
	var sprite_size = Vector2(24, 24)  # Replace with your actual sprite size
	
	# Calculate how many sprites are needed to cover the screen
	var columns = int(ceil(screen_size.x / sprite_size.x))
	var rows = int(ceil(screen_size.y / sprite_size.y))
	
	for x in range(columns):
		for y in range(rows):
			# Instance the AnimatedSprite2D scene
			var sprite_instance = rain_scene.instantiate()
		# Position it correctly on the grid
			sprite_instance.position = Vector2(x * sprite_size.x, y * sprite_size.y)
			
			# Add it as a child of the current node
			%rain_container.add_child(sprite_instance)
			
		

func _on_city_spawn_value_changed(value):
	Global.settlement_spawn_rate_changed.emit(value)
	city_label.set_text("City spawn rate: " + str(value))


func _on_tree_spawn_value_changed(value:):
	Global.tree_spawn_rate_changed.emit(value)
	tree_label.set_text("Tree spawn rate: " + str(value))


func _on_fade_out():
	print("Rain faded out")
	%AnimationPlayer.play("fade_out")
func _on_fade_in():
	print("Rain faded in")
	%AnimationPlayer.play("fade_in")
	
