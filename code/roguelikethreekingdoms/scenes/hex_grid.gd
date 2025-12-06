extends Node2D
#图层z-index值
#玩家 2
#山脉 3
#可行走地图 0

#移动速度
@export var move_speed: float = 2000.0
#阈值
@export var arrival_threshold: float = 1.0 # Smaller threshold for precise center alignment

#地图网格
@onready var tile_map: TileMapLayer = $TileMap
#游戏内角色
@onready var gamer_manager: Node2D = $GamerManager

#目标位置
var target_position: Vector2
#路径一组坐标点
var path: PackedVector2Array

#画一个多边形高亮用来鼠标经过地图显示
var hover_effect: Line2D #多边形空心

#画N个多边形高亮用来显示移动范围
var move_range_show: Array[Polygon2D] = []
#移动范围网格集合
var move_range: Array[Vector2i] = []

#当前选中角色
var now_selected_gamer: Gamer
#当前鼠标经过的角色
var last_hover_gamer: Gamer


func _ready():
	#把一个多边形加入到树中
	_setup_hover_polygon()


func _process(_delta):
	#处理鼠标经过高亮
	_handle_hover_effect()
	#处理是否显示移动范围
	handle_show_moving_range()


#鼠标移上去效果某地图块六边形边缘高亮地图初始时先加到树中，之后改变位置即可
func _setup_hover_polygon() -> void:
	#多边形
	# 1. 定义多边形顶点（示例：六边形）
	hover_effect = Line2D.new()
	var hexagon_points = [
		Vector2(0, -18), 
		Vector2(-32, -10), 
		Vector2(-32, 9), 
		Vector2(0, 17), 
		Vector2(32, 9), 
		Vector2(32, -10)
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


#处理鼠标经过高亮移动六边形框框的位置
func _handle_hover_effect() -> void:
	#鼠标坐标
	var mouse_pos = get_local_mouse_position()
	#鼠标坐标转单元格
	var mouse_tile = tile_map.local_to_map(mouse_pos)
	#可用网格
	var used_cells = tile_map.get_used_cells()

	if used_cells.has(mouse_tile):
		#转换网格到坐标
		var local_pos = tile_map.map_to_local(mouse_tile)
		hover_effect.position = local_pos
		hover_effect.visible = true
	else:
		hover_effect.visible = false


#显示角色移动范围
func _show_walk_height_tile(gamer:Gamer):
	#如果是我方且移动过则不显示移动范围
	if (gamer.gamer_type == 1 or gamer.gamer_type == 3) && gamer.is_moved:
		return
	#先清一下
	_disable_walk_height_tile()
	var blocked_tiles = get_blocked_tiles()
	#获取移动范围全部单元格
	var walk_range = GlobalUtils.find_range(gamer, tile_map, blocked_tiles, gamer_manager)
	move_range = walk_range
	
	for i in walk_range:
		#转换网格到坐标
		var local_pos = tile_map.map_to_local(i)
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
	
	
#隐藏移动范围
func _disable_walk_height_tile():
	for i in move_range_show:
		i.queue_free()
	move_range_show = []
	move_range = []
	

#输入事件捕获
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("进到鼠标点击事件:")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			now_selected_gamer = null
			_disable_walk_height_tile()
		if event.button_index == MOUSE_BUTTON_LEFT:
			#当前鼠标点击的角色
			var gamer = mouse_position_gamer()
			if gamer != null:
				# 判断单位是否可选中（我方/友军/敌方）
				var is_selectable = gamer.gamer_type == 1 \
				|| gamer.gamer_type == 2 || gamer.gamer_type == 3

				if is_selectable:
					# 当前无选中单位，直接选中,当前有选中单位且不是同一个，切换选中
					if (now_selected_gamer == null 
					|| gamer != now_selected_gamer):
						now_selected_gamer = gamer
						print("当前选择的角色：" , now_selected_gamer)
						# 显示新棋子移动范围
						_show_walk_height_tile(now_selected_gamer)
				else:
					now_selected_gamer = null
					_disable_walk_height_tile()
			#点击的空地要判断是否是移动范围内
			else:
				if now_selected_gamer != null:
					if now_selected_gamer.is_moving:
						return
					if now_selected_gamer.gamer_type == 1:
						#鼠标转网格
						var mouse_position = get_global_mouse_position()
						var mouse_tile = tile_map.local_to_map(mouse_position)
						if move_range.has(mouse_tile):
							#移动
							_go_to_move(mouse_position)
						else:
							now_selected_gamer = null
							_disable_walk_height_tile()
		
		
#推进到下一个目标			
func _advance_to_next_target() -> void:
	path.remove_at(0)
	
	if path.is_empty():
		print("移动结束")
		now_selected_gamer.is_moving = false
		now_selected_gamer.is_moved = true
		now_selected_gamer = null
		return
		
	target_position = path[0]
	if target_position.distance_to(now_selected_gamer.global_position) < arrival_threshold:
		print("下一个目标太近, 忽略")
		_advance_to_next_target()
	else:
		print("新的目标点: ", target_position)


#物理帧
func _physics_process(delta: float) -> void:
	if now_selected_gamer == null:
		return
	if not now_selected_gamer.is_moving or path.is_empty():
		return
		
	var distance_to_target = now_selected_gamer.global_position.distance_to(target_position)
	
	if distance_to_target < arrival_threshold:
		#太近了
		now_selected_gamer.global_position = target_position
		_advance_to_next_target()
	else:
		var direction = (target_position - now_selected_gamer.global_position).normalized()
		var movement = direction * move_speed * delta
		# Prevent overshooting by clamping movement to remaining distance
		if movement.length() > distance_to_target:
			movement = direction * distance_to_target
		now_selected_gamer.global_position += movement


#获取地图上不能走的单位
func get_blocked_tiles():
	var blocked_tiles:Array[Vector2i] = []
	var gamers = gamer_manager.get_children()
	for i in gamers:
		#得排除当前选择的玩家，否则就无法移动
		if i == now_selected_gamer:
			continue
		var gamer_position = i.global_position
		var tile = tile_map.local_to_map(gamer_position)
		blocked_tiles.append(tile)
	return blocked_tiles


#鼠标在地图上划过时触发显示移动范围方法
func handle_show_moving_range():
	#鼠标当前位置对象
	var gamer = mouse_position_gamer()
	if(gamer != null):
		if(now_selected_gamer == null):
			if last_hover_gamer != null &&  last_hover_gamer!= gamer:
				_disable_walk_height_tile()
			if(gamer.gamer_type == 1):
				#如果是我方则显示移动范围高亮
				_show_walk_height_tile(gamer)
			no_selected_show_gamer_ui(gamer, true)
	else:
		if(now_selected_gamer == null):
			_disable_walk_height_tile()
			no_selected_show_gamer_ui(last_hover_gamer, false)
		last_hover_gamer = null


#没有选择对象时鼠标经过对象UI显示
func no_selected_show_gamer_ui(gamer:Gamer, show:bool):
	if null == gamer:
		return
	#如果传过来的对象不是当前鼠标过的对象则说明俩对象连续挨着的。则要先隐藏上一个对象的生命UI
	if last_hover_gamer != null && gamer != last_hover_gamer:
		last_hover_gamer.health_ui.visible = false;
	#我方、敌方、友方、建筑显示血条 TODO 左下角UI、其他被动效果(护甲、爆炸)、敌方攻击后效果
	if(gamer.gamer_type != 4 ):
		gamer.health_ui.visible = show;
	last_hover_gamer = gamer
		
		
		

#鼠标当前位置网格 角色,空地：返回null 有角色 返回角色
func mouse_position_gamer() -> Gamer:
	#鼠标转网格
	var mouse_position = get_global_mouse_position()
	var mouse_tile = tile_map.local_to_map(mouse_position)
	#当前地图中角色
	var all_gamers = gamer_manager.get_children()
	for gamer in all_gamers:
		var gamer_tile = tile_map.local_to_map(gamer.global_position)
		if(gamer_tile == mouse_tile):
			return gamer
	return null


#移动
func _go_to_move(click_pos:Vector2):
	_disable_walk_height_tile()
	var block_tiles = get_blocked_tiles()
	#一组路径坐标点
	var new_path = GlobalUtils.get_path_to_tile(
		now_selected_gamer.global_position,
		click_pos,
		tile_map,
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
			print("警告: 第一个目的与出发地太近了!")
			_advance_to_next_target()
	else:
		print("移动队列点是空的，移动取消")
