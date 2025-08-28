extends VehicleBody3D

var last_position := Vector3.ZERO
var velocity := Vector3.ZERO
var last_velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var save_n_vels := 5

var balance_mag := 5000.0
var throttle := 20000.0
var steering_force := 10.0

@onready var front_wheel: VehicleWheel3D = $VehicleWheel3D2
@onready var back_wheel: VehicleWheel3D = $VehicleWheel3D
@onready var rider_seat: Node3D = $RiderSeat
@onready var rider_feet: Node3D = $RiderFeet


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#apply_impulse(Vector3(0,0,-100))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	engine_force = delta * throttle * Input.get_axis("throttle_up", "throttle_down")
	steering = Input.get_axis("roll_right", "roll_left") * 0.25
	#steering = delta * steering_force * Input.get_axis("roll_right", "roll_left")
	#update_acceleration()
	#set_roll()

func _physics_process(_delta: float) -> void:
	update_acceleration()
	set_roll()
	pass

## Call from physics process pls
func update_acceleration() -> void:
	velocity = position - last_position
	last_position = position
	acceleration *= (save_n_vels - 1)/save_n_vels
	acceleration += (velocity - last_velocity)/save_n_vels
	last_velocity = velocity

func project(a : Vector3, b : Vector3) -> Vector3:
	return a.dot(b)/b.dot(b)*b

func set_roll() -> void:
	var wheel_og_position := back_wheel.global_position
	wheel_og_position -= project(wheel_og_position, Vector3.UP)
	var desired_x_dir := transform.basis.x
	desired_x_dir.y = 0.0
	var angle := transform.basis.x.signed_angle_to(desired_x_dir,-transform.basis.z)
	apply_force(angle*Vector3.RIGHT*balance_mag, rider_seat.position)
	apply_force(angle*Vector3.LEFT*balance_mag, rider_feet.position)
	#print_debug(angle*Vector3.RIGHT*balance_mag)
	#transform = transform.rotated_local(-transform.basis.z,angle)
	#to account for weird drifting problems
	#it doesn't work lawl
	#transform = transform.translated(wheel_og_position - project(back_wheel.global_position, Vector3.UP))
