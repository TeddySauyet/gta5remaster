extends CharacterBody3D
class_name PlayerPlane

@onready var model : GeometryInstance3D = $CSGCombiner3D

## Adapted from https://kidscancode.org/godot_recipes/3.x/3d/simple_airplane/index.html

# Can't fly below this speed
var min_flight_speed := 10
# Maximum airspeed
var max_flight_speed := 30
# Turn rate
var turn_speed := 0.75
# Climb/dive rate
var pitch_speed := 0.5
# Wings "autolevel" speed
var level_speed := 3.0
# Throttle change speed
var throttle_delta := 30
# Acceleration/deceleration
var acceleration := 6.0

# Current speed
var forward_speed := 0.0
# Throttle input speed
var target_speed := 0.0
# Lets us disable certain things when grounded
var grounded := false

var turn_input := 0.0
var pitch_input := 0.0


func _physics_process(delta):
	get_input(delta)
	# Rotate the transform based on the input values
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(Vector3.UP, turn_input * turn_speed * delta)
	# If on the ground, don't roll the body
	if grounded:
		model.rotation.z = 0
	else:
		# Roll the body based on the turn input
		model.rotation.z = lerp(model.rotation.z, turn_input, level_speed * delta)
	# Accelerate/decelerate
	forward_speed = lerp(forward_speed, target_speed, acceleration * delta)
	# Movement is always forward
	velocity = -transform.basis.z * forward_speed
	# Handle landing/taking off
	if is_on_floor():
		if not grounded:
			rotation.x = 0
		velocity.y -= 1
		grounded = true
	else:
		grounded = false

	move_and_slide()

func get_input(delta):
	# Throttle input
	if Input.is_action_pressed("throttle_up"):
		target_speed = min(forward_speed + throttle_delta * delta, max_flight_speed)
	if Input.is_action_pressed("throttle_down"):
		var limit = 0 if grounded else min_flight_speed
		target_speed = max(forward_speed - throttle_delta * delta, limit)
	# Turn (roll/yaw) input
	turn_input = 0
	if forward_speed > 0.5:
		turn_input -= Input.get_action_strength("roll_right")
		turn_input += Input.get_action_strength("roll_left")
	# Pitch (climb/dive) input
	pitch_input = 0
	if not grounded:
		pitch_input -= Input.get_action_strength("pitch_down")
	if forward_speed >= min_flight_speed:
		pitch_input += Input.get_action_strength("pitch_up")
