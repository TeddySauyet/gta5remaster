@tool
extends Path3D
class_name CRoad

@export var bake : bool = false : set = _set_bake
@export var width : float = 8.0
@export var height : float = 0.1
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var static_body_3d: StaticBody3D = $StaticBody3D
@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D

var _points : PackedVector3Array
var _collision_points : PackedVector3Array
var _points_index := 0
var _verts_index := 0

var _surface_array = []

var _verts := PackedVector3Array()
var _uvs := PackedVector2Array()
var _normals := PackedVector3Array()
var _indices := PackedInt32Array()
var _space_state : PhysicsDirectSpaceState3D = null 

func _set_bake(value : bool) -> void:
	make_mesh()

func _physics_process(delta: float) -> void:
	_space_state = get_world_3d().direct_space_state

func make_mesh() -> void:
	for child in mesh_instance.get_children():
		if child is StaticBody3D:
			child.collision_mask = 0
			child.collision_layer = 0
			child.queue_free()
	mesh_instance.mesh.clear_surfaces()
	_calculate_points()
	_collision_points = []
	_surface_array = []
	_surface_array.resize(Mesh.ARRAY_MAX)
	_verts = PackedVector3Array()
	_uvs = PackedVector2Array()
	_normals = PackedVector3Array()
	_indices = PackedInt32Array()
	_points_index = -1
	_verts_index = -1
		
	add_beginning_face()
	
	for i in range(_points.size() - 1):
		add_next_tube()
	
	add_ending_face()
	
	# Assign arrays to surface array.
	_surface_array[Mesh.ARRAY_VERTEX] = _verts
	_surface_array[Mesh.ARRAY_TEX_UV] = _uvs
	_surface_array[Mesh.ARRAY_NORMAL] = _normals
	_surface_array[Mesh.ARRAY_INDEX] = _indices
	
	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _surface_array)
	
	calculate_collision_points()
	generate_collision_mesh()

func add_beginning_face() -> void:
	_points_index = 0
	var forward := _points[1] - _points[0]
	var right := forward.cross(Vector3.UP).normalized()
	_verts_index = 3
	
	_verts.append(_points[0] - right * width - Vector3.UP * height)
	_verts.append(_points[0] - right * width + Vector3.UP * height)
	_verts.append(_points[0] + right * width + Vector3.UP * height)
	_verts.append(_points[0] + right * width - Vector3.UP * height)

	_normals.append((-right.normalized() - Vector3.UP.normalized() -forward.normalized()).normalized())
	_normals.append((-right.normalized() + Vector3.UP.normalized() -forward.normalized()).normalized())
	_normals.append((+right.normalized() + Vector3.UP.normalized() -forward.normalized()).normalized())
	_normals.append((+right.normalized() - Vector3.UP.normalized() -forward.normalized()).normalized())
	
	
	_uvs.append(Vector2(0,0))
	_uvs.append(Vector2(0,1))
	_uvs.append(Vector2(1,1))
	_uvs.append(Vector2(1,0))
	
	_indices.append_array([0,1,2])
	_indices.append_array([2,3,0])
	
func add_next_tube() -> void:
	_points_index += 1
	var forward := _points[_points_index] - _points[_points_index-1]
	var right := forward.cross(Vector3.UP).normalized()
	var up := forward.cross(-right).normalized()
	_verts_index += 4
	
	_verts.append(_points[_points_index] - right * width - up * height)
	_verts.append(_points[_points_index] - right * width + up * height)
	_verts.append(_points[_points_index] + right * width + up * height)
	_verts.append(_points[_points_index] + right * width - up * height)
	
	#causes smooth lighting
	#_normals.append((-right * width - Vector3.UP * height).normalized())
	#_normals.append((-right * width + Vector3.UP * height).normalized())
	#_normals.append((+right * width + Vector3.UP * height).normalized())
	#_normals.append((+right * width - Vector3.UP * height).normalized())
	
	#makes the edges all nasty like
	_normals.append(-up)
	_normals.append(up)
	_normals.append(up)
	_normals.append(-up)
	
	_uvs.append(Vector2(0,0))
	_uvs.append(Vector2(0,1))
	_uvs.append(Vector2(1,1))
	_uvs.append(Vector2(1,0))
	
	var i := _verts_index
	var j := _verts_index - 4
	
	_indices.append_array([i, i-3, j-3])
	_indices.append_array([j-3, j, i])
	
	for face in range(3):
		_indices.append_array([j-face-1, i-face-1, i-face])
		_indices.append_array([i-face, j-face, j-face-1])

func add_ending_face() -> void:
	var forward := _points[_points_index] - _points[_points_index-1]
	var right := forward.cross(Vector3.UP).normalized()
	_verts_index += 4
	
	_verts.append(_points[_points_index] - right * width - Vector3.UP * height)
	_verts.append(_points[_points_index] - right * width + Vector3.UP * height)
	_verts.append(_points[_points_index] + right * width + Vector3.UP * height)
	_verts.append(_points[_points_index] + right * width - Vector3.UP * height)
	
	_normals.append((-right.normalized() - Vector3.UP.normalized() + forward.normalized()).normalized())
	_normals.append((-right.normalized() + Vector3.UP.normalized() + forward.normalized()).normalized())
	_normals.append((+right.normalized() + Vector3.UP.normalized() + forward.normalized()).normalized())
	_normals.append((+right.normalized() - Vector3.UP.normalized() + forward.normalized()).normalized())
	
	
	_uvs.append(Vector2(0,0))
	_uvs.append(Vector2(0,1))
	_uvs.append(Vector2(1,1))
	_uvs.append(Vector2(1,0))
	
	var zero := _verts_index - 3

	_indices.append_array([zero+2, zero+1,zero])
	_indices.append_array([zero, zero+3,zero+2])

func _calculate_points() -> void:
	_points = curve.get_baked_points()
	var mods := {}
	var idx := -1
	for point in _points:
		idx += 1
		var query := PhysicsRayQueryParameters3D.create(global_transform*point, point+Vector3.DOWN*1000.0)
		var result := _space_state.intersect_ray(query)
		if result:
			mods[idx] = result["position"] * global_transform
	for key in mods:
		_points[key] = mods[key]

func calculate_collision_points() -> void:
	_collision_points.resize(_indices.size())
	var idx := 0
	for index in _indices:
		_collision_points[idx] = _verts[index]
		idx += 1

func generate_collision_mesh() -> void:
	collision_shape_3d.shape.set_faces(_collision_points)
