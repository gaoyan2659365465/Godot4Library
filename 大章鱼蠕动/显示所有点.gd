extends Node2D

var 点数组 = []
var 线数组 = []


var 生成的网格

# 绘制网格、创建骨骼
var 模式 = "绘制网格"

func _ready() -> void:
	生成的网格 = 根据图片生成网格($"图片")
	删除所有网格点(生成的网格)
	

func 创建所有点(target:Polygon2D):
	for i in 点数组:
		i.点击.disconnect(_on_点_点击)
		i.queue_free()
	点数组.clear()
	var id = 0
	for i:Vector2 in target.polygon:
		var d = preload("res://大章鱼蠕动/2D骨骼动画/点.tscn").instantiate()
		add_child(d)
		d.global_position = target.to_global(i)
		点数组.append(d)
		d.id = id
		id+=1
		d.点击.connect(_on_点_点击)


func 创建所有线(target:Polygon2D):
	for i in 线数组:
		i.queue_free()
	线数组.clear()
	for i in target.polygons:
		var x = preload("res://大章鱼蠕动/2D骨骼动画/线.tscn").instantiate()
		add_child(x)
		x.position = target.position
		var v = [target.polygon[i[0]],target.polygon[i[1]],
		target.polygon[i[0]],target.polygon[i[2]],
		target.polygon[i[1]],target.polygon[i[2]]]
		x.初始化(v)
		线数组.append(x)


func 创建三角面(poly : Polygon2D):
	poly.polygons = []
	var points = Geometry2D.triangulate_delaunay(poly.polygon)
	for point in range(0, points.size(), 3):
		var triangle = []
		triangle.push_back(points[point])
		triangle.push_back(points[point + 1])
		triangle.push_back(points[point + 2])
		poly.polygons.push_back(triangle)
	poly.uv = poly.polygon
	return poly



func 减少点(target:Polygon2D,id):
	var poly = target.polygon
	poly.remove_at(id)
	target.polygon = poly
	创建三角面(target)
	创建所有线(target)
	创建所有点(target)
	

func 增加点(target:Polygon2D,pos):
	var poly = target.polygon
	var tran = get_canvas_transform().affine_inverse()
	poly.append(tran * pos - target.position)
	target.polygon = poly
	创建三角面(target)
	创建所有线(target)
	创建所有点(target)



func 获取所有骨骼(target:Polygon2D):
	var sk = get_node(target.skeleton)
	var n = sk.get_bone_count()
	var bones = []
	for i in range(n):
		var bone = sk.get_bone(i)
		bones.append(bone)
	return bones


# 骨骼是一条线，应该计算各个顶点到线的距离而不是单纯计算到骨骼点的距离
func 自动计算权重(target:Polygon2D):
	# 获取所有骨骼
	# 新的权重骨骼数组
	var new_bones = []
	var bones = 获取所有骨骼(target)
	var sk = get_node(target.skeleton)
	for i in bones:
		new_bones.append(sk.get_path_to(i))
		var new_qz:PackedFloat32Array = []
		for a in range(target.polygon.size()):
			# 拿到相应顶点的位置
			var pos:Vector2 = target.polygon[a]
			# 计算该顶点与骨骼的距离(注意骨骼的相对位置，如果Skeleton2D节点与Polygon2D节点的位置相同)
			var distance = pos.distance_to(i.global_position)
			var 权重 = 1.0 / (distance + 0.001)  # 使用距离倒数衰减
			new_qz.append(权重)
		new_bones.append(new_qz)
	target.bones = new_bones

func 删除所有网格点(target:Polygon2D):
	target.polygon = []
	target.polygons = []
	target.uv = []
	创建所有线(target)
	创建所有点(target)
	target.clear_bones()
	target.bones = []


func 根据图片生成网格(target:Sprite2D):
	var wg = preload("res://大章鱼蠕动/2D骨骼动画/图片转网格.gd").new()
	var poly = wg.create_polygon_from_sprite(target)
	poly.visible = false
	add_child(poly)
	poly.owner = self
	创建三角面(poly)
	创建所有线(poly)
	创建所有点(poly)
	return poly



func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if 模式 == "绘制网格":
					增加点(生成的网格,event.global_position)


func _on_点_点击(id):
	减少点(生成的网格,id)

func _on_button_pressed() -> void:
	删除所有网格点(生成的网格)

# 图片转网格
func _on_button_2_pressed() -> void:
	生成的网格.queue_free()
	生成的网格 = 根据图片生成网格($"图片")
	move_child($"创建骨骼",-1)


# 从剪切板复制图像
func copyImageFromClipboard(target:Sprite2D):
	if DisplayServer.clipboard_has_image():
		var clipboard_img = DisplayServer.clipboard_get_image()
		clipboard_img.convert(Image.FORMAT_RGBA8)
		target.texture = ImageTexture.create_from_image(clipboard_img)

func _on_button_3_pressed() -> void:
	copyImageFromClipboard($"图片")
	$"图片".position = $"图片".texture.get_size()/2.0



func _on_button_4_toggled(toggled_on: bool) -> void:
	if toggled_on:
		模式 = "创建骨骼"
		$"创建骨骼".允许创建 = true
	else:
		模式 = "绘制网格"
		$"创建骨骼".允许创建 = false



func _on_button_5_pressed() -> void:
	生成的网格.visible = true
	$"图片".visible = false
	生成的网格.skeleton = $"创建骨骼/Skeleton2D".get_path()
	自动计算权重(生成的网格)
	
	var scene = PackedScene.new()
	$Camera2D.owner = null
	$Control.owner = null
	$"图片".owner = null
	scene.pack(self)
	ResourceSaver.save(scene,"res://大章鱼蠕动//保存数据.tscn")
