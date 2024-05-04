@tool
class_name PaintOverlay extends Control

@onready var dotted_line: TextureRect = %DottedLine

var target
# 设置蚂蚁线框遮罩图到UI
# target是追踪的目标
func setImage(_target:Sprite2D,img:Image):
	var img_tex = ImageTexture.create_from_image(img)
	dotted_line.texture = img_tex
	target = _target
	
func _process(delta: float) -> void:
	if target:
		var tran = target.get_viewport_transform()
		var _size = dotted_line.texture.get_size() / 2
		dotted_line.position = tran * (target.position-_size)
		dotted_line.size = tran * (target.position+_size) - dotted_line.position
