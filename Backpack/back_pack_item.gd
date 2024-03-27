class_name BackPackItem extends RigidBody2D


@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var item_shadow: TextureRect = $ItemTexture/ItemShadow
@onready var grid_container: GridContainer = $GridContainer

# 定位格子列表
@export var pos = [[0,0],[0,1]]
# 物品左上角与中心的偏移
var offset = Vector2.ZERO

# 表示当前物品位置的二维数组
var grid_list = []
var old_grid_list = []

# 是否拿起
var is_pick_up = false


# 拖拽信号
signal drag(target)
signal drag_start(target)
signal drag_end(target)


func _ready() -> void:
	# 初始化偏移
	offset = grid_container.position

# 放进背包时取消物理和碰撞
func setFreeze(value:bool):
	self.freeze = value
	# 在背包中应该暂时忽视碰撞
	collision_shape_2d.disabled = value

# 旋转值为0
func playAnim():
	var tween = create_tween()
	tween.tween_property(self,"rotation",0,0.2)

# 阴影偏移
func playAnim2(value:bool):
	var tween = create_tween()
	var pos = Vector2.ZERO
	if value:
		pos = Vector2(30,30)
	else:
		pos = Vector2(5,5)
	tween.tween_property(item_shadow,"position",pos,0.2)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if not self.is_pick_up:
			return
		position = get_global_mouse_position()
		emit_signal("drag",self)

func _on_texture_button_button_down() -> void:
	self.is_pick_up = true
	self.setFreeze(true)
	# 旋转值为0
	self.playAnim()
	self.playAnim2(true)
	emit_signal("drag_start",self)

func _on_texture_button_button_up() -> void:
	self.is_pick_up = false
	self.playAnim2(false)
	emit_signal("drag_end",self)
