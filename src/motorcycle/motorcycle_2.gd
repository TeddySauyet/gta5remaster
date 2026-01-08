extends CharacterBody3D
class_name Motorcyle

@onready var road_ray_cast: RayCast3D = $RoadRayCast
@onready var area_3d_step_up_clear: Area3D = $Area3DStepUpClear
@onready var area_3d_step_up_step: Area3D = $Area3DStepUpStep

var max_speed := 60.0
var acceleration := 10.0
var max_angle := 60.0/180.0*PI
var max_steering := 5.0/180.0*PI

var speed := 0.0
var steering := 0.0
var steering_speed := 0.1

var current_gear := 1
var speed_per_gear := 8.0
var gear_transition_threshhold := 12.0
var gear_min_disadvantage := 0.65

var time_since_on_floor = 0.0

var steering_input := 0.0
var throttle_input := 0.0

var step_up_height := 0.15

var _is_on_road : bool = false

func set_inputs() -> void:
	steering_input = Input.get_axis("roll_right", "roll_left")
	throttle_input = Input.get_axis("throttle_down", "throttle_up")

func is_authority() -> bool:
	return multiplayer.get_unique_id() == get_multiplayer_authority()

func _physics_process(delta: float) -> void:
	if is_authority():
		set_inputs()
	_is_on_road = road_ray_cast.get_collider() != null
	#print_debug(_is_on_road)
	var steering_delta = steering_input * delta*steering_speed
	if signf(steering_delta) != signf(steering):
		steering_delta *= 2
	if steering_delta != 0:
		steering = steering + steering_delta
	else:
		steering = steering - steering_speed *sign(steering) * delta
		if abs(steering) < 2 * steering_speed * delta:
			steering = 0
	
	
	var speed_factor := 1.0 - velocity.length()/100.0
	steering = clampf(steering, -max_steering*speed_factor, max_steering*speed_factor)
	
	var angle := transform.basis.y.angle_to(Vector3.UP) * signf(transform.basis.x.dot(Vector3.UP))
	var desired_angle := -steering*absf(speed)/(max_steering*max_speed) * max_angle
	
	
	if time_since_on_floor < 0.2:
		transform = transform.rotated_local(transform.basis.y.normalized(), steering)
	#transform = transform.rotated_local(transform.basis.z, desired_angle - angle)
	$CSGCombiner3D.transform = Transform3D.IDENTITY
	$CSGCombiner3D.transform = $CSGCombiner3D.transform.rotated_local(-$CSGCombiner3D.transform.basis.z, desired_angle)
	
	var delta_speed := throttle_input * delta * acceleration
	
	var dist_to_current_gear := speed_per_gear*current_gear - speed/current_gear
	var gear_disadvantage := lerpf(1.0, gear_min_disadvantage,absf(dist_to_current_gear)/speed_per_gear)
	gear_disadvantage = clampf(gear_disadvantage, gear_min_disadvantage,1.0)
	
	if absf(dist_to_current_gear)/gear_transition_threshhold >= 1.0:
		current_gear -= signf(dist_to_current_gear)
		if(current_gear <= 0):
			current_gear = 1
	
	delta_speed = clampf(delta_speed*gear_disadvantage, -speed, max_speed-speed)
	
	speed += delta_speed
	
	velocity = -transform.basis.z * speed
	
	if not is_on_floor():
		velocity += 9.8*Vector3.DOWN * time_since_on_floor
		time_since_on_floor += delta
	else:
		time_since_on_floor = 0
		
	if move_and_slide():
		var hit_step := area_3d_step_up_step.get_overlapping_bodies().size() > 0
		var can_step_up := area_3d_step_up_clear.get_overlapping_bodies().size() == 0
		if can_step_up and hit_step:
			var delta_move := (Vector3.UP - transform.basis.z*delta*speed) * step_up_height
			transform = transform.translated_local(delta_move)
			
	#print_debug(velocity.length(), '|', gear_disadvantage)

func receive_damage(dmg : DamageInstance) -> void:
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		client_change_to_spectator.rpc()
		EntitySpawner.spawn_item(
			{
				CEntitySpawner.Config.PATH: "res://src/spectator/Spectator.tscn",
				CEntitySpawner.Config.GLOBAL_TRANSFORM: global_transform,
				CEntitySpawner.Config.MULTIPLAYER_AUTHORITY: get_multiplayer_authority(),
				CEntitySpawner.Config.SET_CAMERA3D: true,
			}
		)

@rpc("call_local", "authority", "reliable")	
func client_change_to_spectator() -> void:
	print_debug("Changing to spectator on ", multiplayer.get_unique_id())
	queue_free()
	if multiplayer.is_server():
		GameState.players[get_multiplayer_authority()].state = CGameState.PLAYER_STATE.SPECTATING
