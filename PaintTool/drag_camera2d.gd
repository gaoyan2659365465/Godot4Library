class_name DragCamera2D extends Camera2D


# 鼠标按下时的位置
var pressed_mouse_pos = Vector2.ZERO
var camera_pos = Vector2.ZERO
var is_drag = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			self.pressed_mouse_pos = event.position
			self.camera_pos = self.position
			is_drag = event.is_pressed()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom - Vector2(0.1,0.1),Vector2(0.1,0.1),Vector2(999,999))
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(0.1,0.1)
	if event is InputEventMouseMotion:
		if is_drag:
			var mouse_offset = event.position - self.pressed_mouse_pos
			self.position = self.camera_pos - mouse_offset
		

