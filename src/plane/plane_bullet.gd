extends RigidBody3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_impulse(-transform.basis.z * 100)
	body_entered.connect(on_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_body_entered(body : Node3D) -> void:
	print_debug("Body: ", body)
	if body.has_method("receive_damage"):
		body.receive_damage(make_damage_instance())
		
func make_damage_instance() -> DamageInstance:
	var result = DamageInstance.new()
	result.source_name = "plane bullet"
	return result
