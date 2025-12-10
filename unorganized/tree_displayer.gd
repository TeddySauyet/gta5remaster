extends Label

@export var root_item : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if root_item:
		text = add_all_children("", root_item.get_path())
	else:
		text = add_all_children()


func add_all_children(tree: String = "", path : NodePath = "/root", i : int = 0) -> String:
	var node := get_node(path)
	var result := tree + "\n"
	for idx in range(i):
		result += "  "
	result += node.name
	var children := node.get_children()
	if children.size() == 0:
		return result
	else:
		for child in children:
			result = add_all_children(result, child.get_path(), i+1)
	return result
