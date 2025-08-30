extends CharacterBody3D
class_name Motorcyle

var speed = 0.0
var max_speed := 90.0
var acceleration := 22.5

var steering := 0.0
var steering_speed := 0.1

var time_since_on_floor = 0.0

func _physics_process(delta: float) -> void:
	var steering_delta = Input.get_axis("roll_right", "roll_left") * delta*steering_speed
	if steering_delta != 0:
		steering = steering + steering_delta
	else:
		steering = 0.95*delta*steering
		if steering < 0.05:
			steering = 0
	
	transform = transform.rotated_local(transform.basis.y, steering)
	
	
	var delta_speed := Input.get_axis("throttle_down", "throttle_up") * delta * acceleration
	delta_speed = clampf(delta_speed, -speed, max_speed-speed)
	
	speed += delta_speed
	
	velocity = -transform.basis.z * speed
	
	if not is_on_floor():
		velocity += 9.8*Vector3.DOWN * time_since_on_floor
		time_since_on_floor += delta
		print_debug("hi")
	else:
		time_since_on_floor = 0
		
	move_and_slide()
	print_debug(speed,'|',delta_speed)
