extends Camera2D


# 鼠标按下时的位置
var pressed_mouse_pos = Vector2.ZERO
var camera_pos = Vector2.ZERO
var is_press

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			self.pressed_mouse_pos = event.position
			self.camera_pos = self.global_position
			is_press = event.is_pressed()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom - Vector2(0.1,0.1),Vector2(0.1,0.1),Vector2(999,999))
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(0.1,0.1)
	if event is InputEventMouse:
		if is_press:
			var mouse_offset = event.position - self.pressed_mouse_pos
			var tran = get_canvas_transform().affine_inverse()
			self.global_position = self.camera_pos - Vector2(tran.x[0],tran.y[1]) * mouse_offset
