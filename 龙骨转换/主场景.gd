extends Node2D


"""
注意事项
1、在龙骨中最好不要把网格直接放到骨骼里，图片的话随意（龙骨中网格不受骨骼影响但godot会）
2、不兼容龙骨IK
3、未知BUG，个别网格会有微小偏移

使用说明
运行一次后关闭即可，会自动保存场景数据
"""
@onready var node_2d: Node2D = $Node2D

var 图片路径 = "res://龙骨转换/Rooster_Ani_texture/"
var json路径 = "res://龙骨转换/Rooster_Ani_ske.json"

func _ready() -> void:
	var json = load(json路径)
	var bones = json.data['armature'][0]['bone']
	var k = Skeleton2D.new()
	k.name = "Skeleton2D"
	node_2d.add_child(k)
	k.owner = node_2d
	
	var s:Dictionary = {}
	for i in bones:
		#print(i['name'])
		var b = Bone2D.new()
		b.set_autocalculate_length_and_angle(false)
		b.rest = Transform2D(Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(0, 0))
		s[i['name']] = b
		b.name = i['name']
		if i.has('parent'):
			s[i['parent']].add_child(b)
			
			if i.has('length'):
				b.set_length(i['length'])
		
			if i.has('transform'):
				if i.has('inheritRotation'):
					if i['inheritRotation']:
						pass
					else:
						if i['transform'].has('skX'):
							b.global_rotation_degrees = i['transform']['skX']# 因为龙骨的坐标系跟godot的不同
							#b.set_bone_angle(b.rotation)
				else:
					if i['transform'].has('skX'):
						b.rotation_degrees = i['transform']['skX']# 因为龙骨的坐标系跟godot的不同
						#b.set_bone_angle(b.rotation)
				var pos = Vector2.ZERO
				if i['transform'].has('x'):
					pos.x = i['transform']['x']
				if i['transform'].has('y'):
					pos.y = i['transform']['y']
				b.position = pos
				b.rest = Transform2D(b.rotation, Vector2(b.position.x, b.position.y))
				
		else:
			k.add_child(b)#说明是root骨骼
		b.owner = node_2d
	
	
	var skins = json.data['armature'][0]['skin']
	skins = skins[0]['slot']
	
	var 插槽 = json.data['armature'][0]['slot']#插槽顺序
	for _c in 插槽:
		if _c["parent"] == "mesh":# 找到网格
			var _n = _c["name"]
			for sk in skins:
				if sk["name"] == _n:
					创建网格(json,k,s,sk)
	
	
	for sk in skins:
		# 判断有没有"display",排除空的插槽
		if not sk.has("display"):
			continue
		# 如果有"type",说明是网格而不是图片
		if sk['display'][0].has("type"):
			continue
		# 如果有"path",说明改名了
		var _p = ""# 这是图片资源路径
		if sk['display'][0].has("path"):
			_p = sk['display'][0]['path']
		else:
			_p = sk['display'][0]['name']
		
		var _n = sk['name']# 这是插槽名
		var _sprite = Sprite2D.new()
		_sprite.texture = load(图片路径+ _p +".png")
		_sprite.name = _n
		# 寻找父项
		var _slot = json.data['armature'][0]['slot']
		var _parent
		for i in _slot:
			if i['name'] == _n:
				_parent = s[i['parent']]# s是所有骨骼引用字典，需要找到指定骨骼并赋予子项
		if _parent:
			_parent.add_child(_sprite)
			#_sprite.z_index = 1
		else:
			print("警告：未找到该图片的父层级骨骼")
		_sprite.owner = node_2d
		var pos = Vector2.ZERO
		var _tran = sk['display'][0]['transform']
		if _tran.has("x"):
			pos.x = _tran["x"]
		if _tran.has("y"):
			pos.y = _tran["y"]
		_sprite.position = pos
		
		# 设置图片旋转
		if _tran.has("skX"):
			_sprite.rotation_degrees = _tran["skX"]
	
	# 骨架里可能有一些图片，防止被网格遮挡
	node_2d.move_child(k,-1)
	
	创建动画(json,k,s)
	
	var scene = PackedScene.new()
	scene.pack(node_2d)
	ResourceSaver.save(scene,"res://龙骨转换/保存数据.tscn")

func parse_weights(data: Array) -> Array:
	var result = []
	var i = 0

	while i < data.size():
		var num_bones = data[i]  # 当前点参与的骨骼数量
		var bones_and_weights = []
		i += 1  # 移动到骨骼号

		# 遍历每个骨骼号和对应的权重
		for _i in range(num_bones):
			var bone_id = data[i]
			var weight = data[i + 1]
			bones_and_weights.append({"bone_id": bone_id, "weight": weight})
			i += 2  # 每个骨骼号和权重占用2个位置

		# 将解析后的骨骼和权重加入结果
		result.append(bones_and_weights)
	return result


		
func 创建网格(json,k,s,sk):
	# 如果有"path",说明改名了
	var _p = ""# 这是图片资源路径
	if sk['display'][0].has("path"):
		_p = sk['display'][0]['path']
	else:
		_p = sk['display'][0]['name']
	
	var _n = sk['name']# 这是插槽名
	var _poly = Polygon2D.new()
	_poly.texture = load(图片路径+ _p +".png")
	_poly.name = _n
	# 寻找父项
	var _slot = json.data['armature'][0]['slot']
	var _parent
	for i in _slot:
		if i['name'] == _n:
			_parent = s[i['parent']]# s是所有骨骼引用字典，需要找到指定骨骼并赋予子项
	if _parent:
		_parent.add_child(_poly)
		#_poly.top_level = true# 因为龙骨的网格如果在骨骼层级下，不会受到骨骼影响，但是godot会，所以尽量不要把网格放骨骼里
		# 开启会导致层级错乱，需要手动调整
	else:
		print("警告：未找到该图片的父层级骨骼")
	_poly.owner = node_2d
	var points:PackedVector2Array = []
	var _ver = sk['display'][0]['vertices']
	for i in range(0, _ver.size(), 2):
		points.append(Vector2(_ver[i],_ver[i+1]))
	_poly.polygon = points
	
	var uvs:PackedVector2Array = []
	var _uvs = sk['display'][0]['uvs']
	var _uvw = sk['display'][0]['width']
	var _uvh = sk['display'][0]['height']
	for i in range(0, _uvs.size(), 2):
		uvs.append(Vector2(_uvs[i]*_uvw,_uvs[i+1]*_uvh))
	_poly.uv = uvs
	
	var trianles = []
	var _triangles = sk['display'][0]['triangles']
	for i in range(0, _triangles.size(), 3):
		var _t = []
		_t.push_back(_triangles[i])
		_t.push_back(_triangles[i+1])
		_t.push_back(_triangles[i+2])
		trianles.push_back(_t)
	_poly.polygons = trianles
	
	_poly.skeleton = _poly.get_path_to(k)
	
	var weights = sk['display'][0]['weights']
	var _weights = parse_weights(weights)
	
	var new_bones = []
	var _sn = 0
	# 遍历所有骨骼
	for i in s:
		#var 骨骼号 = s[i].get_index_in_skeleton()
		
		new_bones.append(k.get_path_to(s[i]))
		var new_qz:PackedFloat32Array = []
		for a in range(_poly.polygon.size()):# a是遍历的当前点号
			var 权重 = 0.0
			# 找到所有当前骨骼当前点的权重
			for ii in _weights[a]:
				if ii['bone_id'] == _sn:
					权重 = ii['weight']
			new_qz.append(权重)
		new_bones.append(new_qz)
		_sn += 1
		
	_poly.bones = new_bones	


func 创建动画(json,k,s):
	var 帧数 = 24.0
	
	var animplay = AnimationPlayer.new()
	node_2d.add_child(animplay)
	animplay.owner = node_2d
	animplay.name = "AnimationPlayer"
	
	var al = AnimationLibrary.new()
	
	var lg_anim = json.data['armature'][0]['animation']
	for i in lg_anim:
		var 时长 = i["duration"]/帧数
		var 动画名 = i["name"]
		var 骨骼数据 = i["bone"]
		var animation = Animation.new()
		animation.set_length(时长)
		for g in 骨骼数据:
			var 骨名 = g["name"]
			if g.has("translateFrame"):
				# 获取当前骨骼的原始变换
				var 原始变换 = s[骨名].position
				
				var 变换帧 = g["translateFrame"]
				#变换帧.reverse()# 倒序
				var 末尾零帧 = 变换帧.pop_back()
				变换帧.push_front(末尾零帧)
				var 骨路径 =  str(node_2d.get_path_to(s[骨名])) + ":position"
				var track_index = animation.add_track(Animation.TYPE_VALUE)# 添加轨道
				animation.track_set_path(track_index, 骨路径)
				var 延迟 = 0.0
				for _t in 变换帧:
					if not _t.has("duration"):
						延迟 += 1.0/帧数
					else:
						延迟 += _t["duration"]/帧数
					var 变换值 = Vector2.ZERO
					if _t.has("x"):
						变换值.x = 原始变换.x + _t["x"]
					else:
						变换值.x = 原始变换.x
					if _t.has("y"):
						变换值.y = 原始变换.y + _t["y"]
					else:
						变换值.y = 原始变换.y
					animation.track_insert_key(track_index,延迟, 变换值)
			if g.has("rotateFrame"):
				# 获取当前骨骼的旋转值，单位度数
				var 原始旋转值 = s[骨名].rotation_degrees
				
				var 旋转帧 = g["rotateFrame"]
				#旋转帧.reverse()# 倒序
				var 末尾零帧 = 旋转帧.pop_back()
				旋转帧.push_front(末尾零帧)
				var 骨路径 =  str(node_2d.get_path_to(s[骨名])) + ":rotation"
				var track_index = animation.add_track(Animation.TYPE_VALUE)# 添加轨道
				animation.track_set_path(track_index, 骨路径)
				var 延迟 = 0.0
				for _r in 旋转帧:
					if not _r.has("duration"):
						延迟 += 1.0/帧数
					else:
						延迟 += _r["duration"]/帧数
					var 旋转值 = 0
					if _r.has("rotate"):
						旋转值 = 原始旋转值 + _r["rotate"]
					else:
						旋转值 = 原始旋转值
					
					animation.track_insert_key(track_index,延迟, deg_to_rad(旋转值))
	
		al.add_animation(动画名,animation)
	var anim_library_name = json.data['name']
	animplay.add_animation_library(anim_library_name,al)
