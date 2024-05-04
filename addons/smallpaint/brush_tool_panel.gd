@tool
class_name BrushToolPanel extends Control


signal color_changed(color: Color)
signal toggled(toggled_on: bool)
signal value_changed(value: float)
signal pressed(tool_mode: int)

# 更改颜色
func _on_color_picker_color_changed(color: Color) -> void:
	emit_signal("color_changed",color)

# 锁定像素
func _on_check_button_toggled(toggled_on: bool) -> void:
	emit_signal("toggled",toggled_on)

# 调整笔刷尺寸
func _on_h_slider_value_changed(value: float) -> void:
	emit_signal("value_changed",value)


func _on_bt_pen_pressed() -> void:
	%btPen.button_pressed = true
	emit_signal("pressed",0)

func _on_bt_rubber_pressed() -> void:
	%btRubber.button_pressed = true
	emit_signal("pressed",1)


func _on_bt_move_pressed() -> void:
	%btMove.button_pressed = true
	emit_signal("pressed",2)


func _on_bt_clip_board_pressed() -> void:
	%btMove.button_pressed = true
	emit_signal("pressed",3)
	emit_signal("pressed",2)


func _on_bt_magic_eraser_pressed() -> void:
	%btMagicEraser.button_pressed = true
	emit_signal("pressed",4)
