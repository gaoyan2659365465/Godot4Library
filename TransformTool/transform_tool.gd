class_name TransformTool extends Control


# 缩放图像尺寸控件，有八个方向

# 绘制框与控件尺寸的偏移值
var offset = 20.0

# 蓝色颜色
var line_color = Color(0, 0.236816, 0.378906)

# 各个点的位置
var points = []

# 鼠标是否按下
var is_pressed = false
# 鼠标按下时的位置
var pressed_mouse_pos = Vector2.ZERO
# 鼠标按下时的rect
var pressed_rect = Rect2(Vector2.ZERO,Vector2.ZERO)
# 鼠标按下时选中的控制键点数组索引
var pressed_index = -1


func _ready():
	self.connect("gui_input",Callable(self,"_on_TransformTool_gui_input"))
	for i in range(8):
		self.points.append(Vector2.ZERO)

# 设置控件尺寸,根据偏移计算
func setWidgetRect(rect):
	rect = rect.grow_individual(offset,offset,offset,offset)
	self.set_position(rect.position)
	self.set_size(rect.size)
	
# 通过位置获取控制键小方块的rect
func getRectForPos(pos,size=10.0):
	return Rect2(pos-Vector2(size/2.0,size/2.0),Vector2(size,size))

# 通过Rect计算八个控制键小方块的位置
func getPointsForRect(rect:Rect2):
	self.points[0] = rect.position
	self.points[1] = Vector2(rect.end.x, rect.position.y)
	self.points[2] = Vector2(rect.position.x, rect.end.y)
	self.points[3] = rect.end
	self.points[4] = Vector2((rect.end.x-rect.position.x)/2+rect.position.x, rect.position.y)
	self.points[5] = Vector2(rect.position.x, (rect.end.y-rect.position.y)/2+rect.position.y)
	self.points[6] = Vector2(rect.end.x, (rect.end.y-rect.position.y)/2+rect.position.y)
	self.points[7] = Vector2((rect.end.x-rect.position.x)/2+rect.position.x, rect.end.y)

func _draw():
	var rect = self.get_rect()
	rect.position = Vector2.ZERO
	rect = rect.grow_individual(-offset,-offset,-offset,-offset)
	draw_rect(rect, self.line_color,false,1.0)
	self.getPointsForRect(rect)
	for i in self.points:
		draw_rect(self.getRectForPos(i), Color(0.878906, 0.878906, 0.878906))
		draw_rect(self.getRectForPos(i), self.line_color,false)


func _on_TransformTool_gui_input(event):
	if event is InputEventMouseButton:
		self.is_pressed = event.pressed
		self.pressed_mouse_pos = get_global_mouse_position()
		self.pressed_rect = self.get_rect()
		var n = 0
		self.pressed_index = -1
		for i in self.points:
			if getRectForPos(i,20).has_point(self.get_local_mouse_position()):
				self.pressed_index = n
			n = n+1
	if event is InputEventMouseMotion:
		self.set_default_cursor_shape(CURSOR_ARROW)
		var mouse_pos = get_local_mouse_position()
		var n=0
		for i in self.points:
			if getRectForPos(i,20).has_point(mouse_pos):
				var cursor = CURSOR_ARROW
				if n == 0 or n == 3:
					cursor = CURSOR_FDIAGSIZE
				elif n == 1 or n == 2:
					cursor = CURSOR_BDIAGSIZE
				elif n == 4 or n == 7:
					cursor = CURSOR_VSIZE
				elif n == 5 or n == 6:
					cursor = CURSOR_HSIZE
				self.set_default_cursor_shape(cursor)
				break
			n = n+1
		
		if self.is_pressed:
			var mouse_offset = get_global_mouse_position() - self.pressed_mouse_pos
			var rect = Rect2(Vector2.ZERO,Vector2.ZERO)
			if self.pressed_index != -1:
				if self.pressed_index == 3:
					rect = self.pressed_rect.grow_individual(0.0,0.0,mouse_offset.x,mouse_offset.y)
				elif self.pressed_index == 1:
					rect = self.pressed_rect.grow_individual(0.0,-mouse_offset.y,mouse_offset.x,0.0)
				elif self.pressed_index == 0:
					rect = self.pressed_rect.grow_individual(-mouse_offset.x,-mouse_offset.y,0.0,0.0)
				elif self.pressed_index == 2:
					rect = self.pressed_rect.grow_individual(-mouse_offset.x,0.0,0.0,mouse_offset.y)
				elif self.pressed_index == 4:
					rect = self.pressed_rect.grow_individual(0.0,-mouse_offset.y,0.0,0.0)
				elif self.pressed_index == 7:
					rect = self.pressed_rect.grow_individual(0.0,0.0,0.0,mouse_offset.y)
				elif self.pressed_index == 5:
					rect = self.pressed_rect.grow_individual(-mouse_offset.x,0.0,0.0,0.0)
				elif self.pressed_index == 6:
					rect = self.pressed_rect.grow_individual(0.0,0.0,mouse_offset.x,0.0)
				self.position = rect.position
				self.size = rect.size
				self.queue_redraw()
			else:
				self.position = self.pressed_rect.position + mouse_offset
				emit_signal("resized")
