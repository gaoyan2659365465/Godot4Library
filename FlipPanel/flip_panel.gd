@tool
class_name FlipPanel extends Control

# 翻转卡牌效果
@onready var behind: TextureRect = $Behind
@onready var front: TextureRect = $Front
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal flip
signal burning

@export_range(0.0,180.0) var y_rot = 0.0:
	set(value):
		y_rot = value
		if front:
			front.material.set("shader_parameter/y_rot",value)
		if behind:
			behind.material.set("shader_parameter/y_rot",(180.0-value)*-1)

@export var a = 0

func _ready() -> void:
	if a == 1:
		$SubViewport/Ui8/Label.text = "攻击力+10"
		$SubViewport/Ui8/Label2.text = "突然间，你感觉到一股强大的力量涌入你的体内，仿佛火焰在你的血液中燃烧。你的肌肉鼓胀，你的眼神变得锐利起来，仿佛一只被激怒的鹰隼准备向前扑击。"
	if a == 2:
		$SubViewport/Ui8/Label.text = "血上限+20"
		$SubViewport/Ui8/Label2.text = "这种血量上限提升让你感觉自己仿佛是一座坚不可摧的城堡。你感受到自己的每一滴血液都沸腾着生命的力量，仿佛要将你笼罩在一层坚实的保护之中。"

func flipAnim():
	animation_player.play("flip_anim")

func burningAnim():
	animation_player.play("burning_anim")


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
	playAnim(behind)


func _on_texture_button_pressed() -> void:
	await playAnim2(behind)
	flipAnim()
	await animation_player.animation_finished
	emit_signal("flip")
	




func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "burning_anim":
		emit_signal("burning")
