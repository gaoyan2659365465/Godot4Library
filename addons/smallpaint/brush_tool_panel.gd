@tool
class_name BrushToolPanel extends Control


signal color_changed(color: Color)
signal toggled(toggled_on: bool)
signal value_changed(value: float)

# 更改颜色
func _on_color_picker_color_changed(color: Color) -> void:
	emit_signal("color_changed",color)

# 锁定像素
func _on_check_button_toggled(toggled_on: bool) -> void:
	emit_signal("toggled",toggled_on)

# 调整笔刷尺寸
func _on_h_slider_value_changed(value: float) -> void:
	emit_signal("value_changed",value)
