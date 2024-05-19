@tool
extends EditorPlugin

# 当前选中的节点
var handle_node

var brush = BrushTool.new()
var brush_tool_panel = preload("res://addons/smallpaint/brush_tool_panel.tscn").instantiate()
var brush_pos = Vector2.ZERO

# 主屏幕
var w_overlay:Control
var paint_overlay

func _handles(object: Object) -> bool:
	if object.is_class("Sprite2D"):
		self.handle_node = object
		self.brush.setTarget(object)
		return true
	return false

# 返回true则阻止 InputEvent 到达其他编辑类
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
	
	if self.brush.tool_mode == 0 || self.brush.tool_mode == 1:
		return true
	if self.brush.tool_mode == 4:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.is_pressed():
					# Flood Fill洪水填充算法实现魔棒工具
					var img_mask = self.brush.floodFill(self.brush_pos)
					self.brush.createMagicWandTool(self.w_overlay,img_mask)
		return true
	return false


func _forward_canvas_draw_over_viewport(overlay:Control):
	self.w_overlay = overlay
	overlay.draw_circle(self.brush_pos, 10, Color.BLACK)


func _ready() -> void:
	add_control_to_bottom_panel(brush_tool_panel, "画画")
	brush_tool_panel.connect("color_changed",_on_BrushToolPanel_color_changed)
	brush_tool_panel.connect("toggled",_on_BrushToolPanel_toggled)
	brush_tool_panel.connect("value_changed",_on_BrushToolPanel_value_changed)
	brush_tool_panel.connect("pressed",_on_BrushToolPanel_pressed)
	brush_tool_panel.connect("toggled2",_on_BrushToolPanel_toggled2)
	
func _process(delta: float) -> void:
	if self.brush.tool_mode != 2:
		self.brush.drawTick(self.brush_pos)

func _on_BrushToolPanel_pressed(tool_mode):
	self.brush.tool_mode = tool_mode
	if tool_mode == 3:
		# 从剪切板复制图像
		self.brush.copyImageFromClipboard()
	if tool_mode == 4:
		# 初始化魔棒工具，删除之前的选区
		self.brush.initMagicWandTool()


# 修改画笔颜色
func _on_BrushToolPanel_color_changed(color: Color) -> void:
	self.brush.brush_color = color

# 锁定像素
func _on_BrushToolPanel_toggled(toggled_on: bool) -> void:
	self.brush.is_lock_pixel = toggled_on

# 调整笔刷尺寸
func _on_BrushToolPanel_value_changed(value: float) -> void:
	self.brush.drawing_size = Vector2(value,value)

# 创建空图像
func _on_BrushToolPanel_toggled2(toggled_on: bool) -> void:
	if toggled_on:
		self.w_overlay.connect("gui_input",_on_Overlay_gui_input)
	else:
		self.w_overlay.disconnect("gui_input",_on_Overlay_gui_input)

var drag_from
func _on_Overlay_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				drag_from = event.position
			else:
				var scene = get_tree().get_edited_scene_root()
				var tran = scene.get_viewport_transform()
				var start_pos = tran.affine_inverse() * drag_from
				var end_pos = tran.affine_inverse() * event.position
				var size = end_pos-start_pos
				
				var sprite = Sprite2D.new()
				scene.add_child(sprite)
				sprite.name = "新建图层"
				sprite.set_owner(scene)
				var img = Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
				img.fill(self.brush.brush_color)
				sprite.texture = ImageTexture.create_from_image(img)
				sprite.position = start_pos + size/2
				#sprite.position = tran.affine_inverse() * (drag_from+(event.position-drag_from)/2)
				

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	remove_control_from_bottom_panel(brush_tool_panel)
	brush_tool_panel.queue_free()
