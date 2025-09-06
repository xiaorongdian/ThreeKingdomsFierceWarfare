extends Control

var astar_grid = AStarGrid2D.new()
#路径一组坐标
var path:PackedVector2Array
#阻塞列表
var solids = [] # 障碍物列表
#移动距离
var max_step:int = 16

var can_walk_rect:Rect2i
#一组坐标点
var can_walk_points:PackedVector2Array 

@onready var icon = $Icon
var speed = 200.0
#正在移动
var can_walk = false
#目的位置
var target_pos:Vector2


func _process(delta):
	if can_walk:
		if path.size()>0:
			target_pos = path[0]
			if icon.position.distance_to(target_pos)>0:
				icon.position = icon.position.move_toward(target_pos,speed * delta)
			else:
				path.remove_at(0)
				queue_redraw()
		else:
			can_walk = false
			queue_redraw()


func _ready():
	randomize()
	astar_grid.size = Vector2i.ONE * 32
	astar_grid.cell_size = Vector2i.ONE * 32
	astar_grid.offset = astar_grid.cell_size/2
	icon.position = astar_grid.cell_size/2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

	astar_grid.update()
	
	# 随机生成障碍
	for i in range(150):
		var solid_point = Vector2i(randi_range(0,astar_grid.size.x-1),randi_range(0,astar_grid.size.y-1))
		astar_grid.set_point_solid(solid_point,true)
		solids.append(solid_point)


func _draw():
	var grid_width = astar_grid.size.x * astar_grid.cell_size.x
	var cell_width = astar_grid.cell_size.x
	var cell_height = astar_grid.cell_size.y
	# 绘制网格
	for i in range(astar_grid.size.x):
		draw_line(i * Vector2i(0,cell_height),i * Vector2i(grid_width,cell_height),Color.DARK_OLIVE_GREEN,2)
	for j in range(astar_grid.size.y):
		draw_line(j * Vector2i(cell_height,0),j * Vector2i(cell_height,grid_width),Color.DARK_OLIVE_GREEN,2)
	
	# 绘制路径和其上的点
	if path.size() > 0:
		for pot in path:
			draw_circle(pot,5,Color.YELLOW)
		# 修复：检查点数量是否足够绘制折线
		if path.size() >= 2:
			# 只有至少2个点时才绘制折线
			draw_polyline(path, Color.YELLOW, 2)  # 原第62行
		elif path.size() == 1:
			# 只有1个点时，绘制一个圆点表示
			draw_circle(path[0], 5, Color.YELLOW)
	# 绘制障碍物
	for p in solids:
		draw_rect(Rect2(p * Vector2i(astar_grid.cell_size),astar_grid.cell_size),Color.GRAY)
	# 绘制可行走范围
	# 遍历矩形
	if !can_walk:
		var player_pos = floor(icon.position/astar_grid.cell_size)
		var top_left = clamp(player_pos - Vector2.ONE * max_step,Vector2.ZERO,player_pos)
		var end =  clamp(player_pos + Vector2.ONE * max_step,player_pos,Vector2(astar_grid.size))
		can_walk_rect = Rect2(top_left,end-top_left) # 获取矩形
		for i in range(can_walk_rect.position.x,can_walk_rect.end.x + 1):
			for j in range(can_walk_rect.position.y,can_walk_rect.end.y + 1):
				if(i < 0 || j < 0 || i > 31 || j > 31):
					continue
				var v = Vector2(i,j)
				if astar_grid.get_point_path(player_pos,v).size() <= max_step+1:
					if !astar_grid.is_point_solid(v):
						can_walk_points.append(v)
						draw_rect(Rect2(v * astar_grid.cell_size,astar_grid.cell_size),Color.YELLOW_GREEN,false,2)
	
	
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				can_walk = true
				var player_pos = floor(icon.position/astar_grid.cell_size)
				var targ_pos = floor(get_global_mouse_position()/astar_grid.cell_size)
				if targ_pos in can_walk_points: # 如果在可行走的范围内
					path = astar_grid.get_point_path(player_pos,targ_pos)
					can_walk_points.clear() # 清空原来的可行走范围
					queue_redraw()
