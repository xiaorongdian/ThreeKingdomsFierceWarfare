extends Node
class_name GlobalUtils

static func get_path_to_tile(
	#起始坐标
	start_pos: Vector2,
	#终点坐标
	target_pos: Vector2,
	#可行走图层
	tilemap: TileMapLayer,
	#阻塞的图块
	blocked_tiles: Array[Vector2i]
) -> PackedVector2Array:
	print("开始 坐标 (world): ", start_pos)
	print("目的 坐标 (world): ", target_pos)
	
	#转网格
	var start_tile = tilemap.local_to_map(start_pos)
	var end_tile = tilemap.local_to_map(target_pos)
	
	print("开始 网格 (map): ", start_tile)
	print("目的 网格 (map): ", end_tile)
	
	# 开始结束是一个点
	if start_tile == end_tile:
		print("开始结束是一个点")
		return PackedVector2Array([])
	
	#有可行网格
	var all_tiles = tilemap.get_used_cells()
	var walkable_tiles = all_tiles.filter(func(tile): return not blocked_tiles.has(tile))
	print("总共 网格: ", all_tiles.size(), ", 阻塞网格: ", blocked_tiles.size(), ", 可走网格: ", walkable_tiles.size())
	
	# new 一个 AStar2D
	var astar = AStar2D.new()
	
	# 先把walkable_tiles网格加入astar中
	for tile in walkable_tiles:
		var point_id = _get_point_id(tile)
		# 存储寻路用的瓦片坐标
		astar.add_point(point_id, Vector2(tile))
	
	# 建立连接，每次都重新绘制连接
	for tile in walkable_tiles:
		var point_id = _get_point_id(tile)
		
		for neighbor in _get_neighbors(tile):
			if walkable_tiles.has(neighbor):
				var neighbor_id = _get_point_id(neighbor)
				if not astar.are_points_connected(point_id, neighbor_id):
					astar.connect_points(point_id, neighbor_id)
	
	#获取开始和目的网格id
	var start_id = _get_point_id(start_tile)
	var end_id = _get_point_id(end_tile)
	
	#如果开始或结束不在astar网格中则返回空路径队列
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		print("没有有效的路径")
		return PackedVector2Array([])
	
	#返回一组路径点
	var tile_path = astar.get_point_path(start_id, end_id)
	
	#定义一组坐标点
	var world_path: PackedVector2Array = PackedVector2Array([])
	for tile_pos in tile_path:
		#返回网格中心坐标
		var world_pos = tilemap.map_to_local(Vector2i(tile_pos))
		# Include all points to ensure precise center-to-center movement 中心对中心的移动
		world_path.append(world_pos)
		print("添加坐标到移动队列中: ", world_pos)
	
	print("最终移动队列大小: ", world_path.size())
	if world_path.is_empty():
		print("警告: 生成的移动队列是空的!")
	else:
		print("第一个移动队列点: ", world_path[0])
	return world_path


static func _get_point_id(tile: Vector2i) -> int:
	# Convert 2D coordinates to unique ID 康托尔配对函数
	#var a = tile.x + 10000
	#var b = tile.y + 10000
	#return (a + b) * (a + b + 1) / 2 + b
	return hash(str(tile.x) + "," + str(tile.y))  #
	


static func _get_neighbors(tile: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	neighbors.append(Vector2i(tile.x + 1, tile.y))#右下
	neighbors.append(Vector2i(tile.x - 1, tile.y))#左上
	neighbors.append(Vector2i(tile.x, tile.y + 1))#左下
	neighbors.append(Vector2i(tile.x, tile.y - 1))#右上
	neighbors.append(Vector2i(tile.x - 1, tile.y + 1))#左
	neighbors.append(Vector2i(tile.x + 1, tile.y - 1))#右
	return neighbors


#移动范围格子返回--洪水算法 广度优先、tilemap可行走的图层 blocked_layer 不可行走图层
static func find_range(gamer:Gamer, 
			tilemap: TileMapLayer,
			blocked_tiles: Array[Vector2i],
			gamer_manager: GamerManager)-> Array[Vector2i]:
	var range:Array[Vector2i] = []
	var open:Array[Vector2i] = []
	var now:Array[Vector2i] = []
	var all_gamers_position:Array[Vector2i] = get_all_gamers_tiles(gamer_manager, tilemap)
	
	#玩家当前位置
	var gamer_position = gamer.global_position
	#转地图网格
	var tile = tilemap.local_to_map(gamer_position)
	now.append(tile)
	#可用网格
	var walkable_tiles = tilemap.get_used_cells()
	
	for i in gamer.max_step:
		for j in now:
			var neighbours = _get_neighbors(j)
			for k in neighbours:
				if(!open.has(k) && k != tile 
				&& !blocked_tiles.has(k) 
				&& walkable_tiles.has(k)
				&& !all_gamers_position.has(k)):
					open.append(k)
					range.append(k)
		now.clear()
		now.append_array(open)
	return range


#所有玩家的位置
static func get_all_gamers_tiles(gamer_manager, walkable_map):
	var all_gamers_position:Array[Vector2i] = []
	#所有玩家的位置
	var all_gamers = gamer_manager.get_children()
	for i in all_gamers:
		var gamer_position = i.global_position
		var gamer_tile = walkable_map.local_to_map(gamer_position)
		all_gamers_position.append(gamer_tile)
	return all_gamers_position
