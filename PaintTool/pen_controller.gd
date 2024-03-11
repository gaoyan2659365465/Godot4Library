class_name PenController extends Panel

@onready var tree = $Tree
@onready var popup_menu = $Tree/PopupMenu

signal value_changed(value)
signal color_changed(color)
signal item_selected(index)
signal move_layer(uuids)
signal mask_toggled(toggled_on)
signal menu_id_pressed(uuid,menu_id)

func _ready():
	emit_signal("color_changed",Color.BLACK)
	emit_signal("value_changed",5)
	
	tree.create_item()
	# 隐藏树的根节点
	tree.set_hide_root(true)

# 添加图层
func addLayer(i,uuid):
	var root:TreeItem = tree.create_item()
	root.set_text(0,"图层"+str(i))
	root.set_meta("uuid",uuid)

func _can_drop_data(position, data):
	return true

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
	# 移动图层信号
	var root = tree.get_root()
	var uuids = []
	
	for i in root.get_children():
		uuids.append(i.get_meta("uuid"))
	emit_signal("move_layer",uuids)

func _get_drag_data(position):
	tree.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	var item = tree.get_item_at_position(position-tree.position)
	return item

func _on_tree_item_selected():
	var item = tree.get_selected()
	emit_signal("item_selected",item.get_index())


func _on_h_slider_value_changed(value):
	emit_signal("value_changed",value)

func _on_color_picker_button_color_changed(color):
	emit_signal("color_changed",color)


# 画遮罩按钮
func _on_check_button_toggled(toggled_on):
	emit_signal("mask_toggled",toggled_on)


func _on_tree_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var item = tree.get_item_at_position(event.position)
			# 选中指定的列
			item.select(0)
			popup_menu.popup_on_parent(Rect2(event.global_position, Vector2.ZERO))

# Tree右键菜单
func _on_popup_menu_id_pressed(id):
	var item = tree.get_selected()
	var uuid = item.get_meta("uuid")
	emit_signal("menu_id_pressed",uuid,id)
