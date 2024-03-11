class_name SpriteCanvasItem extends Sprite2D

# 画布拆分出来的小画布，能显示多张Image

# 图层用于存储多个Image
var layer = []
# 选中图层索引
var select_layer_id = 0
# 遮罩材质
var mask_material = preload("res://PaintTool/mask_material.tres")

func _ready():
	# 主要为了获取尺寸
	var img = Image.create(512,512,true,Image.FORMAT_RGBA8)
	self.texture = ImageTexture.create_from_image(img)

# 新建图层
func addLayer(uuid):
	var sprite = Sprite2D.new()
	var _mask_material = mask_material.duplicate()
	var mask_img = Image.create(512,512,true,Image.FORMAT_RGBA8)
	mask_img.fill(Color(1.0, 1.0, 1.0, 1.0))
	_mask_material.set("shader_parameter/mask_img",ImageTexture.create_from_image(mask_img))
	sprite.set_material(_mask_material)
	add_child(sprite)
	move_child(sprite,0)
	var img = Image.create(512,512,true,Image.FORMAT_RGBA8)
	#img.fill(Color(randf(), randf(), randf()))
	#img.fill(Color(1.0, 1.0, 1.0, 0.0))
	sprite.texture = ImageTexture.create_from_image(img)
	layer.append(sprite)
	sprite.set_meta("uuid",uuid)
	return img

# 根据UUID查找图层
func getSpriteForUUID(uuid):
	for i in self.get_children():
		if uuid == i.get_meta("uuid"):
			return i

# 获取选中图层
func getSelectLayer():
	return layer[select_layer_id]

# 绘制某图层
func blend_rect(src: Image, src_rect: Rect2i, dst: Vector2i, is_mask:bool=false):
	var sprite = getSelectLayer()
	var img = sprite.texture.get_image()
	# 遮罩模式
	if is_mask:
		var tex = sprite.material.get("shader_parameter/mask_img")
		img = tex.get_image()
	
	img.blend_rect(src,src_rect,dst)
	if is_mask:
		var tex = sprite.material.get("shader_parameter/mask_img")
		tex.update(img)
	else:
		sprite.texture.update(img)
	return img
