extends VehicleBody3D

var last_position := Vector3.ZERO
var velocity := Vector3.ZERO
var last_velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var save_n_vels := 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	engine_force = delta * 500 * Input.get_axis("throttle_down", "throttle_up")

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

func set_roll() -> void:
	var desired_x_dir := transform.basis.x
	desired_x_dir.y = 0.0
	var angle := transform.basis.x.signed_angle_to(desired_x_dir,-transform.basis.z)
	transform = transform.rotated_local(-transform.basis.z,angle)
