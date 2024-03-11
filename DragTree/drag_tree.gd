class_name DragTree extends Control

@onready var tree = $Tree


func _ready():
	tree.create_item()
	# 隐藏树的根节点
	tree.set_hide_root(true)
	
	for i in range(5):
		var root:TreeItem = tree.create_item()
		root.set_text(0,"图层"+str(i))
	
func _can_drop_data(position, data):
	return true

func _get_drag_data(position):
	tree.drop_mode_flags = Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM
	var item = tree.get_item_at_position(position-tree.position)
	return item

func _drop_data(position, data):
	var n = tree.get_drop_section_at_position(position-tree.position)
	var item = tree.get_item_at_position(position-tree.position)
	if item == null:
		return
	if n == -1:
		data.move_before(item)
	elif n == 1:
		data.move_after(item)
	elif n == 0:
		var root = data.get_parent()
		root.remove_child(data)
		item.add_child(data)

