extends Control

var 所有格子 = []
var width = 10

func _ready() -> void:
	创建格子()
	播放格子动画()


func 创建格子():
	var offset = 5
	for i in range(width):
		for o in range(width):
			var gz = preload("res://格子动效/格子.tscn").instantiate()
			$MarginContainer/Control.add_child(gz)
			gz.position = Vector2(i*50+i*offset,o*50+o*offset)
			所有格子.append(gz)
			gz.主场景引用 = self
			gz.id = 所有格子.size()-1


func 获取斜线格子的编号(n=10):
	var diagonals = []
	# 遍历对角线编号 k
	for k in range(2 * n - 1):
		var diagonal = []
		# 对角线 k 上，满足 x + y = k 的坐标 (x, y)
		for x in range(n):
			var y = k - x
			if y >= 0 and y < n:
				# 转换为一维数组的编号
				diagonal.append(x * n + y)
		diagonals.append(diagonal)
	return diagonals

func 播放格子动画():
	var 间隔 = 0.05
	var tween = create_tween()
	# 非阻塞模式
	tween.set_parallel(true)
	var diagonal_indices = 获取斜线格子的编号()
	for i in range(diagonal_indices.size()):
		#print("对角线 %d: %s" % [i, diagonal_indices[i]])
		for a in diagonal_indices[i]:
			var target = 所有格子[a]
			tween.tween_property(target,"scale",Vector2(0.8,0.8),0.1).set_delay(间隔*i)
			tween.tween_property(target,"scale",Vector2(1.0,1.0),0.1).set_delay(间隔*i+0.1)
			tween.tween_property(target,"scale",Vector2(0.9,0.9),0.1).set_delay(间隔*i+0.2)
			tween.tween_property(target,"scale",Vector2(1.0,1.0),0.1).set_delay(间隔*i+0.3)


func 点击周围格子(index):
	# 一维索引转二维索引
	var _index = [index%width, index/width]
	for _x in range(-1,2):
		for _y in range(-1,2):
			var x = _index[0]+_x
			var y = _index[1]+_y
			# 二维索引转一维索引
			if x >= 0 and y >= 0 and x < width and y < width:
				var _index_ = y * width + x
				if 所有格子.size() <= _index_:
					return
				var gz = 所有格子[_index_]
				gz.自动点击()
