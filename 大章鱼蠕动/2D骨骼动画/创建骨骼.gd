extends Control


# 鼠标按下时的位置
var pressed_mouse_pos = Vector2.ZERO
var is_press

@onready var skeleton_2d: Skeleton2D = $Skeleton2D

var 游标

var 正在画的骨骼控件

var 允许创建 = false

func _ready() -> void:
	游标 = skeleton_2d

func 创建骨骼(pos):
	var b = Bone2D.new()
	b.set_autocalculate_length_and_angle(false)
	游标.add_child(b)
	b.owner = self.get_parent()
	游标 = b
	b.global_position = pos
	b.rest = Transform2D(b.rotation, Vector2(b.position.x, b.position.y))

func _unhandled_input(event):
	if not 允许创建:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			self.pressed_mouse_pos = event.position
			is_press = event.is_pressed()
			if is_press:
				var tran = get_canvas_transform().affine_inverse()
				创建骨骼控件(tran*self.pressed_mouse_pos)
				创建骨骼(tran*self.pressed_mouse_pos)
			else:
				正在画的骨骼控件 = null
	if event is InputEventMouse:
		if is_press:
			var tran = get_canvas_transform().affine_inverse()
			var mouse_offset = tran*event.position - tran*self.pressed_mouse_pos
			#print(mouse_offset)
			正在画的骨骼控件.更新骨骼末端(mouse_offset)


func 创建骨骼控件(pos):
	var gw = preload("res://大章鱼蠕动/2D骨骼动画/骨骼.tscn").instantiate()
	add_child(gw)
	gw.position = pos
	正在画的骨骼控件 = gw
