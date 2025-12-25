@tool
extends Path3D
class_name CRoad

@export var bake : bool = false : set = _set_bake

@export var width : float = 8.0
@export var height : float = 0.1
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _points : PackedVector3Array
var _points_index := 0
var _verts_index := 0

var _surface_array = []

var _verts = PackedVector3Array()
var _uvs = PackedVector2Array()
var _normals = PackedVector3Array()
var _indices = PackedInt32Array()


func _set_bake(value : bool) -> void:
	bake = value
	make_mesh()


func make_mesh() -> void:
	mesh_instance.mesh.clear_surfaces()
	_points = curve.get_baked_points()
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
	_verts_index += 4
	
	_verts.append(_points[_points_index] - right * width - Vector3.UP * height)
	_verts.append(_points[_points_index] - right * width + Vector3.UP * height)
	_verts.append(_points[_points_index] + right * width + Vector3.UP * height)
	_verts.append(_points[_points_index] + right * width - Vector3.UP * height)
	
	_normals.append((-right * width - Vector3.UP * height).normalized())
	_normals.append((-right * width + Vector3.UP * height).normalized())
	_normals.append((+right * width + Vector3.UP * height).normalized())
	_normals.append((+right * width - Vector3.UP * height).normalized())
	
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
	
	#_indices.append_array([0,1,2])
	#_indices.append_array([1,2,3])
	_indices.append_array([zero+2, zero+1,zero])
	_indices.append_array([zero, zero+3,zero+2])

func add_2m_cube() -> void:
	mesh_instance.mesh.clear_surfaces()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	for x in [-1, 1]:
		for y in [-1, 1]:
			for z in [-1, 1]:
				verts.append(Vector3(x, y, z))
				normals.append(Vector3(x, y, z))
				uvs.append(Vector2(x/2 + 0.5, y/2 + 0.5))
	
	indices.append_array([2,1,0])
	indices.append_array([3,1,2])
	

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
