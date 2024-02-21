extends Control


@onready var color_rect = $ColorRect
@onready var color_rect_2 = $ColorRect2
@onready var canvas_layer = $CanvasLayer

var w_tran
var widget

func _ready():
	self.w_tran = TransformTool.new()
	self.canvas_layer.add_child(self.w_tran)
	self.w_tran.connect("resized",Callable(self,"_on_TransformTool_resized"))
	
	# 初始化变换框控件位置尺寸
	self.widget = self.color_rect
	self.w_tran.setWidgetRect(self.widget.get_rect())

func _on_TransformTool_resized():
	var rect = self.w_tran.get_rect()
	self.widget.position = rect.position + Vector2(20,20)
	self.widget.size = rect.size - Vector2(40,40)


# 切换按钮
func _on_button_pressed():
	if self.widget == self.color_rect:
		self.widget = self.color_rect_2
	else:
		self.widget = self.color_rect
	self.w_tran.setWidgetRect(self.widget.get_rect())
