@tool
extends EditorPlugin

var popup_menu = null

func _enter_tree():
	var fs_dock: = get_editor_interface().get_file_system_dock()

	var popup_menus = []
	for n in fs_dock.get_children():
		if n is PopupMenu:
			popup_menus.push_back(n)
	
	self.popup_menu = popup_menus[-1]
	self.popup_menu.connect("menu_changed", Callable(self, "on_context_menu_changed"))
	self.popup_menu.connect("id_pressed", Callable(self, "on_context_menu_id_pressed"))


func on_context_menu_changed():
	if self.popup_menu.item_count == 0:
		return
	var name = self.popup_menu.get_item_text(self.popup_menu.item_count - 1)
	#print(name)
	var cur_path:String = get_editor_interface().get_current_path()
	if not cur_path: return
	
	var ext = cur_path.get_extension()
	if name == "打开":
		if ext == "txt":
			self.popup_menu.add_separator()
			self.popup_menu.add_item("测试添加按钮")
			print("添加完毕")


func on_context_menu_id_pressed(id:int):
	var cur_path:String = get_editor_interface().get_current_path()
	#获取文件的绝对路径（仅编辑器状态下可用）
	var path = ProjectSettings.globalize_path(cur_path)
	print(path)


func _exit_tree():
	# Clean-up of the plugin goes here.
	pass
