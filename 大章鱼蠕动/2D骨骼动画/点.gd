extends Control

var id = 0

signal 点击(v)

func _ready() -> void:
	设置尺寸(8)


func 设置尺寸(n=16):
	$TextureButton.size = Vector2(n,n)
	$TextureButton.position = Vector2(-n/2.0,-n/2.0)


func _on_texture_button_pressed() -> void:
	print("1")
	emit_signal("点击",id)
