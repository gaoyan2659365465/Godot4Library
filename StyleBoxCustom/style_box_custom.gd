@tool
class_name StyleBoxCustom extends StyleBox
#RenderingServer


@export_range(3,30) var edge = 3:
	set(value):
		edge = value
		emit_changed()
@export var color:Color = Color(1,1,1):
	set(value):
		color = value
		emit_changed()
@export_range(0.0,100.0) var radius = 10.0:
	set(value):
		radius = value
		emit_changed()

@export_range(0.0,360.0) var rotate = 0.0:
	set(value):
		rotate = value
		emit_changed()

@export var curve = Curve2D.new()

## 膨胀系数
@export_range(0.0,100.0) var delta = 0.0:
	set(value):
		delta = value
		emit_changed()

func _draw(to_canvas_item, rect):
	# 清理贝塞尔曲线上的所有点
	curve.clear_points()
	# 计算矩形中心
	var centre = rect.position + rect.size/2.0
	var tran = Transform2D(rotate,Vector2.ONE,0.0,centre).affine_inverse()
	
	var points:PackedVector2Array
	var colors:PackedColorArray
	for i in range(edge):
		var pos = Vector2(radius * cos(2 * PI * i / edge), radius * sin(2 * PI * i / edge))
		points.append(pos)
	
	var points_list = Geometry2D.offset_polygon(points,delta*-1,1)
	points_list = Geometry2D.offset_polygon(points_list[0],delta,1)
	points = points_list[0]
	points = points * tran
	for i in points:
		curve.add_point(i)
		
	points = curve.tessellate()
	
	var geo = Geometry2D.triangulate_delaunay(points)
	
	for i in points:
		colors.append(color)
	
	#RenderingServer.canvas_item_add_polygon(to_canvas_item,points,colors)
	RenderingServer.canvas_item_add_triangle_array(to_canvas_item,geo,points,colors)

