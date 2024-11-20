extends Control


var 主场景引用
var id

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# 按下按钮时按钮放大
func playAnim(target):
	if target.pivot_offset == Vector2(0.0,0.0):
		target.pivot_offset = target.size/2
	var tween = create_tween()
	tween.tween_property(target,"scale",Vector2(1.1,1.1),0.1)

# 松开按钮时按钮收缩回原尺寸
func playAnim2(target):
	var tween = create_tween()
	tween.tween_property(target,"scale",Vector2(1.0,1.0),0.1)
	await tween.finished

func 单个格子动画(target=self):
	var tween = create_tween()
	# 非阻塞模式
	tween.set_parallel(true)
	tween.tween_property(target,"scale",Vector2(0.8,0.8),0.1)
	tween.tween_property(target,"scale",Vector2(1.0,1.0),0.1).set_delay(0.1)
	tween.tween_property(target,"scale",Vector2(0.9,0.9),0.1).set_delay(0.2)
	tween.tween_property(target,"scale",Vector2(1.0,1.0),0.1).set_delay(0.3)
	await get_tree().create_timer(0.05).timeout
	$AudioStreamPlayer2D.play()


func _on_texture_button_button_down() -> void:
	playAnim($TextureButton/Panel)

var 是否点击 = false
func _on_texture_button_pressed() -> void:
	await playAnim2($TextureButton/Panel)
	
	自动点击()


func 自动点击():
	if not 是否点击:
		是否点击 = true
		await 单个格子动画()
		主场景引用.点击周围格子(id)
