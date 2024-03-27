class_name BackpackPanel extends Control

@onready var grid: GridContainer = $GridContainer


# 背包尺寸
var widget = 5
var height = 5

# 背包二维数组
var grid_list = []
 # 物品拖拽背包的合法性检查
var is_legal = -1

func _ready() -> void:
	# 初始化背包二维数组
	self.grid_list = self.createGridList()
	# 创建格子控件
	self.createGridItem()
	
	

# 创建二维数组表示背包
func createGridList():
	var _grid_list = []
	for i in range(self.widget):
		var _list = []
		for n in range(self.height):
			_list.append(0)
		_grid_list.append(_list)
	return _grid_list

# 创建新格子
func createGridItem():
	# 删除所有默认格子
	for i in range(grid.get_child_count()):
		grid.remove_child(grid.get_child(0))
	# 创建新格子
	for i in range(self.widget * self.height):
		var backpack_item = preload("res://Backpack/grid_item.tscn").instantiate()
		grid.add_child(backpack_item)

# 两个二维数组相加
func addGridList(grid_a,grid_b):
	# 创建一个空的二维数组
	var _grid = createGridList()
	for i in range(self.widget):
		for a in range(self.height):
			_grid[i][a] = grid_a[i][a] + grid_b[i][a]
	return _grid

# 两个二维数组相减
func subGridList(grid_a,grid_b):
	# 创建一个空的二维数组
	var _grid = createGridList()
	for i in range(self.widget):
		for a in range(self.height):
			_grid[i][a] = grid_a[i][a] - grid_b[i][a]
			if _grid[i][a] < 0:
				print_debug("Error:数组相减小于0")
	return _grid

# 判断背包二维数组否合法，如大于1的情况
func legal(grid):
	for i in grid:
		for n in i:
			if n > 1:
				return false
	return true

# 清空所有高亮
func cleanHighlight():
	for n:GridItem in grid.get_children():
		n.setHighlight(false)

# 判断鼠标处于格子的二维数组索引
func getMouseIndex():
	var mouse_pos = get_global_mouse_position() - grid.position
	for n:GridItem in grid.get_children():
		if n.get_rect().has_point(mouse_pos-Vector2(0,50)):
			var a = n.get_index()
			return [a%self.widget,a/self.widget]
	return []

# 根据二维数组的索引获取格子引用
func getGridItemForIndex(index):
	var _list = []
	var a = 0
	var b = 0
	for i in index:
		b = 0
		for n in i:
			if n != 0:
				var c = a * self.widget + b
				_list.append(grid.get_children()[c])
			b += 1
		a += 1
	return _list


func _on_back_pack_item_drag_start(target: Variant) -> void:
	if target.old_grid_list != []:
		self.grid_list = subGridList(self.grid_list,target.old_grid_list)

func _on_back_pack_item_drag(target: Variant) -> void:
	var mouse_index = getMouseIndex()
	if mouse_index == []:
		return
	self.is_legal = -1
	
	var _grid = createGridList()
	for i in target.pos:
		var a1 = i[1]+mouse_index[1]
		var b1 = i[0]+mouse_index[0]
		if a1 >= self.widget or b1 >= self.height:
			# 物品能沾到背包边缘，即使是红色非法情况
			self.is_legal = 2
			break
		_grid[a1][b1] = 1
	
	# 根据背包的二维数组判断当前位置是否合法
	var new_grid = addGridList(self.grid_list,_grid)
	if self.legal(new_grid):
		if self.is_legal != 2:
			self.is_legal = 0
	else:
		self.is_legal = 1
	
	if self.is_legal == 0:
		target.grid_list = _grid
	elif self.is_legal == 1 or self.is_legal == 2:
		# 如果不合法就回到老位置
		target.grid_list = target.old_grid_list
	
	cleanHighlight()
	for i in getGridItemForIndex(_grid):
		i.setHighlight(true,is_legal)

func _on_back_pack_item_drag_end(target: Variant) -> void:
	cleanHighlight()
	# 表示物品拖拽到背包边缘不合法的情况
	if self.is_legal == 2:
		target.setFreeze(false)
	# 获取鼠标指向的二维数组索引
	var mouse_index = getMouseIndex()
	if mouse_index == []:
		target.grid_list = []
		target.old_grid_list = []
		target.setFreeze(false)
		return
	
	# 根据二维数组确定位置
	var grid_item = getGridItemForIndex(target.grid_list)
	if grid_item.size() > 0:
		target.position = grid_item[0].position - target.offset + grid.position
	# 更新当前背包的二维数组
	if target.grid_list != []:
		self.grid_list = addGridList(self.grid_list,target.grid_list)
	for i in self.grid_list:
		print(i)
	
	# 存储老位置
	target.old_grid_list = target.grid_list
