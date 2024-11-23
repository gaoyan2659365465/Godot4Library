extends Control

var 半径 = 5
var 颜色 = Color(1, 1, 1)

var 终点=Vector2.ZERO
func 更新骨骼末端(pos):
	终点 = pos
	# 长度越长，半径越大
	半径 = clamp(remap(终点.length(),0,500,5,10),5,10)
	self.queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO,半径,颜色,false,2,true)
	var 起点 = Vector2(半径+3,0).rotated(终点.angle())
	var 右点 = Vector2(半径*2+3,半径).rotated(终点.angle())
	var 左点 = Vector2(半径*2+3,-半径).rotated(终点.angle())
	var pos:PackedVector2Array = [起点,左点,终点,右点,起点]
	if 终点==Vector2.ZERO:
		return
	draw_colored_polygon(pos,颜色,pos)
	draw_polyline(pos,颜色,3,true)
