class_name Trail2D extends Line2D


# 拖尾效果

@export var lenght = 50
var point = Vector2()


func _process(delta: float) -> void:
	global_position = Vector2.ZERO
	global_rotation = 0
	
	point = get_parent().global_position
	add_point(point)
	while get_point_count()>lenght:
		remove_point(0)
