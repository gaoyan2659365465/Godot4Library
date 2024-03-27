class_name GridItem extends TextureRect

@onready var ui_2: TextureRect = $Ui2


# 设置选择高亮
func setHighlight(value:bool=true,type=0):
	if type == 0:
		self.set("modulate",Color(1.0,1.0,1.0,1.0))
	elif type >= 1:
		self.set("modulate",Color(1.0,0.0,0.0,1.0))
	ui_2.visible = value
