extends Control

@onready var line_2d: Line2D = $Line2D



func 初始化(value:PackedVector2Array):
	line_2d.points = value
