class_name AntPlayer extends CharacterBody2D

var SPEED = 50.0
var move_vector := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if Input.get_vector("ui_left","ui_right","ui_up","ui_down"):
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.stop()

func _physics_process(delta: float) -> void:
	move_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	move_vector = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	velocity += move_vector * SPEED
	move_and_slide()
	if velocity:
		rotation = atan2(velocity.x, -velocity.y)
