@tool
extends EditorPlugin

# 当前选中的节点
var handle_node

var bt = Button.new()
var bt_rubber = Button.new()
var brush = BrushTool.new()
var brush_tool_panel = preload("res://addons/smallpaint/brush_tool_panel.tscn").instantiate()
var brush_pos = Vector2.ZERO


func _handles(object: Object) -> bool:
	if object.is_class("Sprite2D"):
		self.handle_node = object
		self.brush.setTarget(object)
		bt.visible = true
		bt_rubber.visible = true
	else:
		bt.visible = false
		bt_rubber.visible = false
	return bt.visible

# 阻止 InputEvent 到达其他编辑类
func _forward_canvas_gui_input(event):
	if event is InputEventMouseMotion:
		# 当光标被移动时，重绘视窗。
		update_overlays()
		self.brush_pos = event.position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				self.brush.drawStart()
			else:
				self.brush.drawEnd()
	
	if self.bt.button_pressed:
		return true
	if self.bt_rubber.button_pressed:
		return true
	return false


func _forward_canvas_draw_over_viewport(overlay):
	if self.bt.button_pressed:
		overlay.draw_circle(self.brush_pos, 10, Color.BLACK)



func _ready() -> void:
	bt.toggle_mode = true
	bt.set_button_icon(load("res://addons/smallpaint/pen.svg"))
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, bt)
	
	bt_rubber.toggle_mode = true
	bt_rubber.set_button_icon(load("res://addons/smallpaint/rubber.svg"))
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, bt_rubber)
	
	bt.connect("pressed",_on_button_pressed)
	bt_rubber.connect("pressed",_on_button2_pressed)
	
	add_control_to_bottom_panel(brush_tool_panel, "画画")
	brush_tool_panel.connect("color_changed",_on_BrushToolPanel_color_changed)
	brush_tool_panel.connect("toggled",_on_BrushToolPanel_toggled)
	brush_tool_panel.connect("value_changed",_on_BrushToolPanel_value_changed)
	
func _process(delta: float) -> void:
	if self.bt.button_pressed or self.bt_rubber.button_pressed:
		self.brush.drawTick(self.brush_pos)


func _on_button_pressed():
	if self.bt.button_pressed:
		bt_rubber.button_pressed = false
		self.brush.tool_mode = 0

func _on_button2_pressed():
	if self.bt_rubber.button_pressed:
		bt.button_pressed = false
		self.brush.tool_mode = 1

# 修改画笔颜色
func _on_BrushToolPanel_color_changed(color: Color) -> void:
	self.brush.brush_color = color

# 锁定像素
func _on_BrushToolPanel_toggled(toggled_on: bool) -> void:
	self.brush.is_lock_pixel = toggled_on

# 调整笔刷尺寸
func _on_BrushToolPanel_value_changed(value: float) -> void:
	self.brush.drawing_size = Vector2(value,value)


func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	remove_control_from_bottom_panel(brush_tool_panel)
	brush_tool_panel.queue_free()
