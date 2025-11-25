extends Node3D
class_name Spectator

var speed := 1.0
var min_speed := 1.0
var max_speed := 10.0
var acceleration := 1.0
var pitch := 0.0
var theta := 0.0

var sensitivity := 0.01

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pitch -= event.relative.y * sensitivity
		theta -= event.relative.x * sensitivity
	
	if abs(pitch) > 2.0*PI:
		pitch = pitch - pitch/(2*PI) * signf(pitch)
	if abs(theta) > 2.0*PI:
		theta = theta - theta/(2*PI) * signf(theta)
	

func _physics_process(delta: float) -> void:
	var move_lr := Input.get_axis("roll_left", "roll_right")
	var move_fb := Input.get_axis("pitch_down", "pitch_up")
	var move_ud := Input.get_axis("throttle_down", "throttle_up")
	var move := Vector3(move_lr, move_ud,move_fb)
	
	if move.length() != 0.0:
		speed += acceleration * delta
	else:
		speed -= acceleration * delta
	
	speed = clampf(speed, min_speed,max_speed)
	
	
	transform.basis = Basis()
	transform = transform.rotated_local(Vector3.UP, theta)
	transform = transform.rotated_local(Vector3.RIGHT, pitch)
	transform = transform.translated_local(move*delta*speed)
	
