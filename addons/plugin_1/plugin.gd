@tool
extends EditorPlugin

var scene_menu = null

func _enter_tree():
	var base = get_editor_interface().get_base_control()
	var scene_tree_dock = base.find_child("Scene", true, false)
	
	var scene_menu_list = []
	for n in scene_tree_dock.get_children():
		if n is PopupMenu:
			scene_menu_list.push_back(n)
	
	self.scene_menu = scene_menu_list[0]
	self.scene_menu.connect("menu_changed",Callable(self,"_on_menu_changed"))
	self.scene_menu.connect("id_pressed",Callable(self,"_on_id_pressed"))
	

func _on_menu_changed():
	if self.scene_menu.item_count == 0:
		return
	var name = self.scene_menu.get_item_text(self.scene_menu.item_count - 1)
	if name == "删除节点":
		var nodes = get_editor_interface().get_selection().get_selected_nodes()
		if nodes[0] as Panel:
			self.scene_menu.add_item("测试添加菜单按钮",99)#不能超过100

func _on_id_pressed(id:int):
	if id == 99:
		var nodes = get_editor_interface().get_selection().get_selected_nodes()
		print(nodes)


func _exit_tree():
	# Clean-up of the plugin goes here.
	pass
