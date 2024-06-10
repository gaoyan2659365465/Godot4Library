extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


var n = 0
func _on_timer_timeout() -> void:
	for i in range(10):
		var _ant = preload("res://Ant/ant.tscn").instantiate()
		_ant.player = $AntPlayer
		add_child(_ant)
		_ant.position = Vector2(346,263)
		n+=1
	if n > 50:
		$Timer.stop()
		
