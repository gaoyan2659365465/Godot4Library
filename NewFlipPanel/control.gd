@tool
extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var texture_rect_2: TextureRect = $TextureRect2

@onready var animation_player: AnimationPlayer = $AnimationPlayer


@export_range(0.0,180.0) var a=0.0:
	set(value):
		a = value
		if texture_rect_2:
			texture_rect_2.material.set("shader_parameter/y_rot",value)
			texture_rect.material.set("shader_parameter/y_rot",(180.0-value)*-1)


# 按下按钮时按钮放大
func playAnim(target):
	target.pivot_offset = target.size/2
	var tween = create_tween()
	tween.tween_property(target,"scale",Vector2(1.1,1.1),0.1)

# 松开按钮时按钮收缩回原尺寸
func playAnim2(target):
	var tween = create_tween()
	tween.tween_property(target,"scale",Vector2(1.0,1.0),0.1)
	await tween.finished


func _on_texture_button_button_down() -> void:
	playAnim(texture_rect_2)


func _on_texture_button_pressed() -> void:
	await playAnim2(texture_rect_2)
	animation_player.play("flip_anim")
	await animation_player.animation_finished
	animation_player.play("rongjie_anim")
