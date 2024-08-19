
extends TextureRect

@export var start_position: Vector2
@export var end_position: Vector2
@export var move_speed: float = 0.05  # Speed at which the background moves

var direction: int = 1  # 1 for moving towards end_position, -1 for moving towards start_position
var lerp_time: float = 0.0  # Time variable to control the interpolation

func _ready():
	# Initialize positions
	global_position = start_position
	start_position = %left.global_position
	end_position = %right.global_position

func _process(delta: float):
	# Update lerp_time based on move_speed and delta time
	lerp_time += move_speed * delta * direction

	# Ensure lerp_time stays within the 0 to 1 range
	if lerp_time >= 1.0:
		lerp_time = 1.0
		direction = -1  # Reverse direction
	elif lerp_time <= 0.0:
		lerp_time = 0.0
		direction = 1  # Reverse direction

	# Lerp between start_position and end_position
	global_position = start_position.lerp(end_position, lerp_time)
