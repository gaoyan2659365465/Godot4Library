class_name Ant extends CharacterBody2D

@export var speed:int = 40
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@export var player:AntPlayer


func _on_timer_timeout() -> void:
	navigation_agent_2d.target_position = player.position

func _physics_process(delta: float) -> void:
	var direction = to_local(navigation_agent_2d.get_next_path_position()).normalized()
	rotation += atan2(direction.x, -direction.y)*delta
	navigation_agent_2d.velocity = Vector2(sin(rotation), -cos(rotation)) * speed


func _on_navigation_agent_2d_navigation_finished() -> void:
	$AnimatedSprite2D.stop()


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
	$AnimatedSprite2D.play("default")
