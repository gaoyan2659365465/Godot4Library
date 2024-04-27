@tool
class_name BrushTool extends Node

var target_sprite:Sprite2D = null
var target_image:Image = null

# 用于记录笔迹的曲线路径
var path = null
# 用于记录当前帧执行了曲线的多少缓存点
var baked_index = 0
# 用于记录每帧旋转的img笔刷
var viewport_pen_imgs = []
# 当前是否可以进入绘制tick状态，上锁
var is_start_draw = false
# 笔刷尺寸
var drawing_size = Vector2(50,50)

# 画笔还是橡皮
var tool_mode = 0
# 颜色
var brush_color = Color.WHITE
# 是否锁定像素
var is_lock_pixel = false



func _ready() -> void:
	pass



func drawTick(pos) -> void:
	if self.is_start_draw:
		if self.path:
			var tran = self.target_sprite.get_viewport_transform()
			var _size = self.target_sprite.texture.get_size()
			self.path.curve.add_point(tran.affine_inverse() * pos + _size/2.0 - self.target_sprite.position)
			self.drawPointsForCurve(self.drawing_size)

# 设置目标精灵图
func setTarget(target:Sprite2D):
	self.target_sprite = target
	var image_tex = ImageTexture.new()
	image_tex.set_image(target.texture.get_image())
	self.target_sprite.texture = image_tex
	self.target_image = target.texture.get_image()

# 绘画开始
func drawStart():
	# 上锁，让tick进行等待
	self.is_start_draw = false
	self.path = Path2D.new()
	# 让曲线更细腻默认为5
	self.path.curve = Curve2D.new()
	self.path.curve.set_bake_interval(self.drawing_size.x/4.0)
	self.add_child(self.path)
	
	# 复制4份不同旋转的笔刷
	self.viewport_pen_imgs.clear()
	for i in range(4):
		var img_tex = preload("res://addons/smallpaint/round.tres")
		var img = img_tex.get_image()
		img.resize(drawing_size.x,drawing_size.y)
		var new_img = img.get_region(Rect2(Vector2.ZERO,img.get_size()))
		new_img.fill(self.brush_color)
		img.blit_rect_mask(new_img,img,Rect2(Vector2.ZERO,img.get_size()),Vector2.ZERO)
		self.viewport_pen_imgs.append(img)
		await RenderingServer.frame_post_draw
	self.is_start_draw = true

# 绘画结束
func drawEnd():
	if self.path:
		self.path.queue_free()
		self.path = null
	self.baked_index = 0
	# 上锁，让tick进行等待
	self.is_start_draw = false

# 根据曲线缓存点每帧绘画点
func drawPointsForCurve(size):
	if self.path == null or self.is_start_draw == false:
		return
	# 笔刷图越大，频率应该越小
	var frequency = remap(clamp(size.x,0.0,30.0),0.0,30,80,10)
	# 由于每帧开销太大所以创建缓存笔迹图像
	var cache_img_size = Vector2(size.x*frequency*0.5,size.y*frequency*0.5)
	
	var cache_img = Image.create(cache_img_size.x,cache_img_size.y,false,Image.FORMAT_RGBA8)
	# 计算曲线缓存点的位置
	var baked_point = self.path.curve.get_baked_points()
	if baked_point.size() == 0:
		return
	if baked_point.size() <= self.baked_index:
		return
	
	var baked_pos = baked_point[self.baked_index]
	for i in range(frequency):
		if baked_point.size() <= self.baked_index:
			break
		# 随机获取笔刷img
		var random_int = randi() % 4
		var img = self.viewport_pen_imgs[random_int]
		# 计算小图像的偏移
		var new_baked_pos = baked_point[self.baked_index]
		var baked_pos_offset = (new_baked_pos - baked_pos)+cache_img_size/2.0-img.get_size()/2.0
		cache_img.blend_rect(img,Rect2(Vector2.ZERO,img.get_size()),baked_pos_offset)
		self.baked_index += 1
	
	if tool_mode == 0:
		# 如果是画笔模式
		# 是否锁定像素
		if self.is_lock_pixel:
			var mask_rect = Rect2(Vector2.ZERO,cache_img_size)
			mask_rect.position = baked_pos-cache_img_size/2.0
			var mask = self.target_image.get_region(mask_rect)
			self.target_image.blend_rect_mask(cache_img,mask,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)
		else:
			self.target_image.blend_rect(cache_img,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)
		
	elif tool_mode == 1:
		# 如果是橡皮模式
		var mask = cache_img.get_region(Rect2(Vector2.ZERO,cache_img_size))
		cache_img.fill(Color(1, 1, 1, 0))
		self.target_image.blit_rect_mask(cache_img,mask,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)
	self.target_sprite.texture.update(self.target_image)
