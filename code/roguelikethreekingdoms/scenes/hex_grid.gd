extends Node2D
#图层z-index值
#玩家 2
#山脉 3
#可行走地图 0


#移动速度
@export var move_speed: float = 200.0
#阈值
@export var arrival_threshold: float = 1.0 # Smaller threshold for precise center alignment

@onready var walkable_map: TileMapLayer = $walkable_map
@onready var gamer_manager: Node2D = $GamerManager

#目标位置
var target_position: Vector2
#路径一组坐标点
var path: PackedVector2Array

#高亮颜色
const HIGHLIGHT_COLOR = Color(1, 0.5, 0.5, 0.7)

#画一个多边形高亮用来鼠标经过地图显示 多边形实心
#var hover_effect: Polygon2D
var hover_effect: Line2D #多边形空心

#画N个多边形高亮用来显示移动范围
var move_range_show: Array[Polygon2D] = []

#当前选中角色
var now_selected_gamer: Gamer

#当前经过角色
var now_hover_gamer: Gamer


func _ready():
	#把一个多边形加入到树中
	setup_hover_polygon()


func _process(_delta):
	#处理鼠标经过高亮
	handle_hover_effect()


#鼠标移上去效果
func setup_hover_polygon() -> void:
	#多边形
	#hover_effect = Polygon2D.new()
	#hover_effect.polygon = PackedVector2Array([
		#Vector2(0, -16), 
		#Vector2(-32, -8), 
		#Vector2(-32, 11), 
		#Vector2(0, 19), 
		#Vector2(32, 11), 
		#Vector2(32, -8)
	#])
	# 1. 定义多边形顶点（示例：六边形）
	hover_effect = Line2D.new()
	var hexagon_points = [
		Vector2(0, -16), 
		Vector2(-32, -8), 
		Vector2(-32, 11), 
		Vector2(0, 19), 
		Vector2(32, 11), 
		Vector2(32, -8)
	]
	hover_effect.points = hexagon_points
	# 2. 闭合路径形成多边形
	hover_effect.closed = true
	# 3. 自定义空心样式
	hover_effect.width = 2  # 线宽3像素
	hover_effect.joint_mode = Line2D.LINE_JOINT_ROUND  # 拐角圆角处理
	hover_effect.begin_cap_mode = Line2D.LINE_CAP_ROUND    # 端点圆角处理（闭合多边形时端点不明显）
	hover_effect.end_cap_mode = Line2D.LINE_CAP_ROUND    # 端点圆角处理（闭合多边形时端点不明显）
	hover_effect.default_color = Color(0, 191, 255, 0.8)
	hover_effect.visible = true
	hover_effect.z_index = 0
	add_child(hover_effect)


#处理鼠标经过高亮
func handle_hover_effect() -> void:
	#鼠标坐标
	var mouse_pos = get_local_mouse_position()
	#鼠标坐标转单元格
	var mouse_tile = walkable_map.local_to_map(mouse_pos)
	#可用网格
	var used_cells = walkable_map.get_used_cells()

	if used_cells.has(mouse_tile):
		#转换网格到坐标
		var local_pos = walkable_map.map_to_local(mouse_tile)
		hover_effect.position = local_pos
		hover_effect.visible = true
	else:
		hover_effect.visible = false


#显示角色移动范围
func show_walk_height_tile(gamer:Gamer):
	#先清一下
	disable_walk_height_tile(gamer)
	var blocked_tiles = get_blocked_tiles()
	#获取移动范围全部单元格
	var walk_range = GlobalUtils.find_range(gamer, walkable_map, blocked_tiles, gamer_manager)
	
	for i in walk_range:
		#转换网格到坐标
		var local_pos = walkable_map.map_to_local(i)
		#多边形
		var hover_effect = Polygon2D.new()
		hover_effect.polygon = PackedVector2Array([
			Vector2(0, -16), 
			Vector2(-32, -8), 
			Vector2(-32, 11), 
			Vector2(0, 19), 
			Vector2(32, 11), 
			Vector2(32, -8)
		])
		hover_effect.color = Color(1, 1, 0, 0.4)
		hover_effect.visible = true
		hover_effect.position = local_pos
		move_range_show.append(hover_effect)
		add_child(hover_effect)
	
	
#选中
func select_gamer(gamer:Gamer):
	if(now_selected_gamer == null):
		if(gamer.gamer_type == 2):
			show_walk_height_tile(gamer)
	elif(now_selected_gamer != gamer):
		show_walk_height_tile(gamer)
	now_selected_gamer = gamer


#隐藏高亮范围
func disable_walk_height_tile(gamer:Gamer):
	for i in move_range_show:
		i.queue_free()
	move_range_show = []
	

#未处理的输入事件捕获
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			now_selected_gamer = null
			disable_walk_height_tile(now_selected_gamer)
		if event.button_index == MOUSE_BUTTON_LEFT:
			#鼠标点击位置坐标
			var click_pos = get_global_mouse_position()
			var click_tile = walkable_map.local_to_map(click_pos)
			#判断一下点击的是walkable_map 不是 block_map 不是玩家位置
			var all_tiles = walkable_map.get_used_cells()
			var blocked_tiles = get_blocked_tiles()
			var all_gamers_tils:Array[Vector2i] = GlobalUtils.get_all_gamers_tiles(gamer_manager, walkable_map)
			if(!all_tiles.has(click_tile) 
			|| blocked_tiles.has(click_tile)
			|| all_gamers_tils.has(click_tile)):
				return
			print("未处理的左键点击")
			#点击左键如果有选择的对象则做如下处理
			if(now_selected_gamer != null):
				var gamer_type = now_selected_gamer.gamer_type
				if(gamer_type == 1):
					#移动命令
					disable_walk_height_tile(now_selected_gamer)
					var block_tiles = get_blocked_tiles()
					#一组路径坐标点
					var new_path = GlobalUtils.get_path_to_tile(
						now_selected_gamer.global_position,
						click_pos,
						walkable_map,
						block_tiles
					)
					
					if not new_path.is_empty():
						path = new_path
						now_selected_gamer.is_moving = true
						#第一个目的位置
						target_position = path[0]
						print("移动队列生成完毕，第一个目的点是: ", target_position)
						#检查距离小于阈值不移动
						if target_position.distance_to(now_selected_gamer.global_position) < arrival_threshold:
							#print("Warning: First target too close to current position!")
							_advance_to_next_target()
					else:
						print("移动队列点是空的，移动取消")
		
			
func _advance_to_next_target() -> void:
	path.remove_at(0)
	#print("Point reached, remaining points: ", path.size())
	
	if path.is_empty():
		#print("Path completed")
		now_selected_gamer.is_moving = false
		now_selected_gamer = null
		return
		
	target_position = path[0]
	if target_position.distance_to(now_selected_gamer.global_position) < arrival_threshold:
		#print("Next target too close, skipping")
		_advance_to_next_target()
	else:
		print("New target set: ", target_position)


func _physics_process(delta: float) -> void:
	if now_selected_gamer == null:
		return
	if not now_selected_gamer.is_moving or path.is_empty():
		return
		
	var distance_to_target = now_selected_gamer.global_position.distance_to(target_position)
	#print("Distance to target: ", distance_to_target)
	
	if distance_to_target < arrival_threshold:
		# Snap to exact center when close enough
		now_selected_gamer.global_position = target_position
		_advance_to_next_target()
	else:
		var direction = (target_position - now_selected_gamer.global_position).normalized()
		var movement = direction * move_speed * delta
		# Prevent overshooting by clamping movement to remaining distance
		if movement.length() > distance_to_target:
			movement = direction * distance_to_target
		now_selected_gamer.global_position += movement
		#print("Moving: dir=", direction, " movement=", movement, " new_pos=", now_selected_gamer.global_position)


#获取地图上不能走的单位
func get_blocked_tiles():
	var blocked_tiles:Array[Vector2i] = []
	var gamers = gamer_manager.get_children()
	for i in gamers:
		var gamer_position = i.global_position
		var tile = walkable_map.local_to_map(gamer_position)
		blocked_tiles.append(tile)
	print("阻塞的图块，", blocked_tiles)
	return blocked_tiles
