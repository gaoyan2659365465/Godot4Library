class_name PaintTool extends Node2D

@onready var drawing = $SubViewport/Drawing
@onready var drawing_2 = $SubViewport/Drawing2

@onready var viewport_pen = $SubViewport
@onready var pen_controller = $CanvasLayer/PenController


# 存储单独小画布
var sprites = []
# 用于记录笔迹的曲线路径
var path = null
# 用于记录当前帧执行了曲线的多少缓存点
var baked_index = 0
# 用于记录每帧旋转的img笔刷
var viewport_pen_imgs = []
# 当前是否可以进入绘制tick状态，上锁
var is_start_draw = false
# 是否画遮罩模式
var is_mask = false

func _ready():
	for i in range(4):
		for n in range(2):
			var sprite = self.createSprite()
			sprite.position = Vector2(i*512,n*512)
			self.sprites.append(sprite)
	
	# 创建5个图层
	for a in range(5):
		var uuid = UUID.v4()
		for sprite in self.sprites:
			sprite.addLayer(uuid)
		pen_controller.addLayer(a,uuid)

func _process(delta):
	if self.is_start_draw:
		if self.path:
			self.path.curve.add_point(get_local_mouse_position())
			self.drawPointsForCurve(drawing.size)
	

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				# 上锁，让tick进行等待
				self.is_start_draw = false
				self.path = Path2D.new()
				# 让曲线更细腻默认为5
				self.path.curve = Curve2D.new()
				self.path.curve.set_bake_interval(drawing.size.x/4.0)
				self.add_child(self.path)
				
				# 复制4份不同旋转的笔刷
				self.viewport_pen_imgs.clear()
				for i in range(4):
					var random_float = randf()*6.28
					drawing.material.set("shader_parameter/angle",random_float)
					drawing_2.material.set("shader_parameter/angle",random_float)
					var img = viewport_pen.get_texture().get_image()
					self.viewport_pen_imgs.append(img)
					await RenderingServer.frame_post_draw
				self.is_start_draw = true
			else:
				self.path.queue_free()
				self.path = null
				self.baked_index = 0
				# 上锁，让tick进行等待
				self.is_start_draw = false

# 创建单独小画布
func createSprite():
	var sprite = SpriteCanvasItem.new()
	self.add_child(sprite)
	return sprite

func setDrawingSize(value):
	drawing.size = Vector2(value,value)
	drawing_2.size = Vector2(value,value)
	viewport_pen.size = Vector2(value,value)

# 根据新图像的rect获取图集中符合的Sprite列表
func getSpriteForRect(new_rect):
	var list = []
	for i in self.sprites:
		var rect = i.get_rect()
		rect.position = i.position - rect.size/2.0
		if new_rect.intersects(rect,true):
			list.append(i)
	return list

# 绘制多图图像
func blend_rect(src: Image, src_rect: Rect2, dst: Vector2):
	# 计算新图像的rect
	var new_rect = Rect2(dst,src_rect.size)
	var spritslist = self.getSpriteForRect(new_rect)
	for i in spritslist:
		var rect:Rect2 = i.get_rect()
		rect.position = i.position - rect.size/2.0
		# 求当前子画布与新图像的交集
		var rect_clip = new_rect.intersection(rect)
		rect_clip.position = rect_clip.position.ceil()
		var local_rect_clip = Rect2(rect_clip.position - dst,rect_clip.size)
		var local_pos = rect_clip.position - rect.position
		i.blend_rect(src,local_rect_clip,local_pos,self.is_mask)

# 根据曲线缓存点每帧绘画点
func drawPointsForCurve(size):
	if self.path == null or self.is_start_draw == false:
		return
	# 笔刷图越大，频率应该越小
	var frequency = remap(clamp(size.x,0.0,30.0),0.0,30,80,10)
	# 由于每帧开销太大所以创建缓存笔迹图像
	var cache_img_size = Vector2(size.x*(frequency*2.0-1),size.y*(frequency*2.0-1))
	
	var cache_img = Image.create(cache_img_size.x,cache_img_size.y,false,Image.FORMAT_RGBA8)
	# 计算曲线缓存点的位置
	var baked_point = self.path.curve.get_baked_points()
	if baked_point.size() == 0:
		return
	if baked_point.size() <= self.baked_index:
		return
	
	var baked_pos = baked_point[self.baked_index]
	for i in range(frequency):
		if baked_point.size() == 0:
			break
		if baked_point.size() <= self.baked_index:
			break
		# 随机获取笔刷img
		var random_int = randi() % 4
		var img = self.viewport_pen_imgs[random_int]
		# 计算小图像的偏移
		var new_baked_pos = baked_point[self.baked_index]
		var baked_pos_offset = (new_baked_pos - baked_pos)+cache_img_size/2.0-img.get_size()/2.0
		cache_img.blend_rect(img,Rect2(Vector2.ZERO,img.get_size()),baked_pos_offset)
		self.baked_index = self.baked_index + 1
	self.blend_rect(cache_img,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)

# 设置笔刷颜色
func setColor(color):
	%Drawing.material.set("shader_parameter/color",color)
	%Drawing2.material.set("shader_parameter/color",color)


func _on_pen_controller_color_changed(color):
	setColor(color)

func _on_pen_controller_value_changed(value):
	%Drawing.size = Vector2(value,value)
	%Drawing2.size = Vector2(value,value)
	$SubViewport.size = Vector2(value,value)


func _on_pen_controller_item_selected(index):
	for i in sprites:
		i.select_layer_id = index

func _on_pen_controller_move_layer(uuids):
	for i in sprites:
		for uuid in uuids:
			for a in i.get_children():
				if uuid == a.get_meta("uuid"):
					i.move_child(a,0)


# 遮罩切换按钮
func _on_pen_controller_mask_toggled(toggled_on):
	self.is_mask = toggled_on

var images = []
# Tree右键菜单选项点击事件
func _on_pen_controller_menu_id_pressed(uuid, menu_id):
	if menu_id == 0:
		images.clear()
	var n = 0
	for i in sprites:
		var a = i.getSpriteForUUID(uuid)
		# 复制A通道
		if menu_id == 0:
			images.append(a.texture.get_image())
		# 粘贴到遮罩
		if menu_id == 1:
			var tex = a.material.get("shader_parameter/mask_img")
			var img2 = images[n]
			var img = Image.create(512,512,true,Image.FORMAT_RGBA8)
			img.fill(Color(0.0, 0.0, 0.0, 1.0))
			var img3 = Image.create(512,512,true,Image.FORMAT_RGBA8)
			img3.fill(Color(1.0, 1.0, 1.0, 1.0))
			img.blend_rect_mask(img3,img2,Rect2(Vector2.ZERO,img.get_size()),Vector2.ZERO)
			tex.update(img)
		n += 1
