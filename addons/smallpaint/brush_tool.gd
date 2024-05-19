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

# 编辑器覆盖层
var paint_overlay
# 选区遮罩图像
var selection_mask:Image = null
# 是否存在选区
var is_selection = false


func _ready() -> void:
	pass



func drawTick(pos) -> void:
	if self.is_start_draw:
		if self.path:
			self.path.curve.add_point(getPos(pos))
			self.drawPointsForCurve(self.drawing_size)

# 设置目标精灵图
func setTarget(target:Sprite2D):
	if target.texture as ImageTexture:
		self.target_sprite = target
		#var image_tex = ImageTexture.new()
		#image_tex.set_image(target.texture.get_image())
		#self.target_sprite.texture = image_tex
		self.target_image = target.texture.get_image()
	else:
		print("当前选中的精灵节点的图像类型不是ImageTexture")

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
			if not is_selection:
				# 锁定像素且无选区的情况
				var mask_rect = Rect2(Vector2.ZERO,cache_img_size)
				mask_rect.position = baked_pos-cache_img_size/2.0
				var mask = self.target_image.get_region(mask_rect)
				self.target_image.blend_rect_mask(cache_img,mask,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)
			else:
				# 锁定像素且有选区的情况
				var mask_rect = Rect2(Vector2.ZERO,cache_img_size)
				mask_rect.position = baked_pos-cache_img_size/2.0
				var mask = self.target_image.get_region(mask_rect)
				var _mask = self.selection_mask.get_region(mask_rect)
				_mask.blend_rect_mask(mask,_mask,Rect2(Vector2.ZERO,cache_img_size),Vector2.ZERO)
				self.target_image.blend_rect_mask(cache_img,_mask,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)
		else:
			if not is_selection:
				# 无锁定像素且无选区的情况
				self.target_image.blend_rect(cache_img,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)
			else:
				# 无锁定像素且有选区的情况
				var mask_rect = Rect2(Vector2.ZERO,cache_img_size)
				mask_rect.position = baked_pos-cache_img_size/2.0
				var _mask = self.selection_mask.get_region(mask_rect)
				self.target_image.blend_rect_mask(cache_img,_mask,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)

	elif tool_mode == 1:
		# 如果是橡皮模式
		var mask = cache_img.get_region(Rect2(Vector2.ZERO,cache_img_size))
		cache_img.fill(Color(1, 1, 1, 0))
		self.target_image.blit_rect_mask(cache_img,mask,Rect2(Vector2.ZERO,cache_img_size),baked_pos-cache_img_size/2.0)
	self.target_sprite.texture.update(self.target_image)

# 视口坐标转场景坐标
func getPos(pos:Vector2i):
	var tran = self.target_sprite.get_viewport_transform()
	var _size = self.target_sprite.texture.get_size()
	return Vector2i(tran.affine_inverse() * Vector2(pos) + _size/2.0 - self.target_sprite.position)

# 判断c与seed_color颜色的距离
func are_colors_similar(c:Color,seed_color:Color) -> bool:
	var r = c.r - seed_color.r
	var g = c.g - seed_color.g
	var b = c.b - seed_color.b
	var a = c.a - seed_color.a
	return r*r + g*g + b*b + a*a <= 0.01

# 洪水填充算法实现魔棒工具
func floodFill(seed_pos:Vector2i):
	seed_pos = getPos(seed_pos)
	var img_size = self.target_image.get_size()
	var img = self.target_image
	selection_mask = Image.create(img_size.x,img_size.y,false,Image.FORMAT_RGBA8)
	selection_mask.fill(Color(0,0,0,0))
	var fill_color = Color(1,0,0,1)
	
	# 判断是否越界
	if not Rect2(Vector2.ZERO,img_size).has_point(seed_pos):
		return
	
	var ww = img_size.x - 1
	var hh = img_size.y - 1
	# 获取种子颜色
	var seed_color = img.get_pixelv(seed_pos)
	var cache = [seed_pos]
	var flag = {}

	var index = 0
	while index < cache.size():
		var p = cache[index]
		flag[p] = true
		selection_mask.set_pixelv(p,fill_color)
		# 判断四周像素颜色与种子颜色是否一致
		# 判断像素是否已经标记过
		var l = p-Vector2i(1,0)
		var r = p+Vector2i(1,0)
		var u = p-Vector2i(0,1)
		var d = p+Vector2i(0,1)
		if not flag.get(l,false):
			flag[l] = true
			if p.x > 0 && are_colors_similar(img.get_pixelv(l),seed_color):
				cache.push_back(l)
		if not flag.get(r,false):
			flag[r] = true
			if p.x < ww && are_colors_similar(img.get_pixelv(r),seed_color):
				cache.push_back(r)
		if not flag.get(u,false):
			flag[u] = true
			if p.y > 0 && are_colors_similar(img.get_pixelv(u),seed_color):
				cache.push_back(u)
		if not flag.get(d,false):
			flag[d] = true
			if p.y < hh && are_colors_similar(img.get_pixelv(d),seed_color):
				cache.push_back(d)
		index += 1
	# 进入选区模式，绘画和橡皮擦都将会受到影响
	self.is_selection = true
	return selection_mask

# 从剪切板复制图像
func copyImageFromClipboard():
	if DisplayServer.clipboard_has_image():
		var clipboard_img = DisplayServer.clipboard_get_image()
		clipboard_img.convert(Image.FORMAT_RGBA8)
		self.target_sprite.texture = ImageTexture.create_from_image(clipboard_img)
		self.target_image = self.target_sprite.texture.get_image()
		
# 创建魔棒工具控件
func createMagicWandTool(overlay:Control,img_mask):
	if paint_overlay:
		paint_overlay.queue_free()
	paint_overlay = preload("res://addons/smallpaint/paint_overlay.tscn").instantiate()
	overlay.add_child(paint_overlay)
	paint_overlay.setImage(self.target_sprite,img_mask)
	
# 初始化魔棒工具
func initMagicWandTool():
	self.is_selection = false
	if paint_overlay:
		paint_overlay.queue_free()
